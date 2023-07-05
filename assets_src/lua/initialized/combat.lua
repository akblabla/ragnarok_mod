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
			damageTakenPercent = attacker.damageTakenPercent
		}
	else
		effectiveAttacker = attacker
	end
	local result, _ = Stats.getTerrainCost("bridge", effectiveAttacker.unitClassId)
	local isGroundUnit = result<100
	if not (isGroundUnit and defender.unitClass.isStructure) then
		if not isGroove and (Stats.meleeUnits[effectiveAttacker.unitClassId] ~= nil and not Wargroove.canStandAt(effectiveAttacker.unitClassId, defender.pos)) then
			return nil, false
		end
	end
	if Ragnarok.hasCrown(effectiveAttacker) then return nil, false end
	
	local passiveMultiplier = self:getPassiveMultiplier(effectiveAttacker, defender, attackerPos, defenderPos, attackerPath, isCounter, attacker.state)

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
		passiveMultiplier = attacker.unitClass.passiveMultiplier
	end
	sawItComing = false
	for i,tile in pairs(defenderPath) do
		if (i ~= #defenderPath) and VisionTracker.canUnitSeeTile(attacker,tile) then
			sawItComing = true
		end
	end
	visibleTiles = VisionTracker.calculateVisionOfUnit(attacker)
	for i,tile in pairs(visibleTiles) do
		local viewer = Wargroove.getUnitAt(tile)
		if not ((defenderPos.x == tile.x) and (defenderPos.y == tile.y)) and (viewer ~= nil) and Wargroove.areEnemies(attacker.playerId,viewer.playerId) then
			sawItComing = true
		end
	end
	if attacker.unitClass.isStructure == true then
		sawItComing = true
	end
	if (sawItComing == false) and StealthManager.isActive(attacker.playerId) and not StealthManager.isVisuallyAlerted(attacker) then
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
			weaponId = attacker.unitClass.weapons[1].id
		end
		baseDamage = Wargroove.getWeaponDamageForceGround(weaponId, defender)
	else	
		local weapon
		weapon, baseDamage = self:getBestWeapon(effectiveAttacker, defender, delta, moved, attackerPos.facing)

		if weapon == nil or (isCounter and not weapon.canMoveAndAttack) or baseDamage <= 0 then
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

	local damage, hadPassive = self:getDamage(attacker, defender, solveType, isCounter, attackerPos, defenderPos, attackerPath, defenderPath, nil, false, false)	
	if (damage == nil) then
		return nil, false
	end
	
	local defenderHealth = math.floor(defender.health - damage)
	return defenderHealth, hadPassive
end

function NewCombat:solveCombat(attackerId, defenderId, attackerPath, solveType)

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
	attackResult, results.hasAttackerCrit = self:solveRound(attacker, defender, solveType, false, attacker.pos, defender.pos, attackerPath, {defender.pos})
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
		defenderResult, results.hasDefenderCrit = self:solveRound(damagedDefender, attacker, solveType, true, defender.pos, attacker.pos, {defender.pos}, attackerPath)
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

return Combat