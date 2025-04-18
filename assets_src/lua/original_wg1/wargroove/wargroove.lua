local Wargroove = {}
local Functional = require "halley/functional"
local UnitBuffs = require "wargroove/unit_buffs"
local UnitBuffSpawns = require "wargroove/unit_buff_spawns"
local UnitPostCombat = require "wargroove/unit_post_combat"

-- Capture wargrooveAPI
local api = wargrooveAPI
wargrooveAPI = nil


-- Caches
local caches = {
    getUnitClass = {},
    getWeapon = {},
    getTerrainDefenceAt = {},
    getTerrainMovementCostAt = {},
    getBaseTerrainDefenceAt = {},
    getTerrainNameAt = {},
    getGizmoAt = {},

    getTerrainByName = {},
    getGroove = {},
    getPlayerTeam = {},
    getPlayerChildOf = {},
    getAllUnitIds = {}
}

local activeBuffs = {}

local difficulty = {
    damageMultiplier = 1.0
}

function Wargroove.clearUnitPositionCache()
    caches.getUnitIdAt = {}
end

function Wargroove.clearPlayerCache()
    caches.getPlayerTeam = {}
    caches.getPlayerChildOf = {}
end    

local simulating = false

function Wargroove.setSimulating(newValue)
    simulating = newValue
end

function Wargroove.isSimulating()
    return simulating
end

local buffsToClear = nil
local buffsToApply = nil

function Wargroove.prepareBuffs()
    buffsToClear = {}
    buffsToApply = {}

    for id, pos in pairs(activeBuffs) do
        if Wargroove.getUnitById(id) == nil then
            Wargroove.clearBuffVisualEffect(id)
        end
    end

    local buffs = UnitBuffs:getBuffs()
    local clearBuffs = UnitBuffs:getClearBuffs()
    local allUnits = Wargroove.getAllUnitIds()
    for i, id in ipairs(allUnits) do
        local unit = Wargroove.getUnitById(id)

        local buff = buffs[unit.unitClassId]
        if buff ~= nil and buff ~= "" then
            buffsToApply[id] = unit
        end
    end

    for id, unit in pairs(buffsToApply) do
        local clearBuff = clearBuffs[unit.unitClassId]
        if clearBuff ~= nil and clearBuff ~= "" then
            buffsToClear[id] = unit
        end
    end
end

function Wargroove.applyBuffs()
    if buffsToApply == nil then
        Wargroove.prepareBuffs()
    end

    local buffs = UnitBuffs:getBuffs()
    local clearBuffs = UnitBuffs:getClearBuffs()

    for id, unit in pairs(buffsToClear) do
        local clearBuff = clearBuffs[unit.unitClassId]
        clearBuff(Wargroove, unit)
    end

    activeBuffs = {}

    for id, unit in pairs(buffsToApply) do
        local buff = buffs[unit.unitClassId]
        buff(Wargroove, unit)
        activeBuffs[id] = unit.pos
    end
end

function Wargroove:doPostCombat(unitId, isAttacker)
    local unit = Wargroove.getUnitById(unitId)
    if unit == nil then
        return
    end

    local postCombat = UnitPostCombat:getPostCombat(unit.unitClassId)
    if (postCombat ~= nil) then
        postCombat(Wargroove, unit, isAttacker)
    end
end

function Wargroove.clearCaches()
    Wargroove.clearUnitPositionCache()
    Wargroove.clearPlayerCache()
    caches.getUnitById = {}
    caches.getTerrainDefenceAt = {}
    caches.getSkyDefenceAt = {}
    caches.getTerrainMovementCostAt = {}
    caches.getBaseTerrainDefenceAt = {}
    caches.getTerrainNameAt = {}
    caches.getTerrainByName = {}
    caches.getGroove = {}
    caches.getWeapon = {}
    caches.getUnitClass = {}
    caches.getGizmoAt = {}
    caches.getAllUnitIds = {}

    buffsToClear = nil
    buffsToApply = nil

    if (api.isApiReady()) then
        Wargroove.applyBuffs()
    end
end

Wargroove.clearCaches()

function cachedCall(cache, cacheKey, f, ...)
    local cachedResult = cache[cacheKey]
    if cachedResult ~= nil then
        return cachedResult[1]
    else
        local result = f(...)
        cache[cacheKey] = {result}
        return result
    end
end

local function xyToCacheKey(x, y)
    return x * 65536 + y
end


-- Internal storage
local wargrooveState = {
    turnNumber = 0,
    currentPlayerId = 0
}


