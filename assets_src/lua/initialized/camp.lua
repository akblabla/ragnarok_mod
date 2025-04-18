
local Ragnarok = require "initialized/ragnarok"
local Wargroove = require "wargroove/wargroove"
local camp = {}
function camp.init()
	Ragnarok.addAction(camp.update,"repeating",false)
end

function camp.update(context)
	local allUnits = Wargroove.getAllUnitIds()
	for i, id in ipairs(allUnits) do
		local unit = Wargroove.getUnitById(id)

		if unit~=nil and unit.unitClassId == "outpost" then
			local process = Wargroove.getUnitState(unit, "process");
			if process==nil then
				Wargroove.setUnitState(unit, "process","idle");
				process = "idle"
			end
			if process ~= "idle" then
				if context:checkState("startOfTurn") and unit.playerId == Wargroove.getCurrentPlayerId() then
					if process == "working" then
						Wargroove.setUnitState(unit, "process","idle");
						Wargroove.playUnitAnimation(id, "empty")
						process = "idle"
					end
					if context:checkState("startOfTurn") and unit.playerId == Wargroove.getCurrentPlayerId() and process == "sleeping" then
						Wargroove.setUnitState(unit, "process","working");
						process = "working"
						unit.hadTurn = true;
					end
					Wargroove.updateUnit(unit);
				end
			end
			if process ~= "idle" then
				Wargroove.playUnitAnimation(id, process)
			end
		end
	end
end
return camp
