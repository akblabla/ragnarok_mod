local Wargroove = require "wargroove/wargroove"
local Ragnarok = require "initialized/ragnarok"
local Stats = require "util/stats"
local Pathfinding = require "util/pathfinding"
local VisionTracker = require "initialized/vision_tracker"
local PosKey = require "util/posKey"

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
--	Ragnarok.addAction(AIManager.update,"repeating",true)
end

function AIManager.setup(context)
end

function AIManager.letNeutralUnitsMove()
   for i,unit in ipairs(Wargroove.getUnitsAtLocation(nil)) do
       if Pathfinding.withinBounds(unit.pos) and Wargroove.isNeutral(unit.playerId) then
         local nextTile, distMoved, dist = AIManager.getNextPosition(unit.id)
         if nextTile ~= nil then 
            local path = Pathfinding.AStar(unit, nextTile)
            if (path~=nil) and (next(path)~=nil) then
               Pathfinding.forceMoveAlongPath(unit.id, path)
            end
         end
       end
   end
end

function AIManager.update(context)
end

function AIManager.getPath(unitId)
   local unit = Wargroove.getUnitById(unitId)
   if unit == nil then
      return {}
   end
   if unit.health <= 0 then
      return {}
   end
   local order = AIManager.getOrder(unitId)
   if order == nil then
      return {}
   end
   if not Pathfinding.withinBounds(unit.pos) then
      return {}
   end
   if order.type == "safe_move" then
      if order.location == nil then
         return {}
      end
      local safetyMap = Pathfinding.distanceToEnemyMap(unit.pos, 50, unit.playerId)
      local path = Pathfinding.AStar(unit, order.location,{posPenalty = function(unit,pos)
         if pos == nil then
            return 0
         end
         if safetyMap == nil then
            return 0
         end
         if next(safetyMap)==nil then
            return 0
         end
         if Stats.getMovementType(unit.unitClassId) == "flying" then
            return 4-Wargroove.getSkyDefenceAt(pos) + math.max(10-safetyMap[PosKey.generatePosKey(pos)],0)*2
         end
         return 4-Wargroove.getTerrainDefenceAt(pos) + math.max(10-safetyMap[PosKey.generatePosKey(pos)],0)*2
      end, posPenaltyId = "defense_and_safety"})
	   return path
   end
   if order.type == "road_move" then
      if order.location == nil then
         return {}
      end
      local path = Pathfinding.AStar(unit, order.location,{pathPenalty = function(unit,pos)
         local terrainName = Wargroove.getTerrainNameAt(pos)
         local movementType = Stats.getMovementType(unit.unitClassId);
         local cover = Stats.isTerrainFowCover(Wargroove.getTerrainNameAt(pos))
         local blocker = Stats.isTerrainBlocking(Wargroove.getTerrainNameAt(pos))
         local bonus = 2
         if cover then
            bonus = bonus+1
         end
         if blocker then
            bonus = bonus+1
         end
         if (movementType == "walking") or (movementType == "riding") or (movementType == "wheels") then
           if not (terrainName == "road" or terrainName == "bridge") then
               return Stats.getTerrainCost(Wargroove.getTerrainNameAt(pos),unit.unitClassId)+bonus
           end
         end
         if (movementType == "amphibious") or (movementType == "sailing") then
           if not (terrainName == "sea" or terrainName == "river" or terrainName == "ocean") then
             return Stats.getTerrainCost(Wargroove.getTerrainNameAt(pos),unit.unitClassId)+bonus
           end
         end
         return 0
      end, pathPenaltyId = "roads"})
	   return path
   end
   if order.type == "road_move_left" then
      if order.location == nil then
         return {}
      end
      local path = Pathfinding.AStar(unit, order.location,{pathPenalty = function(unit,pos)
         local terrainName = Wargroove.getTerrainNameAt(pos)
         local movementType = Stats.getMovementType(unit.unitClassId);
         local cover = Stats.isTerrainFowCover(Wargroove.getTerrainNameAt(pos))
         local blocker = Stats.isTerrainBlocking(Wargroove.getTerrainNameAt(pos))
         local bonus = 2
         local positionalBonus = math.max(pos.x,0)/Wargroove.getMapSize().x
         if cover then
            bonus = bonus+1
         end
         if blocker then
            bonus = bonus+1
         end
         if (movementType == "walking") or (movementType == "riding") or (movementType == "wheels") then
           if not (terrainName == "road" or terrainName == "bridge") then
               return Stats.getTerrainCost(Wargroove.getTerrainNameAt(pos),unit.unitClassId)+bonus+positionalBonus
           end
         end
         if (movementType == "amphibious") or (movementType == "sailing") then
           if not (terrainName == "sea" or terrainName == "river" or terrainName == "ocean") then
             return Stats.getTerrainCost(Wargroove.getTerrainNameAt(pos),unit.unitClassId)+bonus+positionalBonus
           end
         end
         return positionalBonus
      end, pathPenaltyId = "roads_and_left"})
	   return path
   end
   if order.type == "road_move_right" then
      if order.location == nil then
         return {}
      end
      local path = Pathfinding.AStar(unit, order.location,{pathPenalty = function(unit,pos)
         local terrainName = Wargroove.getTerrainNameAt(pos)
         local movementType = Stats.getMovementType(unit.unitClassId);
         local cover = Stats.isTerrainFowCover(Wargroove.getTerrainNameAt(pos))
         local blocker = Stats.isTerrainBlocking(Wargroove.getTerrainNameAt(pos))
         local bonus = 2
         local positionalBonus = math.max(Wargroove.getMapSize().x-pos.x,0)/Wargroove.getMapSize().x
         if cover then
            bonus = bonus+1
         end
         if blocker then
            bonus = bonus+1
         end
         if (movementType == "walking") or (movementType == "riding") or (movementType == "wheels") then
           if not (terrainName == "road" or terrainName == "bridge") then
               return Stats.getTerrainCost(Wargroove.getTerrainNameAt(pos),unit.unitClassId)+bonus+positionalBonus
           end
         end
         if (movementType == "amphibious") or (movementType == "sailing") then
           if not (terrainName == "sea" or terrainName == "river" or terrainName == "ocean") then
             return Stats.getTerrainCost(Wargroove.getTerrainNameAt(pos),unit.unitClassId)+bonus+positionalBonus
           end
         end
         return positionalBonus
      end, pathPenaltyId = "roads_and_right"})
	   return path
   end
   if order.type == "move" then
      if order.location == nil then
         return {}
      end
      local path = Pathfinding.AStar(unit, order.location)
	   return path
   end
   if order.type == "retreat" then
      local availableTiles = Pathfinding.getMoveTiles(unit)
      local safetyMap = Pathfinding.distanceToEnemyMap(unit.pos, unit.unitClass.moveRange, unit.playerId)
      local safestPos = unit.pos
      local bestSafety = 0
      for posKey,dist in pairs(availableTiles) do
         if (safetyMap[posKey]~=nil) and (safetyMap[posKey]>bestSafety) then
            bestSafety = safetyMap[posKey]
            safestPos = PosKey.revertPosKey(posKey)
         end
      end
      local path = Pathfinding.AStar(unit, safestPos)
	   return path
   end
   if order.type == "attack_move" then
      if order.location == nil then
         return {}
      end
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
         return {}
      else
         local path = Pathfinding.AStar(unit, order.location, {posPenalty = function(unit,pos)
            if Stats.getMovementType(unit.unitClassId) == "flying" then
               return 4-Wargroove.getSkyDefenceAt(pos)
            end
            return 4-Wargroove.getTerrainDefenceAt(pos)
         end, posPenaltyId = "defense"})
         return path
      end
   end
   return {}
