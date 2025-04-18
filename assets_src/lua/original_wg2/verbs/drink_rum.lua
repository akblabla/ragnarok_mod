local Wargroove = require "wargroove/wargroove"
local Verb = require "wargroove/verb"

local DrinkRum = Verb:new()

function DrinkRum:getMaximumRange(unit, endPos)
    return 0
end

function DrinkRum:getTargetType()
    return "unit"
end

function DrinkRum:execute(unit, targetPos, strParam, path)
    Wargroove.pushUnitClassModifier(unit.id, "inspire_high")
    Wargroove.pushBuff(2, unit, unit.playerId, "drink_rum_spawn", "drink_rum", "drink_rum_death")

    unit:setHealth(unit.health-10, unit.id)
    Wargroove.playUnitAnimation(unit.id, "hit")

    Wargroove.waitTime(0.2)
end

return DrinkRum