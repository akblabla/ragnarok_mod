local Wargroove = require "wargroove/wargroove"
local Ragnarok = require "initialized/ragnarok"
local Verb = require "wargroove/verb"

local Upgrade = Verb:new()

local costMultiplier = 1

local defaultUnits = {"soldier", "dog", "spearman", "mage", "archer", "knight", "rifleman"}

function Upgrade:recruitsContain(recruits, unit)
    for i, recruit in pairs(recruits) do
        if recruit == unit then 
           return true
        end
     end
     return false
end

function Upgrade:getRecruitableTargets(unit)
    local recruits = {}
    for i,recruit in pairs(defaultUnits) do
        if recruit~=unit.unitClassId then
            table.insert(recruits,recruit)
        end
    end
    return recruits
end


function Upgrade:getMaximumRange(unit, endPos)
	return 0
end

local function getCost(cost)
    return math.floor(cost * costMultiplier + 0.5)
end


function Upgrade:getTargetType()
    return "all"
end

function Upgrade:canExecuteAnywhere(unit)
    return true
end

Upgrade.inPreExecute = true
Upgrade.classToRecruit = nil

function Upgrade:canExecuteWithTarget(unit, endPos, targetPos, strParam)
    if not self:canSeeTarget(targetPos) then
        return false
    end
    if (unit.unitClassId~="villager") then
        local neighbours = Wargroove.getTargetsInRange(targetPos, 1, "unit");
        local isTavern = false;
        for i,tile in pairs(neighbours) do
            local neighbour = Wargroove.getUnitAt(tile)
            if (neighbour~=nil) and (neighbour.unitClassId == "tavern") then
                isTavern = true
            end
        end
        if isTavern == false then
            return false
        end
    end

    local classToRecruit = Upgrade.classToRecruit
    if classToRecruit == nil then
        classToRecruit = strParam
    end

    if (Upgrade.inPreExecute) then
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

function Upgrade:preExecute(unit, targetPos, strParam, endPos)
    Upgrade.inPreExecute = false
    local recruitableUnits = Upgrade.getRecruitableTargets(self, unit);

    Wargroove.openRecruitMenu(unit.playerId, unit.id, unit.pos, unit.unitClassId, recruitableUnits, costMultiplier, defaultUnits, "outlaw");

    while Wargroove.recruitMenuIsOpen() do
        coroutine.yield()
    end

    Upgrade.classToRecruit = Wargroove.popRecruitedUnitClass();

    Upgrade.inPreExecute = true
    if Upgrade.classToRecruit == nil then
        return false, ""
    end

    return true, Upgrade.classToRecruit
end

function Upgrade:execute(unit, targetPos, strParam, path)

    Upgrade.classToRecruit = nil

    if strParam == nil then
        print("Upgrade strParam is nil.")
        return
    end
    if strParam == "" then
        print("Upgrade was not given a class to recruit.")
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

    unit.unitClassId = strParam
    unit:setHealth(100,-1)
    unit.hadTurn = true
    if (strParam=="rifleman") then
        Wargroove.setUnitState("ammo",3)
    end
    Wargroove.updateUnit(unit)

    Wargroove.waitTime(0.2)

    strParam = ""
end

function Upgrade:generateOrders(unitId, canMove)
    local unit = Wargroove.getUnitById(unitId)
    return {}
end

function Upgrade:getScore(unitId, order)
    local unit = Wargroove.getUnitById(unitId)
    return {score = -1, introspection = {}}
end

return Upgrade
