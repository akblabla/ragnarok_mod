local Wargroove = require "wargroove/wargroove"
local Ragnarok = require "initialized/ragnarok"

local function dump(o,level)
   if type(o) == 'table' then
      local s = '\n' .. string.rep("   ", level) .. '{\n'
      for k,v in pairs(o) do
         if type(k) ~= 'number' then k = '"'..k..'"' end
         s = s .. string.rep("   ", level+1) .. '['..k..'] = ' .. dump(v,level+1) .. ',\n'
      end
      return s .. string.rep("   ", level) .. '}'
   else
      return tostring(o)
   end
end


local VisionTracker = {}
local sightRangeList = {
	archer = 5,
	ballista = 4,
	commander_emeric = 5,
	commander_flagship_rival = 5,
	commander_flagship_wulfar = 5,
	commander_mercival = 5,
	commander_vesper = 5,
	commander_wulfar = 5,
	dog = 5,
	dragon = 6,
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
	trebuchet = 4,
	travelboat = 4,
	turtle = 5,
	warship = 5,
	witch = 7,
	barracks = 1,
	city = 1,
	gate = 1,
	hideout = 1,
	hq = 2,
	port = 1,
	tower = 1,
	water_city = 1,
	crew = 0,
	gate_no_los_blocker = 1
}

local scoutList = {
	dog = true,
	turtle = true,
	reveal_all = true,
	flare = true
}

local seeOverList = {
	harpy = true,
	dragon = true,
	reveal_all = true,
	reveal_all_but_hidden = true,
	witch = true
}

local fowCoverList = {
	forest = true,
	reef = true,
	mangrove = true,
	cave_reef = true,
	forest_alt = true
}

