local Wargroove = require "wargroove/wargroove"
local OldVerb = require "wargroove/verb"
local Combat = require "wargroove/combat"
local Resumable = require "wargroove/resumable"
local VisionTracker = require "initialized/vision_tracker"
local AIManager = require "initialized/ai_manager"


local Verb = {}
function Verb.init()
    OldVerb.executeEntry = Verb.executeEntry
--    OldVerb.canExecuteAt = Verb.canExecuteAt
end

local function awarenessCheck(unitId, path)
    local unit = Wargroove.getUnitById(unitId)
    local newAlertedList = {}
    local newSearchersList = {}
    if unit.playerId == 0 then
        for g,tile in ipairs(path) do
            local listOfViewerIds = VisionTracker.getListOfViewerIds(tile);
            for j, viewerId in pairs(listOfViewerIds) do
                local viewer = Wargroove.getUnitById(viewerId)
                if (viewer ~= nil) then
                    if (viewer.playerId == 1) then
                        if (Wargroove.hasAIRestriction(viewerId, "cant_move") == false and Wargroove.hasAIRestriction(viewerId, "cant_attack") == true or newSearchersList[viewerId]~=nil) then
                            newAlertedList[viewerId] = tile;
                            newSearchersList[viewerId] = nil;
                        end
                        if (Wargroove.hasAIRestriction(viewerId, "cant_move") == false and Wargroove.hasAIRestriction(viewerId, "cant_attack") == true and g == #path) then
                            newAlertedList[viewerId] = tile;
                            newSearchersList[viewerId] = nil;
                        end
                        if (Wargroove.hasAIRestriction(viewerId, "cant_move") ~= false and newAlertedList[viewerId]==nil) then
                            newSearchersList[viewerId] = tile;
                        end
                    end
                end
            end
        end
    end
    for viewerId,tile in pairs(newAlertedList) do
        local viewer = Wargroove.getUnitById(viewerId)
        if (tile.x>viewer.pos.x) then
            Wargroove.setFacingOverride(viewerId, "right")
        else
            Wargroove.setFacingOverride(viewerId, "left")
        end
        Wargroove.updateUnit(viewer)
        Wargroove.spawnPaletteSwappedMapAnimation(viewer.pos, 0, "fx/ambush_fx", viewer.playerId, "default", "over_units", { x = 12, y = 0 })
        Wargroove.playMapSound("cutscene/surprised", viewer.pos)
        Wargroove.waitTime(0.5)
        Wargroove.setAIRestriction(viewerId, "cant_move", false)
        Wargroove.setAIRestriction(viewerId, "cant_attack", false)
        Wargroove.updateUnit(viewer)
    end
    for viewerId,tile in pairs(newSearchersList) do
        local viewer = Wargroove.getUnitById(viewerId)
        newAlertedList[viewerId] = tile;
        if (tile.x>viewer.pos.x) then
            Wargroove.setFacingOverride(viewerId, "right")
        else
            Wargroove.setFacingOverride(viewerId, "left")
        end
        Wargroove.updateUnit(viewer)
        Wargroove.spawnPaletteSwappedMapAnimation(viewer.pos, 0, "fx/surprised_fx", viewer.playerId, "default", "over_units", { x = 12, y = 0 })
        Wargroove.playMapSound("cutscene/surprised", viewer.pos)
        Wargroove.waitTime(0.5)
        Wargroove.setAIRestriction(viewerId, "cant_move", false)
        Wargroove.updateUnit(viewer)
    end
end

function Verb:executeEntry(unitId, targetPos, strParam, path)
    return Resumable.run(function ()
        Wargroove.clearCaches()
        local unit = Wargroove.getUnitById(unitId)
        awarenessCheck(unitId, path)
        self:execute(unit, targetPos, strParam, path)
        self:updateSelfUnit(unit, targetPos, path)
        self:onPostUpdateUnit(unit, targetPos, strParam, path)
        Wargroove.updateUnit(unit)

        Wargroove.setMetaLocationArea("last_move_path", path)
        Wargroove.setMetaLocation("last_unit", unit.pos)
    end)
end

function Verb:canExecuteAt(unit, endPos)

    print("Verb:canExecuteEntry")
    local target = AIManager.getAITarget(unit.id)
    if (target ~= nil) then
        print("Found the target")
        if target.x == endPos.x and target.y == endPos.y then
            return true
        else
            return false
        end
    end
    return false
end

function Verb:getScore(unitId, order)
    local unit = Wargroove.getUnitById(unitId)
    print("Verb:getScore")
    local target = AIManager.getAITarget(unitId)
    if (target ~= nil) then
        print("Found the target")
        if target.x == order.endPosition.x and target.y == order.endPosition.y then
            return {score = 1000, introspection = {}}
        else
            return {score = -1, introspection = {}}
        end
    end
    print("getScore not implemented for verb.")
    return {score = -1, introspection = {}}
end

return Verb
