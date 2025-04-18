local Wargroove = require "wargroove/wargroove"
local GrooveVerb = require "wargroove/groove_verb"


local Diplomacy = GrooveVerb:new()


function Diplomacy:getMaximumRange(unit, endPos)
    return 1
end


function Diplomacy:getTargetType()
    return "unit"
end


function Diplomacy:canExecuteWithTarget(unit, endPos, targetPos, strParam)
    local targetUnit = Wargroove.getUnitAt(targetPos)
    return targetUnit and targetUnit.unitClass.isStructure and Wargroove.areEnemies(unit.playerId, targetUnit.playerId)
end


function Diplomacy:execute(unit, targetPos, strParam, path)
    Wargroove.setIsUsingGroove(unit.id, true)
    Wargroove.updateUnit(unit)

    Wargroove.playUnitAnimation(unit.id, "groove")
    Wargroove.waitTime(1.2)
    Wargroove.playGrooveEffect()
    local endPos = unit.pos
    if path and #path > 0 then
        endPos = path[#path]
    end
    local targetUnit = Wargroove.getUnitAt(targetPos);
    targetUnit:setHealth(100, unit.id)
    targetUnit.playerId = unit.playerId
    Wargroove.updateUnit(targetUnit)
end


function Diplomacy:generateOrders(unitId, canMove)
    local orders = {}

    local unit = Wargroove.getUnitById(unitId)
    local unitClass = Wargroove.getUnitClass(unit.unitClassId)
    local movePositions = {}
    if canMove then
        movePositions = Wargroove.getTargetsInRange(unit.pos, unitClass.moveRange, "empty")
    end
    table.insert(movePositions, unit.pos)

    for i, pos in pairs(movePositions) do
        local targets = Wargroove.getTargetsInRangeAfterMove(unit, pos, pos, 1, "unit")
        for j, targetPos in pairs(targets) do
            local u = Wargroove.getUnitAt(targetPos)
            if u ~= nil then
                local uc = Wargroove.getUnitClass(u.unitClassId)
                if Wargroove.areEnemies(u.playerId, unit.playerId) and uc.isStructure and u.unitClassId ~= "hq" then
                    orders[#orders+1] = {targetPosition = targetPos, strParam = "", movePosition = pos, endPosition = pos}
                end
            end
        end
    end

    return orders
end

function Diplomacy:getScore(unitId, order)
    local unit = Wargroove.getUnitById(unitId)

    local targetUnit = Wargroove.getUnitAt(order.targetPosition)
    local targetUnitClass = Wargroove.getUnitClass(targetUnit.unitClassId)

    local opportunityCost = -1
    local score = targetUnitClass.cost
    local maxScore = 500
    
    local normalizedScore = 2 * score / maxScore + opportunityCost

    return {score = normalizedScore, introspection = {
        {key = "unitCost", value = targetUnitClass.cost},
        {key = "unitHealth", value = targetUnit.health},
        {key = "maxScore", value = maxScore},
        {key = "opportunityCost", value = opportunityCost}}}
end


return Diplomacy
