local Wargroove = require "wargroove/wargroove"
local Capture = require "verbs/capture"

local CaptureAI = Capture:new()

function CaptureAI:canExecuteAnywhere(unit)
    return not Wargroove.isHuman(unit.playerId)
end
function CaptureAI:getScore(unitId, order)
    local unit = Wargroove.getUnitById(unitId)
    local target = Wargroove.getUnitAt(order.targetPosition)
    local captureScore = Wargroove.getUnitState(target, "captureScore")
    if captureScore ~= nil and captureScore ~= "" then
        return {score = tonumber(captureScore)*unit.health / 100, introspection = {}}
    end
    return {score = -1, introspection = {}}
end

return CaptureAI
