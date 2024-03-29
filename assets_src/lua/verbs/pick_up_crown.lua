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
    Wargroove.playMapSound("cutscene/throwObject", unit.pos)
    Wargroove.waitTime(0.2)
    Wargroove.updateUnit(unit)
    Wargroove.waitTime(0.4)
    Wargroove.playMapSound("cutscene/land", targetPos)
    Ragnarok.grabCrown(unit)
end

function handOverCrown:generateOrders(unitId, canMove)
    local unit = Wargroove.getUnitById(unitId)
    return {}
end

function handOverCrown:getScore(unitId, order)
    local unit = Wargroove.getUnitById(unitId)
    return {score = -1, introspection = {}}
end

return handOverCrown
