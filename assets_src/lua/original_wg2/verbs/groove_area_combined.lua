local Wargroove = require "wargroove/wargroove"
local GrooveVerb = require "wargroove/groove_verb"

local AreaHealDamage = GrooveVerb:new()

local damageAmount = 20
local healAmount = 20
local damageRadius = 3

function AreaHealDamage:getMaximumRange(unit, endPos)
    return 4
end

function AreaHealDamage:getTargetType()
  return "all"
end

function AreaHealDamage:canExecuteGroove(unit)
    local baseExecute = GrooveVerb:canExecuteGroove(unit)

    local tier = self:getCurrentGrooveTier(unit)
    if tier ~= 2 then
        return false
    end

    return baseExecute
end

function AreaHealDamage:canExecuteWithTarget(unit, endPos, targetPos, strParam)
    if not self:canSeeTarget(targetPos) then
        return false
    end
    
    local u = Wargroove.getUnitAt(targetPos)
    return (endPos.x ~= targetPos.x or endPos.y ~= targetPos.y) 
        and (u == nil or unit.id == u.id)
        and Wargroove.canStandAt("soldier", targetPos)
end

function AreaHealDamage:execute(unit, targetPos, strParam, path)
    Wargroove.trackCameraTo(unit.pos)

    Wargroove.setIsUsingGroove(unit.id, true)
    Wargroove.updateUnit(unit)

    Wargroove.playGrooveChargeUp(unit.pos, unit.playerId)
    
    Wargroove.playPositionlessSound("battleStart")
    Wargroove.playGrooveCutscene(unit.id, 2, "area_combined")
        
    Wargroove.playUnitAnimation(unit.id, "groove2")
    Wargroove.playMapSound("twins/orlaGroove", unit.pos)
    Wargroove.waitTime(1.9)
    Wargroove.playMapSound("twins/orlaGrooveEffect", targetPos)
    Wargroove.spawnMapAnimation(targetPos, 3, "fx/groove/orla_groove_fx", "idle", "behind_units", {x = 12, y = 12})

    Wargroove.playGrooveEffect()

    local startingState = {}
    local pos = {key = "pos", value = "" .. targetPos.x .. "," .. targetPos.y}
    local radius = {key = "radius", value = tostring(damageRadius)}
    table.insert(startingState, pos)
    table.insert(startingState, radius)
    local hiddenSpawnId = Wargroove.spawnUnit(unit.playerId, { x = -100, y = -100 }, "area_combined_hidden", false, "", startingState)

    local hiddenSpawn = { key = "hiddenId", value = tostring(hiddenSpawnId) }
    table.insert(startingState, hiddenSpawn)
    Wargroove.spawnUnit(unit.playerId, targetPos, "area_combined", false, "", startingState)

    for i, pos in ipairs(Wargroove.getTargetsInRange(targetPos, damageRadius, "unit")) do
        local u = Wargroove.getUnitAt(pos)
        
        if u and (not u.unitClass.isStructure) and (u.playerId >= 0) and u.unitClassId ~= "area_combined" then
            local ally = Wargroove.areAllies(u.playerId, unit.playerId)

            if ally then
                u:setHealth(u.health + healAmount, unit.id)
                Wargroove.spawnMapAnimation(pos, 0, "fx/heal_unit")
            else
                local adjustedDamage = clamp(damageAmount * u.damageTakenPercent, 0, 20)

                if adjustedDamage > 0 then
                    u:setHealth(u.health - adjustedDamage, unit.id)
                    Wargroove.playUnitAnimation(u.id, "hit")
                end
            end

            Wargroove.updateUnit(u)
        end
    end

    Wargroove.waitTime(1.2)
end

function AreaHealDamage:generateOrders(unitId, canMove)
    local orders = {}

    local unit = Wargroove.getUnitById(unitId)
    local unitClass = Wargroove.getUnitClass(unit.unitClassId)
    local movePositions = {}
    if canMove then
        movePositions = Wargroove.getTargetsInRange(unit.pos, unitClass.moveRange, "empty")
    end
    table.insert(movePositions, unit.pos)

    for i, pos in pairs(movePositions) do
        local targets = Wargroove.getTargetsInRangeAfterMove(unit, pos, pos, 1, "empty")
        for j, target in pairs(targets) do
            if target ~= pos and self:canSeeTarget(target) then
                orders[#orders+1] = {targetPosition = target, strParam = "", movePosition = pos, endPosition = pos}
            end
        end
    end

    return orders
end

function AreaHealDamage:getScore(unitId, order)
    local unit = Wargroove.getUnitById(unitId)
    local targets = Wargroove.getTargetsInRangeAfterMove(unit, order.endPosition, order.targetPosition, 3, "unit")

    local opportunityCost = -1
    local totalScore = 0
    local maxScore = 300

    for i, pos in ipairs(targets) do
        local u = Wargroove.getUnitAt(pos)
        if u ~= nil and (not u.unitClass.isStructure) then
            local uc = u.unitClass
            if not Wargroove.areEnemies(unit.playerId, u.playerId) then
                totalScore = totalScore - uc.cost
            else
                totalScore = totalScore + uc.cost
            end
        end
    end
    
    local score = totalScore/maxScore + opportunityCost
    return {score = score, introspection = {{key = "totalScore", value = totalScore}}}
end

return AreaHealDamage
