local Wargroove = require "wargroove/wargroove"
local GrooveVerb = require "wargroove/groove_verb"


local Convert = GrooveVerb:new()


function Convert:getMaximumRange(unit, endPos)
    return 1
end


function Convert:getTargetType()
    return "unit"
end


function Convert:canExecuteWithTarget(unit, endPos, targetPos, strParam)
    if not self:canSeeTarget(targetPos) then
        return false
    end

    -- Exception list
    local convertExceptions = { "tentacle" }
    if Wargroove.isInList(unit.unitClassId, convertExceptions) then
        return false
    end

    local targetUnit = Wargroove.getUnitAt(targetPos)
    return targetUnit and not targetUnit.unitClass.isStructure and not targetUnit.unitClass.isCommander and Wargroove.areEnemies(unit.playerId, targetUnit.playerId) and targetUnit.canBeAttacked and (targetUnit.unitClass.isAttackable)
end


function Convert:execute(unit, targetPos, strParam, path)
    local tier = self:getCurrentGrooveTier(unit)

    Wargroove.setIsUsingGroove(unit.id, true)
    Wargroove.updateUnit(unit)

    Wargroove.playMapSound("battleStart", unit.pos)
    Wargroove.playGrooveCutscene(unit.id, tier)

    Wargroove.playUnitAnimation(unit.id, "groove")
    Wargroove.playMapSound("elodie/elodieGroove", unit.pos)
    Wargroove.waitTime(1.9)
    Wargroove.playGrooveEffect()
    local endPos = unit.pos
    if path and #path > 0 then
        endPos = path[#path]
    end
    local targetUnit = Wargroove.getUnitAt(targetPos)

    -- Make sure we untangle krakens
    if targetUnit.unitClassId == "kraken" then
        Wargroove.untangleKraken(targetUnit)
    end

    if tier == 1 then
        Wargroove.setUnitState(targetUnit, "originalPlayerId", tostring(targetUnit.playerId))
        Wargroove.pushBuff(1, targetUnit, targetUnit.playerId, "convert_spawn", "convert", "convert_death")
        
        targetUnit.playerId = unit.playerId
        Wargroove.spawnPaletteSwappedMapAnimation(targetPos, 0, "fx/groove/elodie_groove_fx", unit.playerId, "idle", "over_units", {x = 12, y = 12})
    else
        Wargroove.spawnPaletteSwappedMapAnimation(targetPos, 0, "fx/groove/elodie_groove_fx", unit.playerId, "idle", "over_units", {x = 12, y = 12})
        Wargroove.spawnPaletteSwappedMapAnimation(targetPos, 0, "fx/groove/control_unit", unit.playerId, "spawn", "over_units", {x = 12, y = 12})
        targetUnit.playerId = unit.playerId
    end

    Wargroove.updateUnit(targetUnit)

    Wargroove.logAnalyticsAction("UnitAbility", unit.playerId, "groove", unit.unitClassId)
end

function Convert:generateOrders(unitId, canMove)
    local orders = {}

    local unit = Wargroove.getUnitById(unitId)
    local unitClass = Wargroove.getUnitClass(unit.unitClassId)
    local movePositions = {}
    if canMove then
        movePositions = Wargroove.getTargetsInRange(unit.pos, unitClass.moveRange, "empty")
    end
    table.insert(movePositions, unit.pos)

    local function canTarget(pos, u)
        if Wargroove.hasAIRestriction(u.id, "dont_target_this") then
            return false
        end
        return self:canExecuteWithTarget(unit, pos, u.pos, "")
    end

    for i, pos in pairs(movePositions) do
        local targets = Wargroove.getTargetsInRangeAfterMove(unit, pos, pos, 1, "unit")
        for j, targetPos in pairs(targets) do
            local u = Wargroove.getUnitAt(targetPos)
            if u ~= nil and canTarget(pos, u) then
                orders[#orders+1] = {targetPosition = targetPos, strParam = "", movePosition = pos, endPosition = pos}
            end
        end
    end

    return orders
end

function Convert:getScore(unitId, order)
    local unit = Wargroove.getUnitById(unitId)

    local targetUnit = Wargroove.getUnitAt(order.targetPosition)
    local targetUnitClass = Wargroove.getUnitClass(targetUnit.unitClassId)

    local opportunityCost = -1
    local score = targetUnitClass.cost * targetUnit.health
    local maxScore = 300 * 100
    
    local normalizedScore = score / maxScore + opportunityCost

    return {score = normalizedScore, introspection = {{key = "unitCost", value = targetUnitClass.cost}, {key = "unitHealth", value = targetUnit.health}, {key = "maxScore", value = maxScore}}}
end

return Convert
