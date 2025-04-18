local Wargroove = require "wargroove/wargroove"
local Verb = require "wargroove/verb"

local EncourageTarget = Verb:new()

local attackRange = 4

function EncourageTarget:getMaximumRange(unit, endPos)
    return attackRange
end

function EncourageTarget:getTargetType()
    return "unit"
end

function EncourageTarget:canExecuteWithTarget(unit, endPos, targetPos, strParam)
    if not self:canSeeTarget(targetPos) then
        return false
    end

    local targetUnit = Wargroove.getUnitAt(targetPos)

    if not targetUnit or (not targetUnit.canBeAttacked) or (not targetUnit.unitClass.isAttackable) then
        return false
    end

    if not targetUnit.hadTurn then
        return false
    end
    
    if targetUnit.unitClass.isCommander or targetUnit.unitClass.isStructure then
        return false
    end

    if not Wargroove.areAllies(targetUnit.playerId, unit.playerId) then
        return false
    end

    for i, tag in ipairs(targetUnit.unitClass.tags) do
        if tag == "summon" then
            return false
        end
    end

    return true
end

function EncourageTarget:execute(unit, targetPos, strParam, path)
    local targetUnit = Wargroove.getUnitAt(targetPos)
    if targetUnit == nil then
        return
    end

    Wargroove.trackCameraTo(targetUnit.pos)
    Wargroove.waitTime(0.35)
    
    Wargroove.playMapSound("knightPreAttackGreen", unit.pos)
    Wargroove.waitTime(0.5)

    Wargroove.spawnMapAnimation(targetUnit.pos, 0, "fx/groove/inspire_unit")
    targetUnit.hadTurn = false
    Wargroove.updateUnit(targetUnit)

    Wargroove.playMapSound("caesar/caesarGrooveInspired", unit.pos)

    Wargroove.waitTime(0.2)
end

function EncourageTarget:generateOrders(unitId, canMove)
    local orders = {}

    local unit = Wargroove.getUnitById(unitId)
    local unitClass = Wargroove.getUnitClass(unit.unitClassId)
    local movePositions = {}
    if canMove then
        movePositions = Wargroove.getTargetsInRange(unit.pos, unitClass.moveRange, "empty")
    end
    table.insert(movePositions, unit.pos)

    for i, pos in pairs(movePositions) do
        local targets = Wargroove.getTargetsInRangeAfterMove(unit, pos, pos, attackRange, "unit")
        for j, targetPos in pairs(targets) do
            local u = Wargroove.getUnitAt(targetPos)
            if u ~= nil then
                local uc = Wargroove.getUnitClass(u.unitClassId)
                if self:canExecuteWithTarget(unit, pos, targetPos, "") and not Wargroove.hasAIRestriction(u.id, "dont_target_this") then
                    orders[#orders+1] = {targetPosition = targetPos, strParam = "", movePosition = pos, endPosition = pos}
                end
            end
        end
    end

    return orders
end

function EncourageTarget:getScore(unitId, order)
    local unit = Wargroove.getUnitById(unitId)
    local targets = Wargroove.getTargetsInRangeAfterMove(unit, order.endPosition, order.targetPosition, attackRange, "unit")

    local opportunityCost = -1

    local effectScore = 0
    for i, pos in ipairs(targets) do
        local u = Wargroove.getUnitAt(pos)
        if u ~= nil and Wargroove.areAllies(u.playerId, unit.playerId) and u.hadTurn then
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

return EncourageTarget