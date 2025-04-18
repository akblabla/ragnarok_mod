local Wargroove = require "wargroove/wargroove"
local Verb = require "wargroove/verb"

local AreaHealDamageHidden = Verb:new()

local damageAmount = 20
local healAmount = 20

function AreaHealDamageHidden:execute(unit, targetPos, strParam, path)
    local currentRadius = tonumber(Wargroove.getUnitState(unit, "radius"))
    
    local posString = Wargroove.getUnitState(unit, "pos")
    local vals = {}
    for val in posString.gmatch(posString, "([^"..",".."]+)") do
        vals[#vals+1] = val
    end
    local center = { x = tonumber(vals[1]), y = tonumber(vals[2])}

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
    
    local hiddenId = Wargroove.spawnUnit(unit.playerId, {x=-100, y=-100}, "area_combined_hidden", false, "", startingState)
    
    Wargroove.trackCameraTo(center)
    Wargroove.waitTime(0.5)

    Wargroove.setUnitState(visibleSpawn, "hiddenId", tostring(hiddenId))
    Wargroove.updateUnit(visibleSpawn)
    Wargroove.waitFrame()
    
    for i, pos in ipairs(Wargroove.getTargetsInRange(center, currentRadius, "unit")) do
        local u = Wargroove.getUnitAt(pos)
        
        if u and (not u.unitClass.isStructure) and (u.playerId >= 0) and u.unitClassId ~= "area_combined" then
            local ally = Wargroove.areAllies(u.playerId, unit.playerId)

            if ally then
                u:setHealth(u.health + healAmount, unit.id)
                Wargroove.spawnMapAnimation(pos, 0, "fx/heal_unit")
            else
                u:setHealth(u.health - damageAmount, unit.id)
                Wargroove.playUnitAnimation(u.id, "hit")
            end
            Wargroove.updateUnit(u)
        end
    end

    Wargroove.waitTime(0.5)
end

return AreaHealDamageHidden