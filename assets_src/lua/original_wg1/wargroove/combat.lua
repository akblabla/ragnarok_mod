local Combat = {}
local Wargroove = require "wargroove/wargroove"
local PassiveConditions = require "wargroove/passive_conditions"


--
local defencePerShield = 0.10
local damageAt0Health = 0.0
local damageAt100Health = 1.0
local randomDamageMin = 0.0
local randomDamageMax = 0.1
--


function Combat:canUseWeapon(weapon, moved, delta, facing)
	local distance = math.abs(delta.x) + math.abs(delta.y)
	if weapon.canMoveAndAttack or not moved then
		if weapon.minRange <= distance and weapon.maxRange >= distance then
				if weapon.horizontalAndVerticalOnly then
					local xDiff = math.abs(delta.x)
					local yDiff = math.abs(delta.y)
					local maxDiff = weapon.horizontalAndVerticalExtraWidth
					if (xDiff > maxDiff and yDiff > maxDiff) then
							return false
					end
			end

			if weapon.directionality == "omni" then
				return true
			else
				local facingToTarget = self:getFacing({x = 0, y = 0}, delta)
				local aligned = (delta.x == 0) or (delta.y == 0)
				local backFacing = (facing + 2) % 4

				if weapon.directionality == "forward" then
					return aligned and (facing == facingToTarget)
				elseif weapon.directionality == "backwards" then
					return aligned and (backFacing == facingToTarget)
				elseif weapon.directionality == "sideways" then
					return aligned and (facing ~= facingToTarget) and (backFacing ~= facingToTarget)
				else
					return false
				end
			end
		end
	end

	return false
end

function Combat:getBestWeapon(attacker, defender, delta, moved, facing)
	assert(facing ~= nil)

	local weapons = attacker.unitClass.weapons
		for i, weapon in ipairs(weapons) do
		if self:canUseWeapon(weapon, moved, delta, facing) then
			local dmg = Wargroove.getWeaponDamage(weapon, defender, facing)
            if dmg > 0.0001 then
                return weapon, dmg
            end
        end
    end

	return nil, 0.0
end

function Combat:getBaseDamage(attacker, defender, endPos)
	local delta = { x = defender.pos.x - endPos.x, y = defender.pos.y - endPos.y }
	local moved = (attacker.pos.x ~= endPos.x) or (attacker.pos.y ~= endPos.y)
	local weapon, dmg = self:getBestWeapon(attacker, defender, delta, moved, endPos.facing)
	return dmg
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

function Combat:getDamage(attacker, defender, solveType, isCounter, attackerPos, defenderPos, attackerPath, isGroove, grooveWeaponIdOverride)
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
		attackerEffectiveness = 1.0
	else
		effectiveAttacker = attacker
	end

	local passiveMultiplier = self:getPassiveMultiplier(effectiveAttacker, defender, attackerPos, defenderPos, attackerPath, isCounter, attacker.state)

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

		if weapon == nil or (isCounter and not weapon.canMoveAndAttack) or baseDamage < 0.01 then
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

	local damage = self:solveDamage(baseDamage, attackerEffectiveness, defenderEffectiveness, terrainDefenceBonus, randomValue, passiveMultiplier, multiplier)

	local hasPassive = passiveMultiplier > 1.01
	return damage, hasPassive
end

function Combat:solveRound(attacker, defender, solveType, isCounter, attackerPos, defenderPos, attackerPath)
	if (defender.canBeAttacked == false) then
		return nil, false
	end

	local damage, hadPassive = self:getDamage(attacker, defender, solveType, isCounter, attackerPos, defenderPos, attackerPath, nil, false, false)	
	if (damage == nil) then
		return nil, false
	end
	
	local defenderHealth = math.floor(defender.health - damage)
	return defenderHealth, hadPassive
end

function Combat:getGrooveAttackerDamage(attacker, defender, solveType, attackerPos, defenderPos, attackerPath, weaponIdOverride)
	local damage, hadPassive = self:getDamage(attacker, defender, solveType, false, attackerPos, defenderPos, attackerPath, true, weaponIdOverride)
	if (damage == nil) then
		return nil, false
	end

	return damage
end

function Combat:getFacing(a, b)
	local dx = b.x - a.x
	local dy = b.y - a.y
	if math.abs(dx) > math.abs(dy) then
		if dx > 0 then
			return 1
		else
			return 3
		end
	else
		if dy > 0 then
			return 2
		else
			return 0
		end
	end
end

function Combat:getEndPosition(path, startPos)
	if #path == 0 then
		return startPos
	elseif #path == 1 then
		local p = path[#path]
		return {x = p.x, y = p.y, facing = self:getFacing(startPos, p) }
	else
		local p = path[#path]
		return {x = p.x, y = p.y, facing = self:getFacing(path[#path - 1], p) }
	end
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
	attackResult, results.hasAttackerCrit = self:solveRound(attacker, defender, solveType, false, attacker.pos, defender.pos, attackerPath)
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
		defenderResult, results.hasDefenderCrit = self:solveRound(damagedDefender, attacker, solveType, true, defender.pos, attacker.pos, {defender.pos})
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

function Combat:getPassiveMultiplier(attacker, defender, attackerPos, defenderPos, path, isCounter, unitState)
	local condition = self.passiveConditions[attacker.unitClassId]
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

Combat.passiveConditions = PassiveConditions:getPassiveConditions()

return Combat
