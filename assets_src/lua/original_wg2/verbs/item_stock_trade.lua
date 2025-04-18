local Wargroove = require "wargroove/wargroove"
local ItemVerb = require "wargroove/item_verb"

local StockTrade = ItemVerb:new()

local cost = 300

function StockTrade:getMaximumRange(unit, endPos)
    return 0
end

function StockTrade:getTargetType()
    return "all"
end

function StockTrade:canExecuteAnywhere(unit)
    return Wargroove.getMoney(unit.playerId) >= cost
end

function StockTrade:getCostAt(unit, endPos, targetPos)
    return cost
end

function StockTrade:execute(unit, targetPos, strParam, path)
    Wargroove.changeMoney(unit.playerId, -cost)

    local startingState = {}
    local money = {key = "money", value = tostring(cost * 2)}
    local unitId = {key = "unitId", value = tostring(unit.id)}
    table.insert(startingState, money)
    table.insert(startingState, unitId)
    Wargroove.spawnUnit(unit.playerId, {x = -100, y = -100}, "stock_trade", false, "", startingState)

    Wargroove.playMapSound("thiefGoldObtained", unit.pos)
    Wargroove.spawnMapAnimation(unit.pos, 0, "fx/ransack_2", "default", "over_units", { x = 12, y = 0 })
    Wargroove.waitTime(0.2)
end

return StockTrade