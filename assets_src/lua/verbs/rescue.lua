local Wargroove = require "wargroove/wargroove"
local Verb = require "wargroove/verb"
local Ragnarok = require "initialized/ragnarok"

local rescue = Verb:new()

function rescue:getMaximumRange(unit, endPos)
	return 1
end

function rescue:getTargetType()
    return "unit"
end

function rescue:canExecuteAnywhere(unit)
    return true
end

function rescue:canExecuteWithTarget(unit, endPos, targetPos, strParam)    
    local gizmo = Wargroove.getGizmoAt(targetPos)
	
    return gizmo and gizmo.type == "capsized_crew"
end

function rescue:execute(unit, targetPos, strParam, path)
	Ragnarok.reportOccation("rescued")
end

return rescue
