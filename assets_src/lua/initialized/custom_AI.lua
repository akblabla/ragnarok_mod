local Wargroove = require "wargroove/wargroove"
local Ragnarok = require "initialized/ragnarok"
local Recruit = require "verbs/recruit"
local Events = require "wargroove/events"

local CustomAI = {}
function CustomAI.init()
	Ragnarok.addAction(CustomAI.spendRest,"repeating",false)
end

local function isProductionStucture(unit)
	return next(unit.recruits) ~= nil
end
local function rotate(vector)
	return {x = -vector.y, y = vector.x}
end

local valueReductionPerUnit = {
	archer = 0.8,
	ballista = 0.3,
	dog = 0.8,
	dragon = 0.8,
	giant = 0.9,
	harpoonship = 0.7,
	harpy = 0.9,
	knight = 0.9,
	mage = 0.9,
	merman = 0.9,
	rifleman = 0.5,
	soldier = 0.95,
	spearman = 0.95,
	trebuchet = 0.5,
	turtle = 0.8,
	warship = 0.8,
	witch = 0.6
}

local bannedUnits = {
	pirate_ship = true,
	wagon = true,
	balloon = true,
	travelboat = true,
	flare = true
}

local function isUnitClassBanned(unitClassId)
	return bannedUnits[unitClassId] == true
end

local unitCount = {}
local function getUnitValue(unitClassId)
	if valueReductionPerUnit[unitClassId] == nil or unitCount[unitClassId] == nil then
		return Wargroove.getUnitClass(unitClassId).cost
	else
		return Wargroove.getUnitClass(unitClassId).cost*valueReductionPerUnit[unitClassId]^unitCount[unitClassId]
	end
end

function CustomAI.spendRest(context)
	print("spendRest starts here")
	if context:checkState("endOfTurn") then
		print("it is the end of the turn")
		local playerId = Wargroove.getCurrentPlayerId();
		print("Player of the day is: " .. tostring(playerId))
		if Wargroove.isHuman(playerId) == true then
			print("Is Human")
			return
		end
		print("Is AI")
		unitCount = {}
		local barracksCount = 0
		for i, unit in ipairs(Wargroove.getAllUnitsForPlayer(playerId, true)) do
			if not isProductionStucture(unit) then
				if unitCount[unit.unitClassId] == nil then
					unitCount[unit.unitClassId] = 1
				else
					unitCount[unit.unitClassId] = unitCount[unit.unitClassId] + 1
				end
			end
			if unit.unitClassId == "barracks" then
				local relPos = {x = 0, y = 1}
				for i = 1,4 do
					relPos = rotate(relPos);
					local spawnPos = {x = relPos.x+unit.pos.x, y = relPos.y+unit.pos.y}
					if unit.hadTurn == false and Wargroove.getUnitAt(spawnPos) == nil and Recruit:canExecuteWithTarget(unit, unit.pos,spawnPos, "soldier") then
						barracksCount = barracksCount + 1
						break
					end
				end
			end
		end
		local soldierClass = Wargroove.getUnitClass("soldier")
		local budget = Wargroove.getMoney(playerId)-soldierClass.cost*barracksCount
		local productionBuildings = {}
		for i, unit in ipairs(Wargroove.getAllUnitsForPlayer(playerId, true)) do
			if isProductionStucture(unit) then
				local pos = math.random(1, #productionBuildings+1)
				table.insert(productionBuildings, pos, unit)
			end
		end
		print("productionBuildings")
		print(dump(productionBuildings,0))
		for i, unit in ipairs(productionBuildings) do
			local relPos = {x = 0, y = 1}
			for i = 1,4 do
				relPos = rotate(relPos);
				print("Relative Spawn Position: (" .. tostring(relPos.x) .. ", " .. tostring(relPos.y) .. ")")
				local spawnPos = {x = relPos.x+unit.pos.x, y = relPos.y+unit.pos.y}
				print("Actual Spawn Position: (" .. tostring(spawnPos.x) .. ", " .. tostring(spawnPos.y) .. ")")
				local cheapestRecruit = ""
				local cheapestCost = 1000000
				
				for i, recruit in ipairs(unit.recruits) do 
					local recruitClass = Wargroove.getUnitClass(recruit)
					if recruitClass.cost < cheapestCost and not isUnitClassBanned(recruitClass.id) then
						cheapestRecruit = recruit
						cheapestCost = recruitClass.cost
					end
				end
				if unit.hadTurn == false and Wargroove.getUnitAt(spawnPos) == nil and Recruit:canExecuteWithTarget(unit, unit.pos,spawnPos, cheapestRecruit) then
					local bestRecruit = cheapestRecruit
					local score = 0
					local convertedCost = 0
					for i, recruit in ipairs(unit.recruits) do 
						local recruitClass = Wargroove.getUnitClass(recruit)
						if unit.unitClassId == "barracks" then
							convertedCost = recruitClass.cost-soldierClass.cost
						else
							convertedCost = recruitClass.cost
						end
						local newScore = getUnitValue(recruit)
						if newScore > score and budget >= convertedCost and not isUnitClassBanned(recruitClass.id) then
							bestRecruit = recruit
							score = newScore
						end
					end
					budget = budget-convertedCost
					Recruit:execute(unit, spawnPos, bestRecruit, {})
					unit.hadTurn = true
					Wargroove.updateUnit(unit)
					break
				end
			end
		end
	end
end

function dump(o,level)
   if type(o) == 'table' then
      local s = '\n' .. string.rep("   ", level) .. '{\n'
      for k,v in pairs(o) do
         if type(k) ~= 'number' then k = '"'..k..'"' end
         s = s .. string.rep("   ", level+1) .. '['..k..'] = ' .. dump(v,level+1) .. ',\n'
      end
      return s .. string.rep("   ", level) .. '}'
   else
      return tostring(o)
   end
end

return CustomAI
