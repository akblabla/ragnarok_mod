local Wargroove = require "wargroove/wargroove"
local OldDeathGiveGold = require "verbs/death_give_gold"
local DefaultDeath = require "verbs/default_death"


local DeathGiveGold = {}

local stateKey = "gold"

function DeathGiveGold.init()
    OldDeathGiveGold.execute = DeathGiveGold.execute
end

function DeathGiveGold:execute(unit, targetPos, strParam, path)
    DefaultDeath:execute(unit, targetPos, strParam, path)
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
