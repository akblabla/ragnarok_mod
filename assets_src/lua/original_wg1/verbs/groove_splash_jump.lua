local Wargroove = require "wargroove/wargroove"
local GrooveVerb = require "wargroove/groove_verb"
local Combat = require "wargroove/combat"

local SplashJump = GrooveVerb:new()


function SplashJump:getMaximumRange(unit, endPos)
    return 5
end


function SplashJump:getTargetType()
    return "all"
end


function SplashJump:canExecuteWithTarget(unit, endPos, targetPos, strParam)
    if not self:canSeeTarget(targetPos) then
        return false
    end

    local u = Wargroove.getUnitAt(targetPos)
    local uc = Wargroove.getUnitClass("soldier")
    return (u == nil or u.id == unit.id) and Wargroove.canStandAt("soldier", targetPos)
end


function SplashJump:execute(unit, targetPos, strParam, path)
    Wargroove.setIsUsingGroove(unit.id, true)
    Wargroove.updateUnit(unit)

    Wargroove.playPositionlessSound("battleStart")
    Wargroove.playGrooveCutscene(unit.id)

    Wargroove.playMapSound("ragna/ragnaGroove", unit.pos)
    Wargroove.waitTime(0.25)
    Wargroove.playUnitAnimation(unit.id, "groove_1")
    Wargroove.waitTime(1.4)
    unit.pos = { x = targetPos.x, y = targetPos.y }
    Wargroove.updateUnit(unit)
    Wargroove.playMapSound("ragna/ragnaGrooveLanding", targetPos)
    Wargroove.playUnitAnimation(unit.id, "groove_2")
    Wargroove.waitTime(0.4)
    Wargroove.playGrooveEffect()
    Wargroove.spawnMapAnimation(unit.pos, 3, "fx/groove/ragna_groove_fx", "idle", "behind_units", { x = 12, y = 12 })
    
    for i, pos in ipairs(Wargroove.getTargetsInRange(targetPos, 3, "unit")) do
        local u = Wargroove.getUnitAt(pos)
        if u and Wargroove.areEnemies(u.playerId, unit.playerId) then
            local damage = Combat:getGrooveAttackerDamage(unit, u, "random", unit.pos, pos, path, nil) * 0.65
            
            u:setHealth(u.health - damage, unit.id)
            Wargroove.updateUnit(u)
            Wargroove.playUnitAnimation(u.id, "hit")
        end
    end

    Wargroove.waitTime(0.5)
end


function SplashJump:onPostUpdateUnit(unit, targetPos, strParam, path)
    GrooveVerb.onPostUpdateUnit(self, unit, targetPos, strParam, path)
    unit.pos = targetPos
end

function SplashJump:generateOrders(unitId, canMove)
    local orders = {}

    local unit = Wargroove.getUnitById(unitId)
    local unitClass = Wargroove.getUnitClass(unit.unitClassId)    
    local movePositions = {}
    if canMove then
        movePositions = Wargroove.getTargetsInRange(unit.pos, unitClass.moveRange, "empty")
    end
    table.insert(movePositions, unit.pos)

    for i, pos in pairs(movePositions) do
        if Wargroove.canStandAt("soldier", pos) then
            local targets = Wargroove.getTargetsInRangeAfterMove(unit, pos, pos, 5, "empty")
            for j, target in pairs(targets) do
                if self:canSeeTarget(target) and Wargroove.canStandAt("soldier", target) then
                    orders[#orders+1] = {targetPosition = target, strParam = "", movePosition = pos, endPosition = target}
                end
            end
        end
    end

    return orders
end

function SplashJump:getScore(unitId, order)
    local unit = Wargroove.getUnitById(unitId)
    local targets = Wargroove.getTargetsInRangeAfterMove(unit, order.endPosition, order.endPosition, 3, "unit")

    local opportunityCost = -1
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

    for i, target in ipairs(targets) do
        local u = Wargroove.getUnitAt(target)
        if u ~= nil and canTarget(u) then
            local damage = Combat:getGrooveAttackerDamage(unit, u, "aiSimulation", unit.pos, u.pos, path, nil) * 0.65
            local newHealth = math.max(0, u.health - damage)
            local theirValue = Wargroove.getAIUnitValue(u.id, target)
            local theirDelta = theirValue - Wargroove.getAIUnitValueWithHealth(u.id, target, newHealth)
            effectivenessScore = effectivenessScore + theirDelta
            totalValue = totalValue + theirValue
        end
    end

    local locationGradient = 0.0
    if (Wargroove.getAICanLookAhead(unitId)) then
        locationGradient = Wargroove.getAILocationScore(unit.unitClassId, order.endPosition) - Wargroove.getAILocationScore(unit.unitClassId, unit.pos)
    end
    local gradientBonus = 0.0
    if (locationGradient > 0.0001) then
        gradientBonus = 0.25
    end
    
    local locationScore = Wargroove.getAIUnitValue(unit.id, order.endPosition) - Wargroove.getAIUnitValue(unit.id, unit.pos)

    local bravery = Wargroove.getAIBraveryBonus()
    local attackBias = Wargroove.getAIAttackBias()

    local score = (effectivenessScore + gradientBonus + bravery) * attackBias + locationScore + opportunityCost
    local introspection = {
        {key = "effectivenessScore", value = effectivenessScore},
        {key = "totalValue", value = totalValue},
        {key = "bravery", value = bravery},
        {key = "attackBias", value = attackBias},
        {key = "locationScore", value = locationScore},
        {key = "opportunityCost", value = opportunityCost}}

    return {score = score, introspection = introspection}
end


return SplashJump
