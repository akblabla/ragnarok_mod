local Wargroove = require "wargroove/wargroove"
local Verb = require "wargroove/verb"
local Ragnarok = require "initialized/ragnarok"

local throwCrown = Verb:new()

local stateKey = "crown"

function throwCrown:getMaximumRange(unit, endPos)
    return 2
end

function throwCrown:getTargetType()
    return "all"
end

function throwCrown:canExecuteAnywhere(unit)
    local crown = Wargroove.getUnitState(unit, stateKey)
    return crown ~= nil
end

function throwCrown:canExecuteWithTarget(unit, endPos, targetPos, strParam)    
    local targetUnit = Wargroove.getUnitAt(targetPos)
	if targetUnit then
		return Wargroove.areAllies(unit.playerId, targetUnit.playerId)
	end
    return not Wargroove.isTerrainImpassableAt(targetPos)
end

function throwCrown:execute(unit, targetPos, strParam, path)
    local crownID = Ragnarok.dropCrown(unit.pos)
	local facingOverride = "left"
    if targetPos.x > unit.pos.x then
        facingOverride = "right"
    elseif targetPos.x < unit.pos.x then
        facingOverride = "left"
    end

    Wargroove.setFacingOverride(unit.id, facingOverride)
	
	local numSteps = 8

    local steps = {}
    local xDiff = targetPos.x - unit.pos.x
    local yDiff = targetPos.y - unit.pos.y
    local xStep = xDiff / numSteps
    local yStep = yDiff / numSteps
	local startHeight = 0.5
    Wargroove.playMapSound("cutscene/throwObject", targetPos)
    for i = 1,numSteps do
      if (xDiff ~= 0) then
        local radians = i / numSteps * 3.14
        steps[i] = {x = xStep * i, y = yStep * i + -0.5*math.sin(radians)-(numSteps-i)*startHeight/numSteps}
      else
        steps[i] = { x = 0, y = yStep * i}
      end
    end

    local startingPosition = {x = unit.pos.x-100, y = unit.pos.y-100}
	--print("Start Arch")
	Ragnarok.printCrownInfo()
    for i = 1, numSteps do
      Wargroove.moveUnitToOverride(crownID, startingPosition, steps[i].x, steps[i].y, 20)
      while (Wargroove.isLuaMoving(crownID)) do
        coroutine.yield()
      end
    end
	--print("End Arch")
	--print("")
	local targetUnit = Wargroove.getUnitAt(targetPos)
	if targetUnit then
		Wargroove.playMapSound("cutscene/land", targetPos)
		--print("Handing Crown to Another")
		Ragnarok.grabCrown(targetUnit)
	else
		Wargroove.playMapSound("cutscene/swordDrop", targetPos)
		--print("Throwing crown on the ground")
		Ragnarok.dropCrown(targetPos)
	end
	Ragnarok.printCrownInfo()
    Wargroove.waitTime(0.25)
end

function throwCrown:onPostUpdateUnit(unit, targetPos, strParam, path)
    Verb.onPostUpdateUnit(self, unit, targetPos, strParam, path)
    Wargroove.unsetFacingOverride(unit.id)
end

function throwCrown:generateOrders(unitId, canMove)
    local unit = Wargroove.getUnitById(unitId)
    return {}
end

function throwCrown:getScore(unitId, order)
    local unit = Wargroove.getUnitById(unitId)
    return {score = -1, introspection = {}}
end

function dump(o,level)
   if type(o) == 'table' then
      local s = '\n' .. string.rep("   ", level) .. '{\n'
      for k,v in pairs(o) do
         if type(k) ~= 'number' then k = '"'..k..'"' end
         s = s .. string.rep("   ", level+1) .. '['..k..'] = ' .. dump(v,level+1) .. ',\n'
      end
      return s .. string.rep("   ", level) .. '}'
   else
      return tostring(o)
   end
end
return throwCrown
