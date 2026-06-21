local Wargroove = require "wargroove/wargroove"
local Verb = require "wargroove/verb"
local Combat = require "wargroove/combat"

local Kick = Verb:new()

function Kick:getMaximumRange(unit, endPos)
    return 1
end


function Kick:getTargetType()
    return "unit"
end




function Kick:canExecuteWithTarget(unit, endPos, targetPos, strParam)
    if not self:canSeeTarget(targetPos) then
        return false
    end

    local targetUnit = Wargroove.getUnitAt(targetPos)

    if not targetUnit then
        return false
    end

    if targetUnit.id == unit.id then
        return false
    end
    return true
end

function Kick:getTargetArrows(unit, targetPos, endPos)
    local results = {}

    local targetUnit = Wargroove.getUnitAt(targetPos)
    
    if Wargroove.isValidPushPullTarget(targetUnit, false) then
        local pushResults = Wargroove.getPushPullResult(endPos, targetPos, 1, false, false)
        if pushResults == nil then return results end
        if pushResults["pushTargetUnit"] and not pushResults["isBreakPosition"] then
            Wargroove.pushUnitPos(targetUnit, pushResults["pushPosition"])
            pushResults = Wargroove.getPushPullResult(endPos, pushResults["pushPosition"], 1, false, false)
            Wargroove.popUnitPos()
        end
        local targetArrow = Wargroove.createTargetArrowFromPushPullResult(pushResults)
        table.insert(results, targetArrow)
    end

    return results
end

function Kick:execute(unit, targetPos, strParam, path)

    local targetUnit = Wargroove.getUnitAt(targetPos)


    --- Telegraph
    if unit.pos.x>targetPos.x then
        -- spawnedUnit.startPos.facing = 1
        unit.pos.facing = 1
        Wargroove.setFacingOverride(unit.id, "left")
    elseif unit.pos.x<targetPos.x then
        -- spawnedUnit.startPos.facing = 0
        unit.pos.facing = 0
        Wargroove.setFacingOverride(unit.id, "right")
    end
    local dist = math.sqrt((targetPos.x-unit.pos.x)^2 + (targetPos.y-unit.pos.y)^2)
    Wargroove.waitTime(0.2)
    Wargroove.moveUnitToOverride(unit.id, unit.pos, -0.2*(targetPos.x-unit.pos.x)/dist, -0.2*(targetPos.y-unit.pos.y)/dist, 1.5)
    Wargroove.playMapSound("prepKick", targetPos)
    while Wargroove.isLuaMoving(unit.id) do
      coroutine.yield()
    end
    Wargroove.waitTime(0.4)
    Wargroove.moveUnitToOverride(unit.id, unit.pos, 0.5*(targetPos.x-unit.pos.x)/dist, 0.5*(targetPos.y-unit.pos.y)/dist, 8)
    while Wargroove.isLuaMoving(unit.id) do
      coroutine.yield()
    end
    Wargroove.playMapSound("hitKick", targetPos)
    
    if Wargroove.isValidPushPullTarget(targetUnit, false) then
        
    local pushResults = Wargroove.getPushPullResult(unit.pos, targetPos, 1, false, false)
    if pushResults == nil then return end
        if pushResults["pushTargetUnit"] and not pushResults["isBreakPosition"] then
            Wargroove.pushUnitPos(targetUnit, pushResults["pushPosition"])
            pushResults = Wargroove.getPushPullResult(unit.pos, pushResults["pushPosition"], 1, false, false)
            Wargroove.popUnitPos()
            pushResults["pushTargetUnit"] = true
        end
        Wargroove.moveUnitToOverride(unit.id, unit.pos, 0, 0, 3)
        Wargroove.processPushPullResult(unit, pushResults, 20, 20)
        
        while Wargroove.isLuaMoving(unit.id) do
        coroutine.yield()
        end
    end
    Wargroove.updateUnit(targetUnit)
end

return Kick