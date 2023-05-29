local Wargroove = require "wargroove/wargroove"
local VisionTracker = require "initialized/vision_tracker"
local AIManager = require "initialized/ai_manager"
local Ragnarok = require "initialized/ragnarok"
local Pathfinding = require "util/pathfinding"

local function dump(o,level)
    if type(o) == 'table' then
       local s = '\n' .. string.rep("   ", level) .. '{\n'
       for k,v in pairs(o) do
          if type(k) ~= 'number' then k = '"'..k..'"' end
          s = s .. string.rep("   ", level+1) .. '['..k..'] = ' .. dump(v,level+1) .. ',\n'
       end
       return s .. string.rep("   ", level) .. '}'
    else
       return tostring(o)
    end
 end
 

local function getFacing(from, to)
   local dx = to.x - from.x
   local dy = to.y - from.y

   if dx ~= 0 then
       if dx > 0 then
           return 1 -- Right
       else
           return 3 -- Left
       end
   else
       if dy > 0 then
           return 2 -- Down
       else
           return 0 -- Up
       end
   end
end

local StealthManager = {}
local fleeingCount = 0
local active = {}
local AIGoalPos = {}
local AIOrder = {}
local AISpeed = {}
local lastKnownPosMap = {}
local braveryMap = {}

function StealthManager.setBravery(playerId, bravery)
    braveryMap[playerId] = bravery
end

function StealthManager.canBeAlerted(unit)
    if not Pathfinding.withinBounds(unit.pos) then
        return false
    end
    if unit.unitClass.isStructure then
        return false
    end
    if active[unit.playerId]== nil then
        return false
    end
    return true
end

function StealthManager.canAlert(unit)
    if not Pathfinding.withinBounds(unit.pos) then
        return false
    end
    if (unit.unitClassId == "reveal_all") or (unit.unitClassId == "reveal_all_but_hidden") or (unit.unitClassId == "reveal_all_but_over") or (unit.canBeAttacked == false) then
        return false
    end
    return true
end

function StealthManager.isCivilian(unitClassId)
    if (unitClassId == "wagon") or (unitClassId == "travelboat") or (unitClassId == "thief_with_gold") or (unitClassId == "thief") or (unitClassId == "villager") then
        return true
    end
    return false
end

function StealthManager.getFleeCountTarget(playerId)
    local playerValue = 0
    for id,unit in pairs(Wargroove.getUnitsAtLocation(nil)) do
        if (StealthManager.isUnitSearching(unit,true)) and (playerId == unit.playerId) then
            playerValue = playerValue + (unit.unitClass.cost+100)*unit.health/100.0;
        end
    end
    local enemyValue = 0
    for id,unit in pairs(Wargroove.getUnitsAtLocation(nil)) do
        if Wargroove.areEnemies(unit.playerId,playerId) and not unit.unitClass.isStructure then
            enemyValue = enemyValue + (unit.unitClass.cost+100)*unit.health/100.0;
        end
    end
    if braveryMap[playerId] == nil then
        braveryMap[playerId] = 100
    end
    return math.ceil((enemyValue-2*playerValue*braveryMap[playerId]/100.0)/800.0)
end

function StealthManager.init()
    Ragnarok.addAction(StealthManager.startOfGame,"start_of_match",false)
    Ragnarok.addAction(StealthManager.update,"repeating",false)
end

function StealthManager.reportDeadUnit(unitId)
    local unit = Wargroove.getUnitById(unitId)

    fleeingCount = 0
    for id,friend in pairs(Wargroove.getUnitsAtLocation(nil)) do
        if (StealthManager.isUnitFleeing(friend)) and (unit.playerId == friend.playerId) then
            fleeingCount = fleeingCount + 1
        end
    end
    local listOfViewerPos = VisionTracker.getListOfViewerIds(unit.pos);
    for viewerId, pos in pairs(listOfViewerPos) do
        local viewer = Wargroove.getUnitAt(pos)
        if (viewer ~= nil) and (StealthManager.canBeAlerted(viewer)) and (unitId ~= viewerId) then
            if unit.playerId == viewer.playerId then
                StealthManager.setLastKnownLocation(viewerId, unit.pos)
                StealthManager.makeAlerted(viewer)
                StealthManager.spreadInfo(viewer)
            end
        end
    end
    local targetFleeCount = StealthManager.getFleeCountTarget(unit.playerId)
    for viewerId, pos in pairs(listOfViewerPos) do
        local viewer = Wargroove.getUnitAt(pos)
        if (viewer ~= nil) and (StealthManager.canBeAlerted(viewer)) and (unitId ~= viewerId) then
            if unit.playerId == viewer.playerId then
                if fleeingCount <= targetFleeCount then
                    if StealthManager.makeFleeing(viewer) then
                        fleeingCount = fleeingCount + 1
                    end
                end
            end
        end
    end
	VisionTracker.removeUnitFromVisionMatrix(unit)
    StealthManager.removeUnit(unit)
