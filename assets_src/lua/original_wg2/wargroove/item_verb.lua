local Verb = require "wargroove/verb"
local Wargroove = require "wargroove/wargroove"
local Resumable = require "wargroove/resumable"
local ItemScores = require "wargroove/item_scores"

local ItemVerb = Verb:new()

function ItemVerb:new(o)
    o = o or {}
    setmetatable(o, self)
    self.__index = self
    return o
end

function ItemVerb:executeEntry(unitId, verb, targetPos, strParam, path, usesTurn)
    Wargroove.consumeItemAt(path[#path])
    return Resumable.run(function ()
        Wargroove.clearCaches()
        local unit = Wargroove.getUnitById(unitId)
        self:execute(unit, targetPos, strParam, path)

        -- Give post verb scritps an opportunity to do something before self-update
        Wargroove.doPostVerb(unitId)

        -- Unit may have been invalidated in pre combat/post verb, so we get it again
        unit = Wargroove.getUnitById(unitId)

        self:updateSelfUnit(unit, targetPos, path)
        self:onPostUpdateUnit(unit, targetPos, strParam, path)
        Wargroove.updateUnit(unit)

        Wargroove.setMetaLocationArea("last_move_path", path)
        Wargroove.setMetaLocation("last_unit", unit.pos)

        -- Remember the verb use
        Wargroove.reportVerbUsed(unitId, verb, targetPos, strParam, path)
    end)
end

function ItemVerb:generateOrders(unitId, canMove)
    local unit = Wargroove.getUnitById(unitId)
    if unit.itemId ~= "" then
        local item = Wargroove.getItem(unit.itemId)
        print("generateOrders not implemented for item " .. item.id)
    else
        print("unit does not hold any item")
    end
    return {}
end

function ItemVerb:getScore(unitId, order)
    local score = {score = -1, introspection = {}}
    local unit = Wargroove.getUnitById(unitId)
    if unit.itemId ~= "" then
        local item = Wargroove.getItem(unit.itemId)
        score = ItemScores.getScoreForItem(item.id, unitId, order)
    end
    return score
end

return ItemVerb
