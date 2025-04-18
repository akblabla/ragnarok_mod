local Wargroove = require "wargroove/wargroove"
local Verb = require "wargroove/verb"

local DeathElderStrength = Verb:new()

function DeathElderStrength:execute(unit, targetPos, strParam, path)
    Wargroove.clearCounterModifiers()

    Wargroove.waitTime(0.5)
end

return DeathElderStrength
