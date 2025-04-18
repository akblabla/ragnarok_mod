local Wargroove = require "wargroove/wargroove"
local Verb = require "wargroove/verb"

local ActivateDungeonToggle = Verb:new()

function ActivateDungeonToggle:getMaximumRange(unit, endPos)
    return 1
end

function ActivateDungeonToggle:getTargetType()
    return "unit"
end

function ActivateDungeonToggle:canExecuteWithTarget(unit, endPos, targetPos, strParam)
    local targetUnit = Wargroove.getUnitAt(targetPos)
    if targetUnit == nil or targetUnit.unitClassId ~= "dungeon_toggle" then
        return false
    end

    local activated = Wargroove.getUnitState(targetUnit, "activated")

    if activated and tostring(activated) == "true" then
        return false
    end

    return true
end

function ActivateDungeonToggle:execute(unit, targetPos, strParam, path)
    local targetUnit = Wargroove.getUnitAt(targetPos)
    if not targetUnit then
        return
    end

    Wargroove.playUnitAnimation(targetUnit.id, "idle", "open")
    Wargroove.setMapFlag(targetUnit.attachedFlagId, true)

    Wargroove.setUnitState(targetUnit, "activated", "true")
    Wargroove.updateUnit(targetUnit)
end

return ActivateDungeonToggle
