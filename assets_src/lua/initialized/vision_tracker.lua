local Wargroove = require "wargroove/wargroove"
local Ragnarok = require "initialized/ragnarok"

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
	witch = 7
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
	invisible_blocker_ocean = true
}

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

--Taken from https://www.baeldung.com/cs/circle-line-segment-collision-detection#:~:text=Mathematical%20Idea&text=on%20the%20line-,.,line%20collides%20with%20the%20circle.
--04/09-2022
local function crossProduct(A,B)
	return A.x*B.y-B.x*A.y
end

local function triangleArea(A, B, C)
	local AB = {x=B.x-A.x, y=B.y-A.y}
	local AC = {x=C.x-A.x, y=C.y-A.y}
	local area = math.abs(crossProduct(AB,AC)/2)
	print("\t\t\t\t\ttriangleArea: "..tostring(area))
	return area
end
local function dotProduct(A,B)
	return A.x*B.x+A.y*B.y
end
local function vectorRotate90(A)
	return {x = -A.y, y = A.x}
end
local function vectorLength(A)
	return math.sqrt(dotProduct(A,A))
end

local function lineSegmentCircleCollision(A, B, circleCenter, circleRadius)
	print("\t\t\t\tlineSegmentCircleCollision starts here")
	print("\t\t\t\tA: "..tostring(A.x)..", "..tostring(A.y))
	print("\t\t\t\tB: "..tostring(B.x)..", "..tostring(B.y))
	print("\t\t\t\tcircleCenter: "..tostring(circleCenter.x)..", "..tostring(circleCenter.y))
	print("\t\t\t\tcircleRadius: "..tostring(circleRadius))
	local minDist = circleRadius+1 --initial value must be some value bigger than circle radius
	print("\t\t\t\tminDist: "..tostring(minDist))
	local OA = {x=A.x-circleCenter.x, y=A.y-circleCenter.y}
	local OB = {x=B.x-circleCenter.x, y=B.y-circleCenter.y}
	local BA = {x=A.x-B.x, y=A.y-B.y}
	print("\t\t\t\tAssigned Derived Vectors: ")
	local distanceOA = vectorLength(OA)
	local distanceOB = vectorLength(OB)
	local distanceBA = vectorLength(BA)
	print("\t\t\t\tdistanceAB: "..tostring(distanceBA))
	local maxDist = math.max(distanceOA,distanceOB)
	print("\t\t\t\tmaxDist: "..tostring(maxDist))
	if dotProduct(OA,BA)>0 and dotProduct(OB,BA)<=0 then
		minDist = 2*triangleArea(circleCenter, A, B)/distanceBA
	else
		minDist = math.min(distanceOA,distanceOB)
	end
	if (minDist<=circleRadius and maxDist>=circleRadius) then
		print("\t\t\t\tCollision!")
		return true
	end
	print("\t\t\t\tNo collision")
	return false
end


function VisionTracker.init()

	print("VisionTracker Test added to list of tests")
	Ragnarok.addAction(VisionTracker.test,"repeating",true)
end

function VisionTracker.test(context)
	if context:checkState("endOfUnitTurn") == true then
		print("VisionTracker Test Starts here")
		Wargroove.updateFogOfWar()
		print("Fog of war updated")
		coroutine.yield()
		coroutine.yield()
		coroutine.yield()
		coroutine.yield()
		local testSuccess = true
		local units = Wargroove.getAllUnitsForPlayer(0, false)
		local failedTile = nil
		local failedFalsePositive = nil
		print("Units Acquired")
		print(dump(units,0))
		for i, unit in pairs(units) do
			if testSuccess then
				print("Got inside the loop")
				local tilesInRange = Wargroove.getTargetsInRange(unit.pos, sightRangeList[unit.unitClassId], "all")
				print("Tiles Acquired")
				print(dump(tilesInRange,0))
				for j, checkedTile in ipairs(tilesInRange) do
					print("Checking Vision")
					local visionTrackerResult = VisionTracker.canUnitSeeTile(unit,checkedTile)
					--visionTrackerResult = true
					local wargrooveResult = Wargroove.canPlayerSeeTile(unit.playerId, checkedTile)
					if visionTrackerResult~=wargrooveResult then
						print("Vision Test failed at tile: "..tostring(checkedTile.x)..", "..tostring(checkedTile.y))
						failedTile = checkedTile
						failedFalsePositive = visionTrackerResult
						testSuccess = false break
					end
				end
			end
		end
		print("VisionTracker Test Result: "..tostring(testSuccess))
		if (testSuccess == false) then
			Wargroove.showMessage("VisionTracker Test Failed")
			Wargroove.showMessage("Tile: "..tostring(failedTile.x)..","..tostring(failedTile.y))
			if failedFalsePositive then
				Wargroove.showMessage("Result: False Positive")
			else
				Wargroove.showMessage("Result: False Negative")
			end
		end
	end
