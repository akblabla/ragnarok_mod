local Wargroove = require "wargroove/wargroove"
local GrooveVerb = require "wargroove/groove_verb"
local Combat = require "wargroove/combat"

local Spin = GrooveVerb:new()

Spin.isInPreExecute = false
Spin.locationOne = nil

local spinRange = { 1, 2 }
local spinDamage = { 0.35, 0.5 }
local modifiers = { "", "spin_concussion" }

function Spin:getMaximumRange(unit, endPos)
    local tier = self:getCurrentGrooveTier(unit)
    return spinRange[tier]
end

function Spin:getTargetType()
    return "all"
end

local function addArrow(arrows, startingPos, steps)
    local arrowPositions = {}

    for _, pos in ipairs(steps) do
        table.insert(arrowPositions, {x=startingPos.x+pos.x, y=startingPos.y+pos.y})
    end

    table.insert(arrows, { positions=arrowPositions, type="default"})
end

local function limitToNeighbours(positions, endPos)
    for _, pos in ipairs(positions) do
        local deltaX = clamp(pos.x - endPos.x, -1, 1)
        local deltaY = clamp(pos.y - endPos.y, -1, 1)

        pos.x = endPos.x + deltaX
        pos.y = endPos.y + deltaY
    end
end

function Spin:getTargetArrows(unit, targetPos, endPos)
    local results = {}

    if Spin.locationOne == nil then
        return {}
    end

    local positions = {{x=Spin.locationOne.x, y=Spin.locationOne.y}, {x=targetPos.x, y=targetPos.y}}

    limitToNeighbours(positions, endPos)

    local half_spin = positions[1].x ~= positions[2].x and positions[1].y ~= positions[2].y
    local stepOne = { x = endPos.x - positions[1].x, y = endPos.y - positions[1].y }
    local stepTwo = { x = endPos.x - positions[2].x, y = endPos.y - positions[2].y }
    local rotate_right = stepOne.y == -stepTwo.x and stepOne.x == stepTwo.y
    
    if half_spin then
        if rotate_right then
            addArrow(results, endPos, { {x=0, y=-1}, {x=1,y=-1}, {x=1,y=0} })
            -- addArrow(results, unit.pos, { {x=1, y=0}, {x=1,y=1}, {x=0,y=1} })
            addArrow(results, endPos, { {x=0, y=1}, {x=-1,y=1}, {x=-1,y=0} })
            -- addArrow(results, unit.pos, { {x=-1, y=0}, {x=-1,y=-1}, {x=0,y=-1} })
        else
            addArrow(results, endPos, { {x=0, y=-1}, {x=-1,y=-1}, {x=-1,y=0} })
            -- addArrow(results, unit.pos, { {x=-1, y=0}, {x=-1,y=1}, {x=0,y=1} })
            addArrow(results, endPos, { {x=0, y=1}, {x=1,y=1}, {x=1,y=0} })
            -- addArrow(results, unit.pos, { {x=1, y=0}, {x=1,y=-1}, {x=0,y=-1} })
        end
    else
        addArrow(results, endPos, { {x=0, y=-1}, {x=1,y=-1}, {x=1,y=0}, {x=1, y=1}, {x=0, y=1} })
    end

    return results
end

function Spin:getSplashTargets(unit, targetPos, endPos)
    local tier = self:getCurrentGrooveTier(unit)

    local targets = Wargroove.getTargetsInRange(targetPos, spinRange[tier], "all")
    return targets
end

function Spin:canExecuteWithTarget(unit, endPos, targetPos, strParam)
    if not self:canSeeTarget(targetPos) then
        return false
    end

    if math.abs(targetPos.x - endPos.x) ~= 0 and math.abs(targetPos.y - endPos.y) ~= 0 then
        return false
    end

    if Spin.isInPreExecute and Spin.locationOne ~= nil then
        if targetPos.x == Spin.locationOne.x and targetPos.y == Spin.locationOne.y then
            return false
        end

        if (targetPos.x == Spin.locationOne.x and math.abs(targetPos.y - Spin.locationOne.y) < 2) or
            (targetPos.y == Spin.locationOne.y and math.abs(targetPos.x - Spin.locationOne.x) < 2)
        then
            return false
        end
    end

    return true
end

function Spin:preExecute(unit, targetPos, strParam, endPos)
    Spin.isInPreExecute = true

    Wargroove.hideMovementArrow()

    Wargroove.selectTarget()
    while Wargroove.waitingForSelectedTarget() do
        coroutine.yield()
    end

    local startingPoint = Wargroove.getSelectedTarget()
    if startingPoint == nil then
        Spin:cleanUpPreExecute()    
        return false, ""
    end
    Spin.locationOne = startingPoint
    Wargroove.displayTarget(startingPoint)
    Wargroove.waitFrame()

    Wargroove.selectTarget()
    while Wargroove.waitingForSelectedTarget() do
        coroutine.yield()
    end

    local endPoint = Wargroove.getSelectedTarget()
    if endPoint == nil then
        Spin:cleanUpPreExecute()    
        return false, ""
    end
    Wargroove.displayTarget(endPoint)

    Wargroove.waitTime(0.5)
    Spin:cleanUpPreExecute()

    return true, Wargroove.positionsToString({ startingPoint, endPoint })
