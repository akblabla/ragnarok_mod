local VectorMath = require "util/vectorMath"

local PulseScanner = {}

PulseScanner.__index = PulseScanner

local isBlockerFunction;
local blockerRadiusFunction;

function PulseScanner.setBlockerFunction(func)
	isBlockerFunction = func
end

function PulseScanner.setBlockerRadiusFunction(func)
	blockerRadiusFunction = func
end

local function getKnownOcclusionTileOrder(pos, range)
	local result = {}
	local orientationId = 0
	local currentOrientationMatrixTable = {
		{{x=1,y=0}, {x=0,y=1}},
		{{x=-1,y=0}, {x=0,y=-1}},
		{{x=0,y=-1}, {x=1,y=0}},
		{{x=0,y=1}, {x=-1,y=0}}
	}
	local layer = 1
	local currentLayerSize = 1
	while layer<=range do
		for orientationId = 1, 4 do
			for i = 0,currentLayerSize*2-2 do
				local offset = {x = layer, y = math.ceil(i/2.0)*(2*(i%2)-1)}
				if math.abs(offset.x)+math.abs(offset.y) > range then
					break
				end
				local rotatedOffset = {x = VectorMath.dotProduct(offset,currentOrientationMatrixTable[orientationId][1]),
					y = VectorMath.dotProduct(offset,currentOrientationMatrixTable[orientationId][2])}
				table.insert(result,VectorMath.add(pos,rotatedOffset))

			end
			if orientationId == 2 then
				currentLayerSize = currentLayerSize+1
			end
		end
		layer = layer+1
	end
	return result
end

local function getBlockerCorners(origin,blockerPos)
	local dist = VectorMath.dist(origin,blockerPos)
	local radius = blockerRadiusFunction(origin, blockerPos)
	local diff = VectorMath.diff(origin,blockerPos)
	local baseAngle = math.atan2(diff.y,diff.x)
	local deltaAngle = math.asin(radius/dist)
	local lowerAngle = (baseAngle-deltaAngle)%(2*math.pi)
	local upperAngle = (baseAngle+deltaAngle)%(2*math.pi)
	return lowerAngle, upperAngle
end

local function getRelativeAngle(originAngle, angle)
	return (angle-originAngle)%(2*math.pi)
end

function PulseScanner.calculateLoSOfUnitPulse(pos, scout, canSeeOver, sightRange)
	if Tree == nil then
        Tree = require "util/binarySearchTreeDoubleLinked"
    end
	local visibleTiles = {}
	local orderedTiles = getKnownOcclusionTileOrder(pos, sightRange)
	local t = Tree:new()
	for i, checkedTile in ipairs(orderedTiles) do
		print("Checked Tile: "..tostring(checkedTile.x)..","..tostring(checkedTile.y))
		local dist = VectorMath.dist(pos,checkedTile)
		if(not isBlockerFunction(checkedTile)) or dist<=1 then
			local diff = VectorMath.diff(pos,checkedTile)
			local angle = math.atan2(diff.y,diff.x)%(2*math.pi)

			local angleNode = t:getNodeBefore(angle)
			if angleNode == nil or (angleNode ~= nil and angleNode:getData() == false) then
				table.insert(visibleTiles, checkedTile)
				print("visible\n")
			else
				print("blocked\n")
			end
		end
		if isBlockerFunction(checkedTile) then
			print("isForest\n")
			local lowerAngle, upperAngle = getBlockerCorners(pos,checkedTile)
			print("Corners: "..tostring(lowerAngle)..","..tostring(upperAngle))
			local lowerAngleNode =t:getNodeBefore(lowerAngle)
			local upperAngleNode =t:getNodeBefore(upperAngle)
			if lowerAngleNode ~= nil and upperAngleNode ~= nil then
				print("Lower Angle Before: angle = "..tostring(lowerAngleNode:getKey())..", isBlocking = "..tostring(lowerAngleNode:getData()))
				print("Upper Angle Before: angle = "..tostring(upperAngleNode:getKey())..", isBlocking = "..tostring(upperAngleNode:getData()))
			end

			if lowerAngleNode == nil or lowerAngleNode:getData()==false then
				t:insert(lowerAngle, true)
			end
			if upperAngleNode == nil or upperAngleNode:getData()==false then
				t:insert(upperAngle, false)
			end
			if (lowerAngleNode ~= nil and upperAngleNode ~= nil) then
				local currentNode = upperAngleNode
				local relativeUpperAngle = getRelativeAngle(lowerAngle,upperAngle)
				local relativeAngle = getRelativeAngle(lowerAngle, currentNode:getKey())
				local keysToBeRemoved = {}
				local keysToBeRemovedCount = 0
				--cull tree
				print("upperAngleNode angle: "..tostring(relativeUpperAngle))
				print("relative angle: ".. tostring(relativeAngle))
				while (relativeAngle>0 and relativeAngle<relativeUpperAngle) do
					table.insert(keysToBeRemoved,currentNode:getKey())
					keysToBeRemovedCount = keysToBeRemovedCount+1
					if keysToBeRemovedCount>=t:getSize() then
						--All angles are blocked
						break
					end
					currentNode = currentNode.prev
					relativeAngle = getRelativeAngle(lowerAngle, currentNode:getKey())
					print("relative angle: ".. tostring(relativeAngle))
				end
				if keysToBeRemovedCount>=t:getSize() then
					--All angles are blocked
					break
				end
				for i, key in ipairs(keysToBeRemoved) do
					t:remove(key)
				end
			end
		end
		print("tree")
		if (t._root ~= nil) then
			local curentNode = t:getNodeBefore(0);
			local prevAngle = 0;
			local originAngle = curentNode:getKey()
			print("Corner : angle = "..tostring(curentNode:getKey())..", isBlocking = "..tostring(curentNode:getData()))
			curentNode = curentNode.next
			local newAngle = getRelativeAngle(originAngle,curentNode:getKey())
			while (getRelativeAngle(originAngle,curentNode:getKey())>prevAngle) do
				newAngle = getRelativeAngle(originAngle,curentNode:getKey())
				print("Corner : angle = "..tostring(curentNode:getKey())..", isBlocking = "..tostring(curentNode:getData()))
				prevAngle = newAngle
				curentNode = curentNode.next
			end
		end
	end
	return visibleTiles
end

return PulseScanner
