local Wargroove = require "wargroove/wargroove"
local Verb = require "wargroove/verb"
local UnitOnTurn = require "wargroove/unit_on_turn"

local PullFar = Verb:new()

local pullRange = 5

function PullFar:getMaximumRange(unit, endPos)
    return pullRange
end

function PullFar:getTargetType()
    return "all"
end

function PullFar:getTargetArrows(unit, targetPos, endPos)
    local results = {}

    local pullResult = Wargroove.getPushPullResult(endPos, targetPos, -1, true, false)
    local targetArrow = Wargroove.createTargetArrowFromPushPullResult(pullResult)
    if targetArrow then
        table.insert(results, targetArrow)
    end

    return results
end

function PullFar:canExecuteWithTarget(unit, endPos, targetPos, strParam)
    if not self:canSeeTarget(targetPos) then
        return false
    end

    -- Check for cardinal directions
    local deltaX = clamp(targetPos.x - endPos.x, -1, 1)
    local deltaY = clamp(targetPos.y - endPos.y, -1, 1)

    if math.abs(deltaX) > 0 and math.abs(deltaY) > 0 then
        return false
    end
    
    local targetUnit = Wargroove.getUnitAt(targetPos)
    local pullPosition = { x=targetPos.x - deltaX, y=targetPos.y - deltaY }
    
    if targetUnit == nil or targetUnit.id == unit.id or not Wargroove.isValidPushPullTarget(targetUnit, false) then
        return false
    end

    if Wargroove.getUnitState(targetUnit, "tentacled") == "true" then
        return false
    end

    if pullPosition.x == endPos.x and pullPosition.y == endPos.y then
        return false
    end
    
    return true
end

function PullFar:execute(unit, targetPos, strParam, path)
    local pullDistance = math.max(math.abs(targetPos.x - unit.pos.x), math.abs(targetPos.y - unit.pos.y))
    pullDistance = clamp(pullDistance, 1, pullRange)

    local facing = Wargroove.getFacing(unit, targetPos)
    local postfix = ""

    print("Facing: " .. facing)

    Wargroove.setFacingOverride(unit.id, facing)

    if facing == "right" then
        postfix = ""
    elseif facing == "left" then
        postfix = ""
    elseif facing == "up" then
        facing = "down"
        postfix = "up_"
    else
        facing = "up"
        postfix = "down_"
    end

    Wargroove.playUnitAnimation(unit.id, "pull_" .. postfix .. pullDistance)
    Wargroove.playMapSound("frogPull", unit.pos)
    Wargroove.waitTime(0.7)
    
    local pullResult = Wargroove.getPushPullResult(unit.pos, targetPos, -1, false, false)
    Wargroove.processPushPullResult(unit, pullResult, 0, 20)

    Wargroove.waitTime(0.5)
    Wargroove.unsetFacingOverride(unit.id)

    UnitOnTurn:setCooldown(Wargroove, unit, 2, 3)
end

function PullFar:generateOrders(unitId, canMove)
    local orders = {}

    local unit = Wargroove.getUnitById(unitId)
    local unitClass = Wargroove.getUnitClass(unit.unitClassId)

    if UnitOnTurn:isOnCooldown(Wargroove, unit) then
        print("pull is still on cooldown")
        return orders
    end

    if not self:canExecuteAnywhere(unit) then
        return orders
    end

    local movePositions = {}
    if canMove then
        movePositions = Wargroove.getTargetsInRange(unit.pos, unitClass.moveRange, "empty")
    end
    table.insert(movePositions, unit.pos)

    for i, pos in ipairs(movePositions) do
        local targets = Wargroove.getTargetsInRangeAfterMove(unit, pos, pos, pullRange, "unit")
        for j, targetPos in ipairs(targets) do
            -- There used to be a bunch of extra checks here, but all of them
            -- are done by canExecuteWithTarget() too/again.
            if Wargroove.canAIPlayerSeeTile(-1, targetPos) and self:canExecuteWithTarget(unit, pos, targetPos, "") then
                table.insert(orders, { targetPosition = targetPos, strParam = "", movePosition = pos, endPosition = pos })
            end
        end
    end

    return orders
end

function PullFar:getScore(unitId, order)
    local unit = Wargroove.getUnitById(unitId)
    local unitClass = Wargroove.getUnitClass(unit.unitClassId)

    local target = Wargroove.getUnitAt(order.targetPosition)
    local targetClass = Wargroove.getUnitClass(target.unitClassId)

    local opportunityCost = -1
    local totalScore = 0
    local maxScore = 300

    -- pull position
    local deltaX = clamp(target.pos.x - unit.pos.x, -1, 1)
    local deltaY = clamp(target.pos.y - unit.pos.y, -1, 1)
    local pullPosition = { x=target.pos.x - deltaX, y=target.pos.y - deltaY }

    -- friend or foe
    local isEnemy = Wargroove.areEnemies(unit.playerId, target.playerId)

    if isEnemy then
        --totalScore = totalScore + 1000
        -- enemy unit
        local moveCostNow = Wargroove.getTerrainMovementCostAt(target.pos)
        local moveCostAfter = Wargroove.getTerrainMovementCostAt(pullPosition)
        --print("enemy move cost " .. moveCostNow .. " -> " .. moveCostAfter)
        if (moveCostAfter > moveCostNow) and (moveCostAfter < 99) then
            totalScore = totalScore + 450 * (moveCostAfter - moveCostNow)
        end
    else
        --[[if not target.hadTurn then
            -- friendly unit, hasn't moved yet:
            local moveCostNow = Wargroove.getTerrainMovementCostAt(target.pos)
            local moveCostAfter = Wargroove.getTerrainMovementCostAt(pullPosition)
            --print("friendly hasn't moved yet, move cost " .. moveCostNow .. " -> " .. moveCostAfter)
            if (moveCostAfter < moveCostNow) and (moveCostAfter < 99) then
                totalScore = totalScore + 450 * (moveCostNow - moveCostAfter)
            end
        else
            -- friendly unit, already has moved
            -- TODO: as of now, frogs always seem to move first - score too high?
            local defenseNow = Wargroove.getBaseTerrainDefenceAt(target.pos)
            local defenseAfter = Wargroove.getBaseTerrainDefenceAt(pullPosition)
            --print("friendly has moved already, defense " .. defenseNow .. " -> " .. defenseAfter)
            if (defenseAfter > defenseNow) then
                totalScore = totalScore + 1200
            end
        end]]--
    end

    local score = totalScore / maxScore + opportunityCost
    return {score = score, introspection = {{key = "totalScore", value = totalScore}}}
end

return PullFar