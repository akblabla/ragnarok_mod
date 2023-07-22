local Wargroove = require "wargroove/wargroove"
local Ragnarok = require "initialized/ragnarok"
local Recruit = require "verbs/recruit"
local StealthManager = require "scripts/stealth_manager"
--local AIProfile = require "AIProfiles/ai_profile"

local AIEconomyManager = {}
function AIEconomyManager.init()
	Ragnarok.addAction(AIEconomyManager.spendRest,"repeating",true)
end

local function isProductionStucture(unit)
	return (next(unit.recruits) ~= nil) and (Wargroove.hasAIRestriction(unit.id, "cant_recruit") == false)
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

AIEconomyManager.valueReductionPerUnitList = {
	archer = 0.8,
	ballista = 0.3,
	dog = 0.5,
	dragon = 0.8,
	giant = 0.9,
	harpoonship = 0.7,
	harpy = 0.8,
	knight = 0.9,
	mage = 0.8,
	merman = 0.9,
	rifleman = 0.5,
	soldier = 0.85,
	spearman = 0.95,
	trebuchet = 0.5,
	turtle = 0.8,
	warship = 0.8,
	witch = 0.6,
	travelboat = 1,
	balloon = 1,
	thief = 1
}

AIEconomyManager.idealUnitRatioList = {
	archer = 1,
	ballista = 0.2,
	dog = 1,
	dragon = 0.5,
	giant = 0.5,
	harpoonship = 1,
	harpy = 1,
	knight = 1,
	mage = 1,
	merman = 1,
	rifleman = 0.5,
	soldier = 2,
	spearman = 1,
	trebuchet = 0.3,
	turtle = 1,
	warship = 1,
	witch = 1,
	travelboat = 0,
	balloon = 0,
	thief = 0
}

local currentUnitRatioScalingList = {}

AIEconomyManager.powerMultiplierList = {
	archer = 0.9,
	ballista = 0.5,
	harpy = 1.1,
	harpoonship = 0.5,
	mage = 0.65,
	soldier = 1.5,
	witch = 0
}

AIEconomyManager.antiAirMultiplierList = {
	archer = 0.25,
	ballista = 1.5,
	harpoonship = 1.5,
	harpy = 0.5,
	mage = 0.8,
	witch = 3
}

AIEconomyManager.bannedUnitList = {
	pirate_ship = true,
	wagon = true,
	balloon = true,
	travelboat = true,
	flare = true
}

local function isUnitClassBanned(unitClassId)
	return AIEconomyManager.bannedUnitList[unitClassId] == true
end

local function canUnitClassCapture(unitClassId)
	return captureUnitList[unitClassId] == true
end

local unitCountPlayerList = {}
local function getAirUnitPower(count)
	local power = 0
	for classId, amount in pairs(count) do
		-- print(tostring(amount).. " "..classId)
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
		if AIEconomyManager.antiAirMultiplierList[classId] ~= nil then
			power = power+amount*class.cost*AIEconomyManager.antiAirMultiplierList[classId]
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


AIEconomyManager.antiAirReluctance = 1000;
AIEconomyManager.airThreatPerTower = 200;

local function getIncome(playerId)
	local income = 0
	if unitCountPlayerList[playerId]["city"] ~= nil then
		income = income + unitCountPlayerList[playerId]["city"]*100
	end
	if unitCountPlayerList[playerId]["water_city"] ~= nil then
		income = income + unitCountPlayerList[playerId]["water_city"]*100
	end
	if unitCountPlayerList[playerId]["hq"] ~= nil then
		income = income + unitCountPlayerList[playerId]["hq"]*100
	end
	return income
end
AIEconomyManager.baseLineOpportunityCost = 0.8
AIEconomyManager.baseLineOpportunityCostScaling = 0.8
AIEconomyManager.unitRatioResetPerUnit = 0.98

