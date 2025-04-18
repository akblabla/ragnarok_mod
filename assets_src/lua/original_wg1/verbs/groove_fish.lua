local Wargroove = require "wargroove/wargroove"
local Combat = require "wargroove/combat"
local GrooveVerb = require "wargroove/groove_verb"

local Fish = GrooveVerb:new()


function Fish:getMaximumRange(unit, endPos)
    return 1
end


function Fish:getTargetType()
    return "empty"
end


function Fish:canExecuteWithTarget(unit, endPos, targetPos, strParam)
    if not self:canSeeTarget(targetPos) then
        return false
    end

    if (Wargroove.getUnitAt(targetPos) ~= nil) then
        return false
    end

    local terrainName = Wargroove.getTerrainNameAt(targetPos)
    return terrainName == "beach" or terrainName == "ocean" or terrainName == "reef" or terrainName == "river" or terrainName == "sea"
end

function Fish:preExecute(unit, targetPos, strParam, endPos)
    return true, Wargroove.chooseFish(targetPos)
end

function Fish:execute(unit, targetPos, strParam, path)
    Wargroove.setIsUsingGroove(unit.id, true)
    Wargroove.updateUnit(unit)

    Wargroove.playPositionlessSound("battleStart")
    Wargroove.playGrooveCutscene(unit.id)

    local facingOverride = ""
    if targetPos.x > unit.pos.x then
        facingOverride = "right"
    elseif targetPos.x < unit.pos.x then
        facingOverride = "left"
    end

    local grooveAnimation = "groove"
    if targetPos.y < unit.pos.y then
        grooveAnimation = "groove_up"
    elseif targetPos.y > unit.pos.y then
        grooveAnimation = "groove_down"
    end

    if facingOverride ~= "" then
        Wargroove.setFacingOverride(unit.id, facingOverride)
    end

    Wargroove.playUnitAnimation(unit.id, grooveAnimation)
    Wargroove.playMapSound("mercival/mercivalGroove", targetPos)
    Wargroove.waitTime(3.0)

    Wargroove.playGrooveEffect()
    Wargroove.unsetFacingOverride(unit.id)
    Wargroove.playUnitAnimation(unit.id, "groove_end")
    Wargroove.openFishingUI(unit.pos, strParam)
    Wargroove.waitTime(0.5)
    Wargroove.playMapSound("mercival/mercivalGrooveCatch", unit.pos)
    Wargroove.waitTime(2.5)

end

function Fish:generateOrders(unitId, canMove)
    return {}
end

function Fish:getScore(unitId, order)
    return {score = 0, introspection = {}}    
end

return Fish
