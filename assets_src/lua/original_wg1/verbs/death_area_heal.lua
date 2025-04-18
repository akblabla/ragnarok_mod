local Wargroove = require "wargroove/wargroove"
local Verb = require "wargroove/verb"

local AreaHeal = Verb:new()

local healAmount = 20

function AreaHeal:execute(unit, targetPos, strParam, path)
    local currentRadius = tonumber(Wargroove.getUnitState(unit, "radius"))
    
    local posString = Wargroove.getUnitState(unit, "pos")
    local vals = {}
    for val in posString.gmatch(posString, "([^"..",".."]+)") do
        vals[#vals+1] = val
    end
    local center = { x = tonumber(vals[1]), y = tonumber(vals[2])}

    Wargroove.trackCameraTo(center)
    Wargroove.waitTime(0.5)

    local hasUnit = false

    if (unit.killedByLosing) then
        return
    end

    for i, pos in ipairs(Wargroove.getTargetsInRange(center, currentRadius, "unit")) do
        local u = Wargroove.getUnitAt(pos)
        if u and u.health > 0 and u.health < 100 and (not u.unitClass.isStructure) and (u.playerId >= 0) then
            u:setHealth(u.health + healAmount, unit.id)
            Wargroove.updateUnit(u)
            hasUnit = true
            Wargroove.spawnMapAnimation(pos, 0, "fx/heal_unit")
        end
    end

    if hasUnit then
        Wargroove.playMapSound("twins/errolGrooveUnitsHealed", center)
    end

    Wargroove.playMapSound("twins/errolGrooveZoneHeal", center)

    if (currentRadius == 0) then
        return
    end

    local startingState = {}
    local pos = {key = "pos", value = posString}
    local radius = {key = "radius", value = tostring(currentRadius - 1)}
    table.insert(startingState, pos)
    table.insert(startingState, radius)
    Wargroove.spawnUnit(unit.playerId, {x = -100, y = -100}, "area_heal", false, "", startingState)
    Wargroove.waitTime(0.5)
end

return AreaHeal