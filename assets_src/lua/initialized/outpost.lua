
local Ragnarok = require "initialized/ragnarok"
local Wargroove = require "wargroove/wargroove"
local outpost = {}
function outpost.init()
	Ragnarok.addAction(outpost.update,"repeating",false)
	Ragnarok.addAction(outpost.setup,"start_of_match",false)

end

function outpost.update(context)
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
function outpost.setup(context)

	for i,unit in pairs(Wargroove.getUnitsAtLocation()) do
		if unit.unitClassId == "barracks" and unit.damageTakenPercent == 57 then
			unit.unitClassId = "outpost"
			unit.damageTakenPercent = 100
			Wargroove.updateUnit(unit)
		end
	end
end
return outpost