end

function StealthManager.removeUnit(unit)
    AIGoalPos[unit.id] = nil
    AIOrder[unit.id] = nil
    AISpeed[unit.id] = nil
    lastKnownPosMap[unit.id] = nil
    Wargroove.setUnitState(unit,"awareness","unaware")
    Wargroove.setUnitState(unit,"visual_awareness","unaware")
    Wargroove.updateUnit(unit)
end

function StealthManager.setActive(playerId,isActive)
	active[playerId] = isActive
    if isActive == false then
        active[playerId] = nil
        local units = Wargroove.getUnitsAtLocation(nil)
        for i, unit in pairs(units) do
            if unit.playerId == playerId then
                StealthManager.removeUnit(unit)
            end
        end
    end
end

function StealthManager.isActive(playerId)
	return active[playerId] ~= nil
end

function StealthManager.setAIGoalPos(order, unitId,pos, maxSpeed)
	AIGoalPos[unitId] = pos
	AIOrder[unitId] = order
    if maxSpeed~=nil then
        AISpeed[unitId] = maxSpeed
    end
end
local init = true
function StealthManager.startOfGame(context)
    local units = Wargroove.getUnitsAtLocation(nil)
    for i,unit in ipairs(units) do
        StealthManager.removeUnit(unit)
    end
    for playerId, value in ipairs(active) do
        StealthManager.endOfTurnCleanUp(playerId)
    end
end

local canSeeTiles = {}


function StealthManager.update(context)
    if init then
        
        init = false
    end
    local units = {}
    for i,unit in ipairs(Wargroove.getUnitsAtLocation(nil)) do
        if Pathfinding.withinBounds(unit.pos) then
            table.insert(units,unit)
        end
    end

    for i,unit in ipairs(units) do
        if (active[unit.playerId]~=nil) then
            AIManager.roadMoveOrder(unit.id,unit.pos)
        end
        StealthManager.awarenessCheck(unit.id, {unit.pos})
    end
    print("stealth goal list")
    for unitId,pos in pairs(AIGoalPos) do
        local unit = Wargroove.getUnitById(unitId)
        if (unit ~= nil) and not StealthManager.isUnitPermaAlerted(unit) then
            print(unit.unitClassId)
            if AIOrder[unitId]~=nil then
                print(AIOrder[unitId])
            else

                print("nil")
            end
            if AISpeed[unitId]~=nil then
                print(AISpeed[unitId])
            else

                print("nil")
            end
            print(dump(AIGoalPos[unit.id],0))
            if AIOrder[unitId]==nil then
                AIOrder[unitId] = "road_move"
            end
            AIManager.order(AIOrder[unitId], unitId, pos, AISpeed[unitId])
            print("path")
            print(dump(AIManager.getPath(unitId),0))
            print(dump(AIManager.getNextPosition(unitId),0))
        end
    end
    for id,lastKnownPos in pairs(lastKnownPosMap) do
        local unit = Wargroove.getUnitById(id)
        if (unit ~= nil) then
            if StealthManager.isUnitAlerted(unit) then
                AIManager.attackMoveOrder(id,lastKnownPos.pos)
            elseif StealthManager.isUnitSearching(unit) then
                AIManager.moveOrder(id,lastKnownPos.pos)
            elseif StealthManager.isUnitFleeing(unit) then
                if AIGoalPos[id]~=nil then
                    AIManager.safeMoveOrder(id,AIGoalPos[id])
                else
                    local unawareAllyPos = {}
                    for i,ally in ipairs(units) do
                        if StealthManager.canBeAlerted(ally) and StealthManager.isUnitUnaware(ally) and (ally.playerId == unit.playerId) and (unit.id~=ally.id) and (Ragnarok.isCombatUnit(ally)) then
                            table.insert(unawareAllyPos,ally.pos)
                        end
                    end
                    if next(unawareAllyPos) ~=nil then
                        AIManager.moveOrder(id,unawareAllyPos)
                    else
                        AIManager.retreatOrder(id)
                    end
                end
            end
        end
    end
    if (context:checkState("endOfTurn")) and (active[Wargroove.getCurrentPlayerId()] ~= nil) then
        StealthManager.endOfTurnCleanUp(Wargroove.getCurrentPlayerId())
    end
