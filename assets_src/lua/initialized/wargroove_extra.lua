local OldWargroove = require "wargroove/wargroove"
local UnitPostCombat = require "wargroove/unit_post_combat"
local Stats = require "util/stats"
local Combat = require "wargroove/combat"

local WargrooveExtra = {}
local Original = {}
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
function WargrooveExtra.init()
	print("wargroove_extra.lua loaded")
	Original.getMapTriggers = OldWargroove.getMapTriggers
	OldWargroove.getMapTriggers = WargrooveExtra.getMapTriggers
	
	Original.applyBuffs = OldWargroove.applyBuffs
	OldWargroove.applyBuffs = WargrooveExtra.applyBuffs

	OldWargroove.highAlertBuff = WargrooveExtra.highAlertBuff
	

	OldWargroove.removeUnitState = WargrooveExtra.removeUnitState
	OldWargroove.unitHasState = WargrooveExtra.unitHasState

	Original.isValidPushPullTarget = OldWargroove.isValidPushPullTarget
	OldWargroove.isValidPushPullTarget = WargrooveExtra.isValidPushPullTarget

	OldWargroove.isPushPullBreakPosition = WargrooveExtra.isPushPullBreakPosition

	Original.canStandAt = OldWargroove.canStandAt
	OldWargroove.canStandAt = WargrooveExtra.canStandAt

	Original.pickupItem = OldWargroove.pickupItem
	OldWargroove.pickupItem = WargrooveExtra.pickupItem

	Original.equipItem = OldWargroove.equipItem
	OldWargroove.equipItem = WargrooveExtra.equipItem

	Original.unequipItem = OldWargroove.unequipItem
	OldWargroove.unequipItem = WargrooveExtra.unequipItem

	OldWargroove.isPlayersCurrentTurn = WargrooveExtra.isPlayersCurrentTurn

	Original.setAIRestriction = OldWargroove.setAIRestriction
	OldWargroove.setAIRestriction = WargrooveExtra.setAIRestriction
	
	OldWargroove.doPostCombat = WargrooveExtra.doPostCombat

	Original.startCombat = OldWargroove.startCombat
	OldWargroove.startCombat = WargrooveExtra.startCombat

	Original.startCapture = OldWargroove.startCapture
	OldWargroove.startCapture = WargrooveExtra.startCapture
end

local hiddenTriggersStart = {}
local hiddenTriggersEnd = {}

local highAlertAnimation = "ui/icons/high_alert"
local highAlertEntity = {}
--[[function WargrooveExtra:doPostCombat(unitId, isAttacker, healthAfterCombat)
    local unit = self.getUnitById(unitId)
    if unit == nil then
        return
    end

    local postCombat = UnitPostCombat:getPostCombat(unit.unitClassId)
    if (postCombat ~= nil) then
        postCombat(self, unit, isAttacker, healthAfterCombat)
    end
	local postCombatGeneric = UnitPostCombat:getPostCombatGeneric()
	for i,method in pairs(postCombatGeneric) do
		method(self, unit, isAttacker)
	end
end]]

function WargrooveExtra:doPostCombat(unitId, isAttacker, healthAfterCombat)
    local unit = self.getUnitById(unitId)
    if unit == nil then
        return
    end

    local postCombat = UnitPostCombat:getPostCombat(unit.unitClassId)
    if (postCombat ~= nil) then
        postCombat(self, unit, isAttacker, healthAfterCombat)
    end
	local postCombatGeneric = UnitPostCombat:getPostCombatGeneric()
	for i,method in pairs(postCombatGeneric) do
		method(self, unit, isAttacker, healthAfterCombat)
	end

end

function WargrooveExtra.highAlertBuff(unit)

    if OldWargroove.isSimulating() then
        return
    end
	if (OldWargroove.getUnitState(unit, "high_alert") == nil) then
        OldWargroove.setUnitState(unit, "high_alert", "false")
        OldWargroove.updateUnit(unit)
    end
	local isHighAlert = OldWargroove.getUnitState(unit, "high_alert")
	if (isHighAlert ~= nil) and (isHighAlert ~= "false") then
		isHighAlert = true
	else
		isHighAlert = false
	end
	if (isHighAlert) then
		if not OldWargroove.hasUnitEffect(unit.id, highAlertAnimation) then
			highAlertEntity[unit.id] = OldWargroove.spawnUnitEffect(unit.id, highAlertAnimation, "idle", "spawn", true, false)
		end
	elseif OldWargroove.hasUnitEffect(unit.id, highAlertAnimation)  then
		if highAlertEntity[unit.id] ~= nil then
			OldWargroove.deleteUnitEffect(highAlertEntity[unit.id], "death")
		else
			OldWargroove.deleteUnitEffectByAnimation(unit.id, highAlertAnimation, "death")
		end
	end
