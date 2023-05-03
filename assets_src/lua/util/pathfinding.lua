local BinaryHeap = require "util/binary_heap"
local Wargroove = require "wargroove/wargroove"
local Pathfinding = {}

Pathfinding.__index = Pathfinding
local function generatePosKey(pos)
	return pos.x*1000+pos.y --Should work as long as people don't make maps taller than 1000 tiles.
end
local function revertPosKey(posKey)
	return {x = math.floor(posKey/1000), y = math.floor(posKey%1000)} --Should work as long as people don't make maps taller than 1000 tiles.
end
local directions = {{x = 1,y = 0},{x = -1,y = 0},{x = 0,y = 1},{x = 0,y = -1}}

function Pathfinding.guess(cur, dest)
  local newYorkDistance = math.abs(cur.x-dest.x)+math.abs(cur.y-dest.y)
  return newYorkDistance*1
end


function Pathfinding.tileCost(unitClassId,pos, playerId, roadBoost)
    local stranger = Wargroove.getUnitAt(pos)
    local Stats = require "util/stats"
    local Wargroove = require "wargroove/wargroove"
    local mapSize = Wargroove.getMapSize()
    if not (pos.x >= 0 and pos.y >= 0 and pos.x < mapSize.x and pos.y < mapSize.y) then
        return 1000
    end
    if playerId ~= nil and stranger ~= nil and Wargroove.areEnemies(playerId, stranger.playerId) then
        return 100
    end
    local tileCost, cantStop = Stats.getTerrainCost(Wargroove.getTerrainNameAt(pos),unitClassId)
    local terrainName = Wargroove.getTerrainNameAt(pos)
    if roadBoost and not (terrainName == "road" or terrainName == "bridge") then
        tileCost = tileCost+1
    end
    return tileCost
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
    path[pathLength] = currentPos
  end
  -- currentPos = dest
  -- currentPosKey = generatePosKey(currentPos)
  -- while cameFrom[currentPosKey] ~= nil do
  --   path[pathLength] = currentPos
  --   pathLength = pathLength - 1
  --   currentPos = cameFrom[currentPosKey]
  --   currentPosKey = generatePosKey(currentPos)
  -- end
  return path
end

