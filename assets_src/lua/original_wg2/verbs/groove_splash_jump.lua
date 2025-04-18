local Wargroove = require "wargroove/wargroove"
local GrooveVerb = require "wargroove/groove_verb"
local Combat = require "wargroove/combat"

local SplashJump = GrooveVerb:new()

local knockonDamage = 20
local pushDamage = {0.5, 1.0}
local jumpRange = {3, 6}
local pushRange = {1, 2}

function SplashJump:getMaximumRange(unit, endPos)
    local tier = self:getCurrentGrooveTier(unit)
    return jumpRange[tier]
end


function SplashJump:getTargetType()
    return "all"
end


function SplashJump:getTargetArrows(unit, targetPos, endPos)
    local results = {}
    local tier = self:getCurrentGrooveTier(unit)

    for i, pos in ipairs(Wargroove.getTargetsInRange(targetPos, 1, "unit")) do
        local u = Wargroove.getUnitAt(pos)
        if u and Wargroove.areEnemies(u.playerId, unit.playerId) then
            local pushResults = Wargroove.getPushPullResult(targetPos, pos, pushRange[tier], true, false)
            
            local targetArrow = Wargroove.createTargetArrowFromPushPullResult(pushResults)
            if targetArrow then
                table.insert(results, targetArrow)
            end
        end
    end

    return results
end


function SplashJump:canExecuteWithTarget(unit, endPos, targetPos, strParam)
    if not self:canSeeTarget(targetPos) then
        return false
    end

    local u = Wargroove.getUnitAt(targetPos)
    return (u == nil or u.id == unit.id) and Wargroove.canStandAt("soldier", targetPos)
end


function SplashJump:execute(unit, targetPos, strParam, path)
    local tier = self:getCurrentGrooveTier(unit)

    Wargroove.setIsUsingGroove(unit.id, true)
    Wargroove.updateUnit(unit)

    if tier == 2 then
        Wargroove.playGrooveChargeUp(unit.pos, unit.playerId)
    end

    Wargroove.playPositionlessSound("battleStart")
    Wargroove.playGrooveCutscene(unit.id, tier)

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
    Wargroove.spawnMapAnimation(unit.pos, 2, "fx/map_effects/ragnas_special1", "idle", "behind_units", { x = 12, y = -6 })
    
    for i, pos in ipairs(Wargroove.getTargetsInRange(targetPos, 1, "unit")) do
        local u = Wargroove.getUnitAt(pos)
        if u and Wargroove.areEnemies(u.playerId, unit.playerId) then
            local pushResults = Wargroove.getPushPullResult(targetPos, pos, pushRange[tier], false)

            if pushResults == nil then
                goto NEXT_POS
            end
            
            local pushFinalDamage = Combat:getGrooveAttackerDamage(unit, u, "average", unit.pos, pos, path, nil) * pushDamage[tier]
            Wargroove.processPushPullResult(unit, pushResults, pushFinalDamage, knockonDamage)

            :: NEXT_POS ::
        end
    end

    Wargroove.waitTime(0.5)

    Wargroove.logAnalyticsAction("UnitAbility", unit.playerId, "groove", unit.unitClassId)
end


function SplashJump:onPostUpdateUnit(unit, targetPos, strParam, path)
    GrooveVerb.onPostUpdateUnit(self, unit, targetPos, strParam, path)
    unit.pos = targetPos
end

function SplashJump:generateOrders(unitId, canMove)
    local orders = {}
    
    local unit = Wargroove.getUnitById(unitId)
    local tier = self:getCurrentGrooveTier(unit)
    local unitClass = Wargroove.getUnitClass(unit.unitClassId)    
    local movePositions = {}
    if canMove then
        movePositions = Wargroove.getTargetsInRange(unit.pos, unitClass.moveRange, "empty")
    end
    table.insert(movePositions, unit.pos)

    for i, pos in pairs(movePositions) do
        if Wargroove.canStandAt("soldier", pos) then
            local targets = Wargroove.getTargetsInRangeAfterMove(unit, pos, pos, jumpRange[tier], "empty")
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
    local targets = Wargroove.getTargetsInRangeAfterMove(unit, order.endPosition, order.endPosition, 1, "unit")
    local tier = self:getCurrentGrooveTier(unit)

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
            local damage = Combat:getGrooveAttackerDamage(unit, u, "aiSimulation", unit.pos, u.pos, path, nil) * pushDamage[tier]
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
