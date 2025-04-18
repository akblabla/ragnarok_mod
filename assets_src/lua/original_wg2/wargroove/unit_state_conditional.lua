local UnitStateConditional = {}

local StateConditional = {}

function StateConditional.rooted(Wargroove, unit, targetPos, strParam, path)
    print(Wargroove.tableToString(unit))

    Wargroove.playUnitAnimation(unit.id, "hit")

    unit:setHealth(unit.health - 25, unit.id)
    Wargroove.setUnitState(unit, "rooted", "false")

    Wargroove.updateUnit(unit)
    Wargroove.waitTime(0.6)

    Wargroove.clearBuffVisualEffect(unit.id)
end

function UnitStateConditional.getStateConditional(Wargroove, unit)
    if Wargroove.getUnitState(unit, "rooted") == "true" then
        return StateConditional["rooted"];
    end

    return nil
end

return UnitStateConditional