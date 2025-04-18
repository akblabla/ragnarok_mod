local Wargroove = require "wargroove/wargroove"
local GrooveVerb = require "wargroove/groove_verb"
local Verb = require "wargroove/verb"
local Combat = require "wargroove/combat"

local Dash = GrooveVerb:new()

Dash.isInPreExecute = false
Dash.jumpedUnits = {}
Dash.lastLocation = {}
Dash.endFacing = -1

local startingDamage = 0.5

function Dash:getMaximumRange(unit, endPos)
    return 9999
end

function Dash:getTargetType()
    return "empty"
end

function Dash:canExecuteAt(unit, endPos)
    if not Verb.canExecuteAt(self, unit, endPos) then
        return false
    end
    
    local targets = self:getDashTargets(unit, endPos, {}, false)
    return #targets > 0
end

function Dash:canExecuteWithTarget(unit, endPos, targetPos, strParam)
    if not self:canSeeTarget(targetPos) then
        return false
    end

    local uc = Wargroove.getUnitClass("soldier")
    local u = Wargroove.getUnitAt(targetPos)
    if (u ~= nil and unit.id ~= u.id) or not Wargroove.canStandAt("soldier", targetPos) then     
        print("Checked position for soldier and found false.")   
        return false
    end

    if not Dash.isInPreExecute then
        print("not in pre execute")
        return true
    end

    local targets = self:getTargets(unit, Dash.lastLocation, false)
    for i, target in ipairs(targets) do
        if target.x == targetPos.x and target.y == targetPos.y then
            return true
        end
    end

    if targetPos.x == Dash.lastLocation.x and targetPos.y == Dash.lastLocation.y then
        return true
    end

    return false
end

