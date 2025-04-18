local Wargroove = require "wargroove/wargroove"
local ItemVerb = require "wargroove/item_verb"

local EnergyDrink = ItemVerb:new()

local extraRange = 2

function EnergyDrink:getMaximumRange(unit, endPos)
    return 3
end

function EnergyDrink:getTargetType()
    return "unit"
end

function EnergyDrink:canExecuteWithTarget(unit, endPos, targetPos, strParam)
    local target = Wargroove.getUnitAt(targetPos)

    if not target then
        return false
    end

    if target.isStructure then
        return false
    end

    if target.unitClass.moveRange <= 0 then
        return false
    end

    if target.hadTurn then
        return false
    end

    if target == unit then
        return false
    end

    if Wargroove.areAllies(target.playerId, unit.playerId) then
        return true
    end

    return false
end

function EnergyDrink:execute(unit, targetPos, strParam, path)
    Wargroove.updateUnit(unit)

    local target = Wargroove.getUnitAt(targetPos)

    Wargroove.playMapSound("reinforceStructureDrain", target.pos)
    Wargroove.spawnMapAnimation(target.pos, 0, "fx/reinforce_1", "default", "over_units", { x = 12, y = 0 })
    
    Wargroove.setUnitModifier(target.id, "MoveRange", extraRange, 1)
    Wargroove.updateUnit(target)
end

return EnergyDrink