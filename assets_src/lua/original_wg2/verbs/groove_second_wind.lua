local Wargroove = require "wargroove/wargroove"
local GrooveVerb = require "wargroove/groove_verb"

local SecondWind = GrooveVerb:new()

local inspireRange = { 1, 2 }
local modifiers = { "", "caesar_inspire_high" }

function SecondWind:getMaximumRange(unit, endPos)
    return 0
end


function SecondWind:getTargetType()
    return "unit"
end


function SecondWind:getSplashTargets(unit, targetPos, endPos)
    local tier = self:getCurrentGrooveTier(unit)

    local targets = Wargroove.getTargetsInRange(targetPos, inspireRange[tier], "all")
    return targets
end


function SecondWind:execute(unit, targetPos, strParam, path)
    local tier = self:getCurrentGrooveTier(unit)

    Wargroove.setIsUsingGroove(unit.id, true)
    Wargroove.updateUnit(unit)

    if tier == 2 then
        Wargroove.playGrooveChargeUp(unit.pos, unit.playerId)
    end

    Wargroove.playPositionlessSound("battleStart")
    Wargroove.playGrooveCutscene(unit.id, tier)

    Wargroove.playUnitAnimation(unit.id, "groove")
    Wargroove.playMapSound("caesar/caesarGroove", unit.pos)
    Wargroove.spawnMapAnimation(unit.pos, 1, "fx/groove/caesar_groove_fx")
    Wargroove.waitTime(1.9)
    Wargroove.playMapSound("caesar/caesarGrooveInspired", unit.pos)

    Wargroove.playGrooveEffect()

    for i, pos in ipairs(Wargroove.getTargetsInRange(targetPos, inspireRange[tier], "unit")) do
        local u = Wargroove.getUnitAt(pos)
        
        if Wargroove.areAllies(u.playerId, unit.playerId) and u.id ~= unit.id and Wargroove.isInList(u.unitClassId, Wargroove.getTroopUnitClasses()) then
            Wargroove.spawnMapAnimation(pos, 0, "fx/groove/inspire_unit")
            if u.hadTurn then
                u.hadTurn = false
            end

            local modifier = modifiers[tier]
            if modifier ~= "" then
                Wargroove.pushUnitClassModifier(u.id, modifier)
                Wargroove.pushBuff(1, u, unit.playerId, "inspire_high_spawn", "inspire_high", "inspire_high_death")
            end
            
            Wargroove.updateUnit(u)
        end
    end

    Wargroove.waitTime(1.0)

    Wargroove.logAnalyticsAction("UnitAbility", unit.playerId, "groove", unit.unitClassId)
end

function SecondWind:generateOrders(unitId, canMove)
    local orders = {}

    local unit = Wargroove.getUnitById(unitId)
    local unitClass = Wargroove.getUnitClass(unit.unitClassId)
    local movePositions = {}
    if canMove then
        movePositions = Wargroove.getTargetsInRange(unit.pos, unitClass.moveRange, "empty")
    end
    table.insert(movePositions, unit.pos)

    for i, pos in pairs(movePositions) do
        local targets = Wargroove.getTargetsInRangeAfterMove(unit, pos, pos, 1, "unit")
        if #targets ~= 0 then
            orders[#orders+1] = {targetPosition = pos, strParam = "", movePosition = pos, endPosition = pos}
        end
    end

    return orders
end

function SecondWind:getScore(unitId, order)
    local unit = Wargroove.getUnitById(unitId)
    local targets = Wargroove.getTargetsInRangeAfterMove(unit, order.endPosition, order.targetPosition, 1, "unit")

    local opportunityCost = -1

    local effectScore = 0
    for i, pos in ipairs(targets) do
        local u = Wargroove.getUnitAt(pos)
        if u ~= nil and Wargroove.areAllies(u.playerId, unit.playerId) and u.hadTurn and Wargroove.isInList(u.unitClassId, Wargroove.getTroopUnitClasses()) then
            local uc = Wargroove.getUnitClass(u.unitClassId)
            if not uc.isStructure then
                local uValue = math.sqrt(uc.cost / 100)
                if uc.isCommander then
                    uValue = 10
                end
                effectScore = effectScore + (u.health / 100) * uValue
            end
        end
    end


    local score = opportunityCost + effectScore

    return {score = score, introspection = {
        { key = "opportunityCost", value = opportunityCost },
        { key = "effectScore", value = effectScore }}}
end


return SecondWind
