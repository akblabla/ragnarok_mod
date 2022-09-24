local Wargroove = require "wargroove/wargroove"
local OldCombat = require "wargroove/combat"
local PassiveConditions = require "wargroove/passive_conditions"
local Ragnarok = require "initialized/ragnarok"
local Stats = require "util/stats"


--
local defencePerShield = 0.10
local damageAt0Health = 0.1
local damageAt100Health = 1.0
local randomDamageMin = -0.05
local randomDamageMax = 0.05
--

local Combat = {}

-- This is called by the game when the map is loaded.
function Combat.init()
  OldCombat.getDamage = Combat.getDamage
  OldCombat.solveDamage = Combat.solveDamage
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
	else
		effectiveAttacker = attacker
	end
	if not isGroove and (Stats.meleeUnits[effectiveAttacker.unitClassId] ~= nil and not Wargroove.canStandAt(effectiveAttacker.unitClassId, defender.pos)) then
		return nil, false
	end
	if Ragnarok.hasCrown(effectiveAttacker) then return nil, false end
	
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
	if effectiveAttacker.unitClassId == "harpoonship" and (not Wargroove.canStandAt(effectiveAttacker.unitClassId, defender.pos)) and (not defenderIsInAir) then
		attackerEffectiveness = attackerEffectiveness*0.5
	end
	local damage = self:solveDamage(baseDamage, attackerEffectiveness, defenderEffectiveness, terrainDefenceBonus, randomValue, passiveMultiplier, multiplier)

	local hasPassive = passiveMultiplier > 1.01
	return damage, hasPassive
end

-- function Combat:getDamage(attacker, defender, solveType, isCounter, attackerPos, defenderPos, attackerPath, isGroove, grooveWeaponIdOverride)
	-- if type(solveType) ~= "string" then
		-- error("solveType should be a string. Value is " .. tostring(solveType))
	-- end
	-- local delta = {x = defenderPos.x - attackerPos.x, y = defenderPos.y - attackerPos.y }
	-- local moved = attackerPath and #attackerPath > 1

	-- local randomValue = 0.5
	-- if solveType == "random" and Wargroove.isRNGEnabled() then
		-- local values = { attacker.id, attacker.unitClassId, attacker.startPos.x, attacker.startPos.y, attackerPos.x, attackerPos.y,
		                 -- defender.id, defender.unitClassId, defender.startPos.x, defender.startPos.y, defenderPos.x, defenderPos.y,
						 -- isCounter, Wargroove.getTurnNumber(), Wargroove.getCurrentPlayerId() }
		-- local str = ""
		-- for i, v in ipairs(values) do
			-- str = str .. tostring(v) .. ":"
		-- end
		-- randomValue = Wargroove.pseudoRandomFromString(str)
	-- end
	-- if solveType == "simulationOptimistic" then
		-- if isCounter then
			-- randomValue = 0
		-- else
			-- randomValue = 1
		-- end
	-- end
	-- if solveType == "simulationPessimistic" then
		-- if isCounter then
			-- randomValue = 1
		-- else
			-- randomValue = 0
		-- end
	-- end

	-- local attackerHealth = isGroove and 100 or attacker.health
	-- local attackerEffectiveness = attackerHealth * (damageAt100Health - damageAt0Health) + damageAt0Health
	-- attackerEffectiveness = math.max(0.1,attackerEffectiveness)
	-- local defenderEffectiveness = defender.health * (damageAt100Health - damageAt0Health) + damageAt0Health
	-- defenderEffectiveness = math.max(0.1,defenderEffectiveness)

	-- -- For structures, check if there's a garrison; if so, attack as if it was that instead
	-- local effectiveAttacker
	-- if attacker.garrisonClassId ~= '' then
		-- effectiveAttacker = {
			-- id = attacker.id,
			-- pos = attacker.pos,
			-- startPos = attacker.startPos,
			-- playerId = attacker.playerId,
			-- unitClassId = attacker.garrisonClassId,
			-- unitClass = Wargroove.getUnitClass(attacker.garrisonClassId),
			-- health = attackerHealth,
			-- state = attacker.state,
			-- damageTakenPercent = attacker.damageTakenPercent
		-- }
		-- attackerEffectiveness = 1.0
	-- else
		-- effectiveAttacker = attacker
	-- end

	-- if not isGroove and (Stats.meleeUnits[effectiveAttacker.unitClassId] ~= nil and not Wargroove.canStandAt(effectiveAttacker.unitClassId, defender.pos)) then
		-- return nil, false
	-- end
	-- if Ragnarok.hasCrown(effectiveAttacker) then return nil, false end
	-- local passiveMultiplier = self:getPassiveMultiplier(effectiveAttacker, defender, attackerPos, defenderPos, attackerPath, isCounter, attacker.state)

	-- local defenderUnitClass = Wargroove.getUnitClass(defender.unitClassId)
	-- local defenderIsInAir = defenderUnitClass.inAir
	-- local defenderIsStructure = defenderUnitClass.isStructure

	-- local terrainDefence
	-- if defenderIsInAir then
		-- terrainDefence = Wargroove.getSkyDefenceAt(defenderPos)
	-- elseif defenderIsStructure then
		-- terrainDefence = 0
	-- else
		-- terrainDefence = Wargroove.getTerrainDefenceAt(defenderPos)
	-- end

	-- local terrainDefenceBonus = terrainDefence * defencePerShield

	-- local baseDamage
	-- if (isGroove) then
		-- local weaponId
		-- if (grooveWeaponIdOverride ~= nil) then
			-- weaponId = grooveWeaponIdOverride
		-- else
			-- weaponId = attacker.unitClass.weapons[1].id
		-- end
		-- baseDamage = Wargroove.getWeaponDamageForceGround(weaponId, defender)
	-- else	
		-- local weapon
		-- weapon, baseDamage = self:getBestWeapon(effectiveAttacker, defender, delta, moved, attackerPos.facing)

		-- if weapon == nil or (isCounter and not weapon.canMoveAndAttack) or baseDamage < 0.01 then
			-- return nil, false
		-- end

		-- if #(weapon.terrainExclusion) > 0 then
			-- local targetTerrain = Wargroove.getTerrainNameAt(defenderPos)
			-- for i, terrain in ipairs(weapon.terrainExclusion) do
				-- if targetTerrain == terrain then
					-- return nil, false
				-- end
			-- end
		-- end
	-- end

	-- local multiplier = 1.0
	-- if Wargroove.isHuman(defender.playerId) then
		-- multiplier = Wargroove.getDamageMultiplier()

		-- -- If the player is on "easy" for damage, make the AI overlook that.
		-- if multiplier < 1.0 and solveType == "aiSimulation" then
			-- multiplier = 1.0
		-- end
	-- end

	-- -- Damage reduction
	-- multiplier = multiplier * defender.damageTakenPercent / 100

	-- local damage = self:solveDamage(baseDamage, attackerEffectiveness, defenderEffectiveness, terrainDefenceBonus, randomValue, passiveMultiplier, multiplier)

	-- local hasPassive = passiveMultiplier > 1.01
	-- return damage, hasPassive
-- end

return Combat