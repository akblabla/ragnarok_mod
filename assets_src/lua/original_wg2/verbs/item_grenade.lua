local Wargroove = require "wargroove/wargroove"
local ItemVerb = require "wargroove/item_verb"

local Grenade = ItemVerb:new()

local attackRange = 1
local throwRange = 2
local damage = 30

function Grenade:getMaximumRange(unit, endPos)
    return throwRange
end

function Grenade:getTargetType()
    return "all"
end

function Grenade:execute(unit, targetPos, strParam, path)
    Wargroove.spawnMapAnimation(targetPos, 1, "fx/groove/koji_groove_fx", "idle", "behind_units", { x = 12, y = 12 })
    Wargroove.playMapSound("koji/kojiDroneExplode", targetPos)

    local targets = Wargroove.getTargetsInRange(targetPos, attackRange, "unit")
    if targets then
        for i, pos in ipairs(targets) do
            local u = Wargroove.getUnitAt(pos)
            if u and u.health > 0 and (not u.unitClass.isStructure) and (u.playerId ~= -1) and Wargroove.areEnemies(unit.playerId, u.playerId) then
                u:setHealth(u.health - damage, unit.id)
                Wargroove.playUnitAnimation(u.id, "hit")
                Wargroove.updateUnit(u)
            end
        end
    end

    Wargroove.waitTime(0.2)
end

return Grenade
