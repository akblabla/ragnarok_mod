local Wargroove = require "wargroove/wargroove"
local Verb = require "wargroove/verb"

local DispenseItem = Verb:new()

DispenseItem.target = nil
DispenseItem.item = nil

function DispenseItem:getMaximumRange(unit, endPos)
    return 1
end

function DispenseItem:getTargetType()
    return "all"
end

function DispenseItem:preExecute(unit, targetPos, strParam, endPos)
    Wargroove.openItemPickMenu(unit.playerId, unit.items)
    while Wargroove.itemPickMenuIsOpen() do
        coroutine.yield()
    end

    DispenseItem.item = Wargroove.popItemPickedClass();
    if DispenseItem.item == nil then
        return false, ""
    end

    Wargroove.selectTarget()
    while Wargroove.waitingForSelectedTarget() do
        coroutine.yield()
    end

    DispenseItem.target = Wargroove.getSelectedTarget()
    if (DispenseItem.target == nil) then
        DispenseItem.item = nil
        return false, ""
    end

    return true, ""
end

function DispenseItem:canExecuteAnywhere(unit)
    local dispensed = Wargroove.getUnitState(unit, "itemsDispensed")
    if dispensed and tonumber(dispensed) >= unit.itemDropNumber then
         return false
    end

    return true
end

function DispenseItem:canExecuteAt(unit, endPos)
    local dispensed = Wargroove.getUnitState(unit, "itemsDispensed")
    if dispensed and tonumber(dispensed) >= unit.itemDropNumber then
        return false
    end

    local freeNeighbours = Wargroove.getTargetsInRangeAfterMove(unit, endPos, endPos, 1, "empty")
    if #freeNeighbours == 0 then
        return false
    end

    return true
end

function DispenseItem:canExecuteWithTarget(unit, endPos, targetPos, strParam)
    if not self:canSeeTarget(targetPos) then
        return false
    end

    return (endPos.x ~= targetPos.x or endPos.y ~= targetPos.y) and (u == nil or unit.id == u.id) and Wargroove.canStandAt("soldier", targetPos)
end

function DispenseItem:execute(unit, targetPos, strParam, path)
    Wargroove.spawnMapAnimation(unit.pos, 0, "fx/ransack_1", "default", "over_units", { x = 12, y = 0 })
    Wargroove.playMapSound("thiefGoldObtained", targetPos)
    Wargroove.waitTime(0.3)

    Wargroove.spawnItemAt(DispenseItem.item, DispenseItem.target)
    Wargroove.spawnMapAnimation(DispenseItem.target, 0, "fx/mapeditor_unitdrop")
    Wargroove.waitTime(0.2)

    local dispensed = Wargroove.getUnitState(unit, "itemsDispensed")
    if not dispensed then
        dispensed = 0
    else 
        dispensed = tonumber(dispensed)
    end

    Wargroove.setUnitState(unit, "itemsDispensed", dispensed + 1)
    Wargroove.updateUnit(unit)
    DispenseItem.target = nil
    DispenseItem.item = nil
end

return DispenseItem
