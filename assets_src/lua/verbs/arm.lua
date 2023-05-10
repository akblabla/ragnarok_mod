local Wargroove = require "wargroove/wargroove"
local Ragnarok = require "initialized/ragnarok"
local Verb = require "wargroove/verb"

local Arm = Verb:new()

local costMultiplier = 1

local defaultUnits = {"soldier", "spearman", "archer", "mage"}

function Arm:recruitsContain(recruits, unit)
    for i, recruit in pairs(recruits) do
        if recruit == unit then 
           return true
        end
     end
     return false
end

function Arm:getRecruitableTargets(unit)
    return defaultUnits
end


function Arm:getMaximumRange(unit, endPos)
	return 0
end

local function getCost(cost)
    return math.floor(cost * costMultiplier + 0.5)
end


function Arm:getTargetType()
    return "all"
end

local enabledPlayerList = {}

function Arm.enableForPlayer(playerId)
    enabledPlayerList[playerId] = true;
end

function Arm:canExecuteAnywhere(unit)
    return (enabledPlayerList[unit.playerId] ~= nil) and (enabledPlayerList[unit.playerId] == true)
end

Arm.inPreExecute = true
Arm.classToRecruit = nil

function Arm:canExecuteWithTarget(unit, endPos, targetPos, strParam)
    if not self:canSeeTarget(targetPos) then
        return false
    end

    local classToRecruit = Arm.classToRecruit
    if classToRecruit == nil then
        classToRecruit = strParam
    end

    if (Arm.inPreExecute) then
        return true
    else

        -- Check if this player can recruit this type of unit
        local isDefault = false
        for i, unitClass in ipairs(defaultUnits) do
            if (unitClass == classToRecruit) then
                isDefault = true
            end
        end
        if not isDefault and not Wargroove.canPlayerRecruit(unit.playerId, classToRecruit) then
            return false
        end

        local uc = Wargroove.getUnitClass(classToRecruit)
        return Wargroove.getMoney(unit.playerId) >= getCost(uc.cost)
    end
end

function Arm:preExecute(unit, targetPos, strParam, endPos)
    Arm.inPreExecute = false
    local recruitableUnits = Arm.getRecruitableTargets(self, unit);

    Wargroove.openRecruitMenu(unit.playerId, unit.id, unit.pos, unit.unitClassId, recruitableUnits, costMultiplier, defaultUnits, "outlaw");

    while Wargroove.recruitMenuIsOpen() do
        coroutine.yield()
    end

    Arm.classToRecruit = Wargroove.popRecruitedUnitClass();

    Arm.inPreExecute = true
    if Arm.classToRecruit == nil then
        return false, ""
    end

    return true, Arm.classToRecruit
end

function Arm:execute(unit, targetPos, strParam, path)

    Arm.classToRecruit = nil

    if strParam == nil then
        print("Arm strParam is nil.")
        return
    end
    if strParam == "" then
        print("Arm was not given a class to recruit.")
        return
    end

    Wargroove.waitTime(0.2)
    Wargroove.playMapSound("thiefGoldReleased", targetPos)
    Wargroove.spawnMapAnimation(unit.pos, 0, "fx/ransack_1", "default", "over_units", { x = 12, y = 0 })
    Wargroove.waitTime(1.0)
    Wargroove.spawnMapAnimation(targetPos, 0, "fx/ransack_2", "default", "over_units", { x = 12, y = 0 })
    Wargroove.waitTime(0.2)
    Wargroove.playMapSound("thiefDeposit", targetPos)
    Wargroove.waitTime(0.4)
    local uc = Wargroove.getUnitClass(strParam)
    Wargroove.changeMoney(unit.playerId, -getCost(uc.cost))
 --   Wargroove.spawnUnit(unit.playerId, targetPos, strParam, false, "", "", "floran")

	local u = Wargroove.getUnitAt(targetPos)

    unit.unitClassId = strParam
    unit.hadTurn = true
    Wargroove.updateUnit(unit)

    Wargroove.waitTime(0.2)

    strParam = ""
end

function Arm:generateOrders(unitId, canMove)
    local unit = Wargroove.getUnitById(unitId)
    return {}
end

function Arm:getScore(unitId, order)
    local unit = Wargroove.getUnitById(unitId)
    return {score = -1, introspection = {}}
end

return Arm
