local Wargroove = require "wargroove/wargroove"
local Death = require "verbs/death"

local DeathDropCrown = {}

local function execute(me, unit, targetPos, strParam, path)
	local Ragnarok = require "initialized/ragnarok"
	local crownPos = Ragnarok.getCrownPos()
	if crownPos and crownPos.x == unit.pos.x and crownPos.y == unit.pos.y then
		Wargroove.waitTime(0.3)
		Ragnarok.dropCrown(unit.pos)
		Wargroove.waitTime(0.2)
	end
end

function DeathDropCrown.init()
	Death.addDeathVerb(execute)
end




return DeathDropCrown
