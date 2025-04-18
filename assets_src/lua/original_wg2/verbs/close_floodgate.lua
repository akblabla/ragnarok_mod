local Wargroove = require "wargroove/wargroove"
local Verb = require "wargroove/verb"

local CloseFloodgate = Verb:new()

function CloseFloodgate:getMaximumRange(unit, endPos)
    return 1
end

function CloseFloodgate:getTargetType()
    return "unit"
end

function CloseFloodgate:canExecuteWithTarget(unit, endPos, targetPos, strParam)
    local targetUnit = Wargroove.getUnitAt(targetPos)
    if targetUnit == nil or targetUnit.unitClassId ~= "floodgate" then
        return false
    end

    local opened = Wargroove.getUnitState(targetUnit, "opened")

    if opened and tostring(opened) == "true" then
        return false
    end

    return true
end

function CloseFloodgate:execute(unit, targetPos, strParam, path)
    local targetUnit = Wargroove.getUnitAt(targetPos)
    if not targetUnit then
        return
    end

    Wargroove.playUnitAnimation(targetUnit.id, "idle", "open")
    Wargroove.setMapFlag(targetUnit.attachedFlagId, true)

    Wargroove.setUnitState(targetUnit, "opened", "true")
    Wargroove.updateUnit(targetUnit)
end

return CloseFloodgate