local function updateUnitRatioModifier(newUnitClassId, playerId)
	if currentUnitRatioScalingList[playerId] == nil then
		currentUnitRatioScalingList[playerId] = {
			archer = 0,
			ballista = 0,
			dog = 0,
			dragon = 0,
			giant = 0,
			harpoonship = 0,
			harpy = 0,
			knight = 0,
			mage = 0,
			merman = 0,
			rifleman = 0,
			soldier = 0,
			spearman = 0,
			trebuchet = 0,
			turtle = 0,
			warship = 0,
			witch = 0
		}
	end
	local unitRatioNormalizationFactor = 0
	--print("summing up normalization factor")
	for unitClassId, ratio in pairs(AIEconomyManager.idealUnitRatioList) do
		--print("unit type: '" .. unitClassId .. "' has a ratio of: " .. tostring(ratio))
		if unitClassId ~= newUnitClassId then
			unitRatioNormalizationFactor = unitRatioNormalizationFactor+ratio
		end
	end
	--print("modifying table")
	for unitClassId, ratio in pairs(AIEconomyManager.idealUnitRatioList) do
	--	print("unit type: '" .. unitClassId .. "' has a ratio of: " .. tostring(ratio))
		currentUnitRatioScalingList[playerId][unitClassId] = currentUnitRatioScalingList[playerId][unitClassId]*AIEconomyManager.unitRatioResetPerUnit
		if unitClassId ~= newUnitClassId then
	--		print("Another unit class")
			currentUnitRatioScalingList[playerId][unitClassId] = currentUnitRatioScalingList[playerId][unitClassId]-ratio/unitRatioNormalizationFactor
		else
	--		print("Current unit class")
			currentUnitRatioScalingList[playerId][unitClassId] = currentUnitRatioScalingList[playerId][unitClassId]+1
		end
	end
end
AIEconomyManager.unitRatioPenaltyPerUnit = 0.2
local function getUnitRatioModifier(unitClassId, playerId)
	if currentUnitRatioScalingList[playerId] == nil then
		currentUnitRatioScalingList[playerId] = {
			archer = 0,
			ballista = 0,
			dog = 0,
			dragon = 0,
			giant = 0,
			harpoonship = 0,
			harpy = 0,
			knight = 0,
			mage = 0,
			merman = 0,
			rifleman = 0,
			soldier = 0,
			spearman = 0,
			trebuchet = 0,
			turtle = 0,
			warship = 0,
			witch = 0,
			wagon = 0,
			travelboat = 0,
			balloon = 0,
			thief = 0
		}
	end
	
	local result = 1
	local ratioScaling = currentUnitRatioScalingList[playerId][unitClassId]
	if ratioScaling ~= nil then
		if ratioScaling>0 then
			result = (1-AIEconomyManager.unitRatioPenaltyPerUnit)^(ratioScaling)
			if unitClassId == "soldier" then
				result = result*0.5+0.5 --soldier has a lower cap, because soldier
			end
		else
			result = 2-(1-AIEconomyManager.unitRatioPenaltyPerUnit)^(-ratioScaling)
		end
	end
	return result
end
local soldierClass = Wargroove.getUnitClass("soldier")

local reserve = 0
local function calculateConvertedCost(producer, recruit)
	local recruitClass = Wargroove.getUnitClass(recruit)
	local convertedCost = 0
	if producer.unitClassId == "barracks" then
		convertedCost = recruitClass.cost-math.min(soldierClass.cost,reserve)
	else
		convertedCost = recruitClass.cost
	end
	return convertedCost
end
local function getOpportunityCost(producer, unitClassId, playerId)
	local income = getIncome(playerId)
	
	return calculateConvertedCost(producer, unitClassId) * AIEconomyManager.baseLineOpportunityCost*(AIEconomyManager.baseLineOpportunityCostScaling)^(Wargroove.getMoney(playerId)/income)
end

local function getUnitCountPenalty(playerId)
	local totalUnits = 0
	for unitClassId, unitCount in ipairs(unitCountPlayerList[playerId]) do
		totalUnits = totalUnits + unitCount
	end
	return totalUnits * 10
end