-- User-facing functions
function Wargroove.getWeapon(weaponId, unitClassId)
    return cachedCall(caches.getWeapon, (weaponId .. unitClassId), api.getWeapon, weaponId, unitClassId)
end

function Wargroove.getAllUnitIds()
    return cachedCall(caches.getAllUnitIds, "all", api.getAllUnits)
end

function Wargroove.getUnitClass(unitClassId)
    assert(unitClassId ~= nil)
    assert(unitClassId ~= "")

    local function getClass(id)
        local uc = api.getUnitClass(id)
        if uc ~= nil then
            uc.weapons = {}
            for i, k in ipairs(uc.weaponIds) do
                uc.weapons[i] = Wargroove.getWeapon(k, id)
            end
        end
        return uc
    end
    
    return cachedCall(caches.getUnitClass, unitClassId, getClass, unitClassId)
end


function Wargroove.getUnitById(unitId)
    assert(unitId ~= nil)

    local function unitSetHealth(self, health, attackerId)
        self.health = math.floor(math.max(0, math.min(health, 100)) * 0.01 * self.unitClass.maxHealth + 0.5)
        self.attackerId = attackerId
        if attackerId >= 0 then
            attacker = Wargroove.getUnitById(attackerId)
            self.attackerUnitClass = attacker.unitClass.id
            self.attackerPlayerId = attacker.playerId
        end
    end

    local function unitSetGroove(self, groove)
        self.grooveCharge = math.floor(math.max(0, math.min(groove, 100)) * 0.01 * self.unitClass.maxGroove + 0.5)
    end

    if unitId == -1 then
        return nil
    end

    local function getUnit(id)
        local unit = api.getUnitById(id)
        if unit ~= nil then
            unit.unitClass = Wargroove.getUnitClass(unit.unitClassId)
            unit.setHealth = unitSetHealth
            unit.setGroove = unitSetGroove
            unit.canBeAttacked = true
        end
        return unit
    end

    return cachedCall(caches.getUnitById, unitId, getUnit, unitId)
end


function Wargroove.getUnitIdAtXY(x, y)
    return cachedCall(caches.getUnitIdAt, xyToCacheKey(x, y), api.getUnitIdAt, x, y)
end


function Wargroove.setUnitIdAtXY(x, y, unitId)
    local key = xyToCacheKey(x, y)
    caches.getUnitIdAt[key] = {unitId}
end


function Wargroove.getUnitIdAt(pos)
    return Wargroove.getUnitIdAtXY(pos.x, pos.y)
end


function Wargroove.getUnitAtXY(x, y)
    return Wargroove.getUnitById(Wargroove.getUnitIdAtXY(x, y))
end


function Wargroove.getUnitAt(pos)
    return Wargroove.getUnitById(Wargroove.getUnitIdAt(pos))
end


function Wargroove.getGizmoAt(pos)
    assert(pos ~= nil)

    local function gizmoSetState(self, state)
        api.setGizmoState(self.pos, state)
    end

    local function gizmoGetState(self)
        return api.getGizmoState(self.pos)
    end

    local function getGizmo(pos)
        local gizmo = api.getGizmoAt(pos)
        if gizmo ~= nil then
            gizmo.setState = gizmoSetState
            gizmo.getState = gizmoGetState
        end
        return gizmo
    end

    return cachedCall(caches.getGizmoAt, xyToCacheKey(pos.x, pos.y), getGizmo, pos)
end


function Wargroove.getPlayerTeam(playerId)
    return cachedCall(caches.getPlayerTeam, playerId, api.getPlayerTeam, playerId)
end

function Wargroove.getPlayerChildOf(playerId)
    return cachedCall(caches.getPlayerChildOf, playerId, api.getPlayerChildOf, playerId)
end


function Wargroove.setPlayerTeam(playerId, teamId)
    api.setPlayerTeam(playerId, teamId)
    Wargroove.clearPlayerCache()
end


function Wargroove.areAllies(playerId1, playerId2)
    return Wargroove.getPlayerTeam(playerId1) == Wargroove.getPlayerTeam(playerId2)
end


function Wargroove.areEnemies(playerId1, playerId2)
    -- Neutral player is not anyone's enemy
    if playerId1 == -1 or playerId2 == -1 then
        return false
    end

    return Wargroove.getPlayerTeam(playerId1) ~= Wargroove.getPlayerTeam(playerId2)
end


function Wargroove.isNeutral(playerId)
    return playerId == -1
end


