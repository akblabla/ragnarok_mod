local Wargroove = require "wargroove/wargroove"
local Verb = require "wargroove/verb"

local HospitalHeal = Verb:new()
local costScoreFactor = 0.5
local healAmount = 50

function HospitalHeal:getMaximumRange(unit, endPos)
    return 1
end


function HospitalHeal:getTargetType()
    return "unit"
end

local function getHealCost(unit)
    local unitClass = Wargroove.getUnitClass(unit.unitClassId)

    return unitClass.resourceCost
end


function HospitalHeal:canExecuteWithTarget(unit, endPos, targetPos, strParam)
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

    if targetUnit.unitClassId == "hospital" then
        return true
    end

    return false
end


function HospitalHeal:getCostAt(unit, endPos, targetPos)
    return getHealCost(unit)
end


function HospitalHeal:execute(unit, targetPos, strParam, path)
    local targetUnit = Wargroove.getUnitAt(targetPos)

    local supplies = tonumber(Wargroove.getUnitState(targetUnit, "supplies"))
    local newSupplies = math.max(supplies - getHealCost(unit), 0)
    Wargroove.setUnitState(targetUnit, "supplies", newSupplies)
    Wargroove.updateUnit(targetUnit)

    unit:setHealth(unit.health + healAmount, unit.id)
    Wargroove.updateUnit(unit)

    Wargroove.spawnMapAnimation(unit.pos, 0, "fx/reinforce_2", "default", "over_units", { x = 12, y = 0 })
    Wargroove.playMapSound("reinforceUnitHeal", unit.pos)
    Wargroove.waitTime(0.4)
end


function HospitalHeal:onPostUpdateUnit(unit, targetPos, strParam, path)
    unit.hadTurn = true
    Wargroove.updateUnit(unit)
end

function HospitalHeal:generateOrders(unitId, canMove)
    --print("generateOrders not implemented for 'HospitalHeal'.")
    return {}
end

function HospitalHeal:getScore(unitId, order)
    print("getScore not implemented for 'HospitalHeal'.")
    return {score = -1, introspection = {}}
end

return HospitalHeal
