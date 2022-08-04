local Wargroove = require "wargroove/wargroove"
local GrooveVerb = require "wargroove/groove_verb"

local AreaDamage = GrooveVerb:new()

function AreaDamage:getMaximumRange(unit, endPos)
    return 6
end

function AreaDamage:getTargetType()
  return "all"
end

function AreaDamage:canExecuteWithTarget(unit, endPos, targetPos, strParam)
    if not self:canSeeTarget(targetPos) then
        return false
    end

    return true
end

function AreaDamage:execute(unit, targetPos, strParam, path)
    Wargroove.trackCameraTo(unit.pos)

    Wargroove.setIsUsingGroove(unit.id, true)
    Wargroove.updateUnit(unit)
    
    Wargroove.playPositionlessSound("battleStart")
    Wargroove.playGrooveCutscene(unit.id, "area_damage", "orla")
        
    --Wargroove.playUnitAnimation(unit.id, "groove2")
    Wargroove.playMapSound("twins/orlaGroove", unit.pos)
    Wargroove.waitTime(1.9)
	Wargroove.trackCameraTo(targetPos)
    Wargroove.playMapSound("twins/orlaGrooveEffect", targetPos)
    Wargroove.spawnMapAnimation(targetPos, 3, "fx/groove/orla_groove_fx", "idle", "behind_units", {x = 12, y = 12})

    Wargroove.playGrooveEffect()

    local startingState = {}
    local pos = {key = "pos", value = "" .. targetPos.x .. "," .. targetPos.y}
    local radius = {key = "radius", value = "0"}    
    table.insert(startingState, pos)
    table.insert(startingState, radius)
    Wargroove.spawnUnit(unit.playerId, {x = -100, y = -100}, "area_damage", false, "", startingState)

    Wargroove.waitTime(1.2)
end

function AreaDamage:generateOrders(unitId, canMove)
    local orders = {}

    local unit = Wargroove.getUnitById(unitId)
    local unitClass = Wargroove.getUnitClass(unit.unitClassId)
    local movePositions = {}
    if canMove then
        movePositions = Wargroove.getTargetsInRange(unit.pos, unitClass.moveRange, "empty")
    end
    table.insert(movePositions, unit.pos)

    for i, pos in pairs(movePositions) do
        local targets = Wargroove.getAllUnitsForPlayer(0, false)
        for j, target in pairs(targets) do
            if target.pos ~= pos and self:canSeeTarget(target.pos) then
                orders[#orders+1] = {targetPosition = target.pos, strParam = "", movePosition = pos, endPosition = pos}
            end
        end
    end

    return orders
end

function AreaDamage:getScore(unitId, order)
    local unit = Wargroove.getUnitById(unitId)
    local targets = Wargroove.getTargetsInRangeAfterMove(unit, order.endPosition, order.targetPosition, 3, "unit")

    local opportunityCost = -1
    local totalScore = 0
    local maxScore = 500

    for i, pos in ipairs(targets) do
        local u = Wargroove.getUnitAt(pos)
        if u ~= nil and (not u.unitClass.isStructure) then
            local uc = u.unitClass
            if Wargroove.isHuman(u.playerId) then
                totalScore = totalScore + uc.cost
            else
                totalScore = totalScore - uc.cost
            end
        end
    end
    
    local score = totalScore/maxScore + opportunityCost
    return {score = score, introspection = {{key = "totalScore", value = totalScore}}}
end

return AreaDamage
