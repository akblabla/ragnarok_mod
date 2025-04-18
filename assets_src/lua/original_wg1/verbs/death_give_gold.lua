local Wargroove = require "wargroove/wargroove"
local Verb = require "wargroove/verb"

local DeathGiveGold = Verb:new()

local stateKey = "gold"

function DeathGiveGold:execute(unit, targetPos, strParam, path)
    local killedById = tonumber(strParam)

    if killedById == unit.id then
        return
    end

    local killedByUnit = Wargroove.getUnitById(killedById)

    if (killedByUnit == nil) then
        return
    end

    local amountCarried = Wargroove.getUnitState(unit, stateKey)
    
    if (amountCarried == nil) then
        return
    end
    
    Wargroove.changeMoney(killedByUnit.playerId, amountCarried)
end


return DeathGiveGold
