local Wargroove = require "wargroove/wargroove"
local Verb = require "wargroove/verb"
local Ragnarok = require "initialized/ragnarok"

local Rescue = Verb:new()
local rescuedCrewList = {}

function Rescue.isRescuedByPlayer(gizmo,playerId)
	print("isRescuedByPlayer starts here")
	print(dump(rescuedCrewList,0))
	print(Ragnarok.generateGizmoKey(gizmo))
	if playerId == nil then
		return not (rescuedCrewList[Ragnarok.generateGizmoKey(gizmo)] == nil)
	end
	return rescuedCrewList[Ragnarok.generateGizmoKey(gizmo)] == playerId
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
    local gizmo = Wargroove.getGizmoAt(targetPos)
	
    return gizmo and gizmo.type == "capsized_crew" and Ragnarok.getGizmoState(gizmo) == false
end

function Rescue:execute(unit, targetPos, strParam, path)
	print("Rescue:execute starts here")
	Ragnarok.reportOccation("rescued")
	local gizmo = Wargroove.getGizmoAt(targetPos)
	rescuedCrewList[Ragnarok.generateGizmoKey(gizmo)] = unit.playerId
	print(dump(rescuedCrewList,0))
	print(Ragnarok.generateGizmoKey(gizmo))
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
