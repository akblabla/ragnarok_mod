
local Wargroove = require("wargroove/wargroove")
local WargrooveExtra = require("initialized/wargroove_extra")
local Ragnarok = require("initialized/ragnarok")
local json = require("util/json")
local io = require("io")
local CheckpointManager = {}
local checkpointLoaded = false

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

function CheckpointManager.init()
    Ragnarok.addAction(CheckpointManager.updateCheckpointBuffer,"repeating",false)
end
function CheckpointManager.isCheckpointLoaded()
    return checkpointLoaded
end

function CheckpointManager.extractMatchState(context)
    local matchState = {}
    print("set up matchState")
    matchState.mapCounters = {}
    for k,data in ipairs(context.mapCounters) do
        matchState.mapCounters[k] = data
    end
    print("set up mapCounters")
    matchState.creditsToPlay = context.creditsToPlay
    print("set up creditsToPlay")
    matchState.campaignCutscenes = {}
    for k,data in ipairs(context.campaignCutscenes) do
        matchState.campaignCutscenes[k] = data
    end
    print("set up campaignCutscenes")
    matchState.mapFlags = {} --only string keys are allowed for this json library
    for k,flag in ipairs(context.mapFlags) do
        matchState.mapFlags[k] = flag
    end
    print("set up mapFlags")
    matchState.triggersFired = {}
    for k,flag in pairs(context.fired) do
        matchState.triggersFired[k] = flag
    end
    print("set up triggersFired")
    matchState.campaignFlags = {}
    for k,flag in ipairs(context.campaignFlags) do
        matchState.campaignFlags[k] = flag
    end
    print("set up campaignFlags")
    matchState.party = {}
    for k,member in ipairs(context.party) do
        matchState.party[k] = member
    end
    print("set up party")
    return matchState
end

function CheckpointManager.updateCheckpointBuffer(context)
    if context:checkState("startOfTurn") and Wargroove.getCurrentPlayerId() == 0 then
        print("Updating buffer")
        print("context:")
        print(dump(context,0))
        local matchState = CheckpointManager.extractMatchState(context)
        print("matchState:")
        print(dump(matchState,0))
        local checkpointData = CheckpointManager.setupCheckpointData(matchState)
        CheckpointManager.setCheckpointWithId(matchState, "-tmp", checkpointData)
    end
end
function CheckpointManager.getCheckpointDataFromStartOfRound()
        return CheckpointManager.getCheckpointDataWithId("-tmp")
end


local mapSeed
function CheckpointManager.setMapSeed(newMapSeed)
    mapSeed = newMapSeed
end
function CheckpointManager.getMapSeed()
    return mapSeed
end


function CheckpointManager.clearCheckpoint(id)
    if id==nil then
        id=""
    end
    local file = io.open(tostring(CheckpointManager.getMapSeed())..id..".save", "w+")
    if file == nil then
        Wargroove.showMessage("Failed to clear checkpoint "..tostring(CheckpointManager.getMapSeed())..id..".save. Access Denied.")
        return
    end
    file:flush()
    file:close()
end

function CheckpointManager.setCheckpointWithId(matchState, id, checkpointData)
    if id==nil then
        id=""
    end
    --Wargroove.showMessage("setting checkpoint with id: "..tostring(CheckpointManager.getMapSeed()..id))
    local file = io.open(tostring(CheckpointManager.getMapSeed())..id..".save", "w+")
    if file == nil then
        Wargroove.showMessage("Failed to load checkpoint "..tostring(CheckpointManager.getMapSeed())..id..".save. Access Denied.")
        return
    end
    if checkpointData == nil then
        checkpointData = CheckpointManager.getCheckpointDataFromStartOfRound()
    end
    if checkpointData == nil then
        checkpointData = CheckpointManager.setupCheckpointData(matchState)
    end
    local status, err = pcall(function() file:write(json.encode(checkpointData)) end)

    if not status then
      Wargroove.showMessage(err.code)
      print(err.code)
    end
    file:flush()
    file:close()
    
    Wargroove.runGC(false)
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

