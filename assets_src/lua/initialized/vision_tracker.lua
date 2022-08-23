local Wargroove = require "wargroove/wargroove"

local VisionTracker = {}
function VisionTracker.init()
	local initializeVisionTrigger = {
		id = "Initialize Vision List",
		recurring = "repeat",
		actions = {
			{
				id = "reset_occurence_list",
				parameters = {
				}
			}
		},
		conditions = {},
		players = {1, 0, 0, 0, 0, 0, 0, 0}
	}
	--Ragnarok.addHiddenTrigger(initializeVisionTrigger,true)
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

return VisionTracker
