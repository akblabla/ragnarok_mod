local Verb = require "wargroove/verb"
local Wargroove = require "wargroove/wargroove"
local Resumable = require "wargroove/resumable"

local GrooveVerb = Verb:new()


function GrooveVerb:canExecuteGroove(unit)
    local groove = Wargroove.getGroove(unit.grooveId)
    return (unit.grooveCharge >= groove.chargePerUse)
end


function GrooveVerb:consumeGroove(unit)
    local groove = Wargroove.getGroove(unit.grooveId)
    unit.grooveCharge = unit.grooveCharge - groove.chargePerUse
    Wargroove.updateUnit(unit)
end

function GrooveVerb:canExecuteAnywhere(unit)
    local groove = Wargroove.getGroove(unit.grooveId)
    return (unit.grooveCharge >= groove.chargePerUse)
end


function GrooveVerb:canExecuteEntry(unitId, endPos, targetPos, strParam)
    local unit = Wargroove.getUnitById(unitId)
    return self:canExecuteGroove(unit) and self:canExecute(unit, endPos, targetPos, strParam)
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
