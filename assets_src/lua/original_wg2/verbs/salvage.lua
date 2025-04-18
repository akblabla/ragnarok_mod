local Wargroove = require "wargroove/wargroove"
local Verb = require "wargroove/verb"
local Combat = require "wargroove/combat"

local Salvage = Verb:new()

function Salvage:getMaximumRange(unit, endPos)
    return 1
end

function Salvage:getTargetType()
    return "unit"
end

function Salvage:canExecuteWithTarget(unit, endPos, targetPos, strParam)
    local targetUnit = Wargroove.getUnitAt(targetPos)

    if targetUnit then
        local uc = Wargroove.getUnitClass(targetUnit.unitClassId)
        return (uc.inWater or uc.movementType == "wheels") and targetUnit.health <= 20 and Wargroove.areEnemies(unit.playerId, targetUnit.playerId)
    end

    return false
end

local function getSurroundingUnits(unit, pos)
    result = {}
    for i, p in ipairs(Wargroove.getTargetsInRangeAfterMove(unit, pos, pos, 1, "unit")) do
        local targetUnit = Wargroove.getUnitAt(p)

        if targetUnit then
            local uc = Wargroove.getUnitClass(targetUnit.unitClassId)
            if (uc.inWater or uc.movementType == "wheels") and targetUnit.health <= 20 and Wargroove.areEnemies(unit.playerId, targetUnit.playerId) then
                table.insert(result, targetUnit)
            end
        end
    end
    return result
end

local function getSalvageAmount(health, unit)
    local fullCost = Wargroove.getUnitClass(unit.unitClassId).cost
    return math.ceil(health * fullCost / 100)
end

local function getSalvageAvailableAt(unit, pos)
    local salvageAvailable = 0
    for i, u in ipairs(getSurroundingUnits(unit, pos)) do
        salvageAvailable = math.max(salvageAvailable, getSalvageAmount(u.health, u))
    end
    return salvageAvailable
end

function Salvage:getCostAt(unit, endPos, targetPos)
    if targetPos == nil then 
        return getSalvageAvailableAt(unit, endPos)
    end

    local targetUnit = Wargroove.getUnitAt(targetPos)
    if targetUnit == nil then
        return 0
    end

    local salvageAmount = getSalvageAmount(targetUnit.health, targetUnit)
    return salvageAmount
end

function Salvage:execute(unit, targetPos, strParam, path)
    local targetUnit = Wargroove.getUnitAt(targetPos)

    local salvageAmount = getSalvageAmount(targetUnit.health, targetUnit)
    Wargroove.changeMoney(unit.playerId, salvageAmount)

    targetUnit.health = 0
    Wargroove.updateUnit(targetUnit)

    Wargroove.spawnMapAnimation(targetUnit.pos, 0, "fx/ransack_1", "default", "over_units", { x = 12, y = 0 })
    Wargroove.playMapSound("thiefGoldReleased", targetUnit.pos)
end

return Salvage
