local Wargroove = require "wargroove/wargroove"
local ItemVerb = require "wargroove/item_verb"

local healAmount = 50

local ItemHealingPotion = ItemVerb:new()

function ItemHealingPotion:getMaximumRange(unit, endPos)
    return 0
end

function ItemHealingPotion:getTargetType()
  return "unit"
end

function ItemHealingPotion:canExecuteWithTarget(unit, endPos, targetPos, strParam)
    if not self:canSeeTarget(targetPos) then
        return false
    end

    return true
end

function ItemHealingPotion:execute(unit, targetPos, strParam, path)
    unit.health = math.min(unit.health + healAmount, 100)

    Wargroove.spawnMapAnimation(unit.pos, 0, "fx/heal_unit")
    Wargroove.playMapSound("twins/errolGrooveUnitsHealed", unit.pos)
    
    Wargroove.updateUnit(unit)

    Wargroove.waitTime(1.2)
end

function ItemHealingPotion:generateOrders(unitId, canMove)
    local orders = {}

    local unit = Wargroove.getUnitById(unitId)
    if unit.itemId == "potion01" then
        local unitClass = Wargroove.getUnitClass(unit.unitClassId)
        local movePositions = {}
        if canMove then
            movePositions = Wargroove.getTargetsInRange(unit.pos, unitClass.moveRange, "empty")
        end
        table.insert(movePositions, unit.pos)

        for i, pos in pairs(movePositions) do
            orders[#orders+1] = {targetPosition = pos, strParam = "", movePosition = pos, endPosition = pos}
        end
    end

    return orders
end

return ItemHealingPotion