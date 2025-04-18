local Wargroove = require "wargroove/wargroove"
local Verb = require "wargroove/verb"
local Combat = require "wargroove/combat"

local DeathExplode = Verb:new()

function DeathExplode:execute(unit, targetPos, strParam, path)
    if tonumber(strParam) == unit.id then
        return
    end

    if (unit.killedByLosing) then
        Wargroove.spawnMapAnimation(unit.pos, 1, "fx/groove/koji_groove_fx", "idle", "behind_units", { x = 12, y = 12 })
        Wargroove.playUnitAnimationOnce(unit.id, "explode")
        Wargroove.playMapSound("koji/kojiDroneExplode", unit.pos)
        Wargroove.waitTime(0.2)
        return
    end

    Wargroove.spawnMapAnimation(unit.pos, 1, "fx/groove/koji_groove_fx", "idle", "behind_units", { x = 12, y = 12 })
    
    for i, pos in ipairs(Wargroove.getTargetsInRange(unit.pos, 1, "unit")) do
        local u = Wargroove.getUnitAt(pos)
        if u and u.health > 0 and Wargroove.areEnemies(u.playerId, unit.playerId) then
            local damage = Combat:getGrooveAttackerDamage(unit, u, "random", unit.pos, u.pos, path, "kojiAttack") * 0.5

            u:setHealth(u.health - damage, unit.id)
            Wargroove.updateUnit(u)
            Wargroove.playUnitAnimation(u.id, "hit")
        end
    end

    Wargroove.playUnitAnimationOnce(unit.id, "explode")
    Wargroove.playMapSound("koji/kojiDroneExplode", unit.pos)

    Wargroove.waitTime(0.2)
end


return DeathExplode
