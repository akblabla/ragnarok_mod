local Wargroove = require "wargroove/wargroove"
local Combat = require "wargroove/combat"
local GrooveVerb = require "wargroove/groove_verb"

local BirdWatching = GrooveVerb:new()


function BirdWatching:getMaximumRange(unit, endPos)
    return 1
end


function BirdWatching:getTargetType()
    return "empty"
end

function BirdWatching:canExecuteGroove(unit)
    local baseExecute = GrooveVerb:canExecuteGroove(unit)

    local tier = self:getCurrentGrooveTier(unit)
    if tier ~= 2 then
        return false
    end

    return baseExecute
end

function BirdWatching:canExecuteWithTarget(unit, endPos, targetPos, strParam)
    if not self:canSeeTarget(targetPos) then
        return false
    end

    if (Wargroove.getUnitAt(targetPos) ~= nil) then
        return false
    end

    local terrainName = Wargroove.getTerrainNameAt(targetPos)
    return terrainName == "forest" or terrainName == "mountain"
end

function BirdWatching:preExecute(unit, targetPos, strParam, endPos)
    return true, Wargroove.chooseBird(targetPos)
end

function BirdWatching:execute(unit, targetPos, strParam, path)
    Wargroove.setIsUsingGroove(unit.id, true)
    Wargroove.updateUnit(unit)

    Wargroove.playPositionlessSound("battleStart")
    Wargroove.playGrooveCutscene(unit.id, 2, "bird_watching")

    local facingOverride = ""
    if targetPos.x > unit.pos.x then
        facingOverride = "right"
    elseif targetPos.x < unit.pos.x then
        facingOverride = "left"
    end

    local grooveAnimation = "groove2"
    if targetPos.y < unit.pos.y then
        grooveAnimation = "groove2_up"
    elseif targetPos.y > unit.pos.y then
        grooveAnimation = "groove2_down"
    end

    if facingOverride ~= "" then
        Wargroove.setFacingOverride(unit.id, facingOverride)
    end

    Wargroove.playUnitAnimation(unit.id, grooveAnimation)
    Wargroove.playMapSound("mercival/mercivalGrooveBirdWatching", targetPos)
    Wargroove.waitTime(3.0)

    Wargroove.playGrooveEffect()
    Wargroove.unsetFacingOverride(unit.id)
    Wargroove.playUnitAnimation(unit.id, "groove2_end")
    Wargroove.openFishingUI(unit.pos, strParam, 2)
    Wargroove.waitTime(0.5)
    Wargroove.playMapSound("mercival/mercivalGrooveCatch", unit.pos)
    Wargroove.waitTime(2.5)

    Wargroove.logAnalyticsAction("UnitAbility", unit.playerId, "groove", unit.unitClassId)
end

function BirdWatching:generateOrders(unitId, canMove)
    return {}
end

function BirdWatching:getScore(unitId, order)
    return {score = 0, introspection = {}}    
end

return BirdWatching
