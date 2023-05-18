local CustomAI = require "initialized/ai_economy_manager"
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
	merman = 0.9,
	rifleman = 0.5,
	soldier = 0.85,
	spearman = 0.95,
	trebuchet = 0.5,
	turtle = 0.8,
	warship = 0.8,
	witch = 0.6,
	wagon = 0.6,
	travelboat = 0.6,
	thief = 0.6
}

local idealUnitRatioList = {
	archer = 1,
	ballista = 0.2,
	dog = 1,
	dragon = 0.5,
	giant = 0.5,
	harpoonship = 1,
	harpy = 1,
	knight = 0.1,
	mage = 1,
	merman = 1,
	rifleman = 0.5,
	soldier = 2,
	spearman = 1,
	trebuchet = 0.3,
	turtle = 1,
	warship = 1,
	witch = 1,
	wagon = 1,
	travelboat = 1,
	thief = 1
}

local powerMultiplierList = {
	archer = 0,
	dog = 0,
	ballista = 0,
	dragon = 0,
	harpy = 0,
	knight = 0,
	harpoonship = 0,
	mage = 0,
	soldier = 0,
	witch = 0,
	wagon = 1,
	travelboat = 1,
	thief = 1
}

local antiAirMultiplierList = {
	archer = 0,
	ballista = 0,
	harpoonship = 0,
	harpy = 0,
	mage = 0,
	witch = 0
}

local bannedUnitList = {
	pirate_ship = true,
	balloon = true,
	flare = true
}
local antiAirReluctance = 1000;
local airThreatPerTower = 200;
local baseLineOpportunityCost = 0.8
local baseLineOpportunityCostScaling = 0.8
local unitRatioResetPerUnit = 0.98
local unitRatioPenaltyPerUnit = 0.2

function CityPassiveAI.setProfile()
	DefaultAI.setProfile()
	CustomAI.valueReductionPerUnitList = valueReductionPerUnitList
	CustomAI.idealUnitRatioList = idealUnitRatioList
	CustomAI.powerMultiplierList = powerMultiplierList
	CustomAI.antiAirMultiplierList = antiAirMultiplierList
	CustomAI.bannedUnitList = bannedUnitList
	CustomAI.antiAirReluctance = antiAirReluctance
	CustomAI.airThreatPerTower = airThreatPerTower
	CustomAI.baseLineOpportunityCost = baseLineOpportunityCost
	CustomAI.baseLineOpportunityCostScaling = baseLineOpportunityCostScaling
	CustomAI.unitRatioResetPerUnit = unitRatioResetPerUnit
	CustomAI.unitRatioPenaltyPerUnit = unitRatioPenaltyPerUnit
end

return CityPassiveAI
