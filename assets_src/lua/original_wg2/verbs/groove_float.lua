local Wargroove = require "wargroove/wargroove"
local GrooveVerb = require "wargroove/groove_verb"
local Combat = require "wargroove/combat"

local Float = GrooveVerb:new()


function Float:getMaximumRange(unit, endPos)
    return 0
end


function Float:getTargetType()
    return "all"
end


function Float:canExecuteWithTarget(unit, endPos, targetPos, strParam)
    if not self:canSeeTarget(targetPos) then
        return false
    end

    local u = Wargroove.getUnitAt(targetPos)
    local uc = Wargroove.getUnitClass("soldier")
    return (u == nil or u.id == unit.id) and Wargroove.canStandAt("harpy", targetPos)
end


function Float:execute(unit, targetPos, strParam, path)
    Wargroove.setIsUsingGroove(unit.id, true)
    Wargroove.updateUnit(unit)

    Wargroove.playUnitAnimation(unit.id, "groove")
    Wargroove.playMapSound("valder/valderGroove", unit.pos)
    Wargroove.waitTime(1.0)

    Wargroove.playGrooveEffect()

    Wargroove.setUnitState(unit, "transforming", "true")

    unit.unitClassId = "commander_lytra_flying"
    unit.grooveCharge = 0
    Wargroove.updateUnit(unit)

    Wargroove.waitTime(0.2)
end

function Float:onPostUpdateUnit(unit, targetPos, strParam, path)
    unit.hadTurn = false
end

return Float
