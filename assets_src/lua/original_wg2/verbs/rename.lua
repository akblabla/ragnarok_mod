local Wargroove = require "wargroove/wargroove"
local Verb = require "wargroove/verb"
local Rename = Verb:new()

function Rename:canExecute(unit, endPos, targetPos, strParam)
    local targetUnit = Wargroove.getUnitAt(endPos)

    if targetPos then
        local actualTarget = Wargroove.getUnitAt(targetPos)

        if actualTarget and actualTarget.id ~= unit.id then
            return false
        end
    end

    return Wargroove.canRenameUnit(unit.id) and targetUnit and targetUnit.id == unit.id
end

function Rename:execute(unit, targetPos, strParam, path)
    Wargroove.showRenameWindow(unit.id)
end

function Rename:onPostUpdateUnit(unit, targetPos, strParam, path)
    Verb.onPostUpdateUnit(self, unit, targetPos, strParam, path)

    unit.hadTurn = false
    Wargroove.updateUnit(unit)
end

return Rename