end

function AIManager.getNextPosition(unitId)
   local unit = Wargroove.getUnitById(unitId)
   if unit == nil then
      return nil
   end
   if unit.health <= 0 then
      return nil
   end
   local order = AIManager.getOrder(unitId)
   if order == nil then
      return nil
   end
   if not Pathfinding.withinBounds(unit.pos) then
      return nil
   end

   local path = AIManager.getPath(unitId);
   local nextTile, distMoved, dist = AIManager.getNextPositionTowardsTarget(unit, path,order.maxSpeed)
   if order.type == "attack_move" then
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
      end
   end
   return nextTile, distMoved, dist
end

function AIManager.getNextPositionTowardsTarget(unit, path, maxSpeed)

   --path[1] = nil
   local movePoints = unit.unitClass.moveRange
   if maxSpeed == nil then
      maxSpeed = 1000
   end
   local tiles = maxSpeed
   local target = unit.pos
   local reachedEnd = false
   for i,tile in pairs(path) do
      local tileCost = Stats.getTerrainCost(Wargroove.getTerrainNameAt(tile),unit.unitClassId)
      local canStop = Stats.canStopOnTerrain(Wargroove.getTerrainNameAt(tile),unit.unitClassId)
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
      local other = Wargroove.getUnitAt(tile)
      if (other~=nil) and Wargroove.areEnemies(unit.playerId,other.playerId) then
         break
      end
      movePoints = movePoints-tileCost
      tiles = tiles-1
      if (Wargroove.isAnybodyElseAt(unit,tile) == false) and canStop then
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

