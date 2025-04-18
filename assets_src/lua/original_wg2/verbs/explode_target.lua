local Wargroove = require "wargroove/wargroove"
local Verb = require "wargroove/verb"

local ExplodeTarget = Verb:new()

local attackRange = 4
local explosionRange = 1
local damage = 30

function ExplodeTarget:getMaximumRange(unit, endPos)
    return attackRange
end

function ExplodeTarget:getTargetType()
    return "unit"
end

function ExplodeTarget:canExecuteWithTarget(unit, endPos, targetPos, strParam)
    if not self:canSeeTarget(targetPos) then
        return false
    end

    local targetUnit = Wargroove.getUnitAt(targetPos)

    if not targetUnit or (not targetUnit.canBeAttacked) or (not targetUnit.unitClass.isAttackable) then
        return false
    end
    
    if targetUnit.unitClass.isCommander or targetUnit.unitClass.isStructure then
        return false
    end

    if not Wargroove.areAllies(targetUnit.playerId, unit.playerId) then
        return false
    end

    for i, tag in ipairs(targetUnit.unitClass.tags) do
        if tag == "summon" then
            return false
        end
    end

    return true
end

function ExplodeTarget:execute(unit, targetPos, strParam, path)
    local targetUnit = Wargroove.getUnitAt(targetPos)
    if targetUnit == nil then
        return
    end

    Wargroove.trackCameraTo(targetUnit.pos)
    Wargroove.waitTime(0.7)

    Wargroove.spawnMapAnimation(targetUnit.pos, 1, "fx/groove/koji_groove_fx", "idle", "behind_units", { x = 12, y = 12 })
    Wargroove.playMapSound("koji/kojiDroneExplode", targetUnit.pos)
    targetUnit:setHealth(0, targetUnit.id)
    Wargroove.updateUnit(targetUnit)

    local targets = Wargroove.getTargetsInRange(targetUnit.pos, explosionRange, "unit")
    if targets then
        for i, pos in ipairs(targets) do
            local u = Wargroove.getUnitAt(pos)
            if u and u.health > 0 and (not u.unitClass.isStructure) and (u.playerId ~= -1) then
                u:setHealth(u.health - damage, unit.id)
                Wargroove.playUnitAnimation(u.id, "hit")
                Wargroove.updateUnit(u)
            end
        end
    end

    Wargroove.playMapSound("fish_laugh", targetPos)

    Wargroove.waitTime(0.2)
end

function ExplodeTarget:generateOrders(unitId, canMove)
    local orders = {}

    local unit = Wargroove.getUnitById(unitId)
    local unitClass = Wargroove.getUnitClass(unit.unitClassId)
    local movePositions = {}
    if canMove then
        movePositions = Wargroove.getTargetsInRange(unit.pos, unitClass.moveRange, "empty")
    end
    table.insert(movePositions, unit.pos)

    for i, pos in pairs(movePositions) do
        local targets = Wargroove.getTargetsInRangeAfterMove(unit, pos, pos, attackRange, "unit")
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

function ExplodeTarget:getScore(unitId, order)
    local unit = Wargroove.getUnitById(unitId)
    local targetUnit = Wargroove.getUnitAt(order.targetPosition)

    local balance = 0

    local targets = Wargroove.getTargetsInRange(targetUnit.pos, explosionRange, "unit")
    if targets then
        for i, pos in ipairs(targets) do
            local u = Wargroove.getUnitAt(pos)
            local uc = Wargroove.getUnitClass(u.unitClassId)
            if u and u.health > 0 and (not u.unitClass.isStructure) and (u.playerId ~= -1) then
                if not Wargroove.areAllies(u.playerId, unit.playerId) then
                    -- damaging an enemy unit is scored higher than one of our own
                    balance = balance + damage * uc.cost * 1.5
                elseif u.id ~= targetUnit.id then
                    balance = balance - damage * uc.cost
                    if u.id == unitId then
                        -- it hurts to hit yourself
                        balance = balance - damage * uc.cost
                    end
                end
            end
        end
    end

    local score = balance / (100 * damage)

    return { score = score, introspection = {}}
end

return ExplodeTarget