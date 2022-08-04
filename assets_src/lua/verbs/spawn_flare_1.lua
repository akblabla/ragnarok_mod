local Wargroove = require "wargroove/wargroove"
local Verb = require "wargroove/verb"
local Ragnarok = require "initialized/ragnarok"
local spawnFlareSuper = require "verbs/spawn_flare_super"

local spawnFlare = Verb:new()

function spawnFlare:getMaximumRange(unit, endPos)
    return spawnFlareSuper:getMaximumRange(unit, endPos)
end

function spawnFlare:getTargetType()
    return spawnFlareSuper:getTargetType()
end

function spawnFlare:canExecuteAnywhere(unit)
    return Ragnarok.getFlareCount(unit.playerId) == 1
end

function spawnFlare:canExecuteWithTarget(unit, endPos, targetPos, strParam)    
    return spawnFlareSuper:canExecuteWithTarget(unit, endPos, targetPos, strParam)    
end

function spawnFlare:execute(unit, targetPos, strParam, path)
	spawnFlareSuper:execute(unit, targetPos, strParam, path)
end

function spawnFlare:onPostUpdateUnit(unit, targetPos, strParam, path)
	spawnFlareSuper:onPostUpdateUnit(unit, targetPos, strParam, path)
end

return spawnFlare
