local Wargroove = require "wargroove/wargroove"
local GrooveVerb = require "wargroove/groove_verb"
local UnitOnTurn = require "wargroove/unit_on_turn"

local Putt = GrooveVerb:new()
Putt.isInPreExecute = false

function Putt:getTier()
    return 1
end
local maxPuttRange = 3
function Putt:getMaximumRange(unit, endPos)
    if Putt.isInPreExecute then
      return maxPuttRange+1
    end
  
    return 1
  end

function Putt:getTargetType()
    if Putt.isInPreExecute then
        return "empty"
    end

    return "all"
end

function Putt:consumeGroove(unit)
    local groove = Wargroove.getGroove(self:getGrooveId(unit))
    unit.grooveChargeOnUse = unit.grooveCharge
    unit.grooveCharge = unit.grooveCharge-groove.grooveCost[1]
    if unit.grooveCharge<0 then unit.grooveCharge = 0 end
    Wargroove.updateUnit(unit)
end

function Putt:isValidTarget(targetUnit)
    if not targetUnit then
        return false
    end
    return (not targetUnit.unitClass.isStructure) and (not targetUnit.unitClass.isCommander) and (targetUnit.playerId >= 0) and (targetUnit.unitClass.moveRange > 0) and (targetUnit.canBeAttacked)
end

function Putt:canPushTo(movingUnitPos, targetPos)
    local pushResult = Wargroove.getPushPullResult(movingUnitPos, targetPos, 1, false, false)
    if pushResult == nil then
        return false
    end
    if pushResult["pushTargetUnit"] == false then
        return false
    end
    local destination = pushResult["pushPosition"]
    return destination.x~=targetPos.x and destination.y~=targetPos.y
end

function Putt:canExecuteAnywhere(unit)
    local tier = self:getCurrentGrooveTier(unit)
    return tier>=1
end

function Putt:canExecuteWithTarget(unit, endPos, targetPos, strParam)
    local tier = self:getCurrentGrooveTier(unit)
    if tier==0 then
        return false
    end
    if not self:canSeeTarget(targetPos) then
        return false
    end
    
    if not Putt.isInPreExecute then
        if targetPos.x == unit.pos.x and targetPos.y == unit.pos.y then
            return false
        end

        return self:isValidTarget(Wargroove.getUnitAt(targetPos))
    else
        local movingUnit = Wargroove.getUnitById(Putt.movingUnit)
        local deltaPos = {x = movingUnit.pos.x-endPos.x, y = movingUnit.pos.y-endPos.y}
        local targetDeltaPos = {x = movingUnit.pos.x-targetPos.x, y = movingUnit.pos.y-targetPos.y}
        local dotProduct = deltaPos.x*targetDeltaPos.x+deltaPos.y*targetDeltaPos.y
        if dotProduct~=0 then
          return false
        end

        if (targetPos.x == endPos.x and targetPos.y == endPos.y) then
            return false
        end

        local unitAt = Wargroove.getUnitAt(targetPos)
        local unitMoved = unit.pos.x ~= endPos.x or unit.pos.y ~= endPos.y
        if (unitAt ~= nil and (unitAt.id ~= unit.id or not unitMoved)) then
            return false
        end 

        if not self:isValidTarget(movingUnit) then
            return false
        end
        if not Putt:canPushTo(movingUnit.pos, targetPos) then
            return false
        end

        return not Wargroove.isTerrainImpassableAt(targetPos)
    end
end

function Putt:preExecute(unit, targetPos, strParam, endPos)
    if targetPos.x == unit.pos.x and targetPos.y == unit.pos.y then
        Putt.movingUnit = unit.id
    else
        Putt.movingUnit = Wargroove.getUnitAt(targetPos).id
    end

    if Putt.movingUnit == unit.id and endPos.x == unit.pos.x and endPos.y == unit.pos.y then
        Wargroove.selectTarget()

        while Wargroove.waitingForSelectedTarget() do
            coroutine.yield()
        end

        local newTargetPos = Wargroove.getSelectedTarget()
        if (newTargetPos == nil) then
            return false, ""
        end

        Putt.movingUnit = Wargroove.getUnitAt(newTargetPos).id
    end

    Putt.isInPreExecute = true

    Wargroove.selectTarget()

    while Wargroove.waitingForSelectedTarget() do
        coroutine.yield()
    end

    local destination = Wargroove.getSelectedTarget()

    if (destination == nil) then
        Putt.isInPreExecute = false
        return false, ""
    end
    
    Wargroove.setSelectedTarget(targetPos)

    Putt.isInPreExecute = false

    return true, Putt.movingUnit .. ";" .. destination.x .. "," .. destination.y
