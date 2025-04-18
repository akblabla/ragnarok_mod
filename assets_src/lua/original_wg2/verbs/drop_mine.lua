local Verb = require "wargroove/verb"
local Wargroove = require "wargroove/wargroove"

local DropMine = Verb:new()


local dropNumber = 1

DropMine.selectedLocations = {}

function DropMine:getMaximumRange(unit, endPos)
    return 1
end

function DropMine:getTargetType()
    return "all"
end

function DropMine:selectedLocationsContains(pos)
    for i, selectedPos in pairs(DropMine.selectedLocations) do
        if selectedPos.x == pos.x and selectedPos.y == pos.y then
           return true
        end
     end
     return false
end

function DropMine:canExecuteWithTarget(unit, endPos, targetPos, strParam)
    local ammo = tonumber(Wargroove.getUnitState(unit, "ammo"))
    if ammo == 0 then
        return false
    end

    if not self:canSeeTarget(targetPos) then
        return false
    end

    local terrainName = Wargroove.getTerrainNameAt(targetPos)
    if not(terrainName == "beach" or terrainName == "ocean" or terrainName == "reef" or terrainName == "sea") then
        return false
    end

    local u = Wargroove.getUnitAt(targetPos)
    return (not DropMine.selectedLocationsContains(self, targetPos)) 
        and (endPos.x ~= targetPos.x or endPos.y ~= targetPos.y) 
        and (u == nil or unit.id == u.id)        
        and Wargroove.canStandAt("mine", targetPos)
end

function DropMine:preExecute(unit, targetPos, strParam, endPos)
    DropMine.selectedLocations = {}

    local targets = ""

    for i = 1, dropNumber, 1 do
        Wargroove.selectTarget()

        while Wargroove.waitingForSelectedTarget() do
            coroutine.yield()
        end

        local targetOne = Wargroove.getSelectedTarget()

        if (targetOne == nil) then
            DropMine.selectedLocations = {}
            return false, ""
        end

        Wargroove.displayTarget(targetOne)

        DropMine.selectedLocations[i] = targetOne

        targets = targets .. targetOne.x .. "," .. targetOne.y .. ";"
    end

    DropMine.selectedLocations = {}

    Wargroove.clearDisplayTargets()

    return true, targets
end

function DropMine:execute(unit, targetPos, strParam, path)
    if strParam == "" then
        print("DropMine:execute was not given any target positions.")
        return
    end

    local targetPositions = self:parseTargets(strParam)

    local ammo = tonumber(Wargroove.getUnitState(unit, "ammo"))
    local newAmmo = math.max(ammo - 1, 0)
    Wargroove.setUnitState(unit, "ammo", newAmmo)

    -- if (newAmmo == 0) and not Wargroove.hasUnitEffect(unit.id, outOfAmmoAnimation) then
    --     Wargroove.spawnUnitEffect(unit.id, unit.id, outOfAmmoAnimation, "idle", startAnimation, true, false)
    -- end

    for i, minePos in pairs(targetPositions) do
        Wargroove.spawnUnit(unit.playerId, minePos, "mine", true)
    end

    Wargroove.updateUnit(unit)

    Wargroove.logAnalyticsAction("UnitAbility", unit.playerId, "drop_mine", "")
end

return DropMine
