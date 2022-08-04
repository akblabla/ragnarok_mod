local Wargroove = require "wargroove/wargroove"
local OldCombat = require "wargroove/combat"
local PassiveConditions = require "wargroove/passive_conditions"
local Ragnarok = require "initialized/ragnarok"


--
local defencePerShield = 0.10
local damageAt0Health = 0.1
local damageAt100Health = 1.0
local randomDamageMin = 0.0
local randomDamageMax = 0.1
--

local Combat = {}

-- This is called by the game when the map is loaded.
function Combat.init()
  OldCombat.solveDamage = Combat.solveDamage
  OldCombat.getDamage = Combat.getDamage
  OldCombat.solveCombat = Combat.solveCombat
  OldCombat.getBestWeapon = Combat.getBestWeapon
  OldCombat.canUseWeapon = Combat.canUseWeapon
  OldCombat.getResults = Combat.getResults
end

function Combat:solveDamage(weaponDamage, attackerEffectiveness, defenderEffectiveness, terrainDefenceBonus, randomValue, multiplier)
	local randomBonus = randomDamageMin + (randomDamageMax - randomDamageMin) * randomValue

	local offence = weaponDamage + randomBonus
	local defence = defenderEffectiveness * math.max(0, terrainDefenceBonus) - math.max(0, -terrainDefenceBonus)
	local damage = attackerEffectiveness * offence * (1.0 - defence) * multiplier

	return math.max(math.floor(100 * damage + 0.5), 1)
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
	--I changed stuff here
	--local attackerHealthModfier = math.ceil(math.max(attackerHealth-5,10) * 0.1)*0.1
	--local defenderHealthModfier = math.ceil(math.max(defender.health-5,10) * 0.1)*0.1
	local attackerHealthModfier = attackerHealth*0.01
	local defenderHealthModfier = defender.health*0.01
	local attackerEffectiveness = attackerHealthModfier * (damageAt100Health - damageAt0Health) + damageAt0Health
	local defenderEffectiveness = defenderHealthModfier * (damageAt100Health - damageAt0Health) + damageAt0Health

	
	

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
			state = attacker.state
		}
		--attackerEffectiveness = math.min(attackerEffectiveness*2,1.0)
	else
		effectiveAttacker = attacker
	end

	local passiveMultiplier = self:getPassiveMultiplier(effectiveAttacker, defender, attackerPos, defenderPos, attackerPath, isCounter, attacker.state)
	attackerEffectiveness = attackerEffectiveness * passiveMultiplier
	
	--Units can't attack while holding the crown. Thank you Skydorm for the suggestion
--	Wargroove.popUnitPos()
	if Ragnarok.hasCrown(attacker) then return nil, false end
	-- local e0 = self:getEndPosition(attackerPath, attacker.pos)
	-- Wargroove.pushUnitPos(attacker, e0)

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
	local weapon, baseDamage
	if (isGroove) then
		if (grooveWeaponIdOverride ~= nil) then
			weapon = grooveWeaponIdOverride
			baseDamage = Wargroove.getWeaponDamageForceGround(weapon, defender)
		else
			weapon = attacker.unitClass.weapons[1].id
			baseDamage = Wargroove.getWeaponDamageForceGround(weapon, defender)
		end
	else	
		weapon, baseDamage = self:getBestWeapon(effectiveAttacker, defender, delta, moved, attackerPos.facing)
	end
	
	
	local isGround = false
	for i, tag in ipairs(attacker.unitClass.tags) do
		for i, groundTag in ipairs(Ragnarok.groundTags) do
			if tag == groundTag then
				isGround = true
			end
		end
	end
    local defenderTerrain = Wargroove.getTerrainNameAt(defenderPos)
	local defenderInSea = false
	
	for i, terrain in ipairs(Ragnarok.seaTiles) do
		if defenderTerrain == terrain then
			defenderInSea = true
		end
	end
	if defenderInSea and isGround and weapon and weapon.maxRange == 1 then
		for i, tag in ipairs(defender.unitClass.tags) do
			if tag == "type.sea" then
				return nil,false
			end
		end
	end
	
	if weapon == nil or (isCounter and not weapon.canMoveAndAttack) or (Ragnarok.cantAttackBuildings(attacker.playerId) and defender.unitClass.isStructure) or baseDamage < 0.01 then
		return nil, false
	end

	local multiplier = 1.0
	if Wargroove.isHuman(defender.playerId) then
		multiplier = Wargroove.getDamageMultiplier()

		-- If the player is on "easy" for damage, make the AI overlook that.
		if multiplier < 1.0 and solveType == "aiSimulation" then
			multiplier = 1.0
		end
	end

	local damage = self:solveDamage(baseDamage, attackerEffectiveness, defenderEffectiveness, terrainDefenceBonus, randomValue, multiplier)

	local hasPassive = passiveMultiplier > 1.01
	return damage, hasPassive
end

function Combat:canUseWeapon(defender, weapon, moved, delta, facing)
	local distance = math.abs(delta.x) + math.abs(delta.y)
    if #(weapon.terrainExclusion) > 0 then
        local targetTerrain = Wargroove.getTerrainNameAt(defender.pos)
        for i, terrain in ipairs(weapon.terrainExclusion) do
            if targetTerrain == terrain then
                return false
            end
        end
    end
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
      if self:canUseWeapon(defender, weapon, moved, delta, facing) then
				local dmg = Wargroove.getWeaponDamage(weapon, defender, facing)
            if dmg > 0.0001 then
                return weapon, dmg
            end
        end
    end

	return nil, 0.0
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
	return results
end

function Combat:getResults()
	return results;
end

return Combat