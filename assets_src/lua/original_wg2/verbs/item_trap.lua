local Wargroove = require "wargroove/wargroove"
local ItemVerb = require "wargroove/item_verb"

local Trap = ItemVerb:new()

function Trap:getMaximumRange(unit, endPos)
    return 3
end

function Trap:getTargetType()
    return "unit"
end

function Trap:canExecuteWithTarget(unit, endPos, targetPos, strParam)
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

    if Wargroove.areEnemies(target.playerId, unit.playerId) then
        return true
    end

    return false
end

function Trap:execute(unit, targetPos, strParam, path)
    local target = Wargroove.getUnitAt(targetPos)
    
    print("UnitModifier")
    print(target.health)
    Wargroove.setUnitModifier(target.id, "MoveRange", -target.unitClass.moveRange, 2)
    Wargroove.updateUnit(target)
end

return Trap