end

function StealthManager.endOfTurnCleanUp(playerId)
        local units = {}
        for i,unit in ipairs(Wargroove.getUnitsAtLocation(nil)) do
            if Pathfinding.withinBounds(unit.pos) then
                table.insert(units,unit)
            end
        end
        local cutOffEnemies = {}
        for i,unit in pairs(units) do
            if unit.playerId == playerId then
                cutOffEnemies[unit.id] = unit
            end
        end
        for i,unit in pairs(units) do
            if Wargroove.areEnemies(unit.playerId,playerId) and StealthManager.canAlert(unit) then
                local viewerPosList = VisionTracker.getListOfViewerIds(unit.pos)
                for viewerId,pos in pairs(viewerPosList) do
                    local viewer = Wargroove.getUnitAt(pos)
                    if (viewer ~= nil) and (viewer.playerId == playerId) then
                        cutOffEnemies[viewerId] = nil
                    end
                end
            end
        end

        for i,enemy in pairs(cutOffEnemies) do
            if StealthManager.isUnitSearching(enemy) and (lastKnownPosMap[enemy.id] ~= nil) then
                local dist = math.abs(enemy.pos.x - lastKnownPosMap[enemy.id].pos.x) + math.abs(enemy.pos.y - lastKnownPosMap[enemy.id].pos.y)
                if (dist<=2) and VisionTracker.canUnitSeeTile(enemy,lastKnownPosMap[enemy.id].pos) then
                    lastKnownPosMap[enemy.id] = nil
                end
            end
            if StealthManager.isUnitSearching(enemy) and (lastKnownPosMap[enemy.id] == nil) then
                StealthManager.makeUnaware(enemy)
            end
            local unit = Wargroove.getUnitById(enemy.id)
            if StealthManager.isUnitAlerted(enemy) then
                StealthManager.makeSearching(enemy, true)
            end
            local unawareAllyPos = {}
            for i,ally in ipairs(units) do
                if StealthManager.canBeAlerted(ally) and StealthManager.isUnitUnaware(ally) and (ally.playerId == unit.playerId) and (unit.id~=ally.id) and (Ragnarok.isCombatUnit(ally)) then
                    table.insert(unawareAllyPos,ally.pos)
                end
            end
            if next(unawareAllyPos) ==nil then
                StealthManager.makeUnaware(unit)
            end
        end
        for id,unit in pairs(Wargroove.getUnitsAtLocation(nil)) do
            if (unit ~= nil) and Pathfinding.withinBounds(unit.pos) then
                if StealthManager.isUnitFleeing(unit) then

                    if (StealthManager.spreadInfo(unit) and (cutOffEnemies[unit.id] ~= nil)) then
                        StealthManager.makeSearching(unit,true)
                    end
                end
            end
        end
        StealthManager.updateAwarenessAll()
end

function StealthManager.isUnitPermaAlerted(unit)
    return (active[unit.playerId]~=nil) and (Wargroove.getUnitState(unit, "awareness") == "perma_alerted")
end

function StealthManager.isUnitAlerted(unit,orBetter)
    if orBetter and (StealthManager.isUnitPermaAlerted(unit) or StealthManager.isUnitFleeing(unit)) then
        return true
    end
    return (active[unit.playerId]~=nil) and (Wargroove.getUnitState(unit, "awareness") == "alerted")
end

function StealthManager.isUnitFleeing(unit)
    return (active[unit.playerId]~=nil) and (Wargroove.getUnitState(unit, "awareness") == "fleeing")
end

function StealthManager.makeFleeing(unit)
    if (active[unit.playerId]~=nil) and StealthManager.canBeAlerted(unit) then
        Wargroove.setUnitState(unit,"awareness","fleeing")
        Wargroove.updateUnit(unit)
        return true
    end
    return false
