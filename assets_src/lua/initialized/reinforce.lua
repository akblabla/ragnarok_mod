local Wargroove = require "wargroove/wargroove"
local OldReinforce = require "verbs/reinforce"
local Verb = require "wargroove/verb"


local Reinforce = {}
function Reinforce.init()
    OldReinforce.canExecuteAt = Reinforce.canExecuteAt
	OldReinforce.canExecuteWithTarget = Reinforce.canExecuteWithTarget
	OldReinforce.execute = Reinforce.execute
    OldReinforce.canExecuteAnywhere = Reinforce.canExecuteAnywhere
    OldReinforce.getMaximumRange = Reinforce.getMaximumRange
    OldReinforce.getTargetType = Reinforce.getTargetType
    OldReinforce.getHealAndCost = Reinforce.getHealAndCost
    OldReinforce.getCostAt = Reinforce.getCostAt
	OldReinforce.generateOrders = Reinforce.generateOrders
    OldReinforce.getScore = Reinforce.getScore
end

--------------------
local conversionRate = 1       -- Every health point taken from city becomes <this value> for unit
local minCityHealthAfter = 1   -- minimum % of health left on city after action
local maxUnitHealth = 100      -- maximum % of health that the unit can achieve
local costScoreFactor = 1    -- multiplies the monetary cost portion of the score (AI)
--------------------

local function getHealingAvailableFrom(city)
    if (city.unitClassId == "tavern") then
        return 100
    end
    return math.floor((city.health - minCityHealthAfter) * conversionRate + 0.5)
end


local function getSurroundingCities(unit, pos)
    result = {}
    for i, p in ipairs(Wargroove.getTargetsInRangeAfterMove(unit, pos, pos, 1, "unit")) do
        local city = Wargroove.getUnitAt(p)
        if city and (city.unitClassId == "tavern") then
            return {city}
        end
    end
    for i, p in ipairs(Wargroove.getTargetsInRangeAfterMove(unit, pos, pos, 1, "unit")) do
        local city = Wargroove.getUnitAt(p)
        if city and city.unitClass.canReinforce and Wargroove.areAllies(unit.playerId, city.playerId) then
            table.insert(result, city)
        end
    end
    return result
end


local function getHealingAvailableAt(unit, pos)
    local healingAvailable = 0
    local cities = getSurroundingCities(unit, pos)
    for i, city in ipairs(cities) do
        healingAvailable = healingAvailable + getHealingAvailableFrom(city)
    end
    return healingAvailable
end


local function consumeHealthAt(unit, pos, health)
    local healthLeft = health
    local cities = getSurroundingCities(unit, pos)
    local citiesSpent = {}
    local citiesLeft = #cities
    local soundPlayed = false

    while healthLeft > 0 do
        assert (citiesLeft > 0)
        local healthShare = math.max(1, math.floor(healthLeft / citiesLeft + 0.5))

        for i = 1, #cities do
            if citiesSpent[i] == nil and healthLeft > 0 then
                local city = cities[i]
                local desired = math.min(healthLeft, healthShare)
                local maxToOffer = city.health - minCityHealthAfter
                if desired <= maxToOffer then
                    city.health = city.health - desired
                    healthLeft = healthLeft - desired
                else
                    city.health = city.health - maxToOffer
                    healthLeft = healthLeft - maxToOffer
                    citiesSpent[i] = true
                    citiesLeft = citiesLeft - 1
                end
                if (city.unitClassId == "tavern") then
                    city.health = 100
                end
                
                Wargroove.spawnMapAnimation(city.pos, 0, "fx/reinforce_1", "default", "over_units", { x = 12, y = 0 })

                if not soundPlayed then
                    Wargroove.playMapSound("reinforceStructureDrain", city.pos)
                    soundPlayed = true
                end
            end
        end
    end

    for i = 1, #cities do
        Wargroove.updateUnit(cities[i])
    end
end


function Reinforce:getMaximumRange(unit, endPos)
    return 1
end


function Reinforce:getTargetType()
    return "unit"
end


function Reinforce:canExecuteAnywhere(unit)
    return unit.health < 100
end


local function getHealingCost(health, unit)
    local fullCost = Wargroove.getUnitClass(unit.unitClassId).cost
    return math.ceil(health * fullCost / 100)
end


local function getAffordableHealing(unit)
    local fullCost = Wargroove.getUnitClass(unit.unitClassId).cost
    return math.floor(Wargroove.getMoney(unit.playerId) * 100 / fullCost)
end


function Reinforce:canExecuteAt(unit, endPos)
    local desiredHealing = maxUnitHealth - unit.health
    if desiredHealing == 0 then
        return false
    end
    if getHealingCost(1, unit) > Wargroove.getMoney(unit.playerId) then
        return false
    end

    if not Verb.canExecuteAt(self, unit, endPos) then
        return false
    end

    return getHealingAvailableAt(unit, endPos) > 0
