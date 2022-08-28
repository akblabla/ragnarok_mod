local Wargroove = require "wargroove/wargroove"
local Ragnarok = require "initialized/ragnarok"
local Recruit = require "verbs/recruit"
local Events = require "wargroove/events"

local CustomAI = {}
function CustomAI.init()
	Ragnarok.addAction(CustomAI.spendRest,"repeating",false)
end

local function isProductionStucture(unit)
	return next(unit.recruits) ~= nil -- and Wargroove.hasAIRestriction(unit.id, "cant_recruit") == false
end
local function rotate(vector)
	return {x = -vector.y, y = vector.x}
end

local captureUnitList = {
	archer = true,
	mage = true,
	merman = true,
	rifleman = true,
	soldier = true,
	spearman = true,
}

local valueReductionPerUnitList = {
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
	soldier = 0.8,
	spearman = 0.95,
	trebuchet = 0.5,
	turtle = 0.8,
	warship = 0.8,
	witch = 0.6
}

local powerMultiplierList = {
	archer = 0.9,
	ballista = 0.5,
	harpy = 0.9,
	harpoonship = 0.5,
	mage = 0.7,
	witch = 0
}

local antiAirMultiplierList = {
	archer = 0.25,
	ballista = 1.5,
	harpoonship = 1.5,
	harpy = 0.5,
	mage = 0.8,
	witch = 3
}

local bannedUnitList = {
	pirate_ship = true,
	wagon = true,
	balloon = true,
	travelboat = true,
	flare = true
}

local function isUnitClassBanned(unitClassId)
	return bannedUnitList[unitClassId] == true
end

local function canUnitClassCapture(unitClassId)
	return captureUnitList[unitClassId] == true
end

local unitCount = {}
local enemyUnitCount = {}
local function getAirUnitPower(count)
	local power = 0
	for classId, amount in pairs(count) do
		print(tostring(amount).. " "..classId)
		local class = Wargroove.getUnitClass(classId)
		local isAir = false
		for i, tag in pairs(class.tags) do
			if tag == "type.air" then
				isAir = true
				break
			end
		end
		if isAir then
			power = power+amount*class.cost
		end
	end
	return power
end

local function getAntiAirUnitPower(count)
	local power = 0
	for classId, amount in pairs(count) do
		local class = Wargroove.getUnitClass(classId)
		if antiAirMultiplierList[classId] ~= nil then
			power = power+amount*class.cost*antiAirMultiplierList[classId]
		end
	end
	return power
end

local function calculateCounterBonus(unitClassId, power, counterPower, reluctance, multiplier)
	if multiplier[unitClassId] == nil then
		return 0
	end
	local scala = 0
	scala = 1-(reluctance+counterPower-power)/reluctance
	scala = math.max(scala,0)
	scala = math.min(scala,1)
	local value = Wargroove.getUnitClass(unitClassId).cost
	return value*scala*multiplier[unitClassId]
end


local antiAirReluctance = 1000;
local airThreatPerTower = 200;
local function getUnitValue(unitClassId)
	print("getUnitValue(unitClassId) starts here")
	print("class: " .. unitClassId)
	local value = Wargroove.getUnitClass(unitClassId).cost
	if powerMultiplierList[unitClassId] ~= nil then
		value = value*powerMultiplierList[unitClassId]
	end
	print("value: " .. tostring(value))
	local enemyAirPower = getAirUnitPower(enemyUnitCount)
	print("enemyAirPower: " .. tostring(enemyAirPower))
	local friendlyAntiAirPower = getAntiAirUnitPower(unitCount)
	print("friendlyAntiAirPower: " .. tostring(friendlyAntiAirPower))
	local enemyTowerCount = 0
	if enemyUnitCount["tower"] ~= nil then
		enemyTowerCount = enemyUnitCount["tower"]
	end
	local antiAirCounterBonus = calculateCounterBonus(unitClassId, enemyAirPower+enemyTowerCount*airThreatPerTower, friendlyAntiAirPower, antiAirReluctance, antiAirMultiplierList);
	value = value + antiAirCounterBonus
	print("antiAirCounterBonus: " .. tostring(antiAirCounterBonus))
	if valueReductionPerUnitList[unitClassId] ~= nil and unitCount[unitClassId] ~= nil then
		value = value*valueReductionPerUnitList[unitClassId]^unitCount[unitClassId]
	end
	print("final value: " .. tostring(value))
	return value
end
local soldierClass = Wargroove.getUnitClass("soldier")

