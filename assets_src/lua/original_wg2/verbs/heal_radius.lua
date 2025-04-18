local Wargroove = require "wargroove/wargroove"
local Verb = require "wargroove/verb"


local HealRadius = Verb:new()

local healRange = 3
local cost = 300

function HealRadius:getMaximumRange(unit, endPos)
    return 2
end

function HealRadius:getTargetType()
    return "all"
end

function HealRadius:canExecuteAnywhere(unit)
    return Wargroove.getMoney(unit.playerId) >= cost
end

function HealRadius:getCostAt(unit, endPos, targetPos)
    return cost
end

function HealRadius:execute(unit, targetPos, strParam, path)
    Wargroove.changeMoney(unit.playerId, -cost)

    local targets = Wargroove.getTargetsInRange(targetPos, healRange, "unit")
    if targets then
        for i, pos in ipairs(targets) do
            local u = Wargroove.getUnitAt(pos)
            if u and not u.unitClass.isStructure and u.health < 100 and u.health > 0 then
                u:setHealth(u.health + 10, unit.id)
                Wargroove.updateUnit(u)
                Wargroove.spawnMapAnimation(u.pos, 0, "fx/heal_unit", "default", "over_units", { x = 12, y = 12 })
            end
        end
        Wargroove.playMapSound("unitHealed", targetPos)
    end
end

return HealRadius