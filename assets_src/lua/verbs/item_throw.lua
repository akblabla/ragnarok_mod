local Wargroove = require "wargroove/wargroove"
local ItemVerb = require "wargroove/item_verb"
local Ragnarok = require "initialized/ragnarok"

local itemThrow = ItemVerb:new()

function itemThrow:getMaximumRange(unit, endPos)
    return 2
end

function itemThrow:getTargetType()
    return "all"
end

function itemThrow:canExecuteAnywhere(unit)
    return true
end

function itemThrow:canExecuteWithTarget(unit, endPos, targetPos, strParam)    
    local targetUnit = Wargroove.getUnitAt(targetPos)
	if targetUnit then
        if not Ragnarok.canHoldCrown(targetUnit) then
            return false
        end
		if not Wargroove.areAllies(unit.playerId, targetUnit.playerId) then
            return false
        end
	end
    if Wargroove.isTerrainImpassableAt(targetPos) then
        return false
    end
    return true
end

function itemThrow:execute(unit, targetPos, strParam, path)
    Ragnarok.removeCrown()
	local crownID = Wargroove.spawnUnit(-1, {x = unit.pos.x+100, y = unit.pos.y+100}, "crown", false)
	Wargroove.setVisibleOverride(crownID, true)
	local facingOverride = "left"
    if targetPos.x > unit.pos.x then
        facingOverride = "right"
    elseif targetPos.x < unit.pos.x then
        facingOverride = "left"
    end

    Wargroove.setFacingOverride(unit.id, facingOverride)
	local targetUnit = Wargroove.getUnitAt(targetPos)
	
	local numSteps = 8

    local steps = {}
    local xDiff = targetPos.x - unit.pos.x
    local yDiff = targetPos.y - unit.pos.y
    local xStep = xDiff / numSteps
    local yStep = yDiff / numSteps
	local heightStart = 0.8
	local heightEnd = 0
	if targetUnit then
	    heightEnd = 0.8
    end
    Wargroove.playMapSound("cutscene/throwObject", targetPos)
    for i = 1,numSteps do
      if (xDiff ~= 0) then
        local radians = i / numSteps * 3.14
        local height = i*heightEnd/numSteps+(numSteps-i)*heightStart/numSteps
        steps[i] = {x = xStep * i, y = yStep * i + -0.25*math.sin(radians)-height}
      else
        steps[i] = { x = 0, y = yStep * i}
      end
    end

    local startingPosition = {x = unit.pos.x+100, y = unit.pos.y+100}
	Ragnarok.printCrownInfo()
    for i = 1, numSteps do
      Wargroove.moveUnitToOverride(crownID, startingPosition, steps[i].x, steps[i].y, 20)
      while (Wargroove.isLuaMoving(crownID)) do
        coroutine.yield()
      end
    end
    Wargroove.removeUnit(crownID)
	if targetUnit then
		Wargroove.playMapSound("cutscene/land", targetPos)
		Ragnarok.grabCrown(targetUnit)
	else
		Wargroove.playMapSound("cutscene/swordDrop", targetPos)
		--print("Throwing crown on the ground")
		Ragnarok.dropCrown(targetPos)
	end
	Ragnarok.printCrownInfo()
end

function itemThrow:onPostUpdateUnit(unit, targetPos, strParam, path)
    Wargroove.unsetFacingOverride(unit.id)
    unit.hadTurn = true;
    Wargroove.updateUnit(unit)
end

function itemThrow:generateOrders(unitId, canMove)
    local unit = Wargroove.getUnitById(unitId)
    return {}
end

function itemThrow:getScore(unitId, order)
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
return itemThrow
