local Wargroove = require "wargroove/wargroove"
local VisionTracker = require "initialized/vision_tracker"
local AIManager = require "initialized/ai_manager"
local Ragnarok = require "initialized/ragnarok"

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

   if math.abs(dx) > math.abs(dy) then
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
local awarenessMap = {}
local visualAwarenessMap = {}
local active = {}
local AIGoalPos = {}
local lastKnownPosMap = {}
function StealthManager.init()
    Ragnarok.addAction(StealthManager.update,"repeating",false)
end

function StealthManager.setActive(playerId,isActive)
	active[playerId] = isActive
    if isActive == false then
        active[playerId] = nil
    end
end

function StealthManager.isActive(playerId)
	return active[playerId] ~= nil
end

function StealthManager.setAIGoalPos(unitId,pos)
	AIGoalPos[unitId] = pos
end
local init = true
function StealthManager.update(context)
    if context:checkState("endOfUnitTurn") or init then
        init = false
        local units = Wargroove.getUnitsAtLocation(nil)
        for i,unit in ipairs(units) do
            StealthManager.awarenessCheck(unit.id, {unit.pos})
        end
        for unitId,pos in pairs(AIGoalPos) do
            AIManager.roadMoveOrder(unitId,pos)
        end
        for id,lastKnownPos in pairs(lastKnownPosMap) do
            local unit = Wargroove.getUnitById(id)
            if (unit ~= nil) and (not (unit.unitClassId == "villager")) then
                if StealthManager.isUnitAlerted(id) then
                    AIManager.attackMoveOrder(id,lastKnownPos.pos)
                elseif StealthManager.isUnitSearching(id) then
                    AIManager.moveOrder(id,lastKnownPos.pos)
                end
            end
        end
    end
    if context:checkState("endOfTurn") and active[Wargroove.getCurrentPlayerId()] ~= nil then
        local units = Wargroove.getUnitsAtLocation(nil)
        local cutOffEnemies = {}
        for i,unit in pairs(units) do
            if unit.playerId == Wargroove.getCurrentPlayerId() then
                cutOffEnemies[unit.id] = unit
            end
        end
        for i,unit in pairs(units) do
            if Wargroove.areEnemies(unit.playerId,Wargroove.getCurrentPlayerId()) then
                local viewerIds = VisionTracker.getListOfViewerIds(unit.pos)
                for j,viewerId in pairs(viewerIds) do
                    local viewer = Wargroove.getUnitById(viewerId)
                    if viewer ~= nil and viewer.playerId == Wargroove.getCurrentPlayerId() then
                        cutOffEnemies[viewerId] = nil
                    end
                end
            end
        end

        for i,enemy in pairs(cutOffEnemies) do
            if StealthManager.isUnitSearching(enemy.id) and lastKnownPosMap[enemy.id] ~= nil then
                if enemy.pos.x == lastKnownPosMap[enemy.id].pos.x and enemy.pos.y == lastKnownPosMap[enemy.id].pos.y then
                    lastKnownPosMap[enemy.id] = nil
                end
            end
            if StealthManager.isUnitSearching(enemy.id) and lastKnownPosMap[enemy.id] == nil then
                awarenessMap[enemy.id] = nil
            end
            local unit = Wargroove.getUnitById(enemy.id)
            if StealthManager.isUnitAlerted(enemy.id) then
                StealthManager.makeSearching(enemy.id, true)
            end
        end
        for unitId,awareness in pairs(awarenessMap) do
            local unit = Wargroove.getUnitById(unitId)
            if unit ~= nil then
                if StealthManager.isUnitFleeing(unitId) then
                    local listOfViewerIds = VisionTracker.getListOfViewerIds(unit.pos);
                    for j, viewerId in pairs(listOfViewerIds) do
                        local viewer = Wargroove.getUnitById(viewerId)
                        if viewer ~= nil and active[viewer.playerId] ~= nil then
                            if unit.playerId == viewer.playerId then
                                StealthManager.makeSearching(viewerId)
                                StealthManager.shareInfo(unitId, viewerId)
                            end
                        end
                    end
                end
            end
        end
        StealthManager.updateAwarenessAll()
    end
end

function StealthManager.isUnitAlerted(unitId)
    return (awarenessMap[unitId] ~= nil) and (awarenessMap[unitId] == "alerted")
end

function StealthManager.isUnitFleeing(unitId)
    return (awarenessMap[unitId] ~= nil) and (awarenessMap[unitId] == "fleeing")
end

function StealthManager.makeAlerted(unitId)
    local unit = Wargroove.getUnitById(unitId)
    if unit ~= nil then
        if unit.unitClassId == "villager" then
            awarenessMap[unitId] = "fleeing"
        else
            awarenessMap[unitId] = "alerted"
            local listOfViewerIds = VisionTracker.getListOfViewerIds(unit.pos);
            for j, viewerId in pairs(listOfViewerIds) do
                local viewer = Wargroove.getUnitById(viewerId)
                if viewer ~= nil and active[viewer.playerId] ~= nil then
                    if unit.playerId == viewer.playerId then
                        StealthManager.shareInfo(unitId, viewerId)
                    end
                end
            end
        end
    end