end

function Spin:cleanUpPreExecute()
    Wargroove.showMovementArrow()
    Wargroove.clearDisplayTargets()
    Spin.isInPreExecute = false
    Spin.locationOne = nil
end

local function rotateByRadian(origin, point, radians)
    local relPos = { x=point.x - origin.x, y=point.y - origin.y }

    -- rounding -> +0.5, lua doesn't have a round function 
    local posX = math.floor(((math.cos(radians) * relPos.x) + (-math.sin(radians) * relPos.y)) + 0.5)
    local posY = math.floor(((math.sin(radians) * relPos.x) + (math.cos(radians) * relPos.y)) + 0.5)
        
    local newPos = { x = posX + origin.x, y = posY + origin.y }

    return newPos
end

function Spin:canExecuteAt(unit, endPos)
    local tier = self:getCurrentGrooveTier(unit)
    local targets = Wargroove.getTargetsInRange(endPos, spinRange[tier], "unit")

    local targetIds = { }

    for i, pos in ipairs(targets) do
        local targetUnit = Wargroove.getUnitAt(pos)

        if self:isValidTarget(targetUnit) then
            table.insert(targetIds, Wargroove.getUnitIdAt(pos))
        end
    end

    return #targetIds > 0
end

function Spin:isValidTarget(targetUnit)
    if not targetUnit then
        return false
    end
    return (targetUnit.playerId >= 0) and (targetUnit.unitClass.moveRange > 0) and (targetUnit.canBeAttacked) and (targetUnit.unitClass.isAttackable) and (Wargroove.isValidPushPullTarget(targetUnit, false))
end

