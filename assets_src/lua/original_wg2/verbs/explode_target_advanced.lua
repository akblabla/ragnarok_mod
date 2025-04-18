local Wargroove = require "wargroove/wargroove"
local Verb = require "wargroove/verb"

local ExplodeTargetAdvanced = Verb:new()

local attackRange = 6
local explosionRange = 1
local damage = 30
local pushDamage = 20

function ExplodeTargetAdvanced:getMaximumRange(unit, endPos)
    return attackRange
end

function ExplodeTargetAdvanced:getTargetType()
    return "unit"
end

function ExplodeTargetAdvanced:canExecuteWithTarget(unit, endPos, targetPos, strParam)
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

function ExplodeTargetAdvanced:execute(unit, targetPos, strParam, path)
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
    for i, pos in ipairs(targets) do
        local u = Wargroove.getUnitAt(pos)
        if u and u.health > 0 and (not u.unitClass.isStructure) and (u.playerId ~= -1) then
            local deltaX = clamp(pos.x - targetPos.x, -1, 1)
            local deltaY = clamp(pos.y - targetPos.y, -1, 1)

            Wargroove.spawnMapAnimation(pos, 0, "fx/mapeditor_unitdrop")

            local pushPosition = { x=pos.x + deltaX, y=pos.y + deltaY }
            local pushPositionUnit = Wargroove.getUnitAt(pushPosition)

            if pushPositionUnit == nil and not u.unitClass.isStructure then
                Wargroove.moveUnitToOverride(u.id, pushPosition, 0, 0, 10)
                u.pos = pushPosition
                while (Wargroove.isLuaMoving(u.id)) do
                    coroutine.yield()
                end
            end
            if pushPositionUnit ~= nil then
                pushPositionUnit:setHealth(pushPositionUnit.health - pushDamage, unit.id)
                Wargroove.updateUnit(pushPositionUnit)
                Wargroove.playUnitAnimation(pushPositionUnit.id, "hit")
            end
            
            Wargroove.waitTime(0.15)
            u:setHealth(u.health - damage, unit.id)
            Wargroove.updateUnit(u)
            Wargroove.playUnitAnimation(u.id, "hit")
        end
    end

    Wargroove.playMapSound("fish_laugh", targetPos)

    Wargroove.waitTime(0.2)
end

function ExplodeTargetAdvanced:generateOrders(unitId, canMove)
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

function ExplodeTargetAdvanced:getScore(unitId, order)
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

return ExplodeTargetAdvanced