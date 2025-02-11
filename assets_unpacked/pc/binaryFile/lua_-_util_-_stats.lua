local Wargroove = require "wargroove/wargroove"

local Stats = {}
Stats.meleeUnits = {
	commander_emeric = true,
	commander_mercival = true,
	commander_vesper = true,
	commander_wulfar = true,
	dog = true,
	giant = true,
	knight = true,
	soldier = true,
	spearman = true,
	turtle = true,
}
Stats.sightRangeList = {
	archer = 4,
	rival = 4,
	ballista = 4,
	commander_emeric = 4,
	commander_flagship_rival = 4,
	commander_flagship_wulfar = 4,
	commander_mercival = 4,
	commander_vesper = 4,
	commander_wulfar = 4,
	commander_duchess = 4,
	dog = 4,
	dragon = 4,
	flare = 4,
	giant = 4,
	harpoonship = 4,
	harpy = 4,
	knight = 4,
	mage = 4,
	merman = 4,
	pirate_ship = 4,
	pirate_ship_loaded = 4,
	wagon = 4,
	balloon = 4,
	villager = 4,
	rifleman = 4,
	soldier = 4,
	soldier_flanked = 4,
	spearman = 4,
	trebuchet = 4,
	thief = 4,
	thief_with_gold = 4,
	travelboat = 4,
	travelboat_with_gold = 4,
	turtle = 4,
	warship = 4,
	witch = 4,
	reveal_all = 200,
	reveal_all_but_hidden = 200,
	reveal_all_but_over = 200,
	barracks = 1,
	city = 1,
	gate = 1,
	hideout = 1,
	hq = 2,
	statue = 0,
	port = 1,
	tower = 1,
	water_city = 1,
	crew = 0,
	gate_no_los_blocker = 1
}

Stats.scoutList = {
	dog = true,
	turtle = true,
	reveal_all = true,
	flare = true
}

Stats.seeOverList = {
	harpy = true,
	dragon = true,
	reveal_all = true,
	reveal_all_but_hidden = true,
	witch = true
}

Stats.fowCoverList = {
	forest = true,
	reef = true,
	mangrove = true,
	cave_reef = true,
	brush = true,
	brush_invis = true,
	forest_alt = true
}

Stats.visionBlockingList = {
	forest = true,
	mountain = true,
	wall = true,
	building = true,
	mangrove = true,
	forest_alt = true,
	cave_wall = true,
	invisible_blocker_ocean = true
}

function Stats.isScout(unit)
	return Stats.scoutList[unit.unitClassId] ~= nil
end

function Stats.canSeeOver(unit)
	return Stats.seeOverList[unit.unitClassId] ~= nil
end

function Stats.isTerrainFowCover(terrainName)
	return Stats.fowCoverList[terrainName] ~= nil
end
function Stats.isTerrainBlocking(terrainName)
	return Stats.visionBlockingList[terrainName] ~= nil
end

