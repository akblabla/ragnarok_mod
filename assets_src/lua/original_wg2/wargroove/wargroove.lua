local Wargroove = {}
local Resumable = require "wargroove/resumable"
local Functional = require "halley/functional"
local UnitBuffs = require "wargroove/unit_buffs"
local UnitBuffSpawns = require "wargroove/unit_buff_spawns"
local UnitPostCombat = require "wargroove/unit_post_combat"
local UnitPostCapture = require "wargroove/unit_post_capture"
local UnitPostVerb = require "wargroove/unit_post_verb"
local UnitPreCombat = require "wargroove/unit_pre_combat"
local UnitPreCapture = require "wargroove/unit_pre_capture"
local UnitPreVerb = require "wargroove/unit_pre_verb"
local PlayerBlessings = require "wargroove/player_blessings"
local UnitStateConditional = require "wargroove/unit_state_conditional"
local UnitOnTurn = require "wargroove/unit_on_turn"
local UnitOnEndOfTurn = require "wargroove/unit_on_end_of_turn"
local Resumable = require("wargroove/resumable")

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
    getItem = {},
    getPlayerTeam = {},
    getPlayerChildOf = {},
    getAllUnitIds = {},
    getLocationIdsAt = {}
}

local mapModifiers = {
    getCounterModifierAt = {}
}

local activeBuffs = {}

local onTurnCalls = {}

local difficulty = {
    damageMultiplier = 1.0
}

local metaUnitClass = {}

function sign(x)
    return (x<0 and -1) or 1
end

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

        if unit.health > 0 then
            local buff = buffs[unit.unitClassId]
            if buff ~= nil and buff ~= "" then
                buffsToApply[id] = unit
            end
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

function Wargroove.doPreCapture(unitId, playerId)
    local unit = Wargroove.getUnitById(unitId)
    if unit == nil then
        return
    end

    local preCapture = UnitPreCapture:getPreCapture(unit.unitClassId)
    if (preCapture ~= nil) then
        return preCapture(Wargroove, unit, playerId)
    end
end

function Wargroove.doPreCombat(attackerId, defenderId)
    local attacker = Wargroove.getUnitById(attackerId)
    if attacker == nil then
        return
    end

    local defender = Wargroove.getUnitById(defenderId)
    if defender == nil then
        return
    end

    local preCombat = UnitPreCombat:getPreCombat(attacker.unitClassId)
    if (preCombat ~= nil) then
        preCombat(Wargroove, attacker, defender, true)
    end

    preCombat = UnitPreCombat:getPreCombat(defender.unitClassId)
    if (preCombat ~= nil) then
        preCombat(Wargroove, attacker, defender, false)
    end
end

function Wargroove:doPostCombat(unitId, isAttacker, healthAfterCombat)
    local unit = Wargroove.getUnitById(unitId)
    if unit == nil then
        return
    end

    local postCombat = UnitPostCombat:getPostCombat(unit.unitClassId)
    if (postCombat ~= nil) then
        postCombat(Wargroove, unit, isAttacker, healthAfterCombat)
    end
end

function Wargroove:doPostCapture(unitId, capturerId, playerId)
    -- We reset the captured units cache just in case
    local unit = Wargroove.getUnitById(unitId)

    -- This is the worst
    if unit and unit.unitClassId == "portal_neutral" then
        caches.getUnitById[unitId] = nil
        unit = Wargroove.getUnitById(unitId)
    end

    local capturer = Wargroove.getUnitById(capturerId)

    if capturer == nil or unit == nil then
        return
    end

    local postCapture = UnitPostCapture:getPostCapture(unit.unitClassId)
    if (postCapture ~= nil) then
        return postCapture(Wargroove, unit, capturer, playerId)
    end
end

function Wargroove:doOnTurn(unitId)
    local unit = Wargroove.getUnitById(unitId)
    if unit == nil then
        return
    end

    local onTurn = UnitOnTurn:getOnTurn(unit.unitClassId)
    if (onTurn ~= nil) then
        onTurn(Wargroove, unit)
    end
end

function Wargroove:doOnEndOfTurn(unitId)
    local unit = Wargroove.getUnitById(unitId)
    if unit == nil then
        return
    end

    local onEndOfTurn = UnitOnEndOfTurn:getOnEndOfTurn(unit.unitClassId)
    if (onEndOfTurn ~= nil) then
        onEndOfTurn(Wargroove, unit)
    end
end

function Wargroove.doPostVerb(unitId, verb)
    local unit = Wargroove.getUnitById(unitId)
    if unit == nil then
        return
    end

    local postVerb = UnitPostVerb:getPostVerb(unit.unitClassId)
    if (postVerb ~= nil) then
        postVerb(Wargroove, unit, verb)
    end
end

function Wargroove:doPreVerb(unitId, verb, targetPos, strParam, path)
    local unit = Wargroove.getUnitById(unitId)
    if unit == nil then
        return false
    end

    local preVerb = UnitPreVerb:getPreVerb(unit.unitClassId)
    if (preVerb ~= nil) then
        return Resumable.run(function ()
            preVerb(Wargroove, unit, targetPos, strParam, path)
        end)
    end

    return false
end

function Wargroove:doStateConditionals(unitId, verb, targetPos, strParam, path)
    local unit = Wargroove.getUnitById(unitId)
    if unit == nil then
        return false
    end

    local stateConditional = UnitStateConditional.getStateConditional(Wargroove, unit)
    if (stateConditional ~= nil) then
        return Resumable.run(function ()
            stateConditional(Wargroove, unit, targetPos, strParam, path)
        end)
    end

    return false
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
    caches.getItem = {}
    caches.getWeapon = {}
    caches.getUnitClass = {}
    caches.getGizmoAt = {}
    caches.getAllUnitIds = {}
    caches.getLocationIdsAt = {}

    buffsToClear = nil
    buffsToApply = nil

    if (api.isApiReady()) then
        Wargroove.applyBuffs()
        Wargroove.refreshPlayerBlessings()
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

function Wargroove.pushBuff(turns, unit, playerId, buffSpawnId, buffId, buffDeathId)
    local startingState = {}
    local buffSpawn = {key = "buffSpawnId", value = buffSpawnId}
    local buff = {key = "buffId", value = buffId}
    local buffDeath = {key = "buffDeathId", value = buffDeathId}
    local unitId = {key = "unitId", value = ""..unit.id}
    local turnCount = {key = "turnCount", value = ""..turns}

    table.insert(startingState, buffSpawn)
    table.insert(startingState, buff)
    table.insert(startingState, buffDeath)
    table.insert(startingState, unitId)
    table.insert(startingState, turnCount)

    Wargroove.spawnUnit(playerId, {x = -100, y = -100}, "buff", false, "", startingState)
end

function Wargroove.getWeapon(weaponId, unitClassId, unitId)
    return cachedCall(caches.getWeapon, (weaponId .. unitClassId .. tostring(unitId)), api.getWeapon, weaponId, unitClassId, unitId or -1)
