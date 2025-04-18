local Verb = require "wargroove/verb"
local Wargroove = require "wargroove/wargroove"
local UnitOnTurn = require "wargroove/unit_on_turn"

local Tentacle = Verb:new()

function Tentacle:getMaximumRange(unit, endPos)
    return 3
end

function Tentacle:getTargetType()
    return "unit"
end

function getTentaclePositions(targetPos, endPos)
    if targetPos.x == endPos.x and targetPos.y == endPos.y then
        return nil
    end

    -- steps each tile towards target
    local deltaX = clamp(targetPos.x - endPos.x, -1, 1)
    local deltaY = clamp(targetPos.y - endPos.y, -1, 1)

    if math.abs(deltaX) > 0 and math.abs(deltaY) > 0 then
        return nil
    end

    local tentaclePositions = {}

    if deltaX ~= 0 then
        for i=endPos.x+deltaX,targetPos.x-deltaX,deltaX do
            local nextPos = {x=i, y=targetPos.y}

            table.insert(tentaclePositions, nextPos)
        end
    else
        for i=endPos.y+deltaY,targetPos.y-deltaY,deltaY do
            local nextPos = {x=targetPos.x, y=i}

            table.insert(tentaclePositions, nextPos)
        end
    end

    return tentaclePositions
end

function Tentacle:canExecuteWithTarget(unit, endPos, targetPos, strParam)
    
    if not self:canSeeTarget(targetPos) then
        return false
    end

    local tentaclePositions = getTentaclePositions(targetPos, endPos)
    if tentaclePositions == nil then
        return false
    end

    -- Check for obstacles along the way
    for i, pos in ipairs(tentaclePositions) do
        local pathUnit = Wargroove.getUnitAt(pos)
        if pathUnit ~= nil and pathUnit ~= unit then
            return false
        end

        if not Wargroove.canStandAt("tentacle", pos) then
            return false
        end
    end
    
    local targetUnit = Wargroove.getUnitAt(targetPos)
    if targetUnit and targetUnit.tentacled then
        return false
    end

    return targetUnit ~= nil and not targetUnit.unitClass.isStructure and targetUnit.canBeAttacked and targetUnit.unitClass.isAttackable and targetUnit.unitClassId ~= "tentacle"
end

function Tentacle:execute(unit, targetPos, strParam, path)
    local tentaclePositions = getTentaclePositions(targetPos, unit.pos)

    local facing = Wargroove.getFacing(unit, targetPos)

    -- This is a bit of a hack, not sure we want to keep this
    Wargroove.unsetFacingOverride(unit.id)

    unit.pos.facing = 1
    Wargroove.updateUnit(unit)
    Wargroove.waitFrame()

    Wargroove.playMapSound("krakenTentacle", unit.pos)
    Wargroove.playUnitAnimation(unit.id, facing.."_grab_start", facing.."_grab_idle")
    Wargroove.waitTime(0.3)

    -- Spawn the tentacles
    for i, pos in ipairs(tentaclePositions) do
        local startingState = {}
        local krakenId = {key = "parentId", value = unit.id};
        table.insert(startingState, krakenId)

        Wargroove.spawnUnit(unit.playerId, pos, "tentacle", false, "shoot_"..facing, startingState)
        Wargroove.waitTime(0.1)
    end

    for i, pos in ipairs(tentaclePositions) do
        -- Make sure it's idling correctly
        local freshTentacleBaby = Wargroove.getUnitAt(pos)
        freshTentacleBaby.hadTurn = true
        freshTentacleBaby.health = unit.health
        Wargroove.updateUnit(freshTentacleBaby)

        Wargroove.playUnitAnimation(freshTentacleBaby.id, "idle_"..facing, "idle_"..facing)
    end

    -- Set the tentacles
    local targetUnit = Wargroove.getUnitAt(targetPos)

    print("Storing tentacles: "..Wargroove.positionsToString(tentaclePositions))

    Wargroove.setUnitState(unit, "tentacles", Wargroove.positionsToString(tentaclePositions))
    Wargroove.setUnitState(unit, "targetId", ""..targetUnit.id)

    Wargroove.updateUnit(unit)

    Wargroove.setUnitState(targetUnit, "parentId", ""..unit.id)
    Wargroove.setUnitState(targetUnit, "tentacleFacing", ""..facing)
    targetUnit.tentacled = true

    local tentacledEffectId = Wargroove.spawnUnitEffect(targetUnit.id, unit.id, "units/kraken/cherrystone/map_kraken_tentacle_cherrystone", "grabbed_"..facing, "grab_"..facing, true)
    
    Wargroove.playUnitAnimation(targetUnit.id, "hit")

    Wargroove.updateUnit(targetUnit)

    UnitOnTurn:setCooldown(Wargroove, unit, 2, 3)
