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

local function withinMapBounds(pos,mapsize)
	return pos.x>=0 and pos.x<mapsize.x and pos.y>=0 and pos.y<mapsize.y
end

local function getKnownOcclusionTileOrder(pos, range, mapsize)
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
	pos.x = math.floor(pos.x+0.5)
	pos.y = math.floor(pos.y+0.5)
	range = math.min(range,mapsize.x+mapsize.y)
	while layer<=range do
		for orientationId = 1, 4 do
			for i = 0,currentLayerSize*2-2 do
				local offset = {x = layer, y = math.ceil(i/2.0)*(2*(i%2)-1)}
				if math.abs(offset.x)+math.abs(offset.y) > range then
					break
				end
				local rotatedOffset = {x = VectorMath.dotProduct(offset,currentOrientationMatrixTable[orientationId][1]),
					y = VectorMath.dotProduct(offset,currentOrientationMatrixTable[orientationId][2])}
				local offsetPos = VectorMath.add(pos,rotatedOffset)
				
				if withinMapBounds(offsetPos,mapsize) then
					table.insert(result,offsetPos)
				end

			end
			if orientationId == 2 then
				currentLayerSize = currentLayerSize+1
			end
		end
		layer = layer+1
	end
	return result
end
local function asinApprox(x)
	return x+x^3*1/6
end

local function getBlockerCorners(origin,blockerPos)
	local dist = VectorMath.dist(origin,blockerPos)
	local radius = blockerRadiusFunction(origin, blockerPos)
	local diff = VectorMath.diff(origin,blockerPos)
	local baseAngle = math.atan(diff.y,diff.x)
	local deltaAngle = asinApprox(radius/dist)
	local lowerAngle = (baseAngle-deltaAngle)%(2*math.pi)
	local upperAngle = (baseAngle+deltaAngle)%(2*math.pi)
	return lowerAngle, upperAngle
end

local function getRelativeAngle(originAngle, angle)
	return (angle-originAngle)%(2*math.pi)
end

