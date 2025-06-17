local Wargroove = require "wargroove/wargroove"
local GrooveVerb = require "wargroove/groove_verb"


local Teleport = GrooveVerb:new()

function Teleport:getTier()
    return 1
end

function Teleport:consumeGroove(unit)
    local groove = Wargroove.getGroove(self:getGrooveId(unit))
    unit.grooveChargeOnUse = unit.grooveCharge
    unit.grooveCharge = unit.grooveCharge-groove.grooveCost[1]
    if unit.grooveCharge<0 then unit.grooveCharge = 0 end
    Wargroove.updateUnit(unit)
end

function Teleport:getMaximumRange(unit, endPos)
    return 5
end


function Teleport:getTargetType()
    return "all"
end


function Teleport:canExecuteWithTarget(unit, endPos, targetPos, strParam)
    if not self:canSeeTarget(targetPos) then
        return false
    end

    local u = Wargroove.getUnitAt(targetPos)
    local uc = Wargroove.getUnitClass("soldier")
    return (u == nil or u.id == unit.id) and Wargroove.canStandAt("soldier", targetPos)
end


function Teleport:execute(unit, targetPos, strParam, path)
    Wargroove.setIsUsingGroove(unit.id, true)
    Wargroove.updateUnit(unit)

    Wargroove.playUnitAnimation(unit.id, "mini_groove", "invisible")
    Wargroove.playMapSound("vesper/vesperMiniGroove", unit.pos)
    
    Wargroove.waitTime(0.8)
    Wargroove.spawnPaletteSwappedMapAnimation(unit.pos, 0, "fx/groove/smoke_teleport_fx", "default", "over_units", { x = 12, y = 12 })
    Wargroove.waitTime(0.2)
    Wargroove.setShadowVisible(unit.id, false)
    Wargroove.waitTime(1.3)
    Wargroove.spawnPaletteSwappedMapAnimation(targetPos, 0, "fx/groove/smoke_teleport_fx", "default", "over_units", { x = 12, y = 12 })
    Wargroove.playMapSound("vesper/vesperMiniGrooveEnd", targetPos)
    unit.pos = { x = targetPos.x, y = targetPos.y, facing = unit.pos.facing }
    Wargroove.updateUnit(unit)
    Wargroove.playUnitAnimation(unit.id, "mini_groove_end", "mini_groove_idle")

    Wargroove.waitTime(0.1)
    Wargroove.setShadowVisible(unit.id, true)
end

function Teleport:onPostUpdateUnit(unit, targetPos, strParam, path)
    GrooveVerb.onPostUpdateUnit(self, unit, targetPos, strParam, path)
    unit.pos = { x = targetPos.x, y = targetPos.y, facing = unit.pos.facing }
end

return Teleport
