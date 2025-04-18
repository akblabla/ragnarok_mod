local Wargroove = require "wargroove/wargroove"
local Verb = require "wargroove/verb"

local Recruit = Verb:new()


function Recruit:getMaximumRange(unit, endPos)
    return 1
end


function Recruit:getTargetType()
    return "empty"
end


function Recruit:canExecuteWithTarget(unit, endPos, targetPos, strParam)
    if strParam == nil or strParam == "" then
        return true
    end

    -- Check if this can recruit that type of unit
    local ok = false
    for i, uid in ipairs(unit.recruits) do
        if uid == strParam then
            ok = true
        end
    end
    if not ok then
        return false
    end

    -- Check if this player can recruit this type of unit
    if not Wargroove.canPlayerRecruit(unit.playerId, strParam) then
        return false
    end

    local uc = Wargroove.getUnitClass(strParam)
    return Wargroove.canStandAt(strParam, targetPos) and Wargroove.getMoney(unit.playerId) >= uc.cost
end


function Recruit:execute(unit, targetPos, strParam, path)
    local uc = Wargroove.getUnitClass(strParam)
    Wargroove.changeMoney(unit.playerId, -uc.cost)
    Wargroove.spawnUnit(unit.playerId, targetPos, strParam, true)
    if Wargroove.canCurrentlySeeTile(targetPos) then
        Wargroove.spawnMapAnimation(targetPos, 0, "fx/mapeditor_unitdrop")
        Wargroove.playMapSound("spawn", targetPos)
        Wargroove.playPositionlessSound("recruit")
    end
    Wargroove.notifyEvent("unit_recruit", unit.playerId)
    Wargroove.setMetaLocation("last_recruit", targetPos)
end


return Recruit
