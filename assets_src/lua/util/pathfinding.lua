local BinaryHeap = require "util/binary_heap"

local Pathfinding = {}

Pathfinding.__index = Pathfinding
local function generatePosKey(pos)
	return pos.x*1000+pos.y --Should work as long as people don't make maps taller than 1000 tiles.
end
local function revertPosKey(posKey)
	return {x = math.floor(posKey/1000), y = posKey%1000} --Should work as long as people don't make maps taller than 1000 tiles.
end
local directions = {{x = 1,y = 0},{x = -1,y = 0},{x = 0,y = 1},{x = 0,y = -1}}

function Pathfinding.guess(cur, dest)
  return math.abs(cur.x-dest.x)+math.abs(cur.y-dest.y)
end

function Pathfinding.reconstructPath(cameFrom, dest)
  local pathLength = 0
  local path = {}
  local currentPos = dest
  local currentPosKey = generatePosKey(currentPos)
  while cameFrom[currentPosKey] ~= nil do
    currentPos = cameFrom[currentPosKey]
    currentPosKey = generatePosKey(currentPos)
    pathLength = pathLength + 1
  end
  currentPos = dest
  currentPosKey = generatePosKey(currentPos)
  while cameFrom[currentPosKey] ~= nil do
    path[pathLength] = currentPos
    pathLength = pathLength - 1
    currentPos = cameFrom[currentPosKey]
    currentPosKey = generatePosKey(currentPos)
  end
  return path
end

function Pathfinding.AStar(start, dest, edgeFunc, data)
  local openSet = BinaryHeap()
  local cameFrom = {}
  local startKey = generatePosKey(start)
  local destKey = generatePosKey(dest)
  local gScore = {}
  gScore[startKey] = 0

  local fScore = {}
  fScore[startKey] = Pathfinding.guess(start, dest)
  local bestFScorePos = {fScore = fScore[startKey],pos = start}
  openSet:insert(fScore[startKey],startKey)
  while openSet:empty() == false do
    local currentPosKey
    _,currentPosKey = openSet:pop()
    local currentPos = revertPosKey(currentPosKey)
    if currentPos.x == dest.x and currentPos.y == dest.y then
      return Pathfinding.reconstructPath(cameFrom, currentPos)
    end
    for i,dir in ipairs(directions) do
      local newPos = {x = currentPos.x+dir.x,y = currentPos.y+dir.y}
      local newPosKey = generatePosKey(newPos)
      local tentative_gScore = gScore[currentPosKey] + edgeFunc(newPos, data)
      if gScore[newPosKey] == nil or tentative_gScore<gScore[newPosKey] then
        cameFrom[newPosKey] = currentPos
        gScore[newPosKey] = tentative_gScore
        fScore[newPosKey] = tentative_gScore+Pathfinding.guess(newPos, dest)
        if bestFScorePos.fScore < fScore[newPosKey] then
          bestFScorePos = {fScore = fScore[newPosKey],pos = newPos}
        end
        openSet:insert(fScore[newPosKey],newPosKey)
      end
    end

  end
  return Pathfinding.reconstructPath(cameFrom, bestFScorePos.pos)
end


return Pathfinding