function CheckpointManager.setupCheckpointData(matchState)
    print("Setting up checkpoint data")
    local units = Wargroove.getUnitsAtLocation()
    local unitTable = {}
    print("Setting up unit checkpoint data")
    for k,unit in ipairs(units) do
        local serializableUnit = {}
        serializableUnit.loadedUnits = {}
        for k,unitId in pairs(unit.loadedUnits) do
            serializableUnit.loadedUnits[tostring(k)] = unitId
        end
        serializableUnit.merchantDiscountMultiplier = unit.merchantDiscountMultiplier
        serializableUnit.attackerId = unit.attackerId
        serializableUnit.attackerUnitClass = unit.attackerUnitClass
        serializableUnit.rangedDamageTakenPercent = unit.rangedDamageTakenPercent
        serializableUnit.itemId = unit.itemId
        serializableUnit.playerId = unit.playerId
        serializableUnit.recruitDiscountMultiplier = unit.recruitDiscountMultiplier
        serializableUnit.health = unit.health
        serializableUnit.inTransport = unit.inTransport
        serializableUnit.canBeAttacked = unit.canBeAttacked
        serializableUnit.transportedBy = unit.transportedBy
        serializableUnit.canBeAttackedFromDistance = unit.canBeAttackedFromDistance
        serializableUnit.pos = {x = unit.pos.x, y = unit.pos.y, facing = unit.pos.facing}
        serializableUnit.hasBeenKilled = unit.hasBeenKilled
        serializableUnit.stunned = unit.stunned
        serializableUnit.tentacled = unit.tentacled
        serializableUnit.underwater = unit.underwater
        serializableUnit.canChargeGroove = unit.canChargeGroove
        serializableUnit.state = {}
        for k,state in pairs(unit.state) do
            serializableUnit.state[k] = state
        end
        serializableUnit.factionOverride = unit.factionOverride
        serializableUnit.startPos = {x = unit.startPos.x, y = unit.startPos.y, facing = unit.startPos.facing}
        serializableUnit.id = unit.id
        serializableUnit.damageTakenPercent = unit.damageTakenPercent
        serializableUnit.hadTurn = unit.hadTurn
        serializableUnit.killedByLosing = unit.killedByLosing
        serializableUnit.grooveCharge = unit.grooveCharge
        serializableUnit.unitClassId = unit.unitClassId
        serializableUnit.attackerPlayerId = unit.attackerPlayerId
        table.insert(unitTable,serializableUnit)
    end
    print("Setting up location checkpoint data")
    local locationTable = {}
    for locationId = 0,255 do
        local location = Wargroove.getLocationById(locationId)
        if location~=nil and location.name~=nil and location.name~="" then
            print(locationId)
            location.getArea = nil
            location.setArea = nil
            locationTable[tostring(locationId)] = location
        end
    end
    local items = Wargroove.getMapItemsAtLocation()
    local serializableItems = {}
    for k,item in pairs(items) do
        serializableItems[tostring(item.itemId)] = item
    end
    local newMatchState = {}
    newMatchState.mapCounters = {}
    for k,data in ipairs(matchState.mapCounters) do
        newMatchState.mapCounters[tostring(k)] = data
    end
    print("setup matchState.mapCounters")
    newMatchState.creditsToPlay = matchState.creditsToPlay
    print("setup matchState.creditsToPlay")
    newMatchState.campaignCutscenes = {}
    for k,data in ipairs(matchState.campaignCutscenes) do
        newMatchState.campaignCutscenes[tostring(k)] = data
    end
    print("setup matchState.campaignCutscenes")
    newMatchState.mapFlags = {} --only string keys are allowed for this json library
    for k,flag in ipairs(matchState.mapFlags) do
        newMatchState.mapFlags[tostring(k)] = flag
    end
    print("setup matchState.mapFlags")
    newMatchState.triggersFired = {}
    for k,flag in pairs(matchState.triggersFired) do
        newMatchState.triggersFired[tostring(k)] = flag
    end
    print("setup matchState.triggersFired")
    

    print("Returning setup checkpoint data")
    return {matchState = newMatchState, turnNumber = Wargroove.getTurnNumber(), units = unitTable, locationTable = locationTable, items = serializableItems}
end

local function tobool(string)
    local result = nil
    if (string~=nil) then
        if string == "true" then
            result = true
        else
            result = false
        end
    end
    return result
