local Wargroove = require "wargroove/wargroove"
local Ragnarok = require "initialized/ragnarok"
local Pathfinding = require "util/pathfinding"
local PosKey = require "util/posKey"
local Combat = require "wargroove/combat"

local PirateBout = {}


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


local function getTilesInRange(pos, minRange, maxRange)

    local result = {}
    local x0 = pos.x
    local y0 = pos.y
    for yo = -maxRange, maxRange do
        for xo = -maxRange, maxRange do
            local distance = math.abs(xo) + math.abs(yo)
            if distance <= maxRange and distance >= minRange then
               local x = x0 + xo
               local y = y0 + yo
               table.insert(result, { x = x, y = y})
            end
        end
    end

    return result
end

local function convolve(location1,location2)
   local resultKeys = {}
   for i,tile1 in ipairs(location1) do
      for j,tile2 in ipairs(location2) do
         local x = tile1.x+tile2.x
         local y = tile1.y+tile2.y
         resultKeys[PosKey.generatePosKey({x=x,y=y})] = true
      end
   end
   local result = {}
   for posKey,bool in pairs(resultKeys) do
      table.insert(result,PosKey.revertPosKey(posKey))
   end
   return result
end

function PirateBout.playerIgnoreUnitsThreateningAllies(playerId)
   local units = Wargroove.getUnitsAtLocation(nil)
   for i,unit in ipairs(units) do
      if Wargroove.isPlayersCurrentTurn(playerId) and Wargroove.areEnemies(playerId, unit.playerId) then
         print("Is Unit "..unit.id.." of type "..unit.unitClassId.." at pos "..unit.pos.x..", "..unit.pos.y.." a threat?")
         local moveLocationHashed = Pathfinding.getMoveTiles(unit)
         local moveLocation = {}
         for posKey,dist in pairs(moveLocationHashed) do
            table.insert(moveLocation,PosKey.revertPosKey(posKey))
         end
         if unit.unitClass.isStructure then
            goto next
         end
         local weapons = unit.unitClass.weapons
         if #weapons ~= 1 then
            goto next
         end
         local weapons = unit.unitClass.weapons
         
         local rangeLocation = getTilesInRange({x=0,y=0}, weapons[1].minRange, weapons[1].maxRange)


         local targetableLocation = convolve(moveLocation,rangeLocation)
         --print("targetableLocation")
         --print(dump(targetableLocation,0))
         local bargeScore = 0
         for i,tile in ipairs(targetableLocation) do
            local target = Wargroove.getUnitAt(tile)
            if target~=nil and Wargroove.areAllies(playerId, target.playerId) then
               local attackLocations = convolve({tile},rangeLocation)
               local attackPos = {}
               for j,attackTile in ipairs(attackLocations) do
                  local key = PosKey.generatePosKey(attackTile)
                  if moveLocationHashed[key]~=nil then
                     attackPos = attackTile
                     break
                  end
               end
               attackPos.facing = 0
               print("Threatning Unit "..target.id.." of type "..target.unitClassId.." at pos "..target.pos.x..", "..target.pos.y)
               local damagePotential = Combat:getBaseDamage(unit, target, attackPos)
               if damagePotential==nil then
                  damagePotential = 0
               end
               print("damagePotential: ".. damagePotential)
               local targetValue = target.unitClass.cost*math.min(damagePotential, target.health)/100
               if target.unitClassId == "travelboat_with_gold" then
                  targetValue = targetValue+2000
               end
               print("targetValue: ".. targetValue)
               if target.playerId~=playerId then
                  bargeScore=bargeScore-targetValue*0.75
               else
                  bargeScore=bargeScore+targetValue
               end
               print("bargeScore: ".. bargeScore)
               
            end
         end
         if bargeScore<0 then
            Wargroove.setAIRestriction(unit.id,"dont_target_this", true)
         else
            Wargroove.setAIRestriction(unit.id,"dont_target_this", false)
         end
      end
      ::next::
   end
end


return PirateBout
