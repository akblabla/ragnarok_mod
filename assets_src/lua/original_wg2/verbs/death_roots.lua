local Wargroove = require "wargroove/wargroove"
local Verb = require "wargroove/verb"

local DeathThornyRoots = Verb:new()

function DeathThornyRoots:execute(unit, targetPos, strParam, path)
    local targetId = Wargroove.getUnitState(unit, "unitId")
    local targetUnit = Wargroove.getUnitById(tonumber(targetId))

    if targetUnit then
        local isRooted = Wargroove.getUnitState(targetUnit, "rooted")

        if isRooted == "true" and targetUnit.health > 0 and (targetUnit.playerId ~= -1) and targetUnit.damageTakenPercent > 0 then
            Wargroove.setUnitState(targetUnit, "rooted", "false")
            Wargroove.updateUnit(targetUnit)

            -- Otherwise won't properly clear, unit updates need time to propagate through the system
            Wargroove.waitTime(0.01)
            Wargroove.clearBuffVisualEffect(targetUnit.id)
        end
    end

    Wargroove.waitTime(0.5)
end

return DeathThornyRoots