end

local crownAnimation = "ui/icons/fx_crown"
function WargrooveExtra.crownBuff(unit)

    if OldWargroove.isSimulating() then
        return
    end
	local hasCrown = OldWargroove.getUnitState(unit, "crown") ~= nil
	if (hasCrown) then
		if not OldWargroove.hasUnitEffect(unit.id, crownAnimation) then
			local crownEffectEntityId = OldWargroove.spawnUnitEffect(unit.id, crownAnimation, "idle", nil, true, false)
			OldWargroove.setUnitState(unit, "crownEffectEntityId", crownEffectEntityId)
		end
	elseif OldWargroove.hasUnitEffect(unit.id, crownAnimation)  then
		local crownEffectEntityId = OldWargroove.getUnitState(unit, "crownEffectEntityId")
		if crownEffectEntityId~=nil then
			OldWargroove.deleteUnitEffect(crownEffectEntityId, "death")
		else
			OldWargroove.deleteUnitEffectByAnimation(unit.id, crownAnimation, "death")

		end
	end
end

function WargrooveExtra.applyBuffs()
	for i,id in pairs(OldWargroove.getAllUnitIds()) do
		local unit = OldWargroove.getUnitById(id)
		WargrooveExtra.highAlertBuff(unit)
		WargrooveExtra.crownBuff(unit)
	end
    Original.applyBuffs()
end

function WargrooveExtra.setAIRestriction(unitId, restriction, value)
    Original.setAIRestriction(unitId, restriction, value)
end


function WargrooveExtra.addHiddenTrigger(trigger, atEnd)
	if atEnd == true then
		table.insert(hiddenTriggersEnd, trigger) 
	else
		table.insert(hiddenTriggersStart, trigger) 
	end
end

function WargrooveExtra.getMapTriggers()

	local originalTriggers = Original.getMapTriggers()
	local combinedTriggers = {}
	for i,v in ipairs(hiddenTriggersStart) do
		table.insert(combinedTriggers, v) 
	end
	for i,v in ipairs(originalTriggers) do
		table.insert(combinedTriggers, v) 
	end
	for i,v in ipairs(hiddenTriggersEnd) do
		table.insert(combinedTriggers, v) 
	end
    return combinedTriggers
	
end

function WargrooveExtra.canStandAt(unitClass, pos)
	if OldWargroove.getMapItemIdAt(pos.x, pos.y)~=nil and OldWargroove.getMapItemIdAt(pos.x, pos.y)~=-1 then
		return false
	end
    return Original.canStandAt(unitClass, pos)
end
-- function WargrooveExtra.spawnUnit(playerId, pos, unitType, turnSpent, startAnimation, startingState, factionOverride)  
	-- local unitId = originalSpawnUnit(playerId, pos, unitType, turnSpent, startAnimation, startingState, factionOverride)  
	-- local unit = Wargroove.getUnitById(unitId)
	-- local visibleTiles = VisionTracker.calculateVisionOfUnit(unit)
	-- local team = Wargroove.getPlayerTeam(playerId)
	-- for i, pos in pairs(visibleTiles) do
		-- incrementNumberOfViewers(team,pos)
	-- end
    -- return unitId
-- end


-- function WargrooveExtra.updateUnit(unit)
	-- local oldUnit = getUnitById(unit.id)
	-- local visibleTiles = VisionTracker.calculateVisionOfUnit(oldUnit)
	-- local team = Wargroove.getPlayerTeam(oldUnit.playerId)
	-- for i, pos in pairs(visibleTiles) do
		-- decrementNumberOfViewers(team,pos)
	-- end
    -- api.updateUnit(unit)
	-- visibleTiles = VisionTracker.calculateVisionOfUnit(unit)
	-- team = Wargroove.getPlayerTeam(unit.playerId)
	-- for i, pos in pairs(visibleTiles) do
		-- incrementNumberOfViewers(team,pos)
	-- end
    -- Wargroove.clearUnitPositionCache()
-- end

