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
    print("SmokeScreen:execute(unit, targetPos, strParam, path)")
    Wargroove.setIsUsingGroove(unit.id, true)
    print(1)
    Wargroove.updateUnit(unit)
    print(2)
    
    Wargroove.playPositionlessSound("battleStart")
    print(3)
    Wargroove.playGrooveCutscene(unit.id)
    print(4)

    Wargroove.playUnitAnimation(unit.id, "groove")
    print(5)
    Wargroove.playMapSound("vesper/vesperGroove", unit.pos)
    print(6)
    Wargroove.waitTime(1.0)
    print(7)
    Wargroove.playMapSound("cutscene/smokeBomb", targetPos)
    print(8)
    Wargroove.spawnMapAnimation(targetPos, 3, "fx/groove/vesper_groove_fx", "idle", "over_units", {x = 12, y = 12})
    print(9)

    Wargroove.playGrooveEffect()
    print(10)

    local startingState = {}
    print(11)
    local pos = {key = "pos", value = "" .. targetPos.x .. "," .. targetPos.y}
    print(12)
    table.insert(startingState, pos)
    print(13)
    print(unit.playerId)
    print(dump(startingState,0))
    Wargroove.spawnUnit(1, {x = -100, y = -100}, "smoke_producer", false, "", startingState)
    print(14)

    Wargroove.waitTime(1.0)
end

return SmokeScreen
