local Wargroove = require "wargroove/wargroove"
local GrooveVerb = require "wargroove/groove_verb"
local Combat = require "initialized/combat"
local MoraleBoost = GrooveVerb:new()


function MoraleBoost:getMaximumRange(unit, endPos)
    return 0
end


function MoraleBoost:getTargetType()
    return "unit"
end

local highAlertAnimation = "ui/icons/high_alert"
local highAlertBuffSound = "highAlertBuff"
function MoraleBoost:execute(unit, targetPos, strParam, path)
    print("MoraleBoost")
    Wargroove.setIsUsingGroove(unit.id, true)
    Wargroove.updateUnit(unit)

    Wargroove.playPositionlessSound("battleStart")
    Wargroove.playGrooveCutscene(unit.id)

    local targets = Wargroove.getTargetsInRange(targetPos, 2, "unit")

    Wargroove.playUnitAnimation(unit.id, "groove")
    Wargroove.playMapSound("duchess/duchessGroove", targetPos)
    Wargroove.waitTime(1.1)
    Wargroove.spawnMapAnimation(targetPos, 3, "fx/groove/en_garde_groove_fx", "idle", "behind_units", {x = 12, y = 12})

    Wargroove.playGrooveEffect()

    local function distFromTarget(a)
        return math.abs(a.x - targetPos.x) + math.abs(a.y - targetPos.y)
    end
    table.sort(targets, function(a, b) return distFromTarget(a) < distFromTarget(b) end)

    for i, pos in ipairs(targets) do
        local u = Wargroove.getUnitAt(pos)
        local uc = u.unitClass
        if u ~= nil and Wargroove.areAllies(u.playerId, unit.playerId) and (not uc.isStructure) then
            if (uc.weapons ~= nil) and (uc.weapons[1] ~= nil) and (uc.weapons[1].canMoveAndAttack == true) then
                Wargroove.setUnitState(u, "high_alert", "true")
                Wargroove.highAlertBuff(u)
                Wargroove.playMapSound(highAlertBuffSound,pos)
                Wargroove.updateUnit(u)
                Wargroove.waitTime(0.02)
            end
        end
    end
    Wargroove.waitTime(1.0)
end

function MoraleBoost:generateOrders(unitId, canMove)
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

function MoraleBoost:getScore(unitId, order)
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

return MoraleBoost
