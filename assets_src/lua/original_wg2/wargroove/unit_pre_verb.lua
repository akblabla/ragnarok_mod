local UnitPreVerb = {}

local PreVerb = {}

function PreVerb.airtrooper(Wargroove, unit, targetPos, strParam, path)
    Wargroove.playUnitAnimation(unit.id, "takeoff")
    Wargroove.waitTime(0.1)
end

function UnitPreVerb:getPreVerb(unitClassId)
    return PreVerb[unitClassId]
end

return UnitPreVerb