local Wargroove = require "wargroove/wargroove"
local Verb = require "wargroove/verb"

local RepositionVine = Verb:new()

local range = 2

function RepositionVine:getMaximumRange(unit, endPos)
    return range
end

function RepositionVine:getTargetType()
    return "empty"
end

function RepositionVine:canExecuteWithTarget(unit, endPos, targetPos, strParam)
    if not self:canSeeTarget(targetPos) then
        return false
    end

    local u = Wargroove.getUnitAt(targetPos)
    local uc = Wargroove.getUnitClass("soldier")
    return (u == nil or u.id == unit.id) and Wargroove.canStandAt("soldier", targetPos)
end


function RepositionVine:execute(unit, targetPos, strParam, path)
    if (unit.pos.x == targetPos.x and unit.pos.y == targetPos.y) then
        return
    end

    Wargroove.playUnitAnimationOnce(unit.id, "hide")
    Wargroove.waitTime(0.2)
    Wargroove.playMapSound("greenfinger/greenfingerVineRetract", unit.pos)
    Wargroove.waitTime(0.2)
    Wargroove.setShadowVisible(unit.id, false)    

    Wargroove.waitTime(0.5)

    unit.pos = { x = targetPos.x, y = targetPos.y }

    Wargroove.updateUnit(unit)
    Wargroove.playMapSound("greenfinger/greenfingerVineReposition", unit.pos)
    Wargroove.playUnitAnimation(unit.id, "spawn")
    Wargroove.waitTime(0.4)
    Wargroove.unsetShadowVisible(unit.id)

    Wargroove.waitTime(0.1)
end


function RepositionVine:onPostUpdateUnit(unit, targetPos, strParam, path)
    Verb.onPostUpdateUnit(self, unit, targetPos, strParam, path)
    unit.pos = targetPos
end

function RepositionVine:generateOrders(unitId, canMove)
    local orders = {}

    if (not canMove) then
        return orders
    end

    local unit = Wargroove.getUnitById(unitId)
    local unitClass = Wargroove.getUnitClass(unit.unitClassId)    
    local movePositions = {}
    table.insert(movePositions, unit.pos)

    for i, pos in pairs(movePositions) do
        if Wargroove.canStandAt("soldier", pos) then
            local targets = Wargroove.getTargetsInRangeAfterMove(unit, pos, pos, range, "empty")
            for j, target in pairs(targets) do
                if self:canSeeTarget(target) and Wargroove.canStandAt("soldier", target) then
                    orders[#orders+1] = {targetPosition = target, strParam = "", movePosition = pos, endPosition = target}
                end
            end
        end
    end

    return orders
end

function RepositionVine:getScore(unitId, order)
    local unit = Wargroove.getUnitById(unitId)

    local opportunityCost = -1

    local locationGradient = 0.0
    if (Wargroove.getAICanLookAhead(unitId)) then
        locationGradient = Wargroove.getAILocationScore(unit.unitClassId, order.endPosition) - Wargroove.getAILocationScore(unit.unitClassId, unit.pos)
    end
    local gradientBonus = 0.0
    if (locationGradient > 0.0001) then
        gradientBonus = 0.25
    end
    
    local locationScore = Wargroove.getAIUnitValue(unit.id, order.endPosition) - Wargroove.getAIUnitValue(unit.id, unit.pos)

    local score = gradientBonus + locationScore
    local introspection = {
        {key = "locationScore", value = locationScore},
        {key = "gradientBonus", value = gradientBonus}}

    return {score = score, introspection = introspection}
end


return RepositionVine
