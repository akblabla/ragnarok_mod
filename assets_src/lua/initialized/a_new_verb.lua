local Wargroove = require "wargroove/wargroove"
local OldVerb = require "wargroove/verb"
local Combat = require "wargroove/combat"
local Resumable = require "wargroove/resumable"
local VisionTracker = require "initialized/vision_tracker"
local AIManager = require "initialized/ai_manager"
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
    OldVerb.executeEntry = Verb.executeEntry
    OldVerb.generateOrders = Verb.generateOrders
end
local nextNumber = 1
local function printNextNumber()
    print(nextNumber)
    nextNumber = nextNumber +1
end
function Verb:executeEntry(unitId, targetPos, strParam, path)
    return Resumable.run(function ()
        nextNumber = 1
        Wargroove.clearCaches()
        print("Verb:executeEntry(unitId, targetPos, strParam, path)")
        local unit = Wargroove.getUnitById(unitId)
        printNextNumber()
        local preMovePos = {x = unit.pos.x, y = unit.pos.y}
        printNextNumber()
        StealthManager.awarenessCheck(unitId, path)
        printNextNumber()
        self:execute(unit, targetPos, strParam, path)
        printNextNumber()
        self:updateSelfUnit(unit, targetPos, path)
        printNextNumber()
        self:onPostUpdateUnit(unit, targetPos, strParam, path)
        printNextNumber()
        Wargroove.updateUnit(unit)
        printNextNumber()
        local next,_ = AIManager.getNextPosition(unitId)
        printNextNumber()
        if next == nil then
            AIManager.clearOrder(unitId)
        elseif next.x == unit.pos.x and next.y == unit.pos.y then
            AIManager.clearOrder(unitId)
        end
        printNextNumber()
        StealthManager.awarenessCheck(unitId, {path[#path]})
        printNextNumber()
        local tiles = VisionTracker.calculateVisionOfUnit(unit)
        printNextNumber()
        for i,tile in pairs(tiles) do
            local otherUnit = Wargroove.getUnitAt(tile)
            if (otherUnit~=nil) and (StealthManager.canAlert(otherUnit)) and Wargroove.areEnemies(unit.playerId,otherUnit.playerId) then
                StealthManager.makeAlerted(unit)
                break
            end
        end
        printNextNumber()
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
        printNextNumber()
        Wargroove.setMetaLocationArea("last_move_path", path)
        printNextNumber()
        Wargroove.setMetaLocation("last_unit", unit.pos)
        printNextNumber()
    end)
end

function Verb:generateOrders(unitId, canMove)
    return {}
end

return Verb
