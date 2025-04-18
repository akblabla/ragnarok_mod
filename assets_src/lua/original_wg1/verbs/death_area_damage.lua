local Wargroove = require "wargroove/wargroove"
local Verb = require "wargroove/verb"

local AreaDamage = Verb:new()

local damageAmount = 20

function AreaDamage:execute(unit, targetPos, strParam, path) 
    local currentRadius = tonumber(Wargroove.getUnitState(unit, "radius"))

    local posString = Wargroove.getUnitState(unit, "pos")
    local vals = {}
    for val in posString.gmatch(posString, "([^"..",".."]+)") do
        vals[#vals+1] = val
    end
    local center = { x = tonumber(vals[1]), y = tonumber(vals[2])}

    Wargroove.trackCameraTo(center)
    Wargroove.waitTime(0.5)

    if (unit.killedByLosing) then
        Wargroove.playMapSound("twins/orlaGrooveEnd", center)
        local firePositions = Wargroove.getTargetsInRange(center, currentRadius, "all")
        for i, pos in ipairs(firePositions) do
            Wargroove.playBuffVisualEffectSequenceOnce(unit.id, pos, "units/commanders/twins/area_damage", "despawn")
            Wargroove.playBuffVisualEffectSequenceOnce(unit.id, pos, "units/commanders/twins/smoke_back", "despawn")
            Wargroove.playBuffVisualEffectSequenceOnce(unit.id, pos, "units/commanders/twins/fire_back", "despawn")
            Wargroove.playBuffVisualEffectSequenceOnce(unit.id, pos, "units/commanders/twins/fire_front", "despawn")
        end
        return
    end

    Wargroove.playMapSound("twins/orlaGrooveExpand", center)
    local newFireAnimations = {}
    if (currentRadius == 3) then
        local firePositions = Wargroove.getTargetsInRange(center, currentRadius, "all")
        for i, pos in ipairs(firePositions) do
            local distance = math.abs(pos.x - center.x) + math.abs(pos.y - center.y)
            if (distance == currentRadius) then
                Wargroove.displayBuffVisualEffectAtPosition(unit.id, pos, unit.playerId, "units/commanders/twins/smoke_back", "spawn", 0.6, effectPositions, "units", {x = 0, y = 0})
                Wargroove.displayBuffVisualEffectAtPosition(unit.id, pos, unit.playerId, "units/commanders/twins/fire_back", "spawn", 1.0, firePositions, "units", {x = 0, y = 0})
                Wargroove.displayBuffVisualEffectAtPosition(unit.id, pos, unit.playerId, "units/commanders/twins/fire_front", "spawn", 1.0, firePositions, "units", {x = 0, y = 2})
            end
        end
    end

    for i, pos in ipairs(Wargroove.getTargetsInRange(center, currentRadius, "unit")) do
        local u = Wargroove.getUnitAt(pos)
        if u and u.health > 0 and (not u.unitClass.isStructure) and (u.playerId ~= -1) and u.damageTakenPercent > 0 then
            u:setHealth(0, unit.id)
            Wargroove.playUnitDeathAnimation(u.id)
            if (u.unitClass.isCommander) then
                Wargroove.playMapSound("commanderDie", unit.pos)
            end
            Wargroove.updateUnit(u)
        end
    end

    if (currentRadius == 3) then
        Wargroove.playMapSound("twins/orlaGrooveEnd", center)
        local firePositions = Wargroove.getTargetsInRange(center, currentRadius, "all")
        for i, pos in ipairs(firePositions) do
            Wargroove.playBuffVisualEffectSequenceOnce(unit.id, pos, "units/commanders/twins/area_damage", "despawn")
            Wargroove.playBuffVisualEffectSequenceOnce(unit.id, pos, "units/commanders/twins/smoke_back", "despawn")
            Wargroove.playBuffVisualEffectSequenceOnce(unit.id, pos, "units/commanders/twins/fire_back", "despawn")
            Wargroove.playBuffVisualEffectSequenceOnce(unit.id, pos, "units/commanders/twins/fire_front", "despawn")
        end
        return
    end

    local startingState = {}
    local pos = {key = "pos", value = posString}
    local radius = {key = "radius", value = tostring(currentRadius + 1)}    
    table.insert(startingState, pos)
    table.insert(startingState, radius)
    local newId = Wargroove.spawnUnit(unit.playerId, {x = -100, y = -100}, "area_damage", false, "", startingState)
    Wargroove.playBuffVisualEffectSequence(unit.id, center, "units/commanders/twins/area_damage", "idle_" .. tostring(currentRadius+1))    
    Wargroove.setBuffVisualEffectsOwner(unit.id, newId)
    Wargroove.waitTime(0.5)
end

return AreaDamage
