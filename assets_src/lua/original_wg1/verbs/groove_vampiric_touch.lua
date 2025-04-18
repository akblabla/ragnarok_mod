local Wargroove = require "wargroove/wargroove"
local GrooveVerb = require "wargroove/groove_verb"

local VampiricTouch = GrooveVerb:new()


function VampiricTouch:getMaximumRange(unit, endPos)
    return 1
end


function VampiricTouch:getTargetType()
    return "unit"
end

function VampiricTouch:canExecuteWithTarget(unit, endPos, targetPos, strParam)
    if not self:canSeeTarget(targetPos) then
        return false
    end

    local targetUnit = Wargroove.getUnitAt(targetPos)

    if not targetUnit or not Wargroove.areEnemies(unit.playerId, targetUnit.playerId) or (not targetUnit.canBeAttacked) then
        return false
    end

    if targetUnit.unitClass.isCommander or targetUnit.unitClass.isStructure then
        return false
    end

    for i, tag in ipairs(targetUnit.unitClass.tags) do
        if tag == "summon" then
            return false
        end
    end

    return true
end

function VampiricTouch:execute(unit, targetPos, strParam, path)
    Wargroove.setIsUsingGroove(unit.id, true)
    Wargroove.updateUnit(unit)

    Wargroove.playPositionlessSound("battleStart")
    Wargroove.playGrooveCutscene(unit.id)

    local facingOverride = ""
    local effectSequence = ""
    if targetPos.x == unit.pos.x and targetPos.y > unit.pos.y then
        effectSequence = "groove_down"
    elseif targetPos.x == unit.pos.x and targetPos.y < unit.pos.y then
        effectSequence = "groove_up"
    elseif targetPos.x > unit.pos.x then
        facingOverride = "right"
        effectSequence = "groove"
    else 
        facingOverride = "left"
        effectSequence = "groove"
    end

    Wargroove.setFacingOverride(unit.id, facingOverride)

    Wargroove.playUnitAnimation(unit.id, "groove")
    Wargroove.playMapSound("sigrid/sigridGroove", targetPos)
    Wargroove.waitTime(0)

    Wargroove.spawnMapAnimation(unit.pos, 0, "fx/groove/sigrid_groove_fx", effectSequence, "over_units", { x = 12, y = 12 }, facingOverride)

    Wargroove.waitTime(1.0)
    
    local u = Wargroove.getUnitAt(targetPos)
    if u.health then
        unit:setHealth(unit.health + u.health, unit.id)
        u:setHealth(0, unit.id)
        Wargroove.updateUnit(u)
        Wargroove.playUnitAnimation(u.id, "hit")
    end

    Wargroove.playGrooveEffect()

    Wargroove.unsetFacingOverride(unit.id)

    Wargroove.waitTime(1.0)
end

function VampiricTouch:generateOrders(unitId, canMove)
    local orders = {}

    local unit = Wargroove.getUnitById(unitId)
    local unitClass = Wargroove.getUnitClass(unit.unitClassId)
    local movePositions = {}
    if canMove then
        movePositions = Wargroove.getTargetsInRange(unit.pos, unitClass.moveRange, "empty")
    end
    table.insert(movePositions, unit.pos)

    for i, pos in pairs(movePositions) do
        local targets = Wargroove.getTargetsInRangeAfterMove(unit, pos, pos, 1, "unit")
        for j, targetPos in pairs(targets) do
            local u = Wargroove.getUnitAt(targetPos)
            if u ~= nil then
                local uc = Wargroove.getUnitClass(u.unitClassId)
                if self:canExecuteWithTarget(unit, pos, targetPos, "") and not Wargroove.hasAIRestriction(u.id, "dont_target_this") then
                    orders[#orders+1] = {targetPosition = targetPos, strParam = "", movePosition = pos, endPosition = pos}
                end
            end
        end
    end

    return orders
end

function VampiricTouch:getScore(unitId, order)
    local unit = Wargroove.getUnitById(unitId)
    local unitClass = Wargroove.getUnitClass(unit.unitClassId)
    local unitValue = 10
    
    local targetUnit = Wargroove.getUnitAt(order.targetPosition)
    local targetUnitClass = Wargroove.getUnitClass(targetUnit.unitClassId)
    local targetUnitValue = math.sqrt(targetUnitClass.cost / 100)

    local unitHealth = unit.health
    local targetHealth = targetUnit.health

    local myHealthDelta = math.min(unitHealth + targetHealth, 100) - unitHealth
    local myDelta = myHealthDelta / 100 * unitValue
    local theirDelta = targetHealth / 100 * targetUnitValue

    local score = myDelta + theirDelta

    return { score = score, healthDelta = myHealthDelta, introspection = {
        { key = "unitValue", value = unitValue },
        { key = "targetUnitValue", value = targetUnitValue },
        { key = "myHealthDelta", value = myHealthDelta },
        { key = "myDelta", value = myDelta },
        { key = "theirDelta", value = theirDelta }}}
end

return VampiricTouch
