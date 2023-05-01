local Actions = require "scripts/actions"
local Conditions = require "scripts/conditions"
local Events = require "scripts/events"

local Source = {}



-- This is called by the game when the map is loaded.
function Source.init()
    Events.init()
    Actions.init()
    Conditions.init()
end
return Source
