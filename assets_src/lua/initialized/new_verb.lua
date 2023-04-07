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
end

function Verb:executeEntry(unitId, targetPos, strParam, path)
    return Resumable.run(function ()
        Wargroove.clearCaches()
        local unit = Wargroove.getUnitById(unitId)
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
        Wargroove.setMetaLocationArea("last_move_path", path)
        Wargroove.setMetaLocation("last_unit", unit.pos)
    end)
end

return Verb
