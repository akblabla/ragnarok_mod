local PosKey = require "util/posKey"

local VisionTrackerCache = {}
local calculateVisionOfUnitCache = {}

function VisionTrackerCache.clearCalculateVisionOfUnitCache()
	calculateVisionOfUnitCache = {}
end
function VisionTrackerCache.getCalculateVisionOfUnitCache(unit)	
	local key = PosKey.generatePosKey(unit.pos)
	if calculateVisionOfUnitCache[key] ~=nil then
		return calculateVisionOfUnitCache[key]
	end
	return nil
end
function VisionTrackerCache.addCalculateVisionOfUnitCache(unit,visibleTiles)	
	local key = PosKey.generatePosKey(unit.pos)
	calculateVisionOfUnitCache[key] = visibleTiles
end

return VisionTrackerCache