local Wargroove = require "wargroove/wargroove"
local GrooveVerb = require "wargroove/groove_verb"
local Verb = require "wargroove/verb"

local Tornado = GrooveVerb:new()

Tornado.isInPreExecute = false

function Tornado:getMaximumRange(unit, endPos)
    return 6
end


function Tornado:getTargetType()
    if Tornado.isInPreExecute then
        return "empty"
    end

    return "all"
end

function Tornado:canExecuteWithTarget(unit, endPos, targetPos, strParam)
    if not self:canSeeTarget(targetPos) then
        return false
    end
    
    if not Tornado.isInPreExecute then
        if targetPos.x == unit.pos.x and targetPos.y == unit.pos.y then
            return true
        end

        local targetUnit = Wargroove.getUnitAt(targetPos)
        return targetUnit and not targetUnit.unitClass.isStructure and (not targetUnit.unitClass.isCommander or not Wargroove.areEnemies(targetUnit.playerId, unit.playerId)) and targetUnit.canBeAttacked
    else
        local movingUnit = Wargroove.getUnitById(Tornado.movingUnit)
        if targetPos.x == unit.pos.x and targetPos.y == unit.pos.y then
            return Wargroove.canStandAt(movingUnit.unitClassId, targetPos)
        end

        return (Wargroove.getUnitAt(targetPos) == nil) and Wargroove.canStandAt(movingUnit.unitClassId, targetPos) and (targetPos.x ~= endPos.x or targetPos.y ~= endPos.y)
    end
end

function Tornado:preExecute(unit, targetPos, strParam, endPos)
    if targetPos.x == unit.pos.x and targetPos.y == unit.pos.y then
        Tornado.movingUnit = unit.id
    else
        Tornado.movingUnit = Wargroove.getUnitAt(targetPos).id
    end

    Tornado.isInPreExecute = true

    Wargroove.selectTarget()

    while Wargroove.waitingForSelectedTarget() do
        coroutine.yield()
    end

    local destination = Wargroove.getSelectedTarget()

    if (destination == nil) then
        Tornado.isInPreExecute = false
        return false, ""
    end
    
    Wargroove.setSelectedTarget(targetPos)

    Tornado.isInPreExecute = false

    return true, Tornado.movingUnit .. ";" .. destination.x .. "," .. destination.y
end

