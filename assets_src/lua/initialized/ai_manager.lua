local Wargroove = require "wargroove/wargroove"
local Ragnarok = require "initialized/ragnarok"
local Stats = require "util/stats"
local Pathfinding = require "util/pathfinding"
local VisionTracker = require "initialized/vision_tracker"
local PosKey = require "util/posKey"
local Copy = require "util/copy"
local Events = require "wargroove/events"

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

local orderMap = {}
local AIManager = {}
local AIPriorityMap = {}
local logging = false
function AIManager.enableLogging()
    logging = true
end




function AIManager.init()
	Ragnarok.addAction(AIManager.update,"repeating",true)
end

function AIManager.update(context)
   
   AIManager.moveUnits(context)
end
function AIManager.moveUnits(context)
   local units = Wargroove.getUnitsAtLocation(nil)
   local bestOrder = nil
   print("AIManager.moveUnits(context)")
   local function comparator(a,b)
      if a.dist-a.distMoved<b.dist-b.distMoved then
         return true
      end
      if a.dist-a.distMoved>b.dist-b.distMoved then
         return false
      end
      if a.dist<b.dist then
         return true
      end
      return false
   end
   local moved = true
   for i,unit in ipairs(units) do
      if unit.playerId < 0 then
         goto next 
      end
      print("Unit: ".. unit.unitClassId.. " " .. unit.id.. " is being checked")

      if not Wargroove.isPlayersCurrentTurn(unit.playerId) then
         goto next 
      end
      print("Is owners' turn")
      if Wargroove.isHuman(unit.playerId) then
         goto next 
      end
      print("Is not human")
      if unit.hadTurn then
         goto next 
      end
      print("Hasn't used its turn yet.")
      print("Order "..AIManager.getOrder(unit.id).type)
      if AIManager.getOrder(unit.id).type ~= "no_order"  then

         print("Unit: ".. unit.unitClassId.. " " .. unit.id.. " got an order and might move")
         Pathfinding.clearCaches()
         local path = AIManager.getPath(unit.id)
         if (path~=nil) and (next(path)~=nil) then 
            print("Unit has a path")
            local nextTile, distMoved, dist = AIManager.getNextPosition(unit.id)
            if nextTile~=nil and not (nextTile.x==unit.pos.x and nextTile.y==unit.pos.y) then
               print("Unit has a next tile")
               local newOrder = {unitId = unit.id, nextTile = {x = nextTile.x, y = nextTile.y}, distMoved = distMoved, dist = dist}

               if bestOrder == nil or comparator(newOrder, bestOrder) then
                  bestOrder = newOrder
               end
            else
               print("Unit with order had no next tile or already reached it!")
               print(dump(nextTile,0))
            end
         else
            print("Unit with order had no path!")
            print(dump(path,0))
         end
      end
      ::next::
   end
   print("best order")
   print(dump(bestOrder,0))
   if bestOrder==nil then 
      return
   end
   local unit = Wargroove.getUnitById(bestOrder.unitId)
   print("1")
   if unit~=nil and unit.hadTurn==false and AIManager.getOrder(unit.id).type ~= "no_order" and Wargroove.isPlayersCurrentTurn(unit.playerId) then
      print("2")
      Pathfinding.clearCaches()
      print("3")
      local path = AIManager.getPath(unit.id)
      print("4")
      if (path~=nil) and (next(path)~=nil) then 
         print("5")
         local nextTile, distMoved, dist = AIManager.getNextPosition(unit.id)
         print("6")
         if nextTile~=nil and not (nextTile.x==unit.pos.x and nextTile.y==unit.pos.y) then
            print("7")
            Wargroove.unitAction({bestOrder.unitId}, {nextTile}, {nextTile}, "wait", true, true, false, "")
            print("8")
            Wargroove.waitFrame()
            print("9")
            
            --Wargroove.doLuaDeathCheck(bestOrder.unitId, true)

            Wargroove.refreshObstacles()
            
            print("10")
            Events.checkEventsAfter()
         end
      end
   end
   print("it worked!")
end

function AIManager.setAIPriorityMap(playerId, positions, priority)
   if AIPriorityMap[playerId]== nil then
      AIPriorityMap[playerId] = {}
   end
   for i,pos in pairs(positions) do
      local posKey = PosKey.generatePosKey(pos)
      AIPriorityMap[playerId][posKey] = priority
   end
end

function AIManager.getAIPriority(playerId, pos)
   local posKey = PosKey.generatePosKey(pos)
   if AIPriorityMap[playerId]==nil then
      return nil
   end
   return AIPriorityMap[playerId][posKey]
end

