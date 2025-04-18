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

    local hiddenSpawnId = Wargroove.getUnitState(unit, "hiddenId")
    if hiddenSpawnId ~= nil then
        local hiddenSpawn = Wargroove.getUnitById(tonumber(hiddenSpawnId))
        hiddenSpawn:setHealth(0, hiddenSpawn.id)
        Wargroove.updateUnit(hiddenSpawn)
    end
end

return AreaHeal