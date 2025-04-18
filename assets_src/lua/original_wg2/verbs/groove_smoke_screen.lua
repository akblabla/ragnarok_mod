local Wargroove = require "wargroove/wargroove"
local GrooveVerb = require "wargroove/groove_verb"

local SmokeScreen = GrooveVerb:new()

local smokeRadius = {2, 2}
local smokeRange = {6, 12}

function SmokeScreen:getMaximumRange(unit, endPos)
    local tier = self:getCurrentGrooveTier(unit)
    return smokeRange[tier]
end

function SmokeScreen:getTargetType()
  return "all"
end

function SmokeScreen:canExecuteWithTarget(unit, endPos, targetPos, strParam)
    if not self:canSeeTarget(targetPos) then
        return false
    end

    return true
end

function SmokeScreen:getSplashTargets(unit, targetPos, endPos)
    local tier = self:getCurrentGrooveTier(unit)
    local targets = Wargroove.getTargetsInRange(targetPos, smokeRadius[tier], "all")
    return targets
end

function SmokeScreen:execute(unit, targetPos, strParam, path)
    local tier = self:getCurrentGrooveTier(unit)
    Wargroove.setIsUsingGroove(unit.id, true)
    Wargroove.updateUnit(unit)

    if tier == 2 then
        Wargroove.playGrooveChargeUp(unit.pos, unit.playerId)
    end
    
    Wargroove.playPositionlessSound("battleStart")
    Wargroove.playGrooveCutscene(unit.id, tier)

    Wargroove.playUnitAnimation(unit.id, "groove")
    Wargroove.playMapSound("vesper/vesperGroove", unit.pos)
    Wargroove.waitTime(1.0)
    Wargroove.playMapSound("cutscene/smokeBomb", targetPos)
    Wargroove.spawnMapAnimation(targetPos, 3, "fx/groove/vesper_groove_fx", "idle", "over_units", {x = 12, y = 12})

    Wargroove.playGrooveEffect()

    local startingState = {}
    local pos = {key = "pos", value = "" .. targetPos.x .. "," .. targetPos.y}
    local smokeTier = {key = "tier", value = tostring(tier)}
    table.insert(startingState, pos)
    table.insert(startingState, smokeTier)
    Wargroove.spawnUnit(unit.playerId, {x = -100, y = -100}, "smoke_producer", false, "", startingState)

    -- Also spawn Shadow Sisters at tier 2
    if tier == 2 then
        local values = { unit.id, unit.unitClassId, unit.pos.x, unit.pos.y, Wargroove.getTurnNumber(), Wargroove.getCurrentPlayerId() }
        local str = ""
        for i, v in ipairs(values) do
            str = str .. tostring(v) .. ":"
        end

        local spawnPositions = Wargroove.getTargetsInRange(unit.pos, smokeRadius[tier], "empty")
        local filteredSpawnPositions = {}
        for _, pos in pairs(spawnPositions) do
            if Wargroove.canStandAt("shadow_vesper", pos) then
                table.insert(filteredSpawnPositions, pos)
            end
        end
        
        local spawnNumber = math.min(#filteredSpawnPositions, 2)
        -- If there are still shadow sisters visible, we remove them now. Player is limited to 2 sisters
        local sisters = Wargroove.getAllUnitsOfType(unit.playerId, "shadow_vesper")
        local killNumber = math.min(spawnNumber, #sisters)
        if killNumber > 0 then
            for i=1, killNumber do
                sisters[i]:setHealth(0, unit.id)
                Wargroove.updateUnit(sisters[i])
            end
        end

        if #filteredSpawnPositions > 0 then
            for i=1, spawnNumber, 1 do
                local pick = Wargroove.randomInteger(str, 1, #filteredSpawnPositions)
                Wargroove.spawnUnit(unit.playerId, filteredSpawnPositions[pick], "shadow_vesper", true)
                table.remove(filteredSpawnPositions, pick)
            end
        end
    end

    Wargroove.waitTime(1.0)

    Wargroove.logAnalyticsAction("UnitAbility", unit.playerId, "groove", unit.unitClassId)
end

function SmokeScreen:generateOrders(unitId, canMove)
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
            if target ~= pos and self:canSeeTarget(target) then
                orders[#orders+1] = {targetPosition = target, strParam = "", movePosition = pos, endPosition = pos}
            end
        end
    end

    return orders
end

function SmokeScreen:getScore(unitId, order)
    local unit = Wargroove.getUnitById(unitId)
    local targets = Wargroove.getTargetsInRangeAfterMove(unit, order.endPosition, order.targetPosition, 2, "unit")

    local opportunityCost = -1
    local totalScore = 0
    local maxScore = 300

    for i, pos in ipairs(targets) do
        local u = Wargroove.getUnitAt(pos)
        if u ~= nil then
            local uc = Wargroove.getUnitClass(u.unitClassId)
            if not Wargroove.areEnemies(unit.playerId, u.playerId) then
                totalScore = totalScore + uc.cost
            else
                totalScore = totalScore - uc.cost
            end
        end
    end
    
    local score = totalScore/maxScore + opportunityCost
    return {score = score, introspection = {{key = "totalScore", value = totalScore}}}
end

return SmokeScreen
