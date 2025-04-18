local Wargroove = require "wargroove/wargroove"
local GrooveVerb = require "wargroove/groove_verb"
local Combat = require "wargroove/combat"

local PowerfulForm = GrooveVerb:new()

local modifiers = { "rhomb_rage_medium", "rhomb_rage_high"}

function PowerfulForm:canExecuteWithTarget(unit, endPos, targetPos, strParam)
    if not self:canSeeTarget(targetPos) then
        return false
    end

    local u = Wargroove.getUnitAt(targetPos)
    local uc = Wargroove.getUnitClass("soldier")
    return (u == nil or u.id == unit.id) and Wargroove.canStandAt("soldier", targetPos)
end


function PowerfulForm:execute(unit, targetPos, strParam, path)
    local tier = self:getCurrentGrooveTier(unit)

    Wargroove.setIsUsingGroove(unit.id, true)
    Wargroove.updateUnit(unit)

    if tier == 2 then
        Wargroove.playGrooveChargeUp(unit.pos, unit.playerId)
    end

    Wargroove.playPositionlessSound("battleStart")
    Wargroove.playGrooveCutscene(unit.id, tier)

    Wargroove.playUnitAnimation(unit.id, "groove")
    
    Wargroove.playMapSound("rhomb/rhombGroove", unit.pos)

    if tier == 2 then
        Wargroove.waitTime(0.0)
        Wargroove.spawnMapAnimation(unit.pos, 2, "units/commanders/rhomb/rhomb_groove_effect2", "idle", "over_units", { x = 10, y = 12 })
        Wargroove.waitTime(0.85)
    else
        Wargroove.waitTime(0.85)
        Wargroove.spawnMapAnimation(unit.pos, 2, "units/commanders/rhomb/rhomb_groove_effect", "idle", "over_units", { x = 10, y = 12 })
    end

    Wargroove.waitTime(0.57)

    Wargroove.playGrooveEffect()

    unit.unitClassId = "commander_rhomb_angry"
    unit.hadTurn = false
    unit.grooveCharge = 0
    unit.canChargeGroove = false
    Wargroove.updateUnit(unit)
    Wargroove.waitFrame()
    Wargroove.playUnitAnimation(unit.id, "groove")

    Wargroove.waitTime(0.2)

    Wargroove.pushBuff(1, unit, unit.playerId, "", "rhomb_rage", "rhomb_rage_death")

    Wargroove.setUnitState(unit, "rage", modifiers[tier])
    Wargroove.pushUnitClassModifier(unit.id, modifiers[tier])
    Wargroove.updateUnit(unit)
end

function PowerfulForm:onPostUpdateUnit(unit, targetPos, strParam, path)
    GrooveVerb.onPostUpdateUnit(self, unit, targetPos, strParam, path)
    
    unit.hadTurn = false
end

function PowerfulForm:generateOrders(unitId, canMove)
    local orders = {}

    local unit = Wargroove.getUnitById(unitId)
    local unitClass = Wargroove.getUnitClass(unit.unitClassId)

    local movePositions = {}
    if canMove then
        movePositions = Wargroove.getTargetsInRange(unit.pos, unitClass.moveRange, "empty")
    end
    table.insert(movePositions, unit.pos)

    for i, pos in ipairs(movePositions) do
        if self:canExecuteWithTarget(unit, pos, pos, "") then
            orders[#orders+1] = {targetPosition = pos, strParam = "", movePosition = pos, endPosition = pos}
        end
    end

    return orders
end

function PowerfulForm:getScore(unitId, order)
    -- just evaluates the score of being Angry Rhomb at the target position
    local score = Wargroove.getAILocationScore("commander_rhomb_angry", order.endPosition)
    local introspection = {}
    return {score = score, introspection = introspection}
end

return PowerfulForm
