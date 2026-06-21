local OldWargroove = require "wargroove/wargroove"
local UnitPostCombat = require "wargroove/unit_post_combat"
local Stats = require "util/stats"
local Combat = require "wargroove/combat"
local UnitBuffDeaths = require "initialized/unit_buff_deaths"
local VisionTrackerCache = require "util/vision_tracker_cache"

local WargrooveExtra = {}
local Original = {}
local occurences = {}
local damagedUnits = {}
local healedUnits = {}
function WargrooveExtra.init()
	print("wargroove_extra.lua loaded")
	Original.getMapTriggers = OldWargroove.getMapTriggers
	OldWargroove.getMapTriggers = WargrooveExtra.getMapTriggers
	
	Original.applyBuffs = OldWargroove.applyBuffs
	OldWargroove.applyBuffs = WargrooveExtra.applyBuffs

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

	OldWargroove.removeBuff = WargrooveExtra.removeBuff

	Original.setAIRestriction = OldWargroove.setAIRestriction
	OldWargroove.setAIRestriction = WargrooveExtra.setAIRestriction
	
	OldWargroove.doPostCombat = WargrooveExtra.doPostCombat

	Original.startCombat = OldWargroove.startCombat
	OldWargroove.startCombat = WargrooveExtra.startCombat

	Original.startCapture = OldWargroove.startCapture
	OldWargroove.startCapture = WargrooveExtra.startCapture

	Original.tableToString = OldWargroove.tableToString
	OldWargroove.tableToString = WargrooveExtra.tableToString
	
	OldWargroove.setTurnZero = WargrooveExtra.setTurnZero

	Original.setTurnInfo = OldWargroove.setTurnInfo
	OldWargroove.setTurnInfo = WargrooveExtra.setTurnInfo

	Original.highlightLocation = OldWargroove.highlightLocation
	OldWargroove.highlightLocation = WargrooveExtra.highlightLocation

	Original.setLocationProperties = OldWargroove.setLocationProperties
	OldWargroove.setLocationProperties = WargrooveExtra.setLocationProperties

	Original.revealFogOfWar = OldWargroove.revealFogOfWar
	OldWargroove.revealFogOfWar = WargrooveExtra.revealFogOfWar

	Original.setWeather = OldWargroove.setWeather
	OldWargroove.setWeather = WargrooveExtra.setWeather

	Original.setAIProfile = OldWargroove.setAIProfile
	OldWargroove.setAIProfile = WargrooveExtra.setAIProfile
	
	Original.setDaytime = OldWargroove.setDaytime
	OldWargroove.setDaytime = WargrooveExtra.setDaytime

	Original.setDaytime = OldWargroove.setDaytime
	OldWargroove.setDaytime = WargrooveExtra.setDaytime
	
	Original.setMapMusic = OldWargroove.setMapMusic
	OldWargroove.setMapMusic = WargrooveExtra.setMapMusic

	OldWargroove.fullClearCache = WargrooveExtra.fullClearCache
	OldWargroove.enableHireForPlayer = WargrooveExtra.enableHireForPlayer

	OldWargroove.canPlayerHire = WargrooveExtra.canPlayerHire
	OldWargroove.getDamagedUnits = WargrooveExtra.getDamagedUnits
	OldWargroove.getHealedUnits = WargrooveExtra.getHealedUnits
	
	Original.clearUnitPositionCache = OldWargroove.clearUnitPositionCache
	OldWargroove.clearUnitPositionCache = OldWargroove.clearUnitPositionCache
	
	
	Original.getUnitById = OldWargroove.getUnitById

	OldWargroove.getUnitById = WargrooveExtra.getUnitById

	OldWargroove.cleanUp = WargrooveExtra.cleanUp
	OldWargroove.didItOccur = WargrooveExtra.didItOccur
	OldWargroove.reportOccation = WargrooveExtra.reportOccation
	OldWargroove.registerDamagedUnit = WargrooveExtra.registerDamagedUnit
	OldWargroove.registerHealedUnit = WargrooveExtra.registerHealedUnit
end

function WargrooveExtra.clearUnitPositionCache()
	Original.clearUnitPositionCache()
	VisionTrackerCache.clearCalculateVisionOfUnitCache()
end

function WargrooveExtra.cleanUp()
	damagedUnits = {}
	healedUnits = {}
	occurences = {}
end

function WargrooveExtra.registerDamagedUnit(unitId,attackerId)
	damagedUnits[unitId] = attackerId
