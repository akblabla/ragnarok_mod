local Wargroove = require "wargroove/wargroove"
local GrooveVerb = require "wargroove/groove_verb"

local VineWall = GrooveVerb:new()


function VineWall:getMaximumRange(unit, endPos)
    return 5
end


function VineWall:getTargetType()
    return "empty"
end

function VineWall:selectedLocationsContains(pos)
    for i, selectedPos in pairs(VineWall.selectedLocations) do
        if selectedPos.x == pos.x and selectedPos.y == pos.y then
           return true
        end
     end
     return false
end

function VineWall:canExecuteWithTarget(unit, endPos, targetPos, strParam)
    if not self:canSeeTarget(targetPos) then
        return false
    end

    if VineWall:selectedLocationsContains(targetPos) then
        return false
    end

    local unitThere = Wargroove.getUnitAt(targetPos)
    return (unitThere == nil or unitThere == unit) and Wargroove.canStandAt("soldier", targetPos)
end

VineWall.selectedLocations = {}

function VineWall:preExecute(unit, targetPos, strParam, endPos)
    VineWall.selectedLocations = {}

    for i=1,5 do
        Wargroove.selectTarget()

        while Wargroove.waitingForSelectedTarget() do
            coroutine.yield()
        end

        local target = Wargroove.getSelectedTarget()
        if (target == nil) then
            VineWall.selectedLocations = {}
            Wargroove.clearDisplayTargets()
            return false, ""
        end

        Wargroove.displayTarget(target)
        table.insert(VineWall.selectedLocations, target)
    end

    local result = ""
    for i, target in ipairs(VineWall.selectedLocations) do
        result = result .. target.x .. "," .. target.y
        if i ~= #VineWall.selectedLocations then
            result = result .. ";"
        end
    end

    VineWall.selectedLocations = {}
    Wargroove.clearDisplayTargets()

    return true, result
end

function VineWall:parseTargets(strParam)
    local targetStrs={}
    local i = 1
    for targetStr in string.gmatch(strParam, "([^"..";".."]+)") do
        targetStrs[i] = targetStr
        i = i + 1
    end

    local targets = {}
    i = 1
    for idx, targetStr in pairs(targetStrs) do
        local vals = {}
        local j = 1
        for val in targetStr.gmatch(targetStr, "([^"..",".."]+)") do
            vals[j] = val
            j = j + 1
        end
        targets[i] = { x = tonumber(vals[1]), y = tonumber(vals[2])}
        i = i + 1
    end

    return targets
end

function VineWall:execute(unit, targetPos, strParam, path)
    Wargroove.setIsUsingGroove(unit.id, true)
    Wargroove.updateUnit(unit)

    Wargroove.playPositionlessSound("battleStart")
    Wargroove.playGrooveCutscene(unit.id)

    Wargroove.playUnitAnimation(unit.id, "groove")
    Wargroove.playMapSound("greenfinger/greenfingerGroove", unit.pos)
    Wargroove.waitTime(1.0)

    Wargroove.playGrooveEffect()

    local vinePositions = VineWall:parseTargets(strParam)
    for i, pos in pairs(vinePositions) do
        Wargroove.spawnUnit(unit.playerId, pos, "vine", true, "spawn")
        Wargroove.waitTime(0.1)
    end
    
    Wargroove.waitTime(0.5)
end


function VineWall:generateOrders(unitId, canMove)
    local orders = {}

    local unit = Wargroove.getUnitById(unitId)
    local unitClass = Wargroove.getUnitClass(unit.unitClassId)
    local movePositions = {}
    if canMove then
        movePositions = Wargroove.getTargetsInRange(unit.pos, unitClass.moveRange, "empty")
    end
    table.insert(movePositions, unit.pos)

    local targetScores = {}

    for i, pos in ipairs(movePositions) do
        local targets = Wargroove.getTargetsInRangeAfterMove(unit, pos, pos, self:getMaximumRange(unit, pos), "empty")
        local topTargets = {}
        for j, targetPos in ipairs(targets) do
            if targetPos ~= pos and Wargroove.canStandAt("soldier", targetPos) and self:canSeeTarget(targetPos) then
                local unitScore = VineWall:find(targetScores, targetPos)
                if (unitScore == nil) then
                    unitScore = Wargroove.getAIUnitRecruitScore("vine", targetPos)
                    targetScores[targetPos] = unitScore
                end
                
                if VineWall:count(topTargets) < 5 then
                    topTargets[targetPos] = unitScore
                else
                    local minTarget = VineWall:findMin(topTargets)
                    if unitScore > topTargets[minTarget] then
                        topTargets[minTarget] = nil                    
                        topTargets[targetPos] = unitScore
                    end
                end
            end
        end

        local strParam = ""
        for target, score in pairs(topTargets) do
            strParam = strParam .. target.x .. "," .. target.y
            if i ~= #topTargets then
                strParam = strParam .. ";"
            end
        end

        if (#targets > 0) then
            orders[#orders+1] = {targetPosition = targets[1], strParam = strParam, movePosition = pos, endPosition = pos}
        end
    end

    return orders
end

function VineWall:getScore(unitId, order)
    local targetPos = order.targetPosition

    local vinePositions = VineWall:parseTargets(order.strParam)
    local totalScore = 0
    for i, pos in pairs(vinePositions) do
        totalScore = totalScore + Wargroove.getAIUnitRecruitScore("vine", pos)
    end

    return {score = totalScore * 10.0, introspection = {}}
end

function VineWall:find(table, key)
    for key, value in pairs(table) do
        if key == item then
            return value
        end
    end
    return nil;
end

function VineWall:findMin(targetsTable)
    local minScore = nil
    local minTarget = nil
    for target, score in pairs(targetsTable) do
        if minScore == nil or minScore > score then
            minScore = score
            minTarget = target
        end
    end
    return minTarget
end

function VineWall:count(table)
    local length = 0
    for i, j in pairs(table) do
        length = length + 1
    end
    return length
end

return VineWall
