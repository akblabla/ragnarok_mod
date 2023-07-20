local Actions = require "scripts/actions"
local Conditions = require "scripts/conditions"
local Events = require "scripts/events"
local AIEconomyManager = require "scripts/ai_economy_manager"
local StealthManager = require "scripts/stealth_manager"

local Source = {}



-- This is called by the game when the map is loaded.
function Source.init()
    Events.init()
    Actions.init()
    Conditions.init()
    AIEconomyManager.init()
    StealthManager.init()
end
return Source
