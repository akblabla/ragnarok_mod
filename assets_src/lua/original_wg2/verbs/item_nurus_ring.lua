local Wargroove = require "wargroove/wargroove"
local ItemVerb = require "wargroove/item_verb"

local ItemNurusRing = ItemVerb:new()

ItemNurusRing.movingUnit = nil
ItemNurusRing.isInPreExecute = false

function ItemNurusRing:getMaximumRange(unit, endPos)
    return 6
end

function ItemNurusRing:getTargetType()
    if ItemNurusRing.isInPreExecute then
        return "empty"
    end

    return "all"
end

function ItemNurusRing:canExecuteWithTarget(unit, endPos, targetPos, strParam)
    if not self:canSeeTarget(targetPos) then
        return false
    end
    
    if not ItemNurusRing.isInPreExecute then
        if targetPos.x == unit.pos.x and targetPos.y == unit.pos.y then
            return true
        end

        local targetUnit = Wargroove.getUnitAt(targetPos)
        return targetUnit and not targetUnit.unitClass.isStructure
    else
        local movingUnit = Wargroove.getUnitById(ItemNurusRing.movingUnit)
        if targetPos.x == unit.pos.x and targetPos.y == unit.pos.y then
            return Wargroove.canStandAt(movingUnit.unitClassId, targetPos)
        end

        return (Wargroove.getUnitAt(targetPos) == nil) and Wargroove.canStandAt(movingUnit.unitClassId, targetPos) and (targetPos.x ~= endPos.x or targetPos.y ~= endPos.y)
    end
end

function ItemNurusRing:preExecute(unit, targetPos, strParam, endPos)
    if targetPos.x == unit.pos.x and targetPos.y == unit.pos.y then
        ItemNurusRing.movingUnit = unit.id
    else
        ItemNurusRing.movingUnit = Wargroove.getUnitAt(targetPos).id
    end

    ItemNurusRing.isInPreExecute = true

    Wargroove.selectTarget()

    while Wargroove.waitingForSelectedTarget() do
        coroutine.yield()
    end

    local destination = Wargroove.getSelectedTarget()

    if (destination == nil) then
        ItemNurusRing.isInPreExecute = false
        return false, ""
    end
    
    Wargroove.setSelectedTarget(targetPos)

    ItemNurusRing.isInPreExecute = false

    return true, ItemNurusRing.movingUnit .. ";" .. destination.x .. "," .. destination.y
end

function ItemNurusRing:parseTargets(strParam)
    local targetStrs={}
    local i = 1
    for targetStr in string.gmatch(strParam, "([^"..";".."]+)") do
        targetStrs[i] = targetStr
        i = i + 1
    end

    local targetUnitId = tonumber(targetStrs[1])

    local targetPosStr = targetStrs[2]
    local vals = {}
    for val in targetPosStr.gmatch(targetPosStr, "([^"..",".."]+)") do
        vals[#vals+1] = val
    end
    local targetTeleportPosition = { x = tonumber(vals[1]), y = tonumber(vals[2])}

    return targetUnitId, targetTeleportPosition
end

function ItemNurusRing:execute(unit, targetPos, strParam, path)
    if strParam == "" then
        print("Tornado:execute was not given any target positions.")
        return
    end

    Wargroove.playPositionlessSound("battleStart")

    local targetUnitId, teleportPosition = ItemNurusRing:parseTargets(strParam)  

    Wargroove.playUnitAnimation(unit.id, "groove")
    Wargroove.playMapSound("nuru/nuruGroove", unit.pos)
    Wargroove.waitTime(1.2)
    Wargroove.playGrooveEffect()

    local targetUnit = Wargroove.getUnitById(targetUnitId)

    Wargroove.spawnPaletteSwappedMapAnimation(targetUnit.pos, 0, "fx/groove/nuru_groove_fx", unit.playerId)
    Wargroove.playMapSound("cutscene/teleportIn", targetUnit.pos)

    Wargroove.waitTime(0.2)

    Wargroove.spawnPaletteSwappedMapAnimation(teleportPosition, 0, "fx/groove/nuru_groove_fx", unit.playerId)

    targetUnit.pos = { x = teleportPosition.x, y = teleportPosition.y }
    Wargroove.updateUnit(targetUnit)

    Wargroove.waitTime(0.5)
end

function ItemNurusRing:onPostUpdateUnit(unit, targetPos, strParam, path)
    ItemVerb.onPostUpdateUnit(self, unit, targetPos, strParam, path)

    if strParam == "" then
        print("ItemNurusRing:onPostUpdateUnit was not given any target positions.")
        return
    end

    local targetUnitId, teleportPosition = ItemNurusRing:parseTargets(strParam)
    local targetUnit = Wargroove.getUnitById(targetUnitId)

    if targetUnit.id == unit.id then
        unit.pos = teleportPosition
    end
end

return ItemNurusRing