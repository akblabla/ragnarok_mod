local Wargroove = require "wargroove/wargroove"
local GrooveVerb = require "wargroove/groove_verb"
local Combat = require "wargroove/combat"

local VineWall = GrooveVerb:new()

local spawnRange = { 5, 8 }
local spawnNumber = { 5, 5 }
local spawnId = { "vine", "thorny_vine" }
local thornyDamage = 0.25

function VineWall:getMaximumRange(unit, endPos)
    local tier = self:getCurrentGrooveTier(unit)
    return spawnRange[tier]
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
    local tier = self:getCurrentGrooveTier(unit)
    VineWall.selectedLocations = {}

    for i=1,spawnNumber[tier] do
        Wargroove.selectTarget()

        while Wargroove.waitingForSelectedTarget() do
            coroutine.yield()
        end

        local target = Wargroove.getSelectedTarget()
        if (target == nil) then
            VineWall.selectedLocations = {}
            Wargroove.clearDisplayTargets()
            Wargroove.waitFrame()
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
    Wargroove.waitFrame()
    Wargroove.clearDisplayTargets()
    Wargroove.waitFrame()

    return true, result
end

function VineWall:execute(unit, targetPos, strParam, path)
    Wargroove.clearDisplayTargets()
    
    local tier = self:getCurrentGrooveTier(unit)

    Wargroove.setIsUsingGroove(unit.id, true)
    Wargroove.updateUnit(unit)

    if tier == 2 then
        Wargroove.playGrooveChargeUp(unit.pos, unit.playerId)
    end

    Wargroove.playPositionlessSound("battleStart")
    Wargroove.playGrooveCutscene(unit.id)

    Wargroove.playUnitAnimation(unit.id, "groove")
    Wargroove.playMapSound("greenfinger/greenfingerGroove", unit.pos)
    Wargroove.waitTime(1.0)

    Wargroove.playGrooveEffect()

    local vinePositions = self:parseTargets(strParam)
    for i, pos in pairs(vinePositions) do
        local startingState = {}
        local commanderId = {key="commanderId", value=unit.id}
        table.insert(startingState, commanderId)

        Wargroove.spawnUnit(unit.playerId, pos, spawnId[tier], true, "spawn", startingState)
        Wargroove.waitTime(0.1)

        -- tier 2 groove does additional damge on spawn
        if spawnId[tier] == "thorny_vine" then
            local enemyPositions = Wargroove.getTargetsInRange(pos, 1, "unit")
            
            for _, enemyPos in pairs(enemyPositions) do
                local enemy = Wargroove.getUnitAt(enemyPos)

                if enemy and Wargroove.areEnemies(enemy.playerId, unit.playerId) and enemy.canBeAttacked and enemy.unitClass.isAttackable and not enemy.unitClass.isStructure then
                    -- Potentially change this to commander weapon damage
                    local damage = Combat:getGrooveAttackerDamage(unit, enemy, "average", unit.pos, enemyPos, path, nil) * thornyDamage
                    enemy:setHealth(enemy.health - damage, unit.id)
                    Wargroove.updateUnit(enemy)
                    Wargroove.playUnitAnimation(enemy.id, "hit")
                end
            end
        end
    end
    
    Wargroove.waitTime(0.5)

    Wargroove.logAnalyticsAction("UnitAbility", unit.playerId, "groove", unit.unitClassId)
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

    local vinePositions = self:parseTargets(order.strParam)
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
