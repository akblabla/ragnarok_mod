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
	archer = 5,
	rival = 5,
	ballista = 4,
	commander_emeric = 5,
	commander_flagship_rival = 5,
	commander_flagship_wulfar = 5,
	commander_mercival = 5,
	commander_vesper = 5,
	commander_wulfar = 5,
	dog = 5,
	dragon = 6,
	flare = 6,
	giant = 4,
	harpoonship = 5,
	harpy = 6,
	knight = 3,
	mage = 5,
	merman = 5,
	pirate_ship = 5,
	pirate_ship_loaded = 5,
	reveal_all = 200,
	reveal_all_but_hidden = 200,
	reveal_all_but_over = 200,
	rifleman = 6,	
	soldier = 5,
	spearman = 4,
	trebuchet = 4,
	thief = 5,
	thief_with_gold = 5,
	travelboat = 3,
	turtle = 5,
	warship = 5,
	witch = 6,
	barracks = 1,
	city = 1,
	gate = 1,
	hideout = 1,
	hq = 2,
	port = 1,
	tower = 1,
	water_city = 1,
	crew = 0,
	gate_no_los_blocker = 1,
	wagon = 3,
	balloon = 4
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
	forest_alt = true
}

Stats.visionBlockingList = {
	forest = true,
	mountain = true,
	wall = true,
	mangrove = true,
	forest_alt = true,
	cave_wall = true,
	brush = true,
	brush_invis = true,
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


return Stats
