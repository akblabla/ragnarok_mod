local Wargroove = require "wargroove/wargroove"
local OldCombat = require "wargroove/combat"
local VisionTracker = require "initialized/vision_tracker"
local StealthManager = require "scripts/stealth_manager"

Combat = {}

local defencePerShield = 0.10
local damageAt0Health = 0.0
local damageAt100Health = 1.0
local randomDamageMin = 0.0
local randomDamageMax = 0.1

local damageMultiplierList = {
	fortified_city = 0.5,
	hq = 0.5
}
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
function Combat.init()
    OldCombat.getDamage = Combat.getDamage
	OldCombat.getGrooveAttackerDamage = Combat.getGrooveAttackerDamage
    OldCombat.solveCombat = Combat.solveCombat
	OldCombat.forceAttack = Combat.forceAttack
	OldCombat.forceAttackFake = Combat.forceAttackFake
	OldCombat.solveRound = Combat.solveRound
	OldCombat.getPassiveMultiplier = Combat.getPassiveMultiplier
end

function Combat:getPassiveMultiplier(attacker, defender, attackerPos, defenderPos, path, isCounter, unitState)
	local condition = nil

	-- Itemified unit class
	if attacker.unitClass.aliasId ~= "" then
		condition = self.passiveConditions[attacker.unitClass.aliasId]
	else
		if attacker.unitClass.critConditionId == "" then
			condition = self.passiveConditions[attacker.unitClassId]
		else
			condition = self.passiveConditions[attacker.unitClass.critConditionId]
		end
	end

	local payload = {
		attacker = attacker,
		defender = defender,
		attackerPos = attackerPos,
		defenderPos = defenderPos,
		path = path,
		isCounter = isCounter,
		unitState = unitState
	}
	if condition ~= nil and condition(payload) then
		return attacker.unitClass.passiveMultiplier
	else
		return 1.0
	end
end