end

function Wargroove.getAllUnitIds()
    return cachedCall(caches.getAllUnitIds, "all", api.getAllUnits)
end

function Wargroove.getUnitClass(unitClassId, unitId)
    assert(unitClassId ~= nil)
    assert(unitClassId ~= "")

    local function getClass(id, unitId)
        local uc = api.getUnitClass(id, unitId or -1)
        if uc ~= nil then
            uc.weapons = {}
            for i, k in ipairs(uc.weaponIds) do
                uc.weapons[i] = Wargroove.getWeapon(k, id, unitId or -1)
            end
        end
        return uc
    end
    
    return cachedCall(caches.getUnitClass, unitClassId..tostring(unitId), getClass, unitClassId, unitId)
end

function Wargroove.getGroovePercentage(absoluteGroove, unit)
    local grooveConfig = Wargroove.getGroove(unit.grooveId)
    local groovePercentage = 0
    if absoluteGroove <= grooveConfig.grooveCost[1] then
        groovePercentage = clamp(math.floor((absoluteGroove/grooveConfig.grooveCost[1]) * 100.0 + 0.5), 0, 100)
    else
        -- int overTierOne = grooveCharge - grooveCost[0];
		-- return 100 + int(roundl(float(overTierOne) / float(grooveCost[1]-grooveCost[0]) * 100.0f));
        local overTierOne = absoluteGroove - grooveConfig.grooveCost[1]
        groovePercentage = 100 + clamp(math.floor((overTierOne/(grooveConfig.grooveCost[2]-grooveConfig.grooveCost[1])) * 100.0 + 0.5), 0, 100)
    end

    return groovePercentage
end

function Wargroove.getAbsoluteGroove(percentageGroove, unit)
    local grooveConfig = Wargroove.getGroove(unit.grooveId)
    local newCharge = 0
    if percentageGroove <= 100 then
        newCharge = clamp(math.floor((percentageGroove/100) * grooveConfig.grooveCost[1] + 0.5), 0, grooveConfig.grooveCost[1])
    else
        newCharge = clamp(grooveConfig.grooveCost[1] + math.floor((percentageGroove-100)/100 * (grooveConfig.grooveCost[2]-grooveConfig.grooveCost[1]) + 0.5), 0, grooveConfig.grooveCost[2])
    end

    return newCharge
end

function Wargroove.getUnitById(unitId)
    assert(unitId ~= nil)

    local function unitSetHealth(self, health, attackerId, ignoreParenting)
        if ignoreParenting == nil then
            ignoreParenting = false
        end

        if self.unitClass.isDamagingParentUnit and not ignoreParenting then
            local parentId = Wargroove.getUnitState(self, "parentId")
            local parent = Wargroove.getUnitById(tonumber(parentId))

            if parent then
                parent:setHealth(health, attackerId)
                Wargroove.updateUnit(parent)
            else
                print("Child that is supposed to have a parent didn't. Something went terribly wrong.")
            end
        end

        self.health = math.floor(math.max(0, math.min(health, 100)) * 0.01 * self.unitClass.maxHealth + 0.5)
        self.attackerId = attackerId
        if attackerId >= 0 then
            attacker = Wargroove.getUnitById(attackerId)
            self.attackerUnitClass = attacker.unitClass.id
            self.attackerPlayerId = attacker.playerId
        end
    end

    local function unitSetGroove(self, groove)
        self.grooveCharge = Wargroove.getAbsoluteGroove(groove, self)
    end

    if unitId == -1 then
        return nil
    end

    local function getUnit(id)
        local unit = api.getUnitById(id)
        if unit ~= nil then
            unit.unitClass = Wargroove.getUnitClass(unit.unitClassId, id)
            unit.setHealth = unitSetHealth
            unit.setGroove = unitSetGroove
            unit.hasBeenKilled = false
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

function Wargroove.getMapItemIdAt(x, y)
    return api.getMapItemIdAt(x, y)
end

function Wargroove.getMapItemAt(pos)
    return Wargroove.getMapItemById(Wargroove.getMapItemIdAt(pos.x, pos.y))
end

function Wargroove.getMapItemsAtLocation(location)
    local result = {}

    if location == nil then
        -- Anywhere
        for i, id in ipairs(api.getAllMapItems()) do
            local item = Wargroove.getMapItemById(id)
            if item ~= nil then
                table.insert(result, item)
            end
        end
    else
        -- Specific location
        for i, pos in ipairs(location.positions) do
            local item = Wargroove.getMapItemAt(pos)
            if item ~= nil then
                table.insert(result, item)
            end
        end
    end

    return result
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


function Wargroove.setPlayerColour(playerId, colour)
    api.setPlayerColour(playerId, colour)
end


function Wargroove.setPlayerCommander(playerId, commander)
    api.setPlayerCommander(playerId, commander)
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


function Wargroove.startCombat(attacker, defender, path, combatType)
    Wargroove.doPreCombat(attacker.id, defender.id)

    Wargroove.setMetaLocation("last_attacker", attacker.pos)
    Wargroove.setMetaLocation("last_defender", defender.pos)
    api.startCombat(attacker.id, defender.id, path, combatType)
    Wargroove.clearUnitPositionCache()
end


function Wargroove.startCapture(attacker, defender, attackerPos)
    Wargroove.doPreCapture(attacker.id, attacker.playerId)

    Wargroove.setMetaLocation("last_attacker", attacker.pos)
    Wargroove.setMetaLocation("last_defender", defender.pos)
    api.startCapture(attacker.id, defender.id, attackerPos)
end


function Wargroove.pickupItem(unit, itemId)
    api.pickupItem(unit.id, itemId)
end


function Wargroove.equipItem(unit, itemId)
    api.equipItem(unit.id, itemId)
end

function Wargroove.unequipItem(unit)
    api.unequipItem(unit.id)
end

function Wargroove.dropItem(unit, pos)
    api.dropItem(unit.id, pos)
end

function Wargroove.getKillRewardMultiplier()
    return api.getKillRewardMultiplier()
end

function Wargroove.setKillRewardMultiplier(multiplier)
    api.setKillRewardMultiplier(multiplier)
end


function Wargroove.spawnUnit(playerId, pos, unitType, turnSpent, startAnimation, startingState, factionOverride, ignoreBuffSpawns, skinColour, mapFacing)
    local id = api.spawnUnit(playerId, pos, unitType, turnSpent, startAnimation or "", startingState or {}, factionOverride or "", skinColour or "undefined", mapFacing or "right")
    Wargroove.clearUnitPositionCache()

    if not ignoreBuffSpawns then
        local buffSpawns = UnitBuffSpawns:getBuffSpawns()
        local buffSpawn = buffSpawns[unitType]
        if buffSpawn ~= nil and buffSpawn ~= "" then
            local unit = Wargroove.getUnitById(id)        
            buffSpawn(Wargroove, unit)
            coroutine.yield()
        end
    end

    Wargroove.refreshPlayerBlessings()

    return id
