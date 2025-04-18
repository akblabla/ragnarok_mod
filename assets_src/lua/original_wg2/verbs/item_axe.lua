local Wargroove = require "wargroove/wargroove"
local ItemVerb = require "wargroove/item_verb"


local Axe = ItemVerb:new()

function Axe:getMaximumRange(unit, endPos)
    return 2
end

function Axe:getTargetType()
    return "all"
end

function Axe:selectedLocationsContains(pos)
    for i, selectedPos in pairs(Axe.selectedLocations) do
        if selectedPos.x == pos.x and selectedPos.y == pos.y then
           return true
        end
     end
     return false
end

function Axe:getTreesAround(pos, unit)
    local mapSize = Wargroove.getMapSize()

    local result = {}
    local x0 = pos.x
    local y0 = pos.y
    for yo = -1, 1 do
        for xo = -1, 1 do
            local x = x0 + xo
            local y = y0 + yo
            if (x >= 0) and (y >= 0) and (x < mapSize.x) and (y < mapSize.y) and (xo ~= 0 or yo ~= 0) then
                local target = Wargroove.getUnitAt({x=x, y=y})
                local terrainId = Wargroove.getTerrainNameAt({x=x, y=y})
                if (target == nil or target.id == unit.id or Wargroove.isNeutral(target.playerId)) and terrainId == "forest" then
                    table.insert(result, {x=x, y=y})
                end
            end
        end
    end

    return result
end

Axe.selectedLocations = {}

function Axe:preExecute(unit, targetPos, strParam, endPos)
    Axe.selectedLocations = {}
 
    local trees = self:getTreesAround(endPos, unit)
    if #(trees) == 0 then
        return false, ""
    end
        for i=1,#trees do
        Wargroove.selectTarget()

        while Wargroove.waitingForSelectedTarget() do
            coroutine.yield()
        end

        local target = Wargroove.getSelectedTarget()
        if (target == nil) then
            Axe.selectedLocations = {}
            Wargroove.clearDisplayTargets()
            return false, ""
        end

        Wargroove.displayTarget(target)

        --We do this check before the table insert so we don't need to mask out the unit position in the execute.
        if target.x == endPos.x and target.y == endPos.y then
            break
        end

        table.insert(Axe.selectedLocations, target)
    end
    
    if #Axe.selectedLocations == 0 then
        Axe.selectedLocations = {}
        Wargroove.clearDisplayTargets()
        return false, ""
    end

    local result = ""
    for i, target in ipairs(Axe.selectedLocations) do
        result = result .. target.x .. "," .. target.y
        if i ~= #Axe.selectedLocations then
            result = result .. ";"
        end
    end

    Axe.selectedLocations = {}
    Wargroove.clearDisplayTargets()

    return true, result
end

function Axe:canExecuteWithTarget(unit, endPos, targetPos, strParam)
    if Axe:selectedLocationsContains(targetPos) then
        return false
    end

    if math.abs(endPos.x-targetPos.x) > 1 or math.abs(endPos.y-targetPos.y) > 1 then
        return false
    end

    if targetPos.x == endPos.x and targetPos.y == endPos.y then
        return true
    end

    local targetUnit = Wargroove.getUnitAt(targetPos)
    if targetUnit and targetUnit ~= unit and (not Wargroove.isNeutral(targetUnit.playerId)) then
        return false
    end

    local terrain = Wargroove.getTerrainNameAt(targetPos)
    if terrain ~= "forest" then
        return false
    end

    return true
end

function Axe:execute(unit, targetPos, strParam, path)
    local treePositions = self:parseTargets(strParam)

    for i, pos in pairs(treePositions) do
        Wargroove.playMapSound("thiefGoldReleased", pos)
        Wargroove.spawnMapAnimation(pos, 0, "fx/ransack_1", "default", "over_units", { x = 12, y = 0 })
        
        Wargroove.setTerrainType(pos, "plains")
        Wargroove.changeMoney(unit.playerId, 50)
        
        Wargroove.waitTime(0.1)
    end
end

return Axe