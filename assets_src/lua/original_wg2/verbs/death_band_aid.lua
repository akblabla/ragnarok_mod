local Wargroove = require "wargroove/wargroove"
local Verb = require "wargroove/verb"

local BandAid = Verb:new()

function BandAid:execute(unit, targetPos, strParam, path)
    if (unit.killedByLosing) then
        return
    end
    
    local targetId = tonumber(Wargroove.getUnitState(unit, "unitId"))
    local currentAge = tonumber(Wargroove.getUnitState(unit, "age"))

    local target = Wargroove.getUnitById(targetId)

    if not target then
        return
    end

    Wargroove.waitTime(0.2)

    target:setHealth(target.health + 10, target.id)
    Wargroove.updateUnit(target)
    Wargroove.spawnMapAnimation(target.pos, 0, "fx/heal_unit", "default", "over_units", { x = 12, y = 12 })
    Wargroove.playMapSound("unitHealed", target.pos)

    if currentAge == 3 then
        Wargroove.clearBuffVisualEffect(targetId)
        return
    end

    local startingState = {}
    local tUnitId = {key = "unitId", value = tostring(targetId)}
    local tAge = {key = "age", value = tostring(currentAge + 1)}    
    table.insert(startingState, tUnitId)
    table.insert(startingState, tAge)
    Wargroove.spawnUnit(unit.playerId, {x = -100, y = -100}, "band_aid", false, "", startingState)

    Wargroove.waitTime(0.2)
end

return BandAid
