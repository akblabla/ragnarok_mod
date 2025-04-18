local CustomAI = require "scripts/ai_economy_manager"
local DefaultAI = require "AIProfiles/default"
local CityPassiveAI = {}


local valueReductionPerUnitList = {
	archer = 0.8,
	ballista = 0.3,
	dog = 0.7,
	dragon = 0.7,
	giant = 0.9,
	harpoonship = 0.7,
	harpy = 0.8,
	knight = 0.7,
	mage = 0.8,
	merman = 0.7,
	rifleman = 0.5,
	soldier = 0.85,
	spearman = 0.95,
	trebuchet = 0.5,
	turtle = 0.8,
	warship = 0.8,
	witch = 0.6,
	wagon = 0.4,
	travelboat = 0.4,
	thief = 0.6
}

local idealUnitRatioList = {
	archer = 1,
	ballista = 0.2,
	dog = 1,
	dragon = 0.5,
	giant = 0.5,
	harpoonship = 0,
	harpy = 1,
	knight = 1,
	mage = 1,
	merman = 0.5,
	rifleman = 0.5,
	soldier = 2,
	spearman = 1,
	trebuchet = 0.3,
	turtle = 0,
	warship = 1,
	witch = 1,
	wagon = 0.3,
	travelboat = 0.3,
	balloon = 0.1,
	thief = 0
}

local powerMultiplierList = {
	wagon = 0.5,
	travelboat = 0.5,
	thief = 0
}


local bannedUnitList = {
	thief = true,
	turtle = true,
	warship = true,
	trebuchet = true,
	ballista = true,
	giant = true,
	harpoonship = true,
	pirate_ship = true,
	balloon = true,
	flare = true
}
local antiAirReluctance = 1000;
local airThreatPerTower = 200;
local baseLineOpportunityCost = 0.5
local baseLineOpportunityCostScaling = 0.75
local unitRatioResetPerUnit = 0.9
local unitRatioPenaltyPerUnit = 0.5

function CityPassiveAI.setProfile()
	DefaultAI.setProfile()
	CustomAI.valueReductionPerUnitList = valueReductionPerUnitList
	CustomAI.idealUnitRatioList = idealUnitRatioList
	CustomAI.powerMultiplierList["wagon"] = powerMultiplierList["wagon"]
	CustomAI.powerMultiplierList["travelboat"] = powerMultiplierList["travelboat"]
	CustomAI.powerMultiplierList["thief"] = powerMultiplierList["thief"]
	CustomAI.bannedUnitList = bannedUnitList
	CustomAI.antiAirReluctance = antiAirReluctance
	CustomAI.airThreatPerTower = airThreatPerTower
	CustomAI.baseLineOpportunityCost = baseLineOpportunityCost
	CustomAI.baseLineOpportunityCostScaling = baseLineOpportunityCostScaling
	CustomAI.unitRatioResetPerUnit = unitRatioResetPerUnit
	CustomAI.unitRatioPenaltyPerUnit = unitRatioPenaltyPerUnit
end

return CityPassiveAI
