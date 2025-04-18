local Wargroove = require "wargroove/wargroove"
local Verb = require "wargroove/verb"

local Refreshments = Verb:new()
local costScoreFactor = 0.5

function Refreshments:getMaximumRange(unit, endPos)
    return 1
end


function Refreshments:getTargetType()
    return "unit"
end

local function getRefreshmentCost(unit)
    local unitClass = Wargroove.getUnitClass(unit.unitClassId)

    return unitClass.resourceCost
end


function Refreshments:canExecuteWithTarget(unit, endPos, targetPos, strParam)
    local targetUnit = Wargroove.getUnitAt(targetPos)

    if not self:canSeeTarget(targetPos) then
        return false
    end

    if targetUnit == nil or not targetUnit.unitClass.isStructure then
        return false
    end

    local supplies = tonumber(Wargroove.getUnitState(targetUnit, "supplies"))
    if supplies and (supplies == 0 or getRefreshmentCost(unit) > supplies) then
        return false
    end

    if targetUnit.unitClassId == "tavern" then
        return true
    end

    return false
end


function Refreshments:getCostAt(unit, endPos, targetPos)
    return getRefreshmentCost(unit)
end


function Refreshments:execute(unit, targetPos, strParam, path)
    local targetUnit = Wargroove.getUnitAt(targetPos)

    local supplies = tonumber(Wargroove.getUnitState(targetUnit, "supplies"))
    local newSupplies = math.max(supplies - getRefreshmentCost(unit), 0)
    Wargroove.setUnitState(targetUnit, "supplies", newSupplies)
    Wargroove.updateUnit(targetUnit)

    Wargroove.spawnMapAnimation(unit.pos, 0, "fx/groove/inspire_unit")
    Wargroove.waitTime(0.4)
end


function Refreshments:onPostUpdateUnit(unit, targetPos, strParam, path)
    unit.hadTurn = false
    Wargroove.updateUnit(unit)
end

function Refreshments:generateOrders(unitId, canMove)
    local orders = {}
    -- Orders to use the tavern are generated in movement phase, so on C++ side.
    return orders
end

function Refreshments:getScore(unitId, order)
    return {score = 0, introspection = {}}
end

return Refreshments