end
function WargrooveExtra.registerHealedUnit(unitId,healerId)
	healedUnits[unitId] = healerId
end

function WargrooveExtra.getDamagedUnits()
	return damagedUnits
end

function WargrooveExtra.getHealedUnits()
	return healedUnits
end
function WargrooveExtra.didItOccur(occation)
	return occurences[occation] ~= nil
end

function WargrooveExtra.reportOccation(occation)
	occurences[occation] = true
end

local hiddenTriggersStart = {}
local hiddenTriggersEnd = {}

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

local crownAnimation = "ui/icons/fx_crown"
function WargrooveExtra.crownBuff(unit)

    if OldWargroove.isSimulating() then
        return
    end
	local hasCrown = unit.itemId=="crown"
	if (hasCrown) then
		WargrooveExtra.applyItemEffect(unit, "crown")
	else
		WargrooveExtra.removeItemEffect(unit, "crown")
	end
end

function WargrooveExtra.applyBuffs()
	for i,id in pairs(OldWargroove.getAllUnitIds()) do
		local unit = OldWargroove.getUnitById(id)
		if unit~=nil then
			WargrooveExtra.crownBuff(unit)
		end
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
			print(dump(unit,0))
			local crownEffectEntityId = OldWargroove.spawnUnitEffect(unit.id, unit.id, crownAnimation, "idle", nil, true, false)
			OldWargroove.setUnitState(unit, "crownEffectEntityId", crownEffectEntityId)
		end
	end
end
function WargrooveExtra.removeItemEffect(unit, itemType)
	if itemType == "crown" then
		if OldWargroove.hasUnitEffect(unit.id, crownAnimation)  then
			local crownEffectEntityId = OldWargroove.getUnitState(unit, "crownEffectEntityId")
			if crownEffectEntityId~=nil then
				OldWargroove.deleteUnitEffect(crownEffectEntityId)
				WargrooveExtra.removeUnitState(unit, "crownEffectEntityId")
			else
				OldWargroove.deleteUnitEffectByAnimation(unit.id, crownAnimation)

			end
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
function WargrooveExtra.tableToString(o)
    return dump(o,0)
end

function WargrooveExtra.removeBuff(unit, playerId, buffSpawnId, buffId, buffDeathId)
	local buffUnits = OldWargroove.getUnitsAtLocation()
	local foundBuff = nil
	local lowestTurnCount = 100000 
	for i, buffUnit in ipairs(buffUnits) do
		if buffUnit.unitClassId == "buff" then
			local foundUnitId = OldWargroove.getUnitState(buffUnit,"unitId")
			if foundUnitId~=nil then
				foundUnitId = tonumber(foundUnitId)
			end
			local foundBuffSpawnId = OldWargroove.getUnitState(buffUnit,"buffSpawnId")
			local foundBuffId = OldWargroove.getUnitState(buffUnit,"buffId")
			local foundBuffDeathId = OldWargroove.getUnitState(buffUnit,"buffDeathId")
			local foundTurnCount = OldWargroove.getUnitState(buffUnit,"turnCount")
			if foundTurnCount~=nil then
				foundTurnCount = tonumber(foundTurnCount)
			end
			if foundUnitId == unit.id and foundBuffSpawnId == buffSpawnId and foundBuffId == buffId and foundBuffDeathId == buffDeathId and foundTurnCount<lowestTurnCount then
				foundBuff = buffUnit
				if foundTurnCount == nil then
					lowestTurnCount = 0
				else
					lowestTurnCount = foundTurnCount
				end
			end
		end
	end
	if foundBuff~=nil then
		foundBuff:setHealth(0, foundBuff.id, true)
		OldWargroove.updateUnit(foundBuff)
--        local buffDeaths = UnitBuffDeaths:getBuffDeaths()
--        local buffDeathId = OldWargroove.getUnitState(foundBuff, "buffDeathId")
--        local unitId = OldWargroove.getUnitState(foundBuff, "unitId")
--        local buffUnit = OldWargroove.getUnitById(tonumber(unitId))
--        if buffDeathId and buffDeathId ~= "" then
--            local buffDeath = buffDeaths[buffDeathId]
--            if buffDeath then
--                buffDeath(OldWargroove, buffUnit)
--                --coroutine.yield()
--            end
--        end
	end
end
local turnZero = 0
function WargrooveExtra.setTurnZero(turnNumber)
    turnZero = turnNumber
end

function WargrooveExtra.getTurnZero()
    return turnZero
