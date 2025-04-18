local Wargroove = require "wargroove/wargroove"
local Verb = require "wargroove/verb"

local StockTrade = Verb:new()

function StockTrade:execute(unit, targetPos, strParam, path)
    if (unit.killedByLosing) then
        return
    end

    local money = tonumber(Wargroove.getUnitState(unit, "money"))
    local targetId = tonumber(Wargroove.getUnitState(unit, "unitId"))
    local target = Wargroove.getUnitById(targetId)
    
    if target and not target.hasBeenKilled then
        Wargroove.changeMoney(unit.playerId, money)
        Wargroove.playMapSound("thiefGoldReleased", target.pos)
        Wargroove.spawnMapAnimation(target.pos, 0, "fx/ransack_1", "default", "over_units", { x = 12, y = 0 })
        Wargroove.clearBuffVisualEffect(targetId)
    else
        Wargroove.playPositionlessSound("thiefGoldReleased")
    end

    Wargroove.waitTime(0.2)
end

return StockTrade
