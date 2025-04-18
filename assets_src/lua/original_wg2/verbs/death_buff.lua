local Wargroove = require "wargroove/wargroove"
local Verb = require "wargroove/verb"
local UnitBuffDeaths = require "wargroove/unit_buff_deaths"

local DeathBuff = Verb:new()

function DeathBuff:execute(unit, targetPos, strParam, path)
    -- this is just a shell for making buffs more generic
    local turnCount = tonumber(Wargroove.getUnitState(unit, "turnCount"))
    turnCount = turnCount - 1

    if turnCount <= 0 then
        -- The buff is finished
        local buffDeaths = UnitBuffDeaths:getBuffDeaths()
        local buffDeathId = Wargroove.getUnitState(unit, "buffDeathId")
        local unitId = Wargroove.getUnitState(unit, "unitId")
        local buffUnit = Wargroove.getUnitById(tonumber(unitId))
        if buffDeathId and buffDeathId ~= "" then
            local buffDeath = buffDeaths[buffDeathId]
            if buffDeath then
                buffDeath(Wargroove, buffUnit)
                coroutine.yield()
            end
        end
    else
        -- Respawn buff with adjusted starting state but don't retrigger spawns
        Wargroove.setUnitState(unit, "turnCount", ""..turnCount)
        Wargroove.spawnUnit(unit.playerId, {x = -100, y = -100}, "buff", false, "", unit.state, "", true)
    end
end

return DeathBuff