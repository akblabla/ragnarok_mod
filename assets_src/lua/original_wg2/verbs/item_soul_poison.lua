local Wargroove = require "wargroove/wargroove"
local ItemVerb = require "wargroove/item_verb"

local SoulPoison = ItemVerb:new()

function SoulPoison:getMaximumRange(unit, endPos)
    return 1
end

function SoulPoison:getTargetType()
    return "unit"
end

function SoulPoison:canExecuteWithTarget(unit, endPos, targetPos, strParam)
    local target = Wargroove.getUnitAt(targetPos)

    if not target then
        return false
    end

    if target.isStructure then
        return false
    end

    if target.unitClass.isCommander then
        return false
    end

    if Wargroove.areEnemies(target.playerId, unit.playerId) then
        return true
    end

    return false
end

function SoulPoison:execute(unit, targetPos, strParam, path)
    local target = Wargroove.getUnitAt(targetPos)

    Wargroove.spawnMapAnimation(targetPos, 0, "fx/drain_unit", "default", "over_units", { x = 12, y = 12})

    Wargroove.waitTime(0.8)

    Wargroove.spawnMapAnimation(targetPos, 0, "fx/mapeditor_unitdrop")
    Wargroove.playMapSound("spawn", targetPos)

    Wargroove.waitTime(0.2)

    target.playerId = unit.playerId
    target.hadTurn = true
    Wargroove.updateUnit(target)
end

return SoulPoison