end

function StealthManager.isUnitSearching(unitId)
    return (awarenessMap[unitId] ~= nil) and (awarenessMap[unitId] == "searching")
end

function StealthManager.makeSearching(unitId, force)
    if ((awarenessMap[unitId] ~= "alerted") and (awarenessMap[unitId] ~= "fleeing")) or (force == true) then
        awarenessMap[unitId] = "searching"
    end
end

function StealthManager.isUnitUnaware(unitId)
    return awarenessMap[unitId] == nil
end

function StealthManager.shareInfo(unitId1, unitId2)
    if StealthManager.isUnitAlerted(unitId1) then
        StealthManager.makeSearching(unitId2)
    end
    if StealthManager.isUnitAlerted(unitId2) then
        StealthManager.makeSearching(unitId1)
    end
    if (lastKnownPosMap[unitId1]== nil) and (lastKnownPosMap[unitId2]~= nil) then
        lastKnownPosMap[unitId1] = {pos = lastKnownPosMap[unitId2].pos, date = lastKnownPosMap[unitId2].date}
    end
    if (lastKnownPosMap[unitId2]== nil) and (lastKnownPosMap[unitId1]~= nil) then
        lastKnownPosMap[unitId2] = {pos = lastKnownPosMap[unitId1].pos, date = lastKnownPosMap[unitId1].date}
    end
    if (lastKnownPosMap[unitId1]~= nil) and (lastKnownPosMap[unitId2]~= nil) then
        if lastKnownPosMap[unitId1].date > lastKnownPosMap[unitId2].date then
            lastKnownPosMap[unitId2] = {pos = lastKnownPosMap[unitId1].pos, date = lastKnownPosMap[unitId1].date}
        else
            lastKnownPosMap[unitId1] = {pos = lastKnownPosMap[unitId2].pos, date = lastKnownPosMap[unitId2].date}
        end
    end
end

