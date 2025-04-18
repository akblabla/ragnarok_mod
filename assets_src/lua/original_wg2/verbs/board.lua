local Wargroove = require "wargroove/wargroove"
local Verb = require "wargroove/verb"
local Combat = require "wargroove/combat"

local Board = Verb:new()

local boardAmount = 50

function Board:getMaximumRange(unit, endPos)
    return 1
end

function Board:getTargetType()
    return "unit"
end

function Board:canExecuteWithTarget(unit, endPos, targetPos, strParam)
    local targetUnit = Wargroove.getUnitAt(targetPos)

    if targetUnit then
        local uc = Wargroove.getUnitClass(targetUnit.unitClassId)
        return not uc.isCommander and targetUnit.health <= 30 and Wargroove.areEnemies(unit.playerId, targetUnit.playerId) and (uc.isStructure or uc.inWater)
    end

    return false
end

function Board:execute(unit, targetPos, strParam, path)
    local targetUnit = Wargroove.getUnitAt(targetPos)

    local maxTransferAmount = math.min(unit.health-1, boardAmount);

    Wargroove.spawnMapAnimation(unit.pos, 0, "fx/reinforce_1", "default", "over_units", { x = 12, y = 0 })
    Wargroove.playMapSound("reinforceStructureDrain", unit.pos)
    unit:setHealth(unit.health - maxTransferAmount, unit.id)
    Wargroove.updateUnit(unit)
    Wargroove.waitTime(0.4)

    targetUnit:setHealth(targetUnit.health + maxTransferAmount, unit.id)
    Wargroove.spawnMapAnimation(targetUnit.pos, 0, "fx/reinforce_2", "default", "over_units", { x = 12, y = 0 })
    Wargroove.playMapSound("reinforceUnitHeal", targetUnit.pos)
    targetUnit.playerId = unit.playerId
    targetUnit.hadTurn = true
    Wargroove.updateUnit(targetUnit)

    Wargroove.waitTime(0.4)

    Wargroove.spawnMapAnimation(targetUnit.pos, 0, "fx/reinforce_1", "default", "over_units", { x = 12, y = 0 })
    Wargroove.playMapSound("reinforceStructureDrain", targetUnit.pos)
end

return Board
