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
      local next, distMoved, dist = AIManager.getNextPositionTowardsTarget(unitId, AITargets[unitId].pos,true)
	   return next, distMoved, dist
   end
   if AITargets[unitId].order == "move" then
      local next, distMoved, dist = AIManager.getNextPositionTowardsTarget(unitId, AITargets[unitId].pos,false)
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
         local next,distMoved, dist = AIManager.getNextPositionTowardsTarget(unitId, AITargets[unitId].pos,false)
         return next, distMoved, dist
      end
   end
   return nil, 0,0
end

function AIManager.getNextPositionTowardsTarget(unitId, pos, roadBoost)
   local unit = Wargroove.getUnitById(unitId)
   local path = Pathfinding.AStar(unit.playerId, unit.unitClassId, unit.pos, pos, roadBoost)
   --path[1] = nil
   local movePoints = unit.unitClass.moveRange
   local target = unit.pos
   local reachedEnd = false
   for i,tile in pairs(path) do
      movePoints = movePoints-Stats.getTerrainCost(Wargroove.getTerrainNameAt(pos),unit.unitClassId)
      if i == #path then
         reachedEnd = true
      end
      if Stats.getTerrainCost(Wargroove.getTerrainNameAt(pos),unit.unitClassId) > unit.unitClass.moveRange then
         reachedEnd = true
      end
      if movePoints<0 then
         break
      end
      if Wargroove.isAnybodyElseAt(unit,tile) == false then
         target = tile
      end
   end
   local dist = 0
   for i,tile in pairs(path) do
      if Stats.getTerrainCost(Wargroove.getTerrainNameAt(pos),unit.unitClassId)<100 then
         dist = dist+Stats.getTerrainCost(Wargroove.getTerrainNameAt(pos),unit.unitClassId)
         if i == #path then
            break
         end
         if Stats.getTerrainCost(Wargroove.getTerrainNameAt(pos),unit.unitClassId) > unit.unitClass.moveRange then
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

function AIManager.attackMoveOrder(unitId, pos)
   if pos == nil then
      return
   end
	AITargets[unitId] = {order = "attack_move", pos = pos}
end

function AIManager.moveOrder(unitId, pos)
   if pos == nil then
      return
   end
   AITargets[unitId] = {order = "move", pos = pos}
end

function AIManager.roadMoveOrder(unitId, pos)
   if pos == nil then
      return
   end
   AITargets[unitId] = {order = "road_move", pos = pos}
end

function AIManager.clearOrder(unitId)
	AITargets[unitId] = nil
end

return AIManager