function Dash:getHitPositions(unitPos, targetPos)
    local xChange = targetPos.x - unitPos.x
    local yChange = targetPos.y - unitPos.y
    local positions = {}
    if xChange ~= 0 then
        local min = math.min(targetPos.x, unitPos.x)
        local max = math.max(targetPos.x, unitPos.x)
        for i=min,max do
            if self:canSeeTarget({x = i, y = unitPos.y}) then
                positions[#positions+1] = {x = i, y = unitPos.y}
            end
        end
    end
    if yChange ~= 0 then
        local min = math.min(targetPos.y, unitPos.y)
        local max = math.max(targetPos.y, unitPos.y)
        for i=min,max do
            if self:canSeeTarget({x = unitPos.x, y = i}) then
                positions[#positions+1] = {x = unitPos.x, y = i}
            end
        end
    end
    return positions
end

function Dash:unitCanBeDashed(dasher, target, jumpedUnits)
    for index, value in ipairs(jumpedUnits) do
        if value == target.id then
            return false
        end
    end

    return true
end

function Dash:getTargetsInDirection(unit, startingPos, jumpedUnits, direction, ai)
    local targetPos = nil
    local foundNonDashableSpace = false
    local foundOneUnit = false
    local checkingPos = startingPos

    local uc = Wargroove.getUnitClass("soldier")
    while not foundNonDashableSpace do
        checkingPos = {x = checkingPos.x + direction.x, y = checkingPos.y + direction.y}

        if not self:canSeeTarget(checkingPos) then
            return nil
        end

        local u = Wargroove.getUnitAt(checkingPos)
        if u == nil then
            if (Wargroove.canStandAt("soldier", checkingPos)) then
                targetPos = checkingPos
            else
                return nil
            end
            foundNonDashableSpace = true
        elseif ai and Wargroove.hasAIRestriction(u.id, "dont_target_this") then
            foundNonDashableSpace = true
        elseif u.id == unit.id then
            targetPos = checkingPos
            foundNonDashableSpace = true
        elseif not self:unitCanBeDashed(unit, u, jumpedUnits) then
            foundNonDashableSpace = true
        else
            foundOneUnit = true
        end
    end

    if not foundOneUnit then
        return nil
    end

    return targetPos
end

function Dash:getTargets(unit, endPos, strParam, ai)
    local processed = {}
    if Dash.isInPreExecute then
        local targets = self:getDashTargets(unit, Dash.lastLocation, Dash.jumpedUnits, ai)
        for i, target in ipairs(targets) do
            local u = {pos = target, from = { Dash.lastLocation }}
            table.insert(processed, u.pos)
        end
        if Dash.lastLocation.x ~= endPos.x or Dash.lastLocation.y ~= endPos.y then
            table.insert(processed, Dash.lastLocation)
        end
    else
        table.insert(processed, endPos)        
    end
    return processed
end

function Dash:getDashTargets(unit, startingPos, jumpedUnits, ai)
    local targets = {}
    local leftTargets = self:getTargetsInDirection(unit, startingPos, jumpedUnits, {x = 1, y = 0}, ai)
    local rightTargets = self:getTargetsInDirection(unit, startingPos, jumpedUnits, {x = -1, y = 0}, ai)
    local upTargets = self:getTargetsInDirection(unit, startingPos, jumpedUnits, {x = 0, y = 1}, ai)
    local downTargets = self:getTargetsInDirection(unit, startingPos, jumpedUnits, {x = 0, y = -1}, ai)
    if leftTargets ~= nil then
        targets[#targets+1] = leftTargets
    end
    if rightTargets ~= nil then
        targets[#targets+1] = rightTargets
    end
    if upTargets ~= nil then        
        targets[#targets+1] = upTargets
    end
    if downTargets ~= nil then
        targets[#targets+1] = downTargets
    end
    return targets
end

function Dash:buildTargetString(targets)
    local result = ""
    for i, target in ipairs(targets) do
        result = result .. target.x .. "," .. target.y
        if i ~= #targets then
            result = result .. ";"
        end
    end
    return result
end

function Dash:preExecute(unit, targetPos, strParam, endPos)
    Dash.isInPreExecute = true
    Dash.jumpedUnits= {}
    Dash.lastLocation = endPos

    local selectedTargets = {}

    while true do
        local targets = self:getDashTargets(unit, Dash.lastLocation, Dash.jumpedUnits, false)
        if #targets == 0 then
            Wargroove.clearDisplayTargets()
            Dash.isInPreExecute = false
            return true, self:buildTargetString(selectedTargets)
        end

        Wargroove.selectTarget()

        while Wargroove.waitingForSelectedTarget() do
            coroutine.yield()
        end

        local target = Wargroove.getSelectedTarget();

        if target == nil then
            Wargroove.clearDisplayTargets()
            Dash.isInPreExecute = false
            return false, ""
        end

        if target.x == Dash.lastLocation.x and target.y == Dash.lastLocation.y then
            Wargroove.clearDisplayTargets()
            Dash.isInPreExecute = false
            return true, self:buildTargetString(selectedTargets)
        end

        local hitPositions = self:getHitPositions(Dash.lastLocation, target)

        for i, pos in ipairs(hitPositions) do
            local hitUnit = Wargroove.getUnitAt(pos)
            if hitUnit ~= nil then
                Wargroove.displayTarget(pos)
                table.insert(Dash.jumpedUnits, hitUnit.id)
            end
        end        

        table.insert(selectedTargets, target)
        Dash.lastLocation = target
    end

    --- should never get here
    Wargroove.clearDisplayTargets()
    Dash.isInPreExecute = false
    return false, ""
end

function Dash:parseTargets(strParam)
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

function Dash:getFacing(unit, target)
    if (unit.pos.x < target.x) then
        return "right"
    elseif (unit.pos.x > target.x) then
        return "left"
    else
        return ""
    end
end

function Dash:execute(unit, targetPos, strParam, path)
    Wargroove.setIsUsingGroove(unit.id, true)
    Wargroove.updateUnit(unit)

    Wargroove.playPositionlessSound("battleStart")
    Wargroove.playGrooveCutscene(unit.id)

    local targets = self:parseTargets(strParam)

    local startFacing = self:getFacing(unit, targets[1])
    if (startFacing ~= "") then
        Wargroove.setFacingOverride(unit.id, startFacing)
    end

    Wargroove.playUnitAnimation(unit.id, "groove")
    Wargroove.playMapSound("ryota/ryotaGroove", unit.pos)
    Wargroove.waitTime(0.85)

    local currentDamage = startingDamage

    local lastPosition = unit.pos
    for i, target in ipairs(targets) do
        
        local hitPositions = self:getHitPositions(lastPosition, target)
        local facingOverride = self:getFacing(unit, target)
        local newAnimation = ""
        if (unit.pos.x < target.x) then
            newAnimation = "dash"
        elseif (unit.pos.x > target.x) then
            newAnimation = "dash"
        elseif (unit.pos.y > target.y) then
            newAnimation = "dash_up"
        else
            newAnimation = "dash_down"
        end

        local prefix = "dash_"
        local direction = ""
        if (unit.pos.x ~= target.x) then
            direction = "h"
        else
            direction = "v"
        end
        
        if (facingOverride ~= "") then
            Wargroove.setFacingOverride(unit.id, facingOverride)
        end

        if (i == #targets) then
            Wargroove.playUnitAnimation(unit.id, "groove_end")
        else
            Wargroove.playUnitAnimation(unit.id, newAnimation)
        end

        unit.pos = { x = target.x, y = target.y }        
        Wargroove.updateUnit(unit)

        Wargroove.playGrooveEffect()

        local startPos = nil
        local endPos = nil

        local single = (#hitPositions == 3)
        if single then
            startPos = hitPositions[1]
            endPos = hitPositions[2]    
        elseif not single then
            for i, hitPos in ipairs(hitPositions) do
                local u = Wargroove.getUnitAt(hitPos)
                if u then
                    if (startPos == nil and endPos == nil) then
                        startPos = hitPos
                        endPos = hitPos
                    else
                        if hitPos.x < startPos.x then
                            startPos = hitPos
                        end
                        if hitPos.x > endPos.y then
                            endPos = hitPos
                        end
                        if hitPos.y > startPos.y then
                            startPos = hitPos
                        end
                        if hitPos.y < endPos.y then
                            endPos = hitPos
                        end
                    end
                end
            end
        end

        Wargroove.playMapSound("ryota/ryotaGrooveDash", unit.pos)
        
        for i, hitPos in ipairs(hitPositions) do
            local u = Wargroove.getUnitAt(hitPos)
            if u then
                if Wargroove.areEnemies(u.playerId, unit.playerId) then
                  local damage = Combat:getGrooveAttackerDamage(unit, u, "random", unit.pos, hitPos, path, nil) * currentDamage
                  u:setHealth(u.health - damage, unit.id)
                  Wargroove.updateUnit(u)
                  Wargroove.playUnitAnimation(u.id, "hit")
                end

                if (single) then
                    Wargroove.spawnMapAnimation(u.pos, 0, "fx/groove/dash", prefix .. direction .. "_single", "over_units", {x = 12, y = 8})
                elseif u.pos.x == startPos.x and u.pos.y == startPos.y then
                    Wargroove.spawnMapAnimation(u.pos, 0, "fx/groove/dash", prefix .. direction .. "_start", "over_units", {x = 12, y = 8})
                elseif u.pos.x == endPos.x and u.pos.y == endPos.y then
                    Wargroove.spawnMapAnimation(u.pos, 0, "fx/groove/dash", prefix .. direction .. "_end", "over_units", {x = 12, y = 8})
                else
                    Wargroove.spawnMapAnimation(u.pos, 0, "fx/groove/dash", prefix .. direction .. "_mid", "over_units", {x = 12, y = 8})
                end
            end
        end
        
        Wargroove.waitTime(0.25)

        if (i == #targets - 1) then
            Wargroove.playMapSound("ryota/ryotaGrooveDashEnd", unit.pos)
        end

        if (i == #targets) then
            Wargroove.unsetFacingOverride(unit.id)
            if (lastPosition.x ~= target.x) then
                Dash.endFacing = (lastPosition.x < target.x and 1 or 3)
                unit.pos.facing = Dash.endFacing
                Wargroove.updateUnit(unit)
            end
        end
        lastPosition = target

        currentDamage = currentDamage + 0.05
    end

    Wargroove.waitTime(0.5)
end

function Dash:onPostUpdateUnit(unit, targetPos, strParam, path)
    GrooveVerb.onPostUpdateUnit(self, unit, targetPos, strParam, path)
    unit.pos = targetPos
    if (Dash.endFacing >= 0) then
        unit.pos.facing = Dash.endFacing
    end
end

function Dash:getUnitsFromHitPositions(hitPositions)
    local jumpedUnits = {}
    for i, hitPos in pairs(hitPositions) do
        local u = Wargroove.getUnitAt(hitPos)
        if u ~= nil then
            table.insert(jumpedUnits, u.id)
        end
    end
    return jumpedUnits
end

function Dash:generateOrders(unitId, canMove)
    local unit = Wargroove.getUnitById(unitId)
    local unitClass = Wargroove.getUnitClass(unit.unitClassId)
    local movePositions = {}
    if canMove then
        movePositions = Wargroove.getTargetsInRange(unit.pos, unitClass.moveRange, "empty")
    end
    table.insert(movePositions, unit.pos)

    local dashes = {}
    local unfinishedDashes = {}

    for i, startPos in pairs(movePositions) do
        local targets = self:getDashTargets(unit, startPos, {}, true)
        for j, target in pairs(targets) do
            local pathStart = {}
            table.insert(pathStart, target)
            
            local hitPositions = self:getHitPositions(startPos, target)
            local jumpedUnits = self:getUnitsFromHitPositions(hitPositions)
            local dash = {startPos = startPos, path = pathStart, jumpedUnits = jumpedUnits}

            table.insert(unfinishedDashes, dash)
            table.insert(dashes, dash)
        end
    end

    while #unfinishedDashes > 0 do
        local dash = table.remove(unfinishedDashes, 1)
        local path = dash.path        
        local targets = self:getDashTargets(unit, path[#path], dash.jumpedUnits, true)
        for i, target in pairs(targets) do
            local newDash = {}
            local newPath = {}
            for j, pos in pairs(path) do
                table.insert(newPath, pos)
            end
            
            table.insert(newPath, target)

            local hitPositions = self:getHitPositions(path[#path], target)
            local jumpedUnits = self:getUnitsFromHitPositions(hitPositions)

            newDash.startPos = dash.startPos
            newDash.path = newPath
            newDash.jumpedUnits = jumpedUnits
            for j, u in pairs(dash.jumpedUnits) do
                table.insert(newDash.jumpedUnits, u)
            end

            table.insert(unfinishedDashes, newDash)
            table.insert(dashes, newDash)
        end
    end

    local orders = {}

    for i, dash in pairs(dashes) do
        local strParam = self:buildTargetString(dash.path)
        table.insert(orders, {targetPosition = dash.path[#(dash.path)], strParam = strParam, movePosition = dash.startPos, endPosition = dash.path[#(dash.path)]})
    end

    return orders
end

function Dash:getScore(unitId, order)
    local unit = Wargroove.getUnitById(unitId)
    local targets = self:parseTargets(order.strParam)

    local opportunityCost = -1
    local effectivenessScore = 0.0
    local totalValue = 0.0

    local numCommandersHit = 0
    local currentDamage = startingDamage
    local lastPos = order.movePosition
    for i, target in ipairs(targets) do
        local hitPositions = self:getHitPositions(lastPos, target)
        for j, hitId in pairs(self:getUnitsFromHitPositions(hitPositions)) do
            local u = Wargroove.getUnitById(hitId)
            if u ~= nil and Wargroove.areEnemies(u.playerId, unit.playerId) then
                local damage = Combat:getGrooveAttackerDamage(unit, u, "aiSimulation", unit.pos, u.pos, path, nil) * currentDamage
                local newHealth = math.max(0, u.health - damage)
                local theirValue = Wargroove.getAIUnitValue(u.id, target)
                local theirDelta = theirValue - Wargroove.getAIUnitValueWithHealth(u.id, target, newHealth)
                effectivenessScore = effectivenessScore + theirDelta
                totalValue = totalValue + theirValue
                if u.unitClass.isCommander then
                    numCommandersHit = numCommandersHit + 1
                end
            end
        end
        lastPos = target 
        currentDamage = currentDamage + 0.05
    end

    local locationGradient = 0.0
    if (Wargroove.getAICanLookAhead(unitId)) then
        locationGradient = Wargroove.getAILocationScore(unit.unitClassId, order.endPosition) - Wargroove.getAILocationScore(unit.unitClassId, unit.pos)
    end
    local gradientBonus = 0.0
    if (locationGradient > 0.0001) then
        gradientBonus = 0.25
    end

    local bravery = Wargroove.getAIBraveryBonus()
    local attackBias = Wargroove.getAIAttackBias()

    local score = (effectivenessScore + gradientBonus + bravery) * attackBias + opportunityCost
    if Wargroove.hasAIRestriction(unit.id, "only_target_commander") and numCommandersHit == 0 then
        score = 0.0
    end
    local introspection = {
        {key = "effectivenessScore", value = effectivenessScore},
        {key = "totalValue", value = totalValue},
        {key = "bravery", value = bravery},
        {key = "attackBias", value = attackBias},
        {key = "locationGradient", value = locationGradient},
        {key = "gradientBonus", value = gradientBonus},
        {key = "opportunityCost", value = opportunityCost},
        {key = "numCommandersHit", value = numCommandersHit}}
        
    return {score = score, introspection = introspection}
end

return Dash
