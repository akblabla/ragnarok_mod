local Wargroove = require "wargroove/wargroove"
local GrooveVerb = require "wargroove/groove_verb"

local Drain = GrooveVerb:new()

function Drain:getMaximumRange(unit, endPos)
    return 0
end


function Drain:getTargetType()
    return "unit"
end


function Drain:execute(unit, targetPos, strParam, path)
    Wargroove.setIsUsingGroove(unit.id, true)
    Wargroove.updateUnit(unit)

    Wargroove.playPositionlessSound("battleStart")
    Wargroove.playGrooveCutscene(unit.id)

    local targets = Wargroove.getTargetsInRange(targetPos, 3, "unit")

    Wargroove.playUnitAnimation(unit.id, "groove")
    Wargroove.playMapSound("darkmercia/darkmerciaGroove", targetPos)
    Wargroove.waitTime(2.4)
    Wargroove.spawnPaletteSwappedMapAnimation(targetPos, 3, "fx/groove/darkmercia_groove_fx", "idle", "behind_units", {x = 12, y = 12})

    Wargroove.playGrooveEffect()

    local function distFromTarget(a)
        return math.abs(a.x - targetPos.x) + math.abs(a.y - targetPos.y)
    end
    table.sort(targets, function(a, b) return distFromTarget(a) < distFromTarget(b) end)

    local healthDrained = 0

    for i, pos in ipairs(targets) do
        local u = Wargroove.getUnitAt(pos)
        local uc = u.unitClass
        if u ~= nil and Wargroove.areEnemies(u.playerId, unit.playerId) and (not uc.isStructure) then
            healthDrained = healthDrained + math.min(u.health, 30)

            u:setHealth(u.health - 30, unit.id)            
            Wargroove.updateUnit(u)
            Wargroove.spawnPaletteSwappedMapAnimation(pos, 0, "fx/drain_unit")
            Wargroove.playMapSound("darkmercia/darkmerciaGrooveUnitDrained", pos)
            Wargroove.waitTime(0.2)
        end
    end

    unit:setHealth(unit.health + healthDrained, unit.id)

    Wargroove.waitTime(0.6)
end

function Drain:generateOrders(unitId, canMove)
    local orders = {}

    local unit = Wargroove.getUnitById(unitId)
    local unitClass = Wargroove.getUnitClass(unit.unitClassId)
    local movePositions = {}
    if canMove then
        movePositions = Wargroove.getTargetsInRange(unit.pos, unitClass.moveRange, "empty")
    end
    table.insert(movePositions, unit.pos)

    for i, pos in pairs(movePositions) do
        local targets = Wargroove.getTargetsInRangeAfterMove(unit, pos, pos, 3, "unit")
        if #targets ~= 0 then
            if self:canSeeTarget(pos) then
                orders[#orders+1] = {targetPosition = pos, strParam = "", movePosition = pos, endPosition = pos}
            end
        end
    end

    return orders
end

function Drain:getScore(unitId, order)
    local unit = Wargroove.getUnitById(unitId)
    local targets = Wargroove.getTargetsInRangeAfterMove(unit, order.endPosition, order.targetPosition, 3, "unit")

    local opportunityCost = -1

    local function canTarget(u)
        if not Wargroove.areEnemies(u.playerId, unit.playerId) then
            return false
        end
        if Wargroove.hasAIRestriction(unit.id, "only_target_commander") and not u.unitClass.isCommander then
            return false
        end
        if Wargroove.hasAIRestriction(u.id, "dont_target_this") then
            return false
        end
        return true
    end

    local damageDrained = 0
    local damageOthersScore = 0
    for i, pos in ipairs(targets) do
        local u = Wargroove.getUnitAt(pos)
        if u ~= nil and canTarget(u) then
            local targetClass = Wargroove.getUnitClass(u.unitClassId)
            local targetValue = math.sqrt(targetClass.cost / 100)
            if targetClass.isCommander then
              targetValue = 10
            end
            local damage = math.min(u.health, 30)
            damageDrained = damageDrained + damage
            if not targetClass.isStructure then
                damageOthersScore = damageOthersScore + (damage / 100) * targetValue
            end
        end
    end

    local uc = Wargroove.getUnitClass(unit.unitClassId)
    local unitValue = 10
    local healAmount = math.min(damageDrained, 100 - unit.health)
    local healSelfScore = (healAmount / 100) * unitValue

    local score = opportunityCost + damageOthersScore + healSelfScore
    return { score = score, healthDelta = healAmount, introspection = {
        { key = "opportunityCost", value = opportunityCost },
        { key = "damageOthersScore", value = damageOthersScore },
        { key = "healSelfScore", value = healSelfScore }}}
end

return Drain
