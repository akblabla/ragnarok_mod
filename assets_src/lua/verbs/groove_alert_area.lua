local Wargroove = require "wargroove/wargroove"
local GrooveVerb = require "wargroove/groove_verb"
local StealthManager = require "scripts/stealth_manager"
local AIManager = require "initialized/ai_manager"

local AreaAlert = GrooveVerb:new()

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

function AreaAlert:getMaximumRange(unit, endPos)
    return 12
end

function AreaAlert:getTargetType()
  return "all"
end

function AreaAlert:canExecuteWithTarget(unit, endPos, targetPos, strParam)
    if not self:canSeeTarget(targetPos) then
        return false
    end

    return true
end

function AreaAlert:execute(unit, targetPos, strParam, path)
    Wargroove.trackCameraTo(unit.pos)

    Wargroove.setIsUsingGroove(unit.id, true)
    Wargroove.updateUnit(unit)
    
    Wargroove.playPositionlessSound("battleStart")
    Wargroove.playGrooveCutscene(unit.id, "area_alert", "caesar")
        
    --Wargroove.playUnitAnimation(unit.id, "groove2")
    Wargroove.playMapSound("twins/orlaGroove", unit.pos)
    Wargroove.waitTime(1.9)
	Wargroove.trackCameraTo(targetPos)
    Wargroove.playMapSound("twins/orlaGrooveEffect", targetPos)
    Wargroove.spawnMapAnimation(targetPos, 2, "fx/groove/orla_groove_fx", "idle", "behind_units", {x = 12, y = 12})

    Wargroove.playGrooveEffect()

    local tiles = Wargroove.getTargetsInRange(targetPos,2,"unit")
    local units ={}
    for i, tile in pairs(tiles) do
        local unit = Wargroove.getUnitAt(tile)
        if (unit~=nil) and StealthManager.makePermaAlerted(unit) then
            table.insert(units,unit)
            AIManager.clearOrder(unit.id)
            Wargroove.setAIRestriction(unit.id, "cant_capture", false)
            Wargroove.setAIRestriction(unit.id, "cant_recruit", false)
            Wargroove.setAIRestriction(unit.id, "cant_attack", false)
            Wargroove.setAIRestriction(unit.id, "cant_move", false)
            Wargroove.setAIRestriction(unit.id, "cant_look_ahead", false)
            Wargroove.setAIRestriction(unit.id, "reckless", true)
            
        end
    end
    local function comp(a, b)
        local sqrDistA = (a.pos.x-targetPos.x)^2+(a.pos.y-targetPos.y)^2
        local sqrDistB = (b.pos.x-targetPos.x)^2+(b.pos.y-targetPos.y)^2
        return sqrDistA<sqrDistB
    end
    table.sort(units, comp)
    local lastDist = nil
    for i, unit in ipairs(units) do
        local dist = math.sqrt((unit.pos.x-targetPos.x)^2+(unit.pos.y-targetPos.y)^2)
        if lastDist~= nil then
           Wargroove.waitTime((dist-lastDist)/20) 
        end
        StealthManager.updateAwareness(unit.id)
        lastDist = dist
    end
    Wargroove.waitTime(1.2)
end

function AreaAlert:generateOrders(unitId, canMove)
    local orders = {}

    local unit = Wargroove.getUnitById(unitId)
    local unitClass = Wargroove.getUnitClass(unit.unitClassId)
    local movePositions = {}
    if canMove then
        movePositions = Wargroove.getTargetsInRange(unit.pos, unitClass.moveRange, "empty")
    end
    table.insert(movePositions, unit.pos)

    for i, pos in pairs(movePositions) do
        local targetPosList = Wargroove.getTargetsInRange(pos, AreaAlert:getMaximumRange(unit, pos), "empty")
        for j, targetPos in pairs(targetPosList) do
            if self:canSeeTarget(targetPos) then
                orders[#orders+1] = {targetPosition = targetPos, strParam = "", movePosition = pos, endPosition = pos}
            end
        end
    end

    return orders
end

function AreaAlert:getScore(unitId, order)
    local unit = Wargroove.getUnitById(unitId)
    local targets = Wargroove.getTargetsInRangeAfterMove(unit, order.endPosition, order.targetPosition, 2, "unit")

    local opportunityCost = -1
    local totalScore = 0
    local maxScore = 250

    for i, pos in ipairs(targets) do
        local u = Wargroove.getUnitAt(pos)
        if u ~= nil then
            local uc = u.unitClass
            if (u.playerId == unit.playerId) then
                local score = 0
                if  StealthManager.canBeAlerted(u) then
                    score = (u.unitClass.cost+100)*u.health/100.0
                end
                if u.unitClassId == "port" then
                    score = 50000
                end
                if u.unitClassId == "barracks" then
                    score = 30000
                end
                if u.unitClassId == "commander_duke" then
                    score = 10000
                end
                local multiplier = 0
                if StealthManager.isUnitUnaware(u) then
                    multiplier = 1
                end
                if StealthManager.isUnitSearching(u) then
                    multiplier = 0.5
                end
                if StealthManager.isUnitAlerted(u) then
                    multiplier = 0.25
                end
                if StealthManager.isUnitPermaAlerted(u) then
                    multiplier = 0
                end
                if Wargroove.hasAIRestriction(u.id, "cant_move") then
                    multiplier = multiplier*2
                end

                totalScore = totalScore + score*multiplier
            end
        end
    end
    
    local score = totalScore/maxScore + opportunityCost
    return {score = score, introspection = {{key = "totalScore", value = totalScore}}}
end

return AreaAlert