end
function CheckpointManager.loadLocationObject(locationObject)
	local locationId = tonumber(Wargroove.getUnitState(locationObject,"locationId"))
	local highlightId = Wargroove.getUnitState(locationObject,"highlightId")
	local colour = Wargroove.getUnitState(locationObject,"colour")
	local hideOnSelection = tobool(Wargroove.getUnitState(locationObject,"hideOnSelection"))
	local hideOnAction = tobool(Wargroove.getUnitState(locationObject,"hideOnAction"))
	local showOnUnitSelection = tobool(Wargroove.getUnitState(locationObject,"showOnUnitSelection"))
	local showOnEndPosSelection = tobool(Wargroove.getUnitState(locationObject,"showOnEndPosSelection"))
	local showOnActionSelected = tobool(Wargroove.getUnitState(locationObject,"showOnActionSelected"))
    if highlightId~=nil and colour~=nil and hideOnSelection~=nil and hideOnAction~=nil and showOnUnitSelection~=nil and showOnEndPosSelection~=nil and showOnActionSelected~=nil then
	    Wargroove.highlightLocation(locationId, highlightId, colour, hideOnSelection, hideOnAction, showOnUnitSelection, showOnEndPosSelection, showOnActionSelected)
    end
    
	local isAIObstacle = tobool(Wargroove.getUnitState(locationObject,"isAIObstacle"))
	local isObstacle = tobool(Wargroove.getUnitState(locationObject,"isObstacle"))
	local isInteractable = tobool(Wargroove.getUnitState(locationObject,"isInteractable"))
    if isAIObstacle~=nil and isObstacle~=nil and isInteractable~=nil then
	    Wargroove.setLocationProperties(locationId, isAIObstacle, isObstacle, isInteractable)
    end

    for playerId = 0,7 do
	    local isVisible = tobool(Wargroove.getUnitState(locationObject,"player"..playerId.."visible"))
        if isVisible~=nil then
	        Wargroove.revealFogOfWar(playerId, locationId, isVisible)
        else
            Wargroove.revealFogOfWar(playerId, locationId, false)
        end
    end
	local isVisible = tobool(Wargroove.getUnitState(locationObject,"playerAnyVisible"))
    if isVisible~=nil then
        Wargroove.revealFogOfWar(nil, locationId, isVisible)
    else
        Wargroove.revealFogOfWar(nil, locationId, false)
    end
end

function CheckpointManager.loadGlobalObject(globalObject)
    print("CheckpointManager.loadGlobalObject(globalObject)")
	local weather = Wargroove.getUnitState(globalObject,"weather")
    if weather~=nil then
        print("weather: "..weather)
	    Wargroove.setWeather(weather, 0)
	    Wargroove.setWeather(weather, 1)
    end

    for playerId = 0,7 do
	    local AIProfile = Wargroove.getUnitState(globalObject,"player"..playerId.."AIProfile")
        if AIProfile~=nil then
	        Wargroove.setAIProfile(playerId, AIProfile)
        end
    end

	local dayTime = Wargroove.getUnitState(globalObject,"dayTime")
    if dayTime~=nil then
        print("dayTime: "..dayTime)
	    Wargroove.setDaytime(dayTime)
    end

	local music = Wargroove.getUnitState(globalObject,"music")
	local intensity = Wargroove.getUnitState(globalObject,"musicIntensity")
    if music~=nil and intensity~=nil then
        print("music: "..music)
        print("intensity: "..intensity)
	    Wargroove.setMapMusic(music, intensity)
    end
end

function CheckpointManager.getCheckpointDataWithId(id)
    if id == nil then
        id=""
    end
    --Wargroove.showMessage("Getting checkpoint data with id: "..tostring(CheckpointManager.getMapSeed())..id)
    print("Opening...")
    local file = io.open(tostring(CheckpointManager.getMapSeed())..id..".save", "r")
    if file == nil then
        Wargroove.showMessage("Failed to load checkpoint "..tostring(CheckpointManager.getMapSeed())..id..".save. Access Denied.")
        return -1
    end
    print("Open!")
    local rawdata = file:read("*a") 
    file:flush()
    file:close()
    print("Loaded!")
    return json.decode(rawdata)
