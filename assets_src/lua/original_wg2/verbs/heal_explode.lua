local Wargroove = require "wargroove/wargroove"
local Verb = require "wargroove/verb"
local Combat = require "wargroove/combat"
local DefaultDeath = require "verbs/default_death"

local HealExplode = Verb:new()

local healAmount = 20

function HealExplode:execute(unit, targetPos, strParam, path)
    DefaultDeath:execute(unit, targetPos, strParam, path)

    Wargroove.spawnMapAnimation(unit.pos, 1, "fx/groove/koji_groove_fx", "idle", "behind_units", { x = 12, y = 12 })
    
    for i, pos in ipairs(Wargroove.getTargetsInRange(unit.pos, 1, "unit")) do
        local u = Wargroove.getUnitAt(pos)
        if u and Wargroove.areAllies(u.playerId, unit.playerId) and u ~= unit and not u.unitClass.isStructure then
            u:setHealth(u.health + healAmount, unit.id)
            Wargroove.updateUnit(u)

            Wargroove.spawnMapAnimation(u.pos, 0, "fx/heal_unit")
            Wargroove.playMapSound("unitHealed", u.pos)
        end
    end

    Wargroove.playUnitAnimationOnce(unit.id, "explode")
    Wargroove.playMapSound("koji/kojiDroneExplode", unit.pos)

    unit:setHealth(0, unit.id)
    Wargroove.updateUnit(unit)

    Wargroove.waitTime(0.4)
end

function HealExplode:generateOrders(unitId, canMove)
    local orders = {}
    if Wargroove.hasAIRestriction(unitId, "cant_attack") then
        return orders
    end

    local unit = Wargroove.getUnitById(unitId)
    local unitClass = Wargroove.getUnitClass(unit.unitClassId)
    local movePositions = {}
    if canMove then
        movePositions = Wargroove.getTargetsInRange(unit.pos, unitClass.moveRange, "empty")
    end
    table.insert(movePositions, unit.pos)

    for i, pos in pairs(movePositions) do
        orders[#orders+1] = {targetPosition = pos, strParam = "", movePosition = pos, endPosition = pos}
    end

    return orders
end

return HealExplode