end

function StealthManager.makePermaAlerted(unit)
    if (active[unit.playerId]~=nil) then
        if (StealthManager.canBeAlerted(unit) and Ragnarok.isCombatUnit(unit)) or (unit.unitClassId == "barracks") or (unit.unitClassId == "port") then
            Wargroove.setUnitState(unit,"awareness","perma_alerted")
            Wargroove.updateUnit(unit)
            return true
        end
    end
    return false
end

function StealthManager.makeAlerted(unit, force)
    if not StealthManager.isUnitFleeing(unit) or (force == true) then
        if (active[unit.playerId]~=nil) and StealthManager.canBeAlerted(unit) then
            if Ragnarok.isCombatUnit(unit) then
                if StealthManager.isUnitFleeing(unit) then
                    fleeingCount = fleeingCount-1
                end
                if not StealthManager.isUnitPermaAlerted(unit) then
                    Wargroove.setUnitState(unit,"awareness","alerted")
                    Wargroove.updateUnit(unit)
                end
                StealthManager.spreadInfo(unit)
                return true
            else
                StealthManager.makeFleeing(unit)
                return true
            end
        end
    end
    return false
end

function StealthManager.isUnitSearching(unit, orBetter)
    if orBetter and (StealthManager.isUnitAlerted(unit, orBetter)) then
        return true
    end
    return (active[unit.playerId]~=nil) and (Wargroove.getUnitState(unit, "awareness") == "searching")
end

function StealthManager.makeSearching(unit, force)
    if active[unit.playerId]~=nil and StealthManager.canBeAlerted(unit) and (not StealthManager.isUnitAlerted(unit,true) or (force == true)) then
        if not StealthManager.isUnitSearching(unit) then
            if not StealthManager.isUnitPermaAlerted(unit) then
                Wargroove.setUnitState(unit,"awareness","searching")
                Wargroove.updateUnit(unit)
                return true
            end
        end
    end
    return false
end

function StealthManager.isUnitUnaware(unit)
    return (active[unit.playerId]~=nil) and (Wargroove.getUnitState(unit, "awareness") == "unaware")
end

function StealthManager.makeUnaware(unit)
    if (active[unit.playerId]==nil) then
        return false
    end
    if StealthManager.isUnitFleeing(unit) then
        fleeingCount = fleeingCount-1
    end
    if not StealthManager.isUnitPermaAlerted(unit) then
        Wargroove.setUnitState(unit,"awareness","unaware")
        Wargroove.updateUnit(unit)
        return true
    end
    return false
end

function StealthManager.spreadInfo(unit)
    local checked = {}
    checked[unit.id] = true
    local idsToBeChecked = {unit.id}
    local function addNewToBeChecked(idsToBeChecked, checked, currentUnit)
        local viewerPosList = VisionTracker.getListOfViewerIds(currentUnit.pos)
        for viewerId,pos in pairs(viewerPosList) do
            local viewer = Wargroove.getUnitAt(pos)
            if (viewer ~= nil) and (viewer.playerId == unit.playerId) and StealthManager.canBeAlerted(viewer) and (checked[viewer.id] == nil) then
                
                local dist = math.abs(currentUnit.pos.x - viewer.pos.x) + math.abs(currentUnit.pos.y - viewer.pos.y)
                if (dist<=2) then
                    table.insert(idsToBeChecked,viewerId)
                end
            end
        end
        return idsToBeChecked

    end
    local shared = false
    while next(idsToBeChecked) ~= nil do
        local index,currentId = next(idsToBeChecked)
        local currentUnit = Wargroove.getUnitById(currentId)
        if (currentUnit ~= nil) then
            if StealthManager.shareInfo(unit, currentUnit) then
                shared = true
            end
            idsToBeChecked = addNewToBeChecked(idsToBeChecked, checked, currentUnit)
        end
        checked[currentId] = true
        idsToBeChecked[index] = nil
    end
    return shared
end