function Spin:execute(unit, targetPos, strParam, path)
    local positions = Wargroove.stringToPositions(strParam)
    local tier = self:getCurrentGrooveTier(unit)

    Wargroove.setIsUsingGroove(unit.id, true)
    Wargroove.updateUnit(unit)

    if tier == 2 then
        Wargroove.playGrooveChargeUp(unit.pos, unit.playerId)
    end

    Wargroove.playPositionlessSound("battleStart")
    Wargroove.playGrooveCutscene(unit.id, tier)

    Wargroove.playUnitAnimation(unit.id, "groove")
    Wargroove.waitTime(0.45)
    Wargroove.playMapSound("lytra/lytraGroove", unit.pos)
    Wargroove.waitTime(0.95)

    Wargroove.playGrooveEffect()

    
    local targets = Wargroove.getTargetsInRange(unit.pos, spinRange[tier], "unit")
    
    limitToNeighbours(positions, unit.pos)
    
    -- Half 90 spin if both x and y are different, otherwise 180 spin
    local half_spin = positions[1].x ~= positions[2].x and positions[1].y ~= positions[2].y
    local stepOne = { x = unit.pos.x - positions[1].x, y = unit.pos.y - positions[1].y }
    local stepTwo = { x = unit.pos.x - positions[2].x, y = unit.pos.y - positions[2].y }
    local rotate_right = stepOne.y == -stepTwo.x and stepOne.x == stepTwo.y
    
    local targetIds = { }

    -- Gather potential target list
    for i, pos in ipairs(targets) do
        local targetUnit = Wargroove.getUnitAt(pos)

        if self:isValidTarget(targetUnit) then
            table.insert(targetIds, Wargroove.getUnitIdAt(pos))
        end
    end

    Wargroove.playMapSound("lytra/lytraGrooveSpin", unit.pos)

    -- Calculate rotations
    local lastUnitToMove = nil
    local newPosList = {}
    local rotateStepNumber = 1
    for i, id in ipairs(targetIds) do
        local targetUnit = Wargroove.getUnitById(id)

        if targetUnit then
            local radians = math.pi

            local halfRadian
            if rotate_right then
                halfRadian = math.pi / 2
            else
                halfRadian = -(math.pi / 2)
            end

            local rotateSteps = {}

            if half_spin then
                radians = halfRadian
            else
                local midStep = rotateByRadian(unit.pos, targetUnit.pos, halfRadian)
                table.insert(rotateSteps, midStep)
            end

            local newPos = rotateByRadian(unit.pos, targetUnit.pos, radians)
            table.insert(rotateSteps, newPos)
            table.insert(newPosList, rotateSteps)

            rotateStepNumber = #rotateSteps
            Wargroove.moveUnitToOverride(targetUnit.id, targetUnit.pos, 0, -0.3, 1, "pow3In")

            -- We temporarily move these numbers, the visuals aren't changed by this, just the logic
            Wargroove.pushUnitPos(targetUnit, {x=-99, y=-99})

            lastUnitToMove = targetUnit.id
        end
    end

    -- Wait for initial lift off to finish
    while (Wargroove.isLuaMoving(lastUnitToMove)) do
        coroutine.yield()
    end

    Wargroove.waitTime(0.1)

    -- Spawn map animation
    if tier == 1 then
        if rotate_right then
            Wargroove.spawnMapAnimation(unit.pos, 2, "units/commanders/lytra/lytra_groove_effect", "groove1_CW", "behind_units", { x = 12, y = 12-47 })
        else
            Wargroove.spawnMapAnimation(unit.pos, 2, "units/commanders/lytra/lytra_groove_effect", "groove1_CCW", "behind_units", { x = 12, y = 12-47 })
        end
    else
        if rotate_right then
            Wargroove.spawnMapAnimation(unit.pos, 2, "units/commanders/lytra/lytra_groove_effect_t2_back", "groove2_CW", "behind_units", { x = 12, y = 12-100 })
            Wargroove.spawnMapAnimation(unit.pos, 2, "units/commanders/lytra/lytra_groove_effect_t2_front", "groove2_CW", "behind_units", { x = 12, y = 12-100 })
        else
            Wargroove.spawnMapAnimation(unit.pos, 2, "units/commanders/lytra/lytra_groove_effect_t2_back", "groove2_CCW", "over_units", { x = 12, y = 12-100 })
            Wargroove.spawnMapAnimation(unit.pos, 2, "units/commanders/lytra/lytra_groove_effect_t2_front", "groove2_CCW", "over_units", { x = 12, y = 12-100 })
        end
    end

    Wargroove.waitTime(0.2)

    -- Go through rotation steps (either 1 or 2 if doing full rotation)
    for i = 1, rotateStepNumber do
        for j, id in ipairs(targetIds) do
            Wargroove.moveUnitToOverride(id, newPosList[j][i], 0, -0.3, 10*rotateStepNumber)
            lastUnitToMove = id
        end

        while (Wargroove.isLuaMoving(lastUnitToMove)) do
            coroutine.yield()
        end
    end

    Wargroove.waitTime(0.2)

    -- Drop characters and show dust
    for j, id in ipairs(targetIds) do
        local targetUnit = Wargroove.getUnitById(id)
        local newPos = newPosList[j][rotateStepNumber]
        local unitAtPos = Wargroove.getUnitAt(newPos)
        local dropUnit = Wargroove.canStandAt(targetUnit.unitClassId, newPos) and (unitAtPos == nil)
   
        if dropUnit then
            Wargroove.moveUnitToOverride(id, newPosList[j][rotateStepNumber], 0, 0, 40, "pow3In")
        end
    end

    while (Wargroove.isLuaMoving(lastUnitToMove)) do
        coroutine.yield()
    end

    for j, id in ipairs(targetIds) do
        local targetUnit = Wargroove.getUnitById(id)
        local newPos = newPosList[j][rotateStepNumber]
        local unitAtPos = Wargroove.getUnitAt(newPos)
        local dropUnit = Wargroove.canStandAt(targetUnit.unitClassId, newPos) and (unitAtPos == nil)
   
        if dropUnit then
            Wargroove.spawnMapAnimation(newPosList[j][rotateStepNumber], 0, "fx/mapeditor_unitdrop")
        end
    end

    -- Spin animation finished, deal damage + update actual position
    for i, id in ipairs(targetIds) do
        local targetUnit = Wargroove.getUnitById(id)

        if targetUnit then
            local newPos = newPosList[i][rotateStepNumber]
            local unitAtPos = Wargroove.getUnitAt(newPos)
            if not Wargroove.canStandAt(targetUnit.unitClassId, newPos) or (unitAtPos ~= nil and unitAtPos ~= targetUnit) then
                targetUnit:setHealth(0, unit.id)
                Wargroove.unlockAchievement("complete_spin_dunk")
            end

            targetUnit.pos.x = newPos.x
            targetUnit.pos.y = newPos.y

            if Wargroove.areEnemies(targetUnit.playerId, unit.playerId) then
                local damage = Combat:getGrooveAttackerDamage(unit, targetUnit, "average", unit.pos, targetUnit.pos, path, nil) * spinDamage[tier]
                targetUnit:setHealth(targetUnit.health - damage, unit.id)

                local modifier = modifiers[tier]
                if modifier ~= "" then
                    Wargroove.pushUnitClassModifier(targetUnit.id, modifier)
                    Wargroove.pushBuff(1, targetUnit, unit.playerId, "spin_concussion_spawn", "spin_concussion", "spin_concussion_death")
                end
            end

        end
    end

    Wargroove.popAllUnitPos()

    for i, id in ipairs(targetIds) do
        local targetUnit = Wargroove.getUnitById(id)

        if targetUnit then
            local newPos = newPosList[i][rotateStepNumber]
            
            targetUnit.pos.x = newPos.x
            targetUnit.pos.y = newPos.y

            Wargroove.updateUnit(targetUnit)
        end
    end

    Wargroove.waitTime(0.2)
end

return Spin
