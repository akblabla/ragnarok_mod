
local Wargroove = require("wargroove/wargroove")
local WargrooveExtra = require("initialized/wargroove_extra")
local Ragnarok = require("initialized/ragnarok")
local json = require("util/json")
local io = require("io")
local TriggerContext = require("triggers/trigger_context")
local CheckpointManager = {}
local checkpointLoaded = false
function CheckpointManager.init()
    Ragnarok.addAction(CheckpointManager.updateCheckpointBuffer,"repeating",true)
    Ragnarok.addAction(CheckpointManager.setupCheckpointFile,"start_of_match",true)
end
function CheckpointManager.isCheckpointLoaded()
    return checkpointLoaded
end
function CheckpointManager.setupCheckpointFile(context)
    CheckpointManager.clearCheckpoint()
end
function CheckpointManager.updateCheckpointBuffer(context)
    if context:checkState("startOfTurn") and Wargroove.getCurrentPlayerId() == 0 then
        local checkpointData = CheckpointManager.setupCheckpointData()
        CheckpointManager.setCheckpointWithId("-tmp", checkpointData)
    end
end
function CheckpointManager.getCheckpointDataFromStartOfRound()
        local checkpointData = CheckpointManager.getCheckpointDataWithId("-tmp")
        if checkpointData ~= nil then
            return checkpointData
        else
            return CheckpointManager.setupCheckpointData()
        end

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
        Wargroove.showMessage("Failed to clear checkpoint. Access Denied.")
        return
    end
    file:flush()
    file:close()
end

function CheckpointManager.setCheckpointWithId(id, checkpointData)
    if id==nil then
        id=""
    end
    --Wargroove.showMessage("setting checkpoint with id: "..tostring(CheckpointManager.getMapSeed()..id))
    local file = io.open(tostring(CheckpointManager.getMapSeed())..id..".save", "w+")
    if file == nil then
        Wargroove.showMessage("Failed to load checkpoint. Access Denied.")
        return
    end
    if checkpointData == nil then
        checkpointData = CheckpointManager.getCheckpointDataFromStartOfRound()
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

function CheckpointManager.setupCheckpointData()
    local units = Wargroove.getUnitsAtLocation()
    local unitTable = {}
    for k,unit in ipairs(units) do
        local serializableUnit = {}
        serializableUnit.loadedUnits = {}
        for k,unit in pairs(unit.loadedUnits) do
            serializableUnit.loadedUnits[k] = unit
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
    return {triggerContext = triggerContext, turnNumber = Wargroove.getTurnNumber(), units = unitTable, locationTable = locationTable, items = serializableItems}
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
        Wargroove.showMessage("Failed to save checkpoint. Access Denied.")
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
    CheckpointManager.loadCheckpoint(data)
