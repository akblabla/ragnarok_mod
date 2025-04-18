local Wargroove = require "wargroove/wargroove"
local ItemVerb = require "wargroove/item_verb"

local Timeshifter = ItemVerb:new()

function Timeshifter:getMaximumRange(unit, endPos)
    return 0
end


function Timeshifter:getTargetType()
    return "unit"
end

function Timeshifter:execute(unit, targetPos, strParam, path)
    Wargroove.playPositionlessSound("battleStart")

    Wargroove.playUnitAnimation(unit.id, "groove")

    Wargroove.spawnMapAnimation(unit.pos, 1, "fx/groove/caesar_groove_fx")
    Wargroove.waitTime(1.9)

    Wargroove.playGrooveEffect()

    for i, u in ipairs(Wargroove.getAllUnitsForPlayer(unit.playerId, true)) do
        if Wargroove.areAllies(u.playerId, unit.playerId) then
            Wargroove.spawnMapAnimation(u.pos, 0, "fx/groove/inspire_unit")
            if u.hadTurn then
                u.hadTurn = false
                Wargroove.updateUnit(u)
            end
        end
    end

    Wargroove.waitTime(1.0)
end

return Timeshifter
