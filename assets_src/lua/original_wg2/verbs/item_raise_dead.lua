local Wargroove = require "wargroove/wargroove"
local Verb = require "wargroove/verb"

local ItemRaiseDead = Verb:new()

local numberOfSkeletons = 1
local cost = 50

function ItemRaiseDead:getMaximumRange(unit, endPos)
    return 1
end


function ItemRaiseDead:getTargetType()
    return "empty"
end


function ItemRaiseDead:canExecuteAnywhere(unit)
    print("Checking!")
    return Wargroove.getMoney(unit.playerId) >= cost
end


function ItemRaiseDead:getCostAt(unit, endPos, targetPos)
    return cost
end


function ItemRaiseDead:canExecuteWithTarget(unit, endPos, targetPos, strParam)
    if not self:canSeeTarget(targetPos) then
        return false
    end

    local unitThere = Wargroove.getUnitAt(targetPos)
    return (unitThere == nil or unitThere == unit) and Wargroove.canStandAt("soldier", targetPos)
end


function ItemRaiseDead:preExecute(unit, targetPos, strParam, endPos)
    
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
    
    for i=0,numberOfSkeletons-1 do
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

function ItemRaiseDead:execute(unit, targetPos, strParam, path)
    Wargroove.changeMoney(unit.playerId, -cost)

    local targets = self:parseTargets(strParam)

    for i, pos in pairs(targets) do
        Wargroove.spawnUnit(unit.playerId, pos, "felheim:soldier", false, "summon")
        Wargroove.playMapSound("valder/valderGrooveSummon", pos)
        Wargroove.waitTime(0.5)
    end
    Wargroove.waitTime(1.0)

end

function ItemRaiseDead:generateOrders(unitId, canMove)
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
        for j, targetPos in pairs(targets) do
            if targetPos ~= pos  and Wargroove.canStandAt("soldier", targetPos) and self:canSeeTarget(targetPos) then
                orders[#orders+1] = {
                    targetPosition = targetPos,
                    strParam = targetPos.x .. "," .. targetPos.y,
                    movePosition = pos,
                    endPosition = pos
                }
            end
        end
    end

    return orders
end

function ItemRaiseDead:getScore(unitId, order)
    local unit = Wargroove.getUnitById(unitId)

    local score = -1.0

    if self:canExecuteWithTarget(unit, order.endPosition, order.targetPosition, "") then
        -- uses the score calculation for "recruit" (on the C++ side)
        score = Wargroove.getAIUnitRecruitScore("soldier", order.targetPosition)
    end

    return {score = score, introspection = {}}
end

return ItemRaiseDead
