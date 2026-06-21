local Wargroove = require "wargroove/wargroove"
local OriginalPassiveConditions = require "wargroove/passive_conditions"


local PassiveConditions = {}

-- This is called by the game when the map is loaded.
function PassiveConditions.init()
    OriginalPassiveConditions:getPassiveConditions().merman = PassiveConditions.merman
    OriginalPassiveConditions:getPassiveConditions().harpoonship = PassiveConditions.harpoonship
    OriginalPassiveConditions:getPassiveConditions().warship = PassiveConditions.warship
	OriginalPassiveConditions:getPassiveConditions().dragon = PassiveConditions.dragon
	OriginalPassiveConditions:getPassiveConditions().griffin_walking = PassiveConditions.griffin_walking
	OriginalPassiveConditions:getPassiveConditions().kraken = PassiveConditions.kraken
	OriginalPassiveConditions:getPassiveConditions().frog = PassiveConditions.frog
	OriginalPassiveConditions:getPassiveConditions().rival = PassiveConditions.rival
	
end

function PassiveConditions.merman(payload)
    return Wargroove.canStandAt("caravel", payload.attackerPos)
end

function PassiveConditions.harpoonship(payload)
    local terrainName = Wargroove.getTerrainNameAt(payload.attackerPos)
    return terrainName == "reef" or terrainName == "cave_reef"
end

function PassiveConditions.warship(payload)
    local terrainName = Wargroove.getTerrainNameAt(payload.attackerPos)
    return terrainName == "beach" or terrainName == "cave_beach"
end

function PassiveConditions.rival(payload)
    if payload.isCounter then
        return false
    end
    local function isSame(a, b)
        return a.x == b.x and a.y == b.y
    end
    return payload.path == nil or (#payload.path == 0) or isSame(payload.attacker.startPos, payload.path[#payload.path])
end

function PassiveConditions.dragon(payload)
    local terrainName = Wargroove.getTerrainNameAt(payload.defenderPos)
    if Wargroove.getUnitClass(payload.defender.unitClassId).isStructure then
        return false
    end
    return (terrainName == "road") or (terrainName == "street") or (terrainName == "cave_road")
end

function PassiveConditions.griffin_walking(payload)
    local direction = { x = payload.attackerPos.x - payload.defenderPos.x, y = payload.attackerPos.y - payload.defenderPos.y }
    local beyond = { x = payload.defenderPos.x - direction.x, y = payload.defenderPos.y - direction.y }

    local unit = Wargroove.getUnitAt(beyond)

    if unit and unit.id ~= payload.attacker.id and (not unit.unitClass.isStructure) and Wargroove.areAllies(payload.attacker.playerId, unit.playerId) then
        return true
    end

    return false
end
function PassiveConditions.frog(payload)
    local terrainName = Wargroove.getTerrainNameAt(payload.defenderPos)
    if Wargroove.getUnitClass(payload.defender.unitClassId).isStructure then
        return false
    end
    return terrainName == "beach" or terrainName == "river" or terrainName == "cave_beach" or terrainName == "cave_river" or terrainName == "mangrove"
end


function PassiveConditions.kraken(payload)
    local units = Wargroove.getAllUnitsForPlayer(payload.defender.playerId, true)

    for i, v in ipairs(units) do
        if v.id ~= payload.defender.id then
            local distance = math.abs(v.pos.x - payload.defenderPos.x) + math.abs(v.pos.y - payload.defenderPos.y)
            if distance == 1 then
                return false
            end
        end
    end
    return true
end

return PassiveConditions