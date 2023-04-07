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

local function movementCost(pos, unitId)
   local stranger = Wargroove.getUnitAt(pos)
   local unit = Wargroove.getUnitById(unitId)
   if stranger ~= nil and unit ~= nil and Wargroove.areEnemies(unit.playerId, stranger.playerId) then
      return 1000
   end
   return Wargroove.getTerrainMovementCostAt(pos)
end

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
   print("AIManager.getNextPosition(unitId)")
   print(unitId)
   local unit = Wargroove.getUnitById(unitId)
   if AITargets[unitId].order == "move" then
      local next,reachedEnd = AIManager.getNextPositionTowardsTarget(unitId, AITargets[unitId].pos)
	   return next, reachedEnd
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
         print("can see enemy :)")
         return nil, false
      else
         print("can't see enemy :(")
         local next,reachedEnd = AIManager.getNextPositionTowardsTarget(unitId, AITargets[unitId].pos)
         return next, reachedEnd
      end
   end
   return nil, true
end

function AIManager.getNextPositionTowardsTarget(unitId, pos)
   local unit = Wargroove.getUnitById(unitId)
   local path = Pathfinding.AStar(unit.pos, pos, movementCost, unitId)
   --path[1] = nil
   local movePoints = unit.unitClass.moveRange
   local target = unit.pos
   local reachedEnd = false
   for i,tile in pairs(path) do
      movePoints = movePoints-movementCost(tile,unitId)
      if i == #path then
         reachedEnd = true
      end
      if Wargroove.getTerrainMovementCostAt(target) > unit.unitClass.moveRange then
         reachedEnd = true
      end
      if movePoints<0 then
         break
      end
      if Wargroove.isAnybodyElseAt(unit,tile) == false then
         target = tile
      end
   end
	return target, reachedEnd
end

function AIManager.getAITarget(unitId)
	return AITargets[unitId]
end

function AIManager.attackMoveOrder(unitId, pos)
	AITargets[unitId] = {order = "attack_move", pos = pos}
end

function AIManager.moveOrder(unitId, pos)
	AITargets[unitId] = {order = "move", pos = pos}
end

function AIManager.clearOrder(unitId)
	AITargets[unitId] = nil
end

return AIManager
