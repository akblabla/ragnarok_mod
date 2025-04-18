local Wargroove = require "wargroove/wargroove"
local Verb = require "wargroove/verb"

local Load = Verb:new()


function Load:getTargetType()
    return "unit"
end


function Load:getMaximumRange(unit, endPos)
    return 1
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
   
    -- If it's a water transport, is it on a beach?
    local targetTags = targetUnit.unitClass.tags
    for i, tag in ipairs(targetTags) do
        if tag == "type.sea" then
            if Wargroove.getTerrainNameAt(targetUnit.pos) ~= "beach" then
                return false
            end
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


function Load:execute(unit, targetPos, strParam, path)
    local transport = Wargroove.getUnitAt(targetPos)
    table.insert(transport.loadedUnits, unit.id)
    unit.inTransport = true
    unit.transportedBy = transport.id
    Wargroove.updateUnit(transport)
end


function Load:onPostUpdateUnit(unit, targetPos, strParam, path)
    unit.pos = { x = -100, y = -100 }
end


return Load