local function sawItComingMultiplier(attacker, defender, attackerPos, defenderPos, attackerPath, defenderPath, passiveMultiplier)

	local result = false
	for i,tile in pairs(attackerPath) do
		if (i ~= #attackerPath) and VisionTracker.canUnitSeeTile(defender,tile) then
			result = true
		end
	end
	local visibleTiles = VisionTracker.calculateVisionOfUnit(defender)
	for i,tile in pairs(visibleTiles) do
		local viewer = Wargroove.getUnitAt(tile)
		if not ((attackerPos.x == tile.x) and (attackerPos.y == tile.y)) and (viewer ~= nil) and Wargroove.areEnemies(defender.playerId,viewer.playerId) then
			result = true
		end
	end
	if defender.unitClass.isStructure == true then
		result = true
	end
	if (result == false) and StealthManager.isActive(defender.playerId) and not (StealthManager.isVisuallyAlerted(defender) or StealthManager.isVisuallyFleeing(defender)) then
		passiveMultiplier = math.max(passiveMultiplier,attacker.unitClass.passiveMultiplier)
	end

	result = false
	for i,tile in pairs(defenderPath) do
		if (i ~= #defenderPath) and VisionTracker.canUnitSeeTile(attacker,tile) then
			result = true
		end
	end
	visibleTiles = VisionTracker.calculateVisionOfUnit(attacker)
	for i,tile in pairs(visibleTiles) do
		local viewer = Wargroove.getUnitAt(tile)
		if not ((defenderPos.x == tile.x) and (defenderPos.y == tile.y)) and (viewer ~= nil) and Wargroove.areEnemies(attacker.playerId,viewer.playerId) then
			result = true
		end
	end
	if attacker.unitClass.isStructure == true then
		result = true
	end
	if (result == false) and StealthManager.isActive(attacker.playerId) and not (StealthManager.isVisuallyAlerted(attacker) or StealthManager.isVisuallyFleeing(attacker)) then
		passiveMultiplier = 0
	end
	return passiveMultiplier
end

function Combat:getGrooveAttackerDamage(attacker, defender, solveType, attackerPos, defenderPos, attackerPath, weaponIdOverride)
	local damage, hadPassive = self:getDamage(attacker, defender, solveType, false, attackerPos, defenderPos, attackerPath, {defenderPos}, true, weaponIdOverride)
	if (damage == nil) then
		return nil, false
	end

	return damage
end

function Combat:getDamage(attacker, defender, solveType, isCounter, attackerPos, defenderPos, attackerPath, defenderPath, isGroove, grooveWeaponIdOverride)
	if type(solveType) ~= "string" then
		error("solveType should be a string. Value is " .. tostring(solveType))
	end
	local missedAttack = 1.0
	if solveType == "crazy" then
		local values = { attacker.id, attacker.unitClassId, attacker.startPos.x, attacker.startPos.y, attackerPos.x, attackerPos.y,
		                 defender.id, defender.unitClassId, isCounter, Wargroove.getTurnNumber(), Wargroove.getCurrentPlayerId() }
		local roll = Wargroove.randomIntegerFromTable(values, 1, 100)
		if roll <= 50 then
			missedAttack = 0.0
		end

		solveType = "average"
	end

	local delta = {x = defenderPos.x - attackerPos.x, y = defenderPos.y - attackerPos.y }
	local moved = attackerPath and #attackerPath > 1

	-- This check is specifically relevant in two situations: Koji's groove and Lytra's ultra
	if not attacker.unitClass.canAttack and not isGroove then
		return nil, false
	end

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

		if isCounter then
			randomValue = 0.5
		end
	end
	if solveType == "simulationOptimistic" then
		if isCounter then
			randomValue = 0.5
		else
			randomValue = 1
		end
	end
	if solveType == "simulationPessimistic" then
		if isCounter then
			randomValue = 0.5
		else
			randomValue = 0
		end
	end
	if solveType == "average" then
		randomValue = 0.5
	end

	local attackerHealth = isGroove and 100 or attacker.health
	local attackerEffectiveness = (attackerHealth * 0.01) * (damageAt100Health - damageAt0Health) + damageAt0Health
	local defenderEffectiveness = (defender.health * 0.01) * (damageAt100Health - damageAt0Health) + damageAt0Health

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
			health = attackerHealth,
			state = attacker.state,
			damageTakenPercent = attacker.damageTakenPercent,
			stunned = attacker.stunned,
			tentacled = attacker.tentacled
		}
		--attackerEffectiveness = 1.0
	else
		effectiveAttacker = attacker
	end

	local passiveMultiplier = self:getPassiveMultiplier(effectiveAttacker, defender, attackerPos, defenderPos, attackerPath, isCounter, attacker.state)
	if not isGroove then
		passiveMultiplier = sawItComingMultiplier(attacker, defender, attackerPos, defenderPos, attackerPath, defenderPath, passiveMultiplier)
	end
	local defenderUnitClass = Wargroove.getUnitClass(defender.unitClassId)
	local defenderIsInAir = defenderUnitClass.inAir
	local defenderIsStructure = defenderUnitClass.isStructure
	local defenderIsPoisoned = Wargroove.getUnitState(defender, "poisoned")
	-- TODO
	local defenderCanBeAttackedFromDistance = defender.canBeAttackedFromDistance;

	local terrainDefence
	if defenderIsInAir then
		terrainDefence = Wargroove.getSkyDefenceAt(defenderPos)
	elseif defenderIsStructure then
		terrainDefence = 0
	else
		terrainDefence = Wargroove.getTerrainDefenceAt(defenderPos)
	end

	local terrainDefenceBonus = terrainDefence * defencePerShield
	if defenderIsPoisoned == "true" then
		terrainDefenceBonus = terrainDefenceBonus - 0.15
	end
	if not defenderCanBeAttackedFromDistance then
		terrainDefenceBonus = terrainDefenceBonus + 0.20
	end

	local baseDamage
	if (isGroove) then
		local weaponId
		if (grooveWeaponIdOverride ~= nil) then
			weaponId = grooveWeaponIdOverride
		else
			weaponId = attacker.unitClass.weapons[1].id
		end
		baseDamage = Wargroove.getWeaponDamageForceGround(weaponId, attacker, defender)
	else	
		local weapon
		if grooveWeaponIdOverride ~= nil then
			weapon = Wargroove.getWeapon(grooveWeaponIdOverride, attacker.unitClassId, attacker.id)
			baseDamage = Wargroove.getWeaponDamage(weapon, attacker, defender)
		else
			weapon, baseDamage = self:getBestWeapon(effectiveAttacker, defender, delta, moved, attackerPos.facing)
		end

		if weapon == nil or (isCounter and not weapon.canMoveAndAttack) 
						 or baseDamage < 0.01 
						 or (isCounter and not weapon.canCounterAttack) 
						 or (isCounter and effectiveAttacker.stunned)
						 or (effectiveAttacker.tentacled)
						 then
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

	--To fix the error in the "getWeaponDamage" engine method that returns the wrong value.
	if damageMultiplierList[defender.unitClassId]~=nil then
		baseDamage = baseDamage - 0.05*(1-damageMultiplierList[defender.unitClassId])
	end

	local multiplier = 1.0
	if Wargroove.isHuman(defender.playerId) then
		multiplier = Wargroove.getDamageMultiplier()
		
		-- If the player is on "easy" for damage, make the AI overlook that.
		if multiplier < 1.0 and solveType == "aiSimulation" then
			multiplier = 1.0
		end

		local isScript = Wargroove.isExecutingScript()
		if isScript then
			multiplier = 1.0
		end
	end

	-- Damage reduction
	multiplier = multiplier * defender.damageTakenPercent / 100

	local damage = self:solveDamage(baseDamage, attackerEffectiveness, defenderEffectiveness, terrainDefenceBonus, randomValue, passiveMultiplier, multiplier)

	-- In case the map a counter modifier we increase the base damage of the unit here
	if isCounter then
		local counterModifier = Wargroove.getCounterModifierAt(attackerPos)
		damage = damage + counterModifier
	end

	-- Crazy solve type -> We can miss attacks
	damage = damage * missedAttack

	local hasPassive = passiveMultiplier > 1.01
	if passiveMultiplier == 0 then
		damage = nil
		hasPassive = nil
	end

	return damage, hasPassive
end

function Combat:forceAttack(attacker, defender)
	self:forceAttackFake(attacker, defender)
    Wargroove.setMetaLocation("last_attacker", attacker.pos)
    Wargroove.setMetaLocation("last_defender", defender.pos)
    Wargroove.clearUnitPositionCache()

end

function Combat:solveRound(attacker, defender, solveType, isCounter, attackerPos, defenderPos, attackerPath, defenderPath)
	if (defender.canBeAttacked == false) or (not defender.unitClass.isAttackable) then
		return nil, false
	end

	local damage, hadPassive = self:getDamage(attacker, defender, solveType, isCounter, attackerPos, defenderPos, attackerPath, defenderPath, false, nil)	
	if (damage == nil) then
		return nil, false
	end
	
	local defenderHealth = math.floor(defender.health - damage)
	return defenderHealth, hadPassive
end

function Combat:solveCombat(attackerId, defenderId, attackerPath, solveType)

	local attacker = Wargroove.getUnitById(attackerId)
	assert(attacker ~= nil)
	local defender = Wargroove.getUnitById(defenderId)
	assert(defender ~= nil)

	local results = {
		attackerHealth = attacker.health,
		defenderHealth = defender.health,
		attackerAttacked = false,
		defenderAttacked = false,
		hasCounter = false,
		hasAttackerCrit = false
	}

	local e0 = self:getEndPosition(attackerPath, attacker.pos)
	Wargroove.pushUnitPos(attacker, e0)

	if solveType ~= "random" then
		Wargroove.setSimulating(true)
	end
	Wargroove.applyBuffs()

	local attackResult
	local defenderPath = {defender.pos}
	attackResult, results.hasAttackerCrit = self:solveRound(attacker, defender, solveType, false, attacker.pos, defender.pos, attackerPath, defenderPath)
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
			state = defender.state,
			stunned = defender.stunned
		}
		local defenderResult
		defenderResult, results.hasDefenderCrit = self:solveRound(damagedDefender, attacker, solveType, true, defender.pos, attacker.pos, defenderPath, attackerPath)
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
	
	Wargroove.setSimulating(false)

	return results
