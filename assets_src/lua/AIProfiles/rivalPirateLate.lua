local CustomAI = require "scripts/ai_economy_manager"
local DefaultAI = require "AIProfiles/default"
local RivalPirate = {}


local valueReductionPerUnitList = {
	archer = 0.1,
	ballista = 0.1,
	barge = 0.75,
	dog = 0.1,
	dragon = 0.1,
	giant = 0.1,
	harpoonship = 0.8,
	harpy = 0.1,
	knight = 0.1,
	mage = 0.1,
	merman = 0.6,
	rifleman = 0.1,
	soldier = 0.1,
	spearman = 0.1,
	trebuchet = 0.1,
	turtle = 0.9,
	warship = 0.1,
	witch = 0.1,
	kraken = 0.7,
	frog = 0.2,
	caravel = 0.25,
	griffin_walking = 0.85,
}

local idealUnitRatioList = {
	archer = 0,
	ballista = 0,
	dog = 0,
	dragon = 0,
	giant = 0,
	harpoonship = 1,
	harpy = 0,
	knight = 0,
	mage = 0,
	merman = 1,
	rifleman = 0,
	soldier = 0,
	spearman = 0,
	trebuchet = 0,
	turtle = 1,
	warship = 0,
	witch = 0,
	kraken = 0.75,
	frog = 0.1,
	caravel = 0.85,
}

local powerMultiplierList = {
	barge = 4,
	merman = 0.75,
	caravel = 0.75,
	harpoonship = 1,
	warship = 0.25,
	frog = 0.75
}


local antiAirMultiplierList = {
	archer = 0.25,
	ballista = 1.5,
	harpoonship = 1.5,
	harpy = 0.5,
	mage = 0.8,
	witch = 3
}

function RivalPirate.setProfile()
	DefaultAI.setProfile()
	CustomAI.valueReductionPerUnitList = valueReductionPerUnitList
	CustomAI.idealUnitRatioList = idealUnitRatioList
	CustomAI.powerMultiplierList = powerMultiplierList
	CustomAI.antiAirMultiplierList = antiAirMultiplierList
	CustomAI.bannedUnitList = {}
	CustomAI.antiAirReluctance = 1000
	CustomAI.airThreatPerTower = 200
	CustomAI.baseLineOpportunityCost = 0.8
	CustomAI.baseLineOpportunityCostScaling = 0.8
	CustomAI.unitRatioResetPerUnit = 0.98
	CustomAI.unitRatioPenaltyPerUnit = 0.2
end

return RivalPirate
