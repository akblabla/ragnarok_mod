local Wargroove = require "wargroove/wargroove"
local Verb = require "wargroove/verb"

local AreaDamage = Verb:new()

function AreaDamage:execute(unit, targetPos, strParam, path)
    if (unit.killedByLosing) then
        return
    end

    local currentRadius = tonumber(Wargroove.getUnitState(unit, "radius"))
    
    local posString = Wargroove.getUnitState(unit, "pos")
    local vals = {}
    for val in posString.gmatch(posString, "([^"..",".."]+)") do
        vals[#vals+1] = val
    end
    local center = { x = tonumber(vals[1]), y = tonumber(vals[2])}

    Wargroove.trackCameraTo(center)
    Wargroove.waitTime(0.5)
    
    Wargroove.playMapSound("twins/orlaGrooveEnd", center)
    local firePositions = Wargroove.getTargetsInRange(center, currentRadius, "all")
    for i, pos in ipairs(firePositions) do
        Wargroove.playBuffVisualEffectSequenceOnce(unit.id, pos, "units/commanders/twins/area_damage", "despawn")
        Wargroove.playBuffVisualEffectSequenceOnce(unit.id, pos, "units/commanders/twins/smoke_back", "despawn")
        Wargroove.playBuffVisualEffectSequenceOnce(unit.id, pos, "units/commanders/twins/fire_back", "despawn")
        Wargroove.playBuffVisualEffectSequenceOnce(unit.id, pos, "units/commanders/twins/fire_front", "despawn")
    end

    local hiddenSpawnId = Wargroove.getUnitState(unit, "hiddenId")
    if hiddenSpawnId ~= nil then
        local hiddenSpawn = Wargroove.getUnitById(tonumber(hiddenSpawnId))
        hiddenSpawn:setHealth(0, hiddenSpawn.id)
        Wargroove.updateUnit(hiddenSpawn)
    end

    Wargroove.waitTime(0.5)
end

return AreaDamage