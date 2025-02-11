local OldCancel = require "verbs/cancel"
local Verb = require "initialized/a_new_verb"

local Cancel = {}
function Cancel.init()
	OldCancel.canExecuteAt = Cancel.canExecuteAt
	
end
function Cancel.canExecute(unit, endPos, targetPos, strParam)
    if Verb.inInBorderlands(endPos, unit.playerId) then
        return false
    end
    return true
end

return Cancel
