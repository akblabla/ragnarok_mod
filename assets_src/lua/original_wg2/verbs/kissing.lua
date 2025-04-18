local Wargroove = require "wargroove/wargroove"
local Verb = require "wargroove/verb"

local Kissing = Verb:new()

function Kissing:getMaximumRange(unit, endPos)
    return 1
end

function Kissing:getTargetType()
    return "unit"
end

function Kissing:canExecuteWithTarget(unit, endPos, targetPos, strParam)
    local target = Wargroove.getUnitAt(targetPos)
    if not target or target.id == unit.id then
        return false
    end

    local uc = Wargroove.getUnitClass(target.unitClassId)
    if not uc.isCommander then
        return false
    end

    return true
end

function Kissing:getFacing(unit, target)
    if (unit.x < target.x) then
        return "right"
    elseif (unit.x > target.x) then
        return "left"
    else
        return ""
    end
end

function Kissing:execute(unit, targetPos, strParam, path)
    local facing = self:getFacing(unit.pos, targetPos)
    if (facing ~= "") then
        Wargroove.setFacingOverride(unit.id, facing)
    end

    local target = Wargroove.getUnitAt(targetPos)
    facing = self:getFacing(targetPos, unit.pos)
    if (facing ~= "") then
        Wargroove.setFacingOverride(target.id, facing)
    end

    Wargroove.spawnMapAnimation(unit.pos, 0, "fx/kiss_unit")
    Wargroove.spawnMapAnimation(targetPos, 0, "fx/kiss_unit")
    Wargroove.playMapSound("kissing", unit.pos)
    Wargroove.waitTime(0.5)
end

function Kissing:onPostUpdateUnit(unit, targetPos, strParam, path)
    unit.hadTurn = false
end

return Kissing