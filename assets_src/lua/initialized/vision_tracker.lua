local Wargroove = require "wargroove/wargroove"
local Ragnarok = require "initialized/ragnarok"
local Stats = require "util/stats"
local VectorMath = require "util/vectorMath"

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

local setupRan = false

local VisionTracker = {}

local function isInsideBounds(pos)
	local mapSize = Wargroove.getMapSize()
	return pos.x>=0 and pos.x<mapSize.x and pos.y>=0 and pos.y<mapSize.y
end

function VisionTracker.getSightRange(unit)
	if Stats.sightRangeList[unit.unitClassId] == nil then
		return 0
	end
	local sightRange = Stats.sightRangeList[unit.unitClassId]
	local weather = Wargroove.getCurrentWeather()
	local isStructure = false
	for i,tag in ipairs(unit.unitClass.tags) do
		if tag=="structure" then
			isStructure = true
			break
		end
	end
	if (weather == "rain" or weather == "sandstorm" or weather == "snow" or weather == "ash") and not isStructure then
		sightRange = sightRange-1
	end
	sightRange = math.max(sightRange,0)
	return sightRange
end


local lastKnownUnitStateList = {}
function VisionTracker.setLastKnownUnitState(unit)
	lastKnownUnitStateList[unit.id] = {}
	lastKnownUnitStateList[unit.id].pos = {}
	lastKnownUnitStateList[unit.id].pos.x = unit.pos.x
	lastKnownUnitStateList[unit.id].pos.y = unit.pos.y
	lastKnownUnitStateList[unit.id].id = unit.id
	lastKnownUnitStateList[unit.id].playerId = unit.playerId
	lastKnownUnitStateList[unit.id].unitClassId = unit.unitClassId
	lastKnownUnitStateList[unit.id].unitClass = {}
	lastKnownUnitStateList[unit.id].unitClass.tags = {}
	for i, tag in ipairs(unit.unitClass.tags) do
		lastKnownUnitStateList[unit.id].unitClass.tags[i] = tag
	end
end

function VisionTracker.getLastKnownUnitState(unitId)
	if lastKnownUnitStateList[unitId]==nil then
		VisionTracker.setLastKnownUnitState(Wargroove.getUnitById(unitId))
	end
	return lastKnownUnitStateList[unitId]
end

function VisionTracker.getLastKnownUnitStateList()
	return lastKnownUnitStateList
end

local numberOfViewers = {}
local listOfViewers = {}

local function getViewers(pos)
	if setupRan then
		if isInsideBounds(pos) == false then
			return {}
		end
		return listOfViewers[pos.x][pos.y]
	end
	return {}
end

local function getNumberOfViewers(player,pos)
	if setupRan then
		if isInsideBounds(pos) == false then
			return 0
		end
		return numberOfViewers[player][pos.x][pos.y]
	end
	return 0
end

local function incrementNumberOfViewers(player,pos)
	if isInsideBounds(pos) == false then
		return
	end
	numberOfViewers[player][pos.x][pos.y] = numberOfViewers[player][pos.x][pos.y] + 1
end

local function addUnitToListOfViewers(unit,pos)
	if isInsideBounds(pos) == false then
		return
	end
	listOfViewers[pos.x][pos.y][unit.id] = unit.pos
	incrementNumberOfViewers(unit.playerId,pos)
end

local function decrementNumberOfViewers(player,pos)
	if isInsideBounds(pos) == false then
		return
	end
	numberOfViewers[player][pos.x][pos.y] = math.max(numberOfViewers[player][pos.x][pos.y] - 1,0)
end

local function removeUnitFromListOfViewers(unit,pos)
	if isInsideBounds(pos) == false then
		return
	end
	if (listOfViewers[pos.x][pos.y][unit.id]~=nil) then
		decrementNumberOfViewers(unit.playerId,pos)
	end
	listOfViewers[pos.x][pos.y][unit.id] = nil
end

local teamPlayers = {}

local function isDifferent(o1,o2)
	if type(o1) == 'table' then
		for k,v in pairs(o1) do
			if o2[k] == nil then
				return true
			end
			if isDifferent(o1[k],o2[k]) then
				return true
			end
		end
		return false
	else
		return o1~=o2
	end
end

function VisionTracker.addUnitToVisionMatrix(unit)
	if setupRan then
		if isInsideBounds(unit.pos) == false then
			return
		end
		local visibleTiles = VisionTracker.calculateVisionOfUnit(unit)
		local playerId = unit.playerId
		for i, pos in pairs(visibleTiles) do
			addUnitToListOfViewers(unit,pos)
		end
		VisionTracker.setLastKnownUnitState(unit)
	end
