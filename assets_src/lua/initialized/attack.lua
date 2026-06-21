local Wargroove = require "wargroove/wargroove"
local OldAttack = require "verbs/attack"
local Combat = require "wargroove/combat"
local Ragnarok = require "initialized/ragnarok"
local StealthManager = require "scripts/stealth_manager"
local VisionTracker = require "initialized/vision_tracker"
local Stats = require "util/stats"
--local Verb = require "initialized/a_new_verb"
local AIProfile = require "AIProfiles/ai_profile"


local Attack = {}
function Attack.init()
	--Ragnarok.addAction(Attack.revertFlanked,"repeating",true)
	OldAttack.canExecuteWithTarget = Attack.canExecuteWithTarget
	OldAttack.execute = Attack.execute
	OldAttack.onPostUpdateUnit = Attack.onPostUpdateUnit
	OldAttack.canExecuteAt = Attack.canExecuteAt
end
function Attack:canExecuteAt(unit, endPos)
--    if Verb.inInBorderlands(endPos, unit.playerId) then
--        return false
--    end
    local weapons = unit.unitClass.weapons

    if #weapons == 1 and not weapons[1].canMoveAndAttack then
        local moved = endPos.x ~= unit.startPos.x or endPos.y ~= unit.startPos.y
        if moved then
            return false
        end
    end

    return not Wargroove.isAnybodyElseAt(unit, endPos)
end

local flankedId = nil;
function Attack.revertFlanked(context)
	if flankedId ~= nil and context:checkState("endOfUnitTurn") then
		local flanked = Wargroove.getUnitById(flankedId)
		Wargroove.waitFrame()
		Wargroove.clearCaches()
        Wargroove.waitTime(0.5)
		StealthManager.makeUnitAlerted(flankedId,flanker.pos)
        Wargroove.updateUnit(flanked)
		flankedId = nil
	end
end
function Attack:onPostUpdateUnit(unit, targetPos, strParam, path)
end

