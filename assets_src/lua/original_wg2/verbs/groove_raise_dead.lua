local Wargroove = require "wargroove/wargroove"
local GrooveVerb = require "wargroove/groove_verb"

local RaiseDead = GrooveVerb:new()

local numberOfSkeletons = { 1, 2 }

local unitSpawnIds = { "felheim:soldier", "felheim:soldier" }
local unitRecruitIds = { "soldier", "soldier" }
local skeletonBoostIds = { "", "skeleton_boost_high" }

function RaiseDead:getMaximumRange(unit, endPos)
    return 1
end


function RaiseDead:getTargetType()
    return "empty"
end


function RaiseDead:canExecuteWithTarget(unit, endPos, targetPos, strParam)
    if not self:canSeeTarget(targetPos) then
        return false
    end

    local unitThere = Wargroove.getUnitAt(targetPos)
    return (unitThere == nil or unitThere == unit) and Wargroove.canStandAt("soldier", targetPos)
end


function RaiseDead:preExecute(unit, targetPos, strParam, endPos)
    local tier = self:getCurrentGrooveTier(unit)
    local selectedLocations = {}
    
    local targetSpace = Wargroove.getTargetsInRange(endPos, 1, "all")
    if not targetSpace then
        return false, ""
    end
    
    local targetSpaceNum = 0
    for i,pos in ipairs(targetSpace) do
        local t = Wargroove.getUnitAt(pos)
        if pos.x ~= endPos.x or pos.y ~= endPos.y then
            if t then
                if t.id == unit.id then
                    targetSpaceNum = targetSpaceNum + 1
                end
            elseif Wargroove.canStandAt("soldier", pos) then
                targetSpaceNum = targetSpaceNum + 1
            end
        end
    end
    
    for i=0,numberOfSkeletons[tier]-1 do
        if targetSpaceNum - i <= 0 then
            break
        end

        Wargroove.selectTarget()

        while Wargroove.waitingForSelectedTarget() do
            coroutine.yield()
        end

        local target = Wargroove.getSelectedTarget()
        if (target == nil) then
            selectedLocations = {}
            Wargroove.clearDisplayTargets()
            return false, ""
        end
        
        local ok = false
        for i, pos in ipairs(selectedLocations) do
            if target.x == pos.x and target.y == pos.y then
                ok = true
            end
        end
        if ok == true then
            break
        end

        Wargroove.displayTarget(target)
        table.insert(selectedLocations, target)
    end

    local result = ""
    for i, target in ipairs(selectedLocations) do
        result = result .. target.x .. "," .. target.y
        if i ~= #selectedLocations then
            result = result .. ";"
        end
    end

    Wargroove.waitFrame()

    Wargroove.clearDisplayTargets()

    return true, result
end


function RaiseDead:execute(unit, targetPos, strParam, path)
    local tier = self:getCurrentGrooveTier(unit)

    Wargroove.setIsUsingGroove(unit.id, true)
    Wargroove.updateUnit(unit)

    if tier == 2 then
        Wargroove.playGrooveChargeUp(unit.pos, unit.playerId)
    end

    Wargroove.playPositionlessSound("battleStart")
    Wargroove.playGrooveCutscene(unit.id, tier)

    if tier == 2 then
        Wargroove.playUnitAnimation(unit.id, "groove2")
    else
        Wargroove.playUnitAnimation(unit.id, "groove")
    end
    Wargroove.playMapSound("valder/valderGroove", unit.pos)
    Wargroove.waitTime(1.7)

    Wargroove.playGrooveEffect()

    local targets = self:parseTargets(strParam)

    for i, pos in pairs(targets) do
        Wargroove.spawnUnit(unit.playerId, pos, unitSpawnIds[tier], false, "summon")
        Wargroove.playMapSound("valder/valderGrooveSummon", pos)
    end
    Wargroove.waitTime(0.7)

    if skeletonBoostIds[tier] ~= "" then
        local units = Wargroove.getAllUnitsOfType(unit.playerId, "soldier")
        for _, skellie in ipairs(units) do
            Wargroove.pushUnitClassModifier(skellie.id, skeletonBoostIds[tier])
            Wargroove.setUnitState(skellie, "boosted", skeletonBoostIds[tier])
            Wargroove.updateUnit(skellie)

            Wargroove.playUnitAnimation(skellie.id, "boost")
        end

        Wargroove.waitFrame();
        Wargroove.updateUnit(unit)
    end

    Wargroove.logAnalyticsAction("UnitAbility", unit.playerId, "groove", unit.unitClassId)
end

function RaiseDead:generateOrders(unitId, canMove)
    local orders = {}

    local unit = Wargroove.getUnitById(unitId)
    local unitClass = Wargroove.getUnitClass(unit.unitClassId)
    local movePositions = {}
    if canMove then
        movePositions = Wargroove.getTargetsInRange(unit.pos, unitClass.moveRange, "empty")
    end
    table.insert(movePositions, unit.pos)

    for i, pos in ipairs(movePositions) do
        local targets = Wargroove.getTargetsInRangeAfterMove(unit, pos, pos, 1, "empty")
        for j, targetPos in ipairs(targets) do
            if targetPos ~= pos and self:canExecuteWithTarget(unit, pos, targetPos, "") then
                table.insert(orders, {
                    targetPosition = targetPos,
                    strParam = targetPos.x .. "," .. targetPos.y,
                    movePosition = pos,
                    endPosition = pos
                })
            end
        end
    end

    return orders
end

function RaiseDead:getScore(unitId, order)
    local unit = Wargroove.getUnitById(unitId)
    local tier = self:getCurrentGrooveTier(unit)

    local score = -1.0

    if self:canExecuteWithTarget(unit, order.endPosition, order.targetPosition, "") then
        -- uses the score calculation for "recruit" (on the C++ side)
        score = Wargroove.getAIUnitRecruitScore(unitRecruitIds[tier], order.targetPosition)
    end

    return {score = score, introspection = {}}
end

return RaiseDead
