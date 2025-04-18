local Wargroove = require "wargroove/wargroove"
local Verb = require "wargroove/verb"

local SpellHex = Verb:new()
local spellCost = 300
local spellDamage = 10
local costScoreFactor = 0.5
local effectRange = 4


function SpellHex:getMaximumRange(unit, endPos)
    return 0
end


function SpellHex:getTargetType()
    return "all"
end


function SpellHex:canExecuteAnywhere(unit)
    return Wargroove.getMoney(unit.playerId) >= spellCost
end


function SpellHex:getCostAt(unit, endPos, targetPos)
    return spellCost
end


function SpellHex:execute(unit, targetPos, strParam, path)
    Wargroove.changeMoney(unit.playerId, -spellCost)
    local targets = Wargroove.getTargetsInRange(targetPos, effectRange, "unit")

    local function distFromTarget(a)
        return math.abs(a.x - targetPos.x) + math.abs(a.y - targetPos.y)
    end
    table.sort(targets, function(a, b) return distFromTarget(a) < distFromTarget(b) end)

    Wargroove.spawnMapAnimation(targetPos, effectRange, "fx/hex_spell", "idle", "behind_units", {x = 13, y = 16})
    Wargroove.playMapSound("witchSpell", targetPos)
    Wargroove.waitTime(1.35)


    for i, pos in ipairs(targets) do
        local u = Wargroove.getUnitAt(pos)
        if u ~= nil then
            local uc = u.unitClass
            if Wargroove.areEnemies(u.playerId, unit.playerId) and (not uc.isStructure) then
                u:setHealth(u.health - spellDamage, unit.id)
                Wargroove.updateUnit(u)
                Wargroove.spawnMapAnimation(pos, 0, "fx/hex_spell_hit")
                Wargroove.playMapSound("darkmercia/darkmerciaGrooveUnitDrained", pos)
                Wargroove.playUnitAnimation(u.id, "hit")
                Wargroove.waitTime(0.1)
            end
        end
    end
    Wargroove.waitTime(0.3)
end


function SpellHex:generateOrders(unitId, canMove)
    local orders = {}
    if Wargroove.hasAIRestriction(unitId, "cant_attack") then
        return orders
    end

    local unit = Wargroove.getUnitById(unitId)
    local unitClass = Wargroove.getUnitClass(unit.unitClassId)

    if not self:canExecuteAnywhere(unit) then
      return orders
    end

    local movePositions = {}
    if canMove then
        movePositions = Wargroove.getTargetsInRange(unit.pos, unitClass.moveRange, "empty")
    end
    table.insert(movePositions, unit.pos)

    for i, pos in ipairs(movePositions) do
        local anyTargets = false
        local targets = Wargroove.getTargetsInRangeAfterMove(unit, pos, pos, effectRange, "unit")
        for j, targetPos in ipairs(targets) do
            local u = Wargroove.getUnitAt(targetPos)
            if u ~= nil then
                local uc = Wargroove.getUnitAt(targetPos)
                if Wargroove.areEnemies(u.playerId, unit.playerId) and (not uc.isStructure) then
                    anyTargets = true
                end
            end
        end
        if anyTargets then
            table.insert(orders, { targetPosition = pos, strParam = "", movePosition = pos, endPosition = pos })
        end
    end

    return orders
end


function SpellHex:getScore(unitId, order)
    local unit = Wargroove.getUnitById(unitId)
    local unitClass = Wargroove.getUnitClass(unit.unitClassId)

    local damageScore = 0

    local function canTarget(u)
        if Wargroove.hasAIRestriction(u.id, "dont_target_this") then
            return false
        end
        if Wargroove.hasAIRestriction(unitId, "only_target_commander") and not u.unitClass.isCommander then
            return false
        end
        return Wargroove.areEnemies(u.playerId, unit.playerId) and not u.unitClass.isStructure
    end

    local targets = Wargroove.getTargetsInRangeAfterMove(unit, order.movePosition, order.targetPosition, effectRange, "unit")
    for i, targetPos in ipairs(targets) do
        local u = Wargroove.getUnitAt(targetPos)
        if u ~= nil and canTarget(u) then
            local uc = Wargroove.getUnitClass(u.unitClassId)
            local unitValue = math.sqrt(uc.cost / 100)
            if uc.isCommander then
                unitValue = 10
            end
            damageScore = damageScore + (spellDamage / 100) * unitValue
        end
    end

    local costScore = -math.sqrt(spellCost / 100) * costScoreFactor
    local score = damageScore + costScore

    return { score = score, healthDelta = 0, introspection = {
        { key = "damageScore", value = damageScore },
        { key = "cost", value = spellCost },
        { key = "costScore", value = costScore }}}
end


return SpellHex
