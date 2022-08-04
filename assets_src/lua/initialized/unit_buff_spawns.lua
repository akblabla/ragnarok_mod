local Wargroove = require "wargroove/wargroove"
local OldBuffSpawns = require "wargroove/unit_buff_spawns"

local BuffSpawns = {}
function BuffSpawns.init()
	-- OldBuffSpawns.getBuffSpawns().crown = BuffSpawns.crown
end
function BuffSpawns.crown(Wargroove, unit)
	print("Buffspawn crown starts here")
    local posString = Wargroove.getUnitState(unit, "pos")
    
	print("Attempting to decode position")
    local vals = {}
    for val in posString.gmatch(posString, "([^"..",".."]+)") do
        vals[#vals+1] = val
    end
    local center = { x = tonumber(vals[1]), y = tonumber(vals[2])}
	print("decoded position")
	print(center.x)
	print(center.y)
	
    local radius = 1

    local effectPositions = Wargroove.getTargetsInRange(center, radius, "all")
	
	print("Attempting visual effect")
    Wargroove.displayBuffVisualEffectAtPosition(unit.id, center, unit.playerId, "units/crown/crown", "spawn", 1, effectPositions, "units", {x = 0, y = 0})
	print("Visual effect created")
end

return BuffSpawns