local function getUnitValue(unitClassId, playerId)
	local value = Wargroove.getUnitClass(unitClassId).cost+50
	if AIEconomyManager.powerMultiplierList[unitClassId] ~= nil then
		value = value*AIEconomyManager.powerMultiplierList[unitClassId]
	end
	local enemyUnitCountList = {}
	for _playerId, unitCountList in ipairs(unitCountPlayerList) do
		if Wargroove.areEnemies(_playerId, playerId) then
			for unitClassId, unitCount in ipairs(unitCountList) do
				if enemyUnitCountList[unitClassId] == nil then
					enemyUnitCountList[unitClassId] = 0
				end
				enemyUnitCountList[unitClassId] = enemyUnitCountList[unitClassId]+unitCount
			end
		end
	end
	local enemyAirPower = getAirUnitPower(enemyUnitCountList)
	local friendlyAntiAirPower = getAntiAirUnitPower(unitCountPlayerList[playerId])
	local enemyTowerCount = 0
	if enemyUnitCountList["tower"] ~= nil then
		enemyTowerCount = enemyUnitCountList["tower"]
	end
	local antiAirCounterBonus = calculateCounterBonus(unitClassId, enemyAirPower+enemyTowerCount*AIEconomyManager.airThreatPerTower, friendlyAntiAirPower, AIEconomyManager.antiAirReluctance, AIEconomyManager.antiAirMultiplierList);
	value = value + antiAirCounterBonus
	if AIEconomyManager.valueReductionPerUnitList[unitClassId] ~= nil and unitCountPlayerList[playerId][unitClassId] ~= nil then
		value = value*AIEconomyManager.valueReductionPerUnitList[unitClassId]^unitCountPlayerList[playerId][unitClassId]
	end
	value = value*getUnitRatioModifier(unitClassId, playerId)
	value = value-getUnitCountPenalty(playerId)
	return value
end

local function getProducedUnitValue(producer, unitClassId, playerId)
	local value = getUnitValue(unitClassId, playerId)
	value = value-getOpportunityCost(producer, unitClassId, playerId)
	if unitClassId == "soldier" and value<=0 then
		value = 1 --Always worth buying a soldier if you have money left over
	end
	return value
end


function AIEconomyManager.addUnitOption(recruit,unit,spawnPos,productionOptions,playerId)
	if not isUnitClassBanned(recruit) and Recruit:canExecuteWithTarget(unit, unit.pos,spawnPos, recruit) then
		print("Could recruit: " .. recruit)
		local convertedCost = calculateConvertedCost(unit, recruit)
		local score = getProducedUnitValue(unit, recruit, playerId)
		table.insert(productionOptions,{producerId = unit.id, spawnPos = spawnPos, convertedCost = convertedCost, score = score, recruit = recruit })
	end
end
function AIEconomyManager.spendRest(context)
	if context:checkState("endOfTurn") then
		local playerId = Wargroove.getCurrentPlayerId();
		if Wargroove.isHuman(playerId) == true then
			return
		end
