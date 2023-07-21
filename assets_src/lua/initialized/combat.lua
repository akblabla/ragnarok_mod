local Wargroove = require "wargroove/wargroove"
local PassiveConditions = require "wargroove/passive_conditions"
local VisionTracker = require "initialized/vision_tracker"
local Ragnarok = require "initialized/ragnarok"
local Stats = require "util/stats"
local StealthManager = require "scripts/stealth_manager"


--
local defencePerShield = 0.10
local damageAt0Health = 0.1
local damageAt100Health = 1.0
local randomDamageMin = 0
local randomDamageMax = 0.1
--

local Combat = require "wargroove/combat"
local NewCombat = {}

-- This is called by the game when the map is loaded.
function Combat.init()
	Combat.getDamage = NewCombat.getDamage
	Combat.solveDamage = NewCombat.solveDamage
	Combat.getBestWeapon = NewCombat.getBestWeapon
	Combat.solveRound = NewCombat.solveRound
	Combat.solveCombat = NewCombat.solveCombat
	Combat.getGrooveAttackerDamage = NewCombat.getGrooveAttackerDamage
end

function NewCombat:getGrooveAttackerDamage(attacker, defender, solveType, attackerPos, defenderPos, attackerPath, weaponIdOverride)
	local damage, hadPassive = self:getDamage(attacker, defender, solveType, false, attackerPos, defenderPos, attackerPath, {defenderPos}, true, weaponIdOverride)
	if (damage == nil) then
		return nil, false
	end

	return damage
end

function NewCombat:getBestWeapon(attacker, defender, delta, moved, facing)
	assert(facing ~= nil)

	local weapons = attacker.unitClass.weapons
		for i, weapon in ipairs(weapons) do
		if self:canUseWeapon(weapon, moved, delta, facing) then
			local dmg = Wargroove.getWeaponDamage(weapon, defender, facing)
            if dmg > 0 then
                return weapon, dmg
            end
        end
    end

	return nil, 0.0
end

function Combat:canAttack(attacker, defender, moved)

	local weapons = attacker.unitClass.weapons
		for i, weapon in ipairs(weapons) do
		if self:canUseWeapon(weapon, moved, delta, facing) then
			local dmg = Wargroove.getWeaponDamage(weapon, defender, facing)
            if dmg > 0 then
                return weapon, dmg
            end
        end
    end

	return nil, 0.0
end

function NewCombat:solveDamage(weaponDamage, attackerEffectiveness, defenderEffectiveness, terrainDefenceBonus, randomValue, crit, multiplier)
	-- weaponDamage: the base damage, e.g. soldiers do 0.55 base vs soldiers
	-- attackerEffectiveness: the health of the attacker divided by 100. e.g. a soldier at half health is 0.5
	-- defenderEffectiveness: the health of the defender divided by 100
	-- terrainDefenceBonus: 0.1 * number of shields, or -0.1 * number of skulls. e.g. 0.3 for forests and -0.2 for rivers
	-- randomValue: a random number from 0.0 to 1.0
	-- crit: a damage multiplier from critical damage. 1.0 if not critical, > 1.0 for crits (depending on the attacker)
	-- multiplier: a general multiplier, from campaign difficulty and map editor unit damage multiplier

	-- Adjust RNG as follows: rng' = rng * rngMult + rngAdd
	-- This ensures that the average damage remains the same, but clamps the rng range to 10%
	local rngMult = 1.0 / math.max(1.0, crit)
	local rngAdd = (1.0 - rngMult) * 0.5
	local randomBonus = randomDamageMin + (randomDamageMax - randomDamageMin) * (randomValue * rngMult+rngAdd)

	-- Compute the offence and defence based on the different stats
	local offence = weaponDamage + randomBonus
	local defence = 1.0 - (defenderEffectiveness * math.max(0, terrainDefenceBonus) - math.max(0, -terrainDefenceBonus))

	-- Multiply everything together for final damage (in percent space, not unit health space - still needs to be multiplied by 100)
	local damage = attackerEffectiveness * offence * defence * multiplier * crit

	-- Minimum of 1 damage, if any damage is dealt
	local wholeDamage = math.floor(100 * damage + 0.5)
	if damage > 0.001 and wholeDamage < 1 then
		wholeDamage = 1
	end
	return wholeDamage
end

