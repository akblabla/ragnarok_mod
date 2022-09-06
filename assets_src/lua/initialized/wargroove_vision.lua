local OldWargroove = require "wargroove/wargroove"
local VisionTracker = require "initialized/vision_tracker"

local WargrooveVision = {}
local Original = {}

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

function WargrooveVision.init()
	Original.removeUnit = OldWargroove.removeUnit
	OldWargroove.removeUnit = WargrooveVision.removeUnit
	
	Original.spawnUnit = OldWargroove.spawnUnit
	OldWargroove.spawnUnit = WargrooveVision.spawnUnit
	
	Original.updateUnit = OldWargroove.updateUnit
	OldWargroove.updateUnit = WargrooveVision.updateUnit
	
	Original.startCapture = OldWargroove.startCapture
	OldWargroove.startCapture = WargrooveVision.startCapture
end

function WargrooveVision.startCapture(attacker, defender, attackerPos)
	VisionTracker.removeUnitFromVisionMatrix(defender)
	print("captured building before")
	print(dump(defender,0))
	Original.startCapture(attacker, defender, attackerPos)
	print("captured building after")
	print(dump(defender,0))
	defender.playerId = attacker.playerId
	VisionTracker.addUnitToVisionMatrix(defender)
end

function WargrooveVision.spawnUnit(playerId, pos, unitType, turnSpent, startAnimation, startingState, factionOverride)  
	local unitId = Original.spawnUnit(playerId, pos, unitType, turnSpent, startAnimation, startingState, factionOverride)  
	local unit = OldWargroove.getUnitById(unitId)
	VisionTracker.addUnitToVisionMatrix(unit)
	VisionTracker.getPrevPosList()[unitId] = pos
    return unitId
end


function WargrooveVision.updateUnit(unit)
	print("WargrooveVision.updateUnit starts here")
	local oldUnit = {playerId = unit.playerId, unitClassId = unit.unitClassId, pos = VisionTracker.getPrevPosList()[unit.id], unitClass = unit.unitClass}
	oldUnit.pos = VisionTracker.getPrevPosList()[unit.id]
	print("Old Unit Position: "..tostring(oldUnit.pos.x)..","..tostring(oldUnit.pos.y))
	VisionTracker.removeUnitFromVisionMatrix(oldUnit)
    Original.updateUnit(unit)
	print("New Unit Position: "..tostring(unit.pos.x)..","..tostring(unit.pos.y))
	VisionTracker.addUnitToVisionMatrix(unit)
	VisionTracker.getPrevPosList()[unit.id] = unit.pos
end

function WargrooveVision.removeUnit(unitId)
	local unit = OldWargroove.getUnitById(unitId)
	local oldUnit = {playerId = unit.playerId, unitClassId = unit.unitClassId, pos = VisionTracker.getPrevPosList()[unitId], unitClass = unit.unitClass}
	VisionTracker.removeUnitFromVisionMatrix(oldUnit)
	Original.removeUnit(unitId)
end


return WargrooveVision
