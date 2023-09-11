local Verb = require "wargroove/verb"
local Wargroove = require "wargroove/wargroove"
local AIManager = require "initialized/ai_manager"
local StealthManager = require "scripts/stealth_manager"

local WaitAI = Verb:new()

local function dump(o,level)
    if type(o) == 'table' then
       local s = '\n' .. string.rep("   ", level) .. '{\n'
       for k,v in pairs(o) do
          if type(k) ~= 'number' then k = '"'..k..'"' end
          s = s .. string.rep("   ", level+1) .. '['..k..'] = ' .. dump(v,level+1) .. ',\n'
       end
       return s .. string.rep("   ", level) .. '}'
    else
       return tostring(o)
    end
 end
function WaitAI:canExecuteAnywhere(unit)
    return (not Wargroove.isHuman(unit.playerId))
end

function WaitAI:execute(unit, targetPos, strParam, path)
end

function WaitAI:generateOrders(unitId, canMove)
    local unit = Wargroove.getUnitById(unitId)
    local unitClass = Wargroove.getUnitClass(unit.unitClassId)
    
    local orders = {{targetPosition = unit.pos, strParam = "0", movePosition = unit.pos, endPosition = unit.pos}}
    if (not canMove) then
        return orders
    end
    local target, distMoved, dist = AIManager.getNextPosition(unitId)
    if (target ~= nil) then
        local score = 0
        if dist>0 then
            score = 100+((1.0*distMoved)/dist)*100.0
        end
        table.insert(orders, {targetPosition = target, strParam = tostring(score), movePosition = target, endPosition = target})
    end
    -- local movePositions = Wargroove.getTargetsInRange(unit.pos, unitClass.moveRange, "empty")
    -- table.insert(orders, {targetPosition = unit.pos, strParam = "", movePosition = unit.pos, endPosition = unit.pos})
        
    -- for i, targetPos in ipairs(movePositions) do
    --     if Wargroove.canStandAt(unitClass.id, targetPos) then
    --         table.insert(orders, {targetPosition = targetPos, strParam = "", movePosition = targetPos, endPosition = targetPos})
    --     end
    -- end
    
    return orders
end

function WaitAI:getScore(unitId, order)
    local score = tonumber(order.strParam)
    return {score = score, introspection = {}}
    -- local target, distMoved, dist = AIManager.getNextPosition(unitId)
    -- local unit = Wargroove.getUnitById(unitId)

    -- if (target ~= nil) then
    --     local score = 0
    --     if dist>0 then
    --         score = 100+((1.0*distMoved)/dist)*100.0
    --     end
    --     if (target.x == order.endPosition.x) and (target.y == order.endPosition.y) then
    --         return {score = score, introspection = {}}
    --     else
    --         return {score = -1, introspection = {}}
    --     end
    -- end
    -- return {score = -1, introspection = {}}
end

return WaitAI