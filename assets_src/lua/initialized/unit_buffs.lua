local Wargroove = require "wargroove/wargroove"
local OldBuffs = require "wargroove/unit_buffs"

local Buffs = {}
function Buffs.init()
--	OldBuffs.getBuffs().crown = Buffs.crown
end
function Buffs.crown(Wargroove, unit)
    if Wargroove.isSimulating() then
        return
    end
    local posString = Wargroove.getUnitState(unit, "pos")
    
    local vals = {}
    for val in posString.gmatch(posString, "([^"..",".."]+)") do
        vals[#vals+1] = val
    end
    local center = { x = tonumber(vals[1]), y = tonumber(vals[2])}

    local radius = 1

    local effectPositions = Wargroove.getTargetsInRange(center, radius, "all")
	
    Wargroove.displayBuffVisualEffectAtPosition(unit.id, center, unit.playerId, "units/crown/crown", "spawn", 1, effectPositions, "units", {x = 0, y = 0})

end

return Buffs