end


function Wargroove.spawnUnitInside(playerId, pos, unitType, startingState, factionOverride)
    api.spawnUnitInside(playerId, pos, unitType, startingState or {}, factionOverride or "")
    Wargroove.clearUnitPositionCache()

    coroutine.yield()
end


function Wargroove.updateUnit(unit, preventDeathReport)
    api.updateUnit(unit, preventDeathReport or false)
    Wargroove.clearUnitPositionCache()
end


function Wargroove.updateUnits(units)
    for i, unit in ipairs(units) do
        api.updateUnit(unit, false)
    end
    Wargroove.clearUnitPositionCache()
end


function Wargroove.removeUnit(unitId)
    api.removeUnit(unitId)
    Wargroove.clearUnitPositionCache()
end

function Wargroove.doLuaDeathCheck(unitId, waitForContinue)
    local wait = true
    if waitForContinue ~= nil then
        wait = waitForContinue
    end
    api.doLuaDeathCheck(unitId, wait)
end

function Wargroove.changeMoney(playerId, delta)
    print("Money: " .. api.getMoney(playerId) .. " Delta: " .. delta)
    api.setMoney(playerId, math.floor(delta + api.getMoney(playerId)))
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

function Wargroove.isGround(pos)
    return api.isGround(pos)
end

function Wargroove.setPlayerSkipStatus(playerId, skip)
    return api.setPlayerSkipStatus(playerId, skip)
end

function Wargroove.logAnalyticsAction(action, param1, param2, param3, amount)
    api.logAnalyticsAction(action, param1, param2, param3, amount or 0)
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


