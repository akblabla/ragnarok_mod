local Wargroove = require "wargroove/wargroove"
local GrooveVerb = require "wargroove/groove_verb"
local Combat = require "wargroove/combat"


local Ram = GrooveVerb:new()
local function clamp(val, min, max)
    return math.max(min, math.min(max, val))
end
local function breakOnTerrain(unit,endPos)
    -- Sound and splash(?)
    if Wargroove.isWater(endPos) or Wargroove.getTerrainNameAt(endPos) == "river" then
        local splashFX = Wargroove.getSplashEffect()
        Wargroove.spawnMapAnimation(endPos, 1, splashFX)
        Wargroove.playMapSound("unitSplash", endPos)
    else
        Wargroove.playMapSound("wulfar/wulfarGrooveUnitLanding", endPos)
    end

    -- Break?
    if not Wargroove.canStandAt(endPos.unitClassId, endPos) then
        if not Wargroove.isWater(endPos) then
            Wargroove.spawnMapAnimation(endPos, 1, "fx/unit_ship_break")
        end
        Wargroove.removeUnit(unit.id)
        Wargroove.setVisibleOverride(endPos.id, false)
    end
end

function Ram:getTier(unit)
    return 1
end

function Ram:consumeGroove(unit)
    local groove = Wargroove.getGroove(self:getGrooveId(unit))
    unit.grooveChargeOnUse = unit.grooveCharge
    unit.grooveCharge = unit.grooveCharge-groove.grooveCost[1]
    if unit.grooveCharge<0 then unit.grooveCharge = 0 end
    Wargroove.updateUnit(unit)
end

function Ram:getMaximumRange(unit, endPos)
    return 3
end


function Ram:getTargetType()
    return "all"
end


function Ram:canExecuteWithTarget(unit, endPos, targetPos, strParam)
    if not self:canSeeTarget(targetPos) then
        return false
    end

    --Must actually move
    if targetPos.x == endPos.x and targetPos.y == endPos.y then
        return false
    end

    --Only cardinal lines
    if not (targetPos.x == endPos.x or targetPos.y == endPos.y) then
        return false
    end

    return Wargroove.canStandAt("commander_flagship_wulfar", targetPos)
end

function Ram:getTargetArrows(unit, targetPos, endPos)
    local results = {}

    local targetUnit = Wargroove.getUnitAt(targetPos)
    local pushResults = Wargroove.getPushPullResult(endPos, targetPos, 1, false, false)
    if pushResults == nil then return results end
    if pushResults["pushTargetUnit"] and not pushResults["isBreakPosition"] then
        Wargroove.pushUnitPos(targetUnit, pushResults["pushPosition"])
        pushResults = Wargroove.getPushPullResult(endPos, pushResults["pushPosition"], 1, false, false)
        Wargroove.popUnitPos()
    end
    local targetArrow = Wargroove.createTargetArrowFromPushPullResult(pushResults)
    table.insert(results, targetArrow)

    return results
end
local currentPos
function Ram:execute(unit, targetPos, strParam, path)
    print("Ram:execute(unit, targetPos, strParam, path)")
    Wargroove.setIsUsingGroove(unit.id, true)
    local endPos = path[#path]
    local endFacing = (targetPos.x < endPos.x and 1 or 3)
    unit.pos.facing = endFacing
    Wargroove.updateUnit(unit)
    if unit.pos.x>targetPos.x then
        Wargroove.setFacingOverride(unit.id, "left")
    elseif unit.pos.x<targetPos.x then
        Wargroove.setFacingOverride(unit.id, "right")
    end
    currentPos = endPos
    local deltaX = clamp(targetPos.x - endPos.x, -1, 1)
    local deltaY = clamp(targetPos.y - endPos.y, -1, 1)
    local targetUnit = nil
    local finalResult = nil
    local pushed = false
    print("Delta Pos is: ".. deltaX..", "..deltaY)
    while not (targetPos.x == currentPos.x and targetPos.y == currentPos.y) do
        
        local currentTargetPos = {x = currentPos.x+deltaX, y = currentPos.y+deltaY}
        print("Current Target Pos is: ".. currentTargetPos.x..", "..currentTargetPos.y)
        targetUnit = Wargroove.getUnitAt(currentTargetPos)

        if targetUnit~=nil then
            print("Current Target Unit is a: ".. targetUnit.unitClassId)

            if not Wargroove.isValidPushPullTarget(targetUnit, false) then
                break
            end
            local pushResults = Wargroove.getPushPullResult(currentPos, currentTargetPos, 1, false, false)
            if pushResults == nil then break end
            finalResult = pushResults
            if pushResults["pushTargetUnit"] then
                pushed = true
                if pushResults["isBreakPosition"] then
                    currentPos = currentTargetPos
                    break
                else
                    Wargroove.pushUnitPos(targetUnit, pushResults["pushPosition"])
                end
            else
                break
            end
        end
        currentPos = currentTargetPos
    end
    Wargroove.popAllUnitPos()
    Wargroove.waitTime(0.2)
    Wargroove.moveUnitToOverride(unit.id, unit.pos, -0.2*deltaX, -0.2*deltaY, 1.5)
    Wargroove.playMapSound("wulfar/wulfarMiniGrooveRam", endPos)
    if deltaY == 0 then
        Wargroove.playUnitAnimation(unit.id, "run", "run")
    elseif deltaY>0 then
        Wargroove.playUnitAnimation(unit.id, "run_down", "run_down")
    else
        Wargroove.playUnitAnimation(unit.id, "run_up", "run_up")
    end
    Wargroove.waitTime(1.05)
    Wargroove.playMapSound("wulfar/wulfarMiniGrooveRamWave", endPos)
    Wargroove.waitTime(0.1)
    Wargroove.moveUnitToOverride(unit.id, currentPos, 0, 0, 10)
    if targetUnit~=nil then
        local dist = math.abs(endPos.x-targetUnit.pos.x)+math.abs(endPos.y-targetUnit.pos.y)
        Wargroove.waitTime(dist*0.1-0.075)
        --Wargroove.playMapSound("shipDie",targetUnit.pos)
        Wargroove.playMapSound("wulfar/wulfarMiniGrooveRamHit",targetUnit.pos)
        local damage = Combat:getGrooveAttackerDamage(unit, targetUnit, "average", targetUnit.pos, targetUnit.pos, path, nil) * 0.5
        targetUnit:setHealth(targetUnit.health - damage, unit.id)
        Wargroove.updateUnit(targetUnit)
        if finalResult~=nil then
            finalResult["pushTargetUnit"] = pushed
            Wargroove.processPushPullResult(unit, finalResult, 0, 20)
        end
    
        Wargroove.updateUnit(targetUnit)
    end
    while Wargroove.isLuaMoving(unit.id) do
        coroutine.yield()
    end
    Wargroove.playUnitAnimation(unit.id, "idle", "idle")
end

function Ram:onPostUpdateUnit(unit, targetPos, strParam, path)
    GrooveVerb.onPostUpdateUnit(self, unit, targetPos, strParam, path)
    local endPos = path[#path]
    local endFacing = (targetPos.x < endPos.x)
    unit.pos.facing = endFacing
    unit.pos.x = currentPos.x
    unit.pos.y = currentPos.y
end

return Ram
