local Wargroove = require "wargroove/wargroove"
local Verb = require "wargroove/verb"
local Ragnarok = require "initialized/ragnarok"

local handOverCrown = Verb:new()

local stateKey = "crown"

function handOverCrown:getMaximumRange(unit, endPos)
	return 1
end

function handOverCrown:getTargetType()
    return "unit"
end

function handOverCrown:canExecuteAnywhere(unit)
    local crown = Wargroove.getUnitState(unit, stateKey)
    return crown ~= nil
end

function handOverCrown:canExecuteWithTarget(unit, endPos, targetPos, strParam)    
    local targetUnit = Wargroove.getUnitAt(targetPos)
	local isCorrectType = false
	if targetUnit then
		for i, tag in ipairs(targetUnit.unitClass.tags) do
			if tag == "type.ground.light" or tag == "type.amphibious" or tag == "knight"  or tag == "giant"  then
				isCorrectType = true
			end
		end
	end
    return targetUnit and isCorrectType and Wargroove.areAllies(unit.playerId, targetUnit.playerId) and not targetUnit.isStructure and not (endPos.x == targetPos.x and endPos.y == targetPos.y)
end

local crownAnimation = "ui/icons/fx_crown"
function handOverCrown:execute(unit, targetPos, strParam, path)
    local targetUnit = Wargroove.getUnitAt(targetPos)
    Ragnarok.removeCrown()
    Wargroove.waitTime(0.2)
    Wargroove.playMapSound("thiefGoldReleased", targetPos)
    Wargroove.spawnMapAnimation(unit.pos, 0, "fx/ransack_1", "default", "over_units", { x = 12, y = 0 })
    Wargroove.updateUnit(unit)
    Wargroove.waitTime(1.0)
    Wargroove.spawnMapAnimation(targetPos, 0, "fx/ransack_2", "default", "over_units", { x = 12, y = 0 })
    Wargroove.waitTime(0.2)
    Wargroove.playMapSound("thiefDeposit", targetPos)
    Wargroove.waitTime(0.4)
    Ragnarok.grabCrown(targetUnit)
end

return handOverCrown
