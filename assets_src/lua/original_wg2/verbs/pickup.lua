local Wargroove = require "wargroove/wargroove"
local Verb = require "wargroove/verb"
local ItemScores = require "wargroove/item_scores"
local ItemOnPickup = require "wargroove/item_on_pickup"

local Pickup = Verb:new()


function Pickup:getMaximumRange(unit, endPos)
    return 1
end


function Pickup:getTargetType()
    return "item"
end

local function getSurroundingItems(unit, pos)
    local result = {}
    for i, p in ipairs(Wargroove.getTargetsInRange(pos, 1, "item")) do
        local item = Wargroove.getMapItemAt(p)
        if item then
            table.insert(result, item)
        end
    end
    return result
end

function Pickup:getDynamicName(unit, endPos, targetPos)
    if targetPos == nil then
        targetPos = endPos
    end
    local targetUnit = Wargroove.getUnitAt(targetPos)
    if targetUnit then
        return ""
    end

    local itemId = Wargroove.getMapItemIdAt(targetPos.x, targetPos.y)
    if itemId == -1 then
        local items = getSurroundingItems(unit, targetPos)
        local returnVerb = ""
        if #items == 0 then
            return ""
        end

        for _, item in ipairs(items) do
            if not item.isConsumable then
                if not unit.unitClass.isCommander then
                    returnVerb = "ui_unit_verbs_pickup"
                end
            else
                returnVerb = "ui_unit_verbs_activate_item"
            end
        end

        return returnVerb
    end
    
    local mapItem = Wargroove.getMapItemById(itemId)
    if mapItem.isConsumable then
        return "ui_unit_verbs_activate_item"
    else
        if unit.unitClass.isCommander then
            return ""
        else
            return "ui_unit_verbs_pickup"
        end
    end
end

function Pickup:canExecuteWithTarget(unit, endPos, targetPos, strParam)
    if not self:canSeeTarget(targetPos) then
        return false
    end

    local itemId = Wargroove.getMapItemIdAt(targetPos.x, targetPos.y)
    if itemId == -1 then
        return false
    end

    local mapItem = Wargroove.getMapItemById(itemId)

    if unit.itemId ~= "" and not mapItem.isConsumable then
        return false
    end

    if unit.unitClass.isCommander and not mapItem.isConsumable then
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

function Pickup:execute(unit, targetPos, strParam, path)
    print("Item picked up! at " .. targetPos.x .. "," ..targetPos.y)

    local mapItemId = Wargroove.getMapItemIdAt(targetPos.x, targetPos.y)
    local mapItem = Wargroove.getMapItemById(mapItemId)

    -- Call on item pick up sequence
    local onPickup = ItemOnPickup.getOnPickup(Wargroove, mapItem.type)
    if onPickup ~= nil then
        onPickup(Wargroove, unit, targetPos, strParam, path)
    end

    Wargroove.playMapSound("itemEquip", targetPos)
    Wargroove.playItemAnimation(mapItemId, "pickup")
    Wargroove.waitTime(1.25)

    Wargroove.pickupItem(unit, mapItemId)
    Wargroove.waitTime(0.2)
end

function Pickup:generateOrders(unitId, canMove)
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

function Pickup:getScore(unitId, order)
    local item = Wargroove.getMapItemAt(order.targetPosition)

    if item ~= nil then
        return ItemScores.getScoreForItem(item.type, unitId, order)
    end

    return { score = -1, introspection = {} }
end

return Pickup
