local Wargroove = require "wargroove/wargroove"
local Verb = require "wargroove/verb"

local Die = Verb:new()

function Die:canExecuteAt(unit, endPos)
    return true
end

function Die:execute(unit, targetPos, strParam, path)
    Wargroove.spawnPaletteSwappedMapAnimation(path[#path], 0, "fx/ambush_fx", unit.playerId, "default", "over_units", { x = 12, y = 0 })
    Wargroove.playMapSound("cutscene/surprised", path[#path])
    Wargroove.waitTime(1.0)

    if strParam == "die" then
        unit:setHealth(0, unit.id)
        Wargroove.updateUnit(unit)
    end

    Wargroove.setUnitState(unit, "ambushed", "true")
    Wargroove.updateUnit(unit)
end

function Die:onPostUpdateUnit(unit, targetPos, strParam, path)
    Verb.onPostUpdateUnit(self, unit, targetPos, strParam, path)

    if (Wargroove.getNetworkVersion() == '200000') then
        return
    end

    if (unit.health > 0) then
        unit.pos = targetPos
    end
end

return Die
