local Wargroove = require "wargroove/wargroove"
local GrooveVerb = require "wargroove/groove_verb"
local Combat = require "initialized/combat"
local Confusion = GrooveVerb:new()


function Confusion:getMaximumRange(unit, endPos)
    return 2
end


function Confusion:getTargetType()
    return "unit"
end

function Confusion:canExecuteWithTarget(unit, endPos, targetPos, strParam)
    if not self:canSeeTarget(targetPos) then
        return false
    end

    local targetUnit = Wargroove.getUnitAt(targetPos)

    if not targetUnit or (not targetUnit.canBeAttacked) then
        return false
    end

    if targetUnit.unitClass.isStructure then
        return false
    end

    return true
end

function Confusion:execute(unit, targetPos, strParam, path)
    print("MoraleBoost")
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

    print(1)
    Wargroove.setFacingOverride(unit.id, facingOverride)

    Wargroove.playUnitAnimation(unit.id, "groove")
    Wargroove.waitTime(0)
    print(2)

    Wargroove.spawnMapAnimation(unit.pos, 0, "fx/groove/sigrid_groove_fx", effectSequence, "over_units", { x = 12, y = 12 }, facingOverride)

    Wargroove.waitTime(1.0)
    print(3)
    
    for i, neighbourPos in ipairs(Wargroove.getTargetsInRange(targetPos, 1, "unit")) do
        local u = Wargroove.getUnitAt(targetPos)
        print(4)
        if (u~=nil) and (u.health>0) then
            print(5)
            local neighbour = Wargroove.getUnitAt(neighbourPos)
            if (u.id~=neighbour.id) and (neighbour.hadTurn == false) then
                print(6)
                Combat:forceAttack(neighbour, u,0.5)
                print(7)
            end
        end
    end
    print(8)

    Wargroove.playGrooveEffect()

    print(9)
    Wargroove.unsetFacingOverride(unit.id)

    print(10)
    Wargroove.waitTime(1.0)
    print(11)
end

function Confusion:generateOrders(unitId, canMove)
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

function Confusion:getScore(unitId, order)
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

return Confusion
