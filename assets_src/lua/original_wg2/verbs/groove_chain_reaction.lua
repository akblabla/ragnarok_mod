local Wargroove = require "wargroove/wargroove"
local GrooveVerb = require "wargroove/groove_verb"
local Verb = require "wargroove/verb"
local Combat = require "wargroove/combat"

local ChainReaction = GrooveVerb:new()

local damageStart = {1.0, 1.0 }
local damageFallOff = { 0.2, 0.1 }
local damageMinimum = { 0.1, 0.3 }
local minHealth = { 10, 10 }
local spawn = { "pistil_ball", "pistil_ball_strong" }

function ChainReaction:getMaximumRange(unit, endPos)
    return 1
end

function ChainReaction:getTargetType()
    return "unit"
end

function ChainReaction:canExecuteWithTarget(unit, endPos, targetPos, strParam)
    local targetUnit = Wargroove.getUnitAt(targetPos)

    if not self:canSeeTarget(targetPos) then
        return false
    end

    if not targetUnit or (not targetUnit.canBeAttacked) or unit==targetUnit then
        return false
    end

    if not targetUnit or (not targetUnit.unitClass.isAttackable) then
        return false
    end

    return true
end

local function isInList(target, targets)
    for i, unit in ipairs(targets) do
        if unit.id == target.id then
            return true
        end
    end

    return false
end

local function getChainTargets(unit, target, targets)
    -- Recursively walk through all chained targets relative to the target. Targets contains all the currently evaluated targets.
    local neighbours = Wargroove.getTargetsInRange(target.pos, 1, "unit")
    -- if depth > maxDepth then
    --     return
    -- end

    for i, p in ipairs(neighbours) do
        local target = Wargroove.getUnitAtXY(p.x, p.y)

        if target and unit~=target then
            if not isInList(target, targets) then
                table.insert(targets, target)
            end

            -- Recursive call, lord help us!
            -- getChainTargets(unit, target, targets, depth+1, maxDepth)
        end
    end
end

local function resetLists(availableList, usedList)
    for _, id in ipairs(usedList) do
        table.insert(availableList, id)
    end
    -- clear old table
    for k, v in pairs(usedList) do usedList[k] = nil end
end

local function trimList(availableList, unit)
    for _, id in ipairs(availableList) do
        local ball = Wargroove.getUnitById(id)
        if ball and ball.health > 0 then
            ball:setHealth(0, ball.id)
            Wargroove.moveUnitToOverride(ball.id, unit.pos, 0.55, -0.85, 20, "pow3In")
            Wargroove.updateUnit(ball)
        end
    end
end

local function getManhattanDist(posA, posB)
    local dx = posA.x - posB.x
    local dy = posA.y - posB.y
    return math.abs(dx) + math.abs(dy)
end

local function getClosestAvailableBall(availableList, usedList, position, tier)
    local bestAvailableCandidate = nil
    local bestIdx = 0;
    local bestUnavailableCandiate = nil
    
    local bestAvailableDistance = 99
    local bestUnavailableDistance = 99

    for i, id in ipairs(availableList) do
        local ball = Wargroove.getUnitById(id)
        if ball and ball.health > 0 then
            local dist = getManhattanDist(position, ball.pos)

            if dist <= 1 then
                bestAvailableCandidate = id
                bestAvailableDistance = dist
                bestIdx = i
                break
            end
        end
    end

    -- Couldn't find candidate -> spawn at closest used
    if bestAvailableCandidate == nil then
        for _, id in ipairs(usedList) do
            local ball = Wargroove.getUnitById(id)
            local dist = getManhattanDist(position, ball.pos)
    
            if dist < bestUnavailableDistance then
                bestUnavailableCandiate = id
                bestUnavailableDistance = dist
            end
        end
        local ball = Wargroove.getUnitById(bestUnavailableCandiate)

        local ballId = Wargroove.spawnUnit(ball.playerId, ball.pos, spawn[tier], false)
        table.insert(usedList, ballId)

        bestAvailableCandidate = ballId
    else
        table.remove(availableList, bestIdx)
        table.insert(usedList, bestAvailableCandidate)
    end

    return bestAvailableCandidate
