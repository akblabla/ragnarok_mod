local Wargroove = require "wargroove/wargroove"
local Ragnarok = require "initialized/ragnarok"
local Verb = require "wargroove/verb"

local Hire = Verb:new()

local costMultiplier = 1

local defaultUnits = {"soldier", "dog", "spearman", "mage", "archer"}

function Hire:recruitsContain(recruits, unit)
    for i, recruit in pairs(recruits) do
        if recruit == unit then 
           return true
        end
     end
     return false
end

function Hire:getRecruitableTargets(target)
    if target.unitClassId == "villager" then
        return defaultUnits
    else
        return {target.unitClassId}
    end
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
    local canReqruit = Wargroove.getUnitState(unit,"canReqruit")
    return canReqruit ~= nil
end

Hire.inPreExecute = true
Hire.classToRecruit = nil

function Hire:canExecuteWithTarget(unit, endPos, targetPos, strParam)
    if not self:canSeeTarget(targetPos) then
        return false
    end

    local classToRecruit = Hire.classToRecruit
    if classToRecruit == nil then
        classToRecruit = strParam
    end

    if (Hire.inPreExecute) then
        local u = Wargroove.getUnitAt(targetPos)
        if (u ~= nil) then
            local canBeRequired = Wargroove.getUnitState(u,"Recruitable")
            return (canBeRequired ~= nil) and Wargroove.isNeutral(u.playerId)
        end
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

function Hire:preExecute(unit, targetPos, strParam, endPos)
    Hire.inPreExecute = false
    local recruitableUnits = {"soldier", "dog", "spearman", "mage", "archer"}

    local target = Wargroove.getUnitAt(targetPos)
    if target == nil then
        return false, ""
    end

    recruitableUnits = Hire:getRecruitableTargets(target)
    local message = Wargroove.getUnitState(target,"RecruitMessage")
    local messageCharacter = Wargroove.getUnitState(target,"RecruitMessageCharacter")
    local messageExpression = Wargroove.getUnitState(target,"RecruitMessageExpression")
    local messageShout = Wargroove.getUnitState(target,"RecruitMessageShout")
    local messageName = Wargroove.getUnitState(target,"RecruitMessageName")
    local discount = Wargroove.getUnitState(target,"RecruitDiscount")
    if messageExpression == nil then
        messageExpression = "neutral"
    else
        Wargroove.removeUnitState(target, "RecruitMessageExpression")
    end
    if messageCharacter == nil then
        messageCharacter = "generic_villager"
    else
        Wargroove.removeUnitState(target, "RecruitMessageCharacter")
    end
    if messageShout == nil then
        messageShout = ""
    else
        Wargroove.removeUnitState(target, "RecruitMessageShout")
    end
    if messageName == nil then
        messageName = ""
    else
        Wargroove.removeUnitState(target, "RecruitMessageName")
    end
    if discount == nil then
        discount = 0
    else
        discount = 100 - tonumber(discount)
    end
    if message ~= nil then
        Wargroove.showDialogueBox(messageExpression, messageCharacter, message, messageShout, {}, "standard", false, messageName, "neutral")
        Wargroove.removeUnitState(target, "RecruitMessage")
    end
    Wargroove.openRecruitMenu(unit.playerId, unit.id, unit.pos, unit.unitClassId, recruitableUnits, (100-discount)/100.0, defaultUnits, "outlaw");

    while Wargroove.recruitMenuIsOpen() do
        coroutine.yield()
    end

    Hire.classToRecruit = Wargroove.popRecruitedUnitClass();

    Hire.inPreExecute = true
    if Hire.classToRecruit == nil then
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
		u.hadTurn = true
        if (strParam=="rifleman") then
            Wargroove.setUnitState(u, "ammo",3)
        end
		Wargroove.updateUnit(u)
	end

    Wargroove.waitTime(0.2)

    Wargroove.unsetFacingOverride(unit.id)

    strParam = ""
end

function Hire:generateOrders(unitId, canMove)
    local unit = Wargroove.getUnitById(unitId)
    return {}
end

function Hire:getScore(unitId, order)
    local unit = Wargroove.getUnitById(unitId)
    return {score = -1, introspection = {}}
end

return Hire
