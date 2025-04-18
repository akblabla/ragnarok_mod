local UnitPostVerb = {}

local PostVerb = {}

local maxAir = 2

function PostVerb.turtle_submerged(Wargroove, unit, verb)
    local air = tonumber(Wargroove.getUnitState(unit, "air"))
    local newAir = math.max(air - 1, 0)
    Wargroove.setUnitState(unit, "air", newAir)

    if(newAir <= 0) then
        unit.unitClassId = "turtle"
        unit.hadTurn = true

        Wargroove.spawnMapAnimation(unit.pos, 1, Wargroove.getSplashEffect())
        Wargroove.playMapSound("unitSplash", unit.pos)

        Wargroove.setUnitState(unit, "air", maxAir)
        Wargroove.updateUnit(unit)

        Wargroove.waitTime(0.2)
    end
end

function PostVerb.airtrooper(Wargroove, unit, verb)
    Wargroove.playUnitAnimation(unit.id, "touchdown")
    Wargroove.waitTime(0.1)
end

function PostVerb.commander_lytra_flying(Wargroove, unit, verb)
    if Wargroove.getUnitState(unit, "transforming") == "true" then
        Wargroove.setUnitState(unit, "transforming", "false")
        Wargroove.updateUnit(unit)

        return
    end

    unit.unitClassId = "commander_lytra"
    unit.hadTurn = true
    Wargroove.updateUnit(unit)

    Wargroove.waitTime(0.2)
end

function PostVerb.golem_unit(Wargroove, unit, verb)
    if verb ~= "attack" then
        return
    end

    Wargroove.setUnitState(unit, "recharging", "true")
    Wargroove.pushUnitClassModifier(unit.id, "guardian_recharge")
    Wargroove.playUnitAnimation(unit.id, "charge", "charge")
    Wargroove.updateUnit(unit)
    unit.hadTurn = true
    Wargroove.updateUnit(unit)
    
    Wargroove.pushBuff(2, unit, unit.playerId, "guardian_recharge_spawn", "guardian_recharge", "guardian_recharge_death")
    
    Wargroove.waitFrame()
end

function UnitPostVerb:getPostVerb(unitClassId)
    return PostVerb[unitClassId]
end

return UnitPostVerb