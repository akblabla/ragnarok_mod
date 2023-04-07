local Wargroove = require "wargroove/wargroove"
local Ragnarok = require "initialized/ragnarok"
local io = require("io")
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
	Ragnarok.addAction(Logger.logState,"repeating",true)
end
function Logger.logState(context)
	if (not context:checkState("endOfTurn")) then
		return
	end
	local file = io.open("Mission Log.txt","w")
	if file == nil then
		return
	end
	local function printLine(file,msg)
		file:write(msg)
		file:write("\n")
	end
	local playerId = Wargroove.getCurrentPlayerId();
	printLine(file,"\n--------------------------------------------")
	printLine(file,"Current Turn: "..tostring(Wargroove.getTurnNumber()))
	printLine(file,"Current Player: "..tostring(playerId))
	printLine(file,"Current Player is Human: "..tostring(Wargroove.isHuman(playerId)))
	printLine(file,"\nMap Flags")
	printLine(file,dump(context.mapFlags,0))
	printLine(file,"\nMap Counters")
	printLine(file,dump(context.mapCounters,0))
	local allUnits = Wargroove.getUnitsAtLocation()
	printLine(file,"\nAll Units")
	for i,unit in pairs(allUnits) do
		printLine(file,"class: "..unit.unitClassId)
		printLine(file,"\towner: "..unit.playerId)
		printLine(file,"\thealth: "..tostring(unit.health))
		printLine(file,"\tpos: "..tostring(unit.pos.x)..", "..tostring(unit.pos.y))
	end
	printLine(file,"--------------------------------------------\n")
	file:close()
end

return Logger
