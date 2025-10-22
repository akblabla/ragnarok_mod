local Wargroove = require "wargroove/wargroove"
local GrooveVerb = require "wargroove/groove_verb"
local Combat = require "wargroove/combat"
local BlockChecker = require "util/blockChecker"
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

local Gun = GrooveVerb:new()
local grooveDamage = 1
local function clamp(val, min, max)
    return math.max(min, math.min(max, val))
end
function Gun:getTier(unit)
    return 1;
end

function Gun:consumeGroove(unit)
    local groove = Wargroove.getGroove(self:getGrooveId(unit))
    unit.grooveChargeOnUse = unit.grooveCharge
    unit.grooveCharge = unit.grooveCharge-groove.grooveCost[1]
    if unit.grooveCharge<0 then unit.grooveCharge = 0 end
    Wargroove.updateUnit(unit)
end

function Gun:getMaximumRange(unit, endPos)
    return 4
end


function Gun:getTargetType()
    return "all"
end


function Gun:preExecute(unit, targetPos, strParam, endPos)

    local target = nil
    local deltaPosList = {{x = 1, y=0}, {x = 0, y=1}, {x = -1, y=0}, {x = 0, y=-1}}
    for i, deltaPos in ipairs(deltaPosList) do
        local j = 1
        local currentPos = {x = endPos.x, y = endPos.y}
        while j <= Gun:getMaximumRange(unit, endPos) do
            local nextPos = {x = currentPos.x + deltaPos.x, y = currentPos.y + deltaPos.y}
            local target = Wargroove.getUnitAt(nextPos)
            if Gun:validTarget(unit, target) then
                Wargroove.displayTarget(nextPos)
            end
            if BlockChecker.isBlocked(currentPos,nextPos) then
                break
            end
            currentPos = {x = nextPos.x, y = nextPos.y}
            j = j + 1
        end
    end
    while true do
        Wargroove.selectTarget()

        while Wargroove.waitingForSelectedTarget() do
            coroutine.yield()
        end

        local pretargetPos = Wargroove.getSelectedTarget()
        if (pretargetPos == nil) then
            Wargroove.clearDisplayTargets()
            coroutine.yield()
            return false, ""
        end
        target = Wargroove.getUnitAt(pretargetPos)
        print("pretargetPos")
        print(dump(pretargetPos,0))
        print("target")
        print(dump(target,0))
        if Gun:validTarget(unit, target) then
            break
        end
    end
    Wargroove.clearDisplayTargets()
    coroutine.yield()
    if target == nil then
        return false, ""
    end
    local result = ""
    result = target.pos.x .. "," .. target.pos.y .. ";"

    Wargroove.waitFrame()

    return true, result
end

function Gun:canExecuteWithTarget(unit, endPos, targetPos, strParam)
    if not self:canSeeTarget(targetPos) then
        return false
    end

    --can't target self
    if targetPos.x == endPos.x and targetPos.y == endPos.y then
        return false
    end

    --Only cardinal lines
    if not (targetPos.x == endPos.x or targetPos.y == endPos.y) then
        return false
    end
    if BlockChecker.isBlocked(endPos, targetPos, unit.playerId) then
        return false
    end

    return true
end


function Gun:validTarget(unit, target)
    if target == nil then
        return false
    end
    if not Wargroove.areEnemies(unit.playerId, target.playerId) then
        return false
    end
    
    if not target.canBeAttacked then
        return false
    end
    if not target.unitClass.isAttackable then
        return false
    end
    return true
end

function Gun:getSplashTargets(unit, targetPos, endPos)
    local targets = Wargroove.getTargetsInRange(endPos, Gun:getMaximumRange(unit, endPos), "all")
    return targets
end

function Gun:execute(unit, targetPos, strParam, path)
    local targets = self:parseTargets(strParam)
    local tier = self:getCurrentGrooveTier(unit)
    targetPos = {x = targets[1].x, y = targets[1].y}


    Wargroove.setIsUsingGroove(unit.id, true)
    local endFacing = (targetPos.x > unit.pos.x and 1 or 3)
    unit.pos.facing = endFacing

    Wargroove.updateUnit(unit)

    Wargroove.playPositionlessSound("battleStart")
    Wargroove.playGrooveCutscene(unit.id, tier)

    local facingOverride = ""
    local grooveSequence = ""
    local effectSequence = ""
    local effectOffset = { x = 0, y = 0 }
    if targetPos.y == unit.pos.y then
        if math.abs(targetPos.x-unit.pos.x) == 1 then
            grooveSequence = "mini_groove_close"
        else
            grooveSequence = "mini_groove"
        end
        effectSequence = "right_" .. math.abs(targetPos.x-unit.pos.x)
        effectOffset = { x = 12, y = 24 }
    elseif targetPos.y > unit.pos.y then
        grooveSequence = "mini_groove_down"
        effectSequence = "down_" .. math.abs(targetPos.y-unit.pos.y)
        effectOffset = { x = 12, y = 24 }
    else
        grooveSequence = "mini_groove_up"
        effectSequence = "up_" .. math.abs(targetPos.y-unit.pos.y)
        effectOffset = { x = 12, y = 0 }
    end
    if targetPos.x > unit.pos.x then
        facingOverride = "right"
    else 
        facingOverride = "left"
    end

    Wargroove.setFacingOverride(unit.id, facingOverride)
    Wargroove.waitTime(0.2)

    Wargroove.playUnitAnimation(unit.id, grooveSequence)
    Wargroove.playMapSound("duchess/duchessMiniGroove", unit.pos)
    Wargroove.waitTime(1.3)
    Wargroove.spawnMapAnimation(unit.pos, 0, "fx/groove/a_fix_fx", effectSequence, "units", effectOffset, facingOverride)

    local target = Wargroove.getUnitAt(targetPos)

    if Gun:validTarget(unit, target) then
        -- Potentially change this to commander weapon damage
        local damage = Combat:getGrooveAttackerDamage(unit, target, "average", unit.pos, targetPos, path, nil) * grooveDamage *0.5
        if not target.unitClass.isCommander and Wargroove.doesUnitHaveTag(target, {"type.ground.light", "type.amphibious.light"}) then
            damage = damage *2
        end
        target:setHealth(target.health - damage, unit.id)
        Wargroove.updateUnit(target)
        Wargroove.playUnitAnimation(target.id, "hit")
    end
    Wargroove.waitTime(0.1)
    Wargroove.playGrooveEffect()
    

    Wargroove.logAnalyticsAction("UnitAbility", unit.playerId, "groove", unit.unitClassId)
end

function Gun:onPostUpdateUnit(unit, targetPos, strParam, path)
    GrooveVerb.onPostUpdateUnit(self, unit, targetPos, strParam, path)
    local endPos = path[#path]
    local endFacing = (targetPos.x > unit.pos.x and 1 or 3)
    unit.pos.facing = endFacing
end
return Gun
