local Wargroove = require "wargroove/wargroove"
local Verb = require "wargroove/verb"

local Transfer = Verb:new()
local healAmount = 25
local costScoreFactor = 0.5


function Transfer:getMaximumRange(unit, endPos)
    return 1
end

function Transfer:canExecuteWithTarget(unit, endPos, targetPos, strParam)
    local targetUnit = Wargroove.getUnitAt(targetPos)

    if not self:canSeeTarget(targetPos) then
        return false
    end

    if targetUnit == nil or targetUnit.unitClass.isStructure then
        return false
    end

    if Wargroove.areEnemies(targetUnit.playerId, unit.playerId) then
        return false
    end

    return true
end

function Transfer:getTargetType()
    return "unit"
end

function Transfer:execute(unit, targetPos, strParam, path)
    local targetUnit = Wargroove.getUnitAt(targetPos)

    local maxTransferAmount = math.min(unit.health-1, healAmount);

    Wargroove.spawnMapAnimation(unit.pos, 0, "fx/reinforce_1", "default", "over_units", { x = 12, y = 0 })
    Wargroove.playMapSound("reinforceStructureDrain", unit.pos)
    unit:setHealth(unit.health - maxTransferAmount, unit.id)
    Wargroove.updateUnit(unit)
    Wargroove.waitTime(0.4)

    targetUnit:setHealth(targetUnit.health + maxTransferAmount, unit.id)
    Wargroove.updateUnit(targetUnit)
    Wargroove.spawnMapAnimation(targetUnit.pos, 0, "fx/reinforce_2", "default", "over_units", { x = 12, y = 0 })
    Wargroove.playMapSound("reinforceUnitHeal", targetUnit.pos)
    Wargroove.waitTime(0.4)
end

return Transfer
