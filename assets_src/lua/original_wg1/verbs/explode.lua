local Wargroove = require "wargroove/wargroove"
local Verb = require "wargroove/verb"
local Combat = require "wargroove/combat"

local Explode = Verb:new()

function Explode:execute(unit, targetPos, strParam, path)
    Wargroove.spawnMapAnimation(unit.pos, 1, "fx/groove/koji_groove_fx", "idle", "behind_units", { x = 12, y = 12 })
    
    for i, pos in ipairs(Wargroove.getTargetsInRange(unit.pos, 1, "unit")) do
        local u = Wargroove.getUnitAt(pos)
        if u and Wargroove.areEnemies(u.playerId, unit.playerId) then
            local cost = u.unitClass.cost
            local damage = Combat:getGrooveAttackerDamage(unit, u, "random", unit.pos, u.pos, path, "kojiAttack") * 0.5

            u:setHealth(u.health - damage, unit.id)
            Wargroove.updateUnit(u)
            Wargroove.playUnitAnimation(u.id, "hit")
        end
    end

    Wargroove.playUnitAnimationOnce(unit.id, "explode")
    Wargroove.playMapSound("koji/kojiDroneExplode", unit.pos)

    unit:setHealth(0, unit.id)
    Wargroove.updateUnit(unit)

    Wargroove.waitTime(0.4)
end

function Explode:generateOrders(unitId, canMove)
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

function Explode:getScore(unitId, order)
    local unit = Wargroove.getUnitById(unitId)
    local targets = Wargroove.getTargetsInRangeAfterMove(unit, order.endPosition, order.endPosition, 1, "unit")

    local effectivenessScore = 0.0
    local totalValue = 0.0

    local function canTarget(u)
        if not Wargroove.areEnemies(u.playerId, unit.playerId) then
            return false
        end
        if Wargroove.hasAIRestriction(u.id, "dont_target_this") then
            return false
        end
        if Wargroove.hasAIRestriction(unit.id, "only_target_commander") and not u.unitClass.isCommander then
            return false
        end
        return true
    end

    local foundTarget = false
    for i, target in ipairs(targets) do
        local u = Wargroove.getUnitAt(target)
        if u ~= nil and canTarget(u) then
            foundTarget = true
            local damage = Combat:getGrooveAttackerDamage(unit, u, "aiSimulation", unit.pos, u.pos, path, "kojiAttack") * 0.5
            local newHealth = math.max(0, u.health - damage)
            local theirValue = Wargroove.getAIUnitValue(u.id, target)
            local theirDelta = theirValue - Wargroove.getAIUnitValueWithHealth(u.id, target, newHealth)
            effectivenessScore = effectivenessScore + theirDelta
            totalValue = totalValue + theirValue
        end
    end

    if not foundTarget then
        return {score = -1, introspection = {}}
    end    

    local locationGradient = 0.0
    if (Wargroove.getAICanLookAhead(unitId)) then
        locationGradient = Wargroove.getAILocationScore(unit.unitClassId, order.endPosition) - Wargroove.getAILocationScore(unit.unitClassId, unit.pos)
    end
    local gradientBonus = 0.0
    if (locationGradient > 0.0001) then
        gradientBonus = 0.25
    end

    local bravery = Wargroove.getAIBraveryBonus()
    local attackBias = Wargroove.getAIAttackBias()

    local score = (effectivenessScore + gradientBonus + bravery) * attackBias
    local introspection = {
        {key = "effectivenessScore", value = effectivenessScore},
        {key = "totalValue", value = totalValue},
        {key = "bravery", value = bravery},
        {key = "attackBias", value = attackBias}}

    return {score = score, introspection = introspection}
end

return Explode
