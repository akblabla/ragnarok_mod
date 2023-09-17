local Wargroove = require "wargroove/wargroove"
local Events = require "wargroove/events"
local Ragnarok = require "initialized/ragnarok"
local VisionTracker = require "initialized/vision_tracker"
local Rescue = require "verbs/rescue"

local Conditions = {}

-- This is called by the game when the map is loaded.
function Conditions.init()
  Events.addToConditionsList(Conditions)
end

function Conditions.populate(dst)
    dst["state"] = Conditions.state
    dst["crown_present"] = Conditions.crownPresent
    dst["did_it_occur"] = Conditions.didItOccur
    dst["is_rescued"] = Conditions.isRescued
    dst["or_group"] = Conditions.orGroup
    dst["end_group"] = Conditions.endGroup
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

function Conditions.crownPresent(context)
  -- "If crown is at location {0}."

  -- The context contains an ordered table of values and has accessor methods for various types.
  local location = context:getLocation(0)
  local crownPos = Ragnarok.getCrownPos()
  if crownPos == nil then
    return false
  end
  for i, pos in ipairs(location.positions) do
    print("crownPos")
    print(dump(crownPos,0))
    print("pos")
    print(dump(pos,0))
    if (pos.x == crownPos.x) and (pos.y == crownPos.y) then
      return true
    end
  end
  return false
end

function Conditions.didItOccur(context)
    -- "If {0} occured"
    local occation = context:getString(0)
	return Ragnarok.didItOccur(occation)
end

function Conditions.isRescued(context)
    -- "If capsized crew at location {0} is rescued by player {1}."
    local location = context:getLocation(0)
    local playerId = context:getPlayerId(1)
    for i, pos in pairs(location.positions) do
      local unit = Wargroove.getUnitAt(pos)
      if unit and unit.unitClassId == "crew" then
        if Rescue.isRescuedByPlayer(unit.id,playerId) then
          return true
        end
      end
    end
	return false
end

function Conditions.orGroup(context)
  return true
end

function Conditions.endGroup(context)
  return true
end

return Conditions
