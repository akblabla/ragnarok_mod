local Wargroove = require "wargroove/wargroove"
local OldVerb = require "wargroove/verb"
local Combat = require "wargroove/combat"
local Resumable = require "wargroove/resumable"
local VisionTracker = require "initialized/vision_tracker"
local AIManager = require "initialized/ai_manager"
local StealthManager = require "initialized/stealth_manager"

local Verb = {}
function Verb.init()
    OldVerb.executeEntry = Verb.executeEntry
    OldVerb.generateOrders = Verb.generateOrders
end

function Verb:executeEntry(unitId, targetPos, strParam, path)
    return Resumable.run(function ()
        Wargroove.clearCaches()
        local unit = Wargroove.getUnitById(unitId)
        local preMovePos = {x = unit.pos.x, y = unit.pos.y}
        StealthManager.awarenessCheck(unitId, path)
        self:execute(unit, targetPos, strParam, path)
        self:updateSelfUnit(unit, targetPos, path)
        self:onPostUpdateUnit(unit, targetPos, strParam, path)
        Wargroove.updateUnit(unit)
        local next,_ = AIManager.getNextPosition(unitId)
        if next == nil then
            AIManager.clearOrder(unitId)
        elseif next.x == unit.pos.x and next.y == unit.pos.y then
            AIManager.clearOrder(unitId)
        end
        StealthManager.awarenessCheck(unitId, {path[#path]})
        local tiles = VisionTracker.calculateVisionOfUnit(unit)
        for i,tile in pairs(tiles) do
            local otherUnit = Wargroove.getUnitAt(tile)
            if (otherUnit~=nil) and Wargroove.areEnemies(unit.playerId,otherUnit.playerId) then
                StealthManager.makeAlerted(unitId)
            end
        end
        local viewers = VisionTracker.getListOfViewerIds(preMovePos)
        for i,viewerId in pairs(viewers) do
            StealthManager.shareInfo(unitId,viewerId)
        end
        StealthManager.updateAwarenessAll()
        Wargroove.setMetaLocationArea("last_move_path", path)
        Wargroove.setMetaLocation("last_unit", unit.pos)
    end)
end

function Verb:generateOrders(unitId, canMove)
    return {}
end

return Verb
