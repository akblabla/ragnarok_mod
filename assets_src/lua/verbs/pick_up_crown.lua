local Wargroove = require "wargroove/wargroove"
local Verb = require "wargroove/verb"
local Ragnarok = require "initialized/ragnarok"

local handOverCrown = Verb:new()

local stateKey = "crown"

function handOverCrown:getMaximumRange(unit, endPos)
	if unit.unitClass.id == "commander_vesper" then return 2 end
    return 1
end

function handOverCrown:getTargetType()
    return "all"
end

function handOverCrown:canExecuteAnywhere(unit)
    local crown = Wargroove.getUnitState(unit, stateKey)
    return crown == nil
end

function handOverCrown:canExecuteWithTarget(unit, endPos, targetPos, strParam)    
	local crownPosition = Ragnarok.getCrownPos()
	if crownPosition == nil then return false end
    return targetPos.x == crownPosition.x and targetPos.y == crownPosition.y
end

local crownAnimation = "ui/icons/fx_crown"
function handOverCrown:execute(unit, targetPos, strParam, path)
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
    Ragnarok.grabCrown(unit)
end

return handOverCrown
