local Wargroove = require "wargroove/wargroove"
local OldLoad = require "verbs/load"
local Verb = require "wargroove/verb"

local Load = {}

function Load.init()
	OldLoad.canExecuteWithTarget = Load.canExecuteWithTarget
	
end

function Load:canExecuteWithTarget(unit, endPos, targetPos, strParam)
    -- Has a unit?
    local targetUnit = Wargroove.getUnitAt(targetPos)
    if (not targetUnit) or (targetUnit == unit) or (not Wargroove.areAllies(targetUnit.playerId, unit.playerId)) then
        return false
    end

    -- Is a transport + Has space?
    local capacity = targetUnit.unitClass.loadCapacity
    if #targetUnit.loadedUnits >= capacity then
        return false
    end
   
    

	if targetUnit.unitClassId == "travelboat" then
		if not Wargroove.canStandAt(unit.unitClassId, targetPos) and not Wargroove.canStandAt("soldier", targetPos) then
			return false
		end
	end
	
    -- Can carry me?
    local myTags = unit.unitClass.tags
    local transports = targetUnit.unitClass.transportTags
    for i, transportTag in ipairs(transports) do
        for j, myTag in ipairs(myTags) do
            if transportTag == myTag then
                return true
            end
        end
    end
    return false
end

return Load
