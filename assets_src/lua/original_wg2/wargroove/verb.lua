local Verb = {}
local Wargroove = require "wargroove/wargroove"
local Functional = require "halley/functional"
local Resumable = require "wargroove/resumable"


function Verb:canExecute(unit, endPos, targetPos, strParam)
    if not self:canExecuteAnywhere(unit) then
        return false
    end

    if not self:canExecuteAt(unit, endPos) then
        return false
    end

    if self:getTargetType() ~= nil then
        -- If no target is specified, check if there's any valid target.
        if targetPos == nil then
            return self:canExecuteWithAnyTarget(unit, endPos, strParam)
        else
            return self:isInRange(unit, endPos, targetPos) and self:canExecuteWithTarget(unit, endPos, targetPos, strParam)
        end
    else
        return true
    end
end


function Verb:isInRange(unit, endPos, pos)
    local distance = math.abs(endPos.x - pos.x) + math.abs(endPos.y - pos.y)
    return distance <= self:getMaximumRange(unit, endPos)
end


function Verb:getTargets(unit, endPos, strParam)
    return Functional.filter(function (targetPos)
        return self:canExecuteWithTarget(unit, endPos, targetPos, strParam)
    end, Wargroove.getTargetsInRangeAfterMove(unit, endPos, endPos, self:getMaximumRange(unit, endPos), self:getTargetType()))
end

function Verb:getSplashTargets(unit, targetPos, endPos)
    return {}
end

function Verb:getTargetArrows(unit, targetPos, endPos)
    return {}
end

local function positionToCacheKey(position)
    return position.x * 65536 + position.y
end

function Verb:getTargetsInRange(unit, startPos, moveRange, strParam)
    local result = {}

    if self:canExecuteAnywhere(unit) then
        local range = self:getMaximumRange(unit, nil)
        for i, pos in ipairs(moveRange) do
            if self:canExecuteAt(unit, pos) then
                -- OK, this is every place where this command can feasably be used from
                -- Everyone it can reach from here:
                local targetPositions = Wargroove.getTargetsInRangeAfterMove(unit, pos, pos, range, self:getTargetType())

                for j, targetPos in ipairs(targetPositions) do
                    if self:canSeeTarget(targetPos) and self:canExecuteWithTarget(unit, pos, targetPos, strParam) then
                        local key = positionToCacheKey(targetPos)
                        local u = result[key]
                        if u == nil then
                            u = {pos = targetPos, from = { pos }}
                            result[key] = u
                        else
                            table.insert(u.from, pos)
                        end
                    end
                end

            end
        end
    end

    local processed = {}
    for k, v in pairs(result) do
        table.insert(processed, v)
    end
    return processed
end


function Verb:canExecuteWithAnyTarget(unit, endPos, strParam)
    return #(self:getTargets(unit, endPos, strParam)) > 0
end


function Verb:canSeeTarget(targetPos)
    return Wargroove.canPlayerSeeTile(-1, targetPos)
end


function Verb:parseTargets(strParam)
    local targetStrs={}
    local i = 1
    for targetStr in string.gmatch(strParam, "([^"..";".."]+)") do
        targetStrs[i] = targetStr
        i = i + 1
    end

    local targets = {}
    i = 1
    for idx, targetStr in pairs(targetStrs) do
        local vals = {}
        local j = 1
        for val in targetStr.gmatch(targetStr, "([^"..",".."]+)") do
            vals[j] = val
            j = j + 1
        end
        targets[i] = { x = tonumber(vals[1]), y = tonumber(vals[2])}
        i = i + 1
    end

    return targets
end


local function getFacing(from, to)
    local dx = to.x - from.x
    local dy = to.y - from.y

    if math.abs(dx) > math.abs(dy) then
        if dx > 0 then
            return 1 -- Right
        else
            return 3 -- Left
        end
    else
        if dy > 0 then
            return 2 -- Down
        else
            return 0 -- Up
        end
    end
end


