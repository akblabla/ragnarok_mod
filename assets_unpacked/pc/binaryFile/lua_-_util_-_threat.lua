local Wargroove = require "wargroove/wargroove"
local PosKey = require "util/posKey"
local Threat = {}
local threatMap = {}
function Threat.getThreat(unitClassId,pos)
	local posKey = PosKey.generatePosKey(pos)
	return threatMap[posKey]
end
return Threat