end

function ChainReaction:getFacing(unit, target)
    if (unit.pos.x < target.x) then
        return "right"
    elseif (unit.pos.x > target.x) then
        return "left"
    else
        return ""
    end
end

function ChainReaction:execute(unit, targetPos, strParam, path)
    local tier = self:getCurrentGrooveTier(unit)

    Wargroove.setIsUsingGroove(unit.id, true)
    Wargroove.updateUnit(unit)

    if tier == 2 then
        Wargroove.playGrooveChargeUp(unit.pos, unit.playerId)
    end

    Wargroove.playPositionlessSound("battleStart")
    Wargroove.playGrooveCutscene(unit.id, tier)

    local initialTarget = Wargroove.getUnitAt(targetPos)
    local targets = { }
    local topLineTargets = { }
    local newTargetsFound = true
    local seekingDepth = 1

    local startFacing = self:getFacing(unit, initialTarget.pos)
    if (startFacing ~= "") then
        Wargroove.setFacingOverride(unit.id, startFacing)
    end

    table.insert(targets, initialTarget)
    table.insert(targets, { id = -999999, depth = 0 })
    table.insert(topLineTargets, initialTarget)

    while (newTargetsFound) do
        local preSeekNum = #targets

        for _, target in ipairs(topLineTargets) do
            getChainTargets(unit, target, targets)
        end

        -- We pick off end of the line as a starting point for the next one
        topLineTargets = { }
        for i=preSeekNum+1, #targets do
            table.insert(topLineTargets, targets[i])
        end

        if preSeekNum == #targets then
            newTargetsFound = false
        else
            -- This is "depth" separator
            table.insert(targets, { id = -seekingDepth, depth = seekingDepth })
            
            seekingDepth = seekingDepth + 1
        end
    end
    
    Wargroove.playUnitAnimation(unit.id, "groove_start", "groove_idle")
    Wargroove.playMapSound("pistil/pistilGroove", unit.pos)

    Wargroove.waitTime(2.4)

    -- Hurt Pistil first
    local currentDamage = damageStart[tier]

    -- Ball spawn:
    -- 1. For each target at current depth, spawn 1 ball. Store ball in "list"
    -- 2. When next depth is hit, move closest available ball to new target, add to unavailable list
    -- 3. If not ball is left in list, spawn new ball at closest unavailable and assign to new target
    -- 4. If any balls are left in the available at tend off cycle, destroy them

    local availableList = {}
    local usedList = {}

    local ballId = Wargroove.spawnUnit(unit.playerId, unit.pos, spawn[tier], false, "spawn")
    table.insert(availableList, ballId)

    Wargroove.waitTime(0.2)
    Wargroove.playMapSound("pistil/pistilGrooveBallOn", unit.pos)

    local lastBallId = nil
    local activateReturnIndex = #targets / 2
    if #targets == 1 then
        activateReturnIndex = 1
    end

    local activatedReturn = false

    local targetCount = 0

    for i, target in ipairs(targets) do
        if target.id < 0 then
            while Wargroove.isLuaMoving(lastBallId) do
                coroutine.yield()
            end

            -- Any leftover in available will get trimmed
            trimList(availableList, unit)
            -- Reset all in used to available for next stage
            resetLists(availableList, usedList)

            print(Wargroove.tableToString(target))
            -- separator hit, going one depth down
            currentDamage = math.max(damageStart[tier] - (damageFallOff[tier]*(target.depth+1)), damageMinimum[tier])

            Wargroove.waitTime(0.05)
            goto NEXT_UNIT
        end

        -- Move an available ball to this location
        local ballId = getClosestAvailableBall(availableList, usedList, target.pos, tier)
        local ball = Wargroove.getUnitById(ballId)

        Wargroove.moveUnitToOverride(ballId, target.pos, 0, 0, 20, "pow3In")
        ball.pos = target.pos
        lastBallId = ballId

        local damage = Combat:getGrooveAttackerDamage(unit, target, "average", unit.pos, target.pos, path, nil) * currentDamage

        local rngHit = Wargroove.randomIntegerFromTable({ i, ballId, unit.pos }, 1, 3)

        if tier == 1 then
            Wargroove.spawnMapAnimation(target.pos, 0, "units/commanders/pistil/pistil_ball_effects", "hit" .. rngHit, "sky", {x=12, y=2})
        elseif tier == 2 then
            Wargroove.spawnMapAnimation(target.pos, 0, "units/commanders/pistil/pistil_ball_effects_big", "hit" .. rngHit, "sky", {x=12, y=2})
        end
        Wargroove.waitFrame()

        local currentMinHealth = math.min(minHealth[tier], target.health)

        if i >= activateReturnIndex and not activatedReturn then
            activatedReturn = true
            Wargroove.playUnitAnimation(unit.id, "groove_end", "idle")
        end

        if target.playerId >= 0 then
            target:setHealth(math.max(target.health - damage, currentMinHealth), unit.id)
            Wargroove.updateUnit(target)
            Wargroove.playUnitAnimation(target.id, "hit")
        end
        Wargroove.playMapSound("pistil/pistilGrooveBallZap", target.pos)
        targetCount = targetCount + 1
        :: NEXT_UNIT ::
    end

    Wargroove.playMapSound("pistil/pistilGrooveBallOff", unit.pos)

    trimList(availableList, unit)
    trimList(usedList, unit)

    Wargroove.unsetFacingOverride(unit.id)
    
    Wargroove.setPlayerCounter("chainReactionCount", targetCount)

    Wargroove.waitTime(0.5)