end

function Tentacle:onPostUpdateUnit(unit, targetPos, strParam, path)
    Verb.onPostUpdateUnit(self, unit, targetPos, strParam, path)
    unit.pos.facing = 1
end

function Tentacle:generateOrders(unitId, canMove)
    local orders = {}

    local unit = Wargroove.getUnitById(unitId)
    local unitClass = Wargroove.getUnitClass(unit.unitClassId)

    if not self:canExecuteAnywhere(unit) then
        return orders
    end

    if UnitOnTurn:isOnCooldown(Wargroove, unit) then
        print("tentacle is still on cooldown")
        return orders
    end

    local movePositions = {}
    if canMove then
        movePositions = Wargroove.getTargetsInRange(unit.pos, unitClass.moveRange, "empty")
    end
    table.insert(movePositions, unit.pos)

    for i, pos in ipairs(movePositions) do
        local targets = Wargroove.getTargetsInRangeAfterMove(unit, pos, pos, 2, "unit")
        for j, targetPos in ipairs(targets) do
            local u = Wargroove.getUnitAt(targetPos)
            if u ~= nil and (not u.tentacled) then
                local dx = targetPos.x - pos.x
                local dy = targetPos.y - pos.y
                if ((math.abs(dx) + math.abs(dy)) == 2) and ((dx * dy) < 0.1) then
                    local uc = Wargroove.getUnitAt(targetPos)
                    if Wargroove.areEnemies(u.playerId, unit.playerId) and (not uc.isStructure) then
                        if self:canExecuteWithTarget(unit, pos, targetPos, "") then
                            local tentaclePos = { x = pos.x + dx, y = pos.y + dy }
                            table.insert(orders, { targetPosition = tentaclePos, strParam = "", movePosition = pos, endPosition = pos })
                        end
                    end
                end
            end
        end
    end

    return orders
end

function Tentacle:getScore(unitId, order)
    local unit = Wargroove.getUnitById(unitId)
    local unitClass = Wargroove.getUnitClass(unit.unitClassId)

    local target = Wargroove.getUnitAt(order.targetPosition)
    local targetClass = Wargroove.getUnitClass(target.unitClassId)

    local opportunityCost = -1
    local totalScore = 0
    local maxScore = 300

    -- Check potential targets of target.
    -- This is a pretty rough check, because it uses the current state, which means it doesn't
    -- take movements and actions during the AI's current turn into account.

    local wouldStopAttacks = {}
    local targetMovePositions = Wargroove.getTargetsInRange(target.pos, targetClass.moveRange, "empty")
    for i, pos in ipairs(targetMovePositions) do
        local targetsOfTarget = Wargroove.getTargetsInRangeAfterMove(target, pos, pos, self:getMaximumRange(target, pos), "unit")
        for j, targetOfTargetPos in ipairs(targetsOfTarget) do
            local u = Wargroove.getUnitAt(targetOfTargetPos)
            if u ~= nil and (not u.tentacled) then
                local uc = Wargroove.getUnitClass(u.unitClassId)
                if Wargroove.areEnemies(u.playerId, target.playerId) then
                    wouldStopAttacks[u.id] = uc.cost
                end
            end
        end
    end

    -- Use the most valuable target only for calculating the score.

    local bestTargetOfTargetScore = 0
    for k, v in pairs(wouldStopAttacks) do
        if bestTargetOfTargetScore < v then
            bestTargetOfTargetScore = v
        end
    end

    totalScore = totalScore + 1.5 * bestTargetOfTargetScore

    local score = totalScore / maxScore + opportunityCost
    --print("tentacle score is " .. score .. ", totalScore=" .. totalScore)
    return {score = score, introspection = {{key = "totalScore", value = totalScore}}}
end

return Tentacle
