local Wargroove = require "wargroove/wargroove"
local Verb = require "wargroove/verb"
local Combat = require "wargroove/combat"
local DefaultDeath = require "verbs/default_death"

local MineExplode = Verb:new()

function MineExplode:execute(unit, targetPos, strParam, path)
    DefaultDeath:execute(unit, targetPos, strParam, path)

    if tonumber(strParam) == unit.id then
        return
    end

    Wargroove.spawnMapAnimation(unit.pos, 1, "fx/groove/koji_groove_fx", "idle", "behind_units", { x = 12, y = 12 })
    
    for i, pos in ipairs(Wargroove.getTargetsInRange(unit.pos, 1, "unit")) do
        local u = Wargroove.getUnitAt(pos)
        if u and u.health > 0 and Wargroove.areEnemies(u.playerId, unit.playerId) then
            u.stunned = true
            Wargroove.updateUnit(u)
        end
    end

    Wargroove.playUnitAnimationOnce(unit.id, "explode")
    Wargroove.playMapSound("koji/kojiDroneExplode", unit.pos)

    unit:setHealth(0, unit.id)
    Wargroove.updateUnit(unit)

    Wargroove.waitTime(0.2)
end


return MineExplode
