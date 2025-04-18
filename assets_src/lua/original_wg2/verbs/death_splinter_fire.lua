local Wargroove = require "wargroove/wargroove"
local Verb = require "wargroove/verb"

local SplinterFire = Verb:new()

local damageAmount = 20

function SplinterFire:execute(unit, targetPos, strParam, path)
    local targetsStr = Wargroove.getUnitState(unit, "targets")
    local targets = Wargroove.stringToUnitIds(targetsStr)

    print(Wargroove.tableToString(targets))

    if targets and #targets >= 1 then
        for _, unitId in ipairs(targets) do
            local u = Wargroove.getUnitById(unitId)

            if u then
                local isPoisoned = Wargroove.getUnitState(u, "poisoned")

                if u and isPoisoned == "true" and u.health > 0 and (u.playerId ~= -1) and u.damageTakenPercent > 0 then
                    Wargroove.trackCameraTo(u.pos)
                    Wargroove.waitTime(0.5)

                    Wargroove.setUnitState(u, "poisoned", "false")
                    Wargroove.updateUnit(u)

                    Wargroove.clearBuffVisualEffect(unitId)
                    Wargroove.waitTime(0.2)
                end
            end
        end
    end

    Wargroove.waitTime(0.5)
end

return SplinterFire