function Attack:execute(unit, targetPos, strParam, path, telegraph)
    --- Telegraph
    if (not Wargroove.isLocalPlayer(unit.playerId)) and Wargroove.canCurrentlySeeTile(targetPos) and telegraph then
        Wargroove.spawnMapAnimation(targetPos, 0, "ui/grid/selection_cursor", "target", "over_units", {x = -4, y = -4})
        Wargroove.waitTime(0.5)
    end

    local target = Wargroove.getUnitAt(targetPos)
	local defenderIsHighAlert = Wargroove.getUnitState(target, "high_alert")

	if defenderIsHighAlert~=nil and defenderIsHighAlert == "true" and self:canExecuteWithTarget(target, targetPos, unit.pos, "") then
        Combat:startReverseCombat(unit, target, path)
    else
        Wargroove.startCombat(unit, target, path, "average")
    end
    --[[
    local attackerWitnessIds
    if path[#path]~=nil then
        attackerWitnessIds = VisionTracker.getListOfViewerIds(path[#path])
    else
        attackerWitnessIds = VisionTracker.getListOfViewerIds(targetPos)
    end
    local defenderWitnessIds = VisionTracker.getListOfViewerIds(targetPos)
    local witnesses = {}
    for i,witnessId in ipairs(attackerWitnessIds) do
        witnesses[witnessId] = true
    end
    for i,witnessId in ipairs(defenderWitnessIds) do
        witnesses[witnessId] = true
    end
    for witnessId,exists in pairs(witnesses) do
        local witness = Wargroove.getUnitById(witnessId)
        if witness ~= nil then
            if StealthManager.isActive(witness.playerId) then
                StealthManager.awarenessCheck(unit, {path[#path]})
                if (witness~=nil) and (StealthManager.canBeAlerted(witness)) and Wargroove.areEnemies(unit.playerId,witness.playerId) then
                    StealthManager.makeAlerted(witness)
                    StealthManager.setLastKnownLocation(witness,unit.pos)
                    break
                end
            end
        end
    end]]
end



function Attack:canExecuteWithTarget(unit, endPos, targetPos, strParam)
    if strParam == "always" then
        return true
    end
    if not self:canSeeTarget(targetPos) then
        return false
    end
    local weapons = unit.unitClass.weapons
    if #weapons == 1 and weapons[1].horizontalAndVerticalOnly then
        local xDiff = math.abs(endPos.x - targetPos.x)
        local yDiff = math.abs(endPos.y - targetPos.y)
        local maxDiff = weapons[1].horizontalAndVerticalExtraWidth
        if (xDiff > maxDiff and yDiff > maxDiff) then
            return false
        end

        if weapons[1].blockedByEnemies and (xDiff > 1 or yDiff > 1) then
            local xDelta = endPos.x - targetPos.x
            local yDelta = endPos.y - targetPos.y

            -- Otherwise we march either horizontally/vertically along the position and check for enemies
            if xDiff > yDiff then
                -- horizontal walk
                local xStep = xDelta < 0 and -1 or 1
                local tmpPosX = targetPos.x + xStep

                while tmpPosX ~= endPos.x
                do
                    local targetUnit = Wargroove.getUnitAt({x = tmpPosX, y = targetPos.y})
                    if targetUnit and Wargroove.areEnemies(targetUnit.playerId, unit.playerId) then
                        return false
                    end
                    local targetTerrain = Wargroove.getTerrainNameAt({x = tmpPosX, y = targetPos.y})
                    if Stats.isTerrainBlocking(targetTerrain) then
                        return false
                    end


                    tmpPosX = tmpPosX + xStep
                end
            else 
                -- vertical walk OR same x/y, so we just do a vertical walk
                local yStep = yDelta < 0 and -1 or 1
                local tmpPosY = targetPos.y + yStep

                while tmpPosY ~= endPos.y
                do
                    local targetUnit = Wargroove.getUnitAt({x = targetPos.x, y = tmpPosY })
                    if targetUnit and Wargroove.areEnemies(targetUnit.playerId, unit.playerId) then
                        return false
                    end
                    local targetTerrain = Wargroove.getTerrainNameAt({x = targetPos.x, y = tmpPosY})
                    if Stats.isTerrainBlocking(targetTerrain) then
                        return false
                    end

                    tmpPosY = tmpPosY + yStep
                end
            end
        end
    end

    if #weapons == 1 and #(weapons[1].terrainExclusion) > 0 then
        local targetTerrain = Wargroove.getTerrainNameAt(targetPos)
        for i, terrain in ipairs(weapons[1].terrainExclusion) do
            if targetTerrain == terrain then
                return false
            end
        end
    end

    local targetUnit = Wargroove.getUnitAt(targetPos)

    if not targetUnit or not Wargroove.areEnemies(unit.playerId, targetUnit.playerId) then
        return false
    end

    if #weapons == 1 and weapons[1].maxRange > 1 and targetUnit.canBeAttackedFromDistance == false then
        return false
    end
    
    if #weapons == 1 and weapons[1].unitIdWhenAttacking ~= "" and weapons[1].unitIdWhenAttacking ~= unit.unitClass then

        if not Wargroove.canStandAt(weapons[1].unitIdWhenAttacking, endPos) then
            return false
        end
    end

    if targetUnit.canBeAttacked ~= nil and (not targetUnit.canBeAttacked or not targetUnit.unitClass.isAttackable) then
      return false
    end
    if targetUnit.unitClass.isStructure and not AIProfile.canAttackBuildings(unit.playerId) then
        return false
    end
    local result = Combat:solveCombat(unit.id, targetUnit.id, {endPos}, "average")
    if Wargroove.unitHasState(unit, "refuseToKill", targetUnit.unitClassId) then
        if result.defenderHealth == nil or result.defenderHealth<=0 then
            return false
        end
    end
    if Wargroove.unitHasState(unit, "refuseToDie") then
        if result.attackerHealth == nil or result.attackerHealth<=0 then
            return false
        end
    end
    
    return Combat:getBaseDamage(unit, targetUnit, endPos) > 0.001
end


return Attack
