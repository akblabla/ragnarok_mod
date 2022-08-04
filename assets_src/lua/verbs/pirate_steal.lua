local Wargroove = require "wargroove/wargroove"
local Verb = require "wargroove/verb"
local Ragnarok = require "initialized/ragnarok"

local pirate_steal = Verb:new()

local stateKey = "gold"

function pirate_steal:getMaximumRange(unit, endPos)
    return 1
end

function pirate_steal:getTargetType()
    return "unit"
end

function pirate_steal:canExecuteAnywhere(unit)
    local gold = Wargroove.getUnitState(unit, stateKey)
    return gold == nil or tonumber(gold) == 0
end

function pirate_steal:canExecuteWithTarget(unit, endPos, targetPos, strParam)
    local targetUnit = Wargroove.getUnitAt(targetPos)

    if (tonumber(Wargroove.getNetworkVersion()) ~= nil and tonumber(Wargroove.getNetworkVersion()) <= 210000) then
        return targetUnit and targetUnit.unitClass.isStructure and Wargroove.areEnemies(unit.playerId, targetUnit.playerId) and targetUnit.playerId >= 0 and self:canExecuteWithTargetId(targetUnit.unitClassId)
    else
        return targetUnit and targetUnit.unitClass.isStructure and Wargroove.areEnemies(unit.playerId, targetUnit.playerId) and targetUnit.playerId >= 0 and self:canExecuteWithTargetId(targetUnit.unitClassId) and self:canSeeTarget(targetPos)
    end
    
end

function pirate_steal:canExecuteWithTargetId(targetId)
    return true
end

function pirate_steal:getAmountToSteal()
    return 300
end

function pirate_steal:execute(unit, targetPos, strParam, path)
    local targetUnit = Wargroove.getUnitAt(targetPos)
    local amountToTake = self:getAmountToSteal()
	local facing = unit.facing

    Wargroove.playMapSound("thiefSteal", targetPos)
    Wargroove.waitTime(0.2)
    Wargroove.spawnMapAnimation(targetPos, 0, "fx/ransack_1", "default", "over_units", { x = 12, y = 0 })
    Wargroove.waitTime(0.8)
    Wargroove.spawnMapAnimation(unit.pos, 0, "fx/ransack_2", "default", "over_units", { x = 12, y = 0 })
    Wargroove.waitTime(0.3)
    Wargroove.playMapSound("thiefGoldObtained", targetPos)
    Wargroove.waitTime(0.3)

    Wargroove.setUnitState(unit, stateKey, amountToTake)
    unit.unitClassId = "pirate_ship_loaded"
    Wargroove.changeMoney(targetUnit.playerId, -amountToTake)
	--unit.facing = facing
	Wargroove.updateUnit(unit)
	
    if (targetUnit.unitClassId ~= "hq") then
        targetUnit:setHealth(0, unit.id)
        Wargroove.updateUnit(targetUnit)
    end
	
    Wargroove.waitTime(0.5)
end

function pirate_steal:generateOrders(unitId, canMove)
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
            if u ~= nil and self:canExecuteWithTarget(unit, pos, targetPos, "") and not Wargroove.hasAIRestriction(u.id, "dont_target_this") then
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

function pirate_steal:getScore(unitId, order)
    local targetUnit = Wargroove.getUnitAt(order.targetPosition)
    local opposingPlayerAmount = Wargroove.getMoney(targetUnit.playerId)
    local maxAmount = self:getAmountToSteal()
    local amountToTake = math.min(maxAmount, opposingPlayerAmount)

    local unit = Wargroove.getUnitById(unitId)
    local unitClass = Wargroove.getUnitClass(unit.unitClassId)
    local oldUnitValue = math.sqrt(unitClass.cost / 100) * unit.health / 100
    local newUnitValue = 2*math.sqrt(amountToTake / 100 + unitClass.cost / 100 * unit.health*unit.health / 10000)
    local myDelta = newUnitValue - oldUnitValue

    return { score = myDelta, healthDelta = 0, introspection = {
        { key = "amountToTake", value = amountToTake },
        { key = "oldUnitValue", value = oldUnitValue },
        { key = "newUnitValue", value = newUnitValue }}}
end

return pirate_steal
