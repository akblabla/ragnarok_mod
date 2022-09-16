local function getOpposingCorner(n)
	return math.mod(n+1,4)+1
end

local function getNextCornerCW(n)
	return math.mod(n,4)+1
end

local function getNextCornerCCW(n)
	return math.mod(n+2,4)+1
end

local cornerTypes = {[1] = "R", [2] = "S", [3] = "P", [4] = "C"}

local combinations = {}
local i = 1
for centerCorner = 1,4 do
	for indexCW = 1,3 do
		for indexCCW = 1,3 do
			for opposingCornerIndex = 1,3 do
				if not ((indexCW == 3 or indexCCW == 3) and opposingCornerIndex == 3) then
					local newCombination = {[1] = "C", [2] = "C", [3] = "C", [4] = "C"}
					local currentCorner = centerCorner
					print("Center: "..tostring(currentCorner))
					currentCorner = getNextCornerCW(currentCorner)
					print("CW: "..tostring(currentCorner))
					newCombination[currentCorner] = cornerTypes[indexCW]
					currentCorner = getNextCornerCW(currentCorner)
					print("Opposing: "..tostring(currentCorner))
					newCombination[currentCorner] = cornerTypes[opposingCornerIndex]
					currentCorner = getNextCornerCW(currentCorner)
					print("CCW: "..tostring(currentCorner))
					newCombination[currentCorner] = cornerTypes[indexCCW]

					table.insert(combinations, newCombination)
					print(tostring(newCombination[1])..", "..tostring(newCombination[2]).."\n")
					print(tostring(newCombination[3])..", "..tostring(newCombination[4]).."\n")
					i = i +1
				end
			end
		end
	end
end

-- Opens a file in append mode
file = io.open("cornerCombinations.txt", "w+")

-- sets the default output file as test.lua
io.output(file)

for i, combination in ipairs(combinations) do
	io.write(tostring(combination[1])..", "..tostring(combination[2]).."\n")
	io.write(tostring(combination[3])..", "..tostring(combination[4]).."\n")
	io.write("\n")
end
-- appends a word test to the last line of the file

-- closes the open file
io.close(file)

return 1