end

function CheckpointManager.loadCheckpointWithId(id)
    local data = CheckpointManager.getCheckpointDataWithId(id)
    print("loading checkpoint data")
    print(dump(data,0))
    return CheckpointManager.loadCheckpoint(data)
end

function CheckpointManager.loadCheckpoint(checkpointData)
    print("CheckpointManager.loadCheckpoint(checkpointData)")
    Wargroove.setTurnZero(checkpointData.turnNumber-1)
    local unitIds = Wargroove.getAllUnitIds()
    for k, v in pairs(unitIds) do
        Wargroove.removeUnit(v)
    end
    Wargroove.clearCaches()
    Wargroove.waitFrame()
    Wargroove.clearCaches()
    local maxId = -1
    local indexedUnits = {}
    local spawnedUnits = {}
    local unitsInsideTransports = {}
    for k, unit in pairs(checkpointData.units) do
        if maxId<unit.id then
            maxId = unit.id
        end
        indexedUnits[unit.id] = unit
    end
    local globalObjectUnit = nil
    for unitId, unit in pairs(indexedUnits) do
        local spawnedUnitId = -1
        if unit ~= nil then
            if unit.inTransport then
                table.insert(unitsInsideTransports,unit)
            else
                spawnedUnitId = Wargroove.spawnUnit(unit.playerId,unit.pos,unit.unitClassId,unit.hadTurn,nil,unit.state,unit.factionOverride)
            end
        else
            spawnedUnitId = Wargroove.spawnUnit(-1,{x = -100,y=-100},"soldier",false)
        end
        if spawnedUnitId ~= -1 then
            Wargroove.clearCaches()
            local spawnedUnit = Wargroove.getUnitById(spawnedUnitId)
            spawnedUnits[unitId] = spawnedUnit;
        end
    end
    for unitId, unit in pairs(unitsInsideTransports) do

    end

    for unitId, spawnedUnit in pairs(spawnedUnits) do
        
            local unit = Wargroove.getUnitById(unitId)
            spawnedUnit.loadedUnits = {}
            for k,unit in pairs(unit.loadedUnits) do
                spawnedUnit.loadedUnits[tonumber(k)] = unit
            end
            spawnedUnit.merchantDiscountMultiplier = unit.merchantDiscountMultiplier
            spawnedUnit.attackerUnitClass = unit.attackerUnitClass
            spawnedUnit.rangedDamageTakenPercent = unit.rangedDamageTakenPercent
            if unit.itemId ~= nil and unit.itemId~="" then
                Wargroove.equipItem(spawnedUnit, unit.itemId)
            end
            spawnedUnit.playerId = unit.playerId
            spawnedUnit.recruitDiscountMultiplier = unit.recruitDiscountMultiplier
            spawnedUnit.health = unit.health
            spawnedUnit.inTransport = unit.inTransport
            spawnedUnit.canBeAttacked = unit.canBeAttacked
            spawnedUnit.transportedBy = unit.transportedBy
            spawnedUnit.canBeAttackedFromDistance = unit.canBeAttackedFromDistance
            spawnedUnit.pos = {x = unit.pos.x, y = unit.pos.y, facing = unit.pos.facing}
            spawnedUnit.hasBeenKilled = unit.hasBeenKilled
            spawnedUnit.stunned = unit.stunned
            spawnedUnit.tentacled = unit.tentacled
            spawnedUnit.underwater = unit.underwater
            spawnedUnit.canChargeGroove = unit.canChargeGroove
            spawnedUnit.factionOverride = unit.factionOverride
            spawnedUnit.startPos = {x = unit.startPos.x, y = unit.startPos.y, facing = unit.startPos.facing}
            spawnedUnit.damageTakenPercent = unit.damageTakenPercent
            spawnedUnit.hadTurn = unit.hadTurn
            spawnedUnit.killedByLosing = unit.killedByLosing
            spawnedUnit.grooveCharge = unit.grooveCharge
            spawnedUnit.attackerPlayerId = unit.attackerPlayerId
            spawnedUnit.unitClassId = unit.unitClassId
            if spawnedUnit.unitClassId == "location_object" then
                CheckpointManager.loadLocationObject(spawnedUnit)
            end
            if spawnedUnit.unitClassId == "global_object" then
                globalObjectUnit = spawnedUnit
            end
            if unit.unitClassId == "outpost" then
                print("bugged outpost")
                print("unit")
                print(dump(unit,0))
                print("spawnedUnit")
                print(dump(spawnedUnit,0))
            end
    end
    for unitId, spawnedUnit in pairs(spawnedUnits) do
        print("setting unit id's stored in unit ".. unitId)
        print("original attacker: ".. indexedUnits[unitId].attackerId)
        if spawnedUnits[indexedUnits[unitId].attackerId] ~= nil then
            spawnedUnit.attackerId = spawnedUnits[indexedUnits[unitId].attackerId].id
        else
            spawnedUnit.attackerId = -1
        end
        print("new attacker: ".. spawnedUnit.attackerId)
        spawnedUnit.state = {}
        for name,state in pairs(indexedUnits[unitId].state) do
            if name == "unitId" or name == "targetId" or name == "hiddenId" or name == "parentId" then
                local newUnit = spawnedUnits[tonumber(state)]
                if newUnit ~= nil then
                    spawnedUnit.state[name] = tostring(spawnedUnits[tonumber(state)].id)
                else
                    spawnedUnit.state[name] = nil
                end
                goto next
            end
            spawnedUnit.state[name] = state
            ::next::
        end
        spawnedUnit.loadedUnits = {}
        for id,loadedUnit in pairs(indexedUnits[unitId].loadedUnits) do
            spawnedUnit.loadedUnits[tonumber(id)] = spawnedUnits[tonumber(loadedUnit)].id
        end
        if spawnedUnits[indexedUnits[unitId].transportedBy] ~= nil then
            spawnedUnit.transportedBy = spawnedUnits[indexedUnits[unitId].transportedBy].id
        else
            spawnedUnit.transportedBy = -1
        end
    end
    if globalObjectUnit~= nil then
        CheckpointManager.loadGlobalObject(globalObjectUnit)
    end
    print("spawned units")
    print(dump(spawnedUnits,0))
    Wargroove.updateUnits(spawnedUnits)
    print("Deleting items...")
    local items = Wargroove.getMapItemsAtLocation()
    for k,item in pairs(items) do
        Wargroove.consumeItemAt(item.pos)
    end
    print("Items Deleted ")
    Wargroove.clearCaches()
    print("Spawning items...")
    for k,item in pairs(checkpointData.items) do
        Wargroove.spawnItemAt(item.type,item.pos)
    end
    print("Items Spawned ")
    Wargroove.clearCaches()

    Wargroove.updateFogOfWar()

    Wargroove.runGC(false)
    print("loading map flags...")
    for k,flag in ipairs(checkpointData.matchState.mapFlags) do
        checkpointData.matchState.mapFlags[tonumber(k)] = flag
        checkpointData.matchState.mapFlags[k] = nil
    end
    for k,counter in ipairs(checkpointData.matchState.mapCounters) do
        checkpointData.matchState.mapCounters[tonumber(k)] = counter
        checkpointData.matchState.mapCounters[k] = nil
    end
    for k,cutscene in ipairs(checkpointData.matchState.campaignCutscenes) do
        checkpointData.matchState.campaignCutscenes[tonumber(k)] = cutscene
        checkpointData.matchState.campaignCutscenes[k] = nil
    end
    print("Map flags loaded!")
    Wargroove.waitFrame()
    local units = Wargroove.getUnitsAtLocation()
    print("loaded units")
    print(dump(units,0))
    return checkpointData.matchState
