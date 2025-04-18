local Wargroove = require "wargroove/wargroove"
local Combat = require "wargroove/combat"
local GrooveVerb = require "wargroove/groove_verb"

local SadisticRush = GrooveVerb:new()


function SadisticRush:getMaximumRange(unit, endPos)
    return 1
end


function SadisticRush:getTargetType()
    return "unit"
end


function SadisticRush:canExecuteWithTarget(unit, endPos, targetPos, strParam)
    if not self:canSeeTarget(targetPos) then
        return false
    end

    local targetUnit = Wargroove.getUnitAt(targetPos)

    if not targetUnit or not Wargroove.areEnemies(unit.playerId, targetUnit.playerId) or (not targetUnit.canBeAttacked) then
        return false
    end

    if targetUnit.unitClass.isStructure then
        return false
    end

    for i, tag in ipairs(targetUnit.unitClass.tags) do
        if tag == "summon" then
            return false
        end
    end

    return true
end

function SadisticRush:execute(unit, targetPos, strParam, path)
    local facingOverride = nil
    if targetPos.x > unit.pos.x then
        facingOverride = "right"
    else 
        facingOverride = "left"
    end

    if (facingOverride ~= nil) then
        Wargroove.setFacingOverride(unit.id, facingOverride)
    end

    Wargroove.setIsUsingGroove(unit.id, true)
    Wargroove.updateUnit(unit)

    Wargroove.playPositionlessSound("battleStart")
    Wargroove.playGrooveCutscene(unit.id)

    Wargroove.playUnitAnimation(unit.id, "groove_1")
    Wargroove.playMapSound("sedge/sedgeGroove", targetPos)
    Wargroove.waitTime(1)

    local u = Wargroove.getUnitAt(targetPos)
    Wargroove.setVisibleOverride(unit.id, false)
    Wargroove.waitTime(0.8)
    Wargroove.spawnMapAnimation(targetPos, 0, "fx/groove/sedge_groove_fx", "idle", "sky", { x = 12, y = 12 })

    Wargroove.playGrooveEffect()

    Wargroove.playUnitAnimation(u.id, "hit")
    if u.health then
        u:setHealth(u.health - 35, unit.id)
        Wargroove.updateUnit(u)
    end

    Wargroove.waitTime(0.6)    

    Wargroove.unsetVisibleOverride(unit.id)
    if u.health > 0 then
        Wargroove.playUnitAnimation(unit.id, "groove_2")
        Wargroove.waitTime(0.4)
    else
        Wargroove.playUnitAnimation(unit.id, "groove_3")
        Wargroove.waitTime(1.2)
    end

    Wargroove.unsetFacingOverride(unit.id)
end

function SadisticRush:onPostUpdateUnit(unit, targetPos, strParam, path)
    GrooveVerb.onPostUpdateUnit(self, unit, targetPos, strParam, path)
    local u = Wargroove.getUnitAt(targetPos)
    if not u or u.health == 0 then
        unit.hadTurn = false
        unit.grooveCharge = unit.unitClass.maxGroove
    end
end

function SadisticRush:generateOrders(unitId, canMove)
    local orders = {}

    local unit = Wargroove.getUnitById(unitId)
    local unitClass = Wargroove.getUnitClass(unit.unitClassId)
    local movePositions = {}
    if canMove then
        movePositions = Wargroove.getTargetsInRange(unit.pos, unitClass.moveRange, "empty")
    end
    table.insert(movePositions, unit.pos)

    local function canTarget(pos, u)
        if Wargroove.hasAIRestriction(u.id, "dont_target_this") then
            return false
        end

        if Wargroove.hasAIRestriction(unit.id, "only_target_commander") and not u.unitClass.isCommander then
            return false
        end

        return self:canExecuteWithTarget(unit, pos, u.pos, "")
    end

    for i, pos in pairs(movePositions) do
        local targets = Wargroove.getTargetsInRangeAfterMove(unit, pos, pos, 1, "unit")
        for j, targetPos in pairs(targets) do
            local u = Wargroove.getUnitAt(targetPos)
            if u ~= nil and canTarget(pos, u) then
                local uc = Wargroove.getUnitClass(u.unitClassId)
                orders[#orders+1] = {targetPosition = targetPos, strParam = "", movePosition = pos, endPosition = pos}
            end
        end
    end

    return orders
end

function SadisticRush:getScore(unitId, order)
    local unit = Wargroove.getUnitById(unitId)

    local targetUnit = Wargroove.getUnitAt(order.targetPosition)
    local targetUnitClass = Wargroove.getUnitClass(targetUnit.unitClassId)

    if targetUnitClass.isCommander and targetUnit.health <= 35 then
        return {score = 100000, introspection = {{key = "unitCost", value = targetUnitClass.cost}, {key = "unitHealth", value = targetUnit.health}, {key = "maxScore", value = maxScore}}}
    end

    local opportunityCost = -1

    local score = 0
    if targetUnit.health <= 35 then
        score = 100
    end

    local unitCost = targetUnitClass.cost
    local unitHealth = targetUnit.health / 100

    local totalScore = score * unitCost * unitHealth + opportunityCost
    return {score = totalScore, introspection = {
        {key = "unitCost", value = targetUnitClass.cost},
        {key = "unitHealth", value = targetUnit.health},
        {key = "maxScore", value = maxScore},
        {key = "opportunityCost", value = opportunityCost}}}
end

return SadisticRush
