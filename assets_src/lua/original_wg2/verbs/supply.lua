local Verb = require "wargroove/verb"
local Wargroove = require "wargroove/wargroove"

local Supply = Verb:new()

local supplyCost = 150
local supplyHealAmount = 25

function Supply:getMaximumRange(unit, endPos)
    return 1
end

function Supply:getTargetType()
    return "unit"
end

function Supply:getCostAt(unit, endPos, targetPos)
    return supplyCost;
end


function Supply:canExecuteWithTarget(unit, endPos, targetPos, strParam)
    if supplyCost >= Wargroove.getMoney(unit.playerId) then
        return false
    end

    if not self:canSeeTarget(targetPos) then
        return false
    end
    
    if targetPos.x == unit.pos.x and targetPos.y == unit.pos.y then
        return true
    end

    local targetUnit = Wargroove.getUnitAt(targetPos)
    return targetUnit and not Wargroove.areEnemies(targetUnit.playerId, unit.playerId)
end

function Supply:execute(unit, targetPos, strParam, path)
    local targetUnit = Wargroove.getUnitAt(targetPos)
    targetUnit.health = math.min(targetUnit.health + supplyHealAmount, 100)

    Wargroove.spawnMapAnimation(targetUnit.pos, 0, "fx/heal_unit")
    Wargroove.playMapSound("twins/errolGrooveUnitsHealed", targetUnit.pos)
    
    Wargroove.updateUnit(targetUnit)

    Wargroove.changeMoney(unit.playerId, -supplyCost)
end

return Supply