end

function WargrooveExtra.setTurnInfo(turnNumber, currentPlayerId)
    Original.setTurnInfo(turnNumber + turnZero, currentPlayerId)
end

local locationObjects = {}

function WargrooveExtra.getStealthManagerObject(locationId)
	if locationObjects[locationId] == nil then
        for i,unit in ipairs(OldWargroove.getUnitsAtLocation(nil)) do
            if unit.unitClassId == "location_object" then
				local foundLocationId = OldWargroove.getUnitState(unit,"locationId")
				if foundLocationId~=nil and tonumber(foundLocationId) == locationId then
					locationObjects[locationId] = unit
					return locationObjects[locationId]
				end
            end
        end
        local id = OldWargroove.spawnUnit(-1, {x=-50,y=-50}, "location_object", false,nil,{{key = "locationId", value = tostring(locationId)}})
		OldWargroove.clearCaches()
        return OldWargroove.getUnitById(id)
    else
        return locationObjects[locationId]
    end
end

function WargrooveExtra.highlightLocation(locationId, highlightId, colour, hideOnSelection, hideOnAction, showOnUnitSelection, showOnEndPosSelection, showOnActionSelected)
    local locationObject = WargrooveExtra.getStealthManagerObject(locationId)
	local stateToSave = ""
	OldWargroove.setUnitState(locationObject,"highlightId",highlightId)
	OldWargroove.setUnitState(locationObject,"colour",colour)

	if hideOnSelection then
		stateToSave = "true"
	else
		stateToSave = "false"
	end
	OldWargroove.setUnitState(locationObject,"hideOnSelection",stateToSave)

	if hideOnAction then
		stateToSave = "true"
	else
		stateToSave = "false"
	end
	OldWargroove.setUnitState(locationObject,"hideOnAction",stateToSave)

	if showOnUnitSelection then
		stateToSave = "true"
	else
		stateToSave = "false"
	end
	OldWargroove.setUnitState(locationObject,"showOnUnitSelection",stateToSave)
	
	if showOnEndPosSelection then
		stateToSave = "true"
	else
		stateToSave = "false"
	end
	OldWargroove.setUnitState(locationObject,"showOnEndPosSelection",stateToSave)
	
	if showOnActionSelected then
		stateToSave = "true"
	else
		stateToSave = "false"
	end
	OldWargroove.setUnitState(locationObject,"showOnActionSelected",stateToSave)
	OldWargroove.updateUnit(locationObject)
	Original.highlightLocation(locationId, highlightId, colour, hideOnSelection, hideOnAction, showOnUnitSelection, showOnEndPosSelection, showOnActionSelected)
end

function WargrooveExtra.setLocationProperties(locationId, isAIObstacle, isObstacle, isInteractable)
	local locationObject = WargrooveExtra.getStealthManagerObject(locationId)
	local stateToSave = ""	
	if isAIObstacle then
		stateToSave = "true"
	else
		stateToSave = "false"
	end
	OldWargroove.setUnitState(locationObject,"isAIObstacle",stateToSave)
	
	if isObstacle then
		stateToSave = "true"
	else
		stateToSave = "false"
	end
	OldWargroove.setUnitState(locationObject,"isObstacle",stateToSave)
	
	if isInteractable then
		stateToSave = "true"
	else
		stateToSave = "false"
	end
	OldWargroove.setUnitState(locationObject,"isInteractable",stateToSave)
	OldWargroove.updateUnit(locationObject)
    Original.setLocationProperties(locationId, isAIObstacle, isObstacle, isInteractable)
end

function WargrooveExtra.setWeather(weather, daysAhead)
	local globalObject = WargrooveExtra.getGlobalObject()
	OldWargroove.setUnitState(globalObject,"weather",weather)
	OldWargroove.updateUnit(globalObject)
    Original.setWeather(weather, daysAhead)
end

function WargrooveExtra.setAIProfile(player, profile)
	local globalObject = WargrooveExtra.getGlobalObject()
	OldWargroove.setUnitState(globalObject,"player"..player.."AIProfile",profile)
	OldWargroove.updateUnit(globalObject)
    Original.setAIProfile(player, profile)
end

function WargrooveExtra.setDaytime(daytime)
	local globalObject = WargrooveExtra.getGlobalObject()
	OldWargroove.setUnitState(globalObject,"dayTime",daytime)
	OldWargroove.updateUnit(globalObject)
    Original.setDaytime(daytime)
end