function StealthManager.getWitnesses(unitId, path)
    local unit = Wargroove.getUnitById(unitId)
    if unit == nil then
        return
    end
    local newAlertedList = {}
    local newSearchersList = {}
    if #path > 1 then
        for i,tile in ipairs(path) do
            local listOfViewerIds = VisionTracker.getListOfViewerIds(tile);
            for j, viewerId in pairs(listOfViewerIds) do
                local viewer = Wargroove.getUnitById(viewerId)
                if viewer ~= nil and active[viewer.playerId] ~= nil then
                    if Wargroove.areEnemies(unit.playerId,viewer.playerId) then
                        if (newSearchersList[viewerId]~=nil) then
                            if i<#path then
                                newAlertedList[viewerId] = path[i+1]
                            else
                                newAlertedList[viewerId] = path[#path]
                            end
                        end
                        if newAlertedList[viewerId]==nil and i~=#path then
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
            local listOfViewerIds = VisionTracker.getListOfViewerIds(endPos);
            for j, viewerId in pairs(listOfViewerIds) do
                local viewer = Wargroove.getUnitById(viewerId)
                if viewer ~= nil and active[viewer.playerId] ~= nil then
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
        if viewer ~= nil and active[viewer.playerId] ~= nil then
            lastKnownPosMap[viewerId] = {pos = tile, date = Wargroove.getTurnNumber()}
            StealthManager.makeAlerted(viewerId)
        end
    end
    for viewerId,tile in pairs(newSearchersList) do
        local viewer = Wargroove.getUnitById(viewerId)
        if viewer ~= nil and active[viewer.playerId] ~= nil then
            lastKnownPosMap[viewerId] = {pos = tile, date = Wargroove.getTurnNumber()}
            StealthManager.makeSearching(viewerId)
        end
    end
    StealthManager.updateAwarenessAll()
end

function StealthManager.isVisuallyAlerted(unitId)
    return visualAwarenessMap[unitId] ~= nil and visualAwarenessMap[unitId] == "alerted"
end

function StealthManager.isVisuallyFleeing(unitId)
    return visualAwarenessMap[unitId] ~= nil and visualAwarenessMap[unitId] == "fleeing"
end


function StealthManager.isVisuallySearching(unitId)
    return visualAwarenessMap[unitId] ~= nil and visualAwarenessMap[unitId] == "searching"
end

function StealthManager.updateAwarenessAll()
    local units = Wargroove.getUnitsAtLocation(nil)
    local updated = false
    for i,unit in ipairs(units) do
        updated = StealthManager.updateFleeing(unit.id) or updated
    end
    if updated then
    Wargroove.waitTime(0.2)
    end
    updated = false
    for i,unit in ipairs(units) do
        updated = StealthManager.updateAlerted(unit.id) or updated
    end
    if updated then
    Wargroove.waitTime(0.2)
    end
    updated = false
    for i,unit in ipairs(units) do
        updated = StealthManager.updateSearching(unit.id) or updated
    end
    if updated then
    Wargroove.waitTime(0.2)
    end
    updated = false
    for i,unit in ipairs(units) do
        updated = StealthManager.updateUnaware(unit.id) or updated
    end
    if updated then
    Wargroove.waitTime(0.2)
    end
end

function StealthManager.updateFleeing(unitId)
    local unit = Wargroove.getUnitById(unitId)
    if unit == nil then
        return
    end
    if  active[unit.playerId] == nil then
        return
    end
    if StealthManager.isUnitFleeing(unitId) and not StealthManager.isVisuallyFleeing(unitId) then
        Wargroove.trackCameraTo(unit.pos)
        if lastKnownPosMap[unitId] ~= nil then
            unit.pos.facing = getFacing(unit.pos, lastKnownPosMap[unitId].pos)
        end
        Wargroove.updateUnit(unit)
        Wargroove.spawnPaletteSwappedMapAnimation(unit.pos, 0, "fx/ambush_fx", unit.playerId, "default", "over_units", { x = 12, y = 0 })
        Wargroove.playMapSound("cutscene/surprised", unit.pos)
        Wargroove.setAIRestriction(unitId, "cant_attack", true)
        Wargroove.setAIRestriction(unitId, "cant_look_ahead", true)
        Wargroove.waitTime(0.2)
        Wargroove.updateUnit(unit)
        visualAwarenessMap[unitId] = "fleeing"
        return true
    end
    return false
end


function StealthManager.updateAlerted(unitId)
    local unit = Wargroove.getUnitById(unitId)
    if unit == nil then
        return
    end
    if  active[unit.playerId] == nil then
        return
    end
    if StealthManager.isUnitAlerted(unitId) and not StealthManager.isVisuallyAlerted(unitId) then
        Wargroove.trackCameraTo(unit.pos)
        if lastKnownPosMap[unitId] ~= nil then
            unit.pos.facing = getFacing(unit.pos, lastKnownPosMap[unitId].pos)
        end
        Wargroove.updateUnit(unit)
        Wargroove.spawnPaletteSwappedMapAnimation(unit.pos, 0, "fx/ambush_fx", unit.playerId, "default", "over_units", { x = 12, y = 0 })
        Wargroove.playMapSound("cutscene/surprised", unit.pos)
        Wargroove.setAIRestriction(unitId, "cant_attack", false)
        Wargroove.setAIRestriction(unitId, "cant_look_ahead", false)
        Wargroove.waitTime(0.2)
        Wargroove.updateUnit(unit)
        visualAwarenessMap[unitId] = "alerted"
        return true
    end
    return false
end

function StealthManager.updateSearching(unitId)
    local unit = Wargroove.getUnitById(unitId)
    if unit == nil then
        return
    end
    if  active[unit.playerId] == nil then
        return
    end
    if StealthManager.isUnitSearching(unitId) and not StealthManager.isVisuallySearching(unitId) then
        Wargroove.trackCameraTo(unit.pos)
        if lastKnownPosMap[unitId] ~= nil then
            unit.pos.facing = getFacing(unit.pos, lastKnownPosMap[unitId].pos)
        end
        Wargroove.updateUnit(unit)
        Wargroove.spawnPaletteSwappedMapAnimation(unit.pos, 0, "fx/surprised_fx", unit.playerId, "default", "over_units", { x = 12, y = 0 })
        Wargroove.playMapSound("cutscene/surprised", unit.pos)
        Wargroove.setAIRestriction(unitId, "cant_attack", true)
        Wargroove.setAIRestriction(unitId, "cant_look_ahead", false)
        Wargroove.waitTime(0.2)
        Wargroove.updateUnit(unit)
        visualAwarenessMap[unitId] = "searching"
        return true
    end
    return false
end

function StealthManager.updateUnaware(unitId)
    local unit = Wargroove.getUnitById(unitId)
    if unit == nil then
        return
    end
    if  active[unit.playerId] == nil then
        return
    end
    if StealthManager.isUnitUnaware(unitId) and visualAwarenessMap[unitId] ~= nil then
        Wargroove.trackCameraTo(unit.pos)
        Wargroove.spawnPaletteSwappedMapAnimation(unit.pos, 0, "fx/gave_up_fx", unit.playerId, "default", "over_units", { x = 12, y = 0 })
        Wargroove.playMapSound("cutscene/surprised", unit.pos)
        Wargroove.setAIRestriction(unitId, "cant_attack", true)
        Wargroove.setAIRestriction(unitId, "cant_look_ahead", true)
        Wargroove.waitTime(0.2)
        Wargroove.updateUnit(unit)
        visualAwarenessMap[unitId] = nil
        return true
    end
    return false
end

function StealthManager.updateAwareness(unitId)
    local unit = Wargroove.getUnitById(unitId)
    if unit == nil then
        return
    end
    if  active[unit.playerId] == nil then
        return
    end
    StealthManager.updateAlerted(unitId)
    StealthManager.updateSearching(unitId)
    StealthManager.updateUnaware(unitId)
end

return StealthManager