end

local checkedForCheckpoint = false

function CheckpointManager.checkedForCheckpoint()
    return checkedForCheckpoint
end

local function file_exists(name)
    local file = io.open(name, "r")
    if file == nil then
        return false
    end
    io.close(file)
    return true
end

function CheckpointManager.checkpointExistsWithId(id)
    if id == nil then
        id = ""
    end
    local file = io.open(tostring(CheckpointManager.getMapSeed())..id..".save", "r")
    if file == nil then
        return false
    end
    local data = file:read()
    if data == nil then
        io.close(file)
        return false
    end
    if data == "" then
        io.close(file)
        return false
    end
    io.close(file)
    return true
end

local mapWasPlayedBefore = false
local wasInitMapWasPlayedBefore = false
function CheckpointManager.initMapWasPlayedBefore()
    if not wasInitMapWasPlayedBefore then
        mapWasPlayedBefore = file_exists(tostring(CheckpointManager.getMapSeed()).."-tmp"..".save")
        if mapWasPlayedBefore then
            print("This map was played before")
            print(tostring(CheckpointManager.getMapSeed()).."-tmp"..".save")
        else
            print("This map was NOT played before")
            print(tostring(CheckpointManager.getMapSeed()).."-tmp"..".save")
        end
        wasInitMapWasPlayedBefore = true
    end
