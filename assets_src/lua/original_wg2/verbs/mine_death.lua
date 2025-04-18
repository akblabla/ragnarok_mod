local Wargroove = require "wargroove/wargroove"
local Verb = require "wargroove/verb"
local Combat = require "wargroove/combat"
local DefaultDeath = require "verbs/default_death"

local MineDeath = Verb:new()

function MineDeath:execute(unit, targetPos, strParam, path)
    DefaultDeath:execute(unit, targetPos, strParam, path)

    if tonumber(strParam) == unit.id then
        return
    end

    print("Mine Death!")

    Wargroove.spawnMapAnimation(unit.pos, 1, "fx/groove/koji_groove_fx", "idle", "behind_units", { x = 12, y = 12 })

    Wargroove.playUnitAnimationOnce(unit.id, "explode")
    Wargroove.playMapSound("koji/kojiDroneExplode", unit.pos)

    unit:setHealth(0, unit.id)
    Wargroove.updateUnit(unit)

    Wargroove.waitTime(0.2)
end


return MineDeath
