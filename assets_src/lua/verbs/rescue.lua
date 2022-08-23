local Wargroove = require "wargroove/wargroove"
local Verb = require "wargroove/verb"
local Ragnarok = require "initialized/ragnarok"

local Rescue = Verb:new()
local rescuedCrewList = {}

function Rescue.isRescuedByPlayer(unitId,playerId)
	print("isRescuedByPlayer starts here")
	if playerId == nil then
		return not (rescuedCrewList[unitId] == nil)
	end
	return rescuedCrewList[unitId] == playerId
end

function Rescue.resetRescued()
	rescuedCrewList = {}
end

function Rescue:getMaximumRange(unit, endPos)
	return 1
end

function Rescue:getTargetType()
    return "all"
end

function Rescue:canExecuteAnywhere(unit)
    return true
end

function Rescue:canExecuteWithTarget(unit, endPos, targetPos, strParam)    
    local targetUnit = Wargroove.getUnitAt(targetPos)
	
    return targetUnit and targetUnit.unitClassId == "crew"
end

function Rescue:execute(unit, targetPos, strParam, path)
	print("Rescue:execute starts here")
	Ragnarok.reportOccation("rescued")
	local targetUnit = Wargroove.getUnitAt(targetPos)
	rescuedCrewList[targetUnit.id] = unit.playerId
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

return Rescue
