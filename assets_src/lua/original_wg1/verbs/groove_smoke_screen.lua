local Wargroove = require "wargroove/wargroove"
local GrooveVerb = require "wargroove/groove_verb"

local SmokeScreen = GrooveVerb:new()


function SmokeScreen:getMaximumRange(unit, endPos)
    return 96
end

function SmokeScreen:getTargetType()
  return "all"
end

function SmokeScreen:canExecuteWithTarget(unit, endPos, targetPos, strParam)
    if not self:canSeeTarget(targetPos) then
        return false
    end

    return true
end

function SmokeScreen:execute(unit, targetPos, strParam, path)
    Wargroove.setIsUsingGroove(unit.id, true)
    Wargroove.updateUnit(unit)
    
    Wargroove.playPositionlessSound("battleStart")
    Wargroove.playGrooveCutscene(unit.id)

    Wargroove.playUnitAnimation(unit.id, "groove")
    Wargroove.playMapSound("vesper/vesperGroove", unit.pos)
    Wargroove.waitTime(1.0)
    Wargroove.playMapSound("cutscene/smokeBomb", targetPos)
    Wargroove.spawnMapAnimation(targetPos, 3, "fx/groove/vesper_groove_fx", "idle", "over_units", {x = 12, y = 12})

    Wargroove.playGrooveEffect()

    local startingState = {}
    local pos = {key = "pos", value = "" .. targetPos.x .. "," .. targetPos.y}
    table.insert(startingState, pos)
    Wargroove.spawnUnit(unit.playerId, {x = -100, y = -100}, "smoke_producer", false, "", startingState)

    Wargroove.waitTime(1.0)
end

function SmokeScreen:generateOrders(unitId, canMove)
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
            if target ~= pos and self:canSeeTarget(target) then
                orders[#orders+1] = {targetPosition = target, strParam = "", movePosition = pos, endPosition = pos}
            end
        end
    end

    return orders
end

function SmokeScreen:getScore(unitId, order)
    local unit = Wargroove.getUnitById(unitId)
    local targets = Wargroove.getTargetsInRangeAfterMove(unit, order.endPosition, order.targetPosition, 2, "unit")

    local opportunityCost = -1
    local totalScore = 0
    local maxScore = 300

    for i, pos in ipairs(targets) do
        local u = Wargroove.getUnitAt(pos)
        if u ~= nil then
            local uc = Wargroove.getUnitClass(u.unitClassId)
            if not Wargroove.areEnemies(unit.playerId, u.playerId) then
                totalScore = totalScore + uc.cost
            else
                totalScore = totalScore - uc.cost
            end
        end
    end
    
    local score = totalScore/maxScore + opportunityCost
    return {score = score, introspection = {{key = "totalScore", value = totalScore}}}
end

return SmokeScreen