end

function Combat:solveDamage(weaponDamage, attackerEffectiveness, defenderEffectiveness, terrainDefenceBonus, randomValue, crit, multiplier)
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
	local randomBonus = randomDamageMin + (randomDamageMax - randomDamageMin) * (randomValue * rngMult + rngAdd)

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
function Combat:forceAttackFake(unit, target, delayOverride)
	print("Combat:forceAttackFake(unit, target, delayOverride)")
	if (unit == nil) or (target == nil) then
        return
    end
	if delayOverride == nil then
		delayOverride = 1
	end

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
    if (not Wargroove.isLocalPlayer(unit.playerId)) and Wargroove.canCurrentlySeeTile(target.pos) then
        Wargroove.spawnMapAnimation(target.pos, 0, "ui/grid/selection_cursor", "target", "over_units", {x = -4, y = -4})
        Wargroove.waitTime(0.5)
    end
	print("1")
    local originalPos = unit.pos
    local dist = math.sqrt((target.pos.x-unit.pos.x)^2 + (target.pos.y-unit.pos.y)^2)
    Wargroove.playMapSound("unitAttack",target.pos)
    Wargroove.moveUnitToOverride(unit.id, unit.pos, 0.5*(target.pos.x-unit.pos.x)/dist, 0.5*(target.pos.y-unit.pos.y)/dist, 4)
    while Wargroove.isLuaMoving(unit.id) do
      coroutine.yield()
    end
	print("2")
	print("unit.id: "..unit.id)
	print("target.id: "..target.id)
	print("originalPos:")
	print(dump({originalPos},0))
    local results = self:solveCombat(unit.id, target.id, {originalPos}, "average")
	print("3")
    unit:setHealth(results.attackerHealth,target.id)
	print("4")
	unit.hadTurn = true
    if results.attackerHealth<= 0 then
        Wargroove.playUnitDeathAnimation(unit.id)
        if (unit.unitClass.isCommander) then
            Wargroove.playMapSound("commanderDie", unit.pos)
        end
    end
	print("5")
    
    if target.health>results.defenderHealth then
        Wargroove.playUnitAnimation(target.id,"hit")
        Wargroove.playMapSound("hitOrganic",target.pos)
    end
	print("6")
    target:setHealth(results.defenderHealth,unit.id)
    if results.defenderHealth<= 0 then
        Wargroove.playUnitDeathAnimation(target.id)
        if (target.unitClass.isCommander) then
            Wargroove.playMapSound("commanderDie", target.pos)
        end
    end
	print("7")
    --Wargroove.startCombat(unit, target, {unit.pos})
    Wargroove.updateUnit(unit)
	print("8")
    Wargroove.updateUnit(target)
	print("9")
    Wargroove.moveUnitToOverride(unit.id, unit.pos, 0, 0, 4)
	print("10")
    Wargroove.waitTime(delayOverride)
    if results.attackerHealth<= 0 then
        Wargroove.removeUnit(unit.id)
    end
	print("11")
    if results.defenderHealth<= 0 then
		if target.unitClass.canBeCaptured then
			target.playerId = -1
			target.health = 100
			Wargroove.updateUnit(target)
		else
        	Wargroove.removeUnit(target.id)
		end
    end
	print("12")
    Wargroove.unsetFacingOverride(unit.id)
    Wargroove.setMetaLocationArea("last_move_path", {unit.pos})
    Wargroove.setMetaLocation("last_unit", unit.pos)
	print("13")
end



return Combat