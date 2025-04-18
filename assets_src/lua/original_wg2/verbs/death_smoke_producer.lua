local Wargroove = require "wargroove/wargroove"
local Verb = require "wargroove/verb"

local SmokeProducer = Verb:new()

function SmokeProducer:execute(unit, targetPos, strParam, path)
    local smokeAnim = {"smoke_small", "smoke_medium", "smoke_large"}
    local smokeRadius = {2, 2}
    local posString = Wargroove.getUnitState(unit, "pos")
    local tier = tonumber(Wargroove.getUnitState(unit, "tier"))

    local vals = {}
    for val in posString.gmatch(posString, "([^"..",".."]+)") do
        vals[#vals+1] = val
    end
    local center = { x = tonumber(vals[1]), y = tonumber(vals[2])}

    local smokePositions = Wargroove.getTargetsInRange(center, smokeRadius[tier], "all")
    for i, pos in ipairs(smokePositions) do
        local targetUnit = Wargroove.getUnitAt(pos)
        if targetUnit then
            targetUnit.canBeAttacked = true
            Wargroove.setUnitState(targetUnit, "smokeScreened", "false")
            Wargroove.updateUnit(targetUnit)
        end

        Wargroove.playMapSound("vesper/vesperGrooveEnd", center)
        Wargroove.playBuffVisualEffectSequenceOnce(unit.id, pos, "units/commanders/vesper/"..smokeAnim[tier], "despawn")
        Wargroove.playBuffVisualEffectSequenceOnce(unit.id, pos, "units/commanders/vesper/smoke_back", "despawn")
        Wargroove.playBuffVisualEffectSequenceOnce(unit.id, pos, "units/commanders/vesper/smoke_front", "despawn")
    end
    print("death_smoke deeeeeeead")
    Wargroove.waitTime(1.2)
end

return SmokeProducer