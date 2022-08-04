local Wargroove = require "wargroove/wargroove"
local OldAttack = require "verbs/attack"
local Combat = require "wargroove/combat"
local Ragnarok = require "initialized/ragnarok"


local Attack = {}
local OldAttackGetScore;
function Attack.init()
	OldAttack.canExecuteWithTarget = Attack.canExecuteWithTarget
	--OldAttackGetScore = OldAttack.getScore
	--OldAttack.getScore = Attack.getScore
	
end

function dump(o,level)
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

local function bruteForceCheckIfVisibleInStealthyTile(playerId, targetPos)
	if Wargroove.canPlayerSeeTile(playerId, targetPos) == false then
		return false
	end
	local terrainName = Wargroove.getTerrainNameAt(targetPos)
	if terrainName and (terrainName == "forest" or terrainName == "reef" or terrainName == "forest_alt") then
		local maxDist = 6
		for yOffset = -maxDist, maxDist do
			for xOffset = -maxDist, maxDist do
				local x = targetPos.x + xOffset
				local y = targetPos.y + yOffset
				local spotterUnit = Wargroove.getUnitAtXY(x, y)
				local dist = math.abs(xOffset) + math.abs(yOffset)
				if spotterUnit then
					if Wargroove.areAllies(playerId, spotterUnit.playerId) then
						if dist <= 6 and (spotterUnit.unitClassId == "dog" or Wargroove.getTerrainNameAt(spotterUnit.pos) == "mountain") then
							return true
						end
						if dist <= 5 and (spotterUnit.unitClassId == "flare") then
							return true
						end
						if dist <= 4 and (spotterUnit.unitClassId == "dog" or spotterUnit.unitClassId == "turtle") then
							return true
						end
						if dist <= 1 then
							return true
						end
					end
				end
			end
		end
		return false
	else
		return true
	end
end

function Attack:canExecuteWithTarget(unit, endPos, targetPos, strParam)
    if not self:canSeeTarget(targetPos) then
        return false
    end

    local weapons = unit.unitClass.weapons
    if #weapons == 1 and weapons[1].horizontalAndVerticalOnly then
        local moved = endPos.x ~= unit.startPos.x or endPos.y ~= unit.startPos.y
        local xDiff = math.abs(endPos.x - targetPos.x)
        local yDiff = math.abs(endPos.y - targetPos.y)
        local maxDiff = weapons[1].horizontalAndVerticalExtraWidth
        if (xDiff > maxDiff and yDiff > maxDiff) then
            return false
        end
    end

    local targetTerrain = Wargroove.getTerrainNameAt(targetPos)
    if #weapons == 1 and #(weapons[1].terrainExclusion) > 0 then
        for i, terrain in ipairs(weapons[1].terrainExclusion) do
            if targetTerrain == terrain then
                return false
            end
        end
    end
    local targetUnit = Wargroove.getUnitAt(targetPos)
	if bruteForceCheckIfVisibleInStealthyTile(unit.playerId, targetPos) == false then
		return false
	end
    if not targetUnit or not Wargroove.areEnemies(unit.playerId, targetUnit.playerId) then
        return false
    end

    if targetUnit.canBeAttacked ~= nil and not targetUnit.canBeAttacked then
      return false
    end

	if Ragnarok.cantAttackBuildings(unit.playerId) and targetUnit.unitClass.isStructure then
		return false
	end
	if Ragnarok.hasCrown(unit) then return false end
	local isGround = false
	for i, tag in ipairs(unit.unitClass.tags) do
		for i, groundTag in ipairs(Ragnarok.groundTags) do
			if tag == groundTag then
				isGround = true
			end
		end
	end
	local targetInSea = false
	
	for i, terrain in ipairs(Ragnarok.seaTiles) do
		if targetTerrain == terrain then
			targetInSea = true
		end
	end
	if targetInSea and isGround and #weapons == 1 and weapons[1].maxRange == 1 then
		for i, tag in ipairs(targetUnit.unitClass.tags) do
			if tag == "type.sea" or tag == "type.amphibious" then
				return false
			end
		end
	end
	local fakePath = {unit.pos, endPos}
    local results = Combat:solveCombat(unit.id, targetUnit.id, fakePath, "simulationOptimistic")
	local relativeValue = (targetUnit.unitClass.cost*(targetUnit.health-results.defenderHealth))/(unit.unitClass.cost*(unit.health-results.attackerHealth))
	if relativeValue < 1 and Ragnarok.cantAttackBuildings(unit.playerId) then
		return false
	end
    

    return Combat:getBaseDamage(unit, targetUnit, endPos) > 0.001
end

function Attack:getScore(unitId, order)
    local targetUnit = Wargroove.getUnitAt(order.targetPosition)

    local result = OldAttackGetScore(unitId, order)
	if targetUnit and targetUnit.unitClass.isStructure then
		result.score = -1000
	end
    return { score = myDelta, healthDelta = 0, introspection = {
        { key = "amountToTake", value = amountToTake },
        { key = "oldUnitValue", value = oldUnitValue },
        { key = "newUnitValue", value = newUnitValue }}}
end

return Attack