function Tornado:parseTargets(strParam)
    local targetStrs={}
    local i = 1
    for targetStr in string.gmatch(strParam, "([^"..";".."]+)") do
        targetStrs[i] = targetStr
        i = i + 1
    end

    local targetUnitId = tonumber(targetStrs[1])

    local targetPosStr = targetStrs[2]
    local vals = {}
    for val in targetPosStr.gmatch(targetPosStr, "([^"..",".."]+)") do
        vals[#vals+1] = val
    end
    targetTeleportPosition = { x = tonumber(vals[1]), y = tonumber(vals[2])}

    return targetUnitId, targetTeleportPosition
end

function Tornado:execute(unit, targetPos, strParam, path)
    if strParam == "" then
        print("Tornado:execute was not given any target positions.")
        return
    end

    Wargroove.setIsUsingGroove(unit.id, true)
    Wargroove.updateUnit(unit)

    Wargroove.playPositionlessSound("battleStart")
    Wargroove.playGrooveCutscene(unit.id)

    local targetUnitId, teleportPosition = Tornado:parseTargets(strParam)    

    Wargroove.playUnitAnimation(unit.id, "groove")
    Wargroove.playMapSound("tenri/tenriGroove", unit.pos)
    Wargroove.waitTime(1.2)
    Wargroove.playGrooveEffect()
    local targetUnit = Wargroove.getUnitById(targetUnitId)

    local tornadoFrontEntityId = Wargroove.spawnUnitEffect(targetUnit.id, "units/commanders/tenri/tornado_front", "idle", "spawn", true)
    local tornadoBackEntityId = Wargroove.spawnUnitEffect(targetUnit.id, "units/commanders/tenri/tornado_back", "idle", "spawn", false)
    Wargroove.playMapSound("tenri/tenriGrooveTornado", targetUnit.pos)

    Wargroove.waitTime(0.4)

    Wargroove.moveUnitToOverride(targetUnit.id, targetUnit.pos, 0, -0.5, 3)

    while (Wargroove.isLuaMoving(targetUnit.id)) do
        coroutine.yield()
    end

    Wargroove.moveUnitToOverride(targetUnit.id, teleportPosition, 0, -0.5, 5)

    while (Wargroove.isLuaMoving(targetUnit.id)) do
        coroutine.yield()
    end
    
    Wargroove.moveUnitToOverride(targetUnit.id, teleportPosition, 0, 0, 3)

    while (Wargroove.isLuaMoving(targetUnit.id)) do
        coroutine.yield()
    end

    targetUnit.pos = { x = teleportPosition.x, y = teleportPosition.y }
    Wargroove.updateUnit(targetUnit)

    Wargroove.deleteUnitEffect(tornadoFrontEntityId, "death")
    Wargroove.deleteUnitEffect(tornadoBackEntityId, "death")

    Wargroove.waitTime(0.5)
end

function Tornado:onPostUpdateUnit(unit, targetPos, strParam, path)
    GrooveVerb.onPostUpdateUnit(self, unit, targetPos, strParam, path)

    if strParam == "" then
        print("Tornado:onPostUpdateUnit was not given any target positions.")
        return
    end

    local targetUnitId, teleportPosition = Tornado:parseTargets(strParam)
    local targetUnit = Wargroove.getUnitById(targetUnitId)

    if targetUnit.id == unit.id then
        unit.pos = teleportPosition
    end
end

function Tornado:generateOrders(unitId, canMove)
    local orders = {}

    local unit = Wargroove.getUnitById(unitId)
    local unitClass = Wargroove.getUnitClass(unit.unitClassId)
    local movePositions = {}
    if canMove then
        movePositions = Wargroove.getTargetsInRange(unit.pos, unitClass.moveRange, "empty")
    end
    table.insert(movePositions, unit.pos)

    local function canTarget(u)
        if Wargroove.hasAIRestriction(u.id, "dont_target_this") then
            return false
        end
        if Wargroove.hasAIRestriction(unit.id, "only_target_commander") and not u.unitClass.isCommander then
            return false
        end
        return true
    end

    local originalPos = unit.pos
    for i, pos in pairs(movePositions) do
        Wargroove.pushUnitPos(unit, pos)
        local teleportPositionsInRange = Wargroove.getTargetsInRange(pos, self:getMaximumRange(unit, pos), "empty")

        local targets = Wargroove.getTargetsInRange(pos, 1, "unit")
        for j, targetPos in pairs(targets) do
            local u = Wargroove.getUnitAt(targetPos)

            if u ~= nil and self:canSeeTarget(targetPos) and canTarget(u) then
                local teleportPositions = {}
                for i, teleportPos in ipairs(teleportPositionsInRange) do
                    if Wargroove.getUnitAt(teleportPos) == nil and Wargroove.canStandAt(u.unitClassId, teleportPos) and (teleportPos.x ~= pos.x or teleportPos.y ~= pos.y) then
                        table.insert(teleportPositions, teleportPos)
                    end
                end

                local uc = Wargroove.getUnitClass(u.unitClassId)
                if not uc.isStructure and (not uc.isCommander or not Wargroove.areEnemies(u.playerId, unit.playerId)) then
                    for k, teleportPosition in pairs(teleportPositions) do
                        if (teleportPosition.x ~= pos.x or teleportPosition.y ~= pos.y) and (teleportPosition.x ~= targetPos.x or teleportPosition.y ~= targetPos.y) then
                            local strParam = u.id .. ";" .. teleportPosition.x .. "," .. teleportPosition.y
                            local endPosition = pos
                            local targetPosition = u.pos
                            if u.id == unit.id then
                                endPosition = teleportPosition
                                targetPosition = originalPos
                            end
                            orders[#orders+1] = {targetPosition = targetPosition, strParam = strParam, movePosition = pos, endPosition = endPosition}
                        end
                    end
                end
            end
        end
        Wargroove.popUnitPos()
    end

    return orders
end

function Tornado:getScore(unitId, order)
    local targetUnitId, teleportPosition = Tornado:parseTargets(order.strParam)
    local targetUnit = Wargroove.getUnitById(targetUnitId)    

    local opportunityCost = -1

    --- unit score
    local unitScore = Wargroove.getAIUnitValue(targetUnit.id, targetUnit.pos)
    local newUnitScore = Wargroove.getAIUnitValue(targetUnit.id, teleportPosition)
    local delta = newUnitScore - unitScore

    --- location score
    local startScore = Wargroove.getAILocationScore(targetUnit.unitClassId, targetUnit.pos)
    local endScore = Wargroove.getAILocationScore(targetUnit.unitClassId, teleportPosition)

    local locationGradient = endScore - startScore
    local gradientBonus = 0
    if locationGradient > 0.00001 then
        gradientBonus = 0.25
    end

    local score = (delta + gradientBonus) + opportunityCost

    return {score = score, introspection = {
        {key = "delta", value = delta},
        {key = "gradientBonus", value = gradientBonus},
        {key = "manhattanDistance", value = manhattanDistance},
        {key = "opportunityCost", value = opportunityCost}}}
end

return Tornado
