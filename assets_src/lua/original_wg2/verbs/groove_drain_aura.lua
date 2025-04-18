local Wargroove = require "wargroove/wargroove"
local GrooveVerb = require "wargroove/groove_verb"

local Drain = GrooveVerb:new()

local maxDrainAmount = { 30, 30 }
local drainRadius = { 3, 3 }
local armyDrain = { 0, 10 }
local tierUsed


function Drain:getMaximumRange(unit, endPos)
    return 0
end


function Drain:getTargetType()
    return "unit"
end


function Drain:getSplashTargets(unit, targetPos, endPos)
    local tier = self:getCurrentGrooveTier(unit)

    local targets = Wargroove.getTargetsInRange(targetPos, drainRadius[tier], "all")
    return targets
end


function Drain:execute(unit, targetPos, strParam, path)
    local tier = self:getCurrentGrooveTier(unit)

    tierUsed = tier

    Wargroove.setIsUsingGroove(unit.id, true)
    Wargroove.updateUnit(unit)

    if tier == 2 then
        Wargroove.playGrooveChargeUp(unit.pos, unit.playerId)
    end

    Wargroove.playPositionlessSound("battleStart")
    Wargroove.playGrooveCutscene(unit.id, tier)

    local targets = Wargroove.getTargetsInRange(targetPos, drainRadius[tier], "unit")

    Wargroove.playUnitAnimation(unit.id, "groove")
    Wargroove.playMapSound("darkmercia/darkmerciaGroove", targetPos)
    Wargroove.waitTime(2.4)
    if tier == 1 then
        Wargroove.spawnPaletteSwappedMapAnimation(targetPos, drainRadius[tier], "fx/groove/darkmercia_groove_fx", "idle", "behind_units", {x = 12, y = 12})
    else
        Wargroove.spawnPaletteSwappedMapAnimation(targetPos, drainRadius[tier], "fx/groove/darkmercia_groove_fx_2", "idle", "behind_units", {x = 12, y = 12})
    end

    Wargroove.playGrooveEffect()

    local function distFromTarget(a)
        return math.abs(a.x - targetPos.x) + math.abs(a.y - targetPos.y)
    end
    table.sort(targets, function(a, b) return distFromTarget(a) < distFromTarget(b) end)

    local healthDrained = 0

    for i, pos in ipairs(targets) do
        local u = Wargroove.getUnitAt(pos)
        local uc = u.unitClass
        if u ~= nil and Wargroove.areEnemies(u.playerId, unit.playerId) and (not uc.isStructure) then
            healthDrained = healthDrained + math.min(u.health, maxDrainAmount[tier])

            u:setHealth(u.health - maxDrainAmount[tier], unit.id)
            Wargroove.updateUnit(u)
            Wargroove.spawnPaletteSwappedMapAnimation(pos, 0, "fx/drain_unit")
            Wargroove.playMapSound("darkmercia/darkmerciaGrooveUnitDrained", pos)
            Wargroove.waitTime(0.2)
        end
    end

    if tier == 2 then
        local allUnits = Wargroove.getAllUnitIds()
        for _, id in ipairs(allUnits) do
            local u = Wargroove.getUnitById(id)
            if not u.unitClass.isStructure and Wargroove.areEnemies(unit.playerId, u.playerId) then
                healthDrained = healthDrained + math.min(u.health, armyDrain[tier])

                u:setHealth(u.health - armyDrain[tier], unit.id)
                Wargroove.updateUnit(u)
                Wargroove.spawnMapAnimation(u.pos, 0, "fx/groove/aoe_leech_unit", "idle", "over_units")
            end
        end
        
        Wargroove.playMapSound("darkmercia/darkmerciaGrooveUnitDrained", unit.pos)
    end

    unit:setHealth(unit.health + healthDrained, unit.id)

    Wargroove.logAnalyticsAction("UnitAbility", unit.playerId, "groove", unit.unitClassId)

    Wargroove.waitTime(0.6)
end

function Drain:generateOrders(unitId, canMove)
    local orders = {}

    local unit = Wargroove.getUnitById(unitId)
    local unitClass = Wargroove.getUnitClass(unit.unitClassId)
    local movePositions = {}
    if canMove then
        movePositions = Wargroove.getTargetsInRange(unit.pos, unitClass.moveRange, "empty")
    end
    table.insert(movePositions, unit.pos)

    for i, pos in pairs(movePositions) do
        local targets = Wargroove.getTargetsInRangeAfterMove(unit, pos, pos, 3, "unit")
        if #targets ~= 0 then
            if self:canSeeTarget(pos) then
                orders[#orders+1] = {targetPosition = pos, strParam = "", movePosition = pos, endPosition = pos}
            end
        end
    end

    return orders
end

function Drain:getScore(unitId, order)
    local unit = Wargroove.getUnitById(unitId)
    local targets = Wargroove.getTargetsInRangeAfterMove(unit, order.endPosition, order.targetPosition, 3, "unit")

    local opportunityCost = -1

    local function canTarget(u)
        if not Wargroove.areEnemies(u.playerId, unit.playerId) then
            return false
        end
        if Wargroove.hasAIRestriction(unit.id, "only_target_commander") and not u.unitClass.isCommander then
            return false
        end
        if Wargroove.hasAIRestriction(u.id, "dont_target_this") then
            return false
        end
        return true
    end

    local damageDrained = 0
    local damageOthersScore = 0
    for i, pos in ipairs(targets) do
        local u = Wargroove.getUnitAt(pos)
        if u ~= nil and canTarget(u) then
            local targetClass = Wargroove.getUnitClass(u.unitClassId)
            local targetValue = math.sqrt(targetClass.cost / 100)
            if targetClass.isCommander then
              targetValue = 10
            end
            local damage = math.min(u.health, 30)
            damageDrained = damageDrained + damage
            if not targetClass.isStructure then
                damageOthersScore = damageOthersScore + (damage / 100) * targetValue
            end
        end
    end

    local uc = Wargroove.getUnitClass(unit.unitClassId)
    local unitValue = 10
    local healAmount = math.min(damageDrained, 100 - unit.health)
    local healSelfScore = (healAmount / 100) * unitValue

    local score = opportunityCost + damageOthersScore + healSelfScore
    return { score = score, healthDelta = healAmount, introspection = {
        { key = "opportunityCost", value = opportunityCost },
        { key = "damageOthersScore", value = damageOthersScore },
        { key = "healSelfScore", value = healSelfScore }}}
end

return Drain
