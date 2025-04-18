local Wargroove = require "wargroove/wargroove"
local Verb = require "wargroove/verb"
local Combat = require "wargroove/combat"

local WaterCityAttack = Verb:new()
local costScoreFactor = 0.5
local effectRange = 1

function WaterCityAttack:getMaximumRange(unit, endPos)
    local maxRange = 0
    for i, weapon in ipairs(unit.unitClass.weapons) do
        if weapon.canMoveAndAttack or endPos == nil or (endPos.x == unit.pos.x and endPos.y == unit.pos.y) then
            maxRange = math.max(maxRange, weapon.maxRange)
        end
    end

    return maxRange
end

function WaterCityAttack:getTargetType()
    return "unit"
end


function WaterCityAttack:canExecuteAnywhere(unit)
    local weapons = unit.unitClass.weapons
    return #weapons > 0
end


function WaterCityAttack:canExecuteAt(unit, endPos)
    local weapons = unit.unitClass.weapons

    if #weapons == 1 and not weapons[1].canMoveAndAttack then
        local moved = endPos.x ~= unit.startPos.x or endPos.y ~= unit.startPos.y
        if moved then
            return false
        end
    end

    return true
end


function WaterCityAttack:canExecuteWithTarget(unit, endPos, targetPos, strParam)
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

        -- TODO: this should be cached, especially since we walk the same spaces A LOT
        -- Any enemies in the 1 radius range are automatically valid when using blockedByEnemies
        if weapons[1].blockedByEnemies and (xDiff > 1 or yDiff > 1) then
            local xDelta = endPos.x - targetPos.x
            local yDelta = endPos.y - targetPos.y

            -- Otherwise we march either horizontally/vertically along the position and check for enemies
            if xDiff > yDiff then
                -- horizontal walk
                local xStep = xDelta < 0 and -1 or 1
                local tmpPosX = targetPos.x + xStep

                while tmpPosX ~= endPos.x
                do
                    local targetUnit = Wargroove.getUnitAt({x = tmpPosX, y = targetPos.y})
                    if targetUnit and Wargroove.areEnemies(targetUnit.playerId, unit.playerId) then
                        return false
                    end

                    tmpPosX = tmpPosX + xStep
                end
            else 
                -- vertical walk OR same x/y, so we just do a vertical walk
                local yStep = yDelta < 0 and -1 or 1
                local tmpPosY = targetPos.y + yStep

                while tmpPosY ~= endPos.y
                do
                    local targetUnit = Wargroove.getUnitAt({x = targetPos.x, y = tmpPosY })
                    if targetUnit and Wargroove.areEnemies(targetUnit.playerId, unit.playerId) then
                        return false
                    end

                    tmpPosY = tmpPosY + yStep
                end
            end
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
    
    if #weapons == 1 and weapons[1].unitIdWhenAttacking ~= "" and weapons[1].unitIdWhenAttacking ~= unit.unitClass then
        print("Attack consideration: UnitIdWhenAttacking")

        if not Wargroove.canStandAt(weapons[1].unitIdWhenAttacking, endPos) then
            return false
        end
    end

    if targetUnit.canBeAttacked ~= nil and not targetUnit.canBeAttacked then
      return false
    end

    return Combat:getBaseDamage(unit, targetUnit, endPos) > 0.001
end


function WaterCityAttack:execute(unit, targetPos, strParam, path)
    --- Telegraph
    if (not Wargroove.isLocalPlayer(unit.playerId)) and Wargroove.canCurrentlySeeTile(targetPos) then
        Wargroove.spawnMapAnimation(targetPos, 0, "ui/grid/selection_cursor", "target", "over_units", {x = -4, y = -4})
        Wargroove.waitTime(0.5)
    end

    local target = Wargroove.getUnitAt(targetPos)
    Wargroove.startCombat(unit, target, path, "random")
end


function WaterCityAttack:generateOrders(unitId, canMove)
    local orders = {}
    if Wargroove.hasAIRestriction(unitId, "cant_attack") then
        return orders
    end

    local unit = Wargroove.getUnitById(unitId)
    local unitClass = Wargroove.getUnitClass(unit.unitClassId)

    if not self:canExecuteAnywhere(unit) then
      return orders
    end

    local movePositions = {}
    if canMove then
        movePositions = Wargroove.getTargetsInRange(unit.pos, unitClass.moveRange, "empty")
    end
    table.insert(movePositions, unit.pos)

    for i, pos in ipairs(movePositions) do
        local anyTargets = false
        local targets = Wargroove.getTargetsInRangeAfterMove(unit, pos, pos, effectRange, "unit")
        for j, targetPos in ipairs(targets) do
            local u = Wargroove.getUnitAt(targetPos)
            if u ~= nil then
                local uc = Wargroove.getUnitAt(targetPos)
                if Wargroove.areEnemies(u.playerId, unit.playerId) and (not uc.isStructure) then
                    anyTargets = true
                end
            end
        end
        if anyTargets then
            table.insert(orders, { targetPosition = pos, strParam = "", movePosition = pos, endPosition = pos })
        end
    end

    return orders
end

function WaterCityAttack:getScore(unitId, order)
    local unit = Wargroove.getUnitById(unitId)
    local unitClass = Wargroove.getUnitClass(unit.unitClassId)

    local damageScore = 0

    local function canTarget(u)
        if Wargroove.hasAIRestriction(u.id, "dont_target_this") then
            return false
        end
        if Wargroove.hasAIRestriction(unitId, "only_target_commander") and not u.unitClass.isCommander then
            return false
        end
        return Wargroove.areEnemies(u.playerId, unit.playerId) and not u.unitClass.isStructure
    end

    local targets = Wargroove.getTargetsInRangeAfterMove(unit, order.movePosition, order.targetPosition, effectRange, "unit")
    for i, targetPos in ipairs(targets) do
        local u = Wargroove.getUnitAt(targetPos)
        if u ~= nil and canTarget(u) then
            local uc = Wargroove.getUnitClass(u.unitClassId)
            local unitValue = math.sqrt(uc.cost / 100)
            if uc.isCommander then
                unitValue = 10
            end
            damageScore = damageScore + (spellDamage / 100) * unitValue
        end
    end

    local costScore = -math.sqrt(spellCost / 100) * costScoreFactor
    local score = damageScore + costScore

    return { score = score, healthDelta = 0, introspection = {
        { key = "damageScore", value = damageScore },
        { key = "cost", value = spellCost },
        { key = "costScore", value = costScore }}}
end


return WaterCityAttack