end

function VisionTracker.isTileBlocking(origin, target, blocker)
	print("\t\t\tVisionTracker.isTileBlocking(origin, target, blocker) starts here")
	local blockerTerrainType = Wargroove.getTerrainNameAt(blocker)
	print("\t\t\tblockerTile is: " .. blockerTerrainType)
	if math.floor(origin.x+0.5) == blocker.x and math.floor(origin.y+0.5) == blocker.y then return false end
	print("\t\t\tblockerTile wasn't origin")
	if math.floor(target.x+0.5) == blocker.x and math.floor(target.y+0.5) == blocker.y then return false end
	print("\t\t\tblockerTile wasn't target")
	if visionBlockingList[blockerTerrainType] == nil then return false end
	print("\t\t\tblockerTile can block vision")
	if lineSegmentCircleCollision(origin, target, blocker, 0.5) then
		print("\t\t\tblockerTile blocked vision")
		return true
	end
	print("\t\t\tblockerTile did vision")
	return false
end

function VisionTracker.canUnitSeeTile(unit,tile)
	print("\tVisionTracker.canUnitSeeTile(unit,tile) starts here")
	print("\t\t\t\tTile at Pos: "..tostring(tile.x)..", "..tostring(tile.y))
	local difference = {x = tile.x - unit.pos.x, y = tile.y - unit.pos.y}
	local dist = math.abs(difference.x)+math.abs(difference.y)
	if dist<=1 then
		return true
	end
	print("\tDistance was: ".. tostring(dist))
	if dist>sightRangeList[unit.unitClassId] then return false end
	print("\tClose enough to see potentially")
	if scoutList[unit.unitClassId] ~= nil then return true end
	print("\tNot a scout")
	local terrainType = Wargroove.getTerrainNameAt(tile)
	print("\tThe tile is a: ".. terrainType)
	if fowCoverList[terrainType] ~= nil and dist>1 then return false end
	print("\tThe tile is not fog cover, or at least touching")
	if seeOverList[unit.unitClassId] ~= nil then return true end
	print("\tCan't see over terrain")
	local isFullyBlocked = true
	local euclideanDist = vectorLength(difference)
	towardsUnitVector = {x = difference.x/euclideanDist,y = difference.y/euclideanDist}
	perpendicularUnitVector = vectorRotate90(towardsUnitVector)
	
	local offsets = {{x = 0.1*(-perpendicularUnitVector.x), y = 0.1*(-perpendicularUnitVector.y)},
		{x = 0.1*(perpendicularUnitVector.x), y = 0.1*(perpendicularUnitVector.y)}}
	for i, offset in pairs(offsets) do
		local isBlocked = false
		local origin = {x = unit.pos.x+offset.x/2, y = unit.pos.y+offset.y/2}
		local target = {x = tile.x+offset.x, y = tile.y+offset.y}
		for j,blockingTile in pairs(getTilesInRectangle(unit.pos,tile)) do
			print("\t\tChecking Blocking Tile: "..tostring(blockingTile.x)..", "..tostring(blockingTile.y))
			if VisionTracker.isTileBlocking(origin, target, blockingTile) then
				print("\t\tTile was blocking")
				isBlocked = true
				break
			end
			print("\t\tTile was not blocking")		
		end
		if isBlocked == false then
			isFullyBlocked = false
		end
	end
	print("\tLots of LoS checking done")
	if isFullyBlocked then return false end
	print("\tNo blockers!")
	return true
end

function VisionTracker.calculateVisionOfUnit(unit)
	local tilesInRange = Wargroove.getTargetsInRange(unit.pos, sightRangeList[unit.unitClassId], "all")
	if scoutList[unit.unitClassId] ~= nil then return tilesInRange end
	local visibleTiles = {}
	for i, checkedTile in ipairs(tilesInRange) do
		if VisionTracker.canUnitSeeTile(unit,checkedTile) then table.insert(visibleTiles, checkedTile) end
	end
	return visibleTiles
end

function dump(o,level)
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

return VisionTracker
