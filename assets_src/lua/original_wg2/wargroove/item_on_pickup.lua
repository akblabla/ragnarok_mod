local Wargroove = require "wargroove/wargroove"
local ItemOnPickup = {}

local OnPickup = {}

function OnPickup.guiding_light(Wargroove, unit, targetPos, strParam, path)
    local units = Wargroove.getAllUnitsForPlayer(unit.playerId, true)
    local healAmount = 20

    for _, u in ipairs(units) do
        if not u.unitClass.isStructure then            
            u:setHealth(u.health + healAmount, unit.id)

            Wargroove.updateUnit(u)
            Wargroove.spawnMapAnimation(u.pos, 0, "fx/heal_unit")
            Wargroove.playMapSound("unitHealed", u.pos)
        end
    end
end

function OnPickup.small_healing_potion(Wargroove, unit, targetPos, strParam, path)
    local healAmount = 100

    unit:setHealth(unit.health + healAmount, unit.id)

    Wargroove.updateUnit(unit)
    Wargroove.spawnMapAnimation(unit.pos, 0, "fx/heal_unit")
    Wargroove.playMapSound("unitHealed", unit.pos)
end

function OnPickup.large_healing_potion(Wargroove, unit, targetPos, strParam, path)
    local units = Wargroove.getAllUnitsForPlayer(unit.playerId, true)
    local healAmount = 30

    for _, u in ipairs(units) do
        if not u.unitClass.isStructure then            
            u:setHealth(u.health + healAmount, unit.id)

            Wargroove.updateUnit(u)
            Wargroove.spawnMapAnimation(u.pos, 0, "fx/heal_unit")
            Wargroove.playMapSound("unitHealed", u.pos)
        end
    end
end

function OnPickup.swift_potion(Wargroove, unit, targetPos, strParam, path)
    Wargroove.displayBuffVisualEffect(unit.id, unit.playerId, "fx/general_unit_effect", "spawn", 0.6, {}, "over_units", {x = 0, y = 0}, false, false)
    Wargroove.pushUnitClassModifier(unit.id, "movement_range_bonus")
    Wargroove.updateUnit(unit)
end

function OnPickup.groove_boost(Wargroove, unit, targetPos, strParam, path)
    local grooveBoostAmount = 100

    local commanders = Wargroove.getCommanderUnitsForPlayer(unit.playerId)

    for _, commander in ipairs(commanders) do
        local groove = Wargroove.getGroove(commander.grooveId)
        if commander.grooveCharge < groove.grooveCost[1] then
            grooveBoostAmount = groove.grooveCost[1]
        elseif commander.grooveCharge >= groove.grooveCost[1] then
            grooveBoostAmount = groove.grooveCost[2]
        end

        Wargroove.spawnMapAnimation(commander.pos, 0, "fx/groove/inspire_unit")
        commander.grooveCharge = math.min(grooveBoostAmount, commander.unitClass.maxGroove)
        Wargroove.updateUnit(commander)
    end
end

function OnPickup.immunity_potion(Wargroove, unit, targetPos, strParam, path)
    local units = Wargroove.getAllUnitsForPlayer(unit.playerId, true)

    for _, u in ipairs(units) do
        if not u.unitClass.isStructure then
            Wargroove.pushUnitClassModifier(u.id, "invincibility")
            Wargroove.pushBuff(1, u, u.playerId, "immunity_potion_spawn", "immunity_potion", "immunity_potion_death")
        end
    end
end

function OnPickup.wind_potion(Wargroove, unit, targetPos, strParam, path)
    local units = Wargroove.getAllUnitsForPlayer(unit.playerId, true)

    for _, u in ipairs(units) do
        if not u.unitClass.isStructure then            
            u.hadTurn = false

            Wargroove.updateUnit(u)
            Wargroove.spawnMapAnimation(u.pos, 0, "fx/groove/inspire_unit")
        end
    end
end

function OnPickup.crystal_drop(Wargroove, unit, targetPos, strParam, path)
    local crystalAmount = 1

    Wargroove.spawnMapAnimation(unit.pos, 0, "fx/ransack_1", "default", "over_units", { x = 12, y = 0 })
    Wargroove.rewardCrystals(crystalAmount)
end

function ItemOnPickup.getOnPickup(Wargroove, itemId)
    return OnPickup[itemId]
end

return ItemOnPickup