local orderMap = {}

function AIManager.order(order, unitId, location, maxSpeed)
   if maxSpeed == nil then
      maxSpeed = 10000;
   end
   if (location ~= nil) and (location.x ~= nil) then
      location = {location}
   end
   local unit = Wargroove.getUnitById(unitId)
   if unit ~= nil then
      orderMap[unit.id] = {type = order, location = location, maxSpeed = maxSpeed}
      -- Wargroove.setUnitStateObject(unit, "order", {type = "road_move", location = location, maxSpeed = maxSpeed})
      -- Wargroove.updateUnit(unit)
   end
end

function AIManager.attackMoveOrder(unitId, location, maxSpeed)
   if location == nil then
      return
   end
   AIManager.order("attack_move", unitId, location, maxSpeed)
end

function AIManager.moveOrder(unitId, location, maxSpeed)
   if location == nil then
      return
   end
   AIManager.order("move", unitId, location, maxSpeed)
end

function AIManager.retreatOrder(unitId, maxSpeed)
   AIManager.order("retreat", unitId, {}, maxSpeed)
end

function AIManager.roadMoveOrder(unitId, location, maxSpeed)
   if location == nil then
      return
   end
   AIManager.order("road_move", unitId, location, maxSpeed)
end

function AIManager.roadMoveLeftOrder(unitId, location, maxSpeed)
   if location == nil then
      return
   end
   AIManager.order("road_move_left", unitId, location, maxSpeed)
end

function AIManager.roadMoveRightOrder(unitId, location, maxSpeed)
   if location == nil then
      return
   end
   AIManager.order("road_move_right", unitId, location, maxSpeed)
end

function AIManager.safeMoveOrder(unitId, location, maxSpeed)
   if location == nil then
      return
   end
   AIManager.order("safe_move", unitId, location, maxSpeed)
end


function AIManager.clearOrder(unitId)
   local unit = Wargroove.getUnitById(unitId)
   if unit ~= nil then
      orderMap[unit.id] = {type = "no_order", location = {}, maxSpeed = 0}
      --Wargroove.setUnitStateObject(unit, "order", {type = "no_order", location = {}, maxSpeed = 0})
      --Wargroove.updateUnit(unit)
   end
end

function AIManager.getOrder(unitId)
   local unit = Wargroove.getUnitById(unitId)
   if (unit ~= nil) then
      return orderMap[unit.id]
      -- local state = Wargroove.getUnitStateObject(unit, "order")
      -- if state~= nil then
      --    state.maxSpeed = tonumber(state.maxSpeed)
      --    if state.location ~=nil then
      --       for i,tile in pairs(state.location) do
      --          state.location[i].x = tonumber(tile.x)
      --          state.location[i].y = tonumber(tile.y)
      --       end
      --    end
      --    return state
      -- end
   end
   return {type = "no_order", location = nil, maxSpeed = 0}
end

return AIManager
