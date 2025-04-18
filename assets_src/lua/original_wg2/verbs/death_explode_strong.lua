local Wargroove = require "wargroove/wargroove"
local Verb = require "wargroove/verb"
local Combat = require "wargroove/combat"
local DefaultDeath = require "verbs/default_death"

local DeathExplodeStrong = Verb:new()

local healAmount = 35

function DeathExplodeStrong:execute(unit, targetPos, strParam, path)
    DefaultDeath:execute(unit, targetPos, strParam, path)

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
            local damage = Combat:getGrooveAttackerDamage(unit, u, "average", unit.pos, u.pos, path, "kojiAttack") * 0.75

            u:setHealth(u.health - damage, unit.id)
            Wargroove.updateUnit(u)
            Wargroove.playUnitAnimation(u.id, "hit")
        end
        if u and Wargroove.areAllies(u.playerId, unit.playerId) and u.id ~= unit.id then
            Wargroove.playMapSound("unitHealed", pos)
            u:setHealth(u.health + healAmount, unit.id)
            Wargroove.updateUnit(u)
            Wargroove.spawnMapAnimation(pos, 0, "fx/heal_unit")
        end
    end

    Wargroove.playUnitAnimationOnce(unit.id, "explode")
    Wargroove.playMapSound("koji/kojiDroneExplode", unit.pos)

    Wargroove.waitTime(0.2)
end


return DeathExplodeStrong
