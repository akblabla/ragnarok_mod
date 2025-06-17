local Wargroove = require "wargroove/wargroove"
local OldPickup = require "verbs/pickup"
local ItemScores = require "wargroove/item_scores"


local Pickup = {}
function Pickup.init()
	OldPickup.generateOrders = Pickup.generateOrders
	
end

function Pickup:generateOrders(unitId, canMove)
    local orders = {}
    local unit = Wargroove.getUnitById(unitId)
    if not OldPickup:canExecuteAnywhere(unit) then
        return orders
    end

    local unitClass = Wargroove.getUnitClass(unit.unitClassId)
    local movePositions = {}
    if canMove then
        movePositions = Wargroove.getTargetsInRange(unit.pos, unitClass.moveRange, "empty")
    end
    table.insert(movePositions, unit.pos)

    for i, pos in pairs(movePositions) do
        local targets = Wargroove.getTargetsInRangeAfterMove(unit, pos, pos, OldPickup:getMaximumRange(unit, pos), "item")
        for j, targetPos in pairs(targets) do
            local item = Wargroove.getMapItemAt(targetPos)
            if item ~= nil and OldPickup:canExecuteWithTarget(unit, pos, targetPos, "") then
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

function Pickup:getScore(unitId, order)
    local item = Wargroove.getMapItemAt(order.targetPosition)

    if item ~= nil then
        return ItemScores.getScoreForItem(item.type, unitId, order)
    end

    return { score = -1, introspection = {} }
end

return Pickup
