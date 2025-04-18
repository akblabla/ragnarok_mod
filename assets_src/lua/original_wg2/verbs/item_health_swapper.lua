local Wargroove = require "wargroove/wargroove"
local ItemVerb = require "wargroove/item_verb"

local HealthSwapper = ItemVerb:new()

HealthSwapper.selectedLocations = {}

local range = 3


function HealthSwapper:getMaximumRange(unit, endPos)
    return range
end

function HealthSwapper:getTargetType()
    return "unit"
end

function HealthSwapper:selectedLocationsContains(pos)
    for i, selectedPos in ipairs(HealthSwapper.selectedLocations) do
        if selectedPos.x == pos.x and selectedPos.y == pos.y then
           return true
        end
     end
     return false
end

function HealthSwapper:canExecuteWithTarget(unit, endPos, targetPos, strParam)
    local target = self:getUnitOrSelfAt(targetPos, endPos, unit)

    if not self:isValidTarget(target) then
        return false
    end

    if #HealthSwapper.selectedLocations == 0 then --We only want units with a valid swapping partner
        local targets = Wargroove.getTargetsInRange(endPos, range, "unit")
        table.insert(targets, unit.pos)
        for i, p in ipairs(targets) do
            local t = self:getUnitOrSelfAt(p, endPos, unit)
            if self:isValidTarget(t) and self:targetsCompatible(t, target) then
                return true
            end
        end
    else
        return (not self:selectedLocationsContains(targetPos)) and self:targetsCompatible(self:getUnitOrSelfAt(self.selectedLocations[1], endPos, unit), target)
    end
    
    return false
end

function HealthSwapper:getUnitOrSelfAt(pos, endPos, unit)--in case the position is the endPos, there won't be a unit there so this takes care of that
    if pos.x == endPos.x and pos.y == endPos.y then
        return unit
    else
        return Wargroove.getUnitAt(pos)
    end
end

function HealthSwapper:isValidTarget(target)
    return target and (not target.unitClass.isStructure) and (not target.unitClass.isCommander)
end

function HealthSwapper:targetsCompatible(target1, target2)
    return Wargroove.areAllies(target1.playerId, target2.playerId) and target1.health ~= target2.health
end

function HealthSwapper:preExecute(unit, targetPos, strParam, endPos)
    HealthSwapper.selectedLocations = {}

    for i=1,2 do
        Wargroove.selectTarget()

        while Wargroove.waitingForSelectedTarget() do
            coroutine.yield()
        end

        local target = Wargroove.getSelectedTarget()
        if (target == nil) then
            HealthSwapper.selectedLocations = {}
            Wargroove.clearDisplayTargets()
            return false, ""
        end

        Wargroove.displayTarget(target)
        table.insert(HealthSwapper.selectedLocations, target)
    end

    if #HealthSwapper.selectedLocations ~= 2 then
        HealthSwapper.selectedLocations = {}
        Wargroove.clearDisplayTargets()
        return false, ""
    end

    local result = ""
    for i, target in ipairs(HealthSwapper.selectedLocations) do
        result = result .. target.x .. "," .. target.y
        if i ~= #HealthSwapper.selectedLocations then
            result = result .. ";"
        end
    end

    HealthSwapper.selectedLocations = {}
    Wargroove.clearDisplayTargets()

    return true, result
end

function HealthSwapper:execute(unit, targetPos, strParam, path)
    local targets = self:parseTargets(strParam)

    local target1 = Wargroove.getUnitAt(targets[1])
    local target2 = Wargroove.getUnitAt(targets[2])

    if target1.health == target2.health then
        return
    end

    if target1.health < target2.health then
        local t = target1
        target1 = target2
        target2 = t
    end

    Wargroove.spawnMapAnimation(target1.pos, 0, "fx/drain_unit")
    Wargroove.playMapSound("darkmercia/darkmerciaGrooveUnitDrained", target1.pos)
    Wargroove.waitTime(0.2)

    local h = target1.health
    target1:setHealth(target2.health, unit.id)
    Wargroove.updateUnit(target1)
    Wargroove.playUnitAnimation(target1.id, "hit")
    Wargroove.waitTime(0.7)

    Wargroove.spawnMapAnimation(target2.pos, 0, "fx/heal_unit")
    Wargroove.playMapSound("unitHealed", target2.pos)
    Wargroove.waitTime(0.2)

    target2:setHealth(h, unit.id)
    Wargroove.updateUnit(target2)
    Wargroove.waitTime(0.2)
end

return HealthSwapper