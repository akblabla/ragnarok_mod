local Wargroove = require "wargroove/wargroove"
local Steal = require "verbs/steal"

local StealNormal = Steal:new()

function StealNormal:canExecuteWithTargetId(id)
    return id ~= "hq"
end

function StealNormal:getAmountToSteal()
    return 300
end

return StealNormal