local function calculateConvertedCost(producer, recruit, reserve)
	local recruitClass = Wargroove.getUnitClass(recruit)
	local convertedCost = 0
	if producer.unitClassId == "barracks" then
		convertedCost = recruitClass.cost-math.min(soldierClass.cost,reserve)
	else
		convertedCost = recruitClass.cost
	end
	return convertedCost
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
		enemyUnitCount = {}
		local barracksCount = 0
		for i, unit in ipairs(Wargroove.getUnitsAtLocation(nil)) do
			if unit.playerId == playerId then
				if unitCount[unit.unitClassId] == nil then
					unitCount[unit.unitClassId] = 1
				else
					unitCount[unit.unitClassId] = unitCount[unit.unitClassId] + unit.health/unit.unitClass.maxHealth
				end
			end
			if Wargroove.areEnemies(unit.playerId, playerId) then
				if enemyUnitCount[unit.unitClassId] == nil then
					enemyUnitCount[unit.unitClassId] = 1
				else
					enemyUnitCount[unit.unitClassId] = enemyUnitCount[unit.unitClassId] + unit.health/unit.unitClass.maxHealth
				end
			end
			if unit.unitClassId == "barracks" and unit.playerId == playerId then
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
		local reserve = math.min(soldierClass.cost*barracksCount,Wargroove.getMoney(playerId))
		local captureUnitCount = 0
		for unitClassId, canCapture in pairs(captureUnitList) do
			if canCapture == true then
				if unitCount[unitClassId] ~= nil then
					captureUnitCount = captureUnitCount +  unitCount[unitClassId]
				end
			end
		end
		reserve = math.min(reserve,soldierClass.cost*math.ceil(math.max(6-captureUnitCount/3,0)))
		local budget = Wargroove.getMoney(playerId)-reserve
		local productionBuildings = {}
		local productionOptions = {}
		local enemyProductionBuildings = {}
		local enemyProductionCount = {}
		for i, unit in ipairs(Wargroove.getAllUnitsForPlayer(playerId, true)) do
			if isProductionStucture(unit) then
				if unit.playerId == playerId then 
					table.insert(productionBuildings, unit)
				end
			end
		end
		print("ProductionBuildings detected")
		for i, unit in ipairs(productionBuildings) do
			print(unit.unitClassId)
		end
		print("ProductionBuildings processing initiated")
		for i, unit in pairs(productionBuildings) do
			print("productionBuilding: " .. unit.unitClassId)
			local relPos = {x = 0, y = 1}
			for i = 1,4 do
				relPos = rotate(relPos);
				--print("Relative Spawn Position: (" .. tostring(relPos.x) .. ", " .. tostring(relPos.y) .. ")")
				local spawnPos = {x = relPos.x+unit.pos.x, y = relPos.y+unit.pos.y}
				--print("Actual Spawn Position: (" .. tostring(spawnPos.x) .. ", " .. tostring(spawnPos.y) .. ")")
				if unit.hadTurn == false and Wargroove.getUnitAt(spawnPos) == nil then
					print("valid spawnPoint")
					for i, recruit in ipairs(unit.recruits) do 
						print("Attempting to recruit: " .. recruit)
						if not isUnitClassBanned(recruit) and Recruit:canExecuteWithTarget(unit, unit.pos,spawnPos, recruit) then
							print("Could recruit: " .. recruit)
							local convertedCost = calculateConvertedCost(unit, recruit, reserve)
							local score = getUnitValue(recruit)
							table.insert(productionOptions,{producerId = unit.id, spawnPos = spawnPos, convertedCost = convertedCost, score = score, recruit = recruit })
						end
					end
				end
			end
		end
		print("Production selection starts here")
		while next(productionOptions) ~= nil do
			print("productionOptions before culling")
			print(dump(productionOptions,0))
			print("budget before culling: " .. tostring(budget))
			print("reserve before culling: " .. tostring(reserve))
			for i = #productionOptions, 1, -1 do
				local production = productionOptions[i]
				if (production.convertedCost>budget and production.convertedCost>0) then
					table.remove(productionOptions,i)
				end
			end
			if next(productionOptions) == nil then
				break;
			end
			print("productionOptions")
			table.sort(productionOptions, function (k1, k2) return k1.score > k2.score end )
			print(dump(productionOptions,0))
			print("budget: " .. tostring(budget))
			print("reserve: " .. tostring(reserve))
			table.sort(productionOptions, function (k1, k2) return k1.score > k2.score end )
			local chosenProduction = productionOptions[1]
			local chosenProducer = Wargroove.getUnitById(chosenProduction.producerId)
			budget = budget-chosenProduction.convertedCost
			if Recruit:canExecuteWithTarget(chosenProducer, chosenProducer.pos,chosenProduction.spawnPos, chosenProduction.recruit) then
				Recruit:execute(chosenProducer, chosenProduction.spawnPos, chosenProduction.recruit, {})
				chosenProducer.hadTurn = true
				Wargroove.updateUnit(chosenProducer)
				if chosenProduction.recruit == "soldier" then
					reserve = math.max(reserve-soldierClass.cost,0)
				end
			end
			if unitCount[chosenProduction.recruit] == nil then
				unitCount[chosenProduction.recruit] = 1
			else
				unitCount[chosenProduction.recruit] = unitCount[chosenProduction.recruit] + 1
			end
			print("budget after buying: " .. tostring(budget))
			print("reserve after culling: " .. tostring(reserve))
			for i = #productionOptions, 1, -1 do
				local production = productionOptions[i]
				if (production.spawnPos.x==chosenProduction.spawnPos.x and production.spawnPos.y==chosenProduction.spawnPos.y) or production.producerId == chosenProduction.producerId then
					table.remove(productionOptions,i)
				else
					--recalculate score, just in case
					production.score = getUnitValue(production.recruit)
					production.convertedCost = calculateConvertedCost(Wargroove.getUnitById(production.producerId), production.recruit, reserve)
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
