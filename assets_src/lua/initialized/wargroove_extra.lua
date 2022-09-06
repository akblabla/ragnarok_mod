local OldWargroove = require "wargroove/wargroove"
--local VisionTracker = require "initialized/vision_tracker"

local WargrooveExtra = {}
local originalGetMapTriggers = {}
-- local originalSpawnUnit= {}
-- local originalUpdateUnit= {}
function WargrooveExtra.init()
	originalGetMapTriggers = OldWargroove.getMapTriggers
	OldWargroove.getMapTriggers = WargrooveExtra.getMapTriggers
	
	-- originalSpawnUnit = OldWargroove.spawnUnit
	-- OldWargroove.spawnUnit = WargrooveExtra.spawnUnit
	
	-- originalUpdateUnit = OldWargroove.updateUnit
	-- OldWargroove.updateUnit = WargrooveExtra.updateUnit
end

local hiddenTriggersStart = {}
local hiddenTriggersEnd = {}

function WargrooveExtra.addHiddenTrigger(trigger, atEnd)
	if atEnd == true then
		table.insert(hiddenTriggersEnd, trigger) 
	else
		table.insert(hiddenTriggersStart, trigger) 
	end
end

function WargrooveExtra.getMapTriggers()
	local originalTriggers = originalGetMapTriggers()
	local combinedTriggers = {}
	for i,v in ipairs(hiddenTriggersStart) do
		table.insert(combinedTriggers, v) 
	end
	for i,v in ipairs(originalTriggers) do
		table.insert(combinedTriggers, v) 
	end
	for i,v in ipairs(hiddenTriggersEnd) do
		table.insert(combinedTriggers, v) 
	end
    return combinedTriggers
end

-- function WargrooveExtra.spawnUnit(playerId, pos, unitType, turnSpent, startAnimation, startingState, factionOverride)  
	-- local unitId = originalSpawnUnit(playerId, pos, unitType, turnSpent, startAnimation, startingState, factionOverride)  
	-- local unit = Wargroove.getUnitById(unitId)
	-- local visibleTiles = VisionTracker.calculateVisionOfUnit(unit)
	-- local team = Wargroove.getPlayerTeam(playerId)
	-- for i, pos in pairs(visibleTiles) do
		-- incrementNumberOfViewers(team,pos)
	-- end
    -- return unitId
-- end


-- function WargrooveExtra.updateUnit(unit)
	-- local oldUnit = getUnitById(unit.id)
	-- local visibleTiles = VisionTracker.calculateVisionOfUnit(oldUnit)
	-- local team = Wargroove.getPlayerTeam(oldUnit.playerId)
	-- for i, pos in pairs(visibleTiles) do
		-- decrementNumberOfViewers(team,pos)
	-- end
    -- api.updateUnit(unit)
	-- visibleTiles = VisionTracker.calculateVisionOfUnit(unit)
	-- team = Wargroove.getPlayerTeam(unit.playerId)
	-- for i, pos in pairs(visibleTiles) do
		-- incrementNumberOfViewers(team,pos)
	-- end
    -- Wargroove.clearUnitPositionCache()
-- end

function dump(o,level)
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

return WargrooveExtra
