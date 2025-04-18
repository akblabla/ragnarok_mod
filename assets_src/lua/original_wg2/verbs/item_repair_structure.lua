local Wargroove = require "wargroove/wargroove"
local Verb = require "wargroove/verb"

local RepairStructure = Verb:new()

local heal = 100
local cost = 200

function RepairStructure:getMaximumRange(unit, endPos)
    return 1
end


function RepairStructure:getTargetType()
    return "unit"
end


function RepairStructure:getCostAt(unit, endPos, targetPos)
    return cost
end


function RepairStructure:canExecuteWithTarget(unit, endPos, targetPos, strParam)
    if not self:canSeeTarget(targetPos) then
        return false
    end

    local targetUnit = Wargroove.getUnitAt(targetPos)

    if not targetUnit then
        return false
    end

    if not targetUnit.unitClass.isStructure then
        return false
    end

    if not Wargroove.areAllies(targetUnit.playerId, unit.playerId) then
        return false
    end

    if targetUnit.health == 100 then
        return false
    end

    return true
end


function RepairStructure:execute(unit, targetPos, strParam, path)
    local targetUnit = Wargroove.getUnitAt(targetPos)

    Wargroove.waitTime(0.5)

    targetUnit:setHealth(targetUnit.health + heal, unit.id)
    Wargroove.updateUnit(targetUnit)
    Wargroove.spawnMapAnimation(targetUnit.pos, 0, "fx/heal_unit", "default", "over_units", { x = 12, y = 12 })
    Wargroove.playMapSound("unitHealed", unit.pos)
end

return RepairStructure