Stats.terrainCost = {
	plains = {
		walking = 1,
		riding = 1,
		flying = 1,
		hovering = 1,
		wheels = 2,
		amphibious = 2
	},
	plains_alt = {
		walking = 1,
		riding = 1,
		flying = 1,
		hovering = 1,
		wheels = 2,
		amphibious = 2
	},
	rough = {
		walking = 1,
		riding = 1,
		hovering = 1,
		wheels = 2,
		amphibious = 2
	},
	brush = {
		walking = 1,
		riding = 2,
		flying = 1,
		hovering = 1,
		wheels = 3,
		amphibious = 3
	},
	brush_invis = {
		walking = 1,
		riding = 2,
		flying = 1,
		hovering = 1,
		wheels = 3,
		amphibious = 3
	},
	road = {
		walking = 1,
		riding = 1,
		flying = 1,
		hovering = 1,
		wheels = 1,
		amphibious = 2
	},
	cave_road = {
		walking = 1,
		riding = 1,
		hovering = 1,
		wheels = 1,
		amphibious = 2
	},
	forest = {
		walking = 2,
		riding = 3,
		flying = 1,
		hovering = 1,
		amphibious = 4
	},
	forest_invis = {
		walking = 2,
		riding = 3,
		flying = 1,
		hovering = 1,
		amphibious = 4
	},
	forest_alt = {
		walking = 2,
		riding = 3,
		flying = 1,
		hovering = 1,
		amphibious = 4
	},
	forest_no_hiding = {
		walking = 2,
		riding = 3,
		flying = 1,
		hovering = 1,
		amphibious = 4
	},
	forest_alt_no_hiding = {
		walking = 2,
		riding = 3,
		flying = 1,
		hovering = 1,
		amphibious = 4
	},
	mountain = {
		walking = 3,
		flying = 1,
		hovering = 1,
	},
	mountain_no_blocking = {
		walking = 3,
		flying = 1,
		hovering = 1,
	},
	cobblestone = {
		walking = 1,
		riding = 1,
		hovering = 1,
		amphibious = 2
	},
	carpet = {
		walking = 1,
		riding = 1,
		hovering = 1,
		amphibious = 2
	},
	wall = {
	},
	building = {
	},
	bridge = {
		walking = 1,
		riding = 1,
		flying = 1,
		hovering = 1,
		wheels = 1,
		amphibious = 1,
		sailing = 1,
		cantStop = {sailing = true}
	},
	bridge_wide = {
		walking = 1,
		riding = 1,
		flying = 1,
		hovering = 1,
		wheels = 1,
		amphibious = 1,
		sailing = 1,
		cantStop = {sailing = true}
	},
	cave_bridge = {
		walking = 1,
		riding = 1,
		hovering = 1,
		wheels = 1,
		amphibious = 1,
		sailing = 1,
		cantStop = {sailing = true}
	},
	sea = {
		sailing = 1,
		flying = 1,
		hovering = 1,
		amphibious = 1
	},
	sea_alt = {
		sailing = 1,
		flying = 1,
		hovering = 1,
		amphibious = 1
	},
	cave_sea = {
		sailing = 1,
		hovering = 1,
		amphibious = 1
	},
	quay = {
		sailing = 1,
		flying = 1,
		hovering = 1,
		amphibious = 1
	},
	ocean = {
		sailing = 1,
		flying = 1,
		hovering = 1,
		amphibious = 1
	},
	reef = {
		sailing = 2,
		flying = 1,
		hovering = 1,
		amphibious = 1
	},
	reef_no_hiding = {
		sailing = 2,
		flying = 1,
		hovering = 1,
		amphibious = 1
	},
	cave_reef = {
		sailing = 2,
		hovering = 1,
		amphibious = 1
	},
	river = {
		walking = 2,
		riding = 4,
		flying = 1,
		hovering = 1,
		amphibious = 1,
		sailing = 1
	},
	mangrove = {
		walking = 3,
		flying = 1,
		hovering = 1,
		amphibious = 2,
		sailing = 3
	},
	cave_river = {
		walking = 2,
		riding = 4,
		hovering = 1,
		amphibious = 1,
		sailing = 1
	},
	beach = {
		walking = 1,
		riding = 2,
		flying = 1,
		hovering = 1,
		amphibious = 1,
		sailing = 2
	},
	cave_beach = {
		walking = 1,
		riding = 2,
		hovering = 1,
		amphibious = 1,
		sailing = 2
	},
	street = {
		walking = 1,
		riding = 1,
		flying = 1,
		hovering = 1,
		wheels = 1,
		amphibious = 2
	}
}
local captureUnitList = {
	archer = true,
	mage = true,
	merman = true,
	rifleman = true,
	soldier = true,
	commander_duchess = true,
	commander_emeric = true,
	commander_mercival = true,
	spearman = true,
}
function Stats.getMovementType(unitClassId)
	local unitClass = Wargroove.getUnitClass(unitClassId)
	local validTags = {
		walking = true,
		riding = true,
		wheels = true,
		flying = true,
		hovering = true,
		amphibious = true,
		sailing = true
	}
	for i,tag in pairs(unitClass.tags) do
		if validTags[tag] ~= nil then
			return tag
		end
	end
	return nil
end
function Stats.getTerrainCost(terrainName, unitClassId)
	if Stats.terrainCost[terrainName] == nil then
		return 100
	end
	local movementType = Stats.getMovementType(unitClassId)
	if Stats.terrainCost[terrainName][movementType] ~= nil then
		return Stats.terrainCost[terrainName][movementType]
	end
	return 100
end
function Stats.canStopOnTerrain(terrainName, unitClassId)
	if Stats.terrainCost[terrainName] == nil then
		return false
	end
	local movementType = Stats.getMovementType(unitClassId)
	if Stats.terrainCost[terrainName][movementType] ~= nil then
		return not ((Stats.terrainCost[terrainName]["cantStop"] ~= nil) and (Stats.terrainCost[terrainName]["cantStop"][movementType] == true))
	end
	return false
end

function Stats.getCaptureUnitList()
	return captureUnitList
end

function Stats.canUnitClassCapture(unitClassId)
	return captureUnitList[unitClassId] == true
end

return Stats
