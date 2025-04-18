local Wargroove = require "wargroove/wargroove"
local ItemVerb = require "wargroove/item_verb"

local BackupCall = ItemVerb:new()

function BackupCall:getMaximumRange(unit, endPos)
    return 1
end

function BackupCall:getTargetType()
    return "empty"
end

function BackupCall:canExecuteWithTarget(unit, endPos, targetPos, strParam)
    if targetPos.x == endPos.x and targetPos.y == endPos.y then
        return false
    end

    return Wargroove.canStandAt("soldier", targetPos)
end

function BackupCall:canExecuteAt(unit, endPos)
    if Wargroove.getTargetsInRange(endPos, 1, "empty") then
        return true
    end

    return false
end

function BackupCall:preExecute(unit, targetPos, strParam, endPos)
    
    local selectedLocations = {}
    
    local targetSpace = Wargroove.getTargetsInRange(endPos, 1, "all")
    if not targetSpace then
        return false, ""
    end
    
    local targetSpaceNum = 0
    for i,pos in ipairs(targetSpace) do
        local t = Wargroove.getUnitAt(pos)
        if pos.x ~= endPos.x or pos.y ~= endPos.y then
            if t then
                if t.id == unit.id then
                    targetSpaceNum = targetSpaceNum + 1
                end
            elseif Wargroove.canStandAt("soldier", pos) then
                targetSpaceNum = targetSpaceNum + 1
            end
        end
    end
    
    for i=0,1 do
        if targetSpaceNum - i <= 0 then
            break
        end

        Wargroove.selectTarget()

        while Wargroove.waitingForSelectedTarget() do
            coroutine.yield()
        end

        local target = Wargroove.getSelectedTarget()
        if (target == nil) then
            selectedLocations = {}
            Wargroove.clearDisplayTargets()
            return false, ""
        end
        
        local ok = false
        for i, pos in ipairs(selectedLocations) do
            if target.x == pos.x and target.y == pos.y then
                ok = true
            end
        end
        if ok == true then
            break
        end

        Wargroove.displayTarget(target)
        table.insert(selectedLocations, target)
    end

    local result = ""
    for i, target in ipairs(selectedLocations) do
        result = result .. target.x .. "," .. target.y
        if i ~= #selectedLocations then
            result = result .. ";"
        end
    end

    Wargroove.clearDisplayTargets()

    return true, result
end

function BackupCall:execute(unit, targetPos, strParam, path)
    local targets = self:parseTargets(strParam)

    for i, pos in pairs(targets) do
        Wargroove.spawnMapAnimation(pos, 0, "fx/mapeditor_unitdrop")
        Wargroove.playMapSound("spawn", pos)
        
        Wargroove.spawnUnit(unit.playerId, pos, "soldier", false, "")
        local spawn = Wargroove.getUnitAt(pos)
        spawn.hadTurn = true
        Wargroove.updateUnit(spawn)
    end
end

return BackupCall