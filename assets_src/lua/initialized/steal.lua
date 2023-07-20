local Wargroove = require "wargroove/wargroove"
local OldStealNormal = require "verbs/steal_normal"
local OldStealHeist = require "verbs/steal_heist"
local Verb = require "wargroove/verb"

local Steal = {}

local stateKey = "gold"

function Steal.init()
	OldStealNormal.execute = Steal.execute
	OldStealHeist.execute = Steal.execute
	
end


function Steal:execute(unit, targetPos, strParam, path)
    local targetUnit = Wargroove.getUnitAt(targetPos)
    local amountToTake = self:getAmountToSteal()

    Wargroove.playMapSound("thiefSteal", targetPos)
    Wargroove.waitTime(0.2)
    Wargroove.spawnMapAnimation(targetPos, 0, "fx/ransack_1", "default", "over_units", { x = 12, y = 0 })
    Wargroove.waitTime(0.8)
    Wargroove.spawnMapAnimation(unit.pos, 0, "fx/ransack_2", "default", "over_units", { x = 12, y = 0 })
    Wargroove.waitTime(0.3)
    Wargroove.playMapSound("thiefGoldObtained", targetPos)
    Wargroove.waitTime(0.3)

    Wargroove.setUnitState(unit, stateKey, amountToTake)
    unit.unitClassId = "thief_with_gold"
    Wargroove.changeMoney(targetUnit.playerId, -amountToTake)

    if (targetUnit.unitClassId ~= "hq") then
        if (targetUnit.unitClassId ~= "gate") or (targetUnit.unitClassId ~= "gate_no_los_blocker") then
            targetUnit.playerId = -2
        else
            targetUnit.playerId = -1
        end
        Wargroove.updateUnit(targetUnit)
    end

    Wargroove.waitTime(0.5)
end

return Steal
