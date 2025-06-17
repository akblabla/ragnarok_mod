local Wargroove = require "wargroove/wargroove"
local Verb = require "wargroove/verb"
local Ragnarok = require "initialized/ragnarok"

local TakeCrown = Verb:new()

local stateKey = "crown"

function TakeCrown:getMaximumRange(unit, endPos)
    return 1
end

function TakeCrown:getTargetType()
    return "all"
end

function TakeCrown:canExecuteAnywhere(unit)
    return Ragnarok.canHoldCrown(unit)
end

function TakeCrown:canExecuteWithTarget(unit, endPos, targetPos, strParam)
    local crownHolder = Ragnarok.getCrownBearer()
    if crownHolder==nil then
        return false
    end 
    return targetPos.x == crownHolder.pos.x and targetPos.y == crownHolder.pos.y
end

function TakeCrown:execute(unit, targetPos, strParam, path)
    Ragnarok.removeCrown()
    Wargroove.playMapSound("cutscene/throwObject", unit.pos)
    Wargroove.waitTime(0.2)
    Wargroove.updateUnit(unit)
    Wargroove.waitTime(0.4)
    Wargroove.playMapSound("cutscene/land", targetPos)
    Ragnarok.grabCrown(unit)
end

function TakeCrown:generateOrders(unitId, canMove)
    local orders = {}
    local unit = Wargroove.getUnitById(unitId)
    if not self:canExecuteAnywhere(unit) then
        return orders
    end
    if unit.health > 20 then
        return orders
    end
    local crownPos = Ragnarok.getCrownPos()
	if crownPos == nil then return orders end

    local unitClass = Wargroove.getUnitClass(unit.unitClassId)
    local movePositions = {}
    if canMove then
        movePositions = Wargroove.getTargetsInRange(unit.pos, unitClass.moveRange, "empty")
    end
    table.insert(movePositions, unit.pos)

    for i, pos in pairs(movePositions) do
        local dist = math.abs(pos.x-crownPos.x)+math.abs(pos.y-crownPos.y)
        if dist<=self:getMaximumRange(unit, pos) and self:canExecuteWithTarget(unit, pos, crownPos, "") then
            table.insert(orders, {
                targetPosition = crownPos,
                strParam = "",
                movePosition = pos,
                endPosition = pos
            })
        end
    end

    return orders
end

function TakeCrown:getScore(unitId, order)
    return {score = 200, introspection = {}}
end

return TakeCrown
