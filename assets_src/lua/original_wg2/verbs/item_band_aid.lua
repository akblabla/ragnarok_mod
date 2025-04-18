local Wargroove = require "wargroove/wargroove"
local ItemVerb = require "wargroove/item_verb"

local BandAid = ItemVerb:new()

function BandAid:getMaximumRange(unit, endPos)
    return 0
end


function BandAid:getTargetType()
    return "unit"
end

function BandAid:execute(unit, targetPos, strParam, path)
    local startingState = {}
    local unitId = {key = "unitId", value = tostring(unit.id)}
    local age = {key = "age", value = "1"}    
    table.insert(startingState, unitId)
    table.insert(startingState, age)
    Wargroove.spawnUnit(unit.playerId, {x = -100, y = -100}, "band_aid", false, "", startingState)

    Wargroove.spawnMapAnimation(unit.pos, 0, "fx/reinforce_1", "default", "over_units", { x = 12, y = 0 })
    Wargroove.playMapSound("reinforceStructureDrain", unit.pos)

    Wargroove.waitTime(0.5)

    unit:setHealth(unit.health + 10, unit.id)
    Wargroove.updateUnit(unit)
    Wargroove.spawnMapAnimation(unit.pos, 0, "fx/heal_unit", "default", "over_units", { x = 12, y = 12 })
    Wargroove.playMapSound("unitHealed", unit.pos)
end

return BandAid
