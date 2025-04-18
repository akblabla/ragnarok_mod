local Wargroove = require "wargroove/wargroove"
local GrooveVerb = require "wargroove/groove_verb"
local Verb = require "wargroove/verb"
local Combat = require "wargroove/combat"

local Golf = GrooveVerb:new()

Golf.isInPreExecute = false

local damagePercent = 0.5

local maxDist = 8
local maxGolfRange = maxDist * 2

function Golf:getMaximumRange(unit, endPos)
  if Golf.isInPreExecute then
    return maxGolfRange
  end

  return 1
end


function Golf:getTargetType()
    if Golf.isInPreExecute then
        return "empty"
    end

    return "all"
end

function Golf:isInCone(unitPos, movingUnitPos, targetPos)
  local xDiff = targetPos.x - movingUnitPos.x
  local yDiff = targetPos.y - movingUnitPos.y
  local absXDiff = math.abs(xDiff)
  local absYDiff = math.abs(yDiff)
  if movingUnitPos.x > unitPos.x and xDiff < 0 then
    return false
  elseif movingUnitPos.x < unitPos.x and xDiff > 0 then
    return false
  elseif movingUnitPos.y > unitPos.y and yDiff < 0 then
    return false
  elseif movingUnitPos.y < unitPos.y and yDiff > 0 then
    return false
  end

  if (unitPos.x == movingUnitPos.x) then
    if absXDiff > absYDiff or absYDiff > maxDist then
      return false
    end
  else
    if absYDiff > absXDiff or absXDiff > maxDist then
      return false
    end
  end

  return true
end

function Golf:isValidTarget(targetUnit)
    if not targetUnit then
        return false
    end
    return (not targetUnit.unitClass.isStructure) and (not targetUnit.unitClass.isCommander) and (targetUnit.playerId >= 0) and (targetUnit.unitClass.moveRange > 0) and (targetUnit.canBeAttacked)
end

function Golf:canExecuteWithTarget(unit, endPos, targetPos, strParam)
    if not self:canSeeTarget(targetPos) then
        return false
    end
    
    if not Golf.isInPreExecute then
        if targetPos.x == unit.pos.x and targetPos.y == unit.pos.y then
            return false
        end

        return self:isValidTarget(Wargroove.getUnitAt(targetPos))
    else
        local movingUnit = Wargroove.getUnitById(Golf.movingUnit)
        if not self:isInCone(endPos, movingUnit.pos, targetPos) then
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

        return not Wargroove.isTerrainImpassableAt(targetPos)
    end
end

function Golf:preExecute(unit, targetPos, strParam, endPos)
    if targetPos.x == unit.pos.x and targetPos.y == unit.pos.y then
        Golf.movingUnit = unit.id
    else
        Golf.movingUnit = Wargroove.getUnitAt(targetPos).id
    end

    if Golf.movingUnit == unit.id and endPos.x == unit.pos.x and endPos.y == unit.pos.y then
        Wargroove.selectTarget()

        while Wargroove.waitingForSelectedTarget() do
            coroutine.yield()
        end

        local newTargetPos = Wargroove.getSelectedTarget()
        if (newTargetPos == nil) then
            return false, ""
        end

        Golf.movingUnit = Wargroove.getUnitAt(newTargetPos).id
    end

    Golf.isInPreExecute = true

    Wargroove.selectTarget()

    while Wargroove.waitingForSelectedTarget() do
        coroutine.yield()
    end

    local destination = Wargroove.getSelectedTarget()

    if (destination == nil) then
        Golf.isInPreExecute = false
        return false, ""
    end
    
    Wargroove.setSelectedTarget(targetPos)

    Golf.isInPreExecute = false

    return true, Golf.movingUnit .. ";" .. destination.x .. "," .. destination.y
end

function Golf:parseTargets(strParam)
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
    targetTeleportPosition = { x = tonumber(vals[1]), y = tonumber(vals[2])}

    return targetUnitId, targetTeleportPosition
end

