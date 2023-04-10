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

function StealthManager.update(context)
    if context:checkState("endOfUnitTurn") then
        local units = Wargroove.getUnitsAtLocation(nil)
        for i,unit in ipairs(units) do
            StealthManager.awarenessCheck(unit.id, {unit.pos})
        end
        for unitId,pos in pairs(AIGoalPos) do
            if active[Wargroove.getCurrentPlayerId()] ~= nil then
                AIManager.roadMoveOrder(unitId,pos)
            end
        end
        for id,awareness in pairs(awarenessMap) do
            if active[Wargroove.getCurrentPlayerId()] ~= nil then
                if awareness.alerted == false then
                    AIManager.moveOrder(id,awareness.src)
                elseif awareness.alerted == true then
                    AIManager.attackMoveOrder(id,awareness.src)
                end
            end
        end
    end
    if context:checkState("endOfTurn") and active[Wargroove.getCurrentPlayerId()] ~= nil then
        local units = Wargroove.getUnitsAtLocation(nil)
        local cutOffEnemies = {}
        for i,unit in pairs(units) do
            if Wargroove.getCurrentPlayerId() then
                cutOffEnemies[unit.id] = unit
            end
        end
        for i,unit in pairs(units) do
            if Wargroove.areEnemies(unit.playerId,Wargroove.getCurrentPlayerId()) then
                local viewerIds = VisionTracker.getListOfViewerIds(unit.pos)
                for j,viewerId in pairs(viewerIds) do
                    local viewer = Wargroove.getUnitById(viewerId)
                    if viewer ~= nil and viewer.playerId == 1 then
                        cutOffEnemies[viewerId] = nil
                    end
                end
            end
        end

        for i,enemy in pairs(cutOffEnemies) do
            if awarenessMap[enemy.id] ~= nil and awarenessMap[enemy.id].alerted == false then
                awarenessMap[enemy.id] = nil
            end
            if awarenessMap[enemy.id] ~= nil and awarenessMap[enemy.id].alerted == true then
                StealthManager.makeUnitSearching(enemy.id,awarenessMap[enemy.id].tile, true)
            end
            StealthManager.updateAwareness(enemy.id)
        end
    end
end

function StealthManager.makeUnitAlerted(unitId,tile)
    awarenessMap[unitId] = {alerted = true,src = tile}
end

function StealthManager.isUnitAlerted(unitId)
    return awarenessMap[unitId] ~= nil and awarenessMap[unitId].alerted
end

function StealthManager.makeUnitSearching(unitId,tile, force)
    if force then
        awarenessMap[unitId] = {alerted = false,src = tile}
    elseif awarenessMap[unitId] == nil or (awarenessMap[unitId] ~= nil and awarenessMap[unitId].alerted == false) then
        awarenessMap[unitId] = {alerted = false,src = tile}
    end
end

function StealthManager.isUnitSearching(unitId)
    return awarenessMap[unitId] ~= nil
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
                            newAlertedList[viewerId] = endPos;
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
            StealthManager.makeUnitAlerted(viewerId,tile)
        end
    end
    for viewerId,tile in pairs(newSearchersList) do
        local viewer = Wargroove.getUnitById(viewerId)
        if viewer ~= nil and active[viewer.playerId] ~= nil then
            StealthManager.makeUnitSearching(viewerId,tile)
        end
    end
    for viewerId,tile in pairs(newAlertedList) do
        local viewer = Wargroove.getUnitById(viewerId)
        if viewer ~= nil and active[viewer.playerId] ~= nil then
            StealthManager.updateAwareness(viewerId)
        end
    end
    for viewerId,tile in pairs(newSearchersList) do
        local viewer = Wargroove.getUnitById(viewerId)
        if viewer ~= nil and active[viewer.playerId] ~= nil then
            StealthManager.updateAwareness(viewerId)
        end
    end
end

function StealthManager.updateAwareness(unitId)
    local unit = Wargroove.getUnitById(unitId)
    if unit == nil then
        return
    end
    if  active[unit.playerId] == nil then
        return
    end
    local pair = awarenessMap[unitId]
    if pair ~= nil and pair.alerted == true and not (visualAwarenessMap[unitId] ~= nil and visualAwarenessMap[unitId].alerted == true) then
        if pair.pos ~= nil then
            unit.pos.facing = getFacing(unit.pos, pair.pos)
        end
        Wargroove.updateUnit(unit)
        Wargroove.spawnPaletteSwappedMapAnimation(unit.pos, 0, "fx/ambush_fx", unit.playerId, "default", "over_units", { x = 12, y = 0 })
        Wargroove.playMapSound("cutscene/surprised", unit.pos)
        Wargroove.setAIRestriction(unitId, "cant_attack", false)
        Wargroove.waitTime(0.5)
        Wargroove.updateUnit(unit)
        visualAwarenessMap[unitId] = {alerted = true}
    end
    if pair ~= nil and pair.alerted == false and not (visualAwarenessMap[unitId] ~= nil and visualAwarenessMap[unitId].alerted == false) then
        if pair.pos ~= nil then
            unit.pos.facing = getFacing(unit.pos, pair.pos)
        end
        Wargroove.updateUnit(unit)
        Wargroove.spawnPaletteSwappedMapAnimation(unit.pos, 0, "fx/surprised_fx", unit.playerId, "default", "over_units", { x = 12, y = 0 })
        Wargroove.playMapSound("cutscene/surprised", unit.pos)
        Wargroove.setAIRestriction(unitId, "cant_attack", true)
        Wargroove.waitTime(0.5)
        Wargroove.updateUnit(unit)
        visualAwarenessMap[unitId] = {alerted = false}
    end
    if pair == nil and not visualAwarenessMap[unitId] == nil then
        Wargroove.spawnPaletteSwappedMapAnimation(unit.pos, 0, "fx/gave_up_fx", unit.playerId, "default", "over_units", { x = 12, y = 0 })
        Wargroove.playMapSound("cutscene/surprised", unit.pos)
        Wargroove.setAIRestriction(unitId, "cant_attack", true)
        Wargroove.waitTime(0.5)
        Wargroove.updateUnit(unit)
        visualAwarenessMap[unitId] = nil
    end
end

return StealthManager
