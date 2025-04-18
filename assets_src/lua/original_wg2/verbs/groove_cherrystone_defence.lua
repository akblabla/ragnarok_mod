local Wargroove = require "wargroove/wargroove"
local GrooveVerb = require "wargroove/groove_verb"

local CherrystoneDefence = GrooveVerb:new()

local range = {3, 3}
local spawnIds = {"crystal", "crystal_tier_two" }
local allyModifiers = { "", "emeric_range_boost" }
local allyRange = { 0, 3 }

function CherrystoneDefence:getSplashTargets(unit, targetPos, endPos)
    local tier = self:getCurrentGrooveTier(unit)

    local targets = Wargroove.getTargetsInRange(targetPos, range[tier], "all")
    return targets
end


function CherrystoneDefence:getMaximumRange(unit, endPos)
    return 1
end


function CherrystoneDefence:getTargetType()
    return "empty"
end


function CherrystoneDefence:canExecuteWithTarget(unit, endPos, targetPos, strParam)
    if not self:canSeeTarget(targetPos) then
        return false
    end

    local u = Wargroove.getUnitAt(targetPos)
    return (endPos.x ~= targetPos.x or endPos.y ~= targetPos.y) 
        and (u == nil or unit.id == u.id)
        and Wargroove.canStandAt("soldier", targetPos)
end


function CherrystoneDefence:execute(unit, targetPos, strParam, path)
    local tier = self:getCurrentGrooveTier(unit)

    print("Executing groove with tier "..tier)

    Wargroove.setIsUsingGroove(unit.id, true)
    Wargroove.updateUnit(unit)

    if tier == 2 then
        Wargroove.playGrooveChargeUp(unit.pos, unit.playerId)
    end
    
    Wargroove.playPositionlessSound("battleStart")
    Wargroove.playGrooveCutscene(unit.id, tier)
        
    Wargroove.playUnitAnimation(unit.id, "groove")
    Wargroove.playMapSound("emeric/emericGroove", targetPos)
    Wargroove.waitTime(1.3)
    Wargroove.playGrooveEffect()
    Wargroove.spawnUnit(unit.playerId, targetPos, spawnIds[tier], false, "spawn")

    coroutine.yield()

    if tier == 2 then
        for i, pos in ipairs(Wargroove.getTargetsInRange(targetPos, allyRange[tier], "unit")) do
            local u = Wargroove.getUnitAt(pos)
             if Wargroove.areAllies(u.playerId, unit.playerId) and u.id ~= unit.id and #u.unitClass.weapons > 0 and u.unitClass.weapons[1].maxRange > 1 then
                 Wargroove.spawnMapAnimation(pos, 0, "fx/groove/inspire_unit")
                
                local modifier = allyModifiers[tier]
                if modifier ~= "" then
                    Wargroove.pushUnitClassModifier(u.id, modifier)
                    Wargroove.setUnitState(u, "emeric_range_boost", "true")
                end
                
                Wargroove.updateUnit(u)
            end
        end
    end

    Wargroove.logAnalyticsAction("UnitAbility", unit.playerId, "groove", unit.unitClassId)

    Wargroove.waitTime(1.2)
end

function CherrystoneDefence:generateOrders(unitId, canMove)
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
            if target ~= pos and self:canSeeTarget(target) and Wargroove.canStandAt("soldier", target) then
                orders[#orders+1] = {targetPosition = target, strParam = "", movePosition = pos, endPosition = pos}
            end
        end
    end

    return orders
end

function CherrystoneDefence:getScore(unitId, order)
    local unit = Wargroove.getUnitById(unitId)
    local tier = self:getCurrentGrooveTier(unit)
    local targets = Wargroove.getTargetsInRangeAfterMove(unit, order.endPosition, order.targetPosition, range[tier], "unit")

    local opportunityCost = -1
    local totalScore = 0
    local maxScore = 300

    for i, pos in ipairs(targets) do
        local u = Wargroove.getUnitAt(pos)
        if u ~= nil and u.playerId == unit.playerId then
            local uc = Wargroove.getUnitClass(u.unitClassId)
            if not uc.isStructure then
                totalScore = totalScore + uc.cost
            end
        end
    end
    
    local score = totalScore/maxScore + opportunityCost
    return {score = score, introspection = {{key = "totalScore", value = totalScore}}}
end

return CherrystoneDefence
