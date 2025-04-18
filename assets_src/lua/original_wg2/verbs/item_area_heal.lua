local Wargroove = require "wargroove/wargroove"
local ItemVerb = require "wargroove/item_verb"
local ItemScores = require "wargroove/item_scores"

local ItemAreaHeal = ItemVerb:new()


function ItemAreaHeal:getMaximumRange(unit, endPos)
    return 4
end

function ItemAreaHeal:getTargetType()
  return "all"
end

function ItemAreaHeal:canExecuteWithTarget(unit, endPos, targetPos, strParam)
    if not self:canSeeTarget(targetPos) then
        return false
    end

    return true
end

function ItemAreaHeal:execute(unit, targetPos, strParam, path)
    Wargroove.trackCameraTo(unit.pos)
     
    Wargroove.playPositionlessSound("battleStart")
        
    Wargroove.playUnitAnimation(unit.id, "groove")
    Wargroove.playMapSound("twins/errolGroove", targetPos)
    Wargroove.waitTime(1.2)
    Wargroove.spawnMapAnimation(targetPos, 3, "fx/groove/errol_groove_fx", "idle", "behind_units", {x = 12, y = 12})

    Wargroove.playGrooveEffect()

    local startingState = {}
    local pos = {key = "pos", value = "" .. targetPos.x .. "," .. targetPos.y}
    local radius = {key = "radius", value = "3"}    
    table.insert(startingState, pos)
    table.insert(startingState, radius)
    Wargroove.spawnUnit(unit.playerId, {x = -100, y = -100}, "area_heal", false, "", startingState)

    Wargroove.waitTime(1.2)
end

function ItemAreaHeal:generateOrders(unitId, canMove)
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

function ItemAreaHeal:getScore(unitId, order)
    return ItemScores.getScoreAreaHeal(unitId, order)
end

return ItemAreaHeal