end

function VisionTracker.updateUnitInVisionMatrix(unit)
	if setupRan then
		local prevState = VisionTracker.getLastKnownUnitState(unit.id)
		if isDifferent(prevState,unit) then
			local visibleTiles = VisionTracker.calculateVisionOfUnit(prevState)
			local playerId = prevState.playerId
			for i, pos in pairs(visibleTiles) do
				removeUnitFromListOfViewers(prevState,pos)
			end
		
			visibleTiles = VisionTracker.calculateVisionOfUnit(unit)
			playerId = unit.playerId
			for i, pos in pairs(visibleTiles) do
				addUnitToListOfViewers(unit,pos)
			end
		end
		VisionTracker.setLastKnownUnitState(unit)
	end
end

function VisionTracker.removeUnitFromVisionMatrix(unit)
	if setupRan then
		local prevState = VisionTracker.getLastKnownUnitState(unit.id)
		local visibleTiles = VisionTracker.calculateVisionOfUnit(prevState)
		local playerId = prevState.playerId
		for i, pos in pairs(visibleTiles) do
			removeUnitFromListOfViewers(prevState,pos)
		end
		prevState = nil
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
	return area
end
local function dotProduct(A,B)
	local result = A.x*B.x+A.y*B.y
	return result
end
local function vectorRotate90(A)
	return {x = -A.y, y = A.x}
end
local function vectorLength(A)
	local result = math.sqrt(dotProduct(A,A))
	return result
end
local function vectorAdd(A,B)
	return {x=A.x+B.x,y=A.y+B.y}
end
local function vectorDifference(A,B)
	return {x=A.x-B.x,y=A.y-B.y}
end
local function vectorScale(A,b)
	return {x=A.x*b,y=A.y*b}
end
local function vectorProjection(A,B)
	local scala = dotProduct(A,B)/dotProduct(B,B)
	local result = {x=B.x*scala, y=B.y*scala}
	return result
end

local function vectorProjectionLength(A,B)
	local result = dotProduct(A,B)/vectorLength(B)
	return result
end

local function getTilesInLine(A,B)
	local BA = vectorDifference(A,B)
	local maxDist = vectorLength(BA)
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
	for i,corner in pairs(corners) do
		local result = vectorProjectionLength(corner,BA)
		corner.speed = result
	end
	local result = {}
	local dist = 0
	local currentOffset = {x=0,y=0}
	local BA90 = vectorRotate90(BA)
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
	end
	return result
end

--Taken from https://www.baeldung.com/cs/circle-line-segment-collision-detection#:~:text=Mathematical%20Idea&text=on%20the%20line-,.,line%20collides%20with%20the%20circle.
--04/09-2022

local function lineSegmentCircleCollision(A, B, circleCenter, circleRadius)
	local minDist = circleRadius+1 --initial value must be some value bigger than circle radius
	local OA = {x=A.x-circleCenter.x, y=A.y-circleCenter.y}
	local OB = {x=B.x-circleCenter.x, y=B.y-circleCenter.y}
	local BA = {x=A.x-B.x, y=A.y-B.y}
	local distanceOA = vectorLength(OA)
	local distanceOB = vectorLength(OB)
	local distanceBA = vectorLength(BA)
	local maxDist = math.max(distanceOA,distanceOB)
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
	--print("VisionTracker Test added to list of tests")
--	Ragnarok.addAction(VisionTracker.setup,"start_of_match",true)
--	Ragnarok.addAction(VisionTracker.humanTest,"repeating",true)
	Ragnarok.addAction(VisionTracker.weatherChecker,"repeating",true)
	--Ragnarok.addAction(VisionTracker.aiTest,"repeating",true)
end

local lastWeather = nil
function VisionTracker.weatherChecker(context)
	if context:checkState("startOfTurn") then
		Wargroove.updateFogOfWar()
		if not Ragnarok.usingFogOfWarRules() then
			return
		end
		local playerId = Wargroove.getCurrentPlayerId();
		if playerId ~= 0 then
			return
		end
		local newWeather = Wargroove.getCurrentWeather();
		if lastWeather ~= newWeather then
			VisionTracker.reset()
		end
		lastWeather = newWeather
	end
end

function VisionTracker.setupTeamPlayers()
	teamPlayers = {}
	for playerId=-2,Wargroove.getNumPlayers(false)-1 do
		if playerId >= 0 and Wargroove.getPlayerTeam(playerId) ~= nil then
			if teamPlayers[Wargroove.getPlayerTeam(playerId)] == nil then
				teamPlayers[Wargroove.getPlayerTeam(playerId)] = {}
			end
			table.insert(teamPlayers[Wargroove.getPlayerTeam(playerId)],playerId)
		end
	end
