local Wargroove = require "wargroove/wargroove"
local Verb = require "wargroove/verb"


--------------------
local conversionRate = 0.75    -- This is how much money the player gets back for refunding
--------------------
local Refund = Verb:new()

function Refund:getMaximumRange(unit, endPos)
    return 1
end


function Refund:getTargetType()
    return "unit"
end


function Refund:canExecuteWithTarget(unit, endPos, targetPos, strParam)
    if not self:canSeeTarget(targetPos) then
        return false
    end

    local targetUnit = Wargroove.getUnitAt(targetPos)

    if not targetUnit or not (targetUnit.unitClassId == "barracks" or targetUnit.unitClassId == "tower" or targetUnit.unitClassId == "port") then
        return false
    end

    if not Wargroove.isInList(unit.unitClassId, targetUnit.recruits) then
        return false
    end

    return true
end

local function getSurroundingRecruiters(unit, pos)
    result = {}
    for i, p in ipairs(Wargroove.getTargetsInRangeAfterMove(unit, pos, pos, 1, "unit")) do
        local recruiter = Wargroove.getUnitAt(p)
        if recruiter and #recruiter.recruits > 0 and Wargroove.areAllies(unit.playerId, recruiter.playerId) then
            table.insert(result, recruiter)
        end
    end
    return result
end

function Refund:canExecuteAt(unit, endPos)
    if not Verb.canExecuteAt(self, unit, endPos) then
        return false
    end

    local recruiters = getSurroundingRecruiters(unit, endPos)
    local validRecruiters = { }
    for _, recruiter in ipairs(recruiters) do
        if Wargroove.isInList(unit.unitClassId, recruiter.recruits) then
            table.insert(validRecruiters, recruiter)
        end
    end

    return #validRecruiters > 0
end

local function getRefundAmount(unit)
    local fullCost = Wargroove.getUnitClass(unit.unitClassId, unit.id).cost
    return math.ceil((unit.health * fullCost / 100) * conversionRate)
end


function Refund:getCostAt(unit, endPos, targetPos)
    return -getRefundAmount(unit)
end


function Refund:execute(unit, targetPos, strParam, path)
    local refundAmount = getRefundAmount(unit)

    if not Wargroove.isWater(unit.pos) then
        Wargroove.spawnMapAnimation(unit.pos, 1, "fx/mapeditor_unitdrop")
    end

    unit:setHealth(0, unit.id)
    Wargroove.setVisibleOverride(unit.id, false)
    Wargroove.updateUnit(unit)

    Wargroove.waitTime(1.0)
    Wargroove.changeMoney(unit.playerId, refundAmount)

    Wargroove.playPositionlessSound("thiefGoldObtained")

    local units = Wargroove.getAllUnitsForPlayer(unit.playerId)
    for _, unit in ipairs(units) do
        if unit.unitClass.isCommander then
            Wargroove.spawnMapAnimation(unit.pos, 0, "fx/ransack_1", "default", "over_units", { x = 12, y = 0 })
            break
        end
    end
end

return Refund
