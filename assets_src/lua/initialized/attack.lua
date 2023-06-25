local Wargroove = require "wargroove/wargroove"
local OldAttack = require "verbs/attack"
local Combat = require "wargroove/combat"
local Ragnarok = require "initialized/ragnarok"
local StealthManager = require "scripts/stealth_manager"
local Stats = require "util/stats"
local Verb = require "initialized/a_new_verb"


local Attack = {}
function Attack.init()
	Ragnarok.addAction(Attack.revertFlanked,"repeating",true)
	OldAttack.canExecuteWithTarget = Attack.canExecuteWithTarget
	OldAttack.execute = Attack.execute
	OldAttack.onPostUpdateUnit = Attack.onPostUpdateUnit
	OldAttack.canExecuteAt = Attack.canExecuteAt
	
end


function Attack:canExecuteAt(unit, endPos)
    if Verb.inInBorderlands(endPos, unit.playerId) then
        return false
    end
    local weapons = unit.unitClass.weapons

    if #weapons == 1 and not weapons[1].canMoveAndAttack then
        local moved = endPos.x ~= unit.startPos.x or endPos.y ~= unit.startPos.y
        if moved then
            return false
        end
    end

    return not Wargroove.isAnybodyElseAt(unit, endPos)
end

local function getFacing(from, to)
    local dx = to.x - from.x
    local dy = to.y - from.y

    if math.abs(dx) > math.abs(dy) then
        if dx > 0 then
            return 1 -- Right
        else
            return 3 -- Left
        end
    else
        if dy > 0 then
            return 2 -- Down
        else
            return 0 -- Up
        end
    end
end

local flankerId = nil;
local flankedId = nil;
function Attack.revertFlanked(context)
	if flankedId ~= nil and context:checkState("endOfUnitTurn") then
		local flanked = Wargroove.getUnitById(flankedId)
		local flanker = Wargroove.getUnitById(flankerId)
		-- if flanked ~= nil and flanked.unitClassId == "soldier_flanked" then
		-- 	flanked.unitClassId = "soldier"
		-- 	flanked.pos.facing = getFacing(flanked.pos, flanker.pos)
		-- 	Wargroove.updateUnit(flanked)
		-- end
		Wargroove.waitFrame()
		Wargroove.clearCaches()
        Wargroove.waitTime(0.5)
		StealthManager.makeUnitAlerted(flankedId,flanker.pos)
        Wargroove.updateUnit(flanked)
		flankedId = nil
		flankerId = nil
	end
end

function Attack:onPostUpdateUnit(unit, targetPos, strParam, path)

end

function Attack:execute(unit, targetPos, strParam, path)
    --- Telegraph
    if (not Wargroove.isLocalPlayer(unit.playerId)) and Wargroove.canCurrentlySeeTile(targetPos) then
        Wargroove.spawnMapAnimation(targetPos, 0, "ui/grid/selection_cursor", "target", "over_units", {x = -4, y = -4})
        Wargroove.waitTime(0.5)
    end
 	local flanked = Wargroove.getUnitAt(targetPos)
    Wargroove.startCombat(unit, flanked, path)
	StealthManager.setLastKnownLocation(flanked.id, unit.pos)
	StealthManager.makeAlerted(flanked)
	StealthManager.spreadInfo(flanked)
end


function dump(o,level)
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

function Attack:canExecuteWithTarget(unit, endPos, targetPos, strParam)
    if not Wargroove.canPlayerSeeTile(unit.playerId, targetPos) then
        return false
    end

    local weapons = unit.unitClass.weapons
    if #weapons == 1 and weapons[1].horizontalAndVerticalOnly then
        local moved = endPos.x ~= unit.startPos.x or endPos.y ~= unit.startPos.y
        local xDiff = math.abs(endPos.x - targetPos.x)
        local yDiff = math.abs(endPos.y - targetPos.y)
        local maxDiff = weapons[1].horizontalAndVerticalExtraWidth
        if (xDiff > maxDiff and yDiff > maxDiff) then
            return false
        end
    end

    local targetTerrain = Wargroove.getTerrainNameAt(targetPos)
    if #weapons == 1 and #(weapons[1].terrainExclusion) > 0 then
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

    if targetUnit.canBeAttacked ~= nil and not targetUnit.canBeAttacked then
      return false
    end

	if Ragnarok.cantAttackBuildings(unit.playerId) and targetUnit.unitClass.isStructure then
		return false
	end
	if Ragnarok.hasCrown(unit) then return false end
	local fakePath = {unit.pos, endPos}
    local results = Combat:solveCombat(unit.id, targetUnit.id, fakePath, "simulationOptimistic")
	local relativeValue = (targetUnit.unitClass.cost*(targetUnit.health-results.defenderHealth))/(unit.unitClass.cost*(unit.health-results.attackerHealth))
	if relativeValue < 1 and Ragnarok.cantAttackBuildings(unit.playerId) then
		return false
	end
	local result, _ = Stats.getTerrainCost("bridge", unit.unitClassId)
	local isGroundUnit = result<100
	if not (isGroundUnit and targetUnit.unitClass.isStructure) then
		if (Stats.meleeUnits[unit.unitClassId] ~= nil) and (not Wargroove.canStandAt(unit.unitClassId, targetPos)) then
			return false
		end
	end

    return Combat:getBaseDamage(unit, targetUnit, endPos) > 0
end


return Attack