function Wargroove.popAllUnitPos()
    while (#unitPosStack > 0) do
        Wargroove.popUnitPos()
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

function Wargroove.getTerrainTargetsAround(pos, terrainType)
    local mapSize = Wargroove.getMapSize()

    local result = {}
    local x0 = pos.x
    local y0 = pos.y
    for yo = -1, 1 do
        for xo = -1, 1 do
            local x = x0 + xo
            local y = y0 + yo
            if (x >= 0) and (y >= 0) and (x < mapSize.x) and (y < mapSize.y) then
                local unitId = Wargroove.getUnitIdAtXY(x, y)
                local terrainId = Wargroove.getTerrainNameAt({x=x, y=y})

                if unitId == -1 and terrainId == terrainType then
                    table.insert(result, {x=x, y=y})
                end
            end
        end
    end

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
                        local itemId = Wargroove.getMapItemIdAt(x, y)

                        if (targetType == "unit" and unitId ~= -1) or (targetType == "empty" and unitId == -1 and itemId == -1) or (targetType == "item" and itemId ~= -1) then
                            table.insert(result, { x = x, y = y})
                        end
                    end
                end
            end
        end
    end

    return result
end


function Wargroove.getTargetsInRangeSquare(pos, range, targetType)
    local mapSize = Wargroove.getMapSize()

    local result = {}
    local x0 = pos.x
    local y0 = pos.y
    for yo = -range, range do
        for xo = -range, range do
            local x = x0 + xo
            local y = y0 + yo
            if (x >= 0) and (y >= 0) and (x < mapSize.x) and (y < mapSize.y) then
                if (targetType == "all") then
                    table.insert(result, { x = x, y = y})
                else
                    local unitId = Wargroove.getUnitIdAtXY(x, y)
                    local itemId = Wargroove.getMapItemIdAt(x, y)

                    if (targetType == "unit" and unitId ~= -1) or (targetType == "empty" and unitId == -1) or (targetType == "item" and itemId ~= -1) then
                        table.insert(result, { x = x, y = y})
                    end
                end
            end
        end
    end

    return result
end


function Wargroove.getWeaponDamage(weapon, attacker, defender)
    return api.getWeaponDamage(weapon.id, attacker.id, defender.id, defender.pos.x, defender.pos.y)
end


function Wargroove.getWeaponDamageForceGround(weaponId, attacker, defender)
    return api.getWeaponDamageForceGround(weaponId, attacker.id, defender.id, defender.pos.x, defender.pos.y)
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
    if cachedResult ~= nil then
        return cachedResult[1]
    end
    
    return nil
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

function Wargroove.clearCounterModifiers()
    mapModifiers.getCounterModifierAt = {}
end

function Wargroove.setCounterModifierAt(pos, modifier)
    Wargroove.putValueIntoCache(mapModifiers.getCounterModifierAt, xyToCacheKey(pos.x, pos.y), modifier)
end

function Wargroove.getCounterModifierAt(pos)
    local cachedResult = Wargroove.getValueFromCache(mapModifiers.getCounterModifierAt, xyToCacheKey(pos.x, pos.y))
    if cachedResult ~= nil then
        return cachedResult
    end

    return 0
end

function Wargroove.getAllUnitIdsForPlayer(playerId, includeChildren)
    return api.getAllUnitsForPlayer(playerId, includeChildren)
end

function Wargroove.getAllUnitsOfType(playerId, unitType)
    return Functional.map(Wargroove.getUnitById, api.getAllUnitsOfType(playerId, unitType));
end


function Wargroove.getAllUnitsForPlayer(playerId, includeChildren)
    return Functional.map(Wargroove.getUnitById, Wargroove.getAllUnitIdsForPlayer(playerId, includeChildren))
end


function Wargroove.getCommanderUnitsForPlayer(playerId)
    local allUnits = Wargroove.getAllUnitsForPlayer(playerId, true)
    local commanders = {}

    for _, unit in ipairs(allUnits) do
        if unit.unitClass.isCommander then
            table.insert(commanders, unit)
        end
    end

    return commanders
end


function Wargroove.getCurrentWeather()
    return api.getCurrentWeather()
end


function Wargroove.getGroove(grooveId)
    return cachedCall(caches.getGroove, grooveId, api.getGroove, grooveId)
end

function Wargroove.getItem(itemId)
    return cachedCall(caches.getItem, itemId, api.getItem, itemId)
end

function Wargroove.getMapItemById(id)
    return api.getMapItemById(id)
end

function Wargroove.getMapTriggers()
    return api.getMapTriggers()
end

function Wargroove.rewardCrystals(amount)
    return api.rewardCrystals(amount)
end

function Wargroove.setPlayerCounter(id, amount)
    api.setPlayerCounter(id, amount)
end

function Wargroove.getPlayerCounter(id)
    return api.getPlayerCounter(id)
end

function Wargroove.checkConquestUnlock(id)
    return api.checkConquestUnlock(id)
end

function Wargroove.unlockUnlock(id)
    return api.unlockUnlock(id)
end

function Wargroove.unlockAchievement(id)
    return api.unlockAchievement(id)
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

function Wargroove.getLocationByName(locationName)
    if locationName == nil then
        return nil
    end

    local loc = api.getLocationByName(locationName)
    loc.setArea = function(self, area)
        Wargroove.setLocationArea(self.id, area)
    end
    loc.getArea = function(self)
        return self.positions
    end
    return loc
end

function Wargroove.findPlaceInLocation(location, unitClassId)
    local candidates = {}
    local centre = nil
    local positions = nil

    if location == nil then
        -- No location, use whole map
        local mapSize = Wargroove.getMapSize()
        positions = {}
        for x = 0, mapSize.x - 1 do
            for y = 0, mapSize.y - 1 do
                table.insert(positions, { x = x, y = y })
            end
        end
        centre = { x = math.floor(mapSize.x / 2), y = math.floor(mapSize.y / 2) }
    else
        positions = location.positions
        centre = Wargroove.findCentreOfLocation(location)
    end

    -- All candidates
    for i, pos in ipairs(positions) do
        if Wargroove.getUnitIdAt(pos) == -1 and Wargroove.canStandAt(unitClassId, pos) then
            local dx = pos.x - centre.x
            local dy = pos.y - centre.y
            local dist = dx * dx + dy * dy
            table.insert(candidates, { pos = pos, dist = dist })
        end
    end

    -- Sort candidates
    table.sort(candidates, function(a, b) return a.dist < b.dist end)
    return candidates
end

function Wargroove.findCentreOfLocation(location)
    local centre = { x = 0, y = 0 }
    for i, pos in ipairs(location.positions) do
        centre.x = centre.x + pos.x
        centre.y = centre.y + pos.y
    end
    centre.x = centre.x / #(location.positions)
    centre.y = centre.y / #(location.positions)

    return centre
end


function Wargroove.getLocationIdsAt(x, y)
    return cachedCall(caches.getLocationIdsAt, xyToCacheKey(x, y), api.getLocationIdsAt, x, y)
end

function Wargroove.setMetaLocation(name, pos)
    local area = {}
    table.insert(area, pos)
    Wargroove.setMetaLocationArea(name, area)
end


function Wargroove.setMetaLocationArea(name, area)
    return api.setMetaLocation(name, area)
end


function Wargroove.setMetaUnitClass(name, unitClass)
    metaUnitClass[name] = unitClass
end

function Wargroove.reportUnitRecruited(unitId, unitClass)
    api.reportUnitRecruited(unitId, unitClass)
end

function Wargroove.reportItemPurchased(unitId, itemClass)
    api.reportItemPurchased(unitId, itemClass)
end


function Wargroove.getMetaUnitClass(name)
    local uc = metaUnitClass[name]
    return uc
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

function Wargroove.activateFlood(location, terrain)
    api.activateFlood(location, terrain)
end

function Wargroove.spawnItem(location, item)
    api.spawnItem(location, item)
end

function Wargroove.spawnItemAt(item, pos)
    api.spawnItemAt(item, pos)
end

function Wargroove.consumeItemAt(pos)
    api.consumeItemAt(pos)
end

function Wargroove.unitAction(selectableUnitIds, endPositions, targetPositions, action, usesTurn, ignoreRange, ignoreTerrainSpeed, param)
    api.unitAction(selectableUnitIds, endPositions, targetPositions, action, usesTurn, ignoreRange, ignoreTerrainSpeed, param)
end

function Wargroove.setTerrainType(pos, terrain, removeDecorations)
    api.setTerrainType(pos, terrain, removeDecorations)
end

function Wargroove.setUnitModifier(id, stat, value, duration)
    api.setUnitModifier(id, stat, value, duration)
end

function Wargroove.getUnitModifier(id, stat, value)
    return api.getUnitModifier(id, stat, value)
end

function Wargroove.pushUnitClassModifier(unitId, modifierId)
    api.pushUnitClassModifier(unitId, modifierId)
end

function Wargroove.popUnitClassModifier(unitId, modifierId)
    api.popUnitClassModifier(unitId, modifierId);
end

function Wargroove.registerPlayerBlessing(id, playerId)
    api.registerPlayerBlessing(id, playerId)
    Wargroove.refreshPlayerBlessings()
end

function Wargroove.refreshPlayerBlessings()
    local blessings = api.getPlayerBlessings()

    for _, blessing in ipairs(blessings) do
        local units = Wargroove.getAllUnitsForPlayer(blessing.playerId)
        for _, unit in ipairs(units) do
            local alreadyHasBlessing = false;

            for _, b in ipairs(unit.blessings) do
                if b == blessing.id then
                    alreadyHasBlessing = true
                end
            end

            local condition = Wargroove:getBlessing(blessing.id.."_condition")

            if alreadyHasBlessing == false and condition ~= nil and condition(Wargroove, blessing.playerId, unit) then
                local action = Wargroove:getBlessing(blessing.id.."_action")
                if action then
                    action(Wargroove, blessing.playerId, unit)
                    table.insert(unit.blessings, blessing.id)
                    Wargroove.updateUnit(unit)
                end
            end
        end
    end
end

function Wargroove.doesUnitHaveBlessing(unit, blessingId)
    for _, b in ipairs(unit.blessings) do
        if b == blessingId then
            return true
        end
    end

    return false
end

function Wargroove.getBlessingFormation(blessingId)
    return api.getBlessingFormation(blessingId)
end

function Wargroove.getBlessingFunds(blessingId)
    return api.getBlessingFunds(blessingId)
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


function Wargroove.showDialogueBox(expression, character, message, shout, decisions, type, instant, name, playerColour)
    api.showDialogueBox(expression, character, message, shout, decisions, type, instant, name, playerColour or "")
    coroutine.yield()
end

function Wargroove.showTutorialBox(icon, title, message, instant)
    api.showTutorialBox(icon, title, message, instant)
    coroutine.yield()
end

function Wargroove.showLocationBox(title, message, instant)
    api.showLocationBox(title, message, instant)
    coroutine.yield()
end

function Wargroove.playShout(shout, character)
    api.playShout(shout, character)
    coroutine.yield()
end


function Wargroove.getMapVariables(id)
    return api.getMapVariables(id)
end


function Wargroove.trackCameraTo(pos, noDelay)
    api.trackCameraTo(pos, noDelay)

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

function Wargroove.playGrooveChargeUp(pos, playerId)
    Wargroove.playPositionlessSound("grooveChargeUp")
    Wargroove.spawnPaletteSwappedMapAnimation(pos, 1, "units/commanders/groove_powerup_back", playerId, "idle", "behind_units", {x = 13, y = 16})
    Wargroove.spawnPaletteSwappedMapAnimation(pos, 1, "units/commanders/groove_powerup_front", playerId, "idle", "over_units", {x = 13, y = 16})

    Wargroove.waitTime(0.8)
end

function Wargroove.playUnitAnimation(unitId, sequence, thenLoop)
    api.playUnitAnimation(unitId, sequence, thenLoop or "idle")
end

function Wargroove.playItemAnimation(itemId, sequence)
    api.playItemAnimationOnce(itemId, sequence)
end

function Wargroove.playUnitAnimationOnce(unitId, sequence)
    api.playUnitAnimationOnce(unitId, sequence)
end

function Wargroove.playUnitDeathAnimation(unitId)
    api.playUnitDeathAnimation(unitId)
end

function Wargroove.randomIntegerFromTable(values, min, max)
    local str = ""
    for i, v in ipairs(values) do
        str = str .. tostring(v) .. ":"
    end
    return Wargroove.randomInteger(str, min, max)
end

function Wargroove.randomInteger(str, min, max)
    return math.floor(Wargroove.pseudoRandomFromString(str) * (max - min + 1)) + min
end

function Wargroove.pseudoRandomFromString(str)
    return api.pseudoRandomFromString(str)
end

function Wargroove.isRNGEnabled()
    return api.isRNGEnabled()
end

function Wargroove.canPlayerSeeTile(player, tile)
    return api.canPlayerSeeTile(player, tile, true)
end

function Wargroove.canAIPlayerSeeTile(player, tile)
    return api.canPlayerSeeTile(player, tile, false)
end

function Wargroove.canPlayerSeeUnit(player, unitId)
    return api.canPlayerSeeUnit(player, unitId)
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

function Wargroove.setDaytime(daytime)
    api.setDaytime(daytime)
end

function Wargroove.setWeather(weather, daysAhead)
    api.setWeather(weather, daysAhead)
end


function Wargroove.setAIRestriction(unitId, restriction, value)
    api.setAIRestriction(unitId, restriction, value)
end

function Wargroove.hasAIRestriction(unitId, restriction)
    return api.hasAIRestriction(unitId, restriction)
end

function Wargroove.forceAction(selectableUnitIds, endPositions, targetPositions, action, autoEnd, expression, commander, dialogue, name)
    api.forceAction(selectableUnitIds, endPositions, targetPositions, action, autoEnd, expression, commander, dialogue, name)
end

function Wargroove.forceOpenTutorial(tutorialId, selectableTargets, expression, commander, dialogue, mapFlag, mapFlagValue, name)
    api.forceOpenTutorial(tutorialId, selectableTargets, expression, commander, dialogue, mapFlag, mapFlagValue, name)
end

function Wargroove.queueForceAction(selectableUnitIds, endPositions, targetPositions, action, autoEnd, expression, commander, dialogue, name)
    api.queueForceAction(selectableUnitIds, endPositions, targetPositions, action, autoEnd, expression, commander, dialogue, name)
end

function Wargroove.queueForceOpenTutorial(tutorialId, selectableTargets, expression, commander, dialogue, mapFlag, mapFlagValue, name)
    api.queueForceOpenTutorial(tutorialId, selectableTargets, expression, commander, dialogue, mapFlag, mapFlagValue, name)
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

function Wargroove.openRecruitMenu(player, recruitBaseId, recruitBasePos, unitClassId, units, costMultiplier, unbannableUnits, factionOverride, discount)
    api.openRecruitMenu(player, recruitBaseId, recruitBasePos, unitClassId, units, costMultiplier, unbannableUnits, factionOverride, discount or 0)
end

function Wargroove.openItemPickMenu(player, items)
    api.openItemPickMenu(player, items)
end

function Wargroove.recruitMenuIsOpen()
    return api.recruitMenuIsOpen()
end

function Wargroove.popRecruitedUnitClass()
    return api.popRecruitedUnitClass()
end

function Wargroove.openBlessingPickMenu(player, blessingGroup, number, title, type)
    api.openBlessingPickMenu(player, blessingGroup, number, title, type)
end

function Wargroove.blessingPickMenuIsOpen()
    return api.blessingPickMenuIsOpen()
end

function Wargroove.popBlessingPicked()
    return api.popBlessingPicked()
end

function Wargroove.popAdditionalBlessingPicked()
    return api.popAdditionalBlessingPicked()
end

function Wargroove:getBlessing(blessingId)
    return PlayerBlessings:getBlessing(Wargroove, blessingId)
end

function Wargroove.itemPickMenuIsOpen()
    return api.itemPickMenuIsOpen()
end

function Wargroove.popItemPickedClass()
    return api.popItemPickedClass()
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

function Wargroove.showMovementArrow()
    api.showMovementArrow()
end

function Wargroove.hideMovementArrow()
    api.hideMovementArrow()
end

function Wargroove.getSelectedDecision()
    return api.getSelectedDecision()
end

function Wargroove.displayBuffVisualEffect(parentId, playerId, animation, startSequence, alpha, effectPositions, layer, offset, startSequenceIsLooping, swapPlayerColour)
    if swapPlayerColour == nil then swapPlayerColour = true end
    api.displayBuffVisualEffect(parentId, playerId, animation, startSequence, alpha, effectPositions or {Wargroove.getUnitById(parentId).pos}, layer or "", offset or {}, startSequenceIsLooping or false, swapPlayerColour)
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

function Wargroove.moveUnitToOverride(unitId, endPos, offsetX, offsetY, speed, interpolation)
    api.moveUnitToOverride(unitId, endPos, offsetX, offsetY, speed, interpolation or "linear")
end

function Wargroove.isLuaMoving(unitId)
    return api.isLuaMoving(unitId)
end

function Wargroove.spawnUnitEffect(parentUnitId, referenceUnitId, name, sequence, startAnimation, inFront, paletteSwap)
    if paletteSwap == nil then paletteSwap = true end
    return api.spawnUnitEffect(parentUnitId, referenceUnitId, name, sequence, startAnimation, inFront, paletteSwap)
end

function Wargroove.deleteUnitEffect(entityId, endAnimation)
    api.deleteUnitEffect(entityId, endAnimation)
end

function Wargroove.deleteUnitEffectByAnimation(parentUnitId, animation, endAnimation)
    local unit = Wargroove.getUnitById(parentUnitId)
    if unit then
        print("Unit id: "..parentUnitId.." ("..unit.unitClassId..") at [x: "..unit.pos.x..",y: "..unit.pos.y.."]")
    end
    
    api.deleteUnitEffectByAnimation(parentUnitId, animation, endAnimation)
end

function Wargroove.hasUnitEffect(parentUnitId, animation)
    return api.hasUnitEffect(parentUnitId, animation)
end

function Wargroove.setIsUsingGroove(unitId, isUsing)
    api.setIsUsingGroove(unitId, isUsing)
end

function Wargroove.setIsUsingItem(unitId, isUsing)
    api.setIsUsingItem(unitId, isUsing)
end

function Wargroove.playGrooveCutscene(unitId, tier, verb, commanderOverride)
    api.playGrooveCutscene(unitId, tier, verb or "", commanderOverride or "")
    coroutine.yield()
end

function Wargroove.playGrooveCutsceneForCharacter(character)
    Wargroove.playPositionlessSound("battleStart")
    api.playGrooveCutsceneForCharacter(character)
    coroutine.yield()
end

function Wargroove.playIntroductionForCharacter(character, shout, name, title)
    api.playIntroductionForCharacter(character, shout, name, title)
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

function Wargroove.setLocationProperties(location, isAIObstacle, isObstacle, isInteractable)
    api.setLocationProperties(location, isAIObstacle, isObstacle, isInteractable)
end

function Wargroove.displayMovementGrid(target)
    api.displayMovementGrid(target)
end

function Wargroove.hideMovementGrid()
    api.hideMovementGrid()
end

function Wargroove.setProtagonist(unit, isProtagonist)
    api.setProtagonist(unit.id, isProtagonist)
end

function Wargroove.openCodex(codexEntry)
    api.openCodex(codexEntry)
end

function Wargroove.setCutsceneMode(active)
    api.setCutsceneMode(active)
end

function Wargroove.isConquestMode()
    return api.isConquestMode();
end

function Wargroove.getConquestDifficulty()
    return api.getConquestDifficulty()
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
    
    return Resumable.run(function ()
        Events.runActions(actions.expressions)
    end)
end 

function Wargroove.areIntroEventsSkippable()
    return api.areIntroEventsSkippable();
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
    local unit = Wargroove.getUnitById(id)

    local mapSize = Wargroove.getMapSize()
    if unit and (unit.pos.x < 0 or unit.pos.y < 0 or unit.pos.x > mapSize.x or unit.pos.y > mapSize.y) then
        return false
    else
        Events.reportUnitDeath(id, attackerId, attackerPlayerId, attackerUnitClass)
        return true
    end
end

function Wargroove.reportVerbUsed(id, verb, isGrooveVerb, targetPos, strParam, path)
    if Events == nil then
        Events = require "wargroove/events"
    end
    Events.reportVerbUsed(id, verb, isGrooveVerb, targetPos, strParam, path)
end

function Wargroove.reportInteractionUsed(id, verb, targetPos, path)
    if Events == nil then
        Events = require "wargroove/events"
    end
    Events.reportInteractionUsed(id, verb, targetPos, path)
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

function Wargroove.fulfillBonusObjective(bonusTriggerId)
    return api.fulfillBonusObjective(bonusTriggerId)
end

function Wargroove.failBonusObjective(bonusTriggerId)
    return api.failBonusObjective(bonusTriggerId)
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

function Wargroove.chooseBird(unitPos)    
    return api.chooseBird(unitPos)
end

function Wargroove.openFishingUI(unitPos, fishId, tier)    
    api.openFishingUI(unitPos, fishId, tier)
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

function Wargroove.revealFogOfWar(playerId, locationId, visible)
    api.revealFogOfWar(playerId, locationId, visible)
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

function Wargroove.showConstantObjective()
    api.showConstantObjective()
end

function Wargroove.hideConstantObjective()
    api.hideConstantObjective()
end

function Wargroove.updateConstantObjective(message, replacement, replacementTwo)
    api.updateConstantObjective(message, replacement, replacementTwo)
end

function Wargroove.moveLocationTo(locationId, position)
    api.moveLocationTo(locationId, position)
end

function Wargroove.setMapMusic(music, intensity)
    api.setMapMusic(music, intensity)
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

function Wargroove.isExecutingScript()
    return api.isExecutingScript()
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

function Wargroove.fadeStage(direction, time, belowHUD)
    local dir = -1
    if direction == 'out' then
        dir = 1
    end
    api.fadeStage(dir, time, belowHUD)
end

function Wargroove.showMapUI(show)
    api.showMapUI(show)
end

function Wargroove.showInteractionsMenu(verbs)
    api.showInteractionsMenu(verbs)
end

function Wargroove.interactionsMenuIsOpen()
    return api.interactionsMenuIsOpen()
end

function Wargroove.getInteractionsVerb()
    return api.getInteractionsVerb()
end

function Wargroove.setInteractTarget(targetPos)
    if Events == nil then
        Events = require "wargroove/events"
    end

    Events.setInteractTarget(targetPos)
end

function Wargroove.refreshObstacles()
    api.refreshObstacles()
end

function Wargroove.selectProtagonist()
    api.selectProtagonist()
end

function Wargroove.screenshake(duration, offset, speed)
    api.screenshake(duration, offset, speed)
end

function Wargroove.canRenameUnit(unitId)
    return api.canRenameUnit(unitId)
end

function Wargroove.showRenameWindow(unitId)
    api.showRenameWindow(unitId)
end

local pushDamage = 20

function Wargroove.isValidPushPullTarget(unit, pushCommanders)
    if (not pushCommanders and unit.unitClass.isCommander) or unit.unitClass.isStructure or unit.tentacled or unit.unitClassId == "tentacle" or unit.unitClassId == "organ" or unit.unitClassId == "organ_up" or unit.unitClassId == "golem_unit" then
        return false
    end

    -- Krakens are excluded from push/pull when they have an active tentacle as a "bonus"
    if (unit.unitClassId == "kraken") then
        local targetId = Wargroove.getUnitState(unit, "targetId")

        if targetId ~= nil and targetId ~= "" then
            return false
        end
    end

    return true
end

function Wargroove.getPushPullResult(originPos, targetPos, direction, isPreview, pushCommanders)
    local deltaX = clamp(targetPos.x - originPos.x, -1, 1)
    local deltaY = clamp(targetPos.y - originPos.y, -1, 1)

    -- 1. Should the unit at target be pushed: true/false depending on unit type. Structures/Commanders no, everything else yes.
    -- Units can be pulled/pushed into/from water no matter if they can move there normally. Same for abyss and rivers. If they can't normally stay in that position,
    -- They will break and die. All OTHER non-walkable tiles of those units, will lead to a push/pull damage in that situation.
    -- 2. Is there a unit at push position: true/false
    -- 3. If 2. is true, unit at push position will receive push damage
    -- 4. If 2. is true OR unit is being pushed into an illegal tile such as walls/structures/etc. deal push damage to unit being pushed 

    local result = {}

    -- 0. If there's no unit at the target position at all, ignore position and return
    local targetUnit = Wargroove.getUnitAt(targetPos)
    if not targetUnit then
        return nil
    end

    -- 1. Should the unit at target be pushed: true/false depending on unit type. Structures/Commanders no, everything else yes. If this is false *here*, we return.
    -- This can later be set to false still, by terrain/unit blockage, but in that case we hand out damage.
    result["targetUnit"] = targetUnit
    result["targetUnitCollisionDamage"] = false
    if not Wargroove.isValidPushPullTarget(targetUnit, pushCommanders) then
        result["pushTargetUnit"] = false
        return result
    end

    -- 2. Check for obstacles along the way, we want to stop at the first enemy or obstacle 
    local absoluteDistance = math.abs(direction)
    local pushDistance = 1
    
    result["pushTargetUnit"] = true

    for i=1, absoluteDistance do
        local tmpPushPosition = { x=targetPos.x + (deltaX * (i*sign(direction))), y=targetPos.y + (deltaY * (i*sign(direction))) }
        
        local pushPositionUnit = Wargroove.getUnitAt(tmpPushPosition)

        if pushPositionUnit then
            result["pushPositionUnit"] = pushPositionUnit

            if pushPositionUnit.playerId >= 0 then
                result["pushPositionUnitCollisionDamage"] = true
            end
        end
        
        local canStandAt = Wargroove.canStandAt(targetUnit.unitClassId, tmpPushPosition)
        local isBreakPosition = Wargroove.isPushPullBreakPosition(tmpPushPosition, targetUnit)
        
        pushDistance = i
        result["isBreakPosition"] = isBreakPosition

        if pushPositionUnit and canStandAt then
            if not isPreview then
                pushDistance = i-1
            end
            result["targetUnitCollisionDamage"] = true
            break
        elseif not canStandAt and not isBreakPosition then
            if not isPreview then
                pushDistance = i-1
            end
            result["targetUnitCollisionDamage"] = true
            break
        elseif not canStandAt and pushPositionUnit then
            if not isPreview then
                pushDistance = i-1
            end
            result["targetUnitCollisionDamage"] = true
            break
        elseif not canStandAt and isBreakPosition then
            result["targetUnitCollisionDamage"] = false
            break
        end
    end
    
    local pushPosition = { x=targetPos.x + (deltaX * (pushDistance*sign(direction))), y=targetPos.y + (deltaY * (pushDistance*sign(direction))) }
    result["pushPosition"] = pushPosition

    if pushPosition.x == targetUnit.pos.x and pushPosition.y == targetUnit.pos.y then
        result["pushTargetUnit"] = false
    end

    return result
end

function Wargroove.isPushPullBreakPosition(pos, unit)
    local movementType = unit.unitClass.movementType

    local biome = Wargroove.getBiome()

    if movementType == "flying" or movementType == "hovering" then
        return false
    end

    local terrainName = Wargroove.getTerrainNameAt(pos)
    if terrainName == "abyss" then
        return true
    end

    if biome == "dungeon_lava" then
        if (movementType == "amphibious" and (terrainName == "sea" or terrainName == "ocean" or terrainName == "reef" or terrainName == "river")) then
            return false
        end
    
        if (movementType == "walking" or movementType == "riding" or movementType == "airphibious") and (terrainName == "sea" or terrainName == "ocean" or terrainName == "reef" or terrainName == "river") then
            return true
        elseif movementType == "wheels" and (terrainName == "sea" or terrainName == "ocean" or terrainName == "reef" or terrainName == "river") then
            return true
        elseif (movementType == "sailing" or movementType == "river_sailing") and (terrainName == "bridge" or terrainName == "plains" or terrainName == "road" or terrainName == "forest" 
                                        or terrainName == "forest_cut" or terrainName == "mountain" or terrainName == "cobblestone" or terrainName == "carpet" or terrainName == "wall") then
            return true
        end
    else 
        if movementType == "amphibious" then
            return false
        end
    
        if (movementType == "walking" or movementType == "riding" or movementType == "airphibious") and (terrainName == "sea" or terrainName == "ocean" or terrainName == "reef") then
            return true
        elseif movementType == "wheels" and (terrainName == "sea" or terrainName == "ocean" or terrainName == "reef" or terrainName == "river") then
            return true
        elseif (movementType == "sailing" or movementType == "river_sailing") and (terrainName == "bridge" or terrainName == "plains" or terrainName == "road" or terrainName == "forest" 
                                        or terrainName == "forest_cut" or terrainName == "mountain" or terrainName == "cobblestone" or terrainName == "carpet" or terrainName == "wall") then
            return true
        end
    end

    return false
end

function Wargroove.doesUnitHaveTag(unit, tags)
    local targetTags = unit.unitClass.tags
    for _, tag in ipairs(targetTags) do
        for _, t in ipairs(tags) do
            if t == tag then
                return true
            end
        end
    end

    return false
end

function Wargroove.untangleKraken(unit)
    local targetId = tonumber(Wargroove.getUnitState(unit, "targetId"))
    if not targetId then
        return
    end

    local targetUnit = Wargroove.getUnitById(tonumber(targetId))
    if (targetUnit and not targetUnit.tentacled) or not targetUnit then
        return
    end

    local tentaclePositionsString = Wargroove.getUnitState(unit, "tentacles")
    local tentaclePositions = Wargroove.stringToPositions(tentaclePositionsString)

    for i, pos in ipairs(tentaclePositions) do
        local tentacle = Wargroove.getUnitAt(pos)
        tentacle:setHealth(0, tentacle.id, true)
        Wargroove.removeUnit(tentacle.id)
    end

    -- TODO: Add untangle animation
    Wargroove.deleteUnitEffectByAnimation(targetUnit.id, "units/kraken/cherrystone/map_kraken_tentacle_cherrystone", "")

    Wargroove.setUnitState(unit, "tentacles", "")
    Wargroove.setUnitState(unit, "targetId", nil)
    Wargroove.updateUnit(unit)

    targetUnit.tentacled = false
    Wargroove.updateUnit(targetUnit)

    Wargroove.playUnitAnimation(unit.id, "idle")
end

function Wargroove.processPushPullResult(pusher, pushResults, pushDamage, collisionDamage)
    local targetUnit = pushResults["targetUnit"]
    local targetHitPlayed = false
    if targetUnit and pushDamage > 0 then
        targetUnit:setHealth(targetUnit.health - pushDamage, pusher.id)
        Wargroove.updateUnit(targetUnit)

        targetHitPlayed = true
        Wargroove.playUnitAnimation(targetUnit.id, "hit")
    end

    if pushResults["pushTargetUnit"] then
        Wargroove.spawnMapAnimation(targetUnit.pos, 0, "fx/groove/push_effect", "idle", "units", {x = 12, y=12})

        -- Special case for Kraken here, we need to break the hold potentially
        if targetUnit.unitClassId == "kraken" then
            Wargroove.untangleKraken(targetUnit)
        end

        Wargroove.moveUnitToOverride(targetUnit.id, pushResults["pushPosition"], 0, 0, 10)
        targetUnit.pos = pushResults["pushPosition"]
        while (Wargroove.isLuaMoving(targetUnit.id)) do
            coroutine.yield()
        end
        Wargroove.updateUnit(targetUnit)
    end
    
    if pushResults["targetUnitCollisionDamage"] then
        targetUnit:setHealth(targetUnit.health - collisionDamage, pusher.id)
        Wargroove.updateUnit(targetUnit)
        if not targetHitPlayed then
            Wargroove.playUnitAnimation(targetUnit.id, "hit")
        end
    end

    if pushResults["pushPositionUnit"] then
        if pushResults["pushPositionUnitCollisionDamage"] then
            local pushPositionUnit = pushResults["pushPositionUnit"]
            pushPositionUnit:setHealth(pushPositionUnit.health - collisionDamage, pusher.id)
            Wargroove.updateUnit(pushPositionUnit)
            Wargroove.playUnitAnimation(pushPositionUnit.id, "hit")
        end
    end
end

function Wargroove.batchProcessPushPullResult(pusher, pushResult, pushDamage, collisionDamage, speed)
    local lastPushedUnitId = nil

    local targetUnit = pushResult["targetUnit"]
    if targetUnit and pushDamage > 0 then
        targetUnit:setHealth(targetUnit.health - pushDamage, pusher.id)
        Wargroove.playUnitAnimation(targetUnit.id, "hit")
    end

    if pushResult["pushTargetUnit"] then
        Wargroove.moveUnitToOverride(targetUnit.id, pushResult["pushPosition"], 0, 0, speed)
        targetUnit.pos = pushResult["pushPosition"]
        lastPushedUnitId = targetUnit.id
    end

    return lastPushedUnitId
end

function Wargroove.finalizeBatchPushPullResults(pusher, pushResults, pushDamage, collisionDamage)
    for i, pushResult in ipairs(pushResults) do
        local targetUnit = pushResult["targetUnit"]
        Wargroove.updateUnit(targetUnit, true)
        if i == 1 then
            Wargroove.doLuaDeathCheck(targetUnit.id)
        end
    
        if pushResult["targetUnitCollisionDamage"] then
            targetUnit:setHealth(targetUnit.health - collisionDamage, pusher.id)
            Wargroove.updateUnit(targetUnit, true)
            if not targetHitPlayed then
                Wargroove.playUnitAnimation(targetUnit.id, "hit")
            end
        end

        if pushResult["pushPositionUnit"] then
            if pushResult["pushPositionUnitCollisionDamage"] then
                local pushPositionUnit = pushResult["pushPositionUnit"]
                pushPositionUnit:setHealth(pushPositionUnit.health - collisionDamage, pusher.id)
                Wargroove.updateUnit(pushPositionUnit, true)
                Wargroove.playUnitAnimation(pushPositionUnit.id, "hit")
            end
        end
    end
end

function Wargroove.createTargetArrowFromPushPullResult(pushPullResult)
    if pushPullResult["pushPosition"] == nil then
        return nil
    end

    local arrowType = "default"
    if pushPullResult["targetUnitCollisionDamage"] then
        arrowType = "collision"
    elseif pushPullResult["isBreakPosition"] then
        arrowType = "break"
    end

    local arrowPositions = {}

    local endPos = pushPullResult["pushPosition"]
    local pos = { x=pushPullResult["targetUnit"].pos.x, y=pushPullResult["targetUnit"].pos.y }

    local deltaX = clamp(endPos.x - pos.x, -1, 1)
    local deltaY = clamp(endPos.y - pos.y, -1, 1)

    while(pos.x ~= endPos.x or pos.y ~= endPos.y)
    do
        table.insert(arrowPositions, { x=pos.x, y=pos.y })

        pos.x = pos.x + deltaX
        pos.y = pos.y + deltaY
    end
    table.insert(arrowPositions, { x=pos.x, y=pos.y })
    
    return { positions=arrowPositions, type=arrowType }
end

function Wargroove.getFacing(unit, targetPos)
    if (unit.pos.x < targetPos.x) then
        return "right"
    elseif (unit.pos.x > targetPos.x) then
        return "left"
    elseif (unit.pos.y > targetPos.y) then
        return "up"
    else
        return "down"
    end
end

function Wargroove.getTroopUnitClasses()
    return { "villager", "soldier", "dog", "spearman", "mage", "archer", "merman", "griffin_walking", "thief", "rifleman"  }
end

function Wargroove.isInList(value, list)
    for _, v in ipairs(list) do
        if v == value then
            return true
        end
    end

    return false
end

function Wargroove.indexInList(value, list)
    for i, v in ipairs(list) do
        if v == value then
            return i
        end
    end

    return -1
end

function Wargroove.unitIdsToString(ids)
    local result = ""

    for i, id in ipairs(ids) do
        result = result .. id
        if i ~= #ids then
            result = result .. ";"
        end
    end

    return result
end

function Wargroove.stringToTable(str)
    if str == nil then 
        return nil 
    end

    local ids={}
    i = 1
    for idStr in string.gmatch(str, "([^"..";".."]+)") do
        ids[i] = idStr
        i = i+1
    end

    if i == 1 then
        ids[1] = str
    end

    return ids
end

function Wargroove.stringToUnitIds(str)
    if str == nil then 
        return nil 
    end

    local ids={}
    i = 1
    for idStr in string.gmatch(str, "([^"..";".."]+)") do
        ids[i] = tonumber(idStr)
        i = i+1
    end

    if i == 1 then
        ids[1] = tonumber(str)
    end

    return ids
end

function Wargroove.splitString(str, sep)
    if str == nil then 
        return nil 
    end

    if sep == nil or sep == "" then
        return str
    end

    local strings={}
    for s in string.gmatch(str, "([^"..sep.."]+)") do
        table.insert(strings, s)
    end
    if #strings == 0 then
        return str
    end

    return strings
end

function Wargroove.positionsToString(positions)
    local strParam = ""
    local start = true
    for unitId, target in pairs(positions) do
        if start then
            start = false
        else
            strParam = strParam .. ";"
        end

        strParam = strParam .. unitId .. ":" .. target.x .. "," .. target.y
    end
    return strParam
end

function Wargroove.stringToPositions(strParam)
    local targetStrs={}
    local i = 1
    for targetStr in string.gmatch(strParam, "([^"..";".."]+)") do
        targetStrs[i] = targetStr
        i = i + 1
    end

    local targets = {}
    i = 1
    for unitId, targetStr in pairs(targetStrs) do
        local vals = {}
        local j = 1
        for val in targetStr.gmatch(targetStr, "([^"..":".."]+)") do
            vals[j] = val
            j = j + 1
        end

        local unitId = vals[1]
        local target = {}
        j = 1
        for val in targetStr.gmatch(vals[2], "([^"..",".."]+)") do
            target[j] = val
            j = j + 1
        end

        targets[tonumber(unitId)] = { x = tonumber(target[1]), y = tonumber(target[2])}
        i = i + 1
    end

    return targets
end

function Wargroove.tableToString(o)
    if type(o) == 'table' then
        local s = '{ '
        for k,v in pairs(o) do
            if type(k) ~= 'number' then k = '"'..k..'"' end
            s = s .. '['..k..'] = ' .. Wargroove.tableToString(v) .. ','
        end
        return s .. '} '
    else
        return tostring(o)
    end
end

function clamp(val, min, max)
    return math.max(min, math.min(max, val))
end

function Wargroove.runGC(verbose)
    local mem1 = 0
    if verbose then
        mem1 = collectgarbage("count")
    end

    collectgarbage("collect")
    
    if verbose then
        local mem2 = collectgarbage("count")
        print("LUA memory: " .. mem2 .. " kb in use, " .. (mem1 - mem2) .. " kb freed")
    end
end

function Wargroove.reportGC()
    local mem = collectgarbage("count")
    print("LUA memory: " .. mem .. " kb in use")
end

return Wargroove
