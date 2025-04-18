local Wargroove = require "wargroove/wargroove"
local Verb = require "wargroove/verb"

local Fly = Verb:new()

function Fly:canExecuteAnywhere(unit)
    return unit.unitClassId == "griffin_walking"
end

function Fly:execute(unit, targetPos, strParam, path)
    Wargroove.playUnitAnimation(unit.id, "takeoff")
    Wargroove.waitTime(0.5)

    unit.unitClassId = "griffin_flying"
    Wargroove.updateUnit(unit)

    Wargroove.waitTime(0.2)
end

return Fly