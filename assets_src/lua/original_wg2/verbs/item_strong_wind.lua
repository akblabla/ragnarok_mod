local Wargroove = require "wargroove/wargroove"
local Verb = require "wargroove/verb"

local StrongWind = Verb:new()

StrongWind.isInPreExecute = false

StrongWind.possibleTargets = {}

local pushDistance = 1
local knockonDamage = 20

function StrongWind:getMaximumRange(unit, endPos)
    return 3
end

function StrongWind:getTargetType()
    return "empty"
end

function StrongWind:getTargetArrows(unit, targetPos, endPos)
    local results = {}

    for i, pos in ipairs(Wargroove.getTargetsInRange(targetPos, 1, "unit")) do
        local u = Wargroove.getUnitAt(pos)
        if u and Wargroove.areEnemies(u.playerId, unit.playerId) then
            local pushResults = Wargroove.getPushPullResult(targetPos, pos, pushDistance, true, false)
            
            local targetArrow = Wargroove.createTargetArrowFromPushPullResult(pushResults)
            if targetArrow then
                table.insert(results, targetArrow)
            end
        end
    end

    return results
end

function StrongWind:canExecuteWithTarget(unit, endPos, targetPos, strParam)
    if not self:canSeeTarget(targetPos) then
        return false
    end

    -- Check for cardinal directions
    local deltaX = targetPos.x - endPos.x
    local deltaY = targetPos.y - endPos.y

    if math.abs(deltaX) > 0 and math.abs(deltaY) > 0 then
        return false
    end
    
    if targetPos.x == unit.pos.x and targetPos.y == unit.pos.y then
        return false
    end

    if not self:canSeeTarget(targetPos) then
        return false
    end

    local u = Wargroove.getUnitAt(targetPos)
    return (u == nil or u.id == unit.id)
end

function StrongWind:execute(unit, targetPos, strParam, path)
    Wargroove.spawnMapAnimation(targetPos, 0, "fx/mapeditor_unitdrop")
    Wargroove.spawnMapAnimation(targetPos, 2, "fx/groove/ragna_groove_fx", "idle", "behind_units", { x = 12, y = 12 })
    for i, pos in ipairs(Wargroove.getTargetsInRange(targetPos, pushDistance, "unit")) do
        local u = Wargroove.getUnitAt(pos)
        if u and Wargroove.areEnemies(u.playerId, unit.playerId) then
            local pushResults = Wargroove.getPushPullResult(targetPos, pos, 1, false)

            if pushResults == nil then
                goto NEXT_POS
            end
            
            Wargroove.processPushPullResult(unit, pushResults, 0, knockonDamage)

            :: NEXT_POS ::
        end
    end
end

return StrongWind
