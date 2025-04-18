local Wargroove = require "wargroove/wargroove"
local Verb = require "wargroove/verb"
local Combat = require "wargroove/combat"
local MineExplode = require "verbs/mine_explode"

local MineTrigger = Verb:new()

function MineTrigger:execute(unit, targetPos, strParam, path)
    

    Wargroove.spawnPaletteSwappedMapAnimation(path[#path], 0, "fx/ambush_fx", unit.playerId, "default", "over_units", { x = 12, y = 0 })
    Wargroove.playMapSound("cutscene/surprised", path[#path])

    for i, pos in ipairs(Wargroove.getTargetsInRange(path[#path], 1, "unit")) do
        local u = Wargroove.getUnitAt(pos)

        if Wargroove.areEnemies(u.playerId, unit.playerId) and u.unitClassId == "mine" then
            Wargroove.setVisibleOverride(u.id, true)

            MineExplode:execute(u, path[#path], "", nil)
        end
    end

    Wargroove.waitTime(0.2)
end

return MineTrigger
