local Wargroove = require "wargroove/wargroove"
local Verb = require "wargroove/verb"

local Land = Verb:new()

function Land:canExecuteAnywhere(unit)
    if unit.unitClassId ~= "griffin_flying" then
        return false
    end

    return true
end

function Land:canExecuteAt(unit, endPos)
    if not self:canSeeTarget(endPos) then
        return false
    end

    local terrainName = Wargroove.getTerrainNameAt(endPos)
    if  terrainName == "ocean" or terrainName == "reef" or terrainName == "sea" or terrainName == "mountain" then
        return false
    end

    return true
end

function Land:execute(unit, targetPos, strParam, path)
    Wargroove.playUnitAnimation(unit.id, "touchdown")
    Wargroove.waitTime(0.5)

    unit.unitClassId = "griffin_walking"
    Wargroove.updateUnit(unit)

    Wargroove.waitTime(0.2)
end

return Land