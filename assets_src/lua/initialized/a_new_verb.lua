local Wargroove = require "wargroove/wargroove"
local OldVerb = require "wargroove/verb"
local Combat = require "wargroove/combat"
local Resumable = require "wargroove/resumable"
local VisionTracker = require "initialized/vision_tracker"
local AIManager = require "initialized/ai_manager"
local StealthManager = require "scripts/stealth_manager"
local PosKey = require "util/posKey"
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
    OldVerb.canExecuteAt = Verb.canExecuteAt
    OldVerb.executeEntry = Verb.executeEntry
    OldVerb.generateOrders = Verb.generateOrders
end
local borderLandPlayerList = {}
function Verb.setBorderLands(location, playerId)
    borderLandPlayerList[playerId] = {}
    for i, tile in pairs(location.positions) do
        borderLandPlayerList[playerId][PosKey.generatePosKey(tile)] = true
    end 
end
function Verb.inInBorderlands(pos, playerId)
    if borderLandPlayerList[playerId]~=nil then
        if borderLandPlayerList[playerId][PosKey.generatePosKey(pos)]~=nil then
            return true
        end
    end
    return false
end
function Verb:canExecuteAt(unit, endPos)
    if Verb.inInBorderlands(endPos, unit.playerId) then
        return false
    end
    return (not Wargroove.canPlayerSeeTile(-1, endPos)) or (not Wargroove.isAnybodyElseAt(unit, endPos))
end

function Verb:executeEntry(unitId, targetPos, strParam, path)
    return Resumable.run(function ()
        Wargroove.clearCaches()
        local unit = Wargroove.getUnitById(unitId)
        local preMovePos = {x = unit.pos.x, y = unit.pos.y}
        StealthManager.awarenessCheck(unit, path)
        self:execute(unit, targetPos, strParam, path)
        self:updateSelfUnit(unit, targetPos, path)
        self:onPostUpdateUnit(unit, targetPos, strParam, path)
        Wargroove.updateUnit(unit)
        local next,distMoved,dist = AIManager.getNextPosition(unitId)
        if (dist == nil) or (dist <= 1) then
            AIManager.clearOrder(unitId)
        end
        StealthManager.awarenessCheck(unit, {path[#path]})
        local tiles = VisionTracker.calculateVisionOfUnit(unit)
        for i,tile in pairs(tiles) do
            local otherUnit = Wargroove.getUnitAt(tile)
            if (otherUnit~=nil) and (StealthManager.canAlert(otherUnit)) and Wargroove.areEnemies(unit.playerId,otherUnit.playerId) then
                StealthManager.makeAlerted(unit)
                break
            end
        end
        -- if StealthManager.isUnitAlerted(unit) then
        --     local viewers = VisionTracker.getListOfViewerIds(preMovePos)
        --     for i,viewerId in pairs(viewers) do
        --         local viewer = Wargroove.getUnitById(viewerId)
        --         if (viewer ~= nil) and (viewer.playerId == unit.playerId) then
        --             local dist = math.abs(viewer.pos.x-unit.pos.x)+math.abs(viewer.pos.y-unit.pos.y)
        --             if dist <=2 then
        --                 StealthManager.shareInfo(unit,viewer)
        --             end
        --         end
        --     end
        -- end
        StealthManager.updateAwarenessAll()
        Wargroove.setMetaLocationArea("last_move_path", path)
        Wargroove.setMetaLocation("last_unit", unit.pos)
    end)
end

function Verb:generateOrders(unitId, canMove)
    return {}
end

return Verb
