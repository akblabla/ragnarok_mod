local Wargroove = require "wargroove/wargroove"
local ItemVerb = require "wargroove/item_verb"

local SelfDestructonator = ItemVerb:new()

local attackRange = 1
local damage = 30

function SelfDestructonator:getMaximumRange(unit, endPos)
    return 0
end

function SelfDestructonator:getTargetType()
    return "all"
end

function SelfDestructonator:execute(unit, targetPos, strParam, path)
    Wargroove.spawnMapAnimation(unit.pos, 1, "fx/groove/koji_groove_fx", "idle", "behind_units", { x = 12, y = 12 })
    Wargroove.playMapSound("koji/kojiDroneExplode", unit.pos)

    local targets = Wargroove.getTargetsInRange(unit.pos, attackRange, "unit")
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

    unit:setHealth(0, unit.id)
    Wargroove.updateUnit(unit)

    Wargroove.waitTime(0.2)
end

return SelfDestructonator