function StealthManager.shareInfo(unit1, unit2)
    local infoShared = false
    if StealthManager.isUnitAlerted(unit1,true) and (lastKnownPosMap[unit1.id]~= nil) then
        infoShared = StealthManager.makeSearching(unit2) or infoShared
    end
    if StealthManager.isUnitAlerted(unit2,true) and (lastKnownPosMap[unit2.id]~= nil) then
        infoShared = StealthManager.makeSearching(unit1) or infoShared
    end
    if (lastKnownPosMap[unit1.id]== nil) and (lastKnownPosMap[unit2.id]~= nil) then
        lastKnownPosMap[unit1.id] = {pos = lastKnownPosMap[unit2.id].pos, date = lastKnownPosMap[unit2.id].date}
    end
    if (lastKnownPosMap[unit2.id]== nil) and (lastKnownPosMap[unit1.id]~= nil) then
        lastKnownPosMap[unit2.id] = {pos = lastKnownPosMap[unit1.id].pos, date = lastKnownPosMap[unit1.id].date}
    end
    if (lastKnownPosMap[unit1.id]~= nil) and (lastKnownPosMap[unit2.id]~= nil) then
        if lastKnownPosMap[unit1.id].date > lastKnownPosMap[unit2.id].date then
            lastKnownPosMap[unit2.id] = {pos = lastKnownPosMap[unit1.id].pos, date = lastKnownPosMap[unit1.id].date}
        else
            lastKnownPosMap[unit1.id] = {pos = lastKnownPosMap[unit2.id].pos, date = lastKnownPosMap[unit2.id].date}
        end
    end
    return infoShared
end

function StealthManager.setLastKnownLocation(unitId, pos)
    lastKnownPosMap[unitId] = {pos = pos, date = Wargroove.getTurnNumber()}
end

