local Wargroove = require "wargroove/wargroove"
local Stats = require "util/stats"
local BlockChecker = {}
function BlockChecker.isBlocked(endPos, targetPos, playerId)
    local xDiff = math.abs(endPos.x - targetPos.x)
    local yDiff = math.abs(endPos.y - targetPos.y)
    local xDelta = endPos.x - targetPos.x
    local yDelta = endPos.y - targetPos.y

    -- Otherwise we march either horizontally/vertically along the position and check for enemies
    if xDiff > yDiff then
        -- horizontal walk
        local xStep = xDelta < 0 and -1 or 1
        local tmpPosX = targetPos.x + xStep

        while tmpPosX ~= endPos.x
        do
            local targetUnit = Wargroove.getUnitAt({x = tmpPosX, y = targetPos.y})
            if targetUnit and Wargroove.areEnemies(targetUnit.playerId, playerId) then
                return true
            end
            local targetTerrain = Wargroove.getTerrainNameAt({x = tmpPosX, y = targetPos.y})
            if Stats.isTerrainBlocking(targetTerrain) then
                return true
            end


            tmpPosX = tmpPosX + xStep
        end
    else 
        -- vertical walk OR same x/y, so we just do a vertical walk
        local yStep = yDelta < 0 and -1 or 1
        local tmpPosY = targetPos.y + yStep

        while tmpPosY ~= endPos.y
        do
            local targetUnit = Wargroove.getUnitAt({x = targetPos.x, y = tmpPosY })
            if targetUnit and Wargroove.areEnemies(targetUnit.playerId, playerId) then
                return true
            end
            local targetTerrain = Wargroove.getTerrainNameAt({x = targetPos.x, y = tmpPosY})
            if Stats.isTerrainBlocking(targetTerrain) then
                return true
            end

            tmpPosY = tmpPosY + yStep
        end
    end
    return false
end

return BlockChecker