function Wargroove.startCombat(attacker, defender, path)
    Wargroove.setMetaLocation("last_attacker", attacker.pos)
    Wargroove.setMetaLocation("last_defender", defender.pos)
    api.startCombat(attacker.id, defender.id, path)
    Wargroove.clearUnitPositionCache()
end


function Wargroove.startCapture(attacker, defender, attackerPos)
    Wargroove.setMetaLocation("last_attacker", attacker.pos)
    Wargroove.setMetaLocation("last_defender", defender.pos)
    api.startCapture(attacker.id, defender.id, attackerPos)
end


function Wargroove.spawnUnit(playerId, pos, unitType, turnSpent, startAnimation, startingState, factionOverride)  
    local id = api.spawnUnit(playerId, pos, unitType, turnSpent, startAnimation or "", startingState or {}, factionOverride or "")   
    Wargroove.clearUnitPositionCache()

    local buffSpawns = UnitBuffSpawns:getBuffSpawns()
    local buffSpawn = buffSpawns[unitType]
    if buffSpawn ~= nil and buffSpawn ~= "" then
        local unit = Wargroove.getUnitById(id)        
        buffSpawn(Wargroove, unit)
        coroutine.yield()
    end

    return id
end


function Wargroove.updateUnit(unit)
    api.updateUnit(unit)
    Wargroove.clearUnitPositionCache()
end


function Wargroove.updateUnits(units)
    for i, unit in ipairs(units) do
        api.updateUnit(unit)
    end
    Wargroove.clearUnitPositionCache()
end


function Wargroove.removeUnit(unitId)
    api.removeUnit(unitId)
    Wargroove.clearUnitPositionCache()
end

function Wargroove.doLuaDeathCheck(unitId)
    api.doLuaDeathCheck(unitId)
end

function Wargroove.changeMoney(playerId, delta)
    api.setMoney(playerId, delta + api.getMoney(playerId))
end


function Wargroove.setMoney(playerId, value)
    api.setMoney(playerId, math.floor(value))
end


function Wargroove.getMoney(playerId)
    return api.getMoney(playerId)
end


function Wargroove.canStandAt(unitClass, pos)
    return api.canStandAt(unitClass, pos)
end


function Wargroove.hasCompatibleMovementType(unitClass, pos)
    return api.hasCompatibleMovementType(unitClass, pos)
end


function Wargroove.isWater(pos)
    return api.isWater(pos)
end


local unitPosStack = {}

function Wargroove.pushUnitPos(unit, pos)
    if unit.pos.x ~= pos.x or unit.pos.y ~= pos.y then
        local oldPos = unit.pos

        unit.pos = pos
        local prevHere = Wargroove.getUnitIdAtXY(pos.x, pos.y)
        Wargroove.setUnitIdAtXY(oldPos.x, oldPos.y, -1)
        Wargroove.setUnitIdAtXY(pos.x, pos.y, unit.id)

        table.insert(unitPosStack, function ()
            unit.pos = oldPos
            Wargroove.setUnitIdAtXY(oldPos.x, oldPos.y, unit.id)
            Wargroove.setUnitIdAtXY(pos.x, pos.y, prevHere)
        end)
    else
        table.insert(unitPosStack, function() end)
    end
end


