local Wargroove = require "wargroove/wargroove"
local Verb = require "wargroove/verb"
local Combat = require "wargroove/combat"


local Board = Verb:new()

local stateKey = "gold"

function Board:getMaximumRange(unit, endPos)
    local maxRange = 0
    for i, weapon in ipairs(unit.unitClass.weapons) do
        if weapon.canMoveAndAttack or endPos == nil or (endPos.x == unit.pos.x and endPos.y == unit.pos.y) then
            maxRange = math.max(maxRange, weapon.maxRange)
        end
    end

    return maxRange
end


function Board:getTargetType()
    return "unit"
end


function Board:canExecuteAnywhere(unit)
    local weapons = unit.unitClass.weapons
    return #weapons > 0
end


function Board:canExecuteAt(unit, endPos)
    local weapons = unit.unitClass.weapons

    if #weapons == 1 and not weapons[1].canMoveAndAttack then
        local moved = endPos.x ~= unit.startPos.x or endPos.y ~= unit.startPos.y
        if moved then
            return false
        end
    end

    return true
end


function Board:canExecuteWithTarget(unit, endPos, targetPos, strParam)
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
    
    local targetUnit = Wargroove.getUnitAt(targetPos)

    if not targetUnit or not Wargroove.areEnemies(unit.playerId, targetUnit.playerId) then
        return false
    end
	local fakePath = {unit.pos, endPos}
    local results = Combat:solveCombat(unit.id, targetUnit.id, fakePath, "simulationOptimistic")
	if results.defenderHealth > 0 then
		return false
	end
	local function has_value (tab, val)
		for index, value in ipairs(tab) do
			if value == val then
				return true
			end
		end

		return false
	end
	
	if has_value(targetUnit.unitClass.tags,"structure") or targetUnit.unitClass.isCommander == true then
		return false
	end
    return Combat:getBaseDamage(unit, targetUnit, endPos) > 0.001
end


function Board:execute(unit, targetPos, strParam, path)
    --- Telegraph
    if (not Wargroove.isLocalPlayer(unit.playerId)) and Wargroove.canCurrentlySeeTile(targetPos) then
        Wargroove.spawnMapAnimation(targetPos, 0, "ui/grid/selection_cursor", "target", "over_units", {x = -4, y = -4})
        Wargroove.waitTime(0.5)
    end
	local targetUnit = Wargroove.getUnitAt(targetPos)
    local results = Combat:solveCombat(unit.id, targetUnit.id, path, "random")
    if results.defenderHealth <= 0 then
		targetUnit.playerId = unit.playerId;
		unit.health = unit.health*0.5
		targetUnit.hadTurn = true
		targetUnit.health = unit.health
        Wargroove.updateUnit(targetUnit)
    else
		Wargroove.startCombat(unit, targetUnit, path)
	end
	print(dump(path,1))
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

return Board
