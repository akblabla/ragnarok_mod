local Wargroove = require "wargroove/wargroove"
local Verb = require "wargroove/verb"

local OrganAttack = Verb:new()

OrganAttack.previousAction = {}
OrganAttack.turnsSincePush = 0
OrganAttack.initialPushes = {}

local explosionRange = 1
local explosionDamage = 10
local pushDistance = 2
local pushWidth = 6
local pushDamage = 10
local pushCollisionDamage = 20

local smackDamage = 20

local firstWave = { "soldier", "soldier", "dog", "spearman"}
local secondWave = { "spearman", "spearman", "archer", "archer", "mage", "knight" }
local thirdWave = { "soldier", "soldier", "mage", "mage", "knight", "archer", "rifleman" }

local airUnitsToSpawn = { "harpy", "griffin_walking" }
local finalUnitsToSpawn = { "dragon", "giant" }

function sign(x)
    return (x<0 and -1) or 1
end

-- If you update this, also update in death_organ.lua
local function getDirection(unit)
    -- { ["y"] = 13,["x"] = 17,["facing"] = 0,}
    -- { ["y"] = 21,["x"] = 25,["facing"] = 0,}
    -- { ["y"] = 21,["x"] = 9,["facing"] = 0,}
    if unit.pos.y < 18 then
        return "down"
    elseif unit.pos.x > 20 then
        return "right"
    elseif unit.pos.x < 15 then
        return "left"
    end

    return "up"
end

local function spawnUnit(pos, unitType, playerId)
    local existingUnit = Wargroove.getUnitAt(pos)

    if existingUnit then
        return
    end

    Wargroove.spawnPaletteSwappedMapAnimation(pos, 0, "fx/portal_teleport_fx", playerId, "spawn", "sky")
    Wargroove.playMapSound("cutscene/teleportIn", pos)
    Wargroove.waitTime(0.2)
    Wargroove.spawnUnit(playerId, pos, unitType, true)
end

local function playAttackSequence(unit, facing)
    Wargroove.trackCameraTo(unit.pos)

    Wargroove.playMapSound("organAttackMap", unit.pos)
    Wargroove.playUnitAnimation(unit.id, "attack", "attack_idle")
    Wargroove.waitTime(1.1)

    if facing == "left" or facing == "right" then
        if facing == "left" then
            Wargroove.spawnMapAnimation(unit.pos, 0, "units/commanders/organ/organ_muzzle", "idle", "sky", {x = 12, y = 12}, "right")
        else
            Wargroove.spawnMapAnimation(unit.pos, 0, "units/commanders/organ/organ_muzzle", "idle", "sky", {x = 12, y = 12}, "left")
        end
    else
        Wargroove.spawnMapAnimation(unit.pos, 0, "units/commanders/organ/organ_muzzle_up", "idle", "sky", {x = 12, y = 24})
    end
    Wargroove.waitTime(0.3)

    Wargroove.playUnitAnimation(unit.id, "idle")
end

