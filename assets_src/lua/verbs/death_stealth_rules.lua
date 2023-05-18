local Wargroove = require "wargroove/wargroove"
local Verb = require "wargroove/verb"

local StealthRules = Verb:new()

function StealthRules:execute(unit, targetPos, strParam, path)
    if (unit.killedByLosing) then
        return
    end


    Wargroove.spawnUnit(unit.playerId, {x = -50, y = -50}, "stealth_rules", false, "")
end

return StealthRules