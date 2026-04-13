local CustomAI = require "scripts/ai_economy_manager"
local DefaultAI = require "AIProfiles/default"
local MangroveAI = {}


local valueReductionPerUnitList = {
	archer = 0.7,
	ballista = 0.3,
	dog = 0.6,
	dragon = 0.6,
	giant = 0.8,
	harpoonship = 0.6,
	harpy = 0.7,
	knight = 0.6,
	mage = 0.7,
	merman = 0.8,
	rifleman = 0.4,
	soldier = 0.75,
	spearman = 0.85,
	trebuchet = 0.4,
	turtle = 0.7,
	warship = 0.4,
	witch = 0.5,
	kraken = 0.5,
	frog = 0.7,
	caravel = 0.75,
	griffin_walking = 0.6,
}

local idealUnitRatioList = {
	archer = 1,
	ballista = 0.2,
	dog = 1,
	dragon = 0.5,
	giant = 0.5,
	harpoonship = 1,
	harpy = 2,
	knight = 0.1,
	mage = 1,
	merman = 1,
	rifleman = 0.5,
	soldier = 2,
	spearman = 1,
	trebuchet = 0.3,
	turtle = 1,
	warship = 1,
	witch = 2,
	kraken = 0.65,
	frog = 0.85,
	caravel = 1,
	griffin_walking = 0.5,
}

local powerMultiplierList = {
	archer = 1,
	dog = 1.25,
	ballista = 0.5,
	dragon = 1.2,
	harpy = 1.2,
	knight = 0.5,
	harpoonship = 0.5,
	mage = 0.8,
	soldier = 1.5,
	witch = 0,
	kraken = 1,
	frog = 1.2,
	caravel = 1.1,
	griffin_walking = 0.6,
	trebuchet = 0.5,
	warship = 0.5,
}
local antiAirMultiplierList = {
	ballista = 0.5,
	harpy = 0.6,
	harpoonship = 1.2,
	mage = 0.8,
	witch = 2.5,
}
function MangroveAI.setProfile()
	DefaultAI.setProfile()
	CustomAI.valueReductionPerUnitList = valueReductionPerUnitList
	CustomAI.idealUnitRatioList = idealUnitRatioList
	CustomAI.powerMultiplierList = powerMultiplierList
	CustomAI.antiAirMultiplierList = antiAirMultiplierList
	-- CustomAI.bannedUnitList = bannedUnitList
	CustomAI.antiAirReluctance = 500
	-- CustomAI.airThreatPerTower = airThreatPerTower
	-- CustomAI.baseLineOpportunityCost = baseLineOpportunityCost
	-- CustomAI.baseLineOpportunityCostScaling = baseLineOpportunityCostScaling
	-- CustomAI.unitRatioResetPerUnit = unitRatioResetPerUnit
	-- CustomAI.unitRatioPenaltyPerUnit = unitRatioPenaltyPerUnit
end

return MangroveAI
