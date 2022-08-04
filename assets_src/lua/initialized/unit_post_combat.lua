local Wargroove = require "wargroove/wargroove"
local OldUnitPostCombat = require "wargroove/unit_post_combat"

local UnitPostCombat = {}
local PostCombat = {}
local classMap = {}

function UnitPostCombat.init()
  -- OldUnitPostCombat.getPostCombat = UnitPostCombat.getPostCombat
  -- OldUnitPostCombat.addPostCombat = UnitPostCombat.addPostCombat
  -- --classMap[1] = UnitPostCombat.piratePostCombat
  -- PostCombat["pirate_ship"] = UnitPostCombat.piratePostCombat
end



function UnitPostCombat:getPostCombat(unitClassId)
	-- local function locate( table, value )
		-- for i = 1, #table do
			-- if table[i] == value then return i end
		-- end
		-- return nil
	-- end
	-- local mapId = locate(classMap, unitClassId)
	-- if mapId == nil then
		-- return nil
	-- end
    -- return PostCombat[mapId]
    return PostCombat[unitClassId]
	
end

function UnitPostCombat:addPostCombat(unitClassId, callbackFunction)
	-- classMap(
    PostCombat[unitClassId] = callbackFunction
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

function UnitPostCombat:piratePostCombat(wargroove, unit, isAttacker)
	local defenderPos = wargroove.pos;
	defenderPos.x = defenderPos.x+1;
	local defender = Wargroove.getUnitAt(defenderPos);
	if defender == nil then
		Wargroove.spawnUnit(wargroove.playerId, wargroove.pos, wargroove.unitClassId, false, "")
	else
		print(dump(defender,1))
	end
	
end

return UnitPostCombat