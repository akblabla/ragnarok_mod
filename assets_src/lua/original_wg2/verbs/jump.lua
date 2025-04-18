local Wargroove = require "wargroove/wargroove"
local Verb = require "wargroove/verb"

local Jump = Verb:new()

function Jump:getMaximumRange(unit, endPos)
    return 1
end

function Jump:getTargetType()
    return "all"
end

function Jump:getPointBeyond(endPos, targetPos)
    local direction = { x = targetPos.x - endPos.x, y = targetPos.y - endPos.y}
    return { x = targetPos.x + direction.x, y = targetPos.y + direction.y}
end

function Jump:canExecuteWithTarget(unit, endPos, targetPos, strParam)
    if not self:canSeeTarget(targetPos) then
        return false
    end

    -- no jumping in water
    local terrainName = Wargroove.getTerrainNameAt(targetPos)
    if terrainName == "ocean" or terrainName == "reef" or terrainName == "sea" then
        return false
    end

    local target = Wargroove.getUnitAt(targetPos)
    if (not target) and terrainName ~= "wall" then
        return false
    end

    local beyondPos = Jump:getPointBeyond(endPos, targetPos)
    local beyondUnit = Wargroove.getUnitAt(beyondPos)

    return Wargroove.canStandAt(unit.unitClassId, beyondPos) and beyondUnit == nil and self:canSeeTarget(beyondPos)
end

function Jump:execute(unit, targetPos, strParam, path)
    local beyondPos = Jump:getPointBeyond(unit.pos, targetPos)

    local numSteps = 5

    local steps = {}
    local xDiff = beyondPos.x - unit.pos.x
    local yDiff = beyondPos.y - unit.pos.y
    local xStep = xDiff / numSteps
    local yStep = yDiff / numSteps
    for i = 1,numSteps do
      if (xDiff ~= 0) then
        local radians = i / numSteps * 3.14
        steps[i] = {x = xStep * i, y = yStep * i + -2.5 * math.sin(radians)}
      else
        steps[i] = { x = 0, y = yStep * i}
      end
    end

    if targetPos.x > unit.pos.x then
        unit.pos.facing = 1
    elseif targetPos.x < unit.pos.x then
        unit.pos.facing = 3
    end
    Wargroove.updateUnit(unit)

    Wargroove.spawnMapAnimation(unit.pos, 0, "fx/mapeditor_unitdrop")
    Wargroove.playMapSound("frogJump", unit.pos)
    local startingPosition = unit.pos
    Wargroove.setShadowVisible(unit.id, false)
    for i = 1, numSteps do
      Wargroove.moveUnitToOverride(unit.id, startingPosition, steps[i].x, steps[i].y, 20)
      while (Wargroove.isLuaMoving(unit.id)) do
        coroutine.yield()
      end
    end
    Wargroove.unsetShadowVisible(unit.id)
    

end

function Jump:onPostUpdateUnit(unit, targetPos, strParam, path)
    Verb.onPostUpdateUnit(self, unit, targetPos, strParam, path)

    local facing
    if targetPos.x > unit.pos.x then
        facing = 1
    elseif targetPos.x < unit.pos.x then
        facing = 3
    end

    unit.pos = Jump:getPointBeyond(unit.pos, targetPos)
    unit.pos.facing = facing
end

return Jump