function Pathfinding.forceMoveAlongPath(unitId, path, facing)
  local unit = Wargroove.getUnitById(unitId)
  local lastTile = unit.pos
  for i,tile in ipairs(path) do
    local delta = {x = tile.x-lastTile.x, y = tile.y-lastTile.y}
    if delta.y == 1 then
      Wargroove.playUnitAnimation(unitId,"run_down")
    elseif delta.y == -1 then
      Wargroove.playUnitAnimation(unitId,"run_up")
    else
      Wargroove.playUnitAnimation(unitId,"run")
    end
    if delta.x == 1 then
      Wargroove.setFacingOverride(unitId,"right")
    elseif delta.x == -1 then
      Wargroove.setFacingOverride(unitId,"left")
    end
    Wargroove.moveUnitToOverride(unitId, unit.pos, tile.x-unit.pos.x, tile.y-unit.pos.y, 2)
    while Wargroove.isLuaMoving(unitId) do
      coroutine.yield()
    end
    lastTile = tile
  end
  unit.pos = { x = path[#path].x, y = path[#path].y }
  Wargroove.unsetFacingOverride(unitId)
  Wargroove.updateUnit(unit)
--  Wargroove.playUnitAnimation(unitId,"hit")
end

function Pathfinding.AStar(playerId, unitClassId, start, destList, roadBoost)
  local openSet = BinaryHeap()
  if destList == nil then
    return {start}
  end
  if destList.x ~= nil then
    destList = {{x = destList.x, y = destList.y}}
  end
  local cameFrom = {}
  local gScore = {}
  for i,dest in pairs(destList) do
    gScore[generatePosKey(dest)] = 0
  end

  local fScore = {}
  local bestFScorePos = {fScore = 100000,pos = nil}
  for i,dest in pairs(destList) do
    local destKey = generatePosKey(dest)
    fScore[destKey] = Pathfinding.guess(start, dest)
    openSet:insert(fScore[destKey],destKey)
    if bestFScorePos.fScore < fScore[destKey] then
      bestFScorePos = {fScore = fScore[destKey],pos = start}
    end
  end
  while openSet:empty() == false do
    local currentPosKey
    _,currentPosKey = openSet:pop()
    local currentPos = revertPosKey(currentPosKey)
    if currentPos.x == start.x and currentPos.y == start.y then
      return Pathfinding.reconstructPath(cameFrom, currentPos)
    end
    for i,dir in ipairs(directions) do
      local newPos = {x = currentPos.x+dir.x,y = currentPos.y+dir.y}
      local newPosKey = generatePosKey(newPos)
      local tentative_gScore = gScore[currentPosKey] + Pathfinding.tileCost(unitClassId,currentPos,playerId, roadBoost)
      if gScore[newPosKey] == nil or tentative_gScore<gScore[newPosKey] then
        cameFrom[newPosKey] = currentPos
        gScore[newPosKey] = tentative_gScore
        fScore[newPosKey] = tentative_gScore+Pathfinding.guess(newPos, start)
        if bestFScorePos.fScore < fScore[newPosKey] then
          bestFScorePos = {fScore = fScore[newPosKey],pos = newPos}
        end
        openSet:insert(fScore[newPosKey],newPosKey)
      end
    end

  end
  return Pathfinding.reconstructPath(cameFrom, bestFScorePos.pos)
end

-- function Pathfinding.AStar2(playerId, unitClassId, start, dest, roadBoost)
--   local openSet = BinaryHeap()
--   local cameFrom = {}
--   local startKey = generatePosKey(start)
--   local destKey = generatePosKey(dest)
--   local gScore = {}
--   gScore[startKey] = 0

--   local fScore = {}
--   fScore[startKey] = Pathfinding.guess(start, dest)
--   local bestFScorePos = {fScore = fScore[startKey],pos = start}
--   openSet:insert(fScore[startKey],startKey)
--   while openSet:empty() == false do
--     local currentPosKey
--     _,currentPosKey = openSet:pop()
--     local currentPos = revertPosKey(currentPosKey)
--     if currentPos.x == dest.x and currentPos.y == dest.y then
--       return Pathfinding.reconstructPath(cameFrom, currentPos)
--     end
--     for i,dir in ipairs(directions) do
--       local newPos = {x = currentPos.x+dir.x,y = currentPos.y+dir.y}
--       local newPosKey = generatePosKey(newPos)
--       local tentative_gScore = gScore[currentPosKey] + Pathfinding.tileCost(unitClassId,newPos,playerId, roadBoost)
--       if gScore[newPosKey] == nil or tentative_gScore<gScore[newPosKey] then
--         cameFrom[newPosKey] = currentPos
--         gScore[newPosKey] = tentative_gScore
--         fScore[newPosKey] = tentative_gScore+Pathfinding.guess(newPos, dest)
--         if bestFScorePos.fScore < fScore[newPosKey] then
--           bestFScorePos = {fScore = fScore[newPosKey],pos = newPos}
--         end
--         openSet:insert(fScore[newPosKey],newPosKey)
--       end
--     end

--   end
--   return Pathfinding.reconstructPath(cameFrom, bestFScorePos.pos)
-- end

function Pathfinding.findClosestOpenSpot(unitClassId, start)
  local openSet = BinaryHeap()
  local startKey = generatePosKey(start)
  local gScore = {}
  gScore[startKey] = 0

  openSet:insert(0,startKey)
  while openSet:empty() == false do
    local currentPosKey
    _,currentPosKey = openSet:pop()
    local currentPos = revertPosKey(currentPosKey)
    if Wargroove.getUnitAt(currentPos) == nil then
      return currentPos
    end
    for i,dir in ipairs(directions) do
      local newPos = {x = currentPos.x+dir.x,y = currentPos.y+dir.y}
      local newPosKey = generatePosKey(newPos)
      local tentative_gScore = gScore[currentPosKey] + Pathfinding.tileCost(unitClassId,newPos,nil, false)
      if gScore[newPosKey] == nil and newPos.x>=0 and newPos.y>=0 and newPos.x<Wargroove.getMapSize().x and newPos.y<Wargroove.getMapSize().y then
        gScore[newPosKey] = tentative_gScore
        openSet:insert(gScore[newPosKey],newPosKey)
      end
    end

  end
  return nil
end

return Pathfinding