function StealthManager.getWitnesses(unitId, path)
    
    local unit = Wargroove.getUnitById(unitId)
    if unit == nil then
        return {}, {}
    end
    if not StealthManager.canAlert(unit) then
        return {}, {}
    end
    if path == {} then
        return {}, {}
    end
    local newAlertedList = {}
    local newSearchersList = {}
    if #path > 1 then
        for i,tile in ipairs(path) do
            local viewerPosList = VisionTracker.getListOfViewerIds(tile);
            for viewerId, pos in pairs(viewerPosList) do
                local viewer = Wargroove.getUnitAt(pos)
                if (viewer ~= nil) and (active[viewer.playerId] ~= nil) and (viewer.health>0) then
                    if Wargroove.areEnemies(unit.playerId,viewer.playerId) then
                        if (newSearchersList[viewerId]~=nil) then
                            if i<#path then
                                newAlertedList[viewerId] = path[i+1]
                            else
                                newAlertedList[viewerId] = path[#path]
                            end
                        end
                        if (newAlertedList[viewerId]==nil) and (i~=#path) then
                            if i<#path then
                                newSearchersList[viewerId] = path[i+1]
                            else
                                newSearchersList[viewerId] = path[#path]
                            end
                        end
                    end
                end
            end
        end
    else
        local endPos = path[#path]
        if endPos ~= nil then
            local viewerPosList = VisionTracker.getListOfViewerIds(endPos);
            for viewerId, pos in pairs(viewerPosList) do
                local viewer = Wargroove.getUnitAt(pos)
                if (viewer ~= nil) and (active[viewer.playerId] ~= nil) then
                    if Wargroove.areEnemies(unit.playerId,viewer.playerId) then
                            newAlertedList[viewerId] = endPos
                    end
                end
            end
        end
    end
    return newAlertedList,newSearchersList
end

function StealthManager.awarenessCheck(unitId, path)
    local newAlertedList,newSearchersList = StealthManager.getWitnesses(unitId, path)
    for viewerId,tile in pairs(newAlertedList) do
        local viewer = Wargroove.getUnitById(viewerId)
        newSearchersList[viewerId] = nil
        if (viewer ~= nil) and (active[viewer.playerId] ~= nil) then
            lastKnownPosMap[viewerId] = {pos = tile, date = Wargroove.getTurnNumber()}
            StealthManager.makeAlerted(viewer)
            StealthManager.spreadInfo(viewer)
        end
    end
    for viewerId,tile in pairs(newSearchersList) do
        local viewer = Wargroove.getUnitById(viewerId)
        if (viewer ~= nil) and (active[viewer.playerId] ~= nil) then
            lastKnownPosMap[viewerId] = {pos = tile, date = Wargroove.getTurnNumber()}
            StealthManager.makeSearching(viewer)
        end
    end
    StealthManager.updateAwarenessAll()
end

function StealthManager.isVisuallyAlerted(unit)
    return (active[unit.playerId]~=nil) and (Wargroove.getUnitState(unit,"visual_awareness")  == "alerted")
end

function StealthManager.isVisuallyFleeing(unit)
    return (active[unit.playerId]~=nil) and (Wargroove.getUnitState(unit,"visual_awareness") == "fleeing")
end


function StealthManager.isVisuallySearching(unit)
    return (active[unit.playerId]~=nil) and (Wargroove.getUnitState(unit,"visual_awareness") == "searching")
end

function StealthManager.isVisuallyUnaware(unit)
    return (active[unit.playerId]~=nil) and (Wargroove.getUnitState(unit,"visual_awareness") == "unaware")
end

function StealthManager.isVisuallyUpdated(unit)
    local equivalentAwareness = Wargroove.getUnitState(unit,"awareness")
    if equivalentAwareness == "perma_alerted" then
        equivalentAwareness = "alerted";
    end
    local isUpdated = (Wargroove.getUnitState(unit,"visual_awareness") == equivalentAwareness)
    return isUpdated
end

function StealthManager.updateAwarenessAll()
    local units = Wargroove.getUnitsAtLocation(nil)
    local toBeUpdated = false
    for id, unit in ipairs(units) do
        toBeUpdated = not StealthManager.isVisuallyUpdated(unit) or toBeUpdated
    end
    if not toBeUpdated then
        return
    end
    local function comp(a, b)
        local sqrDistA = 1000
        local sqrDistB = 1000
        if (lastKnownPosMap[a.id] ~= nil) then
            local centerA = lastKnownPosMap[a.id].pos
            sqrDistA = (a.pos.x-centerA.x)^2+(a.pos.y-centerA.y)^2
        end
        if (lastKnownPosMap[b.id] ~= nil) then
            local centerB = lastKnownPosMap[b.id].pos
            sqrDistB = (b.pos.x-centerB.x)^2+(b.pos.y-centerB.y)^2
        end
        return sqrDistA<sqrDistB
    end
    table.sort(units, comp)
    local meanPos = {x=0,y=0}
    local count = 0
    
    for id,unit in pairs(units) do
        if not StealthManager.isVisuallyUpdated(unit) then
            meanPos.x = meanPos.x + unit.pos.x
            meanPos.y = meanPos.y + unit.pos.y
            count = count + 1
        end
    end
    if count>0 then
        meanPos.x = math.floor(0.5+meanPos.x/count);
        meanPos.y = math.floor(0.5+meanPos.y/count);
        Wargroove.trackCameraTo(meanPos)
    end
    local updated = false
    for i,unit in ipairs(units) do
        local result = StealthManager.updateFleeing(unit,false)
        updated = result or updated
        if result then
        Wargroove.waitTime(0.1)
        end
    end
    if updated then
    Wargroove.waitTime(0.3)
    end
    updated = false
    for i,unit in ipairs(units) do
        local result = StealthManager.updateAlerted(unit,false) 
        updated = result or updated
        if result then
        Wargroove.waitTime(0.1)
        end
    end
    if updated then
    Wargroove.waitTime(0.3)
    end
    updated = false
    for i,unit in ipairs(units) do
        local result = StealthManager.updateSearching(unit,false)
        updated = result or updated
        if result then
        Wargroove.waitTime(0.1)
        end
    end
    if updated then
    Wargroove.waitTime(0.3)
    end
    updated = false
    for i,unit in ipairs(units) do
        local result = StealthManager.updateUnaware(unit,false)
        updated = result or updated
        if result then
        Wargroove.waitTime(0.1)
        end
    end
    if updated then
    Wargroove.waitTime(0.3)
    end
end

function StealthManager.updateFleeing(unit, track)
    if  active[unit.playerId] == nil then
        return
    end
    if StealthManager.isUnitFleeing(unit) and not StealthManager.isVisuallyFleeing(unit) and (unit.health>0) then
        if (track~=nil) and (track == true) then
            Wargroove.trackCameraTo(unit.pos)
        end
        if lastKnownPosMap[unit.id] ~= nil then
            unit.pos.facing = getFacing(unit.pos, lastKnownPosMap[unit.id].pos)
        end
        Wargroove.updateUnit(unit)
        Wargroove.spawnPaletteSwappedMapAnimation(unit.pos, 0, "fx/fleeing_fx", unit.playerId, "default", "over_units", { x = 12, y = 0 })
        Wargroove.playMapSound("cutscene/surprised", unit.pos)
        Wargroove.setAIRestriction(unit.id, "cant_attack", true)
        Wargroove.setAIRestriction(unit.id, "cant_look_ahead", true)
        Wargroove.waitFrame()
        Wargroove.setUnitState(unit,"visual_awareness","fleeing")
        Wargroove.updateUnit(unit)
        return true
    end
    return false
end


function StealthManager.updateAlerted(unit, track)
    if  active[unit.playerId] == nil then
        return
    end
    if (StealthManager.isUnitAlerted(unit) or StealthManager.isUnitPermaAlerted(unit)) and not StealthManager.isVisuallyAlerted(unit) and (unit.health>0) then
        if (track~=nil) and (track == true) then
            Wargroove.trackCameraTo(unit.pos)
        end
        if (lastKnownPosMap[unit.id] ~= nil) and (unit.unitClass.isStructure == false) then
            unit.pos.facing = getFacing(unit.pos, lastKnownPosMap[unit.id].pos)
        end
        Wargroove.updateUnit(unit)
        Wargroove.spawnPaletteSwappedMapAnimation(unit.pos, 0, "fx/ambush_fx", unit.playerId, "default", "over_units", { x = 12, y = 0 })
        Wargroove.playMapSound("cutscene/surprised", unit.pos)
        Wargroove.setAIRestriction(unit.id, "cant_attack", false)
        Wargroove.setAIRestriction(unit.id, "cant_look_ahead", false)
        Wargroove.waitFrame()
        Wargroove.setUnitState(unit,"visual_awareness","alerted")
        Wargroove.updateUnit(unit)
        return true
    end
    return false
end

function StealthManager.updateSearching(unit, track)
    if  active[unit.playerId] == nil then
        return
    end
    if StealthManager.isUnitSearching(unit) and not StealthManager.isVisuallySearching(unit) and (unit.health>0) then
        if (track~=nil) and (track == true) then
            Wargroove.trackCameraTo(unit.pos)
        end
        if lastKnownPosMap[unit.id] ~= nil then
            unit.pos.facing = getFacing(unit.pos, lastKnownPosMap[unit.id].pos)
        end
        Wargroove.updateUnit(unit)
        Wargroove.spawnPaletteSwappedMapAnimation(unit.pos, 0, "fx/surprised_fx", unit.playerId, "default", "over_units", { x = 12, y = 0 })
        Wargroove.playMapSound("cutscene/surprised", unit.pos)
        Wargroove.setAIRestriction(unit.id, "cant_attack", true)
        Wargroove.setAIRestriction(unit.id, "cant_look_ahead", false)
        Wargroove.waitFrame()
        Wargroove.setUnitState(unit,"visual_awareness","searching")
        Wargroove.updateUnit(unit)
        return true
    end
    return false
end

function StealthManager.updateUnaware(unit,track)
    if  active[unit.playerId] == nil then
        return
    end
    if StealthManager.isUnitUnaware(unit) and not StealthManager.isVisuallyUnaware(unit) and (unit.health>0) then
        if (track~=nil) and (track == true) then
            Wargroove.trackCameraTo(unit.pos)
        end
        Wargroove.spawnPaletteSwappedMapAnimation(unit.pos, 0, "fx/gave_up_fx", unit.playerId, "default", "over_units", { x = 12, y = 0 })
        Wargroove.playMapSound("cutscene/surprised", unit.pos)
        Wargroove.setAIRestriction(unit.id, "cant_attack", true)
        Wargroove.setAIRestriction(unit.id, "cant_look_ahead", true)
        Wargroove.waitFrame()
        Wargroove.setUnitState(unit,"visual_awareness","unaware")
        Wargroove.updateUnit(unit)
        return true
    end
    return false
end

function StealthManager.updateAwareness(unitId, track)
    local unit = Wargroove.getUnitById(unitId)
    if unit == nil then
        return
    end
    if  active[unit.playerId] == nil then
        return
    end
    StealthManager.updateAlerted(unit, track)
    StealthManager.updateSearching(unit, track)
    StealthManager.updateUnaware(unit, track)
end

return StealthManager
