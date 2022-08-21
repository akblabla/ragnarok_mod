local OldWargroove = require "wargroove/wargroove"

local WargrooveExtra = {}
local originalGetMapTriggers = {}
function WargrooveExtra.init()
	originalGetMapTriggers = OldWargroove.getMapTriggers
	OldWargroove.getMapTriggers = WargrooveExtra.getMapTriggers
end

local hiddenTriggersStart = {}
local hiddenTriggersEnd = {}

function WargrooveExtra.addHiddenTrigger(trigger, atEnd)
	print("addHiddenTrigger starts here")
	print(atEnd)
	if atEnd == true then
		print("placing trigger at end")
		table.insert(hiddenTriggersEnd, trigger) 
	else
		print("placing trigger at start")
		table.insert(hiddenTriggersStart, trigger) 
	end
end

function WargrooveExtra.getMapTriggers()
	print("getMapTriggers starts here")
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
	print(dump(combinedTriggers,0))
    return combinedTriggers
end

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
