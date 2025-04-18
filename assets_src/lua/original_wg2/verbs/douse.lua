local Wargroove = require "wargroove/wargroove"
local Verb = require "wargroove/verb"


local Douse = Verb:new()


function Douse:getMaximumRange(unit, endPos)
    return 1
end


function Douse:getTargetType()
    return "all"
end

function Douse:canExecuteWithTarget(unit, endPos, targetPos, strParam)
    
    if endPos.x == targetPos.x and endPos.y == targetPos.y then
        -- self douse special case
        local isBurning = Wargroove.getUnitState(unit, "burning")
        if isBurning == "true" then
            return true
        end
    else
        local target = Wargroove.getUnitAt(targetPos)
        if target == nil then
            return false
        end
    
        local isBurning = Wargroove.getUnitState(target, "burning")
        if isBurning == "true" and Wargroove.areAllies(target.playerId, unit.playerId) then
            return true
        end
    end

    return false
end

function Douse:execute(unit, targetPos, strParam, path)
    local target = Wargroove.getUnitAt(targetPos)

    if target == nil then
        target = unit
    end
    
    Wargroove.spawnMapAnimation(target.pos, 1, Wargroove.getSplashEffect())

    Wargroove.setUnitState(target, "burning", "false")
    Wargroove.clearBuffVisualEffect(target.id)
    Wargroove.updateUnit(target)

    Wargroove.waitTime(0.1)
end

function Douse:generateOrders(unitId, canMove)
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
        local targets = Wargroove.getTargetsInRangeAfterMove(unit, pos, pos, self:getMaximumRange(unit, pos), "all")
        for j, targetPos in pairs(targets) do
            if self:canExecuteWithTarget(unit, pos, targetPos, "") then
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

function Douse:getScore(unitId, order)
    local unit = Wargroove.getUnitAt(order.targetPosition)

    if unit then
        -- The lower the units health, the higher the chance
        local gainScore = unit.unitClass.maxHealth - unit.health
        local maxScore = unit.unitClass.maxHealth

        local score = gainScore/maxScore

        return {score = score, introspection = {}}
    else
        return {score = -1, introspection = {}}
    end
end

return Douse