local Wargroove = require "wargroove/wargroove"
local ItemVerb = require "wargroove/item_verb"

local Beer = ItemVerb:new()

--still missing sound

local range = 1 --unit must be within this range to receive the effect

function Beer:getMaximumRange(unit, endPos)
    return range
end

function Beer:getTargetType()
    return "all"
end

function Beer:canExecuteWithTarget(unit, endPos, targetPos, strParam)
    if targetPos.x == endPos.x and targetPos.y == endPos.y then
        return true
    end

    local target = Wargroove.getUnitAt(targetPos)

    if not target then
        return false
    end

    if target.isStructure then
        return false
    end

    if target.hadTurn and Wargroove.areAllies(target.playerId, unit.playerId) then
        return true
    end

    return false
end

function Beer:execute(unit, targetPos, strParam, path)
    local target = Wargroove.getUnitAt(targetPos)
    if Wargroove.areAllies(target.playerId, unit.playerId) then
        target.hadTurn = false
        Wargroove.updateUnit(target)
        Wargroove.spawnMapAnimation(target.pos, 0, "fx/reinforce_1", "default", "over_units", { x = 12, y = 0 })
    end
end

function Beer:onPostUpdateUnit(unit, targetPos, strParam, path)
    local target = Wargroove.getUnitAt(targetPos)

    if target == unit then
        unit.hadTurn = false
    end
end

return Beer
