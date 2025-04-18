local Verb = require "wargroove/verb"
local Cancel = Verb:new()

function Cancel.canExecute(unit, endPos, targetPos, strParam)
    return true
end

return Cancel
