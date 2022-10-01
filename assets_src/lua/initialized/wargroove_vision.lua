local OldWargroove = require "wargroove/wargroove"
local Ragnarok = require "initialized/ragnarok"
local VisionTracker = require "initialized/vision_tracker"
local FIFOQueue = require "util/fifoQueue"

local WargrooveVision = {}
local Original = {}

local weatherFIFO = FIFOQueue:new()

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
	Original.setPlayerTeam = OldWargroove.setPlayerTeam
	OldWargroove.setPlayerTeam = WargrooveVision.setPlayerTeam
	
	Original.removeUnit = OldWargroove.removeUnit
	OldWargroove.removeUnit = WargrooveVision.removeUnit
	
	Original.spawnUnit = OldWargroove.spawnUnit
	OldWargroove.spawnUnit = WargrooveVision.spawnUnit
	
	Original.updateUnit = OldWargroove.updateUnit
	OldWargroove.updateUnit = WargrooveVision.updateUnit
	
	Original.updateUnits = OldWargroove.updateUnits
	OldWargroove.updateUnits = WargrooveVision.updateUnits
	
	Original.startCapture = OldWargroove.startCapture
	OldWargroove.startCapture = WargrooveVision.startCapture
	
	Original.canPlayerSeeTile = OldWargroove.canPlayerSeeTile
	OldWargroove.canPlayerSeeTile = WargrooveVision.canPlayerSeeTile
	
	Original.canCurrentlySeeTile = OldWargroove.canCurrentlySeeTile
	OldWargroove.canCurrentlySeeTile = WargrooveVision.canCurrentlySeeTile
	
	Original.setWeather = OldWargroove.setWeather
	OldWargroove.setWeather = WargrooveVision.setWeather
end

function WargrooveVision.startCapture(attacker, defender, attackerPos)
	VisionTracker.removeUnitFromVisionMatrix(defender)
	--print("captured building before")
	--print(dump(defender,0))
	Original.startCapture(attacker, defender, attackerPos)
	--print("captured building after")
	--print(dump(defender,0))
	defender.playerId = attacker.playerId
	VisionTracker.addUnitToVisionMatrix(defender)
end

function WargrooveVision.spawnUnit(playerId, pos, unitType, turnSpent, startAnimation, startingState, factionOverride)  
	local unitId = Original.spawnUnit(playerId, pos, unitType, turnSpent, startAnimation, startingState, factionOverride)  
	local unit = OldWargroove.getUnitById(unitId)
	VisionTracker.addUnitToVisionMatrix(unit)
	--VisionTracker.getPrevPosList()[unitId] = pos
    return unitId
end

function WargrooveVision.setPlayerTeam(playerId, teamId)
    Original.setPlayerTeam(playerId, teamId)
	VisionTracker.setupTeamPlayers()
end

function WargrooveVision.updateUnit(unit)
    Original.updateUnit(unit)
	VisionTracker.updateUnitInVisionMatrix(unit)
end

function WargrooveVision.updateUnits(units)
    Original.updateUnits(units)
    for i, unit in ipairs(units) do
        VisionTracker.updateUnitInVisionMatrix(unit)
    end
end

function WargrooveVision.removeUnit(unitId)
	local unit = OldWargroove.getUnitById(unitId)
	--local oldUnit = {playerId = unit.playerId, unitClassId = unit.unitClassId, pos = VisionTracker.getPrevPosList()[unitId], unitClass = unit.unitClass}
	VisionTracker.removeUnitFromVisionMatrix(unit)
	Original.removeUnit(unitId)
end

function WargrooveVision.canPlayerSeeTile(player, tile)
	if player == -1 then
		player = OldWargroove.getCurrentPlayerId()
	end
	if Ragnarok.usingFogOfWarRules() and not OldWargroove.isHuman(player) then
		return VisionTracker.canSeeTile(player,tile)
	end
    return Original.canPlayerSeeTile(player, tile)
end

function WargrooveVision.canCurrentlySeeTile(tile)
	if Ragnarok.usingFogOfWarRules() then
		local player = OldWargroove.getCurrentPlayerId()
		if not OldWargroove.isHuman(player) then
			return VisionTracker.canSeeTile(player,tile)
		end
	end
    return Original.canCurrentlySeeTile(tile)
end

function WargrooveVision.setWeather(weatherFrequency, daysAhead)
	Original.setWeather(weatherFrequency, daysAhead)
	if daysAhead == 0 then
		VisionTracker.reset()
	end
end

return WargrooveVision
