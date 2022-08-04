local Wargroove = require "wargroove/wargroove"
local OldUnload = require "verbs/unload"
local Verb = require "wargroove/verb"

local Unload = {}

function Unload.init()
	OldUnload.canExecuteWithTarget = Unload.canExecuteWithTarget
	
end


function Unload:canExecuteWithTarget(unit, endPos, targetPos, strParam)
    if #unit.loadedUnits == 0 then
        return false
    end
	if endPos.x == targetPos.x and endPos.y == targetPos.y then
		return false
	end
    -- If it's a water transport, is it on a beach?
    local tags = unit.unitClass.tags
    for i, tag in ipairs(tags) do
        if tag == "type.sea" then
            if Wargroove.getTerrainNameAt(endPos) ~= "beach" and Wargroove.getTerrainNameAt(endPos) ~= "river" then
                return false
            end
        end
    end

    if strParam == '' then
        -- This means that the code is seeing if it should add unload to the action ui list
        -- Actual checking is done in code.
        return true
    end

    local unitId = tonumber(strParam)

    if unitId then
        for i, location in ipairs(OldUnload.selectedLocations) do
            if location.x == targetPos.x and location.y == targetPos.y then
                return false
            end
        end

        local loadedUnit = Wargroove.getUnitById(unitId)

        if Wargroove.canStandAt(loadedUnit.unitClassId, targetPos) and Wargroove.getUnitAt(targetPos)== nil then
            return true
        end

        return false
    end

    local targets = OldUnload:parseStrParam(strParam)
    for unitId, target in pairs(targets) do
        local loadedUnit = Wargroove.getUnitById(unitId)
        if not Wargroove.canStandAt(loadedUnit.unitClassId, target) or not Wargroove.getUnitAt(targetPos)== nil then
            return false
        end
    end    
    return true
end


return Unload
