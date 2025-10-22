
local Wargroove = require("wargroove/wargroove")
local WargrooveExtra = require("initialized/wargroove_extra")
local Ragnarok = require("initialized/ragnarok")
local json = require("util/json")
local io = require("io")
local TriggerContext = require("triggers/trigger_context")
local CheckpointManager = {}
local checkpointLoaded = false
function CheckpointManager.init()
end
function CheckpointManager.isCheckpointLoaded()
    return false
end
function CheckpointManager.setupCheckpointFile(context)
end
function CheckpointManager.updateCheckpointBuffer(context)
end
function CheckpointManager.getCheckpointDataFromStartOfRound()
    return {triggerContext = {}, turnNumber = 0, units = {}, locationTable = {}, items = {}}
end


local mapSeed
function CheckpointManager.setMapSeed(newMapSeed)
    mapSeed = newMapSeed
end
function CheckpointManager.getMapSeed()
    return mapSeed
end


function CheckpointManager.clearCheckpoint(id)
end

function CheckpointManager.setCheckpointWithId(id, checkpointData)
end

function CheckpointManager.setupCheckpointData()
    return {triggerContext = {}, turnNumber = 0, units = {}, locationTable = {}, items = {}}
end

function CheckpointManager.loadLocationObject(locationObject)
end

function CheckpointManager.loadGlobalObject(globalObject)
end

function CheckpointManager.getCheckpointDataWithId(id)
end

function CheckpointManager.loadCheckpointWithId(id)
end
function CheckpointManager.loadCheckpoint(checkpointData)
    return 0
end

local checkedForCheckpoint = false

local function file_exists(name)
    return false
end

function CheckpointManager.checkpointExistsWithId(id)
    return false
end

function CheckpointManager.checkCheckpoint()
end

return CheckpointManager