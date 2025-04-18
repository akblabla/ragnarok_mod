local Wargroove = require "wargroove/wargroove"
local Verb = require "wargroove/verb"
local Combat = require "wargroove/combat"
local DefaultDeath = require "verbs/default_death"

local OrganDeath = Verb:new()

local function getDirection(unit)
    -- { ["y"] = 13,["x"] = 17,["facing"] = 0,}
    -- { ["y"] = 21,["x"] = 25,["facing"] = 0,}
    -- { ["y"] = 21,["x"] = 9,["facing"] = 0,}
    if unit.pos.y < 18 then
        return "down"
    elseif unit.pos.x > 20 then
        return "right"
    elseif unit.pos.x < 15 then
        return "left"
    end

    return "up"
end

function OrganDeath:execute(unit, targetPos, strParam, path)
    local facing = getDirection(unit)

    -- Clear any existing highlights to avoid overlap
    local highlightLocation = Wargroove.getLocationByName("boss_attack_area_" .. facing)
    Wargroove.highlightLocation(highlightLocation.id, "none", "red", false, false, false, false)
    local safeLocation = Wargroove.getLocationByName("boss_safe_area_" .. facing)
    Wargroove.highlightLocation(safeLocation.id, "none", "red", false, false, false, false)

    if unit.unitClassId == "organ" then
        Wargroove.spawnUnit(-1, unit.pos, "organ_destroyed", false, "deactivate", nil, nil, nil, nil, unit.pos.facing)
    else
        Wargroove.spawnUnit(-1, unit.pos, "organ_up_destroyed", false, "deactivate")
    end
    Wargroove.removeUnit(unit.id)
end


return OrganDeath
