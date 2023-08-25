local Wargroove = require "wargroove/wargroove"
local OldCapture = require "verbs/capture"
local Verb = require "initialized/a_new_verb"


local Capture = {}
function Capture.init()
	OldCapture.canExecuteAt = Capture.canExecuteAt
	
end

function Capture:canExecuteAt(unit)
    local state = Wargroove.getUnitState(unit, "canCapture")
    if (state ~= nil) and (state == "false") then
        return false
    end
    return true
end

return Capture
