local Wargroove = require "wargroove/wargroove"
local GrooveVerb = require "wargroove/groove_verb"

local RaiseDead = GrooveVerb:new()


function RaiseDead:getMaximumRange(unit, endPos)
    return 1
end


function RaiseDead:getTargetType()
    return "empty"
end


function RaiseDead:canExecuteWithTarget(unit, endPos, targetPos, strParam)
    if not self:canSeeTarget(targetPos) then
        return false
    end

    local unitThere = Wargroove.getUnitAt(targetPos)
    return (unitThere == nil or unitThere == unit) and Wargroove.canStandAt("soldier", targetPos)
end


function RaiseDead:execute(unit, targetPos, strParam, path)
    Wargroove.setIsUsingGroove(unit.id, true)
    Wargroove.updateUnit(unit)

    Wargroove.playPositionlessSound("battleStart")
    Wargroove.playGrooveCutscene(unit.id)

    Wargroove.playUnitAnimation(unit.id, "groove")
    Wargroove.playMapSound("valder/valderGroove", unit.pos)
    Wargroove.waitTime(1.7)

    Wargroove.playGrooveEffect()

    Wargroove.spawnUnit(unit.playerId, targetPos, "felheim:soldier", false, "summon")
    Wargroove.playMapSound("valder/valderGrooveSummon", targetPos)
    Wargroove.waitTime(1.0)
end

function RaiseDead:generateOrders(unitId, canMove)
    local orders = {}

    local unit = Wargroove.getUnitById(unitId)
    local unitClass = Wargroove.getUnitClass(unit.unitClassId)
    local movePositions = {}
    if canMove then
        movePositions = Wargroove.getTargetsInRange(unit.pos, unitClass.moveRange, "empty")
    end
    table.insert(movePositions, unit.pos)

    for i, pos in pairs(movePositions) do
        local targets = Wargroove.getTargetsInRangeAfterMove(unit, pos, pos, 1, "empty")
        for j, targetPos in pairs(targets) do
            if targetPos ~= pos  and Wargroove.canStandAt("soldier", targetPos) and self:canSeeTarget(targetPos) then
                orders[#orders+1] = {targetPosition = targetPos, strParam = "", movePosition = pos, endPosition = pos}
            end
        end
    end

    return orders
end

function RaiseDead:getScore(unitId, order)
    return {score = 2, introspection = {}}
end

return RaiseDead
