local Wargroove = require "wargroove/wargroove"
local ItemVerb = require "wargroove/item_verb"

local Sabotage = ItemVerb:new()

function Sabotage:getMaximumRange(unit, endPos)
    return 3
end

function Sabotage:getTargetType()
    return "unit"
end

function Sabotage:canExecuteWithTarget(unit, endPos, targetPos, strParam)
    local target = Wargroove.getUnitAt(targetPos)

    if not target then
        return false
    end

    if target.isStructure then
        return false
    end

    if target.unitClass.isCommander then
        return false
    end

    if target.unitClass.moveRange <= 0 then
        return false
    end

    if target.unitClass.movementType ~= "wheels" then
        return false
    end

    if Wargroove.areEnemies(target.playerId, unit.playerId) then
        return true
    end

    return false
end

function Sabotage:execute(unit, targetPos, strParam, path)
    local target = Wargroove.getUnitAt(targetPos)
    
    print("UnitModifier")
    print(target.health)
    Wargroove.setUnitModifier(target.id, "MoveRange", -target.unitClass.moveRange, 999)
    Wargroove.updateUnit(target)
end

return Sabotage