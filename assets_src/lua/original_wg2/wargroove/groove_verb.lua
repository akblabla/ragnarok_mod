local Verb = require "wargroove/verb"
local Wargroove = require "wargroove/wargroove"
local Resumable = require "wargroove/resumable"

local GrooveVerb = Verb:new()

function GrooveVerb:consumeGroove(unit)
    local groove = Wargroove.getGroove(self:getGrooveId(unit))
    unit.grooveChargeOnUse = unit.grooveCharge
    unit.grooveCharge = 0
    Wargroove.updateUnit(unit)
end

function GrooveVerb:canExecuteEntry(unitId, endPos, targetPos, strParam)
    local unit = Wargroove.getUnitById(unitId)
    return self:canExecuteGroove(unit) and self:canExecute(unit, endPos, targetPos, strParam)
end

function GrooveVerb:executeEntry(unitId, verb, targetPos, strParam, path, usesTurn, telegraph)
    local unit = Wargroove.getUnitById(unitId)
    local tier = self:getCurrentGrooveTier(unit)
    local returnValue = self:doExecuteEntry(unitId, verb, true, targetPos, strParam, path, usesTurn, telegraph)

    if tier == 2 then
        Wargroove.unlockAchievement("complete_super_groove")
    end

    return returnValue
end

function GrooveVerb:onPostUpdateUnit(unit, targetPos, strParam, path)
    self:consumeGroove(unit)
    Wargroove.setIsUsingGroove(unit.id, false)
end


function GrooveVerb:new(o)
    o = o or {}
    setmetatable(o, self)
    self.__index = self
    return o
end

function GrooveVerb:getGrooveId(unit)
    return unit.grooveId;
end

function GrooveVerb:getCurrentGrooveTier(unit)
    local groove = Wargroove.getGroove(self:getGrooveId(unit))
    if unit.grooveCharge >= groove.grooveCost[1] and unit.grooveCharge < groove.grooveCost[2] then
        return 1
    elseif unit.grooveCharge >= groove.grooveCost[2] then
        return 2
    end

    return 1
end

function GrooveVerb:calculateScore(unitId, order, randomize)
    local result = self:getScore(unitId, order)

    if randomize then
        local unit = Wargroove.getUnitById(unitId)
        local tier = self:getCurrentGrooveTier(unit)

        -- pseudo-randomize the outcome a little
        local str = unitId .. "/" .. unit.pos.x .. "," .. unit.pos.y
        local rnd = 0.5 + Wargroove.pseudoRandomFromString(str) * 0.75

        -- multiply score with randomized scale
        result.score = result.score * tier * rnd
    end
    
    return result
end

--
-- Override these
--

function GrooveVerb:canExecuteGroove(unit)
    local groove = Wargroove.getGroove(self:getGrooveId(unit))
    return unit.grooveCharge >= groove.grooveCost[1]
end


function GrooveVerb:canExecuteAnywhere(unit)
    return self:canExecuteGroove(unit)
end


function GrooveVerb:generateOrders(unitId, canMove)
    local unit = Wargroove.getUnitById(unitId)
    print("generateOrders not implemented for " .. unit.unitClassId  .. "'s groove.")
    return {}
end


function GrooveVerb:getScore(unitId, order)
    local unit = Wargroove.getUnitById(unitId)
    print("getScore not implemented for " .. unit.unitClassId  .. "'s groove.")
    return {score = -1, introspection = {}}
end

return GrooveVerb
