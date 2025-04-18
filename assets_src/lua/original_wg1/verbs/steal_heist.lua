local Wargroove = require "wargroove/wargroove"
local Steal = require "verbs/steal"

local StealHeist = Steal:new()

function StealHeist:canExecuteWithTargetId(id)
    return id == "hq"
end

function StealHeist:getAmountToSteal()
    return 1000
end

return StealHeist
