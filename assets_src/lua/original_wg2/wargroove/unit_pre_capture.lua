local Resumable = require("wargroove/resumable")

local UnitPreCapture = {}

local PreCapture = {}

function PreCapture.griffin_flying(Wargroove, unit, playerId)
    unit.unitClassId = "griffin_walking"
    unit.hadTurn = true
    Wargroove.updateUnit(unit)
end

function UnitPreCapture:getPreCapture(unitClassId)
    return PreCapture[unitClassId]
end

return UnitPreCapture