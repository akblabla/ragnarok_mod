local Wargroove = require "wargroove/wargroove"
local Combat = require "wargroove/combat"
local Attack = require "verbs/attack"

local AttackAI = Attack:new()

function AttackAI:canExecuteAnywhere(unit)
    return not Wargroove.isHuman(unit.playerId)
end

function AttackAI:generateOrders(unitId, canMove)
    local orders = {}
    local unit = Wargroove.getUnitById(unitId)
    if not self:canExecuteAnywhere(unit) then
        return orders
    end

    local unitClass = Wargroove.getUnitClass(unit.unitClassId)
    local movePositions = {}
    if canMove then
        movePositions = Wargroove.getTargetsInRange(unit.pos, unitClass.moveRange, "empty")
    end
    table.insert(movePositions, unit.pos)

    for i, pos in pairs(movePositions) do
        local targets = Wargroove.getTargetsInRangeAfterMove(unit, pos, pos, self:getMaximumRange(unit, pos), "unit")
        for j, targetPos in pairs(targets) do
            local u = Wargroove.getUnitAt(targetPos)
            pos.facing = 1
            if u ~= nil and self:canExecuteWithTarget(unit, pos, targetPos, "") and not Wargroove.hasAIRestriction(u.id, "dont_target_this") then
                table.insert(orders, {
                    targetPosition = targetPos,
                    strParam = "",
                    movePosition = pos,
                    endPosition = pos
                })
            end
        end
    end

    return orders
end

function AttackAI:getScore(unitId, order)
    local unit = Wargroove.getUnitById(unitId)
    local target = Wargroove.getUnitAt(order.targetPosition)
    local attackScore = Wargroove.getUnitState(target, "attackScore")
    local result = Combat:solveCombat(unitId,target.id,{order.endPosition},"average")
    if attackScore ~= nil and attackScore ~= "" then
        if result.attackerHealth<=0 then        
            return {score = 5*tonumber(attackScore)*(target.health-result.defenderHealth)/100, introspection = {}}
        else
            return {score = tonumber(attackScore)*(target.health-result.defenderHealth)/100-(unit.health-result.attackerHealth)/100*unit.unitClass.cost, introspection = {}}
        end
    end
    if target.unitClassId == "travelboat_with_gold" then
        return {score = 1000, introspection = {}}
    end
    return {score = -1, introspection = {}}
end

return AttackAI