end

function Reinforce:canExecuteWithTarget(unit, endPos, targetPos, strParam)
    -- if not self:canSeeTarget(targetPos) then
    --     return false
    -- end

    -- local targetUnit = Wargroove.getUnitAt(targetPos)

    -- if not targetUnit or not targetUnit.unitClass.canReinforce then
    --     return false
    -- end

    return true
end

function Reinforce:getHealAndCost(unit, targetPos)
    local desiredHealing = maxUnitHealth - unit.health
    local availableHealing = getHealingAvailableAt(unit, targetPos)
    local affordableHealing = getAffordableHealing(unit)

    local toHeal = math.min(math.min(desiredHealing, availableHealing), affordableHealing)
    local cost = getHealingCost(toHeal, unit)

    return toHeal, cost
end


function Reinforce:getCostAt(unit, endPos, targetPos)
    local toHeal, cost = self:getHealAndCost(unit, endPos)
    return cost
end


function Reinforce:execute(unit, targetPos, strParam, path)   
    local toHeal, cost = self:getHealAndCost(unit, targetPos)
    consumeHealthAt(unit, targetPos, math.floor(toHeal / conversionRate + 0.5))

    Wargroove.waitTime(1.0)
    Wargroove.spawnMapAnimation(unit.pos, 0, "fx/reinforce_2", "default", "over_units", { x = 12, y = 0 })
    Wargroove.playMapSound("reinforceUnitHeal", unit.pos)

    unit.health = unit.health + toHeal
    Wargroove.updateUnit(unit)
    Wargroove.changeMoney(unit.playerId, -cost)
end

function Reinforce:generateOrders(unitId, canMove)
    local orders = {}

    local unit = Wargroove.getUnitById(unitId)
    if unit.health == maxUnitHealth or getHealingCost(1, unit) > Wargroove.getMoney(unit.playerId) then
        return orders
    end

    local unitClass = Wargroove.getUnitClass(unit.unitClassId)
    local movePositions = {}
    if canMove then
        movePositions = Wargroove.getTargetsInRange(unit.pos, unitClass.moveRange, "empty")
    end
    table.insert(movePositions, unit.pos)

    for i, pos in pairs(movePositions) do
        if getHealingAvailableAt(unit, pos) > 0 then
            orders[#orders+1] = {targetPosition = pos, strParam = "", movePosition = pos, endPosition = pos}
        end
    end

    return orders
end

function Reinforce:getScore(unitId, order)
    print("getScore")
    local unit = Wargroove.getUnitById(unitId)
    local unitClass = Wargroove.getUnitClass(unit.unitClassId)
    local unitValue = math.sqrt(unitClass.cost+50)
    if unitClass.isCommander then
        unitValue = 20
    end

    local toHeal, cost = self:getHealAndCost(unit, order.endPosition)
    local healthScore = toHeal / 100
    local costScore = -math.sqrt(cost / 100) * costScoreFactor/((100+Wargroove.getMoney(unit.playerId))/2500)

    local cities = getSurroundingCities(unit, order.endPosition)
    local cityScore = 0
    local cityHealthShare = (toHeal / conversionRate) / #cities
    for i, city in ipairs(cities) do
        local cityUC = Wargroove.getUnitClass(city.unitClassId)
        local cityValue = math.sqrt(30*cityUC.cost / 100)
        if city.unitClassId == "tavern" then
            cityValue = 0
        end
        if (city.unitClassId == "barracks") or (city.unitClassId == "port") or (city.unitClassId == "tower") then
            cityValue = cityValue*2
        end
        local cityValueBefore = math.sqrt(city.health/100)*cityValue
        local cityValueAfter = math.sqrt(math.max(city.health-cityHealthShare,0)/100)*cityValue
        
        cityScore = cityScore + (cityValueAfter - cityValueBefore)/(city.health/100)
    end

    local score = (healthScore * unitValue + costScore + cityScore)/4
    print("score = ".. score)
    print("healthScore = ".. healthScore)
    print("unitValue = ".. unitValue)
    print("costScore = ".. costScore)
    print("cityScore = ".. cityScore)
    return { score = score, healthDelta = toHeal, introspection = {
        { key = "toHeal", value = toHeal },
        { key = "cost", value = cost },
        { key = "unitValue", value = unitValue },
        { key = "healthScore", value = healthScore },
        { key = "costScoreFactor", value = costScoreFactor },
        { key = "costScore", value = costScore },
        { key = "#cities", value = #cities },
        { key = "cityHealthShare", value = cityHealthShare },
        { key = "cityScore", value = cityScore }}}
end

return Reinforce