function Verb:updateSelfUnit(unit, targetPos, path, usesTurn)
    local endPos = unit.pos
    if path ~= nil and #path > 0 then
        endPos = path[#path]

        if #path >= 2 then
            unit.pos.facing = getFacing(path[#path - 1], path[#path])
        end
    end

    unit.hadTurn = usesTurn
    unit.pos.x = endPos.x
    unit.pos.y = endPos.y
end


--
-- Override these
--


function Verb:getTargetType()
    return nil
end


function Verb:getMaximumRange(unit, endPos)
    return 0
end


function Verb:canExecuteAnywhere(unit)
    return true
end


function Verb:canExecuteAt(unit, endPos)
    return (not Wargroove.canPlayerSeeTile(-1, endPos)) or (not Wargroove.isAnybodyElseAt(unit, endPos))
end


function Verb:canExecuteWithTarget(unit, endPos, targetPos, strParam)
    return true
end

function Verb:preExecute(unit, targetPos, strParam, endPos)
    return true
end

function Verb:execute(unit, targetPos, strParam, path, telegraph)
end


function Verb:getCostAt(unit, endPos, targetPos)
    return 0
end

function Verb:onPostUpdateUnit(...)
end

function Verb:shouldSetMetaLocations()
    return true
end

function Verb:getDynamicName(unit, endPos, targetPos)
    return ""
end

--
-- Halley entry points
--


function Verb:getTargetsEntry(unitId, endPos, strParam)
    return self:getTargets(Wargroove.getUnitById(unitId), endPos, strParam)
end


function Verb:getTargetsInRangeEntry(unitId, startPos, moveRange, strParam)
    return self:getTargetsInRange(Wargroove.getUnitById(unitId), startPos, moveRange, strParam)
end

function Verb:getSplashTargetsEntry(unitId, endPos, strParam)
    return self:getSplashTargets(Wargroove.getUnitById(unitId), endPos, strParam)
end

function Verb:getTargetArrowsEntry(unitId, targetPos, endPos)
    return self:getTargetArrows(Wargroove.getUnitById(unitId), targetPos, endPos)
end

function Verb:getMaximumRangeEntry(unitId, endPos)
    return self:getMaximumRange(Wargroove.getUnitById(unitId), endPos)
end

function Verb:canExecuteEntry(unitId, endPos, targetPos, strParam)
    return self:canExecute(Wargroove.getUnitById(unitId), endPos, targetPos, strParam)
end

function Verb:preExecuteEntry(unitId, targetPos, strParam, endPos)
    return Resumable.run(function ()
        Wargroove.clearCaches()
        local unit = Wargroove.getUnitById(unitId)
        local shouldExecute, strParam = self:preExecute(unit, targetPos, strParam, endPos)
        Wargroove.finishVerbPreExecute(shouldExecute, strParam)
    end)
end

function Verb:executeEntry(unitId, verb, targetPos, strParam, path, usesTurn, telegraph)
    return self:doExecuteEntry(unitId, verb, false, targetPos, strParam, path, usesTurn, telegraph)
end

function Verb:doExecuteEntry(unitId, verb, isGrooveVerb, targetPos, strParam, path, usesTurn, telegraph)
    return Resumable.run(function ()
        Wargroove.clearCaches()
        local unit = Wargroove.getUnitById(unitId)

        self:execute(unit, targetPos, strParam, path, telegraph)

        unit = Wargroove.getUnitById(unitId)

        -- Give post verb scripts an opportunity to do something before self-update
        Wargroove.doPostVerb(unitId, verb)

        -- Unit may have been invalidated in pre combat/post verb, so we get it again
        unit = Wargroove.getUnitById(unitId)

        self:updateSelfUnit(unit, targetPos, path, usesTurn)
        self:onPostUpdateUnit(unit, targetPos, strParam, path)
        Wargroove.updateUnit(unit)

        if self:shouldSetMetaLocations() then
            Wargroove.setMetaLocationArea("last_move_path", path)
            Wargroove.setMetaLocation("last_unit", unit.pos)
        end

        -- Remember the verb use
        Wargroove.reportVerbUsed(unitId, verb, isGrooveVerb, targetPos, strParam, path)
    end)
end


function Verb:getCostAtEntry(unitId, endPos, targetPos)
    return self:getCostAt(Wargroove.getUnitById(unitId), endPos, targetPos)
end


function Verb:getDynamicNameEntry(unitId, endPos, targetPos)
    return self:getDynamicName(Wargroove.getUnitById(unitId), endPos, targetPos)
end


function Verb:generateOrders(unitId, canMove)
    local unit = Wargroove.getUnitById(unitId)
    -- print("generateOrders not implemented for verb.")
    return {}
end

function Verb:getScore(unitId, order)
    local unit = Wargroove.getUnitById(unitId)
    -- print("getScore not implemented for verb.")
    return {score = -1, introspection = {}}
end


--
-- Constructor
--


function Verb:new(o)
    o = o or {}
    setmetatable(o, self)
    self.__index = self
    return o
end


return Verb
