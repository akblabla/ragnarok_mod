local Wargroove = require "wargroove/wargroove"
local GrooveVerb = require "wargroove/groove_verb"

local Heal = GrooveVerb:new()

local maxHealAmount = { 50, 75 }
local healRadius = { 3, 3 }
local armyHeal = { 0, 10 }
local tierUsed

function Heal:getMaximumRange(unit, endPos)
    return 0
end


function Heal:getSplashTargets(unit, targetPos, endPos)
    local tier = self:getCurrentGrooveTier(unit)

    local targets = Wargroove.getTargetsInRange(targetPos, healRadius[tier], "all")
    return targets
end


function Heal:getTargetType()
    return "unit"
end


function Heal:execute(unit, targetPos, strParam, path)
    local tier = self:getCurrentGrooveTier(unit)

    -- Storing this for later
    tierUsed = tier

    Wargroove.setIsUsingGroove(unit.id, true)
    Wargroove.updateUnit(unit)

    if tier == 2 then
        Wargroove.playGrooveChargeUp(unit.pos, unit.playerId)
    end

    Wargroove.playPositionlessSound("battleStart")
    Wargroove.playGrooveCutscene(unit.id, tier)

    local targets = Wargroove.getTargetsInRange(targetPos, healRadius[tier], "unit")

    Wargroove.playUnitAnimation(unit.id, "groove")
    Wargroove.playMapSound("mercia/merciaGroove", targetPos)
    Wargroove.waitTime(2.1)
    if tier == 1 then
        Wargroove.spawnMapAnimation(targetPos, healRadius[tier], "fx/groove/mercia_groove_fx", "idle", "behind_units", {x = 12, y = 12})
    else
        Wargroove.spawnMapAnimation(targetPos, healRadius[tier], "fx/groove/mercia_groove_fx2", "idle", "behind_units", {x = 12, y = 12})
    end

    Wargroove.playGrooveEffect()

    local function distFromTarget(a)
        return math.abs(a.x - targetPos.x) + math.abs(a.y - targetPos.y)
    end
    table.sort(targets, function(a, b) return distFromTarget(a) < distFromTarget(b) end)

    for i, pos in ipairs(targets) do
        local u = Wargroove.getUnitAt(pos)
        local uc = u.unitClass
        if u ~= nil and Wargroove.areAllies(u.playerId, unit.playerId) and (not uc.isStructure) then
            if tier == 2 and u.id == unit.id then
                -- tier 2 fully heals mercia
                u:setHealth(100, unit.id)
            else
                u:setHealth(u.health + maxHealAmount[tier], unit.id)
            end

            Wargroove.updateUnit(u)
            if tier == 2 then
                Wargroove.spawnMapAnimation(pos, 0, "fx/groove/aoe_heal_unit2")
            else
                Wargroove.spawnMapAnimation(pos, 0, "fx/heal_unit")
            end
            Wargroove.playMapSound("unitHealed", pos)
            Wargroove.waitTime(0.2)
        end
    end

    if tier == 2 then
        local playerUnits = Wargroove.getAllUnitsForPlayer(unit.playerId, false)
        for i, u in ipairs(playerUnits) do
            if not u.unitClass.isStructure then
                u:setHealth(u.health + armyHeal[tier], unit.id)
                Wargroove.updateUnit(u)
                Wargroove.spawnMapAnimation(u.pos, 0, "fx/heal_unit")
            end
        end
        
        Wargroove.playMapSound("unitHealed", unit.pos)
    end

    Wargroove.waitTime(1.0)

    Wargroove.logAnalyticsAction("UnitAbility", unit.playerId, "groove", unit.unitClassId)
end

function Heal:onPostUpdateUnit(unit, targetPos, strParam, path)
    GrooveVerb.onPostUpdateUnit(self, unit, targetPos, strParam, path)
end

function Heal:generateOrders(unitId, canMove)
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
            orders[#orders+1] = {targetPosition = pos, strParam = "", movePosition = pos, endPosition = pos}
        end
    end

    return orders
end

function Heal:getScore(unitId, order)
    local unit = Wargroove.getUnitById(unitId)
    local tier = self:getCurrentGrooveTier(unit)

    local targets = Wargroove.getTargetsInRangeAfterMove(unit, order.endPosition, order.targetPosition, healRadius[tier], "unit")

    local opportunityCost = -1

    local healOthersScore = 0
    for i, pos in ipairs(targets) do
        local u = Wargroove.getUnitAt(pos)
        if u ~= nil and u.playerId == unit.playerId and u.armyId ~= unit.armyId then
            local uc = Wargroove.getUnitClass(u.unitClassId)
            local uValue = math.sqrt(uc.cost / 100)
            if uc.isCommander then
              uValue = 10
            end
            local healAmount = math.min(maxHealAmount[tier], 100 - u.health)
            if not uc.isStructure then
                healOthersScore = healOthersScore + (healAmount / 100) * uValue
            end
        end
    end

    local unitClass = Wargroove.getUnitClass(unit.unitClassId)
    local unitValue = 10
    local healAmount = math.min(maxHealAmount[tier], 100 - unit.health)
    local healSelfScore = (healAmount / 100) * unitValue
    
    local score = opportunityCost + healOthersScore + healSelfScore

    return { score = score, healthDelta = healAmount, introspection = {
        { key = "opportunityCost", value = opportunityCost },
        { key = "healOthersScore", value = healOthersScore },
        { key = "healSelfScore", value = healSelfScore }}}
end

return Heal