local visionBlockingList = {
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
function getSightRange(unit)
	local sightRange = sightRangeList[unit.unitClassId]
	local weather = Wargroove.getCurrentWeather()
	local isStructure = false
	for i,tag in ipairs(unit.unitClass.tags) do
		if tag=="structure" then
			isStructure = true
			break
		end
	end
	if weather == "windy" and scoutList[unit.unitClassId]==nil and not isStructure then
		sightRange = sightRange-1
	end
	if (weather == "rain" or weather == "sandstorm" or weather == "snow" or weather == "ash") and not isStructure then
		sightRange = sightRange-1
		if scoutList[unit.unitClassId]==nil then
			sightRange = sightRange-1
		end
	end
	sightRange = math.max(sightRange,0)
	return sightRange
end

local numberOfViewers = {}

local function getNumberOfViewers(team,pos)
	return numberOfViewers[team][pos.x][pos.y]
end

local function incrementNumberOfViewers(team,pos)
	numberOfViewers[team][pos.x][pos.y] = numberOfViewers[team][pos.x][pos.y] + 1
end

local function decrementNumberOfViewers(team,pos)
	numberOfViewers[team][pos.x][pos.y] = numberOfViewers[team][pos.x][pos.y] - 1
end

function VisionTracker.getPlayerTeam(playerId)
	if playerId == -1 then
		return -1
	end
	return Wargroove.getPlayerTeam(playerId)
end

function VisionTracker.addUnitToVisionMatrix(unit)
	local visibleTiles = VisionTracker.calculateVisionOfUnit(unit)
	local team = VisionTracker.getPlayerTeam(unit.playerId)
	for i, pos in pairs(visibleTiles) do
		incrementNumberOfViewers(team,pos)
	end
end

function VisionTracker.removeUnitFromVisionMatrix(unit)
	local visibleTiles = VisionTracker.calculateVisionOfUnit(unit)
	local team = VisionTracker.getPlayerTeam(unit.playerId)
	for i, pos in pairs(visibleTiles) do
		decrementNumberOfViewers(team,pos)
	end
end

local function getTilesInRectangle(pos1,pos2)
	local x1 = math.min(pos1.x,pos2.x)
	local x2 = math.max(pos1.x,pos2.x)
	local y1 = math.min(pos1.y,pos2.y)
	local y2 = math.max(pos1.y,pos2.y)
	
	local result = {}
	for x = x1, x2 do
		for y = y1, y2 do
			table.insert(result, {x=x, y=y})
		end
	end
	return result
end

local function crossProduct(A,B)
	return A.x*B.y-B.x*A.y
end

local function triangleArea(A, B, C)
	local AB = {x=B.x-A.x, y=B.y-A.y}
	local AC = {x=C.x-A.x, y=C.y-A.y}
	local area = math.abs(crossProduct(AB,AC)/2)
	--print("\t\t\t\t\ttriangleArea: "..tostring(area))
	return area
end
local function dotProduct(A,B)
	--print("\t\t\tdotProduct")
	--print("\t\t\tA: "..tostring(A.x)..", "..tostring(A.y))
	--print("\t\t\tB: "..tostring(B.x)..", "..tostring(B.y))
	local result = A.x*B.x+A.y*B.y
	--print("\t\t\tresult: "..tostring(result))
	return result
end
local function vectorRotate90(A)
	return {x = -A.y, y = A.x}
end
local function vectorLength(A)
	--print("\t\t\tvectorLength")
	--print("\t\t\tA: "..tostring(A.x)..", "..tostring(A.y))
	local result = math.sqrt(dotProduct(A,A))
	--print("\t\t\tresult: "..tostring(result))
	return result
end
local function vectorAdd(A,B)
	return {x=A.x+B.x,y=A.y+B.y}
end
local function vectorDifference(A,B)
	return {x=A.x-B.x,y=A.y-B.y}
end

local function vectorProjection(A,B)
	--print("\t\t\tvectorProjection")
	--print("\t\t\tA: "..tostring(A.x)..", "..tostring(A.y))
	--print("\t\t\tB: "..tostring(B.x)..", "..tostring(B.y))
	local scala = dotProduct(A,B)/dotProduct(B,B)
	--print("\t\t\tscala: "..tostring(scala))
	local result = {x=B.x*scala, y=B.y*scala}
	--print("\t\t\tresult: "..tostring(result.x)..", "..tostring(result.y))
	return result
end

local function vectorProjectionLength(A,B)
	-- print("\t\t\tvectorProjectionLength")
	-- print("\t\t\tA: "..tostring(A.x)..", "..tostring(A.y))
	-- print("\t\t\tB: "..tostring(B.x)..", "..tostring(B.y))
	local result = dotProduct(A,B)/vectorLength(B)
	-- print("\t\t\tresult: "..tostring(result))
	return result
end

local function getTilesInLine(A,B)
	-- print("\t\t\tgetTilesInLine starts here")
	local BA = vectorDifference(A,B)
	-- print("\t\t\tBA: "..tostring(BA.x)..", "..tostring(BA.y))
	local maxDist = vectorLength(BA)
	-- print("\t\t\tmaxDist: "..tostring(maxDist))
	local corners = {}
	if BA.x>0 then
		table.insert(corners,{x=1,y=0})
	elseif BA.x<0 then
		table.insert(corners,{x=-1,y=0})
	end
	if BA.y>0 then
		table.insert(corners,{x=0,y=1})
	elseif BA.y<0 then
		table.insert(corners,{x=0,y=-1})
	end
	-- print("\t\t\tcorners: ")
	-- print(dump(corners,9))
	for i,corner in pairs(corners) do
		-- print("\t\t\t\tcorner: "..tostring(corner.x)..", "..tostring(corner.y))
		local result = vectorProjectionLength(corner,BA)
		corner.speed = result
		-- print("\t\t\t\tcornerSpeed: "..tostring(corner.speed))
	end
	-- print("\t\t\tcornerSpeeds: ")
	-- print(dump(corners,9))
	local result = {}
	local dist = 0
	local currentOffset = {x=0,y=0}
	local BA90 = vectorRotate90(BA)
	-- print("\t\t\tBA90: "..tostring(BA90.x)..", "..tostring(BA90.y))
	-- print("\t\t\tFinding Path")
	while dist<maxDist do
		local leastErrorFromLine = 10000
		local bestCorner = nil
		for i,corner in pairs(corners) do
			local errorFromLine = math.abs(vectorProjectionLength(vectorAdd(corner,currentOffset),BA90))
			if errorFromLine<leastErrorFromLine then
				leastErrorFromLine = errorFromLine
				bestCorner = corner
			end
		end
		currentOffset = vectorAdd(bestCorner,currentOffset)
		dist = dist+bestCorner.speed
		table.insert(result,vectorAdd(B,currentOffset))
		-- print("\t\t\t\t Pos: "..tostring(currentOffset.x)..", "..tostring(currentOffset.y))
		-- print("\t\t\t\t Dist: "..tostring(dist))
	end
	return result
end

--Taken from https://www.baeldung.com/cs/circle-line-segment-collision-detection#:~:text=Mathematical%20Idea&text=on%20the%20line-,.,line%20collides%20with%20the%20circle.
--04/09-2022

local function lineSegmentCircleCollision(A, B, circleCenter, circleRadius)
	-- print("\t\t\t\tlineSegmentCircleCollision starts here")
	-- print("\t\t\t\tA: "..tostring(A.x)..", "..tostring(A.y))
	-- print("\t\t\t\tB: "..tostring(B.x)..", "..tostring(B.y))
	-- print("\t\t\t\tcircleCenter: "..tostring(circleCenter.x)..", "..tostring(circleCenter.y))
	-- print("\t\t\t\tcircleRadius: "..tostring(circleRadius))
	local minDist = circleRadius+1 --initial value must be some value bigger than circle radius
	-- print("\t\t\t\tminDist: "..tostring(minDist))
	local OA = {x=A.x-circleCenter.x, y=A.y-circleCenter.y}
	local OB = {x=B.x-circleCenter.x, y=B.y-circleCenter.y}
	local BA = {x=A.x-B.x, y=A.y-B.y}
	-- print("\t\t\t\tAssigned Derived Vectors: ")
	local distanceOA = vectorLength(OA)
	local distanceOB = vectorLength(OB)
	local distanceBA = vectorLength(BA)
	-- print("\t\t\t\tdistanceAB: "..tostring(distanceBA))
	local maxDist = math.max(distanceOA,distanceOB)
	-- print("\t\t\t\tmaxDist: "..tostring(maxDist))
	if dotProduct(OA,BA)>0 and dotProduct(OB,BA)<=0 then
		minDist = 2*triangleArea(circleCenter, A, B)/distanceBA
	else
		minDist = math.min(distanceOA,distanceOB)
	end
	if (minDist<=circleRadius and maxDist>=circleRadius) then
		-- print("\t\t\t\tCollision!")
		return true
	end
	-- print("\t\t\t\tNo collision")
	return false
end


function VisionTracker.init()

	print("VisionTracker Test added to list of tests")
	Ragnarok.addAction(VisionTracker.humanTest,"repeating",true)
	Ragnarok.addAction(VisionTracker.aiTest,"repeating",true)
	Ragnarok.addAction(VisionTracker.setup,"start_of_match",true)
end

local prevPosList = {}
function VisionTracker.getPrevPosList()
	return prevPosList
end

function VisionTracker.setup()
	
	print("Setting Up Team Array")
	for playerId=-1,Wargroove.getNumPlayers(false)-1 do
		-- print("Player: "..tostring(playerId))
		local team = VisionTracker.getPlayerTeam(playerId)
		-- print("team?")
		-- print("team: "..tostring(team))
		if team ~= nil and numberOfViewers[team] == nil then
			numberOfViewers[team] = {}
		end
	end
	-- print("Setting Up Vision Matrix")
	local mapSize = Wargroove.getMapSize()
	for team,i in pairs(numberOfViewers) do
		-- print("Team: "..tostring(team))
		for x=0, mapSize.x-1 do
			numberOfViewers[team][x] = {}
			for y=0, mapSize.y-1 do
				-- print("Pos: "..tostring(x)..","..tostring(y))
				numberOfViewers[team][x][y] = 0
			end
		end
	end
	
	for i, unit in pairs(Wargroove.getUnitsAtLocation(nil)) do
		local visibleTiles = VisionTracker.calculateVisionOfUnit(unit)
		team = VisionTracker.getPlayerTeam(unit.playerId)
		for i, pos in pairs(visibleTiles) do
			incrementNumberOfViewers(team,pos)
		end
		prevPosList[unit.id] = unit.pos
	end
	-- print(dump(numberOfViewers,0))
end

function VisionTracker.aiTest(context)
	if context:checkState("endOfUnitTurn") or context:checkState("endOfTurn") then
		local playerId = Wargroove.getCurrentPlayerId();
		if Wargroove.isHuman(playerId) == true then
			return
		end
		print("VisionTracker AI Test Starts here")
		print("Player is: "..tostring(playerId))

		local team = VisionTracker.getPlayerTeam(playerId)
		print("Player Team is: "..tostring(team))
		local mapSize = Wargroove.getMapSize()
		for x=0, mapSize.x-1 do
			for y=0, mapSize.y-1 do
				if VisionTracker.canSeeTile(playerId,{x = x, y = y}) then
				end
			end
		end
	end
end

function VisionTracker.humanTest(context)
	if context:checkState("endOfUnitTurn") or context:checkState("endOfTurn") then
		local playerId = Wargroove.getCurrentPlayerId();
		if Wargroove.isHuman(playerId) == false then
			return
		end
		print("VisionTracker Human Test Starts here")
		print("Player is: "..tostring(playerId))
		print("Player Team is: "..tostring(VisionTracker.getPlayerTeam(playerId)))
		Wargroove.updateFogOfWar()
		print("Fog of war updated")
		coroutine.yield()
		coroutine.yield()
		coroutine.yield()
		coroutine.yield()
		local testSuccess = true
		local units = Wargroove.getAllUnitsForPlayer(playerId, false)
		local failedTile = nil
		local failReason = nil
		local allTiles = {}
		local mapSize = Wargroove.getMapSize()
		for x=0, mapSize.x-1 do
			for y=0, mapSize.y-1 do
				allTiles[x+mapSize.x*y+1] = {x=x,y=y}
			end
		end
		for j, checkedTile in ipairs(allTiles) do
			--print("Checking Vision")
			local visionLoggerResult = VisionTracker.canSeeTile(playerId,checkedTile)
			--local visionTrackerResult = VisionTracker.canUnitSeeTile(unit,checkedTile)
			--visionTrackerResult = true
			local wargrooveResult = Wargroove.canPlayerSeeTile(playerId, checkedTile)
			-- if visionTrackerResult~=wargrooveResult then
				-- print("Vision Test failed at tile: "..tostring(checkedTile.x)..", "..tostring(checkedTile.y))
				-- failedTile = checkedTile
				-- if visionTrackerResult then
					-- failReason = "Vanilla Test. False Positive"
				-- else
					-- failReason = "Vanilla Test. False Negative"
				-- end
				-- testSuccess = false break
			-- end
			if visionLoggerResult~=wargrooveResult then
				print("Vision Logger Test failed at tile: "..tostring(checkedTile.x)..", "..tostring(checkedTile.y))
				failedTile = checkedTile
				if visionTrackerResult then
					failReason = "Logger Test. False Positive"
				else
					failReason = "Logger Test. False Negative"
				end
				testSuccess = false break
			end
		end
		print("VisionTracker Test Result: "..tostring(testSuccess))
		if (testSuccess == false) then
			Wargroove.showMessage("VisionTracker Test Failed")
			Wargroove.showMessage("Tile: "..tostring(failedTile.x)..","..tostring(failedTile.y))
			Wargroove.showMessage("Result: "..failReason)
		end
	end
end

function VisionTracker.isTileBlocking(origin, target, blocker)
	-- print("\t\t\tVisionTracker.isTileBlocking(origin, target, blocker) starts here")
	local blockerTerrainType = Wargroove.getTerrainNameAt(blocker)
	-- print("\t\t\tblockerTile is: " .. blockerTerrainType)
	if math.floor(origin.x+0.5) == blocker.x and math.floor(origin.y+0.5) == blocker.y then return false end
	-- print("\t\t\tblockerTile wasn't origin")
	if math.floor(target.x+0.5) == blocker.x and math.floor(target.y+0.5) == blocker.y then return false end
	-- print("\t\t\tblockerTile wasn't target")
	if visionBlockingList[blockerTerrainType] == nil then return false end
	-- print("\t\t\tblockerTile can block vision")
	if lineSegmentCircleCollision(origin, target, blocker, 0.5) then
		-- print("\t\t\tblockerTile blocked vision")
		return true
	end
	-- print("\t\t\tblockerTile did vision")
	return false
end

function VisionTracker.canSeeTile(playerId,tile)
	return getNumberOfViewers(VisionTracker.getPlayerTeam(playerId),tile)>0
end

function VisionTracker.canUnitSeeTile(unit,tile)
	-- print("\tVisionTracker.canUnitSeeTile(unit,tile) starts here")
	-- print("\t\t\t\tTile at Pos: "..tostring(tile.x)..", "..tostring(tile.y))
	local difference = {x = tile.x - unit.pos.x, y = tile.y - unit.pos.y}
	local dist = math.abs(difference.x)+math.abs(difference.y)
	if dist<=1 then
		return true
	end
	-- print("\tDistance was: ".. tostring(dist))
	if dist>getSightRange(unit) then return false end
	-- print("\tClose enough to see potentially")
	if scoutList[unit.unitClassId] ~= nil then return true end
	-- print("\tNot a scout")
	local terrainType = Wargroove.getTerrainNameAt(tile)
	-- print("\tThe tile is a: ".. terrainType)
	if fowCoverList[terrainType] ~= nil and dist>1 then return false end
	-- print("\tThe tile is not fog cover, or at least touching")
	if seeOverList[unit.unitClassId] ~= nil then return true end
	-- print("\tCan't see over terrain")
	local isFullyBlocked = true
	local euclideanDist = vectorLength(difference)
	towardsUnitVector = {x = difference.x/euclideanDist,y = difference.y/euclideanDist}
	perpendicularUnitVector = vectorRotate90(towardsUnitVector)
	
	local offsets = {{x = 0.1*(-perpendicularUnitVector.x), y = 0.1*(-perpendicularUnitVector.y)},
		{x = 0.1*(perpendicularUnitVector.x), y = 0.1*(perpendicularUnitVector.y)},
		{x = 0, y = 0}}
	for i, offset in pairs(offsets) do
		local isBlocked = false
		local origin = {x = unit.pos.x+offset.x/2, y = unit.pos.y+offset.y/2}
		local target = {x = tile.x+offset.x, y = tile.y+offset.y}
		for j,blockingTile in pairs(getTilesInLine(unit.pos,tile)) do
			-- print("\t\tChecking Blocking Tile: "..tostring(blockingTile.x)..", "..tostring(blockingTile.y))
			if VisionTracker.isTileBlocking(origin, target, blockingTile) then
				-- print("\t\tTile was blocking")
				isBlocked = true
				break
			end
			-- print("\t\tTile was not blocking")		
		end
		if isBlocked == false then
			isFullyBlocked = false
		end
	end
	-- print("\tLots of LoS checking done")
	if isFullyBlocked then return false end
	-- print("\tNo blockers!")
	return true
end

function VisionTracker.calculateVisionOfUnit(unit)
	-- print("calculateVisionOfUnit(unit) starts here")
	local tilesInRange = Wargroove.getTargetsInRange(unit.pos, getSightRange(unit), "all")
	-- print("Got the tiles in range")
	if scoutList[unit.unitClassId] ~= nil then return tilesInRange end
	-- print("Not a scout, so LoS checks are needed")
	local visibleTiles = {}
	for i, checkedTile in ipairs(tilesInRange) do
		-- print("checking LoS at: "..tostring(checkedTile.x)..","..tostring(checkedTile.y))
		if VisionTracker.canUnitSeeTile(unit,checkedTile) then
			-- print("Tile at: "..tostring(checkedTile.x)..","..tostring(checkedTile.y))
			-- print("Visible")
			table.insert(visibleTiles, checkedTile)
		else
			-- print("Tile at: "..tostring(checkedTile.x)..","..tostring(checkedTile.y))
			-- print("Not Visible")			
		end
	end
	return visibleTiles
end

return VisionTracker
