local Wargroove = require "wargroove/wargroove"
local GrooveVerb = require "wargroove/groove_verb"

local Heal = GrooveVerb:new()


local maxHealAmount = 50


function Heal:getMaximumRange(unit, endPos)
    return 0
end


function Heal:getTargetType()
    return "unit"
end


function Heal:execute(unit, targetPos, strParam, path)
    Wargroove.setIsUsingGroove(unit.id, true)
    Wargroove.updateUnit(unit)

    Wargroove.playPositionlessSound("battleStart")
    Wargroove.playGrooveCutscene(unit.id)

    local targets = Wargroove.getTargetsInRange(targetPos, 3, "unit")

    Wargroove.playUnitAnimation(unit.id, "groove")
    Wargroove.playMapSound("mercia/merciaGroove", targetPos)
    Wargroove.waitTime(2.1)
    Wargroove.spawnMapAnimation(targetPos, 3, "fx/groove/mercia_groove_fx", "idle", "behind_units", {x = 12, y = 12})

    Wargroove.playGrooveEffect()

    local function distFromTarget(a)
        return math.abs(a.x - targetPos.x) + math.abs(a.y - targetPos.y)
    end
    table.sort(targets, function(a, b) return distFromTarget(a) < distFromTarget(b) end)

    for i, pos in ipairs(targets) do
        local u = Wargroove.getUnitAt(pos)
        local uc = u.unitClass
        if u ~= nil and Wargroove.areAllies(u.playerId, unit.playerId) and (not uc.isStructure) then
            u:setHealth(u.health + maxHealAmount, unit.id)
            Wargroove.updateUnit(u)
            Wargroove.spawnMapAnimation(pos, 0, "fx/heal_unit")
            Wargroove.playMapSound("unitHealed", pos)
            Wargroove.waitTime(0.2)
        end
    end
    Wargroove.waitTime(1.0)
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
    local targets = Wargroove.getTargetsInRangeAfterMove(unit, order.endPosition, order.targetPosition, 3, "unit")

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
            local healAmount = math.min(maxHealAmount, 100 - u.health)
            if not uc.isStructure then
                healOthersScore = healOthersScore + (healAmount / 100) * uValue
            end
        end
    end

    local unitClass = Wargroove.getUnitClass(unit.unitClassId)
    local unitValue = 10
    local healAmount = math.min(maxHealAmount, 100 - unit.health)
    local healSelfScore = (healAmount / 100) * unitValue
    
    local score = opportunityCost + healOthersScore + healSelfScore

    return { score = score, healthDelta = healAmount, introspection = {
        { key = "opportunityCost", value = opportunityCost },
        { key = "healOthersScore", value = healOthersScore },
        { key = "healSelfScore", value = healSelfScore }}}
end

return Heal