function WargrooveExtra.removeUnitState(unit, key)
    for i, stateKey in pairs(unit.state) do
        if (stateKey.key == key) then
			table.remove(unit.state,i)
            return
        end
    end
end

function WargrooveExtra.unitHasState(unit, key, value)

    local state = OldWargroove.getUnitState(unit, key)
	if (state == nil) then
        return false
    end
	if value~=nil then
		return state==value
	end
	return state ~= "false"
end

function WargrooveExtra.waitTime(time)
	local currentTime = 0
    local timeStamp = currentTime+ time
    while currentTime < timeStamp do
		currentTime = currentTime +1.0/60.0
        coroutine.yield()
    end
end

function WargrooveExtra.isValidPushPullTarget(unit, pushCommanders)
    if unit.playerId<0 then
		return false
	end

    return Original.isValidPushPullTarget(unit,pushCommanders)
end

function WargrooveExtra.isPushPullBreakPosition(pos, unit)
    local terrainName = OldWargroove.getTerrainNameAt(pos)
    return Stats.willFallOnTerrain(terrainName, unit)
end

local function findCentreOfLocation(location)
    local centre = { x = 0, y = 0 }
    for i, pos in ipairs(location.positions) do
        centre.x = centre.x + pos.x
        centre.y = centre.y + pos.y
    end
    centre.x = centre.x / #(location.positions)
    centre.y = centre.y / #(location.positions)
    local bestSqrDist = 100^2
    local bestPos = { x = 0, y = 0 }
    for i, pos in ipairs(location.positions) do
        local sqrDist = (pos.x-centre.x)^2+(pos.y-centre.y)^2
        if sqrDist < bestSqrDist then
            bestPos.x = pos.x
            bestPos.y = pos.y
            bestSqrDist = sqrDist
        end
    end
    return bestPos
end

function WargrooveExtra.applyItemEffect(unit, itemType)
	if itemType == "crown" then
		if not OldWargroove.hasUnitEffect(unit.id, crownAnimation) then
			OldWargroove.spawnMapAnimation(unit.pos, 0, crownAnimation, "spawn", "over_units")
			OldWargroove.waitTime(0.5)
			OldWargroove.spawnUnitEffect(unit.id, unit.id, crownAnimation, "idle", "spawn", true, false)
			OldWargroove.updateUnit(unit)
		end
	end
end
function WargrooveExtra.removeItemEffect(unit, itemType)
	if itemType == "crown" then
		if OldWargroove.hasUnitEffect(unit.id, crownAnimation) then
			OldWargroove.deleteUnitEffectByAnimation(unit.id, crownAnimation)
		end
	end
end

function WargrooveExtra.pickupItem(unit, itemId)
	WargrooveExtra.applyItemEffect(unit, OldWargroove.getMapItemById(itemId).type)
	Original.pickupItem(unit, itemId)
end


function WargrooveExtra.equipItem(unit, itemId)
	WargrooveExtra.applyItemEffect(unit, itemId)
	Original.equipItem(unit, itemId)
end

function WargrooveExtra.unequipItem(unit)
	WargrooveExtra.removeItemEffect(unit, unit.itemId)
	Original.unequipItem(unit)
end

function WargrooveExtra.isPlayersCurrentTurn(player)
	return player == OldWargroove.getCurrentPlayerId()
end

local function deepcopy(orig)
    local orig_type = type(orig)
    local copy
    if orig_type == 'table' then
        copy = {}
        for orig_key, orig_value in next, orig, nil do
            copy[deepcopy(orig_key)] = deepcopy(orig_value)
        end
        setmetatable(copy, deepcopy(getmetatable(orig)))
    else -- number, string, boolean, etc
        copy = orig
    end
    return copy
end

function WargrooveExtra.startCombat(attacker, defender, path, combatType)
	
    Original.startCombat(attacker, defender, path, combatType)
	OldWargroove.lastAttacker = deepcopy(attacker)
	OldWargroove.lastDefender = deepcopy(defender)
	local result = Combat:solveCombat(attacker.id, defender.id, path, combatType)
	OldWargroove.lastAttacker.health = result.attackerHealth
	OldWargroove.lastDefender.health = result.defenderHealth
end


function WargrooveExtra.startCapture(attacker, defender, attackerPos)
    Original.startCapture(attacker, defender, attackerPos)
	OldWargroove.lastAttacker = deepcopy(attacker)
	OldWargroove.lastDefender = deepcopy(defender)
end


return WargrooveExtra