function WargrooveExtra.setMapMusic(music, intensity)
	local globalObject = WargrooveExtra.getGlobalObject()
	OldWargroove.setUnitState(globalObject,"music",music)
	OldWargroove.setUnitState(globalObject,"musicIntensity",intensity)
	OldWargroove.updateUnit(globalObject)
    Original.setMapMusic(music, intensity)
end

function WargrooveExtra.enableHireForPlayer(playerId)
	local globalObject = WargrooveExtra.getGlobalObject()
	OldWargroove.setUnitState(globalObject,"enableHire"..playerId,"true")
	OldWargroove.updateUnit(globalObject)
end

function WargrooveExtra.canPlayerHire(playerId)
	local globalObject = WargrooveExtra.getGlobalObject()
	local state = OldWargroove.getUnitState(globalObject,"enableHire"..playerId)
	if state == nil then return false end
	return state == "true"
end

function WargrooveExtra.revealFogOfWar(playerId, locationId, visible)
	local locationObject = WargrooveExtra.getStealthManagerObject(locationId)
	local stateToSave = ""	
	if visible then
		stateToSave = "true"
	else
		stateToSave = "false"
	end
	if playerId~=nil then
		OldWargroove.setUnitState(locationObject,"player"..playerId.."visible",stateToSave)
	else
		OldWargroove.setUnitState(locationObject,"playerAnyVisible",stateToSave)
	end
	OldWargroove.updateUnit(locationObject)
    Original.revealFogOfWar(playerId, locationId, visible)
end

local globalObject = nil

function WargrooveExtra.getGlobalObject()
	if globalObject == nil then
        for i,unit in ipairs(OldWargroove.getUnitsAtLocation(nil)) do
            if unit.unitClassId == "global_object" then
                globalObject = unit
                return globalObject
            end
        end
        local id = OldWargroove.spawnUnit(-1, {x=-50,y=-50}, "global_object", false)
        OldWargroove.clearCaches()
        return OldWargroove.getUnitById(id)
    else
        return globalObject
    end
end


function WargrooveExtra.clearLocationObjectsCache()
	locationObjects = {}
end

function WargrooveExtra.clearGlobalObjectCache()
	globalObject = nil
end

function WargrooveExtra.clearCheckpointObjectCache()
	checkpointObject = nil
end

function WargrooveExtra.fullClearCache()
	OldWargroove.clearCaches()
	OldWargroove.clearDisplayTargets()
	WargrooveExtra.clearLocationObjectsCache()
	WargrooveExtra.clearGlobalObjectCache()
	WargrooveExtra.clearCheckpointObjectCache()
end

function WargrooveExtra.isSkippingIntroOveride()
	return WargrooveExtra.skippingIntroOveride
end

WargrooveExtra.skippingIntroOveride = false

function WargrooveExtra.skipIntroOveride(skip)
	WargrooveExtra.skippingIntroOveride = skip
end
function WargrooveExtra.getUnitById(unitId)
	local unit = Original.getUnitById(unitId)

	local function unitSetHealth(self, health, attackerId, ignoreParenting)
		print("unit health was set.")
        if ignoreParenting == nil then
            ignoreParenting = false
        end
		local originalHealth = self.health+0
        if self.unitClass.isDamagingParentUnit and not ignoreParenting then
            local parentId = OldWargroove.getUnitState(self, "parentId")
            local parent = WargrooveExtra.getUnitById(tonumber(parentId))

            if parent then
                parent:setHealth(health, attackerId)
                OldWargroove.updateUnit(parent)
            else
                print("Child that is supposed to have a parent didn't. Something went terribly wrong.")
            end
        end

        self.health = math.floor(math.max(0, math.min(health, 100)) * 0.01 * self.unitClass.maxHealth + 0.5)
        self.attackerId = attackerId
        if attackerId >= 0 then
            local attacker = WargrooveExtra.getUnitById(attackerId)
            self.attackerUnitClass = attacker.unitClass.id
            self.attackerPlayerId = attacker.playerId
        end
		if health>originalHealth then
			WargrooveExtra.registerHealedUnit(self.id,attackerId)
			WargrooveExtra.reportOccation("unit_was_healed")
		elseif health<originalHealth then
			WargrooveExtra.registerDamagedUnit(self.id,attackerId)
			WargrooveExtra.reportOccation("unit_was_damaged")
		end
    end

	if unit~=nil then unit.setHealth = unitSetHealth end
    return unit
end

return WargrooveExtra
