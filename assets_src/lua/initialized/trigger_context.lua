local Wargroove = require "wargroove/wargroove"
local OldTriggerContext = require "triggers/trigger_context"


local TriggerContext = {}
function TriggerContext.init()
	OldTriggerContext.doesPlayerMatch = TriggerContext.doesPlayerMatch
	
end
function TriggerContext:doesPlayerMatch(playerId, target)
    return (playerId == target) or (target == nil) or (playerId < 0 and target < 0)
end

return TriggerContext
