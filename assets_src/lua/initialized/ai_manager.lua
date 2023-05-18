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

function AIManager.init()
	Ragnarok.addAction(AIManager.update,"repeating",true)
end

function AIManager.setup(context)
end

function AIManager.update(context)
end

function AIManager.getNextPosition(unitId)
   local unit = Wargroove.getUnitById(unitId)
<<<<<<< HEAD
   if unit == nil then
      return nil
   end
   local order = Wargroove.getUnitState(unit, "order")
   if order == nil then
      return nil
   end
   if order.location == nil then
      return nil
   end
   if not Pathfinding.withinBounds(unit.pos) then
      return nil
   end
   if order.type == "road_move" then
      local next, distMoved, dist = AIManager.getNextPositionTowardsTarget(unitId, order.location,order.maxSpeed, true)
	   return next, distMoved, dist
   end
   if order.type == "move" then
      local next, distMoved, dist = AIManager.getNextPositionTowardsTarget(unitId, order.location,order.maxSpeed, false)
=======
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
>>>>>>> parent of 4ab1098 (Revolution map ready for balance testing)
	   return next, distMoved, dist
   end
   if order.type == "attack_move" then
      print("attack_move")
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
      print("can see enemy")
      print(canSeeEnemy)
      if canSeeEnemy then
         return nil, false
      else
         local next,distMoved, dist = AIManager.getNextPositionTowardsTarget(unitId, order.location,order.maxSpeed,false)
         return next, distMoved, dist
      end
   end
   return nil, 0,0
end

function AIManager.getNextPositionTowardsTarget(unitId, location, maxSpeed, roadBoost)
   local unit = Wargroove.getUnitById(unitId)
   local path = Pathfinding.AStar(unit.playerId, unit.unitClassId, unit.pos, location, roadBoost)
<<<<<<< HEAD

=======
   if (unit.unitClassId == "travelboat") then
      print("AIManager.getNextPositionTowardsTarget(unitId, location, roadBoost)")
      print("unit")
      print(dump(unit,0))
      print("path")
      print(dump(path,0))
   end
>>>>>>> parent of 4ab1098 (Revolution map ready for balance testing)
   --path[1] = nil
   local movePoints = unit.unitClass.moveRange
   if maxSpeed == nil then
      maxSpeed = 1000
   end
   local tiles = maxSpeed
   local target = unit.pos
   local reachedEnd = false
   for i,tile in pairs(path) do
      local tileCost, cantStop = Stats.getTerrainCost(Wargroove.getTerrainNameAt(tile),unit.unitClassId)
<<<<<<< HEAD
=======
      if (unit.unitClassId == "travelboat") then
         print("tileCost")
         print(tileCost)
         print("cantStop")
         print(cantStop)
         print("target")
         print(dump(target,0))
      end
      movePoints = movePoints-tileCost
>>>>>>> parent of 4ab1098 (Revolution map ready for balance testing)
      if i == #path then
         reachedEnd = true
      end
      if tileCost > unit.unitClass.moveRange then
         reachedEnd = true
      end
      if movePoints<=0 then
         break
      end
      if tiles<=0 then
         break
      end
      movePoints = movePoints-tileCost
      tiles = tiles-1
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
   local distMoved = maxSpeed-tiles
	return target, distMoved, dist
end

function AIManager.attackMoveOrder(unitId, location, maxSpeed)
   if location == nil then
      return
   end
   if maxSpeed == nil then
      maxSpeed = 10000;
   end
   if location.x ~= nil then
      location = {location}
   end
   local unit = Wargroove.getUnitById(unitId)
   if unit ~= nil then
      Wargroove.setUnitState(unit, "order", {type = "attack_move", location = location, maxSpeed = maxSpeed})
   end
end

function AIManager.moveOrder(unitId, location, maxSpeed)
   if location == nil then
      return
   end
   if maxSpeed == nil then
      maxSpeed = 10000;
   end
   if location.x ~= nil then
      location = {location}
   end
   local unit = Wargroove.getUnitById(unitId)
   if unit ~= nil then
      Wargroove.setUnitState(unit, "order", {type = "move", location = location, maxSpeed = maxSpeed})
   end
end

function AIManager.roadMoveOrder(unitId, location, maxSpeed)
   if location == nil then
      return
   end
   if maxSpeed == nil then
      maxSpeed = 10000;
   end
   if location.x ~= nil then
      location = {location}
   end
   local unit = Wargroove.getUnitById(unitId)
   if unit ~= nil then
      Wargroove.setUnitState(unit, "order", {type = "road_move", location = location, maxSpeed = maxSpeed})
   end
end

function AIManager.clearOrder(unitId)
   local unit = Wargroove.getUnitById(unitId)
   if unit ~= nil then
      Wargroove.setUnitState(unit, "order", nil)
   end
end

return AIManager