function NewCombat:getDamage(attacker, defender, solveType, isCounter, attackerPos, defenderPos, attackerPath, defenderPath, isGroove, grooveWeaponIdOverride)
	if type(solveType) ~= "string" then
		error("solveType should be a string. Value is " .. tostring(solveType))
	end

	local delta = {x = defenderPos.x - attackerPos.x, y = defenderPos.y - attackerPos.y }
	local moved = attackerPath and #attackerPath > 1

	local randomValue = 0.5
	if solveType == "random" and Wargroove.isRNGEnabled() then
		local values = { attacker.id, attacker.unitClassId, attacker.startPos.x, attacker.startPos.y, attackerPos.x, attackerPos.y,
		                 defender.id, defender.unitClassId, defender.startPos.x, defender.startPos.y, defenderPos.x, defenderPos.y,
						 isCounter, Wargroove.getTurnNumber(), Wargroove.getCurrentPlayerId() }
		local str = ""
		for i, v in ipairs(values) do
			str = str .. tostring(v) .. ":"
		end
		randomValue = Wargroove.pseudoRandomFromString(str)
	end
	if solveType == "simulationOptimistic" then
		if isCounter then
			randomValue = 0
		else
			randomValue = 1
		end
	end
	if solveType == "simulationPessimistic" then
		if isCounter then
			randomValue = 1
		else
			randomValue = 0
		end
	end

	local isRallied = Wargroove.getUnitState(attacker, "rallied")
	if (isRallied ~= nil) and (isRallied == "true") then
		isRallied = true
	else
		isRallied = false
	end
	-- For structures, check if there's a garrison; if so, attack as if it was that instead
	local effectiveAttacker
	if attacker.garrisonClassId ~= '' then
		effectiveAttacker = {
			id = attacker.id,
			pos = attacker.pos,
			startPos = attacker.startPos,
			playerId = attacker.playerId,
			unitClassId = attacker.garrisonClassId,
			unitClass = Wargroove.getUnitClass(attacker.garrisonClassId),
			health = attacker.health,
			state = attacker.state,
			damageTakenPercent = attacker.damageTakenPercent
		}
	elseif isRallied then
		effectiveAttacker = {
			id = attacker.id,
			pos = attacker.pos,
			startPos = attacker.startPos,
			playerId = attacker.playerId,
			unitClassId = attacker.unitClassId,
			unitClass = Wargroove.getUnitClass(attacker.unitClassId),
			health = 100,
			state = attacker.state,
			damageTakenPercent = attacker.damageTakenPercent
		}
	else
		effectiveAttacker = attacker
	end

	local attackerHealth = isGroove and 100 or effectiveAttacker.health
	local attackerEffectiveness = (attackerHealth * 0.01) * (damageAt100Health - damageAt0Health) + damageAt0Health
	local defenderEffectiveness = (defender.health * 0.01) * (damageAt100Health - damageAt0Health) + damageAt0Health

	local result, _ = Stats.getTerrainCost("bridge", effectiveAttacker.unitClassId)
	local isGroundUnit = result<100
	if not (isGroundUnit and defender.unitClass.isStructure) then
		if not isGroove and (Stats.meleeUnits[effectiveAttacker.unitClassId] ~= nil and not Wargroove.canStandAt(effectiveAttacker.unitClassId, defender.pos)) then
			return nil, false
		end
	end
	if Ragnarok.hasCrown(effectiveAttacker) then return nil, false end
	
	local passiveMultiplier = self:getPassiveMultiplier(effectiveAttacker, defender, attackerPos, defenderPos, attackerPath, isCounter, effectiveAttacker.state)
	-- local isGiant = false
	-- for _, tag in pairs(effectiveAttacker.unitClass.tags) do
	-- 	if tag == "giant" then
	-- 	  isGiant = true
	-- 	end
	-- end
	-- if not isGiant and isRallied then
	-- 	passiveMultiplier = effectiveAttacker.unitClass.passiveMultiplier
	-- end
	local sawItComing = false
	for i,tile in pairs(attackerPath) do
		if (i ~= #attackerPath) and VisionTracker.canUnitSeeTile(defender,tile) then
			sawItComing = true
		end
	end
	local visibleTiles = VisionTracker.calculateVisionOfUnit(defender)
	for i,tile in pairs(visibleTiles) do
		local viewer = Wargroove.getUnitAt(tile)
		if not ((attackerPos.x == tile.x) and (attackerPos.y == tile.y)) and (viewer ~= nil) and Wargroove.areEnemies(defender.playerId,viewer.playerId) then
			sawItComing = true
		end
	end
	if defender.unitClass.isStructure == true then
		sawItComing = true
	end
	if (sawItComing == false) and StealthManager.isActive(defender.playerId) and not StealthManager.isVisuallyAlerted(defender) then
		passiveMultiplier = math.max(passiveMultiplier,effectiveAttacker.unitClass.passiveMultiplier)
	end
	sawItComing = false
	for i,tile in pairs(defenderPath) do
		if (i ~= #defenderPath) and VisionTracker.canUnitSeeTile(effectiveAttacker,tile) then
			sawItComing = true
		end
	end
	visibleTiles = VisionTracker.calculateVisionOfUnit(effectiveAttacker)
	for i,tile in pairs(visibleTiles) do
		local viewer = Wargroove.getUnitAt(tile)
		if not ((defenderPos.x == tile.x) and (defenderPos.y == tile.y)) and (viewer ~= nil) and Wargroove.areEnemies(effectiveAttacker.playerId,viewer.playerId) then
			sawItComing = true
		end
	end
	if effectiveAttacker.unitClass.isStructure == true then
		sawItComing = true
	end
	if (sawItComing == false) and StealthManager.isActive(effectiveAttacker.playerId) and not StealthManager.isVisuallyAlerted(effectiveAttacker) then
		passiveMultiplier = 0
	end


	local defenderUnitClass = Wargroove.getUnitClass(defender.unitClassId)
	local defenderIsInAir = defenderUnitClass.inAir
	local defenderIsStructure = defenderUnitClass.isStructure

	local terrainDefence
	if defenderIsInAir then
		terrainDefence = Wargroove.getSkyDefenceAt(defenderPos)
	elseif defenderIsStructure then
		terrainDefence = 0
	else
		terrainDefence = Wargroove.getTerrainDefenceAt(defenderPos)
	end

	local terrainDefenceBonus = terrainDefence * defencePerShield

	local baseDamage
	if (isGroove) then
		local weaponId
		if (grooveWeaponIdOverride ~= nil) then
			weaponId = grooveWeaponIdOverride
		else
			weaponId = effectiveAttacker.unitClass.weapons[1].id
		end
		baseDamage = Wargroove.getWeaponDamageForceGround(weaponId, defender)
	else	
		local weapon
		weapon, baseDamage = self:getBestWeapon(effectiveAttacker, defender, delta, moved, attackerPos.facing)

		if weapon == nil or (isCounter and (not weapon.canMoveAndAttack)) or baseDamage <= 0 then
			return nil, false
		end

		if #(weapon.terrainExclusion) > 0 then
			local targetTerrain = Wargroove.getTerrainNameAt(defenderPos)
			for i, terrain in ipairs(weapon.terrainExclusion) do
				if targetTerrain == terrain then
					return nil, false
				end
			end
		end
	end

	local multiplier = 1.0
	if Wargroove.isHuman(defender.playerId) then
		multiplier = Wargroove.getDamageMultiplier()

		-- If the player is on "easy" for damage, make the AI overlook that.
		if multiplier < 1.0 and solveType == "aiSimulation" then
			multiplier = 1.0
		end
	end

	-- Damage reduction
	multiplier = multiplier * defender.damageTakenPercent / 100

	-- Hardcoded harpoonship passive
	if effectiveAttacker.unitClassId == "harpoonship" and (not Wargroove.canStandAt(effectiveAttacker.unitClassId, defender.pos)) and (not defenderIsInAir) then
		attackerEffectiveness = attackerEffectiveness*0.5
	end
	local damage = self:solveDamage(baseDamage, attackerEffectiveness, defenderEffectiveness, terrainDefenceBonus, randomValue, passiveMultiplier, multiplier)

	local hasPassive = passiveMultiplier > 1.01
	if passiveMultiplier == 0 then
		damage = nil
		hasPassive = nil
	end
	return damage, hasPassive
end

function NewCombat:solveRound(attacker, defender, solveType, isCounter, attackerPos, defenderPos, attackerPath, defenderPath)
	if (defender.canBeAttacked == false) then
		return nil, false
	end

	local damage, hadPassive = self:getDamage(attacker, defender, solveType, isCounter, attackerPos, defenderPos, attackerPath, defenderPath, nil, false)	
	if (damage == nil) then
		return nil, false
	end
	
	local defenderHealth = math.floor(defender.health - damage)
	return defenderHealth, hadPassive
end

local reverseOrder = false

local function deepCopy(orig)
    local orig_type = type(orig)
    local copy
    if orig_type == 'table' then
        copy = {}
        for orig_key, orig_value in pairs(orig) do
            copy[orig_key] = deepCopy(orig_value)
        end
    else -- number, string, boolean, etc
        copy = orig
    end
    return copy
end

local function dump(o,level)
    if type(o) == 'table' then
       local s = '\n' .. string.rep("   ", level) .. '{\n'
       for k,v in pairs(o) do
          if type(k) ~= 'number' then k = '"'..k..'"' end
          s = s .. string.rep("   ", level+1) .. '['..k..'] = ' .. dump(v,level+1) .. ',\n'
       end
       return s .. string.rep("   ", level) .. '}'
    else
       return tostring(o)
    end
 end

function NewCombat:solveCombat(attackerId, defenderId, attackerPath, solveType)
	local tempAttacker = deepCopy(Wargroove.getUnitById(attackerId))
	assert(tempAttacker ~= nil)
	local tempDefender = deepCopy(Wargroove.getUnitById(defenderId))
	assert(tempDefender ~= nil)
	local e0 = self:getEndPosition(attackerPath, tempAttacker.pos)
	tempAttacker.pos = e0
	local weapon, _ = self:getBestWeapon(tempDefender, tempAttacker, {x=tempAttacker.pos.x-tempDefender.pos.x,y=tempAttacker.pos.y-tempDefender.pos.y}, false, tempDefender.pos.facing)
	local attacker
	local defender
	local defenderPath
	local isHighAlert = Wargroove.getUnitState(tempDefender, "high_alert")
	if (isHighAlert ~= nil) and (isHighAlert == "true") and (weapon ~= nil) and (weapon.canMoveAndAttack == true) then
		isHighAlert = true
	else
		isHighAlert = false
	end
	if  (solveType ~= "random") and (isHighAlert == true) then
		isHighAlert = true
		attacker = Wargroove.getUnitById(defenderId)
		assert(attacker ~= nil)
		defender = Wargroove.getUnitById(attackerId)
		defender.pos = e0
		assert(defender ~= nil)
		defenderPath = deepCopy(attackerPath)
		attackerPath = {attacker.pos}
	else
		isHighAlert = false
		attacker = Wargroove.getUnitById(attackerId)
		assert(attacker ~= nil)
		defender = Wargroove.getUnitById(defenderId)
		assert(defender ~= nil)
		defenderPath = {defender.pos}
	end
	local results = {
		attackerHealth = attacker.health,
		defenderHealth = defender.health,
		attackerAttacked = false,
		defenderAttacked = false,
		hasCounter = false,
		hasAttackerCrit = false
	}

	if  (reverseOrder == true) then
		local e1 = self:getEndPosition(defenderPath, defender.pos)
		Wargroove.pushUnitPos(defender, e1)
	else
		local e1 = self:getEndPosition(attackerPath, attacker.pos)
		Wargroove.pushUnitPos(attacker, e1)
	end
	if solveType ~= "random" then
		Wargroove.setSimulating(true)
	end
	Wargroove.applyBuffs()

	local attackResult
	if (solveType ~= "random") then
		attackResult, results.hasAttackerCrit = self:solveRound(attacker, defender, solveType, isHighAlert, attacker.pos, defender.pos, attackerPath, defenderPath)
	else
		attackResult, results.hasAttackerCrit = self:solveRound(attacker, defender, solveType, reverseOrder, attacker.pos, defender.pos, attackerPath, defenderPath)
	end
	if attackResult ~= nil then
		results.defenderHealth = attackResult
		results.attackerAttacked = true
		if results.defenderHealth < 1 and solveType == "random" then
			results.defenderHealth = 0
		end
	end

	if results.defenderHealth > 0 then
		local damagedDefender = {
			id = defender.id,
			pos = defender.pos,
			startPos = defender.startPos,
			playerId = defender.playerId,
			health = results.defenderHealth,
			unitClass = defender.unitClass,
			unitClassId = defender.unitClassId,
			garrisonClassId = defender.garrisonClassId,
			state = defender.state
		}
		local defenderResult
		if (solveType ~= "random") then
			defenderResult, results.hasDefenderCrit = self:solveRound(damagedDefender, attacker, solveType, not ( isHighAlert), defender.pos, attacker.pos, defenderPath, attackerPath)
		else
			defenderResult, results.hasDefenderCrit = self:solveRound(damagedDefender, attacker, solveType, not ( reverseOrder), defender.pos, attacker.pos, defenderPath, attackerPath)
		end
		if defenderResult ~= nil then
			results.attackerHealth = defenderResult
			results.defenderAttacked = true
			results.hasCounter = true
			if results.attackerHealth < 1 and solveType == "random" then
				results.attackerHealth = 0
			end
		end
	end
	Wargroove.popUnitPos()
	Wargroove.applyBuffs()

	if isHighAlert and (solveType ~= "random") then
		local temp = results.attackerHealth
		results.attackerHealth = results.defenderHealth
		results.defenderHealth = temp
		local temp = results.hasAttackerCrit
		results.hasAttackerCrit = results.hasDefenderCrit
		results.hasDefenderCrit = temp
	end
	Wargroove.setSimulating(false)
	if solveType == "random" then
		reverseOrder = false
	end
	return results
end

function Combat:forceAttack(attacker, defender)
	Combat:forceAttackFake(attacker, defender)
    Wargroove.setMetaLocation("last_attacker", attacker.pos)
    Wargroove.setMetaLocation("last_defender", defender.pos)
    Wargroove.clearUnitPositionCache()

end
function Combat:forceAttackFake(unit, target, delayOverride)
	if (unit == nil) or (target == nil) then
        return
    end
	print("forceAttack")
	local damage, _ = self:getDamage(unit, target, "simulationOptimistic", false, unit.pos, target.pos, {unit.pos}, {target.pos}, false)
	if damage<=0 then
		return
	end
	if delayOverride == nil then
		delayOverride = 1
	end

	print(1)
    --- Telegraph
    if unit.pos.x>target.pos.x then
        -- spawnedUnit.startPos.facing = 1
        -- spawnedUnit.pos.facing = 1
        Wargroove.setFacingOverride(unit.id, "left")
    elseif unit.pos.x<target.pos.x then
        -- spawnedUnit.startPos.facing = 0
        -- spawnedUnit.pos.facing = 0
        Wargroove.setFacingOverride(unit.id, "right")
    end
	print(2)
    if (not Wargroove.isLocalPlayer(unit.playerId)) and Wargroove.canCurrentlySeeTile(target.pos) then
        Wargroove.spawnMapAnimation(target.pos, 0, "ui/grid/selection_cursor", "target", "over_units", {x = -4, y = -4})
        Wargroove.waitTime(0.5)
    end
	print(3)
    local originalPos = unit.pos
    local dist = math.sqrt((target.pos.x-unit.pos.x)^2 + (target.pos.y-unit.pos.y)^2)
    Wargroove.playMapSound("unitAttack",target.pos)
    Wargroove.moveUnitToOverride(unit.id, unit.pos, 0.5*(target.pos.x-unit.pos.x)/dist, 0.5*(target.pos.y-unit.pos.y)/dist, 4)
    while Wargroove.isLuaMoving(unit.id) do
      coroutine.yield()
    end
	print(4)
    local results = self:solveCombat(unit.id, target.id, {originalPos}, "random")
    unit:setHealth(results.attackerHealth,target.id)
	unit.hadTurn = true
    if results.attackerHealth<= 0 then
        Wargroove.playUnitDeathAnimation(unit.id)
        if (unit.unitClass.isCommander) then
            Wargroove.playMapSound("commanderDie", unit.pos)
        end
    end
	print(5)
    
    if target.health>results.defenderHealth then
        Wargroove.playUnitAnimation(target.id,"hit")
        Wargroove.playMapSound("hitOrganic",target.pos)
    end
	print(6)
    target:setHealth(results.defenderHealth,unit.id)
    if results.defenderHealth<= 0 then
        Wargroove.playUnitDeathAnimation(target.id)
        if (target.unitClass.isCommander) then
            Wargroove.playMapSound("commanderDie", target.pos)
        end
    end
    --Wargroove.startCombat(unit, target, {unit.pos})
	print(7)
    Wargroove.updateUnit(unit)
	print(8)
    Wargroove.updateUnit(target)
	print(9)
    Wargroove.moveUnitToOverride(unit.id, unit.pos, 0, 0, 4)
    Wargroove.waitTime(delayOverride)
    if results.attackerHealth<= 0 then
        Wargroove.removeUnit(unit.id)
    end
    if results.defenderHealth<= 0 then
        Wargroove.removeUnit(target.id)
    end
	print(10)
    Wargroove.unsetFacingOverride(unit.id)
    Wargroove.setMetaLocationArea("last_move_path", {unit.pos})
    Wargroove.setMetaLocation("last_unit", unit.pos)
	print(11)
end


function Combat:startReverseCombat(attacker, defender, path)
	reverseOrder = true
	attacker.pos = self:getEndPosition(path, attacker.pos)

    Wargroove.startCombat(defender, attacker, {})
    Wargroove.setMetaLocation("last_attacker", attacker.pos)
    Wargroove.setMetaLocation("last_defender", defender.pos)
    Wargroove.clearUnitPositionCache()
end

return Combat