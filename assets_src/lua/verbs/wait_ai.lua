local Verb = require "wargroove/verb"
local Wargroove = require "wargroove/wargroove"
local AIManager = require "initialized/ai_manager"

local WaitAI = Verb:new()


function WaitAI:getTargetType()
    return "empty"
end

function WaitAI:canExecuteAnywhere(unit)
    return (not Wargroove.isHuman(unit.playerId))
end

function WaitAI:execute(unit, targetPos, strParam, path)

end

function WaitAI:generateOrders(unitId, canMove)
    local unit = Wargroove.getUnitById(unitId)
    local unitClass = Wargroove.getUnitClass(unit.unitClassId)
    
    local orders = {{targetPosition = unit.pos, strParam = "", movePosition = unit.pos, endPosition = unit.pos}}
    if (not canMove) then
        return orders
    end
    
    local movePositions = Wargroove.getTargetsInRange(unit.pos, unitClass.moveRange, "empty")
    
    for i, targetPos in ipairs(movePositions) do
        if Wargroove.canStandAt(unitClass.id, targetPos) then
            table.insert(orders, {targetPosition = targetPos, strParam = "", movePosition = targetPos, endPosition = targetPos})
        end
    end
    
    return orders
end

function WaitAI:getScore(unitId, order)
    local unit = Wargroove.getUnitById(unitId)
    local target,_ = AIManager.getNextPosition(unitId)
    if (target ~= nil) then
        print("getNextPosition")
        print("target "..tostring(target.x)..", "..tostring(target.y))
        if target.x == order.endPosition.x and target.y == order.endPosition.y then
            return {score = 100, introspection = {}}
        else
            return {score = -1, introspection = {}}
        end
    end
    return {score = -1, introspection = {}}
end

return WaitAI