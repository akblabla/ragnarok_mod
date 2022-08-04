local Wargroove = require "wargroove/wargroove"
local Events = require "wargroove/events"

local Conditions = {}

-- This is called by the game when the map is loaded.
function Conditions.init()
  Events.addToConditionsList(Conditions)
end

function Conditions.populate(dst)
    dst["state"] = Conditions.state
    dst["does_next_structure_exist"] = Conditions.doesNextStructureExist
end

function Conditions.state(context)
    -- "If unit type(s) {0} at location {1} owned by player {2} have state {3} equal to {4}."

    -- The context contains an ordered table of values and has accessor methods for various types.
    local units = context:gatherUnits(2, 0, 1)  -- A useful function for gathering units of type, location, and player
    local stateKey = context:getString(3)       -- Gets a string
    local stateValue = context:getString(4)

    for i, unit in ipairs(units) do
        local state = Wargroove.getUnitState(unit, stateKey)
        if state == stateValue then
          return true
        end
    end

    return false
end

function Conditions.doesNextStructureExist(context)
    -- "If there are more {1} owned by {2} at {3} to the right of location {0}"
    location = context:getLocation(0)
    units = context:gatherUnits(2, 1, 3)
    local center = findCentreOfLocation(location)
	nextLocation = {x = 1000, y = 0}
    for i, unit in ipairs(units) do
		if unit.pos.x<nextLocation.x and unit.pos.x>center.x then
			nextLocation = unit.pos
		end
    end
	return nextLocation.x~=1000
end
return Conditions
