local OldDeathTentacle = require "verbs/death_tentacle"
local Wargroove = require "wargroove/wargroove"
local DeathTentacleNew = {}

function DeathTentacleNew.init()
    OldDeathTentacle.execute = DeathTentacleNew.execute
end

function DeathTentacleNew:execute(unit, targetPos, strParam, path)
    local attacker = Wargroove.getUnitById(tonumber(strParam))

    local krakenId = Wargroove.getUnitState(unit, "parentId")
    local kraken = Wargroove.getUnitById(tonumber(krakenId))
    local targetId = Wargroove.getUnitState(kraken, "targetId")
    local targetUnit = Wargroove.getUnitById(tonumber(targetId))

    local tentaclePositionsString = Wargroove.getUnitState(kraken, "tentacles")
    local tentaclePositions = Wargroove.stringToPositions(tentaclePositionsString)
    for i, pos in ipairs(tentaclePositions) do
        local tentacle = Wargroove.getUnitAt(pos)
        if tentacle then
            tentacle:setHealth(0, tentacle.id)
            Wargroove.removeUnit(tentacle.id)
        end
    end
    targetUnit.tentacled = false
    Wargroove.deleteUnitEffectByAnimation(targetUnit.id, "units/kraken/cherrystone/map_kraken_tentacle_cherrystone", "")
    Wargroove.updateUnit(targetUnit)
    if attacker ~= nil then
        local damage = 10
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

    Wargroove.playUnitAnimation(krakenId, "idle")
end


function Wargroove.untangleKraken(unit)
    local targetId = tonumber(Wargroove.getUnitState(unit, "targetId"))
    if not targetId then
        return
    end

    local targetUnit = Wargroove.getUnitById(tonumber(targetId))
    if (targetUnit and not targetUnit.tentacled) or not targetUnit then
        return
    end

    local tentaclePositionsString = Wargroove.getUnitState(unit, "tentacles")
    local tentaclePositions = Wargroove.stringToPositions(tentaclePositionsString)

    for i, pos in ipairs(tentaclePositions) do
        local tentacle = Wargroove.getUnitAt(pos)
        if tentacle~=nil then
            tentacle:setHealth(0, tentacle.id, true)
            Wargroove.removeUnit(tentacle.id)
        end
    end

    -- TODO: Add untangle animation
    
end

return DeathTentacleNew