function Golf:execute(unit, targetPos, strParam, path)
    if strParam == "" then
        print("Golf:execute was not given any target positions.")
        return
    end

    Wargroove.trackCameraTo(unit.pos)

    Wargroove.setIsUsingGroove(unit.id, true)
    Wargroove.updateUnit(unit)

    Wargroove.playPositionlessSound("battleStart")
    Wargroove.playGrooveCutscene(unit.id)

    local targetUnitId, teleportPosition = Golf:parseTargets(strParam)    

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

    Wargroove.playUnitAnimation(unit.id, "groove")
    Wargroove.playMapSound("wulfar/wulfarGroove", unit.pos)
    Wargroove.waitTime(2.1)
    Wargroove.playMapSound("wulfar/wulfarGrooveUnitFalling", targetPos)
    Wargroove.playGrooveEffect()
    local targetUnit = Wargroove.getUnitById(targetUnitId)

    local numSteps = 10

    local steps = {}
    local xDiff = teleportPosition.x - targetUnit.pos.x
    local yDiff = teleportPosition.y - targetUnit.pos.y
    local xStep = xDiff / numSteps
    local yStep = yDiff / numSteps
    for i = 1,numSteps do
      if (xDiff ~= 0) then
        local radians = i / numSteps * 3.14
        steps[i] = {x = xStep * i, y = yStep * i + -2.5 * math.sin(radians)}
      else
        steps[i] = { x = 0, y = yStep * i}
      end
    end

    local startingPosition = targetUnit.pos
    Wargroove.lockTrackCamera(targetUnit.id)
    Wargroove.setShadowVisible(targetUnit.id, false)
    for i = 1, numSteps do
      Wargroove.moveUnitToOverride(targetUnit.id, startingPosition, steps[i].x, steps[i].y, 20)
      while (Wargroove.isLuaMoving(targetUnit.id)) do
        coroutine.yield()
      end
    end
    Wargroove.unsetShadowVisible(targetUnit.id)
    Wargroove.unlockTrackCamera()

    -- Update unit being tee'd off
    local causeDamage = true
    targetUnit.pos = { x = teleportPosition.x, y = teleportPosition.y }
    if (targetUnit.playerId == unit.playerId) then
        targetUnit.hadTurn = true
    end
    if causeDamage then
        local targetDamage = Combat:getGrooveAttackerDamage(unit, targetUnit, "random", targetUnit.pos, targetPos, path, nil) * damagePercent
        targetUnit:setHealth(targetUnit.health - targetDamage, unit.id)
        local anim = "fx/groove/koji_groove_fx"
        if Wargroove.getTerrainNameAt(teleportPosition) == "river" or Wargroove.isWater(teleportPosition) then
            anim = "fx/groove/wulfar_groove_fx"
        end
        Wargroove.spawnMapAnimation(targetUnit.pos, 3, anim, "idle", "behind_units", { x = 12, y = 12 })
    end

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
    end
    Wargroove.updateUnit(targetUnit)

    -- Damage nearby units
    if causeDamage then
        for i, pos in ipairs(Wargroove.getTargetsInRange(targetUnit.pos, 1, "unit")) do
            local u = Wargroove.getUnitAt(pos)
            if u and u.id ~= targetUnit.id and Wargroove.areEnemies(u.playerId, unit.playerId) then
                local damage = Combat:getGrooveAttackerDamage(unit, u, "random", targetUnit.pos, pos, path, nil) * damagePercent

                u:setHealth(u.health - damage, unit.id)
                Wargroove.updateUnit(u)
                Wargroove.playUnitAnimation(u.id, "hit")
            end
        end

        Wargroove.waitTime(0.5)
    end
end

function Golf:onPostUpdateUnit(unit, targetPos, strParam, path)
    GrooveVerb.onPostUpdateUnit(self, unit, targetPos, strParam, path)

    if strParam == "" then
        print("Golf:onPostUpdateUnit was not given any target positions.")
        return
    end

    local targetUnitId, teleportPosition = Golf:parseTargets(strParam)
    local targetUnit = Wargroove.getUnitById(targetUnitId)

    if targetUnit.id == unit.id then
        unit.pos = teleportPosition
    end
    
    Wargroove.unsetFacingOverride(unit.id)
end

function Golf:generateOrders(unitId, canMove)
    local orders = {}

    local unit = Wargroove.getUnitById(unitId)
    local unitClass = Wargroove.getUnitClass(unit.unitClassId)
    local movePositions = {}
    if canMove then
        movePositions = Wargroove.getTargetsInRange(unit.pos, unitClass.moveRange, "empty")
    end
    table.insert(movePositions, unit.pos)

    local function canTarget(u)
        if Wargroove.hasAIRestriction(u.id, "dont_target_this") then
            return false
        end
        if Wargroove.hasAIRestriction(unit.id, "only_target_commander") and not u.unitClass.isCommander then
            return false
        end
        return true
    end

    local originalPos = unit.pos
    for i, pos in pairs(movePositions) do
        Wargroove.pushUnitPos(unit, pos)
        local teleportPositionsInRange = Wargroove.getTargetsInRange(pos, maxGolfRange, "empty")

        local moved = originalPos.x ~= pos.x or originalPos.y ~= pos.y

        local targets = Wargroove.getTargetsInRange(pos, 1, "unit")
        for j, targetPos in pairs(targets) do
            local u = Wargroove.getUnitAt(targetPos)

            if u ~= nil and self:canSeeTarget(targetPos) and canTarget(u) then
                local teleportPositions = {}
                for i, teleportPos in ipairs(teleportPositionsInRange) do
                    local unitAtPos = Wargroove.getUnitAt(teleportPos)                    
                    local spaceIsEmpty = (unitAtPos == nil and (teleportPos.x ~= pos.x or teleportPos.y ~= pos.y)) or (unitAtPos.id == unit.id and moved)
                    if self:isInCone(pos, targetPos, teleportPos) and spaceIsEmpty and Wargroove.canStandAt(u.unitClassId, teleportPos) then
                        table.insert(teleportPositions, teleportPos)
                    end
                end

                local uc = Wargroove.getUnitClass(u.unitClassId)
                if not uc.isStructure and (not uc.isCommander or not Wargroove.areEnemies(u.playerId, unit.playerId)) and u.playerId >= 0 then
                    for k, teleportPosition in pairs(teleportPositions) do
                        if (teleportPosition.x ~= pos.x or teleportPosition.y ~= pos.y) and (teleportPosition.x ~= targetPos.x or teleportPosition.y ~= targetPos.y) then
                            local strParam = u.id .. ";" .. teleportPosition.x .. "," .. teleportPosition.y
                            local endPosition = pos
                            local targetPosition = u.pos
                            if u.id == unit.id then
                                endPosition = teleportPosition
                                targetPosition = originalPos
                            end
                            orders[#orders+1] = {targetPosition = targetPosition, strParam = strParam, movePosition = pos, endPosition = endPosition}
                        end
                    end
                end
            end
        end
        Wargroove.popUnitPos()
    end

    return orders
end

function Golf:getScore(unitId, order)
    local targetUnitId, teleportPosition = Golf:parseTargets(order.strParam)
    local targetUnit = Wargroove.getUnitById(targetUnitId)    

    local opportunityCost = -1

    --- unit score
    local unitScore = Wargroove.getAIUnitValue(targetUnit.id, targetUnit.pos)
    local newUnitScore = Wargroove.getAIUnitValue(targetUnit.id, teleportPosition)
    local delta = newUnitScore - unitScore

    --- location score
    local startScore = Wargroove.getAILocationScore(targetUnit.unitClassId, targetUnit.pos)
    local endScore = Wargroove.getAILocationScore(targetUnit.unitClassId, teleportPosition)

    local locationGradient = endScore - startScore
    local gradientBonus = 0
    if locationGradient > 0.00001 then
        gradientBonus = 0.25
    end

    --- damage score
    local effectivenessScore = 0.0
    local totalValue = 0.0

    local unit = Wargroove.getUnitById(unitId)
    local function canTarget(u)
      if not Wargroove.areEnemies(u.playerId, unit.playerId) then
          return false
      end
      return true
    end

    
    -- if Wargroove.areEnemies(unit.playerId, targetUnit.playerId) then
    --   local damage = Combat:getGrooveAttackerDamage(unit, targetUnit, "aiSimulation", unit.pos, targetUnit.pos, path, nil) * damagePercent
    --   local newHealth = math.max(0, targetUnit.health - damage)
    --   local theirValue = Wargroove.getAIUnitValue(targetUnit.id, targetUnit.pos)
    --   local theirDelta = theirValue - Wargroove.getAIUnitValueWithHealth(targetUnit.id, targetUnit.pos, newHealth)
    --   effectivenessScore = effectivenessScore + theirDelta
    --   totalValue = totalValue + theirValue
    -- end

    local function computeDamageValue(u, target, scoreMult)
        local damage = Combat:getGrooveAttackerDamage(unit, u, "aiSimulation", teleportPosition, u.pos, path, nil) * damagePercent
        local newHealth = math.max(0, u.health - damage)
        local theirValue = Wargroove.getAIUnitValue(u.id, target)
        local theirDelta = theirValue - Wargroove.getAIUnitValueWithHealth(u.id, target, newHealth)
        effectivenessScore = (effectivenessScore + theirDelta) * scoreMult
        totalValue = totalValue + theirValue
    end

    -- Unit being tee'd off
    local scoreMult = 1
    if not canTarget(targetUnit) then
        scoreMult = -1
    end
    computeDamageValue(targetUnit, teleportPosition, scoreMult)

    -- Other units
    local targets = Wargroove.getTargetsInRange(teleportPosition, 1, "unit")
    for i, target in ipairs(targets) do
        local u = Wargroove.getUnitAt(target)
        if u ~= nil and u.id ~= targetUnit.id and canTarget(u) then
            computeDamageValue(u, target, 1)
        end
    end

    local attackBias = Wargroove.getAIAttackBias()

    local score = effectivenessScore * attackBias + (delta + gradientBonus) + opportunityCost

    return {score = score, introspection = {
        {key = "effectivenessScore", value = effectivenessScore},
        {key = "totalValue", value = totalValue},
        {key = "delta", value = delta},
        {key = "gradientBonus", value = gradientBonus},
        {key = "manhattanDistance", value = manhattanDistance},
        {key = "opportunityCost", value = opportunityCost}}}
end

return Golf
