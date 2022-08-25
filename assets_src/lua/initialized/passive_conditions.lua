local Wargroove = require "wargroove/wargroove"
local OriginalPassiveConditions = require "wargroove/passive_conditions"
local Ragnarok = require "initialized/ragnarok"

local neighbours = { {x = -1, y = 0}, {x = 1, y = 0}, {x = 0, y = -1}, {x = 0, y = 1}, {x = 0, y = 0} }

local function getNeighbour(pos, i)
    local n = neighbours[i]
    return Wargroove.getTerrainNameAt({ x = n.x + pos.x, y = n.y + pos.y })
end

local PassiveConditions = {}

-- This is called by the game when the map is loaded.
function PassiveConditions.init()
    OriginalPassiveConditions.getPassiveConditions().pirate_ship = PassiveConditions.pirate_ship
    OriginalPassiveConditions.getPassiveConditions().merman = PassiveConditions.merman
    OriginalPassiveConditions.getPassiveConditions().harpoonship = PassiveConditions.harpoonship
    OriginalPassiveConditions.getPassiveConditions().warship = PassiveConditions.warship
end

-- Soldiers now get their passive condition if they are next to a dog
function PassiveConditions.pirate_ship(payload)
	local function has_value (tab, val)
		for index, value in ipairs(tab) do
			if value == val then
				return true
			end
		end

		return false
	end
    local attacker = payload.attacker
	for i = 1, 5 do
		local isSea = false
        local terrain = getNeighbour(payload.attackerPos, i)
		for i, seaType in ipairs(Ragnarok.seaTiles) do
			if terrain == seaType then
				isSea = true
			end
		end
		for i, amphibiousType in ipairs(Ragnarok.amphibiousTiles) do
			if terrain == amphibiousType then
				isSea = true
			end
		end
		if not isSea then
			return true
		end
	end
	return false
end

function PassiveConditions.merman(payload)
	local isSea = false
	local terrainName = Wargroove.getTerrainNameAt(payload.attackerPos)
	for i, seaType in ipairs(Ragnarok.seaTiles) do
		if terrainName == seaType then
			isSea = true
		end
	end
	for i, amphibiousType in ipairs(Ragnarok.amphibiousTiles) do
		if terrainName == amphibiousType then
			isSea = true
		end
	end
    return isSea
end

function PassiveConditions.harpoonship(payload)
    local terrainName = Wargroove.getTerrainNameAt(payload.attackerPos)
    return terrainName == "reef" or terrainName == "cave_reef" or terrainName == "reef_no_hiding"
end

function PassiveConditions.warship(payload)
    local terrainName = Wargroove.getTerrainNameAt(payload.attackerPos)
    return terrainName == "beach" or terrainName == "cave_beach"
end

return PassiveConditions