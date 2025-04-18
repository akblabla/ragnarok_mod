local Wargroove = require "wargroove/wargroove"
local Verb = require "wargroove/verb"
local Combat = require "wargroove/combat"


local Attack = Verb:new()


function Attack:getMaximumRange(unit, endPos)
    local maxRange = 0
    for i, weapon in ipairs(unit.unitClass.weapons) do
        if weapon.canMoveAndAttack or endPos == nil or (endPos.x == unit.pos.x and endPos.y == unit.pos.y) then
            maxRange = math.max(maxRange, weapon.maxRange)
        end
    end

    return maxRange
end


function Attack:getTargetType()
    return "unit"
end


function Attack:canExecuteAnywhere(unit)
    local weapons = unit.unitClass.weapons
    return #weapons > 0
end


function Attack:canExecuteAt(unit, endPos)
    local weapons = unit.unitClass.weapons

    if #weapons == 1 and not weapons[1].canMoveAndAttack then
        local moved = endPos.x ~= unit.startPos.x or endPos.y ~= unit.startPos.y
        if moved then
            return false
        end
    end

    return true
end


function Attack:canExecuteWithTarget(unit, endPos, targetPos, strParam)
    if not self:canSeeTarget(targetPos) then
        return false
    end

    local weapons = unit.unitClass.weapons
    if #weapons == 1 and weapons[1].horizontalAndVerticalOnly then
        local moved = endPos.x ~= unit.startPos.x or endPos.y ~= unit.startPos.y
        local xDiff = math.abs(endPos.x - targetPos.x)
        local yDiff = math.abs(endPos.y - targetPos.y)
        local maxDiff = weapons[1].horizontalAndVerticalExtraWidth
        if (xDiff > maxDiff and yDiff > maxDiff) then
            return false
        end
    end

    if #weapons == 1 and #(weapons[1].terrainExclusion) > 0 then
        local targetTerrain = Wargroove.getTerrainNameAt(targetPos)
        for i, terrain in ipairs(weapons[1].terrainExclusion) do
            if targetTerrain == terrain then
                return false
            end
        end
    end
    
    local targetUnit = Wargroove.getUnitAt(targetPos)

    if not targetUnit or not Wargroove.areEnemies(unit.playerId, targetUnit.playerId) then
        return false
    end

    if targetUnit.canBeAttacked ~= nil and not targetUnit.canBeAttacked then
      return false
    end

    return Combat:getBaseDamage(unit, targetUnit, endPos) > 0.001
end


function Attack:execute(unit, targetPos, strParam, path)
    --- Telegraph
    if (not Wargroove.isLocalPlayer(unit.playerId)) and Wargroove.canCurrentlySeeTile(targetPos) then
        Wargroove.spawnMapAnimation(targetPos, 0, "ui/grid/selection_cursor", "target", "over_units", {x = -4, y = -4})
        Wargroove.waitTime(0.5)
    end

    Wargroove.startCombat(unit, Wargroove.getUnitAt(targetPos), path)
end


return Attack