function PulseScanner.calculateLoSOfUnitPulse(pos, scout, canSeeOver, sightRange, targetOffset, mapsize)
	print("PulseScanner.calculateLoSOfUnitPulse starts here")
	print("Pos: "..tostring(pos.x)..","..tostring(pos.y))
	print("scout: "..tostring(scout))
	print("canSeeOver: "..tostring(canSeeOver))
	print("sightRange: "..tostring(sightRange))
	if Tree == nil then
        Tree = require "util/binarySearchTreeDoubleLinked"
    end
	local visibleTiles = {}
	if withinMapBounds(pos,mapsize) then
		table.insert(visibleTiles,{x = math.floor(pos.x+0.5), y = math.floor(pos.y+0.5)})
	end
	print("Attempting to get order")
	local orderedTiles = getKnownOcclusionTileOrder(pos, sightRange, mapsize)
	print("Got Order")
	local t = Tree:new()
	for i, checkedTile in ipairs(orderedTiles) do
		-- print("")
		-- print("------------------------------")
		-- print("Checked Tile: "..tostring(checkedTile.x)..","..tostring(checkedTile.y))
		local dist = VectorMath.dist(pos,checkedTile)
		if(not isBlockerFunction(checkedTile)) or dist<=1 then
			local diff = VectorMath.diff(pos,VectorMath.add(checkedTile,targetOffset))
			local angle = math.atan(diff.y,diff.x)%(2*math.pi)

			local angleNode = t:getNodeBefore(angle)
			if angleNode == nil or (angleNode ~= nil and angleNode:getData() == false) then
				table.insert(visibleTiles, checkedTile)
				-- print("visible\n")
			else
				-- print("blocked\n")
			end
		end
		if isBlockerFunction(checkedTile) then
			-- print("isForest\n")
			local lowerAngle, upperAngle = getBlockerCorners(pos,VectorMath.add(checkedTile,targetOffset))
			-- print("Corners: "..tostring(lowerAngle)..","..tostring(upperAngle))
			local lowerAngleNode =t:getNodeBefore(lowerAngle)
			local upperAngleNode =t:getNodeBefore(upperAngle)
			if lowerAngleNode ~= nil and upperAngleNode ~= nil then
				-- print("Lower Angle Before: angle = "..tostring(lowerAngleNode:getKey())..", isBlocking = "..tostring(lowerAngleNode:getData()))
				-- print("Upper Angle Before: angle = "..tostring(upperAngleNode:getKey())..", isBlocking = "..tostring(upperAngleNode:getData()))
			end

			if lowerAngleNode == nil or lowerAngleNode:getData()==false then
				-- print("Inserting Corner : angle = "..tostring(lowerAngle)..", isBlocking = true")
				t:insert(lowerAngle, true)
			end
			if upperAngleNode == nil or upperAngleNode:getData()==false then
				-- print("Inserting Corner : angle = "..tostring(upperAngle)..", isBlocking = false")
				t:insert(upperAngle, false)
			end
			if (lowerAngleNode ~= nil and upperAngleNode ~= nil) then
				local currentNode = upperAngleNode
				local relativeUpperAngle = getRelativeAngle(lowerAngle,upperAngle)
				local relativeAngle = getRelativeAngle(lowerAngle, currentNode:getKey())
				local keysToBeRemoved = {}
				local keysToBeRemovedCount = 0
				--cull tree
				-- print("upperAngleNode angle: "..tostring(relativeUpperAngle))
				while (relativeAngle>0.000001 and relativeAngle<relativeUpperAngle-0.000001) do
					-- print("relative angle: ".. tostring(relativeAngle))
					table.insert(keysToBeRemoved,currentNode:getKey())
					-- print("removing corner with angle: ".. tostring(currentNode:getKey()))
					keysToBeRemovedCount = keysToBeRemovedCount+1
					if keysToBeRemovedCount>=t:getSize() then
						--All angles are blocked
						break
					end
					currentNode = currentNode.prev
					-- print("next corner with angle: ".. tostring(currentNode:getKey()))
					relativeAngle = getRelativeAngle(lowerAngle, currentNode:getKey())
				end
				if keysToBeRemovedCount>=t:getSize() then
					--All angles are blocked
					break
				end
				local function printTree(node, level)
					if node~=nil then
						print("Corner at layer "..tostring(level).." : angle = "..tostring(node:getKey())..", isBlocking = "..tostring(node:getData()))
						if node.left~=nil then
							print("left")
							printTree(node.left,level+1)
						end
						if node.right~=nil then
							print("right")
							printTree(node.right,level+1)
						end
					end
				end
				-- print("Tree before removal")
				-- printTree(t._root, 0)
				-- print("Removing nodes")
				for i, key in ipairs(keysToBeRemoved) do
					t:remove(key)
				end
				-- print("Tree after removal")
				-- printTree(t._root, 0)
			end
		end
		-- print("tree")
		-- if (t._root ~= nil) then
			-- local curentNode = t:getNodeBefore(0);
			-- local prevAngle = 0;
			-- local originAngle = curentNode:getKey()
			-- -- print("Corner : angle = "..tostring(curentNode:getKey())..", isBlocking = "..tostring(curentNode:getData()))
			-- curentNode = curentNode.next
			-- local newAngle = getRelativeAngle(originAngle,curentNode:getKey())
			-- while (getRelativeAngle(originAngle,curentNode:getKey())>prevAngle) do
				-- newAngle = getRelativeAngle(originAngle,curentNode:getKey())
				-- -- print("Corner : angle = "..tostring(curentNode:getKey())..", isBlocking = "..tostring(curentNode:getData()))
				-- prevAngle = newAngle
				-- curentNode = curentNode.next
			-- end
		-- end
		-- print("------------------------------")
	end
	return visibleTiles
end

return PulseScanner