end

function Putt:parseTargets(strParam)
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

function Putt:execute(unit, targetPos, strParam, path)
    if strParam == "" then
        print("Golf:execute was not given any target positions.")
        return
    end

    Wargroove.trackCameraTo(unit.pos)

    local targetUnitId, teleportPosition = Putt:parseTargets(strParam)    

    local facingOverride = ""
    if targetPos.x > unit.pos.x then
        facingOverride = "right"
    elseif targetPos.x < unit.pos.x then
        facingOverride = "left"
    elseif teleportPosition.x < unit.pos.x then
        facingOverride = "left"
    elseif teleportPosition.x > unit.pos.x then
        facingOverride = "right"
    end

    Wargroove.setFacingOverride(unit.id, facingOverride)

    Wargroove.playUnitAnimation(unit.id, "mini_groove")
	Wargroove.playMapSound("wulfar/wulfarMiniGroove", unit.pos)
    Wargroove.waitTime(2.25)
	Wargroove.playMapSound("wulfar/wulfarMiniGroovePutt", targetPos)
    Wargroove.playGrooveEffect()
    local targetUnit = Wargroove.getUnitById(targetUnitId)

    local numSteps = 10

    local steps = {}
    local xDiff = teleportPosition.x - targetUnit.pos.x
    local yDiff = teleportPosition.y - targetUnit.pos.y
    for i = 0,numSteps do
        local stamp = i / numSteps
        steps[i] = {x = xDiff * (1-(1-stamp)^2), y = yDiff * (1-(1-stamp)^2)}
    end

    local speed = {}
    for i = 1,numSteps do
        speed[i] = math.sqrt((steps[i].x - steps[i-1].x)^2+(steps[i].y - steps[i-1].y)^2);
    end
    local startingPosition = targetUnit.pos
    Wargroove.lockTrackCamera(targetUnit.id)
    for i = 1, numSteps do
      Wargroove.moveUnitToOverride(targetUnit.id, startingPosition, steps[i].x, steps[i].y, speed[i]*15)
      while (Wargroove.isLuaMoving(targetUnit.id)) do
        coroutine.yield()
      end
    end
    Wargroove.unlockTrackCamera()

    targetUnit.pos = { x = teleportPosition.x, y = teleportPosition.y }
    -- Sound and splash(?)
    if Wargroove.isWater(teleportPosition) or Wargroove.getTerrainNameAt(teleportPosition) == "river" then
        local splashFX = Wargroove.getSplashEffect()
        Wargroove.spawnMapAnimation(teleportPosition, 1, splashFX)
        Wargroove.playMapSound("unitSplash", teleportPosition)
    else
        Wargroove.playMapSound("wulfar/wulfarGrooveUnitLanding", teleportPosition)
    end
    -- Break?
    if not Wargroove.canStandAt(targetUnit.unitClassId, teleportPosition) then
        if not Wargroove.isWater(teleportPosition) then
            Wargroove.spawnMapAnimation(teleportPosition, 1, "fx/unit_ship_break")
        end
        Wargroove.setVisibleOverride(targetUnit.id, false)
        Wargroove.updateUnit(targetUnit)
    end
    Wargroove.updateUnit(targetUnit)
end

function Putt:onPostUpdateUnit(unit, targetPos, strParam, path)
    GrooveVerb.onPostUpdateUnit(self, unit, targetPos, strParam, path)

    if strParam == "" then
        print("Golf:onPostUpdateUnit was not given any target positions.")
        return
    end

    local targetUnitId, teleportPosition = Putt:parseTargets(strParam)
    local targetUnit = Wargroove.getUnitById(targetUnitId)

    if targetUnit.id == unit.id then
        unit.pos = teleportPosition
    end
    
    Wargroove.unsetFacingOverride(unit.id)
end


return Putt