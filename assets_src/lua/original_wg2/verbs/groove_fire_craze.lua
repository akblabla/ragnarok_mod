local Wargroove = require "wargroove/wargroove"
local GrooveVerb = require "wargroove/groove_verb"
local Combat = require "wargroove/combat"

local FireCraze = GrooveVerb:new()


local maxDamage = {0.5, 0.75}
local maxRange = {5, 5}
local maxTargets = {3, 5}
local burn = {false, true}


function FireCraze:getMaximumRange(unit, endPos)
    return 0
end


function FireCraze:getTargetType()
    return "unit"
end


function FireCraze:getSplashTargets(unit, targetPos, endPos)
    local tier = self:getCurrentGrooveTier(unit)
    local targets = Wargroove.getTargetsInRange(targetPos, maxRange[tier], "all")
    return targets
end


function FireCraze:execute(unit, targetPos, strParam, path)
    local tier = self:getCurrentGrooveTier(unit)

    local targets = Wargroove.getTargetsInRange(targetPos, maxRange[tier], "all")

    -- Build possible targets
    local unitTargets = {}

    for i, pos in ipairs(targets) do
        local u = Wargroove.getUnitAt(pos)

        if u ~= nil then
            local uc = u.unitClass
            if not Wargroove.areAllies(u.playerId, unit.playerId) and (not uc.isStructure) then
                table.insert(unitTargets, u)
            end
        end
    end

    -- Pick random x targets from table
    local finalTargets = {}
    local values = { unit.id, unit.unitClassId, unit.pos.x, unit.pos.y, Wargroove.getTurnNumber(), Wargroove.getCurrentPlayerId() }
    local str = ""
    for i, v in ipairs(values) do
        str = str .. tostring(v) .. ":"
    end

    local numberTargets = math.min(maxTargets[tier], #unitTargets)
    for i=1,numberTargets,1 do
        local pick = Wargroove.randomInteger(str, 1, #unitTargets)

        table.insert(finalTargets, unitTargets[pick])
        table.remove(unitTargets, pick)
    end

    local function distFromTarget(a)
        return math.abs(a.x - targetPos.x) + math.abs(a.y - targetPos.y)
    end
    table.sort(targets, function(a, b) return distFromTarget(a) < distFromTarget(b) end)

    Wargroove.setIsUsingGroove(unit.id, true)
    Wargroove.updateUnit(unit)

    if tier == 2 then
        Wargroove.playGrooveChargeUp(unit.pos, unit.playerId)
    end

    Wargroove.playPositionlessSound("battleStart")
    Wargroove.playGrooveCutscene(unit.id, tier)

    Wargroove.playMapSound("nadia/nadiaGroove", unit.pos)
    if tier == 2 then
        Wargroove.playUnitAnimation(unit.id, "groove2")
    else
        Wargroove.playUnitAnimation(unit.id, "groove")
    end
    Wargroove.waitTime(1.25)
    Wargroove.playGrooveEffect()

    -- Visual bomb effect
    -- Wargroove.spawnMapAnimation(unit.pos, 2, "units/commanders/nadia/nadia_area_explosion", "idle", "behind_units", { x = 12, y = 12 })
    Wargroove.waitTime(0.35)

    -- Do burn effect on randomized targets
    for i, u in ipairs(finalTargets) do
        local damage = Combat:getGrooveAttackerDamage(unit, u, "average", unit.pos, u.pos, path, nil) * maxDamage[tier]
        u:setHealth(u.health - damage, unit.id)
        Wargroove.updateUnit(u)
        Wargroove.playUnitAnimation(u.id, "hit")
        
        local isBurning = Wargroove.getUnitState(u, "burning")

        Wargroove.playMapSound("nadia/nadiaGrooveHit", u.pos)
        Wargroove.spawnMapAnimation(u.pos, 1, "units/commanders/nadia/nadia_burn_fx_front", "idle", "over_units", {x = 13, y = 16})
        Wargroove.spawnMapAnimation(u.pos, 1, "units/commanders/nadia/nadia_burn_fx_back", "idle", "units", {x = 13, y = 16})

        -- We prevent double burns
        if (isBurning == nil or isBurning == "false") and burn[tier] == true then
            Wargroove.setUnitState(u, "burning", "true")
            Wargroove.updateUnit(u)

            local startingState = {}
            local unitId = {key = "unitId", value = u.id}
            table.insert(startingState, unitId)
            Wargroove.spawnUnit(unit.playerId, {x = -100, y = -100}, "burn", false, "", startingState)

            Wargroove.displayBuffVisualEffect(u.id, u.playerId, "units/commanders/nadia/nadia_constant_burn_fx_back", "spawn", 1.0, nil, "units", {x = 0, y = -1}, false, false)
            Wargroove.displayBuffVisualEffect(u.id, u.playerId, "units/commanders/nadia/nadia_constant_burn_fx_front", "spawn", 1.0, nil, "over_units", {x = 0, y = 3}, false, false)
        end
    end

    Wargroove.waitTime(1.0);
    Wargroove.clearBuffVisualEffect(unit.id)

    Wargroove.waitTime(1.0)
end

function FireCraze:generateOrders(unitId, canMove)
    local orders = {}

    local unit = Wargroove.getUnitById(unitId)
    local unitClass = Wargroove.getUnitClass(unit.unitClassId)
    local tier = self:getCurrentGrooveTier(unit)

    local movePositions = {}
    if canMove then
        movePositions = Wargroove.getTargetsInRange(unit.pos, unitClass.moveRange, "empty")
    end
    table.insert(movePositions, unit.pos)

    for i, pos in pairs(movePositions) do
        local targets = Wargroove.getTargetsInRange(pos, maxRange[tier], "unit")

        local numValidTargets = 0
        for i, pos in ipairs(targets) do
            local u = Wargroove.getUnitAt(pos)
            if u ~= nil then
                local uc = u.unitClass
                if not Wargroove.areAllies(u.playerId, unit.playerId) and (not uc.isStructure) then
                    numValidTargets = numValidTargets + 1
                end
            end
        end

        if numValidTargets ~= 0 then
            orders[#orders+1] = {targetPosition = pos, strParam = "", movePosition = pos, endPosition = pos}
        end
    end

    return orders
end

function FireCraze:getScore(unitId, order)
    local unit = Wargroove.getUnitById(unitId)
    local tier = self:getCurrentGrooveTier(unit)

    local targets = Wargroove.getTargetsInRange(order.endPosition, maxRange[tier], "unit")

    local opportunityCost = 0.75 * tier
    local totalScore = 0
    local numValidTargets = 0

    for i, pos in ipairs(targets) do
        local u = Wargroove.getUnitAt(pos)
        if u ~= nil then
            local uc = u.unitClass
            if not Wargroove.areAllies(u.playerId, unit.playerId) and (not uc.isStructure) then
                totalScore = totalScore + uc.cost
                numValidTargets = numValidTargets + 1
            end
        end
    end

    local numTargetsToHit = math.min(maxTargets[tier], numValidTargets)
    local score = (totalScore / numValidTargets) * numTargetsToHit / 100.0 + opportunityCost

    --print("fire_craze: score " .. score)

    local introspection = {
        {key = "totalScore", value = totalScore},
        {key = "numValidTargets", value = numValidTargets}
    }

    return {score = score, introspection = introspection}
end

return FireCraze
