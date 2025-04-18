local Wargroove = require "wargroove/wargroove"
local Verb = require "wargroove/verb"

local SmokeProducer = Verb:new()

local radius = 2

function SmokeProducer:execute(unit, targetPos, strParam, path)
    local posString = Wargroove.getUnitState(unit, "pos")
    local vals = {}
    for val in posString.gmatch(posString, "([^"..",".."]+)") do
        vals[#vals+1] = val
    end
    local center = { x = tonumber(vals[1]), y = tonumber(vals[2])}

    local smokePositions = Wargroove.getTargetsInRange(center, radius, "all")
    for i, pos in ipairs(smokePositions) do
        Wargroove.playMapSound("vesper/vesperGrooveEnd", center)
        Wargroove.playBuffVisualEffectSequenceOnce(unit.id, pos, "units/commanders/vesper/smoke", "despawn")
        Wargroove.playBuffVisualEffectSequenceOnce(unit.id, pos, "units/commanders/vesper/smoke_back", "despawn")
        Wargroove.playBuffVisualEffectSequenceOnce(unit.id, pos, "units/commanders/vesper/smoke_front", "despawn")

    end
    Wargroove.waitTime(1.2)
end

return SmokeProducer