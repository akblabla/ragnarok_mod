local Wargroove = require "wargroove/wargroove"
local Verb = require "wargroove/verb"
local Combat = require "wargroove/combat"
local DefaultDeath = require "verbs/default_death"

local KrakenDeath = Verb:new()

function KrakenDeath:execute(unit, targetPos, strParam, path)
    DefaultDeath:execute(unit, targetPos, strParam, path)

    local targetId = Wargroove.getUnitState(unit, "targetId")

    if targetId ~= nil and targetId ~= "" then
        
        local tentaclePositionsString = Wargroove.getUnitState(unit, "tentacles")
        local tentaclePositions = Wargroove.stringToPositions(tentaclePositionsString)
        
        for i, pos in ipairs(tentaclePositions) do
            local tentacle = Wargroove.getUnitAt(pos)
            if tentacle ~= nil then
                tentacle:setHealth(0, tentacle.id)
                Wargroove.removeUnit(tentacle.id)
            end
        end
        
        local targetUnit = Wargroove.getUnitById(tonumber(targetId))

        if targetUnit ~= nil then
            targetUnit.tentacled = false
            Wargroove.deleteUnitEffectByAnimation(targetUnit.id, "units/kraken/cherrystone/map_kraken_tentacle_cherrystone", "")
            Wargroove.updateUnit(targetUnit)
        end
    end
end


return KrakenDeath
