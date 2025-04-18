local Verb = require "wargroove/verb"
local Wargroove = require "wargroove/wargroove"

local Build = Verb:new()

local buildCost = 200

function Build:getMaximumRange(unit, endPos)
    return 6
end


function Build:getTargetType()
    if Build.isInPreExecute then
        return "empty"
    end

    return "all"
end

function Build:getCostAt(unit, endPos, targetPos)
    return buildCost;
end


function Build:canExecuteWithTarget(unit, endPos, targetPos, strParam)

    if buildCost > Wargroove.getMoney(unit.playerId) then
        return false
    end

    if not self:canSeeTarget(targetPos) then
        return false
    end
    
    if not Build.isInPreExecute then
        if targetPos.x == unit.pos.x and targetPos.y == unit.pos.y then
            return true
        end

        local targetUnit = Wargroove.getUnitAt(targetPos)
        return targetUnit and not targetUnit.unitClass.isStructure and (not targetUnit.unitClass.isCommander or not Wargroove.areEnemies(targetUnit.playerId, unit.playerId)) and targetUnit.canBeAttacked
    else
        local movingUnit = Wargroove.getUnitById(Build.movingUnit)
        if targetPos.x == unit.pos.x and targetPos.y == unit.pos.y then
            return Wargroove.canStandAt(movingUnit.unitClassId, targetPos)
        end

        return (Wargroove.getUnitAt(targetPos) == nil) and Wargroove.canStandAt(movingUnit.unitClassId, targetPos) and (targetPos.x ~= endPos.x or targetPos.y ~= endPos.y)
    end
end

function Build:execute(unit, targetPos, strParam, path)
    for i, tile in ipairs(path) do
        Wargroove.spawnMapAnimation(tile, 0, "fx/mapeditor_unitdrop")
        Wargroove.playMapSound("spawn", tile)
        Wargroove.setTerrainType(tile, "road")

        Wargroove.waitTime(0.2)
    end

    Wargroove.changeMoney(unit.playerId, -buildCost)
end

return Build