function AIManager.letNeutralUnitsMove()
   local units = Wargroove.getUnitsAtLocation(nil)
   for i,unit in ipairs(units) do
       if Pathfinding.withinBounds(unit.pos) and Wargroove.isNeutral(unit.playerId) and not unit.unitClass.isStructure then
         Pathfinding.clearCaches()
         print("Neutral unit ".. unit.unitClassId.. " has order:")
         print(dump(AIManager.getOrder(unit.id),0))
         local path = AIManager.getPath(unit.id)
         if (path~=nil) and (next(path)~=nil) then 
            local nextTile, distMoved, dist = AIManager.getNextPositionTowardsTarget(unit, path,100)
            if (path~=nil) and (next(path)~=nil) then
               local shortenedPath = {}
               for j, tile in ipairs(path) do
                  if j>distMoved then
                     break
                  end
                  table.insert(shortenedPath,tile)
               end
               if (next(shortenedPath)~=nil) then
                  --Wargroove.unitAction({unit.id}, {shortenedPath[#shortenedPath]}, {shortenedPath[#shortenedPath]}, "wait", true, true, false, "")
                  --Wargroove.waitFrame()

                  --Wargroove.refreshObstacles()
                  Pathfinding.forceMoveAlongPath(unit.id, shortenedPath)
               end
            end
         end
       end
   end
end

function AIManager.shouldAIMoveUnit(unit)
   local order = AIManager.getOrder(unit.id)
   if order.type == "no_order" then
      return nil
   end
   if order.type == "attack_move" then
      if AIManager.isEnemyInRange(unit) then
         return true
      end
   end
   for i,tile in pairs(order.location) do
      if (unit.pos.x == tile.x) and (unit.pos.y == tile.y) then
         return false
      end
   end
   return true
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
      local enemyLocations = {}
      for i, enemy in ipairs(Wargroove.getUnitsAtLocation()) do
        if Wargroove.areEnemies(enemy.playerId,unit.playerId) and VisionTracker.canSeeTile(unit.playerId,enemy.pos) then
            table.insert(enemyLocations,{x = unit.pos.x,y = unit.pos.y})
        end
      end
      local safetyMap = Pathfinding.getDistanceToLocationMap(unit.pos, 50, enemyLocations)
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
   if order.type == "follow" then
      if order.location == nil then
         return {}
      end
      local enemyLocations = {}
      for i, enemy in ipairs(Wargroove.getUnitsAtLocation()) do
        if Wargroove.areEnemies(enemy.playerId,unit.playerId) and VisionTracker.canSeeTile(unit.playerId,enemy.pos) then
            table.insert(enemyLocations,{x = unit.pos.x,y = unit.pos.y})
        end
      end
      local safetyMap = Pathfinding.getDistanceToLocationMap(unit.pos, 50, enemyLocations)
      local targetDistMap = Pathfinding.getDistanceToLocationMap(unit.pos, 50, order.location)
      local targetLocation = {}
      for posKey, dist in pairs(targetDistMap) do
         if dist == 3 then
            table.insert(targetLocation,PosKey.revertPosKey(posKey))
         end
      end
      local path = Pathfinding.AStar(unit, targetLocation,{posPenalty = function(unit,pos)
         if pos == nil then
            return 0
         end
         if safetyMap == nil then
            return 0
         end
         if next(safetyMap)==nil then
            return 0
         end
         return math.max(6-safetyMap[PosKey.generatePosKey(pos)],0)+math.max(2-targetDistMap[PosKey.generatePosKey(pos)],0)
      end, posPenaltyId = "follow"})
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
               return Stats.getMovementCostAtPos(unit,pos)+bonus
           end
         end
         if (movementType == "amphibious") or (movementType == "sailing") then
           if not (terrainName == "sea" or terrainName == "river" or terrainName == "ocean") then
               return Stats.getMovementCostAtPos(unit,pos)+bonus
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
               return Stats.getMovementCostAtPos(unit,pos)+bonus+positionalBonus
            end
         end
         if (movementType == "amphibious") or (movementType == "sailing") then
            if not (terrainName == "sea" or terrainName == "river" or terrainName == "ocean") then
               return Stats.getMovementCostAtPos(unit,pos)+bonus+positionalBonus
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
               return Stats.getMovementCostAtPos(unit,pos)+bonus+positionalBonus
            end
         end
         if (movementType == "amphibious") or (movementType == "sailing") then
            if not (terrainName == "sea" or terrainName == "river" or terrainName == "ocean") then
               return Stats.getMovementCostAtPos(unit,pos)+bonus+positionalBonus
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
      local enemyLocations = {}
      for i, enemy in ipairs(Wargroove.getUnitsAtLocation()) do
        if Wargroove.areEnemies(enemy.playerId,unit.playerId) and VisionTracker.canSeeTile(unit.playerId,enemy.pos) then
            table.insert(enemyLocations,{x = unit.pos.x,y = unit.pos.y})
        end
      end
      local safetyMap = Pathfinding.getDistanceToLocationMap(unit.pos, unit.unitClass.moveRange, enemyLocations)
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
      local goStraight = true
      if Ragnarok.usingFogOfWarRules() then
         local tileList = Wargroove.getTargetsInRange(unit.pos, VisionTracker.getSightRange(unit), "all")
         for i,tile in pairs(tileList) do
            if VisionTracker.canSeeTile(unit.playerId,tile) then
               local target = Wargroove.getUnitAt(tile)
               if target~=nil and Wargroove.areEnemies(unit.playerId, target.playerId) then
                  goStraight = false
                  break
               end
            end
         end
      else
         local tileList = Wargroove.getTargetsInRange(unit.pos, unit.unitClass.moveRange+1, "all")
         for i,tile in pairs(tileList) do
            local target = Wargroove.getUnitAt(tile)
            if target~=nil and Wargroove.areEnemies(unit.playerId, target.playerId) then
               goStraight = false
               break
            end
         end
      end         
      if not goStraight then
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
   if order.type == "do_verb" then
      if order.location == nil then
         return {}
      end
      local path = Pathfinding.AStar(unit, order.location, {posPenalty = function(unit,pos)
         if Stats.getMovementType(unit.unitClassId) == "flying" then
            return 4-Wargroove.getSkyDefenceAt(pos)
         end
         return 4-Wargroove.getTerrainDefenceAt(pos)
      end, posPenaltyId = "defense"})
      return path
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
   if order.type == "no_order" then
      return nil
   end
   if not Pathfinding.withinBounds(unit.pos) then
      return nil
   end

   local path = AIManager.getPath(unitId);
   local nextTile, distMoved, dist = AIManager.getNextPositionTowardsTarget(unit, path,order.maxSpeed)
   if order.type == "attack_move" then
      if AIManager.isEnemyInRange(unit) then
         return nil, nil, nil
      end
   end
   if order.type == "do_verb" then
      if distMoved>=#path-1 then
         return nil, nil, nil
      end
   end
   return nextTile, distMoved, dist
end
--[[Gets tiles attackable by unit. This does not account for minimum range.]]
function AIManager.getAttackableTiles(unitId)
   local unit = Wargroove.getUnitById(unitId)
   if unit == nil then
      return nil
   end
   if unit.health <= 0 then
      return nil
   end
   local weapons = unit.unitClass.weapons
   if #weapons ~= 1 then
      return nil
   end
   local weapons = unit.unitClass.weapons
   local movementArea = Pathfinding.getMoveTiles(unit)
   local result = {}
   local distanceToLocationMap = Pathfinding.getDistanceToLocationMap(unit.pos,weapons[1].maxRange+unit.unitClass.moveRange,movementArea)
   for key,dist in pairs(distanceToLocationMap) do
      local tile = PosKey.revertPosKey(key)
      if dist <= weapons[1].maxRange then
         table.insert(result,tile)
      end
   end
   return result
end

function AIManager.isEnemyInRange(unit)
   local tileList = Wargroove.getTargetsInRange(unit.pos, VisionTracker.getSightRange(unit), "unit")
   for i,tile in pairs(tileList) do
      if VisionTracker.canSeeTile(unit.playerId,tile) then
         local target = Wargroove.getUnitAt(tile)
         if target~=nil and Wargroove.areEnemies(unit.playerId, target.playerId) then
            return true
         end
      end
   end
   return false
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
   local distMoved = 0
   for i,tile in pairs(path) do
      local tileCost = Stats.getMovementCostAtPos(unit,tile)
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
         distMoved = maxSpeed-tiles
      end
   end
   local dist = 0
   for i,tile in pairs(path) do
      local tileCost = Stats.getMovementCostAtPos(unit,tile)
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
	return target, distMoved, dist
end


function AIManager.order(t, unitId, location, maxSpeed)
   if maxSpeed == nil then
      maxSpeed = 1000
   end
   if location == nil then
      
      error("Argument 'location' was missing")
      return
   end
   if location.x ~= nil then
      location = {location}
   end
   local unit = Wargroove.getUnitById(unitId)
   if (unit ~= nil) and Pathfinding.withinBounds(unit.pos) then
      orderMap[unitId] = {type = t, location = location, maxSpeed = maxSpeed}
      if logging then
         local unit = Wargroove.getUnitById(unitId)
         print("Unit: ".. unit.unitClassId.. " " .. unit.id.. "'s order got replaced by")
         print(dump(orderMap[unitId],0))
      end
   end
end

function AIManager.attackMoveOrder(unitId, location, maxSpeed)
   if location == nil then
      return
   end
   AIManager.order("attack_move", unitId, location, maxSpeed)
end

function AIManager.doVerbOrder(unitId, location, maxSpeed)
   if location == nil then
      return
   end
   AIManager.order("do_verb", unitId, location, maxSpeed)
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

function AIManager.followOrder(unitId, location, maxSpeed)
   if location == nil then
      return
   end
   AIManager.order("follow", unitId, location, maxSpeed)
end

function AIManager.clearOrder(unitId)
   if logging then
      local unit = Wargroove.getUnitById(unitId)
      print("Unit: ".. unit.unitClassId.. " " .. unit.id.. " lost its order")
   end
   orderMap[unitId] = {type = "no_order", location = nil, maxSpeed = 0}
end

function AIManager.getOrder(unitId)
   if orderMap[unitId] == nil then
      orderMap[unitId] = {type = "no_order", location = nil, maxSpeed = 0}
   end
   return orderMap[unitId]
end

return AIManager
