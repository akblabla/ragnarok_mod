local Wargroove = require "wargroove/wargroove"
local Verb = require "wargroove/verb"

local BetterMerge = Verb:new()


function BetterMerge:getTargetType()
    return "unit"
end


function BetterMerge:getMaximumRange(unit, endPos)
    return 1
end


function BetterMerge:canExecuteWithTarget(unit, endPos, targetPos, strParam)

    if not self:canSeeTarget(targetPos) then
        return false
    end

    local targetUnit = Wargroove.getUnitAt(targetPos)
	if not targetUnit or not Wargroove.areAllies(targetUnit.playerId, unit.playerId) then
       return false
    end
    return targetUnit ~= nil and targetUnit.health ~= 100 and targetUnit.unitClass.id == unit.unitClass.id and targetUnit.id ~= unit.id
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


function BetterMerge:execute(unit, targetPos, strParam, path)
	print("this is a cool test")
    local target = Wargroove.getUnitAt(targetPos)
    local facingOverride = ""
    if targetPos.x > unit.pos.x then
        facingOverride = "right"
    elseif targetPos.x < unit.pos.x then
        facingOverride = "left"
    end

    Wargroove.setFacingOverride(unit.id, facingOverride)

    local amountToMove = 1
    local xMove = (targetPos.x > unit.pos.x and amountToMove) or (targetPos.x < unit.pos.x and -amountToMove) or 0
    local yMove = (targetPos.y > unit.pos.y and amountToMove) or (targetPos.y < unit.pos.y and -amountToMove) or 0

    
    Wargroove.moveUnitToOverride(unit.id, unit.pos, xMove, yMove, 15)
    Wargroove.waitTime(0.4)

    Wargroove.spawnMapAnimation(targetPos, 0, "fx/reinforce_1")
	
	
	target:setHealth(math.min(unit.health+target.health,100),unit.id)
	target.damageTakenPercent = #path*10
	
	unit.pos  = {x = -100, y = -100}
	unit:setHealth(0,unit.id)
	--print(obj)
	Wargroove.waitTime(0.01)
	Wargroove.updateUnit(target)
	Wargroove.updateUnit(unit)
	unit.unitClass.moveRange = 1
	
	Wargroove.spawnMapAnimation(unit.pos, 0, "fx/mapeditor_unitdrop")
end

function BetterMerge:onPostUpdateUnit(unit, targetPos, strParam, path)
    local target = Wargroove.getUnitAt(targetPos)
	unit.pos = {x = -100, y = -100}
	Wargroove.updateUnit(target)
	target.hadTurn = true
end

return BetterMerge
