local Wargroove = require "wargroove/wargroove"
local Verb = require "wargroove/verb"

local Smack = Verb:new()

local pushDamage = 20

function Smack:getMaximumRange(unit, endPos)
    return 1
end

function Smack:getTargetType()
    return 'empty'
end

function Smack:canExecuteWithTarget(unit, endPos, targetPos, strParam)
    local targetUnit = Wargroove.getUnitAt(targetPos)
    if targetUnit and targetUnit.unitClass.isStructure then
        return false
    end

    return true
end

function Smack:execute(unit, targetPos, strParam, path)
    local targets = Wargroove.getTargetsInRange(targetPos, 1, "unit")

    for i, pos in ipairs(targets) do
        local deltaX = clamp(pos.x - targetPos.x, -1, 1)
        local deltaY = clamp(pos.y - targetPos.y, -1, 1)

        local pushPosition = { x=pos.x + deltaX, y=pos.y + deltaY }
        local originalPosition = { x=pos.x, y=pos.y }

        local targetUnit = Wargroove.getUnitAt(pos)
        local pushPositionUnit = Wargroove.getUnitAt(pushPosition)

        if targetUnit == unit then
            goto skipToNextUnit
        end

        if pushPositionUnit ~= nil then
            targetUnit:setHealth(targetUnit.health - pushDamage, unit.id)
            Wargroove.updateUnit(targetUnit)
            Wargroove.playUnitAnimation(targetUnit.id, "hit")
            Wargroove.spawnMapAnimation(targetUnit.pos, 0, "fx/unit_splash")
        else
            -- We can target structures, but they won't get pushed
            if not (targetUnit.unitClass.isStructure or targetUnit.unitClass.isCommander) then
                Wargroove.spawnMapAnimation(targetUnit.pos, 0, "fx/unit_splash")

                Wargroove.moveUnitToOverride(targetUnit.id, pushPosition, 0, 0, 10)
                while (Wargroove.isLuaMoving(targetUnit.id)) do
                    coroutine.yield()
                end

                targetUnit.pos = pushPosition
                Wargroove.updateUnit(targetUnit)
            end

            Wargroove.updateUnit(targetUnit)
            Wargroove.playUnitAnimation(targetUnit.id, "hit")
        end

        ::skipToNextUnit::
    end
    
    Wargroove.waitTime(0.2)

    -- Neutralize smacker
    Wargroove.spawnMapAnimation(unit.pos, 0, "fx/mapeditor_unitdrop")
    unit.unitClassId = "golem"
    unit.hadTurn = true
    unit.health = 100
    unit.playerId = -1

    Wargroove.updateUnit(unit)
end

return Smack