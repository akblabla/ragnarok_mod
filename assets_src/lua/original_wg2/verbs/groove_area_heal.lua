local Wargroove = require "wargroove/wargroove"
local GrooveVerb = require "wargroove/groove_verb"

local AreaHeal = GrooveVerb:new()

local healAmount = 20
local healRadius = 3

function AreaHeal:getMaximumRange(unit, endPos)
    return 4
end

function AreaHeal:getTargetType()
  return "all"
end

function AreaHeal:canExecuteWithTarget(unit, endPos, targetPos, strParam)
    if not self:canSeeTarget(targetPos) then
        return false
    end

    local u = Wargroove.getUnitAt(targetPos)
    return (endPos.x ~= targetPos.x or endPos.y ~= targetPos.y) 
        and (u == nil or unit.id == u.id)
        and Wargroove.canStandAt("soldier", targetPos)
end

function AreaHeal:canExecuteGroove(unit)
    local baseExecute = GrooveVerb:canExecuteGroove(unit)

    local tier = self:getCurrentGrooveTier(unit)
    if tier ~= 1 then
        return false
    end

    return baseExecute
end

function AreaHeal:execute(unit, targetPos, strParam, path)
    Wargroove.trackCameraTo(unit.pos)

    Wargroove.setIsUsingGroove(unit.id, true)
    Wargroove.updateUnit(unit)
    
    Wargroove.playPositionlessSound("battleStart")
    Wargroove.playGrooveCutscene(unit.id, 1, "area_heal", "errol")
        
    Wargroove.playUnitAnimation(unit.id, "groove")
    Wargroove.playMapSound("twins/errolGroove", targetPos)
    Wargroove.waitTime(1.2)
    Wargroove.spawnMapAnimation(targetPos, 3, "fx/groove/errol_groove_fx", "idle", "behind_units", {x = 12, y = 12})

    Wargroove.playGrooveEffect()

    local startingState = {}
    local pos = {key = "pos", value = "" .. targetPos.x .. "," .. targetPos.y}
    local radius = {key = "radius", value = tostring(healRadius)}    
    table.insert(startingState, pos)
    table.insert(startingState, radius)
    local hiddenSpawnId = Wargroove.spawnUnit(unit.playerId, { x = -100, y = -100 }, "area_heal_hidden", false, "", startingState)
    
    local hiddenSpawn = { key = "hiddenId", value = tostring(hiddenSpawnId) }
    table.insert(startingState, hiddenSpawn)
    Wargroove.spawnUnit(unit.playerId, targetPos, "area_heal", false, "", startingState)

    for i, pos in ipairs(Wargroove.getTargetsInRange(targetPos, healRadius, "unit")) do
        local u = Wargroove.getUnitAt(pos)
        if u and u.health > 0 and u.health < 100 and (not u.unitClass.isStructure) and (u.playerId >= 0) then
            u:setHealth(u.health + healAmount, unit.id)
            Wargroove.updateUnit(u)
            Wargroove.spawnMapAnimation(pos, 0, "fx/heal_unit")
        end
    end

    Wargroove.playMapSound("twins/errolGrooveZoneHeal", targetPos)

    Wargroove.logAnalyticsAction("UnitAbility", unit.playerId, "groove", unit.unitClassId)

    Wargroove.waitTime(1.2)
end

function AreaHeal:generateOrders(unitId, canMove)
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

function AreaHeal:getScore(unitId, order)
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
                totalScore = totalScore + uc.cost
            else
                totalScore = totalScore - uc.cost
            end
        end
    end
    
    local score = totalScore/maxScore + opportunityCost
    return {score = score, introspection = {{key = "totalScore", value = totalScore}}}
end

return AreaHeal
