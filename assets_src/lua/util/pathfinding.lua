local BinaryHeap = require "util/binary_heap"
local Wargroove = require "wargroove/wargroove"
local Stats = require "util/stats"
local PosKey = require "util/posKey"
local Pathfinding = {}

Pathfinding.__index = Pathfinding
local directions = {{x = 1,y = 0},{x = -1,y = 0},{x = 0,y = 1},{x = 0,y = -1}}

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

function Pathfinding.guessList(cur, destList)
  local shortest = 100000
  for i,dest in pairs(destList) do
    local dist = Pathfinding.guess(cur, dest)
    if dist<shortest then
      shortest = dist
    end
  end
  return shortest
end
function Pathfinding.guess(cur, dest)
  local newYorkDistance = math.abs(cur.x-dest.x)+math.abs(cur.y-dest.y)
  return newYorkDistance*1
end
function Pathfinding.withinBounds(pos)
  local mapSize = Wargroove.getMapSize()
  return (pos.x >= 0) and (pos.y >= 0) and (pos.x < mapSize.x) and (pos.y < mapSize.y)
end

function Pathfinding.tileCost(unitClassId,pos, playerId, ignoreUnits)
    local stranger = Wargroove.getUnitAt(pos)
    local mapSize = Wargroove.getMapSize()
    if ignoreUnits == nil then
      ignoreUnits = false
    end
    if not Pathfinding.withinBounds(pos) then
        return 1000
    end
    if (playerId ~= nil) and (stranger ~= nil) and Wargroove.areEnemies(playerId, stranger.playerId) and (not ignoreUnits) then
        return 100
    end
    local tileCost = Stats.getTerrainCost(Wargroove.getTerrainNameAt(pos),unitClassId)
    return tileCost
end


function Pathfinding.roadBoost(unitClassId,pos)
  local terrainName = Wargroove.getTerrainNameAt(pos)
  local movementType = Stats.getMovementType(unitClassId);
  if (movementType == "walking") or (movementType == "riding") or (movementType == "wheels") then
    if not (terrainName == "road" or terrainName == "bridge") then
        return Stats.getTerrainCost(Wargroove.getTerrainNameAt(pos),unitClassId)
    end
  end
  if (movementType == "amphibious") or (movementType == "sailing") then
    if not (terrainName == "sea" or terrainName == "river" or terrainName == "ocean") then
      return Stats.getTerrainCost(Wargroove.getTerrainNameAt(pos),unitClassId)
    end
  end
  return 0
end

function Pathfinding.canStop(unitClassId,pos,ignoreUnits)
  local stranger = Wargroove.getUnitAt(pos)
  local mapSize = Wargroove.getMapSize()
  if ignoreUnits == nil then
    ignoreUnits = false
  end
  if (stranger ~= nil) and not ignoreUnits then
    return false
  end
  return Stats.canStopOnTerrain(Wargroove.getTerrainNameAt(pos),unitClassId)
end

function Pathfinding.reconstructPath(cameFrom, dest)
  local pathLength = 0
  local path = {}
  local currentPos = dest
  if cameFrom == nil then
    return path
  end
  if dest == nil then
    return path
  end

  local currentPosKey = PosKey.generatePosKey(currentPos)
  while cameFrom[currentPosKey] ~= nil do
    currentPos = cameFrom[currentPosKey]
    currentPosKey = PosKey.generatePosKey(currentPos)
    pathLength = pathLength + 1
--    path[pathLength] = currentPos
  end
  currentPos = dest
  currentPosKey = PosKey.generatePosKey(currentPos)
  while cameFrom[currentPosKey] ~= nil do
    path[pathLength] = currentPos
    pathLength = pathLength - 1
    currentPos = cameFrom[currentPosKey]
    currentPosKey = PosKey.generatePosKey(currentPos)
  end
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

function Pathfinding.isBetter(gScore, tentative_gScore, uScore, tentative_uScore, dScore, tentative_dScore)
  if (tentative_gScore + tentative_dScore<gScore+dScore) then
    return true
  else
    return tentative_uScore<uScore
  end
end

function Pathfinding.AStar(playerId, unitClassId, start, destList, roadBoost)
  print("Astar")
  if destList == nil then
    return {start}
  end
  if next(destList) == nil then
    return {start}
  end
  print("start")
  print(dump(start,0))
  print("destList")
  print(dump(destList,0))
  local openSet = BinaryHeap()
  local unitClass = Wargroove.getUnitClass(unitClassId)
  if destList.x ~= nil then
    destList = {{x = destList.x, y = destList.y}}
  end
  local cameFrom = {}
  local gScore = {}
  local uScore = {}
  local dScore = {}
  local fScore = {}
  local bestFScorePos = {fScore = 100000,pos = nil}
  local startKey = PosKey.generatePosKey(start)
  fScore[startKey] = Pathfinding.guessList(start, destList)
  bestFScorePos = {fScore = fScore[startKey],pos = start}
  gScore[startKey] = 0
  uScore[startKey] = 0
  dScore[startKey] = 0
  openSet:insert(fScore[startKey],startKey)
  local i = 0
  while openSet:empty() == false do
    print("1")
    local currentPosKey
    _,currentPosKey = openSet:pop()
    local currentPos = PosKey.revertPosKey(currentPosKey)
    for i,dest in ipairs(destList) do
      if currentPos.x == dest.x and currentPos.y == dest.y then
        return Pathfinding.reconstructPath(cameFrom, currentPos)
      end
    end
    for i,dir in ipairs(directions) do
      print("2")
      local newPos = {x = currentPos.x+dir.x,y = currentPos.y+dir.y}
      local newPosKey = PosKey.generatePosKey(newPos)
      local ignoreUnits = true
      if Pathfinding.guessList(newPos, destList) <= unitClass.moveRange then
        ignoreUnits = false
      end
      print("3")
      local turnMovePoints = unitClass.moveRange-(gScore[currentPosKey]%unitClass.moveRange)
      local tileCost = Pathfinding.tileCost(unitClassId,newPos,playerId,ignoreUnits)
      local moveCost = tileCost
      local canStand = Pathfinding.canStop(unitClassId,newPos, ignoreUnits)
      if canStand then
        turnMovePoints = turnMovePoints-uScore[currentPosKey]
      end
      print("4")
      if tileCost>turnMovePoints then --unit have to wait til next turn :(
        moveCost = tileCost+(unitClass.moveRange-turnMovePoints)
      end 
      if tileCost>unitClass.moveRange then --unit can never cross this :(
        moveCost = 100
      end
      if gScore[newPosKey] == nil then
        gScore[newPosKey] = 10000
      end
      if uScore[newPosKey] == nil then
        uScore[newPosKey] = 10000
      end
      if dScore[newPosKey] == nil then
        dScore[newPosKey] = 10000
      end
      print("5")
      local tentative_uScore = 0
      local tentative_gScore = gScore[currentPosKey]
      local tentative_dScore = dScore[currentPosKey]
      if canStand then
        tentative_gScore = gScore[currentPosKey]+moveCost
      else
        tentative_uScore = uScore[currentPosKey]+moveCost
      end
      if tentative_gScore%unitClass.moveRange == 0 then
--        tentative_dScore = dScore[currentPosKey]+4-Wargroove.getTerrainDefenceAt(newPos)
      end
      if roadBoost then
        tentative_dScore = tentative_dScore+Pathfinding.roadBoost(unitClassId,newPos)
      end
      print("6")
      if Pathfinding.isBetter(gScore[newPosKey], tentative_gScore, uScore[newPosKey], tentative_uScore, dScore[newPosKey], tentative_dScore) then
        dScore[newPosKey] = tentative_dScore
        if canStand then
          gScore[newPosKey] = tentative_gScore
          uScore[newPosKey] = 0
          fScore[newPosKey] = tentative_gScore+Pathfinding.guessList(newPos, destList)
        else
          gScore[newPosKey] = gScore[currentPosKey]
          uScore[newPosKey] = tentative_uScore
          fScore[newPosKey] = gScore[currentPosKey]+tentative_uScore*(1+0.0000001)+Pathfinding.guessList(newPos, destList)
        end
        print("7")
        fScore[newPosKey] = fScore[newPosKey]+tentative_dScore
        cameFrom[newPosKey] = currentPos
        if bestFScorePos.fScore < fScore[newPosKey] then
          bestFScorePos = {fScore = fScore[newPosKey],pos = newPos}
        end
        openSet:insert(fScore[newPosKey],newPosKey)
      end
    end
    print("Incrementing an I")
    i = i+1
    if i>1000 then
      break
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
  local startKey = PosKey.generatePosKey(start)
  local gScore = {}
  gScore[startKey] = 0

  openSet:insert(0,startKey)
  while openSet:empty() == false do
    local currentPosKey
    _,currentPosKey = openSet:pop()
    local currentPos = PosKey.revertPosKey(currentPosKey)
    if Wargroove.getUnitAt(currentPos) == nil then
      return currentPos
    end
    for i,dir in ipairs(directions) do
      local newPos = {x = currentPos.x+dir.x,y = currentPos.y+dir.y}
      local newPosKey = PosKey.generatePosKey(newPos)
      local tentative_gScore = gScore[currentPosKey] + Pathfinding.tileCost(unitClassId,newPos,nil, false)
      if gScore[newPosKey] == nil and Pathfinding.withinBounds(newPos) then
        gScore[newPosKey] = tentative_gScore
        openSet:insert(gScore[newPosKey],newPosKey)
      end
    end

  end
  return nil
end

return Pathfinding
