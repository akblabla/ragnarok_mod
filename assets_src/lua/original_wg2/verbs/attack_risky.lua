local Wargroove = require "wargroove/wargroove"
local Combat = require "wargroove/combat"
local Attack = require "verbs/attack"

local AttackRisky = Attack:new()

function AttackRisky:execute(unit, targetPos, strParam, path)
    --- Telegraph
    if (not Wargroove.isLocalPlayer(unit.playerId)) and Wargroove.canCurrentlySeeTile(targetPos) then
        Wargroove.spawnMapAnimation(targetPos, 0, "ui/grid/selection_cursor", "target", "over_units", {x = -4, y = -4})
        Wargroove.waitTime(0.5)
    end

    local target = Wargroove.getUnitAt(targetPos)
    Wargroove.startCombat(unit, target, path, "random")
end

return AttackRisky
