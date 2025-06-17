local Wargroove = require "wargroove/wargroove"
local OldPickup = require "verbs/pickup"
local ItemScores = require "wargroove/item_scores"
local ItemOnPickup = require "wargroove/item_on_pickup"

local Pickup = {}
function Pickup.init()
	OldPickup.getDynamicName = Pickup.getDynamicName
	OldPickup.canExecuteWithTarget = Pickup.canExecuteWithTarget
	
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
                if not (unit.unitClass.isCommander and not (item.type == "crown")) then
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
        if (unit.unitClass.isCommander and not (mapItem.type == "crown")) then
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

    if (unit.unitClass.isCommander and not (mapItem.type == "crown")) and not mapItem.isConsumable then
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

return Pickup