end

function VisionTracker.reset()
	numberOfViewers = {}
	lastKnownUnitStateList = {}
	setupRan = false
	VisionTracker.setup()
end

function VisionTracker.setup()
	if setupRan then
		return
	end
	setupRan = true
	VisionTracker.setupTeamPlayers()
	for playerId=-2,Wargroove.getNumPlayers(false)-1 do
		if playerId ~= nil and numberOfViewers[playerId] == nil then
			numberOfViewers[playerId] = {}
		end
	end
	local mapSize = Wargroove.getMapSize()
	for checkedPlayerId,i in pairs(numberOfViewers) do
		for x=0, mapSize.x-1 do
			numberOfViewers[checkedPlayerId][x] = {}
			for y=0, mapSize.y-1 do
				numberOfViewers[checkedPlayerId][x][y] = 0
			end
		end
	end
	
	for x=0, mapSize.x-1 do
		listOfViewers[x] = {}
		for y=0, mapSize.y-1 do
			listOfViewers[x][y] = {}
		end
	end

	for i, unit in pairs(Wargroove.getUnitsAtLocation(nil)) do
		local visibleTiles = VisionTracker.calculateVisionOfUnit(unit)
		for j, pos in pairs(visibleTiles) do
			addUnitToListOfViewers(unit,pos)
		end
		VisionTracker.setLastKnownUnitState(unit)
	end
end


function VisionTracker.aiTest(context)

end

function VisionTracker.humanTest(context)
	if (context:checkState("endOfUnitTurn") or context:checkState("endOfTurn")) and Ragnarok.usingFogOfWarRules() then
		local playerId = Wargroove.getCurrentPlayerId();
		Wargroove.updateFogOfWar()
		if Wargroove.isHuman(playerId) == false then
			return
		end
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
				if visionLoggerResult then
					failReason = "Logger Test. False Positive"
				else
					failReason = "Logger Test. False Negative"
				end
				testSuccess = false break
			end
		end
		if (testSuccess == false) then
			Wargroove.showMessage("VisionTracker Test Failed")
			Wargroove.showMessage("Tile: "..tostring(failedTile.x)..","..tostring(failedTile.y))
			Wargroove.showMessage("Result: "..failReason)
		end
	end
end

function VisionTracker.isTileBlocker(tile)
	local blockerTerrainType = Wargroove.getTerrainNameAt(tile)
	return Stats.visionBlockingList[blockerTerrainType] ~= nil
end

function VisionTracker.isTileBlocking(origin, target, blocker)
	if math.floor(origin.x+0.5) == blocker.x and math.floor(origin.y+0.5) == blocker.y then return false end
	if math.floor(target.x+0.5) == blocker.x and math.floor(target.y+0.5) == blocker.y then return false end
	if not VisionTracker.isTileBlocker(blocker) then return false end
	local dist = vectorLength(vectorDifference(origin,target))
	if lineSegmentCircleCollision(origin, target, blocker, math.min(0.5+dist/200,0.6)) then
		return true
	end
	return false
end

function VisionTracker.canSeeTile(playerId,tile)
	if not Ragnarok.usingFogOfWarRules() then
		return true
	end
	VisionTracker.setup()
	if playerId < 0 then
		return getNumberOfViewers(playerId,tile)>0
	else
		for i, checkedPlayerId in pairs(teamPlayers[Wargroove.getPlayerTeam(playerId)]) do
			if getNumberOfViewers(checkedPlayerId,tile)>0 then
				return true
			end
		end
	end
	
	return false
end

