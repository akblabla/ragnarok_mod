local Wargroove = require "wargroove/wargroove"
local Combat = require "wargroove/combat"
local Attack = require "verbs/attack"

local AttackCrazy = Attack:new()

function AttackCrazy:execute(unit, targetPos, strParam, path)
    --- Telegraph
    if (not Wargroove.isLocalPlayer(unit.playerId)) and Wargroove.canCurrentlySeeTile(targetPos) then
        Wargroove.spawnMapAnimation(targetPos, 0, "ui/grid/selection_cursor", "target", "over_units", {x = -4, y = -4})
        Wargroove.waitTime(0.5)
    end

    local target = Wargroove.getUnitAt(targetPos)
    Wargroove.startCombat(unit, target, path, "crazy")
end

return AttackCrazy
