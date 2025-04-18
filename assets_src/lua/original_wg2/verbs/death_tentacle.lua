local Wargroove = require "wargroove/wargroove"
local Verb = require "wargroove/verb"
local Combat = require "wargroove/combat"

local TentacleDeath = Verb:new()

function TentacleDeath:execute(unit, targetPos, strParam, path)
    local attacker = Wargroove.getUnitById(tonumber(strParam))

    local krakenId = Wargroove.getUnitState(unit, "parentId")
    local kraken = Wargroove.getUnitById(tonumber(krakenId))
    local targetId = Wargroove.getUnitState(kraken, "targetId")
    local targetUnit = Wargroove.getUnitById(tonumber(targetId))

    print("Kraken ID: " .. krakenId)
    print(Wargroove.tableToString(kraken))

    local tentaclePositionsString = Wargroove.getUnitState(kraken, "tentacles")
    local tentaclePositions = Wargroove.stringToPositions(tentaclePositionsString)

    for i, pos in ipairs(tentaclePositions) do
        local tentacle = Wargroove.getUnitAt(pos)

        tentacle:setHealth(0, tentacle.id)
        Wargroove.removeUnit(tentacle.id)
    end

    targetUnit.tentacled = false
    Wargroove.updateUnit(targetUnit)

    if attacker ~= nil then
        local damage, hadPassive = Combat:getDamage(attacker, kraken, "random", false, attacker.pos, kraken.pos, path, false, nil)
        if damage ~= nil then
            kraken:setHealth(kraken.health - damage, attacker.id)
            Wargroove.playUnitAnimation(kraken.id, "hit")
        else
            print("failed to calculate kraken damage in TentacleDeath")
        end
    end

    Wargroove.setUnitState(kraken, "tentacles", "")
    Wargroove.setUnitState(kraken, "targetId", nil)
    Wargroove.updateUnit(kraken)
end


return TentacleDeath