function VisionTracker.canUnitSeeTile(unit,tile)
	if not Ragnarok.usingFogOfWarRules() then
		return true
	end
	if unit == nil then
		return false
	end
	if tile == nil then
		return false
	end
	local difference = {x = tile.x - unit.pos.x, y = tile.y - unit.pos.y}
	local dist = math.abs(difference.x)+math.abs(difference.y)
	if dist == 0 then
		return true
	end
	if dist<=1 and VisionTracker.getSightRange(unit)>0 then
		return true
	end
	if dist>VisionTracker.getSightRange(unit) then return false end
	if Stats.scoutList[unit.unitClassId] ~= nil then return true end
	local terrainType = Wargroove.getTerrainNameAt(tile)
	if (Stats.fowCoverList[terrainType] ~= nil) and (dist>1) then return false end
	if Stats.seeOverList[unit.unitClassId] ~= nil then return true end
	local isFullyBlocked = true
	local euclideanDist = vectorLength(difference)
	towardsUnitVector = {x = difference.x/euclideanDist,y = difference.y/euclideanDist}
	perpendicularUnitVector = vectorRotate90(towardsUnitVector)
	
	-- local offsets = {{x = 0.1*(-perpendicularUnitVector.x), y = 0.1*(-perpendicularUnitVector.y)},
		-- {x = 0.1*(perpendicularUnitVector.x), y = 0.1*(perpendicularUnitVector.y)},
		-- {x = 0, y = 0}}
	local offsets = {{x = 0.075, y = 0.075},{x = -0.075, y = 0.075},{x = -0.075, y = -0.075},{x = 0.075, y = -0.075},{x = 0, y = 0}}
	for i, offset in pairs(offsets) do
		local isBlocked = false
		local origin = {x = unit.pos.x+offset.x, y = unit.pos.y+offset.y}
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
	local mapSize = Wargroove.getMapSize()
	if isInsideBounds(unit.pos) == false then
		return {}
	end
	--Wargroove.showMessage("Calculating vision of unit "..unit.id)
	-- print("calculateVisionOfUnit(unit) starts here")
	if VisionTracker.getSightRange(unit) == 0 then
		return {unit.pos}
	end
	local tilesInRange = Wargroove.getTargetsInRange(unit.pos, VisionTracker.getSightRange(unit), "all")
	-- print("Got the tiles in range")
	if Stats.scoutList[unit.unitClassId] ~= nil then return tilesInRange end
	if Stats.seeOverList[unit.unitClassId] ~= nil then
		local visibleTiles = {}
		for i, checkedTile in ipairs(tilesInRange) do
			-- print("checking LoS at: "..tostring(checkedTile.x)..","..tostring(checkedTile.y))
			local checkedTerrainName = Wargroove.getTerrainNameAt(checkedTile)
			local dist = math.abs(checkedTile.x-unit.pos.x)+math.abs(checkedTile.y-unit.pos.y)
			if Stats.fowCoverList[checkedTerrainName] == nil or dist <=1 then
				table.insert(visibleTiles, checkedTile)
			end
		end
		return visibleTiles
	end
	--print("loading pulse scanner")
	local PulseScanner = require "util/pulseScanner"
	--print("loaded pulse scanner")
	local function getBlockerRadius(origin, pos)
		local dist = VectorMath.dist(origin, pos)
		return math.min(0.5+dist/200,0.6)
	end

	--print("Setting Blocker Function")
	PulseScanner.setBlockerFunction(VisionTracker.isTileBlocker)
	--print("Setting Blocker Radius Function")
	PulseScanner.setBlockerRadiusFunction(getBlockerRadius)
	--print("Checking if Scout")
	local isScout = Stats.isScout(unit)
	--print("Checking if it can see over")
	local canSeeOver = Stats.canSeeOver(unit)
	--print("Checking sight range")
	local sightRange = VisionTracker.getSightRange(unit)
	--print("Calculating LoS using pulse")
	local function removeDuplicates(data)
		local hash = {}
		local res = {}

		for _,v in ipairs(data) do
		   if (not hash[v]) then
			   res[#res+1] = v -- you could print here instead of saving to result table if you wanted
			   hash[v] = true
		   end
		end
		return data
	end
	local visibleTiles = VisionTracker.calculateLoSOfUnitRays(unit,math.min(5,sightRange))
	if sightRange>5 then
		local foundTiles = PulseScanner.calculateLoSOfUnitPulse(unit.pos, isScout, canSeeOver, sightRange,{x=0,y=0}, {x = mapSize.x, y = mapSize.y})
		for i, tile in pairs(foundTiles) do
			table.insert(visibleTiles,tile)
		end
		visibleTiles = removeDuplicates(visibleTiles)
	end
	return visibleTiles
--	return VisionTracker.calculateLoSOfUnitRays(unit,getSightRange(unit))
end

function VisionTracker.calculateLoSOfUnitRays(unit,sightRange)
	local tilesInRange = Wargroove.getTargetsInRange(unit.pos, sightRange, "all")
	local visibleTiles = {}
	for i, checkedTile in ipairs(tilesInRange) do
		if VisionTracker.canUnitSeeTile(unit,checkedTile) then
			table.insert(visibleTiles, checkedTile)		
		end
	end
	return visibleTiles
end

function VisionTracker.getListOfViewerIds(pos)
	VisionTracker.setup()
	if setupRan then
		return getViewers(pos)
	end
	return {}
end


return VisionTracker
