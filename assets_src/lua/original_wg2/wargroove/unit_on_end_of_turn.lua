local UnitOnEndOfTurn = {}

local OnEndOfTurn = {}

function OnEndOfTurn.soldier(Wargroove, unit)   
    local boosted = Wargroove.getUnitState(unit, "boosted")
    if boosted ~= nil and boosted ~= "" then
        Wargroove.popUnitClassModifier(unit.id, boosted)
        Wargroove.setUnitState(unit, "boosted", "")
        Wargroove.updateUnit(unit)
    end
end


function UnitOnEndOfTurn:getOnEndOfTurn(unitClassId)
    return OnEndOfTurn[unitClassId]
end


return UnitOnEndOfTurn