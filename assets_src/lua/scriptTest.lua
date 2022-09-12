local Tree = require "util/binarySearchTreeDoubleLinked"
local VectorMath = require "util/vectorMath"

local t = Tree:new()

print(math.atan2(0,1))
print(math.atan2(1,1))
print(math.atan2(1,0))
print(math.atan2(1,-1))
print(math.atan2(0,-1))
print(math.atan2(-1,-1))
print(math.atan2(-1,0))
print(math.atan2(-1,1))
print(" ")

t:insert(2, "bob")
t:insert(5, "fisk")
t:insert(1, "thomas")
t:insert(3, "hval")
t:insert(4, "blaeksprutte")

local currentNode;

currentNode = t:getNodeBefore(2.2)
print(currentNode:getKey())
print(currentNode:getData())
print("")

currentNode = t:getNodeBefore(1.1)
print(currentNode:getKey())
print(currentNode:getData())
print("")

currentNode = t:getNodeBefore(3.5)
print(currentNode:getKey())
print(currentNode:getData())
print("")

currentNode = t:getNodeBefore(4.2)
print(currentNode:getKey())
print(currentNode:getData())
print("")

currentNode = t:getNodeBefore(1.1)
print(currentNode:getKey())
print(currentNode:getData())
print("")



local PulseScanner = require "util/pulseScanner"
local function isBlocker(pos)
	if pos.x == 8 and pos.y == 11 then
		return true
	end
	if pos.x == 9 and pos.y == 11 then
		return true
	end
	if pos.x == 10 and pos.y == 11 then
		return true
	end
	if pos.x == 12 and pos.y == 11 then
		return true
	end

	if pos.x == 12 and pos.y == 7 then
		return true
	end

	if pos.x == 15 and pos.y == 8 then
		return true
	end

	if pos.x == 5 and pos.y == 8 then
		return true
	end
	if pos.x == 6 and pos.y == 7 then
		return true
	end
	return false
end

local function getBlockerRadius(origin, pos)
	local dist = VectorMath.dist(origin, pos)
	return 0.5+dist/200
end

PulseScanner.setBlockerFunction(isBlocker)
PulseScanner.setBlockerRadiusFunction(getBlockerRadius)
local visibleTiles = {}
visibleTiles = PulseScanner.calculateLoSOfUnitPulse({x = 10, y = 10}, false, false, 10)

-- Opens a file in append mode
file = io.open("visibleTiles.txt", "w+")

-- sets the default output file as test.lua
io.output(file)

for i, tile in ipairs(visibleTiles) do
	print("VisibleTile at: "..tostring(tile.x)..","..tostring(tile.y))
	io.write(tostring(tile.x)..","..tostring(tile.y).."\n")
end
-- appends a word test to the last line of the file

-- closes the open file
io.close(file)


return 1
