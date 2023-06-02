local OldWargroove = require "wargroove/wargroove"
local Ragnarok = require "initialized/ragnarok"
local VisionTracker = require "initialized/vision_tracker"
local StealthManager = require "scripts/stealth_manager"
local FIFOQueue = require "util/fifoQueue"
local Pathfinding = require "util/pathfinding"

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
	Original.clearCaches = OldWargroove.clearCaches
	OldWargroove.clearCaches = WargrooveVision.clearCaches

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
	
	Original.setUnitState = OldWargroove.setUnitState
	OldWargroove.setUnitStateObject = WargrooveVision.setUnitStateObject
	
	Original.getUnitState = OldWargroove.getUnitState
	OldWargroove.getUnitStateObject = WargrooveVision.getUnitStateObject
end

function WargrooveVision.clearCaches()
    Original.clearCaches()
	Pathfinding.clearCaches()
end

function WargrooveVision.startCapture(attacker, defender, attackerPos)
	VisionTracker.removeUnitFromVisionMatrix(defender)
	Original.startCapture(attacker, defender, attackerPos)
	defender.playerId = attacker.playerId
	VisionTracker.addUnitToVisionMatrix(defender)
end

function WargrooveVision.spawnUnit(playerId, pos, unitType, turnSpent, startAnimation, startingState, factionOverride)  
	local unitId = Original.spawnUnit(playerId, pos, unitType, turnSpent, startAnimation, startingState, factionOverride)  
	if Pathfinding.withinBounds(pos) then
		OldWargroove.waitFrame()
		OldWargroove.waitFrame()
		local unit = OldWargroove.getUnitById(unitId)
		VisionTracker.addUnitToVisionMatrix(unit)
		--VisionTracker.getPrevPosList()[unitId] = pos
		StealthManager.removeUnit(unit)
		Original.updateUnit(unit)
	end
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

local function deepSetUnitState(unit, key, value)
    local value_type = type(value)
    if value_type == 'table' then
        for orig_key, orig_value in next, value, nil do
            deepSetUnitState(unit, tostring(key).."_"..tostring(orig_key), orig_value)
        end
    else -- number, string, boolean, etc
        Original.setUnitState(unit, key, value)
    end
end

local unitStateObjects = {}

function WargrooveVision.setUnitStateObject(unit, key, value)
    -- deepSetUnitState(unit, key, value)
	-- WargrooveVision.clearUnitStateObjectCache(unit.id, key)
	if unitStateObjects[unit.id]==nil then
		unitStateObjects[unit.id] = {}
	end
	unitStateObjects[unit.id][key] = value
end


local function deepGetUnitState(unit, key, state)
	local retValue = {}
	local trimmedState = {}
	local found = false
	for id, stateKey in pairs(state) do
		if (string.find(stateKey.key,"^"..key) ~= nil) then
			found = true
			table.insert(trimmedState,stateKey)
		else
			if found then
				break
			end
		end
	end
	for id, stateKey in pairs(trimmedState) do
		if stateKey.key == key then
			local value = Original.getUnitState(unit, key)
			return value
		end
		local noPrefix = string.sub(stateKey.key,string.len(key)+2,-1)
		local i,j = string.find(noPrefix,"_")
		if i == nil then
			i = string.len(noPrefix)+1
		end
		local newKey = string.sub(stateKey.key,1,string.len(key)+i)
		local internalKey = string.sub(stateKey.key,string.len(key)+2,string.len(key)+i)
		
		retValue[internalKey] = deepGetUnitState(unit, newKey, trimmedState)
	end
	return retValue
end

local cache = {}

function WargrooveVision.clearUnitStateObjectCache(unitId, key)
	if unitId == nil then
		cache = {}
		return
	end
	if (key == nil) and (cache~=nil) then
		cache[unitId] = {}
		return
	end
	if (cache~=nil) and (cache[unitId]~=nil) then
		cache[unitId][key] = nil
		return
	end
end
function WargrooveVision.getUnitStateObject(unit, key)
	if unitStateObjects[unit.id]~=nil then
		return unitStateObjects[unit.id][key]
	else
		return nil
	end
	-- if cache[unit.id]~=nil then
	-- 	if cache[unit.id][key]~=nil then
	-- 		return cache[unit.id][key]
	-- 	end
	-- else
	-- 	cache[unit] = {}
	-- end
	-- -- print("WargrooveVision.getUnitState(unit, key)")
	-- table.sort(unit.state, function(a,b) return a.key<b.key end)
	-- -- print(dump(unit.state,0))
	-- local value = deepGetUnitState(unit, key, unit.state)
	-- -- print("value table")
	-- -- print(dump(value,0))
	-- cache[unit][key] = value
    -- return value
end

return WargrooveVision
