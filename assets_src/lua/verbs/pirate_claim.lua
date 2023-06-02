local Wargroove = require "wargroove/wargroove"
local Verb = require "wargroove/verb"
local Ragnarok = require "initialized/ragnarok"

local pirate_claim = Verb:new()

local stateKey = "gold"

function pirate_claim:getMaximumRange(unit, endPos)
    return 0
end

function pirate_claim:getTargetType()
    return "unit"
end

function pirate_claim:canExecuteAnywhere(unit)
    return true
end

local function getSurroundingPirates(unit, pos)
    result = {}
    for i, p in ipairs(Wargroove.getTargetsInRange(pos, 1, "unit")) do
        local pirate = Wargroove.getUnitAt(p)
        if pirate and pirate.unitClassId == "pirate_ship_loaded" and pirate.playerId == unit.playerId then
            table.insert(result, pirate)
        end
    end
    return result
end

function pirate_claim:canExecuteAt(unit, endPos)
    if not Verb:canExecuteAt(unit, endPos) then
		return false
	end
    local pirates = getSurroundingPirates(unit, endPos)
	for i, pirate in pairs(pirates) do
		return true
	end
    return false
end

function pirate_claim:execute(unit, targetPos, strParam, path)
	local pirates = getSurroundingPirates(unit, targetPos)
	local amountToReceive = 0
    Wargroove.waitTime(0.2)
	for i, pirate in pairs(pirates) do
		amountToReceive = amountToReceive + Wargroove.getUnitState(pirate, stateKey)
		Wargroove.setUnitState(pirate, stateKey, 0)
		pirate.unitClassId = "pirate_ship"
		Wargroove.spawnMapAnimation(pirate.pos, 0, "fx/ransack_1", "default", "over_units", { x = 12, y = 0 })
		Wargroove.updateUnit(pirate)
    end
    Wargroove.playMapSound("thiefGoldReleased", targetPos)
    Wargroove.waitTime(1.0)
    Wargroove.spawnMapAnimation(targetPos, 0, "fx/ransack_2", "default", "over_units", { x = 12, y = 0 })
    Wargroove.waitTime(0.2)
    Wargroove.playMapSound("thiefDeposit", targetPos)
    Wargroove.waitTime(0.4)
    Wargroove.changeMoney(unit.playerId, amountToReceive)
	Ragnarok.addGoldRobbed(unit.playerId, tonumber(amountToReceive))
	Ragnarok.reportOccation("pirate_ship_deposited")
end

return pirate_claim
