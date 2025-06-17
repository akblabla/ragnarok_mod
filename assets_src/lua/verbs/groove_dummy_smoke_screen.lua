local Wargroove = require "wargroove/wargroove"
local GrooveVerb = require "wargroove/groove_verb"

local SmokeScreen = GrooveVerb:new()

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
function SmokeScreen:execute(unit, targetPos, strParam, path)
    Wargroove.setIsUsingGroove(unit.id, true)
    Wargroove.updateUnit(unit)
    
    Wargroove.playPositionlessSound("battleStart")
    Wargroove.playGrooveCutscene(unit.id)
    Wargroove.playUnitAnimation(unit.id, "groove")
    Wargroove.playMapSound("vesper/vesperGroove", unit.pos)
    Wargroove.waitTime(1.0)
    Wargroove.playMapSound("cutscene/smokeBomb", targetPos)
    Wargroove.spawnMapAnimation(targetPos, 3, "fx/groove/vesper_groove_fx", "idle", "over_units", {x = 12, y = 12})

    Wargroove.playGrooveEffect()

    local startingState = {}
    local pos = {key = "pos", value = "" .. targetPos.x .. "," .. targetPos.y}
    table.insert(startingState, pos)
    Wargroove.spawnUnit(1, {x = -100, y = -100}, "smoke_producer", false, "", startingState)

    Wargroove.waitTime(1.0)
end

return SmokeScreen
