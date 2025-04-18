local Wargroove = require "wargroove/wargroove"
local Verb = require "wargroove/verb"

local BonfireHeal = Verb:new()
local costScoreFactor = 0.5
local healAmount = 30
local healCost = 200

function BonfireHeal:getMaximumRange(unit, endPos)
    return 1
end


function BonfireHeal:getTargetType()
    return "unit"
end

local function getHealCost(unit)
    return healCost
end

function BonfireHeal:canExecuteAnywhere(unit)
    return Wargroove.getMoney(unit.playerId) >= getHealCost(unit)
end

function BonfireHeal:canExecuteWithTarget(unit, endPos, targetPos, strParam)
    local targetUnit = Wargroove.getUnitAt(targetPos)

    if not self:canSeeTarget(targetPos) then
        return false
    end

    if targetUnit == nil or not targetUnit.unitClass.isStructure then
        return false
    end

    local supplies = tonumber(Wargroove.getUnitState(targetUnit, "supplies"))
    if supplies and (supplies == 0 or getHealCost(unit) > supplies) then
        return false
    end

    if targetUnit.hadTurn then
        return false
    end

    if not Wargroove.areAllies(unit.playerId, targetUnit.playerId) then
        return false
    end

    if targetUnit.unitClassId == "bonfire" then
        return true
    end

    return false
end


function BonfireHeal:getCostAt(unit, endPos, targetPos)
    return getHealCost(unit)
end


function BonfireHeal:execute(unit, targetPos, strParam, path)
    local targetUnit = Wargroove.getUnitAt(targetPos)
    targetUnit.hadTurn = true
    Wargroove.updateUnit(targetUnit)

    Wargroove.changeMoney(unit.playerId, -healCost)

    unit:setHealth(unit.health + healAmount, unit.id)
    Wargroove.updateUnit(unit)

    Wargroove.spawnMapAnimation(unit.pos, 0, "fx/reinforce_2", "default", "over_units", { x = 12, y = 0 })
    Wargroove.playMapSound("reinforceUnitHeal", unit.pos)
    Wargroove.waitTime(0.4)
end


function BonfireHeal:onPostUpdateUnit(unit, targetPos, strParam, path)
    unit.hadTurn = true
    Wargroove.updateUnit(unit)
end

return BonfireHeal
