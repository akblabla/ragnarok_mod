local Wargroove = require "wargroove/wargroove"
local OldVerb = require "wargroove/verb"
local Resumable = require "wargroove/resumable"
local VisionTracker = require "initialized/vision_tracker"
local AIManager = require "initialized/ai_manager"
local Pathfinding = require "util/pathfinding"
local StealthManager = require "scripts/stealth_manager"
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

local Verb = {}
function Verb.init()
    OldVerb.doExecuteEntry = Verb.doExecuteEntry
    OldVerb.canExecute = Verb.canExecute
end

function Verb:canExecute(unit, endPos, targetPos, strParam)
    if not self:canExecuteAnywhere(unit) then
        return false
    end

    if not self:canExecuteAt(unit, endPos) then
        return false
    end

    if self:getTargetType() ~= nil then
        -- If no target is specified, check if there's any valid target.
        if targetPos == nil then
            return self:canExecuteWithAnyTarget(unit, endPos, strParam)
        else
            return self:isInRange(unit, endPos, targetPos) and self:canExecuteWithTarget(unit, endPos, targetPos, strParam)
        end
    else
        return true
    end
end

function Verb:doExecuteEntry(unitId, verb, isGrooveVerb, targetPos, strParam, path, usesTurn, telegraph)
    return Resumable.run(function ()
        print("Verb:doExecuteEntry start")
        Wargroove.clearCaches()
        local unit = Wargroove.getUnitById(unitId)
        local preMovePos = unit.pos
        if next(path) ~= nil then
            preMovePos = path[1]
        end
        StealthManager.awarenessCheck(unit, path)
        self:execute(unit, targetPos, strParam, path, telegraph)

        unit = Wargroove.getUnitById(unitId)

        -- Give post verb scripts an opportunity to do something before self-update
        Wargroove.doPostVerb(unitId, verb)
        
        -- Unit may have been invalidated in pre combat/post verb, so we get it again
        unit = Wargroove.getUnitById(unitId)

        self:updateSelfUnit(unit, targetPos, path, usesTurn)
        self:onPostUpdateUnit(unit, targetPos, strParam, path)
        Wargroove.updateUnit(unit)
        local next,distMoved,dist = AIManager.getNextPosition(unitId)
        Pathfinding.clearCaches()
        if (dist == nil) or (dist <= 1) then
            AIManager.clearOrder(unitId)
        end
        StealthManager.awarenessCheck(unit, {path[#path]})
        if StealthManager.isActive(unit.playerId) then
            local tiles = VisionTracker.calculateVisionOfUnit(unit)
            for i,tile in pairs(tiles) do
                local otherUnit = Wargroove.getUnitAt(tile)
                if (otherUnit~=nil) and (StealthManager.canAlert(otherUnit)) and Wargroove.areEnemies(unit.playerId,otherUnit.playerId) then
                    StealthManager.makeAlerted(unit)
                    StealthManager.setLastKnownLocation(unit,otherUnit.pos)
                    break
                end
            end
            if StealthManager.isUnitAlerted(unit) then
                local viewers = VisionTracker.getListOfViewerIds(preMovePos)
                for viewerId,pos in pairs(viewers) do
                    local viewer = Wargroove.getUnitById(viewerId)
                    if (viewer ~= nil) and (viewer.playerId == unit.playerId) then
                        local dist = math.abs(viewer.pos.x-preMovePos.x)+math.abs(viewer.pos.y-preMovePos.y)
                        if dist <=2 then
                            --if StealthManager.isUnitSearching(viewer) then
                                StealthManager.makeAlerted(viewer)
                                StealthManager.shareInfo(unit,viewer)
                            --end
                            --StealthManager.makeSearching(viewer)
                            --StealthManager.shareInfo(unit,viewer)
                        end
                    end
                end
            end
        end
        StealthManager.updateAwarenessAll()
        if self:shouldSetMetaLocations() then
            Wargroove.setMetaLocationArea("last_move_path", path)
            Wargroove.setMetaLocation("last_unit", unit.pos)
        end

        -- Remember the verb use
        Wargroove.reportVerbUsed(unitId, verb, isGrooveVerb, targetPos, strParam, path)
        --Events.checkEventsAfter()
        print("Verb:doExecuteEntry end")
    end)
end

function Verb:generateOrders(unitId, canMove)
    return {}
end

return Verb
