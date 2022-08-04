local Wargroove = require "wargroove/wargroove"
local Verb = require "wargroove/verb"
local Ragnarok = require "initialized/ragnarok"

local pirate_deposit = Verb:new()

local stateKey = "gold"

function pirate_deposit:getMaximumRange(unit, endPos)
    return 1
end

function pirate_deposit:getTargetType()
    return "unit"
end

function pirate_deposit:canExecuteAnywhere(unit)
    local gold = Wargroove.getUnitState(unit, stateKey)
    return gold ~= nil and tonumber(gold) > 0
end

function pirate_deposit:canExecuteWithTarget(unit, endPos, targetPos, strParam)    
    local targetUnit = Wargroove.getUnitAt(targetPos)
    return targetUnit and (targetUnit.unitClassId == "port" or targetUnit.unitClassId == "commander_flagship_wulfar" or targetUnit.unitClassId == "commander_flagship_rival") and Wargroove.areAllies(unit.playerId, targetUnit.playerId)
end

function pirate_deposit:execute(unit, targetPos, strParam, path)
    local targetUnit = Wargroove.getUnitAt(targetPos)
    local amountToDeposit = Wargroove.getUnitState(unit, stateKey)
    Wargroove.setUnitState(unit, stateKey, 0)
    unit.unitClassId = "pirate_ship"
    Wargroove.waitTime(0.2)
    Wargroove.playMapSound("thiefGoldReleased", targetPos)
    Wargroove.spawnMapAnimation(unit.pos, 0, "fx/ransack_1", "default", "over_units", { x = 12, y = 0 })
    Wargroove.updateUnit(unit)
    Wargroove.waitTime(1.0)
    Wargroove.spawnMapAnimation(targetPos, 0, "fx/ransack_2", "default", "over_units", { x = 12, y = 0 })
    Wargroove.waitTime(0.2)
    Wargroove.playMapSound("thiefDeposit", targetPos)
    Wargroove.waitTime(0.4)
    Wargroove.changeMoney(targetUnit.playerId, amountToDeposit)
	Ragnarok.addGoldRobbed(unit.playerId, tonumber(amountToDeposit))
	
end

function pirate_deposit:generateOrders(unitId, canMove)
    local orders = {}
    local unit = Wargroove.getUnitById(unitId)
    if not self:canExecuteAnywhere(unit) then
        return orders
    end

    local unitClass = Wargroove.getUnitClass(unit.unitClassId)
    local movePositions = {}
    if canMove then
        movePositions = Wargroove.getTargetsInRange(unit.pos, unitClass.moveRange, "empty")
    end
    table.insert(movePositions, unit.pos)

    for i, pos in pairs(movePositions) do
        local targets = Wargroove.getTargetsInRangeAfterMove(unit, pos, pos, self:getMaximumRange(unit, pos), "unit")
        for j, targetPos in pairs(targets) do
            local u = Wargroove.getUnitAt(targetPos)
            if u ~= nil and self:canExecuteWithTarget(unit, pos, targetPos, "") and u.playerId == unit.playerId then
                table.insert(orders, {
                    targetPosition = targetPos,
                    strParam = "",
                    movePosition = pos,
                    endPosition = pos
                })
            end
        end
    end

    return orders
end

function pirate_deposit:getScore(unitId, order)
    local unit = Wargroove.getUnitById(unitId)
    local amountToDeposit = Wargroove.getUnitState(unit, stateKey)
    local score = 100*math.sqrt(amountToDeposit / 100)
    return { score = score, healthDelta = 0, introspection = {
        { key = "amountToDeposit", value = amountToDeposit }}}
end

return pirate_deposit
