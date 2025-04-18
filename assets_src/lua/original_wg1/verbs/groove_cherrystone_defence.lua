local Wargroove = require "wargroove/wargroove"
local GrooveVerb = require "wargroove/groove_verb"

local CherrystoneDefence = GrooveVerb:new()

local range = 3

function CherrystoneDefence:getMaximumRange(unit, endPos)
    return 1
end


function CherrystoneDefence:getTargetType()
    return "empty"
end

function CherrystoneDefence:canExecuteWithTarget(unit, endPos, targetPos, strParam)
    if not self:canSeeTarget(targetPos) then
        return false
    end

    local u = Wargroove.getUnitAt(targetPos)
    return (endPos.x ~= targetPos.x or endPos.y ~= targetPos.y) 
        and (u == nil or unit.id == u.id)
        and Wargroove.canStandAt("soldier", targetPos)
end

function CherrystoneDefence:execute(unit, targetPos, strParam, path)
    Wargroove.setIsUsingGroove(unit.id, true)
    Wargroove.updateUnit(unit)
    
    Wargroove.playPositionlessSound("battleStart")
    Wargroove.playGrooveCutscene(unit.id)
        
    Wargroove.playUnitAnimation(unit.id, "groove")
    Wargroove.playMapSound("emeric/emericGroove", targetPos)
    Wargroove.waitTime(1.3)
    Wargroove.playGrooveEffect()
    Wargroove.spawnUnit(unit.playerId, targetPos, "crystal", false, "spawn")

    coroutine.yield()

    local effectPositions = Wargroove.getTargetsInRange(targetPos, range, "all")
    local crystal = Wargroove.getUnitAt(targetPos)
    Wargroove.displayBuffVisualEffect(crystal.id, unit.playerId, "units/commanders/emeric/crystal_aura", "spawn", 0.3, effectPositions)

    Wargroove.waitTime(1.2)
end

function CherrystoneDefence:generateOrders(unitId, canMove)
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
        for j, target in pairs(targets) do
            if target ~= pos and self:canSeeTarget(target) and Wargroove.canStandAt("soldier", target) then
                orders[#orders+1] = {targetPosition = target, strParam = "", movePosition = pos, endPosition = pos}
            end
        end
    end

    return orders
end

function CherrystoneDefence:getScore(unitId, order)
    local unit = Wargroove.getUnitById(unitId)
    local targets = Wargroove.getTargetsInRangeAfterMove(unit, order.endPosition, order.targetPosition, range, "unit")

    local opportunityCost = -1
    local totalScore = 0
    local maxScore = 300

    for i, pos in ipairs(targets) do
        local u = Wargroove.getUnitAt(pos)
        if u ~= nil and u.playerId == unit.playerId then
            local uc = Wargroove.getUnitClass(u.unitClassId)
            if not uc.isStructure then
                totalScore = totalScore + uc.cost
            end
        end
    end
    
    local score = totalScore/maxScore + opportunityCost
    return {score = score, introspection = {{key = "totalScore", value = totalScore}}}
end

return CherrystoneDefence