function Wargroove.popUnitPos()
    if #unitPosStack > 0 then
        unitPosStack[#unitPosStack]()
        table.remove(unitPosStack, #unitPosStack)
    end
end


function Wargroove.getTargetsInRangeAfterMove(unit, endPos, pos, range, targetType)
    Wargroove.pushUnitPos(unit, endPos)
    local result = Wargroove.getTargetsInRange(pos, range, targetType)
    Wargroove.popUnitPos()
    return result
end


function Wargroove.getTargetsInRange(pos, range, targetType)
    local mapSize = Wargroove.getMapSize()

    local result = {}
    local x0 = pos.x
    local y0 = pos.y
    for yo = -range, range do
        for xo = -range, range do
            local distance = math.abs(xo) + math.abs(yo)
            if distance <= range then
                local x = x0 + xo
                local y = y0 + yo
                if (x >= 0) and (y >= 0) and (x < mapSize.x) and (y < mapSize.y) then
                    if (targetType == "all") then
                        table.insert(result, { x = x, y = y})
                    else
                        local unitId = Wargroove.getUnitIdAtXY(x, y)
                        if (targetType == "unit" and unitId ~= -1) or (targetType == "empty" and unitId == -1) then
                            table.insert(result, { x = x, y = y})
                        end
                    end
                end
            end
        end
    end

    return result
end


function Wargroove.getWeaponDamage(weapon, target)
    return api.getWeaponDamage(weapon.id, target.unitClassId, target.pos.x, target.pos.y)
end

function Wargroove.getWeaponDamageForceGround(weaponId, target)
    return api.getWeaponDamageForceGround(weaponId, target.unitClassId, target.pos.x, target.pos.y)
end

function Wargroove.isAnybodyElseAt(unit, pos)
    local u = Wargroove.getUnitAt(pos)
    if u == nil then
        return false
    else
        return u ~= unit
    end
end


function Wargroove.loadInTransport(transport, unit)
    api.loadInTransport(transport.id, unit.id)
end


function Wargroove.unloadFromTransport(transport, unit, position)
    api.unloadFromTransport(transport.id, unit.id, position)
end

function Wargroove.getTerrainByName(name)
    return cachedCall(caches.getTerrainByName, name, api.getTerrainByName, name)
end

function Wargroove.getTerrainNameAt(pos)
    return cachedCall(caches.getTerrainNameAt, xyToCacheKey(pos.x, pos.y), api.getTerrainNameAt, pos)
end

function Wargroove.getTerrainDefenceAt(pos)
    return cachedCall(caches.getTerrainDefenceAt, xyToCacheKey(pos.x, pos.y), api.getTerrainDefenceAt, pos)
end

function Wargroove.isTerrainImpassableAt(pos)
    return api.isTerrainImpassableAt(pos)
end

function Wargroove.getBaseSkyDefence()
    local terrain = Wargroove.getTerrainByName("sky")
    return terrain.defence
end

function Wargroove.getSkyDefenceAt(pos)
    return cachedCall(caches.getSkyDefenceAt, xyToCacheKey(pos.x, pos.y), Wargroove.getBaseSkyDefence)
end

function Wargroove.getTerrainMovementCostAt(pos)
    return cachedCall(caches.getTerrainMovementCostAt, xyToCacheKey(pos.x, pos.y), api.getTerrainMovementCostAt, pos)
end

function Wargroove.getBaseTerrainDefenceAt(pos)
    return cachedCall(caches.getBaseTerrainDefenceAt, xyToCacheKey(pos.x, pos.y), api.getTerrainDefenceAt, pos)
end

function Wargroove.getValueFromCache(cache, cacheKey)
    local cachedResult = cache[cacheKey]
    return cachedResult[1]
end

function Wargroove.putValueIntoCache(cache, cacheKey, result)
    cache[cacheKey] = {result}
    return result
end

function Wargroove.setTerrainDefenceAt(pos, newDefence)
    Wargroove.putValueIntoCache(caches.getTerrainDefenceAt, xyToCacheKey(pos.x, pos.y), newDefence)
end

function Wargroove.setSkyDefenceAt(pos, newDefence)
    Wargroove.putValueIntoCache(caches.getSkyDefenceAt, xyToCacheKey(pos.x, pos.y), newDefence)
end

function Wargroove.getAllUnitIdsForPlayer(playerId, includeChildren)
    return api.getAllUnitsForPlayer(playerId, includeChildren)
end


function Wargroove.getAllUnitsForPlayer(playerId, includeChildren)
    return Functional.map(Wargroove.getUnitById, Wargroove.getAllUnitIdsForPlayer(playerId, includeChildren))
end


function Wargroove.getCurrentWeather()
    return api.getCurrentWeather()
end


function Wargroove.getGroove(grooveId)
    return cachedCall(caches.getGroove, grooveId, api.getGroove, grooveId)
end


function Wargroove.getMapTriggers()
    return api.getMapTriggers()
end


function Wargroove.getLocationById(locationId)
    if locationId == -1 then
        return nil
    end

    local loc = api.getLocationById(locationId)
    loc.setArea = function(self, area)
        Wargroove.setLocationArea(self.id, area)
    end
    loc.getArea = function(self)
        return self.positions
    end
    return loc
end


function Wargroove.setMetaLocation(name, pos)
    local area = {}
    table.insert(area, pos)
    Wargroove.setMetaLocationArea(name, area)
end


function Wargroove.setMetaLocationArea(name, area)
    return api.setMetaLocation(name, area)
end


function Wargroove.setLocationArea(id, area)
    return api.setLocation(id, area)
end


function Wargroove.getUnitsAtLocation(location)
    local result = {}

    if location == nil then
        -- Anywhere
        for i, id in ipairs(api.getAllUnits()) do
            local unit = Wargroove.getUnitById(id)
            if unit ~= nil then
                table.insert(result, unit)
            end
        end
    else
        -- Specific location
        for i, pos in ipairs(location.positions) do
            local unit = Wargroove.getUnitAt(pos)
            if unit ~= nil then
                table.insert(result, unit)
            end
        end
    end

    return result
end


function Wargroove.getGizmosAtLocation(location)
    local result = {}

    if location == nil then
        -- Anywhere
        for i, pos in ipairs(api.getAllGizmos()) do
            local gizmo = Wargroove.getGizmoAt(pos)
            if gizmo ~= nil then
                table.insert(result, gizmo)
            end
        end
    else
        -- Specific location
        for i, pos in ipairs(location.positions) do
            local gizmo = Wargroove.getGizmoAt(pos)
            if gizmo ~= nil then
                table.insert(result, gizmo)
            end
        end
    end

    return result
end


function Wargroove.getTurnNumber()
    return wargrooveState.turnNumber
end


function Wargroove.getCurrentPlayerId()
    return wargrooveState.currentPlayerId
end


function Wargroove.startCutscene(id)
    api.startCutscene(id)
end


function Wargroove.giveVictory(playerId)
    api.giveVictory(playerId)
end


function Wargroove.eliminate(playerId)
    api.eliminate(playerId)
end


function Wargroove.waitFrame()
    coroutine.yield()
end


function Wargroove.waitTime(time)
    local timeLeft = time
    while timeLeft > 0 do
        timeLeft = timeLeft - coroutine.yield()
    end
end


function Wargroove.getNumberOfOpponents(playerId)
    return api.getNumberOfOpponents(playerId)
end


function Wargroove.showMessage(string)
    api.showMessage(string)
end


function Wargroove.showDialogueBox(expression, character, message, shout)
    api.showDialogueBox(expression, character, message, shout)
    coroutine.yield()
end


function Wargroove.getMapVariables(id)
    return api.getMapVariables(id)
end


function Wargroove.trackCameraTo(pos)
    api.trackCameraTo(pos)

    -- :(
    -- OK, so it needs two frames for the message to get to the camera system and initiate the tracking
    coroutine.yield()
    coroutine.yield()
    while api.isCameraTracking() do
        coroutine.yield()
    end
end

function Wargroove.lockTrackCamera(unitId)
    api.lockTrackCamera(unitId)
end

function Wargroove.unlockTrackCamera()
    api.unlockTrackCamera()
end

function Wargroove.spawnMapAnimation(pos, radius, name, sequence, layer, offset, facing)
    if Wargroove.canCurrentlySeeArea(pos, radius) then
        api.spawnMapAnimation(pos, name, sequence or "idle", layer or "units", offset or {x = 12, y = 16}, facing or "default")
    end
end

function Wargroove.spawnPaletteSwappedMapAnimation(pos, radius, name, playerId, sequence, layer, offset)
    if Wargroove.canCurrentlySeeArea(pos, radius) then
        api.spawnPaletteSwappedMapAnimation(pos, name, playerId, sequence or "idle", layer or "units", offset or {x = 12, y = 16})
    end
end

function Wargroove.playUnitAnimation(unitId, sequence)
    api.playUnitAnimation(unitId, sequence)
end

function Wargroove.playUnitAnimationOnce(unitId, sequence)
    api.playUnitAnimationOnce(unitId, sequence)
end

function Wargroove.playUnitDeathAnimation(unitId)
    api.playUnitDeathAnimation(unitId)
end

function Wargroove.pseudoRandomFromString(str)
    return api.pseudoRandomFromString(str)
end

function Wargroove.isRNGEnabled()
    return api.isRNGEnabled()
end


function Wargroove.canPlayerSeeTile(player, tile)
    return api.canPlayerSeeTile(player, tile)
end

function Wargroove.canCurrentlySeeTile(tile)
    return api.canCurrentlySeeTile(tile)
end

function Wargroove.canCurrentlySeeArea(centre, radius)
    local x0 = centre.x
    local y0 = centre.y
    for yo = -radius, radius do
        for xo = -radius, radius do
            local distance = math.abs(xo) + math.abs(yo)
            if distance <= radius then
                if Wargroove.canCurrentlySeeTile({x = x0 + xo, y = y0 + yo}) then
                    return true
                end
            end
        end
    end
    return false
end


function Wargroove.canPlayerRecruit(player, unitClassId)
    return api.canPlayerRecruit(player, unitClassId)
end


function Wargroove.setAIProfile(player, profile)
    api.setAIProfile(player, profile)
end

function Wargroove.setWeather(weatherFrequency, daysAhead)
    api.setWeather(weatherFrequency, daysAhead)
end


function Wargroove.setAIRestriction(unitId, restriction, value)
    api.setAIRestriction(unitId, restriction, value)
end

function Wargroove.hasAIRestriction(unitId, restriction)
    return api.hasAIRestriction(unitId, restriction)
end

function Wargroove.forceAction(selectableUnitIds, endPositions, targetPositions, action, autoEnd, expression, commander, dialogue)
    api.forceAction(selectableUnitIds, endPositions, targetPositions, action, autoEnd, expression, commander, dialogue)
end

function Wargroove.forceOpenTutorial(tutorialId, selectableTargets, expression, commander, dialogue, mapFlag, mapFlagValue)
    api.forceOpenTutorial(tutorialId, selectableTargets, expression, commander, dialogue, mapFlag, mapFlagValue)
end

function Wargroove.queueForceAction(selectableUnitIds, endPositions, targetPositions, action, autoEnd, expression, commander, dialogue)
    api.queueForceAction(selectableUnitIds, endPositions, targetPositions, action, autoEnd, expression, commander, dialogue)
end

function Wargroove.queueForceOpenTutorial(tutorialId, selectableTargets, expression, commander, dialogue, mapFlag, mapFlagValue)
    api.queueForceOpenTutorial(tutorialId, selectableTargets, expression, commander, dialogue, mapFlag, mapFlagValue)
end

function Wargroove.addTutorial(tutorialId, selectableTargets, mapFlag, mapFlagValue)
    api.addTutorial(tutorialId, selectableTargets, mapFlag, mapFlagValue)
end

function Wargroove.playMapSound(sound, pos)
    api.playMapSound(sound, pos)
end

function Wargroove.playPositionlessSound(sound)
    api.playPositionlessSound(sound)
end

function Wargroove.playCutsceneSFX(sound, pos)
    api.playCutsceneSFX(sound, pos)
end

function Wargroove.playPositionlessCutsceneSFX(sound)
    api.playPositionlessCutsceneSFX(sound)
end

function Wargroove.openRecruitMenu(player, recruitBaseId, recruitBasePos, unitClassId, units, costMultiplier, unbannableUnits, factionOverride)
    api.openRecruitMenu(player, recruitBaseId, recruitBasePos, unitClassId, units, costMultiplier, unbannableUnits, factionOverride)
end

function Wargroove.recruitMenuIsOpen()
    return api.recruitMenuIsOpen()
end

function Wargroove.popRecruitedUnitClass()
    return api.popRecruitedUnitClass()
end

function Wargroove.openUnloadMenu(usedUnits)
    api.openUnloadMenu(usedUnits)
end

function Wargroove.unloadMenuIsOpen()
    return api.unloadMenuIsOpen()
end

function Wargroove.getUnloadedUnitId()
    return api.getUnloadedUnitId()
end

function Wargroove.getUnloadVerb()
    return api.getUnloadVerb()
end

function Wargroove.finishVerbPreExecute(shouldExecute, strParam)
    return api.finishVerbPreExecute(shouldExecute, strParam)
end

function Wargroove.cancelVerbExecute()
    return api.cancelVerbExecute()
end

function Wargroove.selectTarget()
    api.selectTarget()
end

function Wargroove.waitingForSelectedTarget()
    return api.waitingForSelectedTarget()
end

function Wargroove.getSelectedTarget()
    return api.getSelectedTarget()
end

function Wargroove.setSelectedTarget(targetPos)
    return api.setSelectedTarget(targetPos)
end

function Wargroove.clearSelectedTarget()
    api.clearSelectedTarget()
end

function Wargroove.displayTarget(targetPos)
    api.displayTarget(targetPos)
end

function Wargroove.clearDisplayTargets()
    api.clearDisplayTargets()
end

function Wargroove.displayBuffVisualEffect(parentId, playerId, animation, startSequence, alpha, effectPositions, layer, offset, startSequenceIsLooping)
    api.displayBuffVisualEffect(parentId, playerId, animation, startSequence, alpha, effectPositions or {Wargroove.getUnitById(parentId).pos}, layer or "", offset or {}, startSequenceIsLooping or false)
end

function Wargroove.displayBuffVisualEffectAtPosition(parentId, position, playerId, animation, startSequence, alpha, effectPositions, layer, offset, startSequenceIsLooping)
  api.displayBuffVisualEffectAtPosition(parentId, position, playerId, animation, startSequence, alpha, effectPositions or {position}, layer or "", offset or {}, startSequenceIsLooping or false)
end

function Wargroove.clearBuffVisualEffect(parentId)
    api.clearBuffVisualEffect(parentId)
end

function Wargroove.setBuffVisualEffectsOwner(oldParentId, newParentId)
    api.setBuffVisualEffectsOwner(oldParentId, newParentId)
end

function Wargroove.playBuffVisualEffectSequence(unitId, position, animation, newSequence)
    api.playBuffVisualEffectSequence(unitId, position, animation, newSequence)
end

function Wargroove.playBuffVisualEffectSequenceOnce(unitId, position, animation, newSequence)
    api.playBuffVisualEffectSequenceOnce(unitId, position, animation, newSequence)
end

function Wargroove.getBestUnitToRecruit(fromUnits, unbannableUnits)
    return api.getBestUnitToRecruit(fromUnits, unbannableUnits)
end

function Wargroove.getAIUnitRecruitScore(unitClassId, position)
    return api.getAIUnitRecruitScore(unitClassId, position)
end

function Wargroove.getAILocationScore(unitClassId, position)
    return api.getAILocationScore(unitClassId, position)
end

function Wargroove.getAIUnitValue(unitId, position)
    return api.getAIUnitValue(unitId, position)
end

function Wargroove.getAICanLookAhead(unitId)
    return api.getAICanLookAhead(unitId)
end

function Wargroove.getAIUnitValueWithHealth(unitId, position, health)
    return api.getAIUnitValueWithHealth(unitId, position, health)
end

function Wargroove.getAIBraveryBonus() 
    return api.getAIBraveryBonus();
end

function Wargroove.getAIAttackBias()
    return api.getAIAttackBias();
end

function Wargroove.moveUnitToOverride(unitId, endPos, offsetX, offsetY, speed)
    api.moveUnitToOverride(unitId, endPos, offsetX, offsetY, speed)
end

function Wargroove.isLuaMoving(unitId)
    return api.isLuaMoving(unitId)
end

function Wargroove.spawnUnitEffect(parentUnitId, name, sequence, startAnimation, inFront, paletteSwap)
    if paletteSwap == nil then paletteSwap = true end
    return api.spawnUnitEffect(parentUnitId, name, sequence, startAnimation, inFront, paletteSwap)
end

function Wargroove.deleteUnitEffect(entityId, endAnimation)
    api.deleteUnitEffect(entityId, endAnimation)
end

function Wargroove.deleteUnitEffectByAnimation(parentUnitId, animation, endAnimation)
    api.deleteUnitEffectByAnimation(parentUnitId, animation, endAnimation)
end

function Wargroove.hasUnitEffect(parentUnitId, animation)
    return api.hasUnitEffect(parentUnitId, animation)
end

function Wargroove.setIsUsingGroove(unitId, isUsing)
    api.setIsUsingGroove(unitId, isUsing)
end

function Wargroove.playGrooveCutscene(unitId, verb, commanderOverride)
    api.playGrooveCutscene(unitId, verb or "", commanderOverride or "")
    coroutine.yield()
end

function Wargroove.playGrooveCutsceneForCharacter(character)
    Wargroove.playPositionlessSound("battleStart")
    api.playGrooveCutsceneForCharacter(character)
    coroutine.yield()
end

function Wargroove.playGrooveEffect()
    api.playGrooveEffect()
end

function Wargroove.setVisibleOverride(unitId, visible)
    api.setVisibleOverride(unitId, visible)
end

function Wargroove.unsetVisibleOverride(unitId)
    api.unsetVisibleOverride(unitId)
end

function Wargroove.setShadowVisible(unitId, visible)
    api.setShadowVisible(unitId, visible)
end

function Wargroove.unsetShadowVisible(unitId)
    api.unsetShadowVisible(unitId)
end

function Wargroove.playCutscene(cutsceneId)
    api.playCutscene(cutsceneId)
    coroutine.yield()

    while(Wargroove.isCutscenePlaying()) do
        coroutine.yield()
    end
end

function Wargroove.isCutscenePlaying()
    return api.isCutscenePlaying()
end

function Wargroove.setFacingOverride(unitId, newFacing)
    api.setFacingOverride(unitId, newFacing)
end

function Wargroove.unsetFacingOverride(unitId)
    api.setFacingOverride(unitId, "")
end

function Wargroove.highlightLocation(location, highlightId, colour, hideOnSelection, hideOnAction, showOnUnitSelection, showOnEndPosSelection, showOnActionSelected)
    api.highlightLocation(location, highlightId, colour, hideOnSelection, hideOnAction, showOnUnitSelection, showOnEndPosSelection, showOnActionSelected)
end

-- Invoked by native code

function Wargroove.setTurnInfo(turnNumber, currentPlayerId)
    wargrooveState.turnNumber = turnNumber
    wargrooveState.currentPlayerId = currentPlayerId
end

local Events = nil
local Resumable = nil

function Wargroove.checkTriggers(state)
    Wargroove.clearCaches()
    if Events == nil then
        Events = require "wargroove/events"
    end
    return Events.checkEvents(state)
end

function Wargroove.checkConditions(conditions)
    Wargroove.clearCaches()
    if Events == nil then
        Events = require "wargroove/events"
    end
    return Events.checkConditions(conditions.expressions)
end

function Wargroove.runActions(actions)
    Wargroove.clearCaches()
    if Events == nil then
        Events = require "wargroove/events"
    end
    Events.runActions(actions.expressions)
end 

function Wargroove.setMapFlag(flagId, value)
    if Events == nil then
        Events = require "wargroove/events"
    end
    Events.setMapFlag(flagId, value)
end

function Wargroove.reportUnitDeath(id, attackerId, attackerPlayerId, attackerUnitClass)
    if Events == nil then
        Events = require "wargroove/events"
    end
    Events.reportUnitDeath(id, attackerId, attackerPlayerId, attackerUnitClass)
end

function Wargroove.isPlayerVictorious(playerId)
    return api.isPlayerVictorious(playerId)
end

function Wargroove.getNumberOfStars()
    return api.getNumberOfStars()
end

function Wargroove.getNumberOfStarsAfterVictory(turnN)
    return api.getNumberOfStarsAfterVictory(turnN)
end

function Wargroove.resumeExecution(time)
    if Resumable == nil then
        Resumable = require "wargroove/resumable"
    end
    return Resumable.resumeExecution(time)
end

function Wargroove.chooseFish(unitPos)    
    return api.chooseFish(unitPos)
end

function Wargroove.openFishingUI(unitPos, fishId)    
    api.openFishingUI(unitPos, fishId)
end

function Wargroove.isLocalPlayer(playerId)
    return api.isLocalPlayer(playerId)
end

function Wargroove.getNumPlayers(independentOnly)
    return api.getNumPlayers(independentOnly)
end

function Wargroove.playCredits(creditsType)
    api.playCredits(creditsType)
end

function Wargroove.setMatchSeed(matchSeed)
    api.setMatchSeed(matchSeed)
end

function Wargroove.updateFogOfWar(matchseed)
    api.updateFogOfWar()
end

function Wargroove.changeObjective(objective)
    api.changeObjective(objective)
end

function Wargroove.showObjective()
    api.showObjective()
end

function Wargroove.moveLocationTo(locationId, position)
    api.moveLocationTo(locationId, position)
end

function Wargroove.setMapMusic(music)
    api.setMapMusic(music)
end

function Wargroove.getMapSize()
    return api.getMapSize()
end

function Wargroove.isHuman(playerId)
    return api.isHuman(playerId)
end

function Wargroove.setDifficulty(dmgMult)
    difficulty.damageMultiplier = dmgMult
end

function Wargroove.getDamageMultiplier()
    return difficulty.damageMultiplier
end

function Wargroove.getNetworkVersion()
    return api.getNetworkVersion()
end

function Wargroove.setUnitState(unit, key, value)
    local found = false
    for i, stateKey in ipairs(unit.state) do
        if (stateKey.key == key) then
            stateKey.value = value
            found = true
        end
    end

    if not found then
        table.insert(unit.state, {key = key, value = value})
    end
end

function Wargroove.getUnitState(unit, key)
    for i, stateKey in ipairs(unit.state) do
        if (stateKey.key == key) then
            return stateKey.value
        end
    end
    return nil
end

function Wargroove.notifyEvent(event, playerId)
    api.notifyEvent(event, playerId)
end

function Wargroove.getOrderId()
    return api.getOrderId()
end

function Wargroove.setThreatMap(unitId, threats)
    api.setThreatMap(unitId, threats)
end

function Wargroove.getBiome()
    return api.getBiome()
end

function Wargroove.getSplashEffect()
    return api.getSplashEffect()
end

return Wargroove
