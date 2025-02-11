local Actions = require "scripts/actions"
local Conditions = require "scripts/conditions"
local Events = require "scripts/events"
local AIEconomyManager = require "scripts/ai_economy_manager"
local AIProfile = require "AIProfiles/ai_profile"
local StealthManager = require "scripts/stealth_manager"

local Source = {}



-- This is called by the game when the map is loaded.
function Source.init()
    Events.init()
    Actions.init()
    Conditions.init()
    AIEconomyManager.init()
    AIProfile.init()
    StealthManager.init()
end
return Source
