local VisionTracker = require "initialized/vision_tracker"
local OldEvents = require("wargroove/events")
local Wargroove = require("wargroove/wargroove")

local Events = {}
local Original = {}

function Events.init()
	Original.reportUnitDeath = OldEvents.reportUnitDeath
	OldEvents.reportUnitDeath = Events.reportUnitDeath
end

function Events.reportUnitDeath(id, attackerUnitId, attackerPlayerId, attackerUnitClass)
	local unit = Wargroove.getUnitById(id)
	local oldUnit = {playerId = unit.playerId, unitClassId = unit.unitClassId, pos = VisionTracker.getPrevPosList()[id], unitClass = unit.unitClass}
	VisionTracker.removeUnitFromVisionMatrix(oldUnit)
	Original.reportUnitDeath(id, attackerUnitId, attackerPlayerId, attackerUnitClass)
end

return Events