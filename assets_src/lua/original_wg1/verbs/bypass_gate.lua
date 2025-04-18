local Wargroove = require "wargroove/wargroove"
local Verb = require "wargroove/verb"

local BypassGate = Verb:new()

function BypassGate:getMaximumRange(unit, endPos)
  return 1
end

function BypassGate:getTargetType()
  return "unit"
end

function BypassGate:getPointBeyond(unit, targetPos)
  local direction = { x = targetPos.x - unit.pos.x, y = targetPos.y - unit.pos.y}
  return { x = targetPos.x + direction.x, y = targetPos.y + direction.y}
end

function BypassGate:canExecuteWithTarget(unit, endPos, targetPos, strParam)
  local targetUnit = Wargroove.getUnitAt(targetPos)
  if targetUnit == nil or targetUnit.unitClassId ~= "gate" then
    return false
  end

  local direction = { x = targetPos.x - endPos.x, y = targetPos.y - endPos.y}
  local pointBeyond = { x = targetPos.x + direction.x, y = targetPos.y + direction.y}

  local unitBeyond = Wargroove.getUnitAt(pointBeyond)
  return unitBeyond == nil and Wargroove.canStandAt("soldier", pointBeyond)
end

function BypassGate:execute(unit, targetPos, strParam, path)
  local pointBeyond = BypassGate:getPointBeyond(unit, targetPos)

  if targetPos.x > unit.pos.x then
    unit.pos.facing = 1
  elseif targetPos.x < unit.pos.x then
    unit.pos.facing = 3
  end
  Wargroove.updateUnit(unit)

  if Wargroove.canCurrentlySeeTile(unit.pos) then
    Wargroove.spawnMapAnimation(unit.pos, 0, "fx/mapeditor_unitdrop")
    Wargroove.playMapSound("spawn", unit.pos)
  end
  Wargroove.setVisibleOverride(unit.id, false)

  Wargroove.waitTime(0.5)
end

function BypassGate:onPostUpdateUnit(unit, targetPos, strParam, path)
  Verb.onPostUpdateUnit(self, unit, targetPos, strParam, path)

  local facing
  if targetPos.x > unit.pos.x then
    facing = 1
  elseif targetPos.x < unit.pos.x then
    facing = 3
  end

  unit.pos = BypassGate:getPointBeyond(unit, targetPos)
  unit.pos.facing = facing
  
  Wargroove.updateUnit(unit)
  coroutine.yield()
  if Wargroove.canCurrentlySeeTile(unit.pos) then
    Wargroove.spawnMapAnimation(unit.pos, 0, "fx/mapeditor_unitdrop")
    Wargroove.playMapSound("spawn", unit.pos)
  end
  Wargroove.unsetVisibleOverride(unit.id)
end

function BypassGate:generateOrders(unitId, canMove)
    local orders = {}

    local unit = Wargroove.getUnitById(unitId)
    local unitClass = Wargroove.getUnitClass(unit.unitClassId)    
    local movePositions = {}
    if canMove then
        movePositions = Wargroove.getTargetsInRange(unit.pos, unitClass.moveRange, "empty")
    end
    table.insert(movePositions, unit.pos)

    for i, pos in pairs(movePositions) do
        if Wargroove.canStandAt("soldier", pos) then
            local targets = Wargroove.getTargetsInRangeAfterMove(unit, pos, pos, 5, "unit")            
            for j, target in pairs(targets) do
                if not self:canSeeTarget(target) then
                  return false
                end

                if self:canExecuteWithTarget(unit, pos, target, "") then
                  orders[#orders+1] = {targetPosition = target, strParam = "", movePosition = pos, endPosition = target}
                end
            end
        end
    end

    return orders
end

function BypassGate:getScore(unitId, order)
    local unit = Wargroove.getUnitById(unitId)
    local pointBeyond = BypassGate:getPointBeyond(unit, order.targetPosition)

    local opportunityCost = -1

    --- unit score
    local unitScore = Wargroove.getAIUnitValue(unit.id, unit.pos)
    local newUnitScore = Wargroove.getAIUnitValue(unit.id, pointBeyond)
    local delta = newUnitScore - unitScore

    --- location score
    local startScore = Wargroove.getAILocationScore(unit.unitClassId, unit.pos)
    local endScore = Wargroove.getAILocationScore(unit.unitClassId, pointBeyond)

    local locationGradient = endScore - startScore
    local gradientBonus = 0
    if locationGradient > 0.00001 then
        gradientBonus = 0.25
    end

    local score = (delta + gradientBonus) + opportunityCost

    return {score = score, introspection = {
        {key = "delta", value = delta},
        {key = "gradientBonus", value = gradientBonus},
        {key = "manhattanDistance", value = manhattanDistance},
        {key = "opportunityCost", value = opportunityCost}}}
end

return BypassGate
