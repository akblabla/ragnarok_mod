local Wargroove = require "wargroove/wargroove"
local Verb = require "wargroove/verb"

local Deposit = Verb:new()

local stateKey = "gold"

function Deposit:getMaximumRange(unit, endPos)
    return 1
end

function Deposit:getTargetType()
    return "unit"
end

function Deposit:canExecuteAnywhere(unit)
    local gold = Wargroove.getUnitState(unit, stateKey)
    return gold ~= nil and tonumber(gold) > 0
end

function Deposit:canExecuteWithTarget(unit, endPos, targetPos, strParam)    
    local targetUnit = Wargroove.getUnitAt(targetPos)
    return targetUnit and (targetUnit.unitClassId == "hideout") and Wargroove.areAllies(unit.playerId, targetUnit.playerId)
end

function Deposit:execute(unit, targetPos, strParam, path)
    local targetUnit = Wargroove.getUnitAt(targetPos)
    local amountToDeposit = Wargroove.getUnitState(unit, stateKey)
    Wargroove.setUnitState(unit, stateKey, 0)
    unit.unitClassId = "thief"
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
end

function Deposit:generateOrders(unitId, canMove)
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
            if u ~= nil and self:canExecuteWithTarget(unit, pos, targetPos, "") then
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

function Deposit:getScore(unitId, order)
    local unit = Wargroove.getUnitById(unitId)
    local amountToDeposit = Wargroove.getUnitState(unit, stateKey)
    local score = math.sqrt(amountToDeposit / 100)
    return { score = score, healthDelta = 0, introspection = {
        { key = "amountToDeposit", value = amountToDeposit }}}
end

return Deposit