--		AIProfile.checkForProfile(playerId)
		unitCountPlayerList = {}
		local barracksCount = 0
		for i, unit in ipairs(Wargroove.getUnitsAtLocation(nil)) do
			if unitCountPlayerList[unit.playerId] == nil then
				unitCountPlayerList[unit.playerId] = {}
			end
			if unit.playerId == playerId then
				if unitCountPlayerList[unit.playerId][unit.unitClassId] == nil then
					unitCountPlayerList[unit.playerId][unit.unitClassId] = 1
				else
					unitCountPlayerList[unit.playerId][unit.unitClassId] = unitCountPlayerList[unit.playerId][unit.unitClassId] + unit.health/unit.unitClass.maxHealth
				end
			end
			if Wargroove.areEnemies(unit.playerId, playerId) then
				if unitCountPlayerList[unit.playerId][unit.unitClassId] == nil then
					unitCountPlayerList[unit.playerId][unit.unitClassId] = 1
				else
					unitCountPlayerList[unit.playerId][unit.unitClassId] = unitCountPlayerList[unit.playerId][unit.unitClassId] + unit.health/unit.unitClass.maxHealth
				end
			end
			if unit.unitClassId == "barracks" and unit.playerId == playerId then
				local relPos = {x = 0, y = 1}
				for i = 1,4 do
					relPos = rotate(relPos);
					local spawnPos = {x = relPos.x+unit.pos.x, y = relPos.y+unit.pos.y}
					if unit.hadTurn == false and Wargroove.getUnitAt(spawnPos) == nil and Recruit:canExecuteWithTarget(unit, unit.pos,spawnPos, "soldier") then
						if StealthManager.isActive(unit.playerId) then
							if StealthManager.isUnitPermaAlerted(unit) then
								barracksCount = barracksCount + 1
							end
						else
							barracksCount = barracksCount + 1
						end
						break
					end
				end
			end
		end
		reserve = math.min(soldierClass.cost*barracksCount,Wargroove.getMoney(playerId))
		local captureUnitCount = 0
		for unitClassId, canCapture in pairs(captureUnitList) do
			if canCapture == true then
				if unitCountPlayerList[playerId] ~= nil and unitCountPlayerList[playerId][unitClassId] ~= nil then
					captureUnitCount = captureUnitCount +  unitCountPlayerList[playerId][unitClassId]
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
		for i, unit in pairs(productionBuildings) do
			local relPos = {x = 0, y = 1}
			for i = 1,4 do
				relPos = rotate(relPos);
				local spawnPos = {x = relPos.x+unit.pos.x, y = relPos.y+unit.pos.y}
				if unit.hadTurn == false and Wargroove.getUnitAt(spawnPos) == nil then
					print("valid spawnPoint")
					for i, recruit in ipairs(unit.recruits) do 
						print("Attempting to recruit: " .. recruit)
						if StealthManager.isActive(unit.playerId) then
							if ((StealthManager.isCivilian(recruit) and not StealthManager.isUnitPermaAlerted(unit))) then
								AIEconomyManager.addUnitOption(recruit,unit,spawnPos,productionOptions,playerId)
							end
							if ((not StealthManager.isCivilian(recruit) and StealthManager.isUnitPermaAlerted(unit))) then
								AIEconomyManager.addUnitOption(recruit,unit,spawnPos,productionOptions,playerId)
							end
						else
							AIEconomyManager.addUnitOption(recruit,unit,spawnPos,productionOptions,playerId)
						end

					end
				end
			end
		end
		
		table.sort(productionOptions, function (k1, k2) return k1.score > k2.score end )
		while next(productionOptions) ~= nil do
			for i = #productionOptions, 1, -1 do
				local production = productionOptions[i]
				if (production.convertedCost>budget and production.convertedCost>0) then
					table.remove(productionOptions,i)
				elseif (production.score<0) then
					table.remove(productionOptions,i)
				end
			end
			if next(productionOptions) == nil then
				break;
			end
			table.sort(productionOptions, function (k1, k2) return k1.score > k2.score end )
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
				updateUnitRatioModifier(chosenProduction.recruit, playerId)
			end
			if unitCountPlayerList[playerId][chosenProduction.recruit] == nil then
				unitCountPlayerList[playerId][chosenProduction.recruit] = 1
			else
				unitCountPlayerList[playerId][chosenProduction.recruit] = unitCountPlayerList[playerId][chosenProduction.recruit] + 1
			end
			for i = #productionOptions, 1, -1 do
				local production = productionOptions[i]
				if (production.spawnPos.x==chosenProduction.spawnPos.x and production.spawnPos.y==chosenProduction.spawnPos.y) or production.producerId == chosenProduction.producerId then
					table.remove(productionOptions,i)
				else
					--recalculate score, just in case
					local producer = Wargroove.getUnitById(production.producerId)
					production.score = getProducedUnitValue(producer, production.recruit, playerId)
					production.convertedCost = calculateConvertedCost(Wargroove.getUnitById(production.producerId), production.recruit)
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

return AIEconomyManager
