local Wargroove = require "wargroove/wargroove"
local Verb = require "wargroove/verb"
local Ragnarok = require "initialized/ragnarok"
local StealthManager = require "scripts/stealth_manager"

local Death = Verb:new()
local deathVerbList = {}

function Death.addDeathVerb(fun)
--	table.insert(deathVerbList,fun)
end
local stateKey = "gold"
function Death:giveGold(unit, targetPos, strParam, path)
    local killedById = tonumber(strParam)

    if killedById == unit.id then
        return
    end

    local killedByUnit = Wargroove.getUnitById(killedById)

    if (killedByUnit == nil) then
        return
    end

    local amountCarried = Wargroove.getUnitState(unit, stateKey)
    
    if (amountCarried == nil) then
        return
    end
    if amountCarried == 75 or amountCarried == "75" then
        Wargroove.waitTime(0.5)
        Wargroove.spawnMapAnimation(unit.pos, 0, "fx/75g", "default", "over_units", { x = 12, y = 0 })
        Wargroove.waitTime(0.2)
        Wargroove.playMapSound("thiefDeposit", unit.pos)
    end
    Wargroove.changeMoney(killedByUnit.playerId, amountCarried)
end

function Death:execute(unit, targetPos, strParam, path)
	local Ragnarok = require "initialized/ragnarok"
	local crownPos = Ragnarok.getCrownPos()
	if crownPos and crownPos.x == unit.pos.x and crownPos.y == unit.pos.y then
		Wargroove.waitTime(0.3)
		Ragnarok.dropCrown(unit.pos)
        unit.itemId = ""
		Wargroove.waitTime(0.2)
	end
    print("Death:execute")
    print("unit: "..unit.unitClassId)
    print("item id: "..unit.itemId)
    if (unit.unitClassId == "thief" or unit.unitClassId == "thief_with_gold") and unit.itemId ~= "" and unit.itemId ~= nil then
        
        local ic = Wargroove.getItem(unit.itemId)
	    Wargroove.spawnItemAt(ic.id, unit.pos)
    end
	-- for i,deathVerb in pairs(deathVerbList) do
	-- 	self:deathVerb(unit, targetPos, strParam, path)
	-- end
	self:giveGold(unit, targetPos, strParam, path)
end


return Death
