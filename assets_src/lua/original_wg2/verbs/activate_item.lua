local Wargroove = require "wargroove/wargroove"
local Verb = require "wargroove/verb"
local ItemScores = require "wargroove/item_scores"
local ItemOnPickup = require "wargroove/item_on_pickup"

local ActivateItem = Verb:new()


function ActivateItem:getMaximumRange(unit, endPos)
    return 1
end


function ActivateItem:getTargetType()
    return "item"
end

function ActivateItem:canExecuteWithTarget(unit, endPos, targetPos, strParam)
    local itemId = Wargroove.getMapItemIdAt(targetPos.x, targetPos.y)
    if itemId == -1 then
        return false
    end
    
    local mapItem = Wargroove.getMapItemById(itemId)
    if not mapItem.isConsumable then
        return false
    end

    if #mapItem.unitTypeRestriction ~= 0 then
        if Wargroove.isInList(unit.unitClassId, mapItem.unitTypeRestriction) then
            return true
        end

        return false
    end

    return true
end

function ActivateItem:execute(unit, targetPos, strParam, path)
    print("Item picked up! at " .. targetPos.x .. "," ..targetPos.y)

    local mapItemId = Wargroove.getMapItemIdAt(targetPos.x, targetPos.y)
    local mapItem = Wargroove.getMapItemById(mapItemId)

    -- Call on item pick up sequence
    local onPickup = ItemOnPickup.getOnPickup(Wargroove, mapItem.type)
    if onPickup ~= nil then
        onPickup(Wargroove, unit, targetPos, strParam, path)
    end

    Wargroove.pickupItem(unit, mapItemId)
    Wargroove.waitTime(0.2)
end

function ActivateItem:generateOrders(unitId, canMove)
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
        local targets = Wargroove.getTargetsInRangeAfterMove(unit, pos, pos, self:getMaximumRange(unit, pos), "item")
        for j, targetPos in pairs(targets) do
            local item = Wargroove.getMapItemAt(targetPos)
            if item ~= nil and self:canExecuteWithTarget(unit, pos, targetPos, "") then
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

function ActivateItem:getScore(unitId, order)
    local item = Wargroove.getMapItemAt(order.targetPosition)

    if item ~= nil then
        return ItemScores.getScoreForItem(item.type, unitId, order)
    end

    return { score = -1, introspection = {} }
end

return ActivateItem
