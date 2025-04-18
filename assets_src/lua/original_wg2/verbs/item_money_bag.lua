local Wargroove = require "wargroove/wargroove"
local ItemVerb = require "wargroove/item_verb"

local MoneyBag = ItemVerb:new()

local moneyAmount = 300

function MoneyBag:getMaximumRange(unit, endPos)
    return 0
end

function MoneyBag:getTargetType()
    return "unit"
end

function MoneyBag:execute(unit, targetPos, strParam, path)
    Wargroove.spawnMapAnimation(unit.pos, 0, "fx/ransack_1", "default", "over_units", { x = 12, y = 0 })
    Wargroove.playMapSound("thiefGoldReleased", unit.pos)

    Wargroove.changeMoney(unit.playerId, moneyAmount)

    Wargroove.waitTime(0.8)
end

return MoneyBag