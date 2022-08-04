local Wargroove = require "wargroove/wargroove"
local Verb = require "wargroove/verb"
local Combat = require "wargroove/combat"
local Ragnarok = require "initialized/ragnarok"

local DeathDropCrown = Verb:new()

function DeathDropCrown:execute(unit, targetPos, strParam, path)
	local crownPos = Ragnarok.getCrownPos()
	if crownPos and crownPos.x == unit.pos.x and crownPos.y == unit.pos.y then
		Wargroove.waitTime(0.3)
		Ragnarok.dropCrown(unit.pos)
		Wargroove.waitTime(0.2)
	end
end


return DeathDropCrown
