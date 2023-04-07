local Wargroove = require "wargroove/wargroove"
local Ragnarok = require "initialized/ragnarok"

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

local Logger = {}
function Logger.init()
--	Ragnarok.addAction(Logger.logState,"repeating",true)
end
function Logger.logState(context)
	if (not context:checkState("endOfTurn")) then
		return
	end
	local playerId = Wargroove.getCurrentPlayerId();
	print("\n--------------------------------------------")
	print("Current Turn: "..tostring(Wargroove.getTurnNumber()))
	print("Current Player: "..tostring(playerId))
	print("Current Player is Human: "..tostring(Wargroove.isHuman(playerId)))
	print("\nMap Flags")
	print(dump(context.mapFlags,0))
	print("\nMap Counters")
	print(dump(context.mapCounters,0))
	local allUnits = Wargroove.getUnitsAtLocation()
	print("\nAll Units")
	for i,unit in pairs(allUnits) do
		print("class: "..unit.unitClassId)
		print("\towner: "..unit.playerId)
		print("\thealth: "..tostring(unit.health))
		print("\tpos: "..tostring(unit.pos.x)..", "..tostring(unit.pos.y))
	end
	print("--------------------------------------------\n")
	
end

return Logger