end

function ChainReaction:generateOrders(unitId, canMove)
    local orders = {}

    local unit = Wargroove.getUnitById(unitId)
    local unitClass = Wargroove.getUnitClass(unit.unitClassId)

    local movePositions = {}
    if canMove then
        movePositions = Wargroove.getTargetsInRange(unit.pos, unitClass.moveRange, "empty")
    end
    table.insert(movePositions, unit.pos)

    for i, pos in pairs(movePositions) do
        local targets = Wargroove.getTargetsInRangeAfterMove(unit, pos, pos, 1, "unit")
        for j, targetPos in ipairs(targets) do
            if self:canExecuteWithTarget(unit, pos, targetPos, "") then
                local u = Wargroove.getUnitAt(targetPos)
                -- AI ignores friendly targets for the initial attack
                if not Wargroove.areAllies(u.playerId, unit.playerId) then
                    orders[#orders+1] = { targetPosition = targetPos, strParam = "", movePosition = pos, endPosition = pos }
                end
            end
        end
    end

    return orders
end

function ChainReaction:getScore(unitId, order)
    local unit = Wargroove.getUnitById(unitId)
    local tier = self:getCurrentGrooveTier(unit)

    local targets = { Wargroove.getUnitAt(order.targetPosition) }
    local seekingDepth = 1
    local newTargetsFound = true

    local opportunityCost = 0.25 + 0.75 * tier
    local totalScore = 0

    while (newTargetsFound) do
        local preSeekNum = #targets

        for _, target in ipairs(targets) do
            getChainTargets(unit, target, targets)
        end

        local damage = math.max(damageStart[tier] - (damageFallOff[tier] * (seekingDepth + 1)), damageMinimum[tier])

        for i=preSeekNum+1, #targets do
            local u = targets[i]
            local uc = u.unitClass
            if not uc.isStructure then
                if not Wargroove.areAllies(u.playerId, unit.playerId) then
                    totalScore = totalScore + uc.cost * damage
                else
                    totalScore = totalScore - uc.cost * damage * 2.5
                end
            end
        end

        if preSeekNum == #targets then
            newTargetsFound = false
        else
            seekingDepth = seekingDepth + 1
        end
    end

    local score = totalScore * (#targets) / 100.0 + opportunityCost

    --print("chain_reaction: score " .. score)

    local introspection = {}

    return {score = score, introspection = introspection}
end

return ChainReaction
