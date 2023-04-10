local Wargroove = require "wargroove/wargroove"
local Ragnarok = require "initialized/ragnarok"
local Verb = require "wargroove/verb"

local Hire = Verb:new()

local costMultiplier = 1

local defaultUnits = {"soldier", "spearman", "archer", "mage"}

function Hire:recruitsContain(recruits, unit)
    for i, recruit in pairs(recruits) do
        if recruit == unit then 
           return true
        end
     end
     return false
end

function Hire:getRecruitableTargets(unit)
    local allUnits = Wargroove.getAllUnitsForPlayer(unit.playerId, true)
    local recruitableUnits = {}
    for i, unit in pairs(allUnits) do
        for i, recruit in pairs(unit.recruits) do
            
            if not Hire.recruitsContain(self, recruitableUnits, recruit) then
                recruitableUnits[#recruitableUnits + 1] = recruit
            end
        end
    end

    if #recruitableUnits == 0 then
        recruitableUnits = defaultUnits
    end

    return recruitableUnits
end


function Hire:getMaximumRange(unit, endPos)
	return 1
end

local function getCost(cost)
    return math.floor(cost * costMultiplier + 0.5)
end


function Hire:getTargetType()
    return "all"
end

function Hire:canExecuteAnywhere(unit)
    return true
end

Hire.classToRecruit = nil

function Hire:canExecuteWithTarget(unit, endPos, targetPos, strParam)
    if not self:canSeeTarget(targetPos) then
        return false
    end

    local classToRecruit = Hire.classToRecruit
    if classToRecruit == nil then
        classToRecruit = strParam
    end

    local u = Wargroove.getUnitAt(targetPos)
    if (classToRecruit == "") then
        return u ~= nil and u.unitClassId == "villager"
    end

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
    return (endPos.x ~= targetPos.x or endPos.y ~= targetPos.y) and ((u ~= nil and u.unitClassId == "villager")) and Wargroove.canStandAt(classToRecruit, targetPos) and Wargroove.getMoney(unit.playerId) >= getCost(uc.cost)
end

function Hire:preExecute(unit, targetPos, strParam, endPos)
    local recruitableUnits = Hire.getRecruitableTargets(self, unit);

    Wargroove.openRecruitMenu(unit.playerId, unit.id, unit.pos, unit.unitClassId, recruitableUnits, costMultiplier, defaultUnits, "outlaw");

    while Wargroove.recruitMenuIsOpen() do
        coroutine.yield()
    end

    Hire.classToRecruit = Wargroove.popRecruitedUnitClass();

    if Hire.classToRecruit == nil then
        return false, ""
    end

    Wargroove.selectTarget()

    while Wargroove.waitingForSelectedTarget() do
        coroutine.yield()
    end

    local target = Wargroove.getSelectedTarget()

    if (target == nil) then
        Hire.classToRecruit = nil
        return false, ""
    end

    return true, Hire.classToRecruit
end

function Hire:execute(unit, targetPos, strParam, path)

    Hire.classToRecruit = nil

    if strParam == nil then
        print("Hire strParam is nil.")
        return
    end
    if strParam == "" then
        print("Hire was not given a class to recruit.")
        return
    end

    local facingOverride = ""
    if targetPos.x > unit.pos.x then
        facingOverride = "right"
    elseif targetPos.x < unit.pos.x then
        facingOverride = "left"
    end

    if facingOverride ~= "" then
        Wargroove.setFacingOverride(unit.id, facingOverride)
    end

    Wargroove.updateUnit(unit)
    Wargroove.playMapSound("wulfarShoutFollowMe",targetPos)

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

	if u then
		print(strParam)
		u.unitClassId = strParam
		u.playerId = unit.playerId
		Wargroove.updateUnit(u)
	end

    Wargroove.waitTime(0.2)

    Wargroove.unsetFacingOverride(unit.id)

    strParam = ""
end


return Hire