end
function CheckpointManager.loadCheckpoint(checkpointData)
    print("CheckpointManager.loadCheckpoint(checkpointData)")
    --triggerContext = TriggerContext:new(checkpointData.triggerContext)
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
    local toBeRemoved = {}
    for k, unit in pairs(checkpointData.units) do
        if maxId<unit.id then
            maxId = unit.id
        end
        indexedUnits[unit.id] = unit
    end
    unitIds = Wargroove.getAllUnitIds()

    print("unitIds left after removing them all. This should be empty")
    print(dump(unitIds,0))
    print("Units to spawn")
    print(dump(indexedUnits,0))
    local currentId = 1
    while currentId<=maxId do
        local unit = indexedUnits[currentId]
        local spawnedUnitId = -1
        if unit ~= nil then
            spawnedUnitId = Wargroove.spawnUnit(unit.playerId,unit.pos,unit.unitClassId,unit.hadTurn,nil,unit.state,unit.factionOverride)
        else
            spawnedUnitId = Wargroove.spawnUnit(-1,{x = -100,y=-100},"soldier",false)
        end
        print("spawned unit ID ".. spawnedUnitId)
        print("expected unit ID ".. currentId)
        if (spawnedUnitId ~= currentId) then
            Wargroove.showMessage("Loading checkpoint failed.")
            Wargroove.showMessage("spawned unit ID ".. spawnedUnitId.." ~= ".."expected unit ID ".. currentId)
            Wargroove.clearCaches()
            Wargroove.removeUnit(spawnedUnitId)
            Wargroove.clearCaches()
            if unit ~= nil then
                spawnedUnitId = Wargroove.spawnUnit(unit.playerId,unit.pos,unit.unitClassId,unit.hadTurn,nil,unit.state,unit.factionOverride)
            else
                spawnedUnitId = Wargroove.spawnUnit(-1,{x = -100,y=-100},"soldier",false)
            end
            --break;
        end
        --unit = indexedUnits[spawnedUnitId]
        Wargroove.clearCaches()
        if unit ~= nil then
            local spawnedUnit = Wargroove.getUnitById(spawnedUnitId)
            spawnedUnit.loadedUnits = {}
            for k,unit in pairs(unit.loadedUnits) do
                spawnedUnit.loadedUnits[k] = unit
            end
            spawnedUnit.merchantDiscountMultiplier = unit.merchantDiscountMultiplier
            spawnedUnit.attackerId = unit.attackerId
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
            spawnedUnit.state = {}
            for k,state in pairs(unit.state) do
                spawnedUnit.state[k] = state
            end
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
                CheckpointManager.loadGlobalObject(spawnedUnit)
            end
            spawnedUnits[currentId] = spawnedUnit;
        else
            table.insert(toBeRemoved,spawnedUnitId)
        end
        currentId = currentId +1;
    end
    Wargroove.updateUnits(spawnedUnits)
    print("Removing extra units...")
    for k,id in ipairs(toBeRemoved) do
        local unit = indexedUnits[id]
        print("id to remove: ".. id)
        if unit == nil then
            Wargroove.removeUnit(id)
            print("id ".. id.. " removed")
        end
    end
    print("Extra units removed")
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
    unitIds = Wargroove.getAllUnitIds()

    print("unitIds after loading")
    print(dump(unitIds,0))
    Wargroove.runGC(false)
    return 0
end

local checkedForCheckpoint = false

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

local function calculateAveragePosOwnedByPlayer(playerId)
    print("calculateAveragePos(units)")
    local units = Wargroove.getUnitsAtLocation()
    local totalX = 0
    local totalY = 0
    local count = 0
    for k, unit in pairs(units) do
        if Wargroove.areAllies(unit.playerId,playerId) then
            print("unit.pos.x: "..unit.pos.x)
            totalX = totalX + unit.pos.x
            print("unit.pos.y: "..unit.pos.y)
            totalY = totalY + unit.pos.y
            count = count + 1
        end
    end
    if count>0 then
        local averagePos = {x = totalX/count, y = totalX/count}
        print("averagePos: "..averagePos.x..","..averagePos.y)
        return averagePos
    else
        local mapSize = Wargroove.getMapSize()
        return {x = mapSize.x/2, y = mapSize.y/2}
    end
end

function CheckpointManager.checkCheckpoint()
    if not checkedForCheckpoint then
        checkedForCheckpoint = true
        if CheckpointManager.checkpointExistsWithId() then
            local preCheckpointData = CheckpointManager.setupCheckpointData()
            CheckpointManager.loadCheckpointWithId()
            local averagePos = calculateAveragePosOwnedByPlayer(0)
            averagePos = {x = math.floor(averagePos.x+0.5), y = math.floor(averagePos.y+0.5)}
            print("rounded averagePos: "..averagePos.x..","..averagePos.y)
            Wargroove.trackCameraTo(averagePos,true)
            Wargroove.showDialogueBox("happy", "generic_codex", "Continue from this checkpoint?", "", { "Yes", "No" }, "standard", true, "Preview", "black")
            if Wargroove.getSelectedDecision() == 1 then
                CheckpointManager.clearCheckpoint()
                Wargroove.fadeStage("out", 0.4, false)
                Wargroove.waitTime(0.5)
                CheckpointManager.loadCheckpoint(preCheckpointData)
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
        if not checkpointLoaded and file_exists(tostring(CheckpointManager.getMapSeed())..".save") and not Wargroove.areIntroEventsSkippable() then
            local averagePos = calculateAveragePosOwnedByPlayer(0)
            averagePos = {x = math.floor(averagePos.x+0.5), y = math.floor(averagePos.y+0.5)}
            Wargroove.trackCameraTo(averagePos,true)
            Wargroove.showDialogueBox("happy", "generic_codex", "Skip intro?", "", { "Yes", "No" }, "standard", true, nil, "black")
            if Wargroove.getSelectedDecision() == 0 then
                WargrooveExtra.skipIntroOveride(true)
            end
        end
        print("Done checking checkpoint.")
    end
end

return CheckpointManager