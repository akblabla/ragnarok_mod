
local Ragnarok = require "initialized/ragnarok"
local Wargroove = require "wargroove/wargroove"
local tileLoader = {}
function tileLoader.init()
	Ragnarok.addAction(tileLoader.setup,"start_of_match",false)

end

function tileLoader.setup(context)

	for i,unit in pairs(Wargroove.getUnitsAtLocation()) do
		if unit.unitClassId == "villager" and unit.damageTakenPercent == 52 then
			Wargroove.removeUnit(unit.id)
			Wargroove.setTerrainType(unit.pos, "mangrove_layer_2", false)
		end
	end
end
return tileLoader
