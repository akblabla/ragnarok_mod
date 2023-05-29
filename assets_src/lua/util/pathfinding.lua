local BinaryHeap = require "util/binary_heap"
local Wargroove = require "wargroove/wargroove"
local Stats = require "util/stats"
local PosKey = require "util/posKey"
local VisionTracker = require "initialized/vision_tracker"
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
  return Pathfinding.newYorkDistance(cur, dest)
end
function Pathfinding.newYorkDistance(pos1, pos2)
  local newYorkDistance = math.abs(pos1.x-pos2.x)+math.abs(pos1.y-pos2.y)
  return newYorkDistance
end
function Pathfinding.withinBounds(pos)
  local mapSize = Wargroove.getMapSize()
  return (pos.x >= 0) and (pos.y >= 0) and (pos.x < mapSize.x) and (pos.y < mapSize.y)
end

function Pathfinding.tileCost(unitClassId,pos, playerId, ignoreUnits)
    local stranger = Wargroove.getUnitAt(pos)
    if ignoreUnits == nil then
      ignoreUnits = false
    end
    if not Pathfinding.withinBounds(pos) then
        return 1000
    end
    if (playerId ~= nil) and VisionTracker.canSeeTile(playerId,pos) and (stranger ~= nil) and Wargroove.areEnemies(playerId, stranger.playerId) and (not ignoreUnits) then
        return 100
    end
    local tileCost = Stats.getTerrainCost(Wargroove.getTerrainNameAt(pos),unitClassId)
    return tileCost
end

function Pathfinding.canStop(unitClassId,pos,playerId, ignoreUnits)
  local stranger = Wargroove.getUnitAt(pos)
  local mapSize = Wargroove.getMapSize()
  if ignoreUnits == nil then
    ignoreUnits = false
  end
  if (stranger ~= nil) and VisionTracker.canSeeTile(playerId,pos) and not ignoreUnits then
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
  local meanPos = {x=0,y=0}
  local count = 0
  
  for id,tile in pairs(path) do
    meanPos.x = meanPos.x + tile.x
    meanPos.y = meanPos.y + tile.y
    count = count + 1
  end
  if count>0 then
      meanPos.x = math.floor(0.5+meanPos.x/count);
      meanPos.y = math.floor(0.5+meanPos.y/count);
      Wargroove.trackCameraTo(meanPos)
  end
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

function Pathfinding.isBetter(gScore, tentative_gScore)
  if ((tentative_gScore.dist + tentative_gScore.bonus)<(gScore.dist+gScore.bonus)) then
    return true
  else
    return false
  end
end

function Pathfinding.AStar(unit, destList, penaltyFunctions)
  if penaltyFunctions == nil then
    penaltyFunctions = {}
  end
  if destList == nil then
    return {unit.pos}
  end
  if next(destList) == nil then
    return {unit.pos}
  end
  local openSet = BinaryHeap()
  local unitClass = Wargroove.getUnitClass(unit.unitClassId)
  if destList.x ~= nil then
    destList = {{x = destList.x, y = destList.y}}
  end
  local cameFrom = {}
  local gScore = {}
  local fScore = {}
  local bestFScorePos = {fScore = 100000,pos = nil}
  local startKey = PosKey.generatePosKey(unit.pos)
  fScore[startKey] = Pathfinding.guessList(unit.pos, destList)
  bestFScorePos = {fScore = fScore[startKey],pos = unit.pos}
  gScore[startKey] = {dist = 0,nWait = 0, bonus = 0}
  openSet:insert(fScore[startKey],startKey)
  local plzStop = 0
  while (openSet:empty() == false) do
    local currentScore,currentPosKey = openSet:pop()
    local currentPos = PosKey.revertPosKey(currentPosKey)
    for i,dest in ipairs(destList) do
      if (currentPos.x == dest.x) and (currentPos.y == dest.y) then
        return Pathfinding.reconstructPath(cameFrom, currentPos)
      end
    end
    for i,dir in ipairs(directions) do
      local newPos = {x = currentPos.x+dir.x,y = currentPos.y+dir.y}
      if Pathfinding.withinBounds(newPos) then
        local newPosKey = PosKey.generatePosKey(newPos)
        local ignoreUnits = true
        if gScore[currentPosKey].dist <= unitClass.moveRange then
          ignoreUnits = false
        end
        local turnMovePoints = unitClass.moveRange-(gScore[currentPosKey].dist%unitClass.moveRange)
        local tileCost = Pathfinding.tileCost(unit.unitClassId,newPos,unit.playerId,ignoreUnits)
        local moveCost = tileCost
        local canStand = Pathfinding.canStop(unit.unitClassId,newPos,unit.playerId, ignoreUnits)
        if canStand then
          turnMovePoints = turnMovePoints-gScore[currentPosKey].nWait
        end
        if tileCost>turnMovePoints then --unit have to wait til next turn :(
          moveCost = tileCost+(unitClass.moveRange-turnMovePoints)
        end 
        if tileCost>unitClass.moveRange then --unit can never cross this :(
          moveCost = 100
        end
        if gScore[newPosKey] == nil then
          gScore[newPosKey] = {dist = 100000,nWait = 100000, bonus = 100000}
        end
        local tentative_gScore = {}
        tentative_gScore.dist = gScore[currentPosKey].dist+moveCost
        tentative_gScore.bonus = gScore[currentPosKey].bonus
        tentative_gScore.nWait = gScore[currentPosKey].nWait
        if canStand then
          tentative_gScore.nWait = 0
        else
          tentative_gScore.nWait = gScore[currentPosKey].nWait+moveCost
        end
        if (tentative_gScore.dist%unitClass.moveRange) == 0 then
          if penaltyFunctions["posPenalty"]~=nil then
            tentative_gScore.bonus = tentative_gScore.bonus+penaltyFunctions["posPenalty"](unit,newPos)
          end
        end
        if penaltyFunctions["pathPenalty"]~=nil then
          tentative_gScore.bonus = tentative_gScore.bonus+penaltyFunctions["pathPenalty"](unit,newPos)
        end
        if Pathfinding.isBetter(gScore[newPosKey], tentative_gScore) then
          gScore[newPosKey].dist = tentative_gScore.dist
          gScore[newPosKey].bonus = tentative_gScore.bonus
          gScore[newPosKey].nWait = tentative_gScore.nWait
          fScore[newPosKey] = tentative_gScore.dist+tentative_gScore.bonus+Pathfinding.guessList(newPos, destList)
          cameFrom[newPosKey] = currentPos
          if bestFScorePos.fScore < fScore[newPosKey] then
            bestFScorePos = {fScore = fScore[newPosKey],pos = newPos}
          end
          openSet:insert(fScore[newPosKey],newPosKey)
        end
      end
    end

  end
  return Pathfinding.reconstructPath(cameFrom, bestFScorePos.pos)
end

function Pathfinding.getMoveTiles(unit)
  local openSet = BinaryHeap()
  local unitClass = Wargroove.getUnitClass(unit.unitClassId)
  local gScore = {}
  local availableTiles = {}
  local startKey = PosKey.generatePosKey(unit.pos)
  gScore[startKey] = {dist = 0,nWait = 0, bonus = 0}
  openSet:insert(gScore[startKey],startKey)
  while (openSet:empty() == false) do
    local currentScore,currentPosKey = openSet:pop()
    local currentPos = PosKey.revertPosKey(currentPosKey)
    for i,dir in ipairs(directions) do
      local newPos = {x = currentPos.x+dir.x,y = currentPos.y+dir.y}
      if Pathfinding.withinBounds(newPos) and (Pathfinding.newYorkDistance(unit.pos,newPos) <= unitClass.moveRange) then
        local newPosKey = PosKey.generatePosKey(newPos)
        local turnMovePoints = unitClass.moveRange-(gScore[currentPosKey].dist%unitClass.moveRange)
        local tileCost = Pathfinding.tileCost(unit.unitClassId,newPos,unit.playerId,false)
        local moveCost = tileCost
        local canStand = Pathfinding.canStop(unit.unitClassId,newPos,unit.playerId, false)
        if canStand then
          turnMovePoints = turnMovePoints-gScore[currentPosKey].nWait
        end
        if tileCost>turnMovePoints then --unit have to wait til next turn :(
          moveCost = tileCost+(unitClass.moveRange-turnMovePoints)
        end 
        if tileCost>unitClass.moveRange then --unit can never cross this :(
          moveCost = 100
        end
        if gScore[newPosKey] == nil then
          gScore[newPosKey] = {dist = 100000,nWait = 100000, bonus = 100000}
        end
        local tentative_gScore = {}
        tentative_gScore.dist = gScore[newPosKey].dist
        tentative_gScore.bonus = gScore[newPosKey].bonus
        tentative_gScore.nWait = gScore[newPosKey].nWait
        tentative_gScore.dist = gScore[currentPosKey].dist+moveCost
        if canStand then
          tentative_gScore.nWait = 0
        else
          tentative_gScore.nWait = gScore[currentPosKey].nWait+moveCost
        end
        if Pathfinding.isBetter(gScore[newPosKey], tentative_gScore) then
          gScore[newPosKey].dist = tentative_gScore.dist
          gScore[newPosKey].bonus = tentative_gScore.bonus
          gScore[newPosKey].nWait = tentative_gScore.nWait
          if gScore[newPosKey].dist<=unitClass.moveRange then
            availableTiles[newPosKey] = gScore[newPosKey].dist
            openSet:insert(gScore[newPosKey].dist+gScore[newPosKey].bonus,newPosKey)
          end
        end
      end
    end

  end
  return availableTiles
end

function Pathfinding.distanceToEnemyMap(pos, range, playerId)

  local openSet = BinaryHeap()
  local distMap = {}
  for i, unit in ipairs(Wargroove.getUnitsAtLocation()) do
    if Wargroove.areEnemies(unit.playerId,playerId) and VisionTracker.canSeeTile(playerId,unit.pos) then
      local startKey = PosKey.generatePosKey(unit.pos)
      distMap[startKey] = 0
      openSet:insert(distMap[startKey],startKey)
    end
  end
  while (openSet:empty() == false) do
    local currentScore,currentPosKey = openSet:pop()
    local currentPos = PosKey.revertPosKey(currentPosKey)
    for i,dir in ipairs(directions) do
      local newPos = {x = currentPos.x+dir.x,y = currentPos.y+dir.y}
      if Pathfinding.withinBounds(newPos) and (Pathfinding.newYorkDistance(pos,newPos) <= range) then
        local newPosKey = PosKey.generatePosKey(newPos)
        if distMap[newPosKey] == nil then
          distMap[newPosKey] = 1000
        end
        local tentative_gScore = distMap[currentPosKey]+1
        if distMap[newPosKey] > tentative_gScore then
          distMap[newPosKey] = tentative_gScore
          openSet:insert(distMap[newPosKey],newPosKey)
        end
      end
    end

  end
  return distMap
end

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
