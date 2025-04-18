local Wargroove = require "wargroove/wargroove"
local Verb = require "wargroove/verb"

local OpenTreasure = Verb:new()

function OpenTreasure:getMaximumRange(unit, endPos)
    return 1
end

function OpenTreasure:getTargetType()
    return "unit"
end

function OpenTreasure:canExecuteWithTarget(unit, endPos, targetPos, strParam)
    local targetUnit = Wargroove.getUnitAt(targetPos)
    if targetUnit == nil or targetUnit.unitClassId ~= "treasure" then
        return false
    end

    local opened = Wargroove.getUnitState(targetUnit, "opened")

    if opened and tostring(opened) == "true" then
        return false
    end

    local freeNeighbours = Wargroove.getTargetsInRangeAfterMove(unit, endPos, targetPos, 1, "empty")
    if #freeNeighbours < targetUnit.itemDropNumber then
        return false
    end

    return true
end

function OpenTreasure:execute(unit, targetPos, strParam, path)
    local treasure = Wargroove.getUnitAt(targetPos)
    if not treasure then
        return
    end

    local freeNeighbours = Wargroove.getTargetsInRange(targetPos, 1, "empty")

    Wargroove.playUnitAnimation(treasure.id, "opening", "open")
    Wargroove.waitTime(0.3)
    Wargroove.spawnMapAnimation(treasure.pos, 0, "fx/ransack_1", "default", "over_units", { x = 12, y = 0 })
    Wargroove.playMapSound("thiefGoldObtained", targetPos)
    Wargroove.waitTime(0.3)

    for i=1, treasure.itemDropNumber, 1 do
        local values = { unit.id, unit.unitClassId, unit.pos.x, unit.pos.y, Wargroove.getTurnNumber(), Wargroove.getCurrentPlayerId(), freeNeighbours[i].x, freeNeighbours[i].y }
        local str = ""
        for i, v in ipairs(values) do
            str = str .. tostring(v) .. ":"
        end

        local item = treasure.items[Wargroove.randomInteger(str, 1, #treasure.items)]
        Wargroove.spawnItemAt(item, freeNeighbours[i])
        Wargroove.spawnMapAnimation(freeNeighbours[i], 0, "fx/mapeditor_unitdrop")
        Wargroove.waitTime(0.2)
    end

    Wargroove.setUnitState(treasure, "opened", "true")
    Wargroove.updateUnit(treasure)
end

return OpenTreasure
