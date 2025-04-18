local Wargroove = require "wargroove/wargroove"
local GrooveVerb = require "wargroove/groove_verb"

local DroneBombs = GrooveVerb:new()

local numberOfDrones = {2, 2}
local dropRange = {1, 1}
local droneType = { "drone", "drone_strong"}

function DroneBombs:getMaximumRange(unit, endPos)
    local tier = self:getCurrentGrooveTier(unit)
    return dropRange[tier]
end


function DroneBombs:getTargetType()
    return "all"
end

DroneBombs.selectedLocations = {}

function DroneBombs:selectedLocationsContains(pos)
    for i, selectedPos in pairs(DroneBombs.selectedLocations) do
        if selectedPos.x == pos.x and selectedPos.y == pos.y then
           return true
        end
     end
     return false
end

function DroneBombs:canExecuteWithTarget(unit, endPos, targetPos, strParam)
    if not self:canSeeTarget(targetPos) then
        return false
    end

    local u = Wargroove.getUnitAt(targetPos)
    return (not DroneBombs.selectedLocationsContains(self, targetPos)) 
        and (endPos.x ~= targetPos.x or endPos.y ~= targetPos.y) 
        and (u == nil or unit.id == u.id)        
        and Wargroove.canStandAt("drone", targetPos)
end

function DroneBombs:preExecute(unit, targetPos, strParam, endPos)
    local tier = self:getCurrentGrooveTier(unit)

    DroneBombs.selectedLocations = {}

    Wargroove.selectTarget()

    while Wargroove.waitingForSelectedTarget() do
        coroutine.yield()
    end

    local targetOne = Wargroove.getSelectedTarget()
    local targetTwo = { x=-1, y=-1 }

    if (targetOne == nil) then
        return false, ""
    end

    Wargroove.displayTarget(targetOne)
    DroneBombs.selectedLocations[0] = targetOne

    if numberOfDrones[tier] > 1 then
        Wargroove.selectTarget()

        while Wargroove.waitingForSelectedTarget() do
            coroutine.yield()
        end

        targetTwo = Wargroove.getSelectedTarget()

        if (targetTwo == nil) then
            DroneBombs.selectedLocations = {}
            Wargroove.clearDisplayTargets()
            return false, ""
        end

        Wargroove.displayTarget(targetTwo)
    end

    Wargroove.waitFrame()
    DroneBombs.selectedLocations = {}
    Wargroove.clearDisplayTargets()

    return true, targetOne.x .. "," .. targetOne.y .. ";" .. targetTwo.x .. "," .. targetTwo.y
end

function DroneBombs:execute(unit, targetPos, strParam, path)
    local tier = self:getCurrentGrooveTier(unit)
    if strParam == "" then
        print("DroneBomb:execute was not given any target positions.")
        return
    end

    Wargroove.setIsUsingGroove(unit.id, true)
    Wargroove.updateUnit(unit)

    if tier == 2 then
        Wargroove.playGrooveChargeUp(unit.pos, unit.playerId)
    end

    Wargroove.playPositionlessSound("battleStart")
    Wargroove.playGrooveCutscene(unit.id, tier)

    local targetPositions = self:parseTargets(strParam)

    Wargroove.playUnitAnimation(unit.id, "groove")
    Wargroove.playMapSound("koji/kojiGroove", unit.pos)
    Wargroove.waitTime(1.1)    
    Wargroove.playMapSound("koji/kojiDroneSpawn", unit.pos)

    for i, dronePos in pairs(targetPositions) do
        if dronePos.x == -1 then
            goto endOfLoop
        end

        local spawnAnimation = ""
        if dronePos.x == unit.pos.x and dronePos.y > unit.pos.y then
            spawnAnimation = "spawn_down"
        elseif dronePos.x == unit.pos.x and dronePos.y < unit.pos.y then
            spawnAnimation = "spawn_up"
        elseif dronePos.y == unit.pos.y and dronePos.x > unit.pos.x then
            spawnAnimation = "spawn_right"
        elseif dronePos.y == unit.pos.y and dronePos.x < unit.pos.x then
            spawnAnimation = "spawn_left"
        end
        Wargroove.spawnUnit(unit.playerId, dronePos, droneType[tier], false, spawnAnimation)

        ::endOfLoop::
    end
    Wargroove.waitTime(0.3)

    Wargroove.playGrooveEffect()

    Wargroove.waitTime(1.6)

    Wargroove.waitTime(0.5)

    Wargroove.logAnalyticsAction("UnitAbility", unit.playerId, "groove", unit.unitClassId)
end

function DroneBombs:generateOrders(unitId, canMove)
    local orders = {}

    local unit = Wargroove.getUnitById(unitId)
    local unitClass = Wargroove.getUnitClass(unit.unitClassId)
    local movePositions = {}
    if canMove then
        movePositions = Wargroove.getTargetsInRange(unit.pos, unitClass.moveRange, "empty")
    end
    table.insert(movePositions, unit.pos)

    for i, pos in pairs(movePositions) do
        local targets = Wargroove.getTargetsInRangeAfterMove(unit, pos, pos, 1, "empty")
        if #targets >= 2 then
            for j, targetOne in pairs(targets) do
                if self:canSeeTarget(targetOne) then
                    for k=(j+1),(#targets) do
                        local targetTwo = targets[k]
                        if self:canSeeTarget(targetTwo) then
                            strParam = targetOne.x .. "," .. targetOne.y .. ";" .. targetTwo.x .. "," .. targetTwo.y
                            orders[#orders+1] = {targetPosition = targetOne, strParam = strParam, movePosition = pos, endPosition = pos}
                        end
                    end
                end
            end
        end
    end

    return orders
end

function DroneBombs:getScore(unitId, order)
    local unit = Wargroove.getUnitById(unitId)
    local targets = self:parseTargets(order.strParam)

    local opportunityCost = -1
    local totalScore = 0

    for i, pos in ipairs(targets) do
        totalScore = totalScore + Wargroove.getAIUnitRecruitScore("drone", pos)
    end
    
    return {score = totalScore + opportunityCost, introspection = {
        {key = "totalScore", value = totalScore},
        {key = "opportunityCost", value = opportunityCost}}}
end

return DroneBombs