end
function CheckpointManager.mapWasPlayedBefore()
    return mapWasPlayedBefore
end

local function calculateAveragePosOwnedByPlayer(playerId)
    print("calculateAveragePos(units)")
    local units = Wargroove.getUnitsAtLocation()
    local totalX = 0
    local totalY = 0
    local count = 0
    for k, unit in pairs(units) do
        if Wargroove.areAllies(unit.playerId,playerId) and unit.pos.x>=0 and unit.pos.y>=0 then
            print("unit.pos.x: "..unit.pos.x)
            totalX = totalX + unit.pos.x
            print("unit.pos.y: "..unit.pos.y)
            totalY = totalY + unit.pos.y
            count = count + 1
        end
    end
    if count>0 then
        local averagePos = {x = totalX/count, y = totalY/count}
        print("averagePos: "..averagePos.x..","..averagePos.y)
        return averagePos
    else
        local mapSize = Wargroove.getMapSize()
        return {x = mapSize.x/2, y = mapSize.y/2}
    end
end

function CheckpointManager.checkCheckpoint(matchState)
    local newMatchState = nil
    if not checkedForCheckpoint then
        checkedForCheckpoint = true
        if CheckpointManager.checkpointExistsWithId() then
            print("checkpoint found!")
            local preCheckpointData = CheckpointManager.setupCheckpointData(matchState)
            print("setup checkpoint data")
            newMatchState = CheckpointManager.loadCheckpointWithId()
            print("loaded checkpoint")
            local averagePos = calculateAveragePosOwnedByPlayer(0)
            averagePos = {x = math.floor(averagePos.x+0.5), y = math.floor(averagePos.y+0.5+1)}
            print("rounded averagePos: "..averagePos.x..","..averagePos.y)
            Wargroove.trackCameraTo(averagePos,true)
            Wargroove.showDialogueBox("happy", "generic_codex", "Continue from this checkpoint?", "", { "Yes", "No" }, "standard", true, "Preview", "black")
            if Wargroove.getSelectedDecision() == 1 then
                CheckpointManager.clearCheckpoint()
                Wargroove.fadeStage("out", 0.4, false)
                Wargroove.waitTime(0.5)
                newMatchState = CheckpointManager.loadCheckpoint(preCheckpointData)
                Wargroove.fullClearCache()
                Wargroove.fadeStage("in", 0.4, false)
                Wargroove.waitTime(0.4)
                CheckpointManager.clearCheckpoint()

                WargrooveExtra.skipIntroOveride(false)

                checkpointLoaded = false
            else
                checkpointLoaded = true
            end
        end
        if not checkpointLoaded and CheckpointManager.mapWasPlayedBefore() and not Wargroove.areIntroEventsSkippable() then
            local averagePos = calculateAveragePosOwnedByPlayer(0)
            averagePos = {x = math.floor(averagePos.x+0.5), y = math.floor(averagePos.y+0.5+1)}
            Wargroove.trackCameraTo(averagePos,true)
            Wargroove.showDialogueBox("happy", "generic_codex", "Skip intro?", "", { "Yes", "No" }, "standard", true, nil, "black")
            if Wargroove.getSelectedDecision() == 0 then
                WargrooveExtra.skipIntroOveride(true)
            end
        end
        if not CheckpointManager.mapWasPlayedBefore() then
            CheckpointManager.clearCheckpoint()
        end
        print("Done checking checkpoint.")
    end
    return newMatchState
end

return CheckpointManager