function OrganAttack:execute(unit, targetPos, strParam, path)
    -- Get current state
    local turnsSincePush = Wargroove.getUnitState(unit, "turnsSincePush")
    local previousAction = Wargroove.getUnitState(unit, "previousAction")
    local initialPushes = Wargroove.getUnitState(unit, "initialPushes")
    local offset = {x = 0, y = 24}

    print(tostring(previousAction))

    if turnsSincePush == nil then
        turnsSincePush = 0
    else
        turnsSincePush = tonumber(turnsSincePush)
    end

    if previousAction == nil then
        previousAction = { }
    else
        previousAction = Wargroove.stringToTable(previousAction)
    end

    if initialPushes == nil then
        initialPushes = { false, false, false }
    end

    print("Previous Action: ".. Wargroove.tableToString(previousAction))
    print("Action: "..strParam)
    print("Turns since push: "..turnsSincePush)

    local allUnits = Wargroove.getAllUnitIds()
    local targetUnits = {}
    for i, unitId in ipairs(allUnits) do
        local targetUnit = Wargroove.getUnitById(unitId)
        if Wargroove.areEnemies(targetUnit.playerId, unit.playerId) then
            table.insert(targetUnits, targetUnit)
        end
    end

    local facing = getDirection(unit)

    -- Sort by distance
    local function distFromTarget(a)
        return math.abs(a.pos.x - unit.pos.x) + math.abs(a.pos.y - unit.pos.y)
    end
    table.sort(targetUnits, function(a, b) return distFromTarget(a) < distFromTarget(b) end)

    if strParam == "throw" then
        turnsSincePush = turnsSincePush + 1

        local values = { unit.id, unit.unitClassId, targetUnits[1].pos.x, targetUnits[1].pos.y, targetUnits[2].pos.x, targetUnits[2].pos.y, Wargroove.getTurnNumber(), Wargroove.getCurrentPlayerId() }
        local rngStr = ""
        for i, v in ipairs(values) do
            rngStr = rngStr .. tostring(v) .. ":"
        end

        -- Pick only from bottom top 3
        local targetIndex = Wargroove.randomInteger(rngStr, 1, math.min(3, #targetUnits))
        local targetUnit = targetUnits[targetIndex]

        playAttackSequence(unit, facing)

        local bombId = Wargroove.spawnUnit(unit.playerId, unit.pos, "organ_bomb", false, "spawn")
        Wargroove.lockTrackCamera(bombId)

        Wargroove.moveUnitToOverride(bombId, targetUnit.pos, 0, 0, 15, "pow3In")
        while Wargroove.isLuaMoving(bombId) do
            coroutine.yield()
        end

        Wargroove.removeUnit(bombId)

        Wargroove.unlockTrackCamera()

        -- Throw bomb at target
        Wargroove.spawnMapAnimation(targetUnit.pos, 1, "units/commanders/organ/organ_explosion", "idle", "over_units", { x = 12, y = 12 })
        Wargroove.playMapSound("koji/kojiDroneExplode", targetUnit.pos)

        local targets = Wargroove.getTargetsInRange(targetUnit.pos, explosionRange, "unit")
        if targets then
            for i, pos in ipairs(targets) do
                local u = Wargroove.getUnitAt(pos)
                if u and u.health > 0 and (not u.unitClass.isStructure) and (u.playerId ~= -1) and u.id ~= unit.id then
                    -- Change to scaled commander damage
                    u:setHealth(u.health - explosionDamage, unit.id)
                    Wargroove.playUnitAnimation(u.id, "hit")
                    Wargroove.updateUnit(u)
                end
            end
        end

        Wargroove.waitTime(0.2)
    elseif strParam == "push" then
        turnsSincePush = 0

        -- Gather targets in front of enemy
        local mainDirectionDelta = { x=0, y=0 }
        local sideDirectionDelta = { x=0, y=0 }

        if facing == "right" then
            mainDirectionDelta.x = 1
            sideDirectionDelta.y = 1
        elseif facing == "left" then
            mainDirectionDelta.x = -1
            sideDirectionDelta.y = 1
        elseif facing == "up" then
            mainDirectionDelta.y = 1
            sideDirectionDelta.x = 1
        elseif facing == "down" then
            mainDirectionDelta.y = -1
            sideDirectionDelta.x = 1
        end

        local highlightLocation = Wargroove.getLocationByName("boss_attack_area_" .. facing)
        Wargroove.highlightLocation(highlightLocation.id, "none", "red", false, false, false, false)
        local safeArea = Wargroove.getLocationByName("boss_safe_area_" .. facing)
        Wargroove.highlightLocation(safeArea.id, "none", "red", false, false, false, false)

        playAttackSequence(unit, facing)

        -- 1. Collect units that are impacted
        local pushedUnits = {}
        for i=1, 15, 1 do
            local pushPositions = {}
            local centrePos = { x=unit.pos.x-(mainDirectionDelta.x*i),  y=unit.pos.y-(mainDirectionDelta.y*i) }
            table.insert(pushPositions, centrePos)
            
            for j=1,pushWidth, 1 do
                local sidePosOne = { x=centrePos.x-(sideDirectionDelta.x*j), y=centrePos.y-(sideDirectionDelta.y*j) }
                local sidePosTwo = { x=centrePos.x+(sideDirectionDelta.x*j), y=centrePos.y+(sideDirectionDelta.y*j) }
                
                table.insert(pushPositions, sidePosOne)
                table.insert(pushPositions, sidePosTwo)
            end
            
            for _, pos in ipairs(pushPositions) do
                local unitAtPushPos = Wargroove.getUnitAt(pos)
                local oneBackPos = { x=pos.x-(mainDirectionDelta.x*-1),  y=pos.y-(mainDirectionDelta.y*-1) }

                local terrain = Wargroove.getTerrainNameAt(oneBackPos)

                if unitAtPushPos ~= nil and terrain ~= "wall" then
                    table.insert(pushedUnits, unitAtPushPos)
                end
            end
        end
        
        -- 2. Sort by reverse distance, so farthest away is first in list
        table.sort(pushedUnits, function(a, b) return distFromTarget(a) > distFromTarget(b) end)
        
        -- 3. Calculate the push result for each, updating their position from the results each time, which should allow for the stacking to work correctly
        local pushResults = {}
        for _, u in ipairs(pushedUnits) do
            print(Wargroove.tableToString(u.pos) .. " " .. u.unitClassId)

            local origin = { x=u.pos.x - (mainDirectionDelta.x*-1), y=u.pos.y - (mainDirectionDelta.y*-1) }
            local pushResult = Wargroove.getPushPullResult(origin, u.pos, pushDistance, false, true)
            if pushResult ~= nil and pushResult["pushPosition"] then
                Wargroove.pushUnitPos(u, pushResult["pushPosition"])

                table.insert(pushResults, pushResult)
            end
        end
        Wargroove.popAllUnitPos()

        -- 4. Execute the push results for all the units and show the visual effect at the same time
        local lastPushedUnitId = nil
        local tornadoList = {}
        for i=1, 15, 1 do
            local pushPositions = {}

            local centrePos = { x=unit.pos.x-(mainDirectionDelta.x*i),  y=unit.pos.y-(mainDirectionDelta.y*i) }
            table.insert(pushPositions, centrePos)

            for j=1,pushWidth, 1 do
                local sidePosOne = { x=centrePos.x-(sideDirectionDelta.x*j), y=centrePos.y-(sideDirectionDelta.y*j) }
                local sidePosTwo = { x=centrePos.x+(sideDirectionDelta.x*j), y=centrePos.y+(sideDirectionDelta.y*j) }
                
                table.insert(pushPositions, sidePosOne)
                table.insert(pushPositions, sidePosTwo)
            end

            if i == 10 then
                Wargroove.trackCameraTo(centrePos)
            end

            for _, pos in ipairs(pushPositions) do
                local oneBackPos = { x=pos.x-(mainDirectionDelta.x*-1),  y=pos.y-(mainDirectionDelta.y*-1) }
                local terrain = Wargroove.getTerrainNameAt(pos)
                local oneBackTerrain = Wargroove.getTerrainNameAt(oneBackPos)
                if terrain == "sea" or terrain == "ocean" or terrain == "reef" or terrain == "beach" or terrain == "wall" or oneBackTerrain == "wall" then
                    goto NEXT_POS
                end

                local targetUnit = Wargroove.getUnitAt(pos)
                if targetUnit then
                    local pushResult = nil
                    for _, result in ipairs(pushResults) do
                        if result["targetUnit"].id == targetUnit.id then
                            pushResult = result
                        end
                    end

                    if pushResult then
                        lastPushedUnitId = Wargroove.batchProcessPushPullResult(unit, pushResult, pushDamage, pushCollisionDamage, 2)
                        
                        -- Replace with some effect
                        local tornadoFrontEntityId = Wargroove.spawnUnitEffect(targetUnit.id, targetUnit.id, "units/commanders/organ/push_front", "idle", "spawn", true, false)
                        local tornadoBackEntityId = Wargroove.spawnUnitEffect(targetUnit.id, targetUnit.id, "units/commanders/organ/push_back", "idle", "spawn", false, false)

                        table.insert(tornadoList, tornadoFrontEntityId)
                        table.insert(tornadoList, tornadoBackEntityId)
                    end
                end

                :: NEXT_POS ::
            end
        end

        Wargroove.playMapSound("tenri/tenriGrooveTornado", unit.pos)
        Wargroove.waitTime(0.3)

        while (lastPushedUnitId and Wargroove.isLuaMoving(lastPushedUnitId)) do
            coroutine.yield()
        end

        for _, effectId in ipairs(tornadoList) do
            Wargroove.deleteUnitEffect(effectId, "death")
        end

        Wargroove.finalizeBatchPushPullResults(unit, pushResults, pushDamage, pushCollisionDamage)
        Wargroove.waitTime(1.5)

        -- Spawn 3 units in front
        local centrePos = { x=unit.pos.x-(mainDirectionDelta.x),  y=unit.pos.y-(mainDirectionDelta.y) }
        local sidePosOne = { x=centrePos.x-sideDirectionDelta.x, y=centrePos.y-sideDirectionDelta.y }
        local sidePosTwo = { x=centrePos.x+sideDirectionDelta.x, y=centrePos.y+sideDirectionDelta.y }
        
        Wargroove.trackCameraTo(centrePos)
        Wargroove.waitTime(1.5)

        local values = { unit.id, unit.unitClassId, centrePos.x, centrePos.y, Wargroove.getTurnNumber(), Wargroove.getCurrentPlayerId() }
        local rngStr = ""
        for i, v in ipairs(values) do
            rngStr = rngStr .. tostring(v) .. ":"
        end

        local mainUnitsToSpawn = firstWave
        if facing == "left" then
            mainUnitsToSpawn = thirdWave
        elseif facing == "right" then
            mainUnitsToSpawn = secondWave
        end

        local unitToSpawn = mainUnitsToSpawn[Wargroove.randomInteger(rngStr, 1, #mainUnitsToSpawn)]
        spawnUnit(sidePosTwo, unitToSpawn, unit.playerId)

        rngStr = rngStr .. sidePosOne.x .. sidePosOne.y
        unitToSpawn = mainUnitsToSpawn[Wargroove.randomInteger(rngStr, 1, #mainUnitsToSpawn)]
        spawnUnit(sidePosOne, unitToSpawn, unit.playerId)

        rngStr = rngStr .. sidePosTwo.x .. sidePosTwo.y

        if facing == "left" then
            unitToSpawn = finalUnitsToSpawn[Wargroove.randomInteger(rngStr, 1, #finalUnitsToSpawn)]
        elseif facing == "right" then
            unitToSpawn = airUnitsToSpawn[Wargroove.randomInteger(rngStr, 1, #airUnitsToSpawn)]
        else
            unitToSpawn = mainUnitsToSpawn[Wargroove.randomInteger(rngStr, 1, #mainUnitsToSpawn)]
        end
        
        spawnUnit(centrePos, unitToSpawn, unit.playerId)
    
    elseif strParam == "spawn" then
        turnsSincePush = turnsSincePush + 1

        local unitSpawnCount = 2

        local values = { unit.id, unit.unitClassId, turnsSincePush, Wargroove.getTurnNumber(), Wargroove.getCurrentPlayerId() }
        local rngStr = ""
        for i, v in ipairs(values) do
            rngStr = rngStr .. tostring(v) .. ":"
        end

        playAttackSequence(unit, facing)

        local mainUnitsToSpawn = firstWave
        if facing == "left" then
            mainUnitsToSpawn = firstWave
        elseif facing == "right" then
            mainUnitsToSpawn = firstWave
        end

        for i=1,unitSpawnCount do
            local unitToSpawn = mainUnitsToSpawn[Wargroove.randomInteger(rngStr, 1, #mainUnitsToSpawn)]
            local loc = Wargroove.getLocationByName("boss_spawn")
            local candidates = Wargroove.findPlaceInLocation(loc, unitToSpawn)

            if #candidates > 0 then
                local pick = Wargroove.randomInteger(rngStr, 1, #candidates)
                local pos = candidates[pick]
                
                if i==1 then
                    Wargroove.trackCameraTo(pos.pos)
                    Wargroove.waitTime(0.2)
                end

                spawnUnit(pos.pos, unitToSpawn, unit.playerId)
            end
        end
        
    elseif strParam == "smack" then
        turnsSincePush = turnsSincePush + 1

        playAttackSequence(unit, facing)

        local loc = Wargroove.getLocationByName("boss_spawn")
        local candidates = Wargroove.findPlaceInLocation(loc, "soldier")

        local values = { unit.id, unit.unitClassId,  turnsSincePush, Wargroove.getTurnNumber(), Wargroove.getCurrentPlayerId() }
        local rngStr = ""
        for i, v in ipairs(values) do
            rngStr = rngStr .. tostring(v) .. ":"
        end

        -- Gather targets in front of enemy
        local mainDirectionDelta = { x=0, y=0 }
        local sideDirectionDelta = { x=0, y=0 }

        if facing == "right" then
            mainDirectionDelta.x = 1
            sideDirectionDelta.y = 1
        elseif facing == "left" then
            mainDirectionDelta.x = -1
            sideDirectionDelta.y = 1
        elseif facing == "up" then
            mainDirectionDelta.y = 1
            sideDirectionDelta.x = 1
        elseif facing == "down" then
            mainDirectionDelta.y = -1
            sideDirectionDelta.x = 1
        end

        local centrePos = { x=unit.pos.x-(mainDirectionDelta.x),  y=unit.pos.y-(mainDirectionDelta.y) }
        local frontRowPositions = {
            { x=centrePos.x,  y=centrePos.y },
            { x=centrePos.x-sideDirectionDelta.x, y=centrePos.y-sideDirectionDelta.y },
            { x=centrePos.x+sideDirectionDelta.x, y=centrePos.y+sideDirectionDelta.y }
        }

        local frontRowTargets = {}
        for _, pos in ipairs(frontRowPositions) do
            local u = Wargroove.getUnitAt(pos)
            if u and Wargroove.areEnemies(u.playerId, unit.playerId) then
                table.insert(frontRowTargets, u)
            end
        end

        local targetPick = Wargroove.randomInteger(rngStr, 1, #frontRowTargets)
        local targetUnit = frontRowTargets[targetPick]

        if #candidates > 0 then
            local pick = Wargroove.randomInteger(rngStr, 1, #candidates)
            local pos = candidates[pick].pos

            print(Wargroove.tableToString(pos) .. " : smacking! ")

            local numSteps = 10

            local steps = {}
            local xDiff = pos.x - targetUnit.pos.x
            local yDiff = pos.y - targetUnit.pos.y
            local xStep = xDiff / numSteps
            local yStep = yDiff / numSteps
            for i = 1,numSteps do
                if (xDiff ~= 0) then
                    local radians = i / numSteps * 3.14
                    steps[i] = {x = xStep * i, y = yStep * i + -2.5 * math.sin(radians)}
                else
                    steps[i] = { x = 0, y = yStep * i}
                end
            end

            local startingPosition = targetUnit.pos
            Wargroove.lockTrackCamera(targetUnit.id)
            Wargroove.setShadowVisible(targetUnit.id, false)
            for i = 1, numSteps do
                Wargroove.moveUnitToOverride(targetUnit.id, startingPosition, steps[i].x, steps[i].y, 20)
                while (Wargroove.isLuaMoving(targetUnit.id)) do
                    coroutine.yield()
                end
            end
            Wargroove.unsetShadowVisible(targetUnit.id)
            Wargroove.unlockTrackCamera()

            targetUnit:setHealth(targetUnit.health - smackDamage, unit.id)
            targetUnit.pos = pos
            Wargroove.updateUnit(targetUnit)
            Wargroove.playUnitAnimation(targetUnit.id, "hit")
        end
    elseif strParam == "charge" then
        turnsSincePush = turnsSincePush + 1

        Wargroove.trackCameraTo(unit.pos)
        Wargroove.playUnitAnimation(unit.id, "attack", "idle")
        Wargroove.waitTime(1.6)
        Wargroove.spawnMapAnimation(unit.pos, 0, "units/commanders/organ/organ_muzzle", "idle", "over_unit", {x=0, y=0}, facing)

        local highlightLocation = Wargroove.getLocationByName("boss_attack_area_" .. facing)
        Wargroove.highlightLocation(highlightLocation.id, "boss_attack_area_" .. facing, "red", false, false, false, false)
        local safeArea = Wargroove.getLocationByName("boss_safe_area_" .. facing)
        Wargroove.highlightLocation(safeArea.id, "safe_space", "green", false, false, false, false)
        Wargroove.trackCameraTo(highlightLocation.centre)
    elseif strParam == "pause" then
        -- Do nothing for a turn
        turnsSincePush = turnsSincePush + 1
    end

    table.insert(previousAction, 1, strParam)
    if #previousAction > 2 then
        table.remove(previousAction, #previousAction)
    end

    -- Store current state
    OrganAttack.turnsSincePush = turnsSincePush
    OrganAttack.previousAction = previousAction
    OrganAttack.initialPushes = initialPushes
end

function OrganAttack:onPostUpdateUnit(unit, targetPos, strParam, path)
    
    local previousActionString = Wargroove.unitIdsToString(OrganAttack.previousAction)

    Wargroove.setUnitState(unit, "turnsSincePush", OrganAttack.turnsSincePush)
    Wargroove.setUnitState(unit, "previousAction", previousActionString)
    Wargroove.setUnitState(unit, "initialPushes", OrganAttack.initialPushes)
end

function OrganAttack:generateOrders(unitId, canMove)
    local orders = {}

    local unit = Wargroove.getUnitById(unitId)

    -- Get current state
    local turnsSincePush = Wargroove.getUnitState(unit, "turnsSincePush")
    local previousAction = Wargroove.getUnitState(unit, "previousAction")
    local initialPushes = Wargroove.getUnitState(unit, "initialPushes")

    if turnsSincePush == nil then
        turnsSincePush = 99
    else
        turnsSincePush = tonumber(turnsSincePush)
    end

    if previousAction == nil then
        previousAction = { }
    else
        previousAction = Wargroove.stringToTable(previousAction)
    end

    if initialPushes == nil then
        initialPushes = { false, false, false }
    end

    print("Previous Action: ".. Wargroove.tableToString(previousAction))
    print("Turns since push: "..turnsSincePush)

    local values = { unit.pos.x, unit.pos.y, Wargroove.getTurnNumber() }
    local rngString = ""
    for i, v in ipairs(values) do
        rngString = rngString .. tostring(v) .. ":"
    end

    local mainDirectionDelta = { x=0, y=0 }
    local sideDirectionDelta = { x=0, y=0 }

    local facing = getDirection(unit)
    if facing == "right" then
        mainDirectionDelta.x = 1
        sideDirectionDelta.y = 1
    elseif facing == "left" then
        mainDirectionDelta.x = -1
        sideDirectionDelta.y = 1
    elseif facing == "up" then
        mainDirectionDelta.y = 1
        sideDirectionDelta.x = 1
    elseif facing == "down" then
        mainDirectionDelta.y = -1
        sideDirectionDelta.x = 1
    end

    -- Spawn 3 units in front
    local centrePos = { x=unit.pos.x-(mainDirectionDelta.x),  y=unit.pos.y-(mainDirectionDelta.y) }
    local frontRowPositions = {
        { x=centrePos.x,  y=centrePos.y },
        { x=centrePos.x-sideDirectionDelta.x, y=centrePos.y-sideDirectionDelta.y },
        { x=centrePos.x+sideDirectionDelta.x, y=centrePos.y+sideDirectionDelta.y }
    }
    local frontRowTargets = {}
    for _, pos in ipairs(frontRowPositions) do
        local u = Wargroove.getUnitAt(pos)
        if u and Wargroove.areEnemies(u.playerId, unit.playerId) then
            table.insert(frontRowTargets, u)
        end
    end

    local nextAction = Wargroove.randomInteger(rngString, 1, 3)

    -- Throw does area damage to random target
    local action = "throw"

    -- If there are targets directly in front -> smack. This overrides previous choices. Pushes front unit somewhere random in boss_spawn location
    -- Spawn spawns a random unit in boss spawn area
    -- Pause .. just pauses for a turn
    if #frontRowTargets > 0 and (nextAction == 2 or nextAction == 3) then
        action = "smack"
    elseif nextAction == 2 then
        action = "spawn" 
    elseif nextAction == 1 then
        action = "throw"
    elseif nextAction == 3 and previousAction[1] ~= "pause" then
        action = "pause"
    end

    local bossUnits = Wargroove.getAllUnitsForPlayer(unit.playerId, true)
    print("Boss units: " .. #bossUnits)

    -- If we haven't pushed in 3 turns, we always do. Overrides any other choice
    -- At 2 -> Take a pause and charge
    if turnsSincePush >= 3 then
        action = "push"
    elseif turnsSincePush >= 2 then
        action = "charge"
    elseif #bossUnits <= 4 and previousAction[1] ~= "spawn" then
        action = "spawn"
    else
        if facing == "down" and initialPushes[1] == false then
            initialPushes[1] = true
            action = "push"
        elseif facing == "right" and initialPushes[2] == false then
            initialPushes[2] = true
            action = "push"
        elseif facing == "left" and initialPushes[3] == false then
            initialPushes[3] = true
            action = "push"
        end
    end

    table.insert(orders, {
        targetPosition = unit.pos,
        strParam = action,
        movePosition = unit.pos,
        endPosition = unit.pos
    })

    -- Store current state
    Wargroove.setUnitState(unit, "initialPushes", initialPushes)
    -- Wargroove.updateUnit(unit)

    return orders
end

function OrganAttack:getScore(unitId, order)
    return {score = 999, introspection = {}}
end

return OrganAttack