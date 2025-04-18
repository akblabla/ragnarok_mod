local Wargroove = require "wargroove/wargroove"
local Verb = require "wargroove/verb"


local CutTrees = Verb:new()

-- local money_reward = { 50, 100, 150, 200, 250, 300, 350, 400 }
-- local money_reward = { 100, 200, 300, 400, 500, 600, 700, 800 }
local money_reward = { 100, 250, 400, 550, 700, 850, 1000, 1150 }

function CutTrees:getMaximumRange(unit, endPos)
    return 2
end

function CutTrees:getTargetType()
    return "all"
end

function CutTrees:selectedLocationsContains(pos)
    for i, selectedPos in pairs(CutTrees.selectedLocations) do
        if selectedPos.x == pos.x and selectedPos.y == pos.y then
           return true
        end
     end
     return false
end

CutTrees.selectedLocations = {}

function CutTrees:getTreesAround(pos)
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
                if (target == nil or Wargroove.isNeutral(target.playerId)) and terrainId == "forest" then
                    table.insert(result, {x=x, y=y})
                end
            end
        end
    end

    return result
end

function CutTrees:preExecute(unit, targetPos, strParam, endPos)
    CutTrees.selectedLocations = {}

    Wargroove.playUnitAnimation(unit.id, "active", "active")

    local trees = self:getTreesAround(unit.pos)
    if #(trees) == 0 then
        return false, ""
    end

    for i=1,#(trees) do
        Wargroove.selectTarget()

        while Wargroove.waitingForSelectedTarget() do
            coroutine.yield()
        end

        local target = Wargroove.getSelectedTarget()
        if (target == nil) then
            CutTrees.selectedLocations = {}
            Wargroove.clearDisplayTargets()
            coroutine.yield()
            Wargroove.playUnitAnimation(unit.id, "idle")
            return false, ""
        end

        Wargroove.displayTarget(target)
        
        if target.x == unit.pos.x and target.y == unit.pos.y then
            break
        end

        table.insert(CutTrees.selectedLocations, target)
    end

    local result = ""
    for i, target in ipairs(CutTrees.selectedLocations) do
        result = result .. target.x .. "," .. target.y
        if i ~= #CutTrees.selectedLocations then
            result = result .. ";"
        end
    end

    CutTrees.selectedLocations = {}
    Wargroove.clearDisplayTargets()
    Wargroove.waitFrame()

    return true, result
end

function CutTrees:canExecuteWithTarget(unit, endPos, targetPos, strParam)
    if CutTrees:selectedLocationsContains(targetPos) then
        return false
    end

    if math.abs(unit.pos.x-targetPos.x) > 1 or math.abs(unit.pos.y-targetPos.y) > 1 then
        return false
    end

    if targetPos.x == unit.pos.x and targetPos.y == unit.pos.y then
        return true
    end

    local targetUnit = Wargroove.getUnitAt(targetPos)
    if targetUnit and not Wargroove.isNeutral(targetUnit.playerId) then
        return false
    end

    local terrain = Wargroove.getTerrainNameAt(targetPos)
    if terrain ~= "forest" then
        return false
    end

    return true
end

function CutTrees:execute(unit, targetPos, strParam, path)
    local treePositions = self:parseTargets(strParam)
    Wargroove.clearDisplayTargets()

    for i, pos in pairs(treePositions) do
        -- if the player finished "early" by clicking on the unit we need to prevent giving gold for that one
        if pos.x ~= unit.pos.x or pos.y ~= unit.pos.y then
            Wargroove.playMapSound("thiefGoldReleased", pos)
            Wargroove.spawnMapAnimation(pos, 0, "fx/ransack_1", "default", "over_units", { x = 12, y = 0 })

            Wargroove.setTerrainType(pos, "forest_cut")
            
            Wargroove.waitTime(0.1)
        end
    end

    -- We always want to reward the highest possible, since players can mistakenly cut in multiple cuts. 
    -- We reward them what they should've gotten.
    local previouslyCutTrees = Wargroove.getUnitState(unit, "treeNumber")
    if previouslyCutTrees then
        previouslyCutTrees = tonumber(previouslyCutTrees)
    else
        previouslyCutTrees = 0
    end

    print("Previously cut: "..previouslyCutTrees)

    local previouslyRewarded = 0
    if previouslyCutTrees > 0 then
        previouslyRewarded = money_reward[previouslyCutTrees]
    end

    local currentlyCutTrees = previouslyCutTrees + #treePositions
    local newReward = 0
    if currentlyCutTrees > 0 then
        newReward = money_reward[currentlyCutTrees] - previouslyRewarded
    end

    Wargroove.changeMoney(unit.playerId, newReward)

    Wargroove.playUnitAnimation(unit.id, "idle")
    Wargroove.setUnitState(unit, "treeNumber", tostring(currentlyCutTrees))
    Wargroove.updateUnit(unit)
end

function CutTrees:onPostUpdateUnit(unit, targetPos, strParam, path)
    local trees = Wargroove.getTerrainTargetsAround(unit.pos, "forest")
    if #(trees) == 0 then
        unit.hadTurn = true
    else
        unit.hadTurn = false
    end
    Wargroove.updateUnit(unit)
end

function CutTrees:generateOrders(unitId, canMove)
    local orders = {}
    local unit = Wargroove.getUnitById(unitId)

    local trees = self:getTreesAround(unit.pos)
    if #trees == 0 then
        print("... AI found no trees around lumbermill")
        return orders
    end

    local result = ""
    for i, target in pairs(trees) do
        result = result .. target.x .. "," .. target.y
        if i ~= #trees then
            result = result .. ";"
        end
    end

    table.insert(orders, {
        targetPosition = unit.pos,
        strParam = result,
        movePosition = unit.pos,
        endPosition = unit.pos
    })

    return orders
end

function CutTrees:getScore(unitId, order)
    local unit = Wargroove.getUnitById(unitId)

    local trees = self:getTreesAround(unit.pos)
    local num_trees = #trees

    local score = 0.0

    -- for now, don't cut if less than three forests nearby
    if num_trees >= 3 then
        score = 5.0 + num_trees / 8.0
    end

    return {score = score, introspection = {}}
end

return CutTrees
