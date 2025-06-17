local Wargroove = require "wargroove/wargroove"
local GrooveVerb = require "wargroove/groove_verb"
local Combat = require "wargroove/combat"

local Golf = GrooveVerb:new()

Golf.isInPreExecute = false

local damagePercent = 0.5

local maxDist = 8
local maxGolfRange = maxDist * 2


Golf.isInPreExecute = false
Golf.isInHops = false
Golf.hops = {}
Golf.destination = nil

local damagePercent = 0.5
local damageRange = 1
local maxDist = 8
local maxSpread = 9

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
function Golf:getMaximumRange(unit, endPos)
    if Golf.isInPreExecute then
        return maxDist * 2
    end

    return 1
end

function Golf:canExecuteAnywhere(unit)
    local tier = self:getCurrentGrooveTier(unit)
    return tier>=Golf:getTier(unit)
end

function Golf:getTargetType()
    if Golf.isInPreExecute then
        return "empty"
    end

    return "all"
end

function Golf:isInCone(unitPos, movingUnitPos, targetPos, tier)
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
    if absXDiff > absYDiff or absYDiff > maxDist or absXDiff > maxSpread then
      return false
    end
  else
    if absYDiff > absXDiff or absXDiff > maxDist or absYDiff > maxSpread then
      return false
    end
  end

  return true
end

function Golf:isValidTarget(targetUnit)
    if not targetUnit then
        return false
    end
    return (targetUnit.playerId >= 0) and (targetUnit.unitClass.moveRange > 0) and (targetUnit.canBeAttacked) and (targetUnit.unitClass.isAttackable) and (Wargroove.isValidPushPullTarget(targetUnit, false))
end

function Golf:getTargetsInDirection(unit, startingPos, direction, range)
    local foundHoppableSpace = false
    local checkingPos = startingPos
    local targets = { }

    for i = 1, range do
        checkingPos = {x = checkingPos.x + direction.x, y = checkingPos.y + direction.y}
        foundHoppableSpace = true

        local mapSize = Wargroove.getMapSize()
        if checkingPos.x < 0 or checkingPos.x > mapSize.x or checkingPos.y < 0 or checkingPos.y > mapSize.y then
            foundHoppableSpace = false
        end

        if not self:canSeeTarget(checkingPos) then
            goto NEXT_POS
        end

        local u = Wargroove.getUnitAt(checkingPos)
        if u ~= nil then
            foundHoppableSpace = false
        end

        if u and u.id == unit.id then
            return { }
        end

        if checkingPos.x == Golf.destination.x and checkingPos.y == Golf.destination.y then
            foundHoppableSpace = false
        end

        for _, pos in ipairs(Golf.hops) do
            if pos.x == checkingPos.x and pos.y == checkingPos.y then
                foundHoppableSpace = false
                break
            end
        end

        if foundHoppableSpace then
            table.insert(targets, checkingPos)
        end

        :: NEXT_POS ::
    end

    return targets
end

function Golf:canExecuteWithTarget(unit, endPos, targetPos, strParam)  
    local tier = self:getCurrentGrooveTier(unit)
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
        if not movingUnit or not self:isInCone(endPos, movingUnit.pos, targetPos, tier) then
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

function Golf:cleanUpPreExecute()
    Golf.isInPreExecute = false
    Golf.destination = nil
end

function Golf:preExecute(unit, targetPos, strParam, endPos)
    local tier = self:getCurrentGrooveTier(unit)

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
        Golf:cleanUpPreExecute()
        return false, ""
    end

    Golf.destination = destination
    
    Wargroove.setSelectedTarget(targetPos)


    Wargroove.clearDisplayTargets()
    self:cleanUpPreExecute()

    return true, Golf.movingUnit .. ";" .. destination.x .. "," .. destination.y
end

function Golf:buildTargetString(targets)
    local result = ""
    for i, target in ipairs(targets) do
        result = result .. target.x .. "," .. target.y
        if i ~= #targets then
            result = result .. ";"
        end
    end
    return result
end

function Golf:parseTargets(strParam)
    local targetStrs={}
    local i = 1
    for targetStr in string.gmatch(strParam, "([^"..";".."]+)") do
        targetStrs[i] = targetStr
        i = i + 1
    end

    local targetUnitId = tonumber(targetStrs[1])

    local teleportPositions = {}
    for i=2, #targetStrs do
        local targetTeleportPosition

        local targetPosStr = targetStrs[i]
        local vals = {}
        for val in targetPosStr.gmatch(targetPosStr, "([^"..",".."]+)") do
            vals[#vals+1] = val
        end
        targetTeleportPosition = { x = tonumber(vals[1]), y = tonumber(vals[2])}

        table.insert(teleportPositions, targetTeleportPosition)
    end

    return targetUnitId, teleportPositions
end

function Golf:golfUnitToTarget(unit, targetUnit, teleportPosition, targetPos, path, tier, number)
    local numSteps = 10

    local steps = {}
    local xDiff = teleportPosition.x - targetUnit.pos.x
    local yDiff = teleportPosition.y - targetUnit.pos.y
    local xStep = xDiff / numSteps
    local yStep = yDiff / numSteps
    for i = 1,numSteps do
      if (xDiff ~= 0) then
        local radians = i / numSteps * 3.14
        steps[i] = {x = xStep * i, y = yStep * i + (-2.5/number)  * math.sin(radians)}
      else
        steps[i] = { x = 0, y = yStep * i}
      end
    end

    local startingPosition = targetUnit.pos
    Wargroove.setShadowVisible(targetUnit.id, false)
    for i = 1, numSteps do
      Wargroove.moveUnitToOverride(targetUnit.id, startingPosition, steps[i].x, steps[i].y, 20*number)
      while (Wargroove.isLuaMoving(targetUnit.id)) do
        coroutine.yield()
      end
    end
    Wargroove.unsetShadowVisible(targetUnit.id)

    -- Update unit being tee'd off
    targetUnit.pos = { x = teleportPosition.x, y = teleportPosition.y }
    if (targetUnit.playerId == unit.playerId) then
        targetUnit.hadTurn = true
    end

    local targetDamage = Combat:getGrooveAttackerDamage(unit,targetUnit,"average",path[#path],targetPos,path,nil) * damagePercent
    
    targetUnit:setHealth(targetUnit.health - targetDamage, unit.id)

    local anim = "fx/groove/koji_groove_fx"
    if Wargroove.getTerrainNameAt(teleportPosition) == "river" or Wargroove.isWater(teleportPosition) then
        anim = "fx/groove/wulfar_groove_fx"
    end
    Wargroove.spawnMapAnimation(targetUnit.pos, 3, anim, "idle", "behind_units", { x = 12, y = 12 })

    -- Sound and splash(?)
    if Wargroove.isWater(teleportPosition) or Wargroove.getTerrainNameAt(teleportPosition) == "river" then
        local splashFX = Wargroove.getSplashEffect()
        Wargroove.spawnMapAnimation(teleportPosition, 1, splashFX)
        Wargroove.playMapSound("unitSplash", teleportPosition)
    else
        Wargroove.playMapSound("wulfar/wulfarGrooveUnitLanding", teleportPosition)
    end
    local result = true
    -- Break?
    if not Wargroove.canStandAt(targetUnit.unitClassId, teleportPosition) then
        if not Wargroove.isWater(teleportPosition) then
            Wargroove.spawnMapAnimation(teleportPosition, 1, "fx/unit_ship_break")
        end
        Wargroove.setVisibleOverride(targetUnit.id, false)
        Wargroove.updateUnit(targetUnit)
        result = false
    end
    Wargroove.updateUnit(targetUnit)

    -- Damage nearby units
    for i, pos in ipairs(Wargroove.getTargetsInRange(targetUnit.pos, damageRange, "unit")) do
        local u = Wargroove.getUnitAt(pos)
        if u and u.id ~= targetUnit.id and Wargroove.areEnemies(u.playerId, unit.playerId) then
            local damage = Combat:getGrooveAttackerDamage(unit, u, "average", targetUnit.pos, pos, path, nil) * damagePercent

            u:setHealth(u.health - damage, unit.id)
            Wargroove.updateUnit(u)
            Wargroove.playUnitAnimation(u.id, "hit")
        end
    end
    return result
end

function Golf:execute(unit, targetPos, strParam, path)
    Wargroove.clearDisplayTargets()

    local tier = self:getCurrentGrooveTier(unit)

    if strParam == "" then
        print("Golf:execute was not given any target positions.")
        return
    end

    Wargroove.trackCameraTo(unit.pos)

    Wargroove.setIsUsingGroove(unit.id, true)
    Wargroove.updateUnit(unit)

    Wargroove.playPositionlessSound("battleStart")
    Wargroove.playGrooveCutscene(unit.id, tier)

    local targetUnitId, teleportPositions = Golf:parseTargets(strParam) 

    local facingOverride = ""
    if targetPos.x > unit.pos.x then
        facingOverride = "right"
    elseif targetPos.x < unit.pos.x then
        facingOverride = "left"
    elseif teleportPositions[1].x < unit.pos.x then
        facingOverride = "left"
    elseif teleportPositions[1].x > unit.pos.x then
        facingOverride = "right"
    end

    Wargroove.setFacingOverride(unit.id, facingOverride)

    Wargroove.playUnitAnimation(unit.id, "groove")
    Wargroove.playMapSound("wulfar/wulfarGroove", unit.pos)
    Wargroove.waitTime(2.1)
    Wargroove.playMapSound("wulfar/wulfarGrooveUnitFalling", targetPos)
    Wargroove.playGrooveEffect()

    local targetUnit = Wargroove.getUnitById(targetUnitId)

    Wargroove.lockTrackCamera(targetUnit.id)
    for i, hopPosition in ipairs(teleportPositions) do
        local result = self:golfUnitToTarget(unit, targetUnit, hopPosition, targetPos, path, tier, i)
        if result == false then
            break
        end
    end
    Wargroove.unlockTrackCamera()

    Wargroove.waitTime(0.5)
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
    local tier = self:getCurrentGrooveTier(unit)
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
        local teleportPositionsInRange = Wargroove.getTargetsInRange(pos, maxDist * 2, "empty")

        local moved = originalPos.x ~= pos.x or originalPos.y ~= pos.y

        local targets = Wargroove.getTargetsInRange(pos, 1, "unit")
        for j, targetPos in pairs(targets) do
            local u = Wargroove.getUnitAt(targetPos)

            if u ~= nil and self:canSeeTarget(targetPos) and canTarget(u) then
                local teleportPositions = {}
                for i, teleportPos in ipairs(teleportPositionsInRange) do
                    local unitAtPos = Wargroove.getUnitAt(teleportPos)                    
                    local spaceIsEmpty = (unitAtPos == nil and (teleportPos.x ~= pos.x or teleportPos.y ~= pos.y)) or (unitAtPos.id == unit.id and moved)
                    if self:isInCone(pos, targetPos, teleportPos, tier) and spaceIsEmpty and Wargroove.canStandAt(u.unitClassId, teleportPos) then
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
    local targetUnitId, teleportPositions = Golf:parseTargets(order.strParam)
    local targetUnit = Wargroove.getUnitById(targetUnitId)    

    local teleportPosition = teleportPositions[1]

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

    local tier = self:getCurrentGrooveTier(unit)

    
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

    local manhattanDistance = 0

    return {score = score, introspection = {
        {key = "effectivenessScore", value = effectivenessScore},
        {key = "totalValue", value = totalValue},
        {key = "delta", value = delta},
        {key = "gradientBonus", value = gradientBonus},
        {key = "manhattanDistance", value = manhattanDistance},
        {key = "opportunityCost", value = opportunityCost}}}
end


return Golf
