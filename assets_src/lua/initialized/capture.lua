local Wargroove = require "wargroove/wargroove"
local OldCapture = require "verbs/capture"
local Verb = require "initialized/a_new_verb"


local Capture = {}
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
function Capture.init()
    print("OldCapture.canExecuteAt = Capture.canExecuteAt")
	OldCapture.canExecuteAt = Capture.canExecuteAt
	
end

function Capture:canExecuteAt(unit)
    print("Custom Capture:canExecuteAt is being executed")
    print("unit")
    print(dump(unit,0))
    local state = Wargroove.getUnitState(unit, "canCapture")
    if (state ~= nil) and (state == "false") then
        print("  No")
        return false
    end
    print("  Yes")
    return true
end

return Capture
