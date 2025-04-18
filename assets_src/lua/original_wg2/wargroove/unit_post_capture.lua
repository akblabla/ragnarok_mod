local Resumable = require("wargroove/resumable")

local UnitPostCapture = {}

local PostCapture = {}

function PostCapture.crystal_struct(Wargroove, unit, capturer, playerId)
    return Resumable.run(function ()
        local range = 3
        local effectPositions = Wargroove.getTargetsInRange(unit.pos, range, "all")

        Wargroove.clearBuffVisualEffect(unit.id)
        Wargroove.displayBuffVisualEffect(unit.id, playerId, "units/commanders/emeric/crystal_aura", "spawn", 0.3, effectPositions, "", {}, false, true)

        Wargroove.waitTime(1.2)

        unit.playerId = playerId
    end)
end

function PostCapture.golem(Wargroove, unit, capturer, playerId)
    return Resumable.run(function ()
        -- Prevent recapture by same faction
        if unit.hadTurn then
            unit.unitClassId = "golem"
            unit.playerId = -1
        else
            unit.unitClassId = "golem_unit"
            unit.playerId = playerId
            unit:setHealth(100, capturer.id)

            Wargroove.playMapSound("guardianActivate", unit.pos)

            Wargroove.playUnitAnimation(unit.id, "activate", "activated")
            Wargroove.waitTime(0.7)
        end

        unit.hadTurn = true
        Wargroove.updateUnit(unit)
    end)
end

function PostCapture.portal_neutral(Wargroove, unit, capturer, playerId)
    return Resumable.run(function ()
        unit.unitClassId = "portal"
        unit.playerId = playerId
        unit.hadTurn = true

        Wargroove.updateUnit(unit)
        Wargroove.waitTime(0.1)
    end)
end

function UnitPostCapture:getPostCapture(unitClassId)
    return PostCapture[unitClassId]
end

return UnitPostCapture