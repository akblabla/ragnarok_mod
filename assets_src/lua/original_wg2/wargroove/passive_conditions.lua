local PassiveConditions = {}
local Wargroove = require "wargroove/wargroove"

local neighbours = { {x = -1, y = 0}, {x = 1, y = 0}, {x = 0, y = -1}, {x = 0, y = 1} }

local function getNeighbour(pos, i)
    local n = neighbours[i]
    return Wargroove.getUnitAt({ x = n.x + pos.x, y = n.y + pos.y })
end


local Conditions = {}

function Conditions.soldier(payload)
    local attacker = payload.attacker
	for i = 1, 4 do
        local unit = getNeighbour(payload.attackerPos, i)
        if unit and (unit.id ~= attacker.id) and (Wargroove.getUnitClass(unit.unitClassId).isCommander) and Wargroove.areAllies(attacker.playerId, unit.playerId) then
            return true
        end
	end
	return false
end


function Conditions.dog(payload)
    local attacker = payload.attacker
	for i = 1, 4 do
        local unit = getNeighbour(payload.defenderPos, i)
        if unit and (unit.id ~= attacker.id) and (unit.unitClassId == attacker.unitClassId) and Wargroove.areAllies(attacker.playerId, unit.playerId) then
            return true
        end
	end
	return false
end


function Conditions.spearman(payload)
    local attacker = payload.attacker
	for i = 1, 4 do
        local unit = getNeighbour(payload.attackerPos, i)
        if unit and (unit.id ~= attacker.id) and (unit.unitClassId == attacker.unitClassId) and Wargroove.areAllies(attacker.playerId, unit.playerId) then
            return true
        end
	end
	return false
end


function Conditions.archer(payload)
    if payload.isCounter then
        return false
    end
    function isSame(a, b)
        return a.x == b.x and a.y == b.y
    end
    return payload.path == nil or (#payload.path == 0) or isSame(payload.attacker.startPos, payload.path[#payload.path])
end


function Conditions.mage(payload)
    return Wargroove.getTerrainDefenceAt(payload.attackerPos) >= 3
end


function Conditions.knight(payload)
    local distance = math.abs(payload.attackerPos.x - payload.attacker.startPos.x) + math.abs(payload.attackerPos.y - payload.attacker.startPos.y)
    return distance == 6
end


function Conditions.merman(payload)
    local terrainName = Wargroove.getTerrainNameAt(payload.attackerPos)
    return terrainName == "river" or terrainName == "sea" or terrainName == "ocean" or terrainName == "reef"
end


function Conditions.ballista(payload)
    local distance = math.abs(payload.attackerPos.x - payload.defenderPos.x) + math.abs(payload.attackerPos.y - payload.defenderPos.y)
    return distance == 2
end


function Conditions.trebuchet(payload)
    local distance = math.abs(payload.attackerPos.x - payload.defenderPos.x) + math.abs(payload.attackerPos.y - payload.defenderPos.y)
    return distance >= 5
end


function Conditions.harpy(payload)
    local terrainName = Wargroove.getTerrainNameAt(payload.attackerPos)
    return terrainName == "mountain"
end


function Conditions.witch(payload)
    local units = Wargroove.getAllUnitsForPlayer(payload.defender.playerId, true)
    for i, v in ipairs(units) do
        if v.unitClassId == "witch" and v.id ~= payload.defender.id then
            local distance = math.abs(v.pos.x - payload.defenderPos.x) + math.abs(v.pos.y - payload.defenderPos.y)
            if distance == 1 then
                return false
            end
        end
    end
    return true
end


function Conditions.dragon(payload)
    local terrainName = Wargroove.getTerrainNameAt(payload.defenderPos)
    return terrainName == "road"
end

function Conditions.giant(payload)
    return payload.attacker.health <= 40
end

function Conditions.harpoonship(payload)
    local terrainName = Wargroove.getTerrainNameAt(payload.attackerPos)
    return terrainName == "reef"
end

function Conditions.warship(payload)
    local terrainName = Wargroove.getTerrainNameAt(payload.attackerPos)
    return terrainName == "beach"
end

function Conditions.turtle(payload)
    local terrainName = Wargroove.getTerrainNameAt(payload.attackerPos)
    return terrainName == "ocean"
end

function Conditions.rifleman(payload)
     -- Check for cardinal directions
     local deltaX = clamp(payload.defender.pos.x - payload.attacker.pos.x, -1, 1)
     local deltaY = clamp(payload.defender.pos.y - payload.attacker.pos.y, -1, 1)

    if math.abs(deltaX) > 0 and math.abs(deltaY) > 0 then
        return false
    end

    return true
end

function Conditions.terraformer(payload)
    local attacker = payload.attacker
	for i = 1, 4 do
        local unit = getNeighbour(payload.attackerPos, i)
        if unit and unit.isStructure and Wargroove.areAllies(attacker.playerId, unit.playerId) then
            return true
        end
	end
	return false
end

function Conditions.minelayer(payload)
    local defender = payload.defender

    if defender.stunned then
        return true
    end

    return false
end

function Conditions.caravel(payload)
	for i = 1, 4 do
        local unit = getNeighbour(payload.defenderPos, i)
        if unit and unit.unitClass.isStructure then
            return true
        end
	end
	return false
end

function Conditions.frog(payload)
    local terrainName = Wargroove.getTerrainNameAt(payload.defenderPos)
    return terrainName == "beach" or terrainName == "river"
end

function Conditions.kraken(payload)
    local units = Wargroove.getAllUnitsForPlayer(payload.defender.playerId, true)

    if Wargroove.getUnitClass(payload.defender.unitClassId).isStructure then
        return false
    end

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

function Conditions.griffin_walking(payload)
    local direction = { x = payload.attackerPos.x - payload.defenderPos.x, y = payload.attackerPos.y - payload.defenderPos.y }
    local beyond = { x = payload.defenderPos.x - direction.x, y = payload.defenderPos.y - direction.y }

    local unit = Wargroove.getUnitAt(beyond)

    if unit and unit.id ~= payload.attacker.id and unit.unitClassId == "griffin_walking" and Wargroove.areAllies(payload.attacker.playerId, unit.playerId) then
        return true
    end

    return false
end

-- Item passives start here
function Conditions.pirate_sabre(payload)
    return payload.attacker.health >= 80
end

function Conditions.caravel_health_crit(payload)
    return payload.attacker.health < 50
end

function Conditions.cursed_crit(payload)
    return false
end

function PassiveConditions:getPassiveConditions()
    return Conditions
end

return PassiveConditions