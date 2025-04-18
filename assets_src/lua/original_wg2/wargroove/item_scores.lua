local Wargroove = require "wargroove/wargroove"

local ItemScores = {}

function ItemScores.getScoreAreaHeal(unitId, order)
    local unit = Wargroove.getUnitById(unitId)
    local targets = Wargroove.getTargetsInRangeAfterMove(unit, order.endPosition, order.targetPosition, 3, "unit")

    local opportunityCost = -1
    local totalScore = 0
    local maxScore = 300

    for i, pos in ipairs(targets) do
        local u = Wargroove.getUnitAt(pos)
        if u ~= nil and (not u.unitClass.isStructure) then
            local uc = u.unitClass
            if not Wargroove.areEnemies(unit.playerId, u.playerId) then
                totalScore = totalScore + uc.cost
            else
                totalScore = totalScore - uc.cost
            end
        end
    end
    
    local score = totalScore/maxScore + opportunityCost
    return {score = score, introspection = {{key = "totalScore", value = totalScore}}}
end

function ItemScores.potion01(unitId, order)
    local unit = Wargroove.getUnitById(unitId)

    local gainScore = unit.unitClass.maxHealth - unit.health
    local maxScore = unit.unitClass.maxHealth

    local score = gainScore/maxScore

    return {score = score, introspection = {}}
end

function ItemScores.money_bag(unitId, order)
    return {score = -1, introspection = {}}
end

function ItemScores.getScoreForItem(itemId, unitId, order)
    local score = {score = -1, introspection = {}}
    local getter = ItemScores[itemId]
    if getter ~= nil then
        score = getter(unitId, order)
    else
        print("getScoreForItem not implemented for item type " .. itemId)
    end
    return score
end

return ItemScores
