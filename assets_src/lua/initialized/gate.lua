local Wargroove = require "wargroove/wargroove"
local Ragnarok = require "initialized/ragnarok"

local Gate = {};

function Gate.init()
	Ragnarok.addAction(Gate.setup,"start_of_match",true)
end

function Gate.setup(context)
	for index, unitId in ipairs(Wargroove.getAllUnitIds()) do
		local unit = Wargroove.getUnitById(unitId)
		if unit then
			if (unit.unitClassId == "gate" or unit.unitClassId == "gate_no_los_blocker") and unit.playerId == -1 then
				unit.playerId = -2
			end
		end
	end
end


return Gate
