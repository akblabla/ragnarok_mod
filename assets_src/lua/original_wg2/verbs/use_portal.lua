local Wargroove = require "wargroove/wargroove"
local Verb = require "wargroove/verb"

local UsePortal = Verb:new()

UsePortal.isInPreExecute = false
UsePortal.startingPortal = nil
UsePortal.dropTarget = nil

function UsePortal:getTargetType()
    if UsePortal.isInPreExecute then
        if UsePortal.startingPortal == nil then
            return "unit"
        else
            return "empty"
        end
    else
        return "unit"
    end
end

function UsePortal:getMaximumRange(unit, endPos)
    if UsePortal.isInPreExecute then
        if UsePortal.startingPortal == nil then
            return 1
        else
            return 99
        end
    else
        return 1
    end
end

local function getSurroundingPortals(unit, pos)
    result = {}
    for i, p in ipairs(Wargroove.getTargetsInRangeAfterMove(unit, pos, pos, 1, "unit")) do
        local portal = Wargroove.getUnitAt(p)
        if portal and portal.unitClassId == "portal" and Wargroove.areAllies(unit.playerId, portal.playerId) and not portal.hadTurn then
            table.insert(result, portal)
        end
    end
    return result
end

function UsePortal:preExecute(unit, targetPos, strParam, endPos)
    UsePortal.isInPreExecute = true

    -- Select starting portal if we don't have one yet
    if targetPos.x == endPos.x and targetPos.y == endPos.y then
        UsePortal.startingPortal = unit
    else
        UsePortal.startingPortal = Wargroove.getUnitAt(targetPos)
    end

    if UsePortal.startingPortal.id == unit.id then
        UsePortal.startingPortal = nil
        local portals = getSurroundingPortals(unit, endPos)

        if (#portals == 0) then
            -- Shouldn't technically be possible
            UsePortal:cleanUpPreExecute()
            return false, ""
        end

        UsePortal.startingPortal = portals[1]
    end

    -- Now select the drop position badibam
    Wargroove.selectTarget()

    while Wargroove.waitingForSelectedTarget() do
        coroutine.yield()
    end

    UsePortal.dropTarget = Wargroove.getSelectedTarget()
    if UsePortal.dropTarget == nil then
        UsePortal:cleanUpPreExecute()
        return false, ""
    end

    local result = {}
    result[0] = endPos
    result[1] = UsePortal.dropTarget

    Wargroove.setSelectedTarget(targetPos)

    UsePortal:cleanUpPreExecute()
    return true, UsePortal:targetsToString(result)
end

function UsePortal:targetsToString(targets)
    local strParam = ""
    local start = true
    for unitId, target in pairs(targets) do
        if start then
            start = false
        else
            strParam = strParam .. ";"
        end

        strParam = strParam .. unitId .. ":" .. target.x .. "," .. target.y
    end
    return strParam
end

function UsePortal:canExecuteWithTarget(unit, endPos, targetPos, strParam)
    if UsePortal.isInPreExecute then
        -- if destination portal is empty, select for portal, otherwise select for drop position
        if UsePortal.startingPortal == nil then
            local portals = getSurroundingPortals(unit, endPos)

            print(Wargroove.tableToString(endPos))
            print("Portals: " .. #portals)
            for _, portal in ipairs(portals) do
                if targetPos.x == portal.pos.x and targetPos.y == portal.pos.y then
                    return true
                end
            end
            return false
        elseif UsePortal.dropTarget == nil then
            local allUnits = Wargroove.getAllUnitIds()
            for _, id in ipairs(allUnits) do
                local portal = Wargroove.getUnitById(id)

                if portal and portal.unitClassId == "portal" and Wargroove.areAllies(portal.playerId, unit.playerId) 
                    and not portal.hadTurn and portal.id ~= UsePortal.startingPortal.id then
                    local targets = Wargroove.getTargetsInRange(portal.pos, 1, "empty")
                    for _, pos in ipairs(targets) do
                        if targetPos.x == pos.x and targetPos.y == pos.y and Wargroove.canStandAt(unit.unitClassId, pos) then
                            return true
                        end
                    end
                end
            end

            return false
        end
    else
        if not self:canSeeTarget(targetPos) then
            return false
        end

        local targetUnit = Wargroove.getUnitAt(targetPos)
        if not targetUnit then
            return false
        end

        if targetUnit.unitClassId ~= "portal" or not Wargroove.areAllies(unit.playerId, targetUnit.playerId) or targetUnit.hadTurn then
            return false
        end

        return true
    end

    return true
end

function UsePortal:execute(unit, targetPos, strParam, path)
    local targets = Wargroove.stringToPositions(strParam)

    Wargroove.trackCameraTo(targets[0])
    Wargroove.waitTime(0.4)

    Wargroove.spawnPaletteSwappedMapAnimation(targets[0], 0, "fx/portal_teleport_fx", unit.playerId, "despawn", "units", { x=12, y=10 })
    Wargroove.playMapSound("cutscene/teleportIn", targetPos)
    Wargroove.waitTime(0.5)

    unit.pos.x = -100
    unit.pos.y = -100
    Wargroove.updateUnit(unit)

    Wargroove.trackCameraTo(targets[1])
    Wargroove.waitTime(0.5)

    Wargroove.spawnPaletteSwappedMapAnimation(targets[1], 0, "fx/portal_teleport_fx", unit.playerId, "spawn", "units", { x=12, y=10 })
    Wargroove.playMapSound("cutscene/teleportIn", targets[1])

    Wargroove.waitTime(0.7)

    unit.pos.x = targets[1].x
    unit.pos.y = targets[1].y
    Wargroove.updateUnit(unit)

    Wargroove.waitTime(0.5)
end


function UsePortal:onPostUpdateUnit(unit, targetPos, strParam, path)
    
    if strParam == "" then
        return
    end

    local targets = Wargroove.stringToPositions(strParam)
    unit.pos = targets[1]
end

function UsePortal:cleanUpPreExecute()
    Wargroove.clearDisplayTargets()

    UsePortal.isInPreExecute = false
    UsePortal.startingPortal = nil
    UsePortal.dropTarget = nil
end

function UsePortal:generateOrders(unitId, canMove)
    local orders = {}
    -- Orders to use the portal are generated in movement phase, so on C++ side.
    return orders
end

function UsePortal:getScore(unitId, order)
    return {score = 0, introspection = {}}
end

return UsePortal
