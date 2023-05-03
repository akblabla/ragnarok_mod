local Wargroove = require "wargroove/wargroove"
local Ragnarok = require "initialized/ragnarok"
local Stats = require "util/stats"
local Pathfinding = require "util/pathfinding"
local VisionTracker = require "initialized/vision_tracker"

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

local AIManager = {}
local AITargets = {}

function AIManager.init()
	Ragnarok.addAction(AIManager.update,"repeating",true)
end

function AIManager.setup(context)
end

function AIManager.update(context)
end

function AIManager.getNextPosition(unitId)
   if AITargets[unitId] == nil then
      return nil
   end
   local unit = Wargroove.getUnitById(unitId)
   if AITargets[unitId].order == "road_move" then
      local next, distMoved, dist = AIManager.getNextPositionTowardsTarget(unitId, AITargets[unitId].location,true)
	   return next, distMoved, dist
   end
   if AITargets[unitId].order == "move" then
      print("AITargets[unitId].order == move")
      print(dump(AITargets[unitId].location,0));
      local next, distMoved, dist = AIManager.getNextPositionTowardsTarget(unitId, AITargets[unitId].location,false)
      print(dump(next,0));
      print(dump(distMoved,0));
      print(dump(dist,0));
	   return next, distMoved, dist
   end
   if AITargets[unitId].order == "attack_move" then
      local tileList = Wargroove.getTargetsInRange(unit.pos, VisionTracker.getSightRange(unit), "all")
      local canSeeEnemy = false
      for i,tile in pairs(tileList) do
         if VisionTracker.canSeeTile(unit.playerId,tile) then
            local target = Wargroove.getUnitAt(tile)
            if target~=nil and Wargroove.areEnemies(unit.playerId, target.playerId) then
               canSeeEnemy = true
               break
            end
         end
      end
      if canSeeEnemy then
         return nil, false
      else
         local next,distMoved, dist = AIManager.getNextPositionTowardsTarget(unitId, AITargets[unitId].location,false)
         return next, distMoved, dist
      end
   end
   return nil, 0,0
end

function AIManager.getNextPositionTowardsTarget(unitId, location, roadBoost)
   local unit = Wargroove.getUnitById(unitId)
   local path = Pathfinding.AStar(unit.playerId, unit.unitClassId, unit.pos, location, roadBoost)
   if (unit.unitClassId == "travelboat") then
      print("AIManager.getNextPositionTowardsTarget(unitId, location, roadBoost)")
      print("unit")
      print(dump(unit,0))
      print("path")
      print(dump(path,0))
   end
   --path[1] = nil
   local movePoints = unit.unitClass.moveRange
   local target = unit.pos
   local reachedEnd = false
   for i,tile in pairs(path) do
      local tileCost, cantStop = Stats.getTerrainCost(Wargroove.getTerrainNameAt(tile),unit.unitClassId)
      if (unit.unitClassId == "travelboat") then
         print("tileCost")
         print(tileCost)
         print("cantStop")
         print(cantStop)
         print("target")
         print(dump(target,0))
      end
      movePoints = movePoints-tileCost
      if i == #path then
         reachedEnd = true
      end
      if tileCost > unit.unitClass.moveRange then
         reachedEnd = true
      end
      if movePoints<0 then
         break
      end
      if (Wargroove.isAnybodyElseAt(unit,tile) == false) and not cantStop then
         target = tile
      end
   end
   local dist = 0
   for i,tile in pairs(path) do
      local tileCost, cantStop = Stats.getTerrainCost(Wargroove.getTerrainNameAt(tile),unit.unitClassId)
      if tileCost<100 then
         dist = dist+tileCost
         if i == #path then
            break
         end
         if tileCost > unit.unitClass.moveRange then
            break
         end
      else
         break
      end
   end
   local distMoved = unit.unitClass.moveRange-movePoints
	return target, distMoved, dist
end

function AIManager.getAITarget(unitId)
	return AITargets[unitId]
end

function AIManager.attackMoveOrder(unitId, location)
   if location == nil then
      return
   end
   if location.x ~= nil then
      location = {location}
   end
	AITargets[unitId] = {order = "attack_move", location = location}
end

function AIManager.moveOrder(unitId, location)
   if location == nil then
      return
   end
   if location.x ~= nil then
      location = {location}
   end
   AITargets[unitId] = {order = "move", location = location}
end

function AIManager.roadMoveOrder(unitId, location)
   if location == nil then
      return
   end
   if location.x ~= nil then
      location = {location}
   end
   AITargets[unitId] = {order = "road_move", location = location}
end

function AIManager.clearOrder(unitId)
	AITargets[unitId] = nil
end

return AIManager
