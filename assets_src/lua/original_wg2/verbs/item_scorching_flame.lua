local Wargroove = require "wargroove/wargroove"
local ItemVerb = require "wargroove/item_verb"

local damageAmount = 25
local flameRadius = 3

local ScorchingFlame = ItemVerb:new()

function ScorchingFlame:getMaximumRange(unit, endPos)
    return 1
end

function ScorchingFlame:getTargetType()
    return "all"
end

function ScorchingFlame:isInCone(unitPos, directionPos, targetPos, maxDist)
    local xDiff = targetPos.x - directionPos.x
    local yDiff = targetPos.y - directionPos.y
    local absXDiff = math.abs(xDiff)
    local absYDiff = math.abs(yDiff)
    if directionPos.x > unitPos.x and xDiff < 0 then
      return false
    elseif directionPos.x < unitPos.x and xDiff > 0 then
      return false
    elseif directionPos.y > unitPos.y and yDiff < 0 then
      return false
    elseif directionPos.y < unitPos.y and yDiff > 0 then
      return false
    end
  
    if (unitPos.x == directionPos.x) then
      if absXDiff > absYDiff or absYDiff > maxDist then
        return false
      end
    else
      if absYDiff > absXDiff or absXDiff > maxDist then
        return false
      end
    end
  
    return true
end

function ScorchingFlame:getSplashTargets(targetPos, endPos)
    local direction = { x = targetPos.x - endPos.x, y = targetPos.y - endPos.y}
    local targets = {}

    local possibleTargets = Wargroove.getTargetsInRangeSquare(endPos, flameRadius, "all")
    for i, pos in pairs(possibleTargets) do
        if self:isInCone(endPos, targetPos, pos, flameRadius) then
            table.insert(targets, pos)
        end
    end

    return targets
end

function ScorchingFlame:canExecuteWithTarget(unit, endPos, targetPos, strParam)
    if not self:canSeeTarget(targetPos) then
        return false
    end

    if targetPos.x == endPos.x and targetPos.y == endPos.y then
        return false
    end

    return true
end

function ScorchingFlame:execute(unit, targetPos, strParam, path)
    local targetTiles = self:getSplashTargets(targetPos, unit.pos)

    for i=1, #targetTiles do
        local pos = targetTiles[#targetTiles + 1 - i]
        local targetUnit = Wargroove.getUnitAt(pos)

        Wargroove.spawnMapAnimation(pos, 1, "fx/groove/orla_groove_fx", "idle", "behind_units", {x = 13, y = 16})
        if targetUnit and Wargroove.areEnemies(unit.playerId, targetUnit.playerId) then
            targetUnit.health = math.max(targetUnit.health - damageAmount, 0)
            Wargroove.playUnitAnimation(targetUnit.id, "hit")
    
            Wargroove.updateUnit(targetUnit)
        end
        Wargroove.waitTime(0.1)
    end
end

return ScorchingFlame