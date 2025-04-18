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

    local hasUnit = false

    if (unit.killedByLosing) then
        return
    end

    local startingState = {}
    local pos = {key = "pos", value = posString}
    local radius = {key = "radius", value = tostring(currentRadius)}
    table.insert(startingState, pos)
    table.insert(startingState, radius)
    local visibleSpawn = Wargroove.getUnitAt(center)
    if visibleSpawn == nil or visibleSpawn.health <= 0 then
        -- This means the spawn has died in the mean time 
        return
    end

    visibleSpawn:setHealth(visibleSpawn.health - 25, visibleSpawn.id)
    local killed = visibleSpawn.health <= 0;
    Wargroove.updateUnit(visibleSpawn)

    if killed then
        return
    end
    
    local hiddenId = Wargroove.spawnUnit(unit.playerId, {x = -100, y = -100}, "area_heal_hidden", false, "", startingState)
    
    Wargroove.trackCameraTo(center)
    Wargroove.waitTime(0.5)

    Wargroove.setUnitState(visibleSpawn, "hiddenId", tostring(hiddenId))
    Wargroove.updateUnit(visibleSpawn)
    Wargroove.waitFrame()
    
    for i, pos in ipairs(Wargroove.getTargetsInRange(center, currentRadius, "unit")) do
        local u = Wargroove.getUnitAt(pos)
        if u and u.health > 0 and u.health < 100 and (not u.unitClass.isStructure) and (u.playerId >= 0) and u.unitClassId ~= "area_heal" then
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

    Wargroove.waitTime(0.5)
end

return AreaHeal