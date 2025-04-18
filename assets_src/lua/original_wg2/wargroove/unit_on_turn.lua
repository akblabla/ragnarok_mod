local UnitOnTurn = {}

local OnTurn = {}

function OnTurn.lumbermill(Wargroove, unit)
    -- reset previously cut trees
    Wargroove.clearCaches()

    unit = Wargroove.getUnitById(unit.id)
    Wargroove.setUnitState(unit, "treeNumber", tostring(0))
    Wargroove.updateUnit(unit)

    local targets = Wargroove.getTerrainTargetsAround(unit.pos, "forest_cut");
    local values = { unit.id, unit.unitClassId, unit.pos.x, unit.pos.y, Wargroove.getTurnNumber(), Wargroove.getCurrentPlayerId() }
    local str = ""
    for i, v in ipairs(values) do
        str = str .. tostring(v) .. ":"
    end
    
    if #(targets) > 0 then
        local selectedTarget = Wargroove.randomInteger(str, 1, #(targets))

        Wargroove.setTerrainType(targets[selectedTarget], "forest")
    end
end

function OnTurn.golem_unit(Wargroove, unit)
    local recharging = Wargroove.getUnitState(unit, "recharging")
    if recharging == "true" then
        unit.hadTurn = true
        Wargroove.updateUnit(unit)
    end
end

function OnTurn.dispenser(Wargroove, unit)
    local dispensed = Wargroove.getUnitState(unit, "itemsDispensed")
    if dispensed and tonumber(dispensed) >= unit.itemDropNumber then
        unit.hadTurn = true
        Wargroove.updateUnit(unit)
    end
end

function OnTurn.kraken(Wargroove, unit)
    Wargroove.untangleKraken(unit)
    UnitOnTurn:tickCooldown(Wargroove, unit)
end

function OnTurn.frog(Wargroove, unit)
    UnitOnTurn:tickCooldown(Wargroove, unit)
end

function OnTurn.minicommander_oaracle(Wargroove, unit)
    UnitOnTurn:tickCooldown(Wargroove, unit)
end

function UnitOnTurn:getOnTurn(unitClassId)
    return OnTurn[unitClassId]
end

function UnitOnTurn:tickCooldown(Wargroove, unit)
    local cooldown = Wargroove.getUnitState(unit, "cooldown")
    if cooldown then
        local cd = tonumber(cooldown)
        cd = cd - 1
        print("decrease cooldown to " .. cd)
        Wargroove.setUnitState(unit, "cooldown", cd)
        Wargroove.updateUnit(unit)
    end
end

function UnitOnTurn:isOnCooldown(Wargroove, unit)
    local cooldown = Wargroove.getUnitState(unit, "cooldown")
    if cooldown then
        local cd = tonumber(cooldown)
        if cd > 0 then
            return true
        end
    end
    return false
end

function UnitOnTurn:setCooldown(Wargroove, unit, min, max)
    local values = { unit.id, unit.unitClassId, unit.pos.x, unit.pos.y, Wargroove.getTurnNumber(), Wargroove.getCurrentPlayerId() }
    local str = ""
    for i, v in ipairs(values) do
        str = str .. tostring(v) .. ":"
    end

    local cooldown = Wargroove.randomInteger(str, min, max)
    print("set pull on cooldown, cd=" .. cooldown)
    Wargroove.setUnitState(unit, "cooldown", tonumber(cooldown))
    Wargroove.updateUnit(unit)
end

return UnitOnTurn
