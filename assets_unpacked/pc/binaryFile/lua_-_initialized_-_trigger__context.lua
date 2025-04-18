local Wargroove = require "wargroove/wargroove"
local OldContext = require "triggers/trigger_context"
local Ragnarok = require "initialized/ragnarok"


local Context = {}

-- This is called by the game when the map is loaded.
function Context.init()
  OldContext.doGatherUnits = Context.doGatherUnits
end

function Context:doGatherUnits(playerId, unitClass, location)
    local result = {}

    for i, unit in ipairs(Wargroove.getUnitsAtLocation(location)) do
        if OldContext:doesPlayerMatch(unit.playerId, playerId) and OldContext:doesUnitMatch(unit.unitClass, unitClass) and not unit.inTransport then
            table.insert(result, unit)
        end
        for i, transportedUnitId in ipairs(unit.loadedUnits) do
            local transportedUnit = Wargroove.getUnitById(transportedUnitId)
            if OldContext:doesPlayerMatch(transportedUnit.playerId, playerId) and OldContext:doesUnitMatch(transportedUnit.unitClass, unitClass) then
                table.insert(result, transportedUnit)
            end
        end
    end

    return result
end

return Context