local Wargroove = require "wargroove/wargroove"
local ItemOnPickup = require "wargroove/item_on_pickup"
local Actions = {}

function Actions.populate(dst)
    dst["set_map_flag"] = Actions.setMapFlag
    dst["toggle_map_flag"] = Actions.toggleMapFlag
    dst["set_campaign_flag"] = Actions.setCampaignFlag
    dst["set_party_member"] = Actions.setPartyMember
    dst["modify_counter"] = Actions.modifyCounter
    dst["add_campaign_cutscene"] = Actions.addCampaignCutscene
    dst["spawn_unit"] = Actions.spawnUnit
    dst["drop_unit"] = Actions.dropUnit
    dst["remove_units"] = Actions.removeUnits
    dst["modify_gold"] = Actions.modifyGold
    dst["modify_health"] = Actions.modifyHealth
    dst["modify_groove"] = Actions.modifyGroove
    dst["victory"] = Actions.victory
    dst["eliminate"] = Actions.eliminate
    dst["convert"] = Actions.convert
    dst["change_unit_type"] = Actions.changeUnitType
    dst["reveal_fow"] = Actions.revealFoW
    dst["change_team"] = Actions.changeTeam
    dst["message"] = Actions.message
    dst["dialogue_box"] = Actions.dialogueBox
    dst["dialogue_box_simple"] = Actions.dialogueBoxSimple
    dst["dialogue_box_decision"] = Actions.dialogueBoxDecision
    dst["tutorial_box"] = Actions.tutorialBox
    dst["tutorial_box_new"] = Actions.tutorialBoxNew
    dst["wait"] = Actions.wait
    dst["centre_camera"] = Actions.centreCamera
    dst["ai_set_profile"] = Actions.aiSetProfile
    dst["set_weather"] = Actions.setWeather
    dst["ai_set_restriction"] = Actions.aiSetRestriction
    dst["set_unit_spent"] = Actions.setUnitSpent
    dst["play_cutscene"] = Actions.playCutscene
    dst["set_location_highlight"] = Actions.setLocationHighlight
    dst["set_conditional_location_highlight"] = Actions.setConditionalLocationHighlight
    dst["force_open_ui_tutorial"] = Actions.forceOpenUITutorial
    dst["force_action"] = Actions.forceAction
    dst["queue_force_action"] = Actions.queueForceAction
    dst["queue_force_open_ui_tutorial"] = Actions.queueForceOpenUITutorial
    dst["add_ui_tutorial"] = Actions.addUITutorial
    dst["play_credits"] = Actions.playCredits
    dst["set_match_seed"] = Actions.setMatchSeed
    dst["update_fog_of_war"] = Actions.updateFogOfWar
    dst["change_objective"] = Actions.changeObjective
    dst["show_objective"] = Actions.showObjective
    dst["move_location_to_unit"] = Actions.moveLocationToUnit
    dst["move_location_to_location"] = Actions.moveLocationToLocation
    dst["set_map_music"] = Actions.setMapMusic
    dst["play_groove_cutscene"] = Actions.playGrooveCutscene
    dst["play_sound_effect"] = Actions.playSoundEffect
    dst["set_gizmo_state"] = Actions.setGizmoState
    dst["toggle_gizmo_state"] = Actions.toggleGizmoState
    dst["set_damage_taken"] = Actions.setDamageTaken
    dst["counter_arithmetics"] = Actions.counterArithmetics
    dst["counter_random"] = Actions.counterRandom
    dst["location_copy"] = Actions.locationCopy
    dst["location_boolean_operation"] = Actions.locationBooleanOperation
    dst["location_move"] = Actions.locationMove
    dst["unit_teleport"] = Actions.unitTeleport
    dst["count_units"] = Actions.countUnits
    dst["transfer_health"] = Actions.transferHealth
    dst["transfer_groove"] = Actions.transferGroove
    dst["transfer_gold"] = Actions.transferGold
    dst["transfer_gizmo_state"] = Actions.transferGizmoState
    dst["activate_flood"] = Actions.activateFlood
    dst["spawn_item"] = Actions.spawnItem
    dst["unit_action"] = Actions.unitAction
    dst["skip_actions"] = Actions.skipActions
    dst["spawn_animation"] = Actions.spawnAnimation
    dst["spawn_unit_inside"] = Actions.spawnUnitInside
    dst["bonus_objective"] = Actions.bonusObjective
    dst["fail_bonus_objective"] = Actions.failBonusObjective
    dst["set_daytime"] = Actions.setDaytime
    dst["fade_stage"] = Actions.fadeStage
    dst["set_player_skip_status"] = Actions.setPlayerSkipStatus
    dst["show_map_ui"] = Actions.showMapUI
    dst["show_interactions_menu"] = Actions.showInteractionsMenu
    dst["location_set_properties"] = Actions.setLocationProperties
    dst["select_protagonist"] = Actions.selectProtagonist
    dst["set_item"] = Actions.setItem
    dst["display_movement_grid"] = Actions.displayMovementGrid
    dst["hide_movement_grid"] = Actions.hideMovementGrid
    dst["set_protagonist"] = Actions.setProtagonist
    dst["open_codex"] = Actions.openCodex
    dst["show_constant_objective"] = Actions.showConstantObjective
    dst["hide_constant_objective"] = Actions.hideConstantObjective
    dst["update_constant_objective"] = Actions.updateConstantObjective
    dst["screenshake"] = Actions.screenshake
    dst["set_cutscene_mode"] = Actions.setCutsceneMode
    dst["play_character_introduction"] = Actions.playCharacterIntroduction
    dst["pick_blessing"] = Actions.pickBlessing
    dst["execute_blessing"] = Actions.executeBlessing
    dst["conditional_skip_actions"] = Actions.conditionalSkipActions
    dst["pick_item"] = Actions.pickItem
    dst["unit_faction_override"] = Actions.unitFactionOverride
    dst["play_shout"] = Actions.playShout
    dst["reward_crystals"] = Actions.rewardCrystals
    dst["set_player_counter"] = Actions.setPlayerCounter
    dst["get_player_counter"] = Actions.getPlayerCounter
    dst["unlock_unlock"] = Actions.unlockUnlock
    dst["unlock_achievement"] = Actions.unlockAchievement
    dst["location_box"] = Actions.locationBox
end


function Actions.setMapFlag(context)
    -- "Set Map Flag {0} to {1}"
    context:setMapFlag(0, context:getBoolean(1))
end


function Actions.toggleMapFlag(context)
    -- "Toggles Map Flag {0}"
    context:setMapFlag(0, not context:getMapFlag(0))
end


function Actions.setCampaignFlag(context)
    -- "Set Campaign Flag {0} to {1}"
    context:setCampaignFlag(0, context:getBoolean(1))
end


function Actions.setPartyMember(context)
    -- "Set {0}'s presence in party to {1}"
    context:setPartyMember(0, context:getBoolean(1))
end


function Actions.modifyCounter(context)
    -- "Counter {0}: {1} {2}"
    local curValue = context:getMapCounter(0)
    local op = context:getOperation(1)
    local value = context:getInteger(2)
    context:setMapCounter(0, op(curValue, value))
end

function Actions.addCampaignCutscene(context)
    -- "Sets the cutscene {0} to be played after the match is over on the campaign map."
    context:addCampaignCutscene(0)
end

local function findCentreOfLocation(location)
    local centre = { x = 0, y = 0 }
    for i, pos in ipairs(location.positions) do
        centre.x = centre.x + pos.x
        centre.y = centre.y + pos.y
    end
    centre.x = centre.x / #(location.positions)
    centre.y = centre.y / #(location.positions)

    return centre
end


local function findPlaceInLocation(location, unitClassId)
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
        centre = findCentreOfLocation(location)
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

function Actions.spawnUnit(context)
    -- "Spawn {5} {0} with colour variation {7} at {1} for {2} facing {8} (silent = {3}, no delay = {4}, random location = {6})."
    local unitClassId = context:getUnitClass(0)
    local location = context:getLocation(1)
    local playerId = context:getPlayerId(2)
    local silent = context:getBoolean(3)
    local noDelay = context:getBoolean(4)
    local spawnCount = context:getInteger(5)
    local randomizeLocation = context:getBoolean(6)
    local skinColour = context:getString(7)
    local facing = context:getString(8)

    Actions.doSpawnUnit(spawnCount, unitClassId, playerId, location, silent, noDelay, randomizeLocation, false, skinColour, facing)
end

function Actions.doSpawnUnit(spawnCount, unitClassId, playerId, location, silent, noDelay, randomizeLocation, drop, skinColour, facing)
    local droppedUnits = {}

    for i=1, spawnCount, 1 do
        -- Get candidates
        local candidates = findPlaceInLocation(location, unitClassId)

        -- Spawn at the best candidate
        if #candidates > 0 then
            local idx = 1
            if randomizeLocation then
                idx = Wargroove.randomInteger(tostring(i)..tostring(spawnCount), 1, #candidates)
            end
            local pos = candidates[idx].pos
            if not silent and not noDelay then
                Wargroove.trackCameraTo(pos)
            end
            
            if drop then
                local unitId = Wargroove.spawnUnit(playerId, {x=pos.x, y=-5}, unitClassId, false)
                Wargroove.clearCaches()

                Wargroove.moveUnitToOverride(unitId, pos, 0, 0, 15, "pow3In")
                table.insert(droppedUnits, {id=unitId, effectSpawned=false, endPos=pos})
            else 
                Wargroove.spawnUnit(playerId, pos, unitClassId, false, "", "", "", false, skinColour, facing or "right")
                Wargroove.clearCaches()
                if (not silent) and Wargroove.canCurrentlySeeTile(pos) then
                    Wargroove.spawnMapAnimation(pos, 0, "fx/mapeditor_unitdrop")
                    
                    if not noDelay then
                        Wargroove.playMapSound("spawn", pos)
                        Wargroove.waitTime(0.5)
                    else
                        if i==1 then
                            Wargroove.playMapSound("spawn", pos)
                        end
                    end
                end
            end
        end
    end

    if drop and #droppedUnits > 0 then
        local stillDroppping = true

        while stillDroppping do
            stillDroppping = false
            for i=1, #droppedUnits do
                if Wargroove.isLuaMoving(droppedUnits[i].id) then
                    stillDroppping = true
                elseif not droppedUnits[i].effectSpawned then
                    local unit = Wargroove.getUnitById(droppedUnits[i].id)
                    unit.pos = droppedUnits[i].endPos
                    Wargroove.updateUnit(unit)

                    Wargroove.spawnMapAnimation(unit.pos, 0, "fx/mapeditor_unitdrop")
                    Wargroove.playMapSound("spawn", unit.pos)
                    droppedUnits[i].effectSpawned = true
                end
            end
            coroutine.yield()
        end
    end
end

function Actions.dropUnit(context)
    -- "Drop {0} {1} at {2} for {3} (random location = {4})."
    local spawnCount = context:getInteger(0)
    local unitClassId = context:getUnitClass(1)
    local location = context:getLocation(2)
    local playerId = context:getPlayerId(3)
    local randomizeLocation = context:getBoolean(4)

    Actions.doSpawnUnit(spawnCount, unitClassId, playerId, location, false, noDelay, randomizeLocation, true, "undefined", "left")
end


function Actions.unitTeleport(context)
    -- "Teleport all {0} owned by {1} from {2} to {3} (silent = {4})"
    local units = context:gatherUnits(1, 0, 2)
    local target = context:getLocation(3)
    local silent = context:getBoolean(4)

    for i, unit in ipairs(units) do
        local candidates = findPlaceInLocation(target, unit.unitClassId)
        local oldPos = unit.pos
        if #candidates > 0 then
            unit.pos = candidates[1].pos
        end

        if not unit.inTransport then
            if (not silent) and Wargroove.canCurrentlySeeTile(oldPos) then
                Wargroove.spawnMapAnimation(oldPos, 0, "fx/mapeditor_unitdrop")
                Wargroove.waitFrame()
                Wargroove.setVisibleOverride(unit.id, false)
            end

            Wargroove.updateUnit(unit)

            if (not silent) then
                Wargroove.waitTime(0.2)
                Wargroove.unsetVisibleOverride(unit.id)
            end

            if (not silent) and Wargroove.canCurrentlySeeTile(unit.pos) then
                Wargroove.trackCameraTo(unit.pos)
                Wargroove.spawnMapAnimation(unit.pos, 0, "fx/mapeditor_unitdrop")
                Wargroove.playMapSound("spawn", unit.pos)
                Wargroove.waitTime(0.2)
            end
        end
    end
end


function Actions.removeUnits(context)
    -- "Remove units of type {0} at {1} for {2}. (silent = {4}, simultaneously = {3})"
    local units = context:gatherUnits(2, 0, 1)
    local simultaneously = context:getBoolean(3)
    local silently = context:getBoolean(4)

    for i, unit in ipairs(units) do
        if not simultaneously then
            Wargroove.trackCameraTo(unit.pos)
        end
        
        if Wargroove.canCurrentlySeeTile(unit.pos) and not silently then
            Wargroove.spawnMapAnimation(unit.pos, 0, "fx/mapeditor_unitdrop")

            if not simultaneously or i == 1 then
                Wargroove.playMapSound("spawn", unit.pos)
            end
        end
        Wargroove.removeUnit(unit.id)
        Wargroove.clearCaches()

        if not simultaneously then
            Wargroove.waitTime(0.2)
        end
    end
end


function Actions.modifyGold(context)
    -- "Modify Gold for {0}: {1} {2}"
    local playerId = context:getPlayerId(0)
    local operation = context:getOperation(1)
    local value = context:getInteger(2)
    local previous = Wargroove.getMoney(playerId)

    Wargroove.setMoney(playerId, operation(previous, value))
end


function Actions.modifyHealth(context)
    -- "Modify Health of {0} at {1} for {2}: {3} {4}%"
    local operation = context:getOperation(3)
    local value = context:getInteger(4)
    local units = context:gatherUnits(2, 0, 1)

    local deadUnitId = -1
    for i, unit in ipairs(units) do
        local newValue = operation(unit.health, value)
        if (newValue <= 0) then
            deadUnitId = unit.id
        end
        unit:setHealth(newValue, -1)
    end

    Wargroove.updateUnits(units)
    Wargroove.waitTime(0.2)

    if (deadUnitId >= 0) then
        Wargroove.doLuaDeathCheck(deadUnitId)
    end

    coroutine.yield()
end


function Actions.setUnitSpent(context)
    -- "Set turn spent for {0} at {1} for {2}: {3}"
    local value = context:getBoolean(3)
    local units = context:gatherUnits(2, 0, 1)

    for i, unit in ipairs(units) do
        unit.hadTurn = value
    end

    Wargroove.updateUnits(units)
end

function Actions.playCutscene(context)
    -- "Play cutscene {0}"
    Wargroove.playCutscene(context:getCutscene(0))
end

function Actions.setLocationHighlight(context)
    -- "Set highlight of location {0} to {1} with the colour {2}."

    if context:getLocation(0) == nil then
        print("Set location highlight event had no location set.")
        return
    end

    Wargroove.highlightLocation(context:getLocation(0).id, context:getLocationHighlight(1), context:getPlayerColour(2), false, false, false, false)
end

function Actions.setConditionalLocationHighlight(context)
    -- "Set highlight of location {0} to {1} with the colour {2}. Hide on selection: {3}. Show: {4}"
    local locationId = context:getLocation(0).id
    local highlight = context:getLocationHighlight(1)
    local playerColour = context:getPlayerColour(2)

    local hideOnSelection = context:getBoolean(3)

    local showOnUnitSelection = false
    local showOnEndPosSelection = false
    local showOnActionSelected = false

    local showType = context:getString(4)
    if showType == "start" then
        -- do nothing
    elseif showType == "unit_selected" then
        showOnUnitSelection = true
    elseif showType == "path_selected" then
        showOnEndPosSelection = true
    elseif showType == "action_selected" then
        showOnActionSelected = true
    end

    local hideOnAction = true
    
    Wargroove.highlightLocation(locationId, highlight, playerColour, hideOnSelection, hideOnAction, showOnUnitSelection, showOnEndPosSelection, showOnActionSelected)
end

function Actions.modifyGroove(context)
    -- "Modify Groove of {0} at {1} for {2}: {3} {4}%"
    local operation = context:getOperation(3)
    local value = context:getInteger(4)
    local units = context:gatherUnits(2, 0, 1)

    for i, unit in ipairs(units) do
        local grooveCharge = Wargroove.getGroovePercentage(unit.grooveCharge, unit)
        unit:setGroove(operation(grooveCharge, value))
    end

    Wargroove.updateUnits(units)
end


function Actions.victory(context)
    -- "Give victory to {0}"
    Wargroove.giveVictory(context:getPlayerId(0))
end


function Actions.eliminate(context)
    -- "Eliminate {0}"
    Wargroove.eliminate(context:getPlayerId(0))
end


function Actions.convert(context)
    -- "Convert {0} from {1} at {2} to {3}"
    local targetPlayer = context:getPlayerId(3)
    local units = context:gatherUnits(1, 0, 2)

    for i, unit in ipairs(units) do
        unit.playerId = targetPlayer
    end

    Wargroove.updateUnits(units)
    Wargroove.waitFrame()
    Wargroove.clearCaches()
end


function Actions.changeUnitType(context)
    -- "Change {0} from {1} at {2} to {3}"
    local units = context:gatherUnits(1, 0, 2)
    local unitClassId = context:getString(3)

    for i, unit in ipairs(units) do
        unit.unitClassId = unitClassId
    end

    Wargroove.updateUnits(units)
    Wargroove.waitFrame()
    Wargroove.clearCaches()
end


function Actions.revealFoW(context)
    -- "Set Fog of War visibility at {0} for {1} to: {2}"
    local playerId = context:getPlayerId(1)
    local locationId = context:getLocation(0).id
    local visible = context:getBoolean(2)
    Wargroove.revealFogOfWar(playerId, locationId, visible)
end


function Actions.changeTeam(context)
    -- "Change {0} to {1}"
    Wargroove.setPlayerTeam(context:getPlayerId(0), context:getTeam(1))
end


function Actions.message(context)
    -- "Display message: {0}"
    Wargroove.showMessage(context:getString(0))
end


function Actions.dialogueBox(context)
    -- "Display dialogue box with {0} {1} saying {2} with shout {3} using name {5} for {6}. (instant = {4})"
    local playerColour = context:getPlayerColour(6)
    Wargroove.showDialogueBox(context:getString(0), context:getString(1), context:getString(2), context:getString(3), {}, "standard", context:getBoolean(4), context:getString(5), playerColour)
end


function Actions.dialogueBoxSimple(context)
    -- "Display dialogue box with {0} {1} saying {2} using name {4}. (instant = {3})"
    Wargroove.showDialogueBox(context:getString(0), context:getString(1), context:getString(2), "", {}, "standard", context:getBoolean(3), context:getString(4))
end

function Actions.dialogueBoxDecision(context)
    -- "Display dialogue box with {0} {1} saying {2} using name {7} for {8}. Decide between {3} and {4}. If {4} skip {5} actions. (instant = {6})"
    local playerColour = context:getPlayerColour(8)

    Wargroove.showDialogueBox(context:getString(0), context:getString(1), context:getString(2), "", { context:getString(3), context:getString(4) }, "standard", context:getBoolean(6), context:getString(7), playerColour)
    local result = Wargroove.getSelectedDecision()

    if result == 1 then
        context.gotoFlag = context:getInteger(5)
    end
end


function Actions.tutorialBox(context)
    -- Display tutorial box with {0} {1} saying {2}.
    Wargroove.showDialogueBox(context:getString(0), context:getString(1), context:getString(2), "", {}, "tutorial")
end


function Actions.tutorialBoxNew(context)
    -- Display tutorial box with image {0}, title {1} and message {2} (instant = {3})
    Wargroove.showTutorialBox(context:getString(0), context:getString(1), context:getString(2), context:getBoolean(3))
end


function Actions.wait(context)
    -- "Wait {0} milliseconds."
    Wargroove.waitTime(context:getInteger(0) * 0.001)
end


function Actions.centreCamera(context)
    -- "Centre camera at {0}."
    local location = context:getLocation(0)
    local noDelay = context:getBoolean(1)
    
    if (location == nil) then
        return
    end

    local pos = findCentreOfLocation(context:getLocation(0))
    pos.x = math.floor(pos.x)
    pos.y = math.floor(pos.y)
    Wargroove.trackCameraTo(pos, noDelay)
end


function Actions.aiSetProfile(context)
    local targetPlayer = context:getPlayerId(0)
    local profile = context:getString(1)
    Wargroove.setAIProfile(targetPlayer, profile)
end

function Actions.setWeather(context)
    local weather = context:getString(0)
    local daysAhead = context:getInteger(1)
    Wargroove.setWeather(weather, daysAhead)
end

function Actions.aiSetRestriction(context)
    -- "Set AI restriction of {0} at {1} for {2}: Set {3} to {4}"
    local restriction = context:getString(3)
    local value = context:getBoolean(4)
    local units = context:gatherUnits(2, 0, 1)

    for i, unit in ipairs(units) do
        Wargroove.setAIRestriction(unit.id, restriction, value)
    end

    Wargroove.updateUnits(units)
end

function Actions.forceAction(context)
    Actions.doForceAction(context, false)
end

function Actions.forceOpenUITutorial(context)
    Actions.doForceOpenUITutorial(context, false)
end

function Actions.queueForceAction(context)
    Actions.doForceAction(context, true)
end

function Actions.queueForceOpenUITutorial(context)
    Actions.doForceOpenUITutorial(context, true)
end

function Actions.doForceAction(context, queue)
    -- "Force a unit at location {0} to do action {1} from location {2} targeting location {3}. Auto end: {4} On failure, display dialouge box with {5} {6} using name {8} saying {7}"

    local fromLocation = context:getLocation(0)
    local action = context:getString(1)
    local toLocation = context:getLocation(2)
    local targetLocation = context:getLocation(3)    
    local autoEnd = context:getBoolean(4)
    local expression = context:getString(5)
    local commander = context:getString(6)
    local dialogue = context:getString(7)
    local name = context:getString(8)

    local selectableUnits = {}
    for i, unit in ipairs(Wargroove.getUnitsAtLocation(fromLocation)) do
        if context:doesPlayerMatch(unit.playerId,  Wargroove.getCurrentPlayerId()) then
            table.insert(selectableUnits, unit.id)
        end
    end

    local toPositions = {}
    if (toLocation ~= nil) then
        toPositions = toLocation.positions
    end

    local targetPositions = {}
    if (targetLocation ~= nil) then
        targetPositions = targetLocation.positions
    end

    if (queue) then
        Wargroove.queueForceAction(selectableUnits, toPositions, targetPositions, action, autoEnd, expression, commander, dialogue, name)
    else
        Wargroove.forceAction(selectableUnits, toPositions, targetPositions, action, autoEnd, expression, commander, dialogue, name)
    end
end

function Actions.doForceOpenUITutorial(context, queue)
    -- "Force a player to do UI tutorial script {0} at {1}. On failure, display dialouge box with {2} {3} using {7} saying {4}. On tutorial completion, set Map Flag {5} to {6}."

    local uiTutorial = context:getString(0)
    local toLocation = context:getLocation(1)
    local expression = context:getString(2)
    local commander = context:getString(3)
    local dialogue = context:getString(4)
    local mapFlag = tonumber(context.params[5 + 1])
    local mapFlagValue = context:getBoolean(6)
    local name = context:getString(7)

    local toPositions = {}
    if (toLocation ~= nil) then
        toPositions = toLocation.positions
    end

    if (queue) then
        Wargroove.queueForceOpenTutorial(uiTutorial, toPositions, expression, commander, dialogue, mapFlag, mapFlagValue, name)
    else
        Wargroove.forceOpenTutorial(uiTutorial, toPositions, expression, commander, dialogue, mapFlag, mapFlagValue, name)
    end
end

function Actions.addUITutorial(context)
    -- "Starts UI tutorial {0} the next time a player opens a UI window at {1}. On tutorial completion, set Map Flag {2} to {3}."  

    local uiTutorial = context:getString(0)
    local toLocation = context:getLocation(1)
    local mapFlag = tonumber(context.params[2 + 1])
    local mapFlagValue = context:getBoolean(3)

    local toPositions = {}
    if (toLocation ~= nil) then
        toPositions = toLocation.positions
    end
    
    Wargroove.addTutorial(uiTutorial, toPositions, mapFlag, mapFlagValue)
end

function Actions.playCredits(context)
    -- "Plays credits of type {0}."
    context:setCreditsToPlay(0)
end

function Actions.setMatchSeed(context)
    -- "Sets the match seed to {0}."
    Wargroove.setMatchSeed(context:getInteger(0))
end

function Actions.updateFogOfWar(context)
    -- "Updates fog of war."
    Wargroove.updateFogOfWar()
end

function Actions.changeObjective(context)
    -- "Sets the map objective to {0}."
    Wargroove.changeObjective(context:getString(0))
end

function Actions.showObjective(context)
    -- "Shows the current objective."
    Wargroove.showObjective()
end

function Actions.moveLocationToUnit(context)
    -- "Move location {0} to {1} owned by {2} at {3}."
    location = context:getLocation(0)
    units = context:gatherUnits(2, 1, 3)
    for i, unit in ipairs(units) do
        if (unit.inTransport) then
            local transport = Wargroove.getUnitById(unit.transportedBy)
            Wargroove.moveLocationTo(location.id, transport.pos)
        else
            Wargroove.moveLocationTo(location.id, unit.pos)
        end
        return
    end
end

function Actions.moveLocationToLocation(context)
    -- "Move location {0} to {1}."
    local location = context:getLocation(0)
    local target = context:getLocation(1)
    Wargroove.moveLocationTo(location.id, target.centre)
end


function Actions.locationCopy(context)
    -- "Set {0} to have the same area of {1}."
    local dst = context:getLocation(0)
    local src = context:getLocation(1)

    dst:setArea(src:getArea())
end


function Actions.locationBooleanOperation(context)
    -- "Set {0} to the {1} of {2} and {3}."
    local dst = context:getLocation(0)
    local op = context:getBooleanOperation(1)
    local lhp = context:getLocation(2)
    local rhp = context:getLocation(3)

    local area = context:boolOpLocations(lhp, rhp, op)
    dst:setArea(area)
end


function Actions.locationMove(context)
    -- "Move {0} {1} tiles to the right and {2} tiles down."
    local loc = context:getLocation(0)
    local dx = context:getInteger(1)
    local dy = context:getInteger(2)

    local centre = loc.centre

    centre.x = centre.x + dx
    centre.y = centre.y + dy

    Wargroove.moveLocationTo(loc.id, centre)
end


function Actions.setMapMusic(context)
    -- "Sets the map's music to {0} with intensity {1}."
    Wargroove.setMapMusic(context:getString(0), context:getString(1))
end

function Actions.playGrooveCutscene(context)
    -- "Play groove cutscene for {0}."
    Wargroove.playGrooveCutsceneForCharacter(context:getString(0))
end

function Actions.playSoundEffect(context)
    -- "Plays a sound effect {0} at location {1}."
    local soundEffect = context:getString(0)
    local location = context:getLocation(1)

    if (location == nil or location.id == -1)  then
        Wargroove.playPositionlessCutsceneSFX(soundEffect)    
    else
        Wargroove.playCutsceneSFX(soundEffect, location.centre)
    end
end

function Actions.setGizmoState(context)
    -- "Sets all gizmos at location {0} to {1}."
    local location = context:getLocation(0)
    local state = context:getBoolean(1)
    for i, gizmo in ipairs(Wargroove.getGizmosAtLocation(location)) do
        gizmo:setState(state)
    end
end

function Actions.toggleGizmoState(context)
    -- "Toggles the state of all gizmos at location {0}."
    local location = context:getLocation(0)
    for i, gizmo in ipairs(Wargroove.getGizmosAtLocation(location)) do
        gizmo:setState(not gizmo:getState())
    end
end

function Actions.setDamageTaken(context)
    -- "For all {0} at {1} for {2}, set the damage taken to {3}%."
    local units = context:gatherUnits(2, 0, 1)
    local value = math.max(0, math.min(context:getInteger(3), 100000))

    for i, unit in ipairs(units) do
        unit.damageTakenPercent = value
    end

    Wargroove.updateUnits(units)
end

function Actions.counterArithmetics(context)
    -- "Counter {0} = {1} {2} {3}."
    local lhp = context:getMapCounter(1)
    local op = context:getArithmeticOperation(2)
    local rhp = context:getMapCounter(3)
    context:setMapCounter(0, op(lhp, rhp))
end

function Actions.counterRandom(context)
    -- "Counter {0}: Set to a random number between {1} and {2} (inclusive)."
    local counterId = context:getInteger(0)
    local min = context:getInteger(1)
    local max = context:getInteger(2)

    local values = { context.state, context.triggerInstanceTriggerId, context.triggerInstancePlayerId, context.triggerInstanceActionId,
                     counterId, min, max, Wargroove.getOrderId() }
    local str = ""
    for i, v in ipairs(values) do
        str = str .. tostring(v) .. ":"
    end
    local value = math.floor(Wargroove.pseudoRandomFromString(str) * (max - min + 1)) + min

    context:setMapCounter(0, value)
end


function Actions.countUnits(context)
    -- "Store the number of {0} owned by {1} at {2} into {3}."
    local units = context:gatherUnits(1, 0, 2)
    context:setMapCounter(3, #units)
end


function Actions.transferHealth(context)
    -- "Transfer health of {0} owned by {1} at {2}: {3} {4}"
    local units = context:gatherUnits(1, 0, 2)
    local transfer = context:getString(3)
    local value = context:getMapCounter(4)

    for i, unit in ipairs(units) do
        if transfer == "store" then
            context:setMapCounter(4, unit.health)
            break
        elseif transfer == "load" then
            unit:setHealth(value, -1)
        end
    end

    if transfer == "load" then
        Wargroove.updateUnits(units)
    end
end


function Actions.transferGroove(context)
    -- "Transfer groove charge of {0} owned by {1} at {2}: {3} {4}"
    local units = context:gatherUnits(1, 0, 2)
    local transfer = context:getString(3)
    local value = context:getMapCounter(4)

    local oldVersion = (tonumber(Wargroove.getNetworkVersion()) ~= nil and tonumber(Wargroove.getNetworkVersion()) <= 210000)
    for i, unit in ipairs(units) do
        if transfer == "store" then
            if oldVersion then
                context:setMapCounter(4, unit.grooveCharge)
            else                
                local grooveCharge = unit.grooveCharge / unit.unitClass.maxGroove * 100.0
                context:setMapCounter(4, grooveCharge)
            end
            break
        elseif transfer == "load" then
            if oldVersion then
                unit:setGroove(value)
            else
                unit:setGroove(value)
            end
        end
    end

    if transfer == "load" then
        Wargroove.updateUnits(units)
    end
end


function Actions.transferGold(context)
    -- "Transfer gold of {0}: {1} {2}"
    local playerId = context:getPlayerId(0)
    local transfer = context:getString(1)

    if transfer == "store" then
        context:setMapCounter(2, Wargroove.getMoney(playerId))
    elseif transfer == "load" then
        Wargroove.setMoney(playerId, context:getMapCounter(2))
    end
end


function Actions.transferGizmoState(context)
    -- "Transfer state of gizmo at {0}: {1} {2}"
    local location = context:getLocation(0)
    local transfer = context:getString(1)

    for i, gizmo in ipairs(Wargroove.getGizmosAtLocation(location)) do
        if transfer == "store" then
            context:setMapFlag(2, gizmo:getState())
        elseif transfer == "load" then
            gizmo:setState(context:getMapFlag(2))
        end
    end
end

function Actions.activateFlood(context)
    local location = context:getLocation(0)
    local terrain = context:getString(1)
    local direction = context:getFloodDirection(2)
    local animation = context:getString(3)
    local time = context:getInteger(4)
    local removeDecorations = context:getBoolean(5)
    local fxOverUnits = context:getBoolean(6)

    local positions = {}
    for i, pos in ipairs(location.positions) do
        table.insert(positions, pos)
    end

    if direction == "up" or direction == "down" then
        local func = nil
        if direction == "up" then
            func = function(a, b) return a.y > b.y end
        else
            func = function(a, b) return a.y < b.y end
        end

        table.sort(positions, func)
    end

    local tempPositions = {}
    local dropCount = Wargroove.randomInteger(animation..tostring(time), 1, 4)
    local dropCounter = 0
    local lastUnitId = -1
    local playSfx = false
    if terrain == "abyss" then
        playSfx = true
    end

    -- If we don't do this, we'll crash since we'll get state confusion
    local doIndividualDeathCheck = true
    if time == 0 then
        doIndividualDeathCheck = false
    end

    if playSfx and #positions >= 1 then
        Wargroove.playMapSound("campaign/groundBreak", positions[1])
    end

    for i, pos in ipairs(positions) do
        local animVariation = Wargroove.randomInteger(animation..tostring(pos.x)..tostring(pos.y), 1, 3)

        if animation ~= "" then
            if fxOverUnits then
                Wargroove.spawnMapAnimation(pos, 0, animation..tostring(animVariation), "over_units")
            else
                Wargroove.spawnMapAnimation(pos, 0, animation..tostring(animVariation))
            end
        end

        table.insert(tempPositions, pos)
        dropCounter = dropCounter + 1
        
        if dropCounter == dropCount then
            if time ~= 0 then
                Wargroove.waitTime(time * 0.001)
            end

            for _, tmpPos in ipairs(tempPositions) do
                if Wargroove.getUnitAt(tmpPos) ~= nil then
                    lastUnitId = Wargroove.getUnitIdAt(tmpPos)
                end

                Wargroove.setTerrainType(tmpPos, terrain, removeDecorations)
            end

            if doIndividualDeathCheck and lastUnitId ~= -1 then
                local lastUnit = Wargroove.getUnitById(lastUnitId)
                if lastUnit then
                    print("Flood: Death Check (Id: "..lastUnitId.." Type: "..lastUnit.unitClassId..")")
                else
                    print("Flood: Death Check (Id: "..lastUnitId..")")
                end

                Wargroove.doLuaDeathCheck(lastUnitId, false)
                lastUnitId = -1
                coroutine.yield()
            end

            tempPositions = {}
            dropCounter = 0
            dropCount = Wargroove.randomInteger(animation..tostring(i)..tostring(dropCount), 1, 4)
            if playSfx and dropCount > 2 then
                Wargroove.playMapSound("campaign/groundBreak", pos)
            end
        end
    end

    if dropCounter > 0 then
        if time ~= 0 then
            Wargroove.waitTime(time * 0.001)
        end
        for _, tmpPos in ipairs(tempPositions) do
            if Wargroove.getUnitAt(tmpPos) ~= nil then
                lastUnitId = Wargroove.getUnitIdAt(tmpPos)
            end

            Wargroove.setTerrainType(tmpPos, terrain, removeDecorations)
        end
    end

    if lastUnitId ~= -1 then
        Wargroove.doLuaDeathCheck(lastUnitId)
        coroutine.yield()
    end
end


function Actions.spawnItem(context)
    local location = context:getLocation(0)
    local item = context:getString(1)

    Wargroove.spawnItem(location.id, item)
end


function Actions.unitAction(context)
    -- "A unit at location {0} performs action {1} at location {2} targeting location {3}. Provide param {7} (use turn={4}, ignore range={5}, ignore speed={6}) "

    local fromLocation = context:getLocation(0)
    local action = context:getString(1)
    local toLocation = context:getLocation(2)
    local targetLocation = context:getLocation(3)
    local usesTurn = context:getBoolean(4)
    local ignoreRange = context:getBoolean(5)
    local ignoreTerrainSpeed = context:getBoolean(6)
    local param = context:getString(7)

    local selectableUnits = {}
    for i, unit in ipairs(Wargroove.getUnitsAtLocation(fromLocation)) do
        table.insert(selectableUnits, unit.id)
    end

    local toPositions = {}
    if (toLocation ~= nil) then
        toPositions = toLocation.positions
    end

    local targetPositions = {}
    if (targetLocation ~= nil) then
        targetPositions = targetLocation.positions
    end

    Wargroove.unitAction(selectableUnits, toPositions, targetPositions, action, usesTurn, ignoreRange, ignoreTerrainSpeed, param)
    Wargroove.waitFrame()

    if #selectableUnits > 0 then
        Wargroove.doLuaDeathCheck(selectableUnits[1])
    end

    Wargroove.refreshObstacles()
end


function Actions.skipActions(context)
    -- "Skip {0} number of actions."

    local skipNumberOfActions = context:getInteger(0)

    context.gotoFlag = skipNumberOfActions
end


function Actions.spawnAnimation(context)
    -- "Spawn animation {0} at location {1}. Render on layer {3}."
    local animation = context:getString(0)
    local location = context:getLocation(1)
    local layer = context:getString(2)

    local pos = findCentreOfLocation(location)

    Wargroove.spawnMapAnimation(pos, 0, animation, "idle", layer)
end


function Actions.spawnUnitInside(context)
    -- "Spawn {0} at {1} inside transport for {2})"
    local unitClassId = context:getUnitClass(0)
    local location = context:getLocation(1)
    local playerId = context:getPlayerId(2)

    -- Get candidates
    local candidates = findCentreOfLocation(location)

    -- Spawn at the best candidate
    if #location.positions > 0 then
        local pos = location.positions[1]
        local unit = Wargroove.getUnitIdAt(pos)

        Wargroove.spawnUnitInside(playerId, unit, unitClassId)

        Wargroove.clearCaches()
    end
end

function Actions.bonusObjective(context)
    -- "Fulfill bonus objective {0}."
    local bonusTriggerId = context:getInteger(0)
    Wargroove.fulfillBonusObjective(bonusTriggerId)
end

function Actions.failBonusObjective(context)
    -- "Fail bonus objective {0}."
    local bonusTriggerId = context:getInteger(0)
    Wargroove.failBonusObjective(bonusTriggerId)
end

function Actions.setDaytime(context)
    local daytime = context:getString(0)
    Wargroove.setDaytime(daytime)
end

function Actions.fadeStage(context)
    -- "Fade {0} for {1} milliseconds (blocking={2}, below HUD: {4})"
    local direction = context:getString(0)
    local time = context:getInteger(1)
    local blocking = context:getBoolean(2)
    local belowHUD = context:getBoolean(3)

    Wargroove.fadeStage(direction, time * 0.001, belowHUD)
    if blocking then
        Wargroove.waitTime(time * 0.001)
    end
end

function Actions.setPlayerSkipStatus(context)
    -- "Set player {0} skip status to {1}"
    local player = context:getPlayerId(0)
    local skip = context:getBoolean(1)
    
    Wargroove.setPlayerSkipStatus(player, skip)
end

function Actions.showMapUI(context)
    local show = context:getBoolean(0)
    Wargroove.showMapUI(show)
end

function Actions.showInteractionsMenu(context)
    local verbs = context:getString(0)
    Wargroove.showInteractionsMenu(verbs)
end

function Actions.setLocationProperties(context)
    -- "Change properties of {0} (AI obstacle = {1}, obstacle = {2}, interactable = {3})"
    local location = context:getLocation(0)
    local isAIObstacle = context:getBoolean(1)
    local isObstacle = context:getBoolean(2)
    local isInteractable = context:getBoolean(3)
    Wargroove.setLocationProperties(location.id, isAIObstacle, isObstacle, isInteractable)
end

function Actions.selectProtagonist(context)
    -- "Select protagonist."
    Wargroove.selectProtagonist()
end

function Actions.setItem(context)
    -- "Set item of unit at location {0} to {1}"
    local location = context:getLocation(0)
    local item = context:getString(1)

    -- Spawn at the best candidate
    if #location.positions > 0 then
        local pos = location.positions[1]
        local unit = Wargroove.getUnitAt(pos)

        Wargroove.equipItem(unit, item)
        -- Call on item pick up sequence
        local onPickup = ItemOnPickup.getOnPickup(Wargroove, item)
        if onPickup ~= nil then
            onPickup(Wargroove, unit, pos, "", nil)
        end
    end
end

function Actions.displayMovementGrid(context)
    -- "Display movement grid of unit at location {0}."
    local location = context:getLocation(0)

    local target = findCentreOfLocation(location)
    Wargroove.displayMovementGrid(target)
end

function Actions.hideMovementGrid(context)
    -- "Hide movement grid."
    Wargroove.hideMovementGrid()
end


function Actions.setProtagonist(context)
    -- "Set protagonist flag of {0} at {1} for {2} to: {3}"
    local units = context:gatherUnits(2, 0, 1)
    local isProtagonist = context:getBoolean(3)

    for i, unit in ipairs(units) do
        Wargroove.setProtagonist(unit, isProtagonist)
    end
end


function Actions.openCodex(context)
    -- "Open codex at codex entry {0}"
    local item = context:getString(0)

    Wargroove.openCodex(item)
end


function Actions.showConstantObjective(context)
    Wargroove.showConstantObjective()
end


function Actions.hideConstantObjective(context)
    Wargroove.hideConstantObjective()
end


function Actions.updateConstantObjective(context)
    -- "Update the current constant objective to: {0} (replace tokens [0] and [1] with {1}, {2})"
    local item = context:getString(0)
    local counter = context:getMapCounter(1)
    local counterTwo = context:getMapCounter(2)

    Wargroove.updateConstantObjective(item, counter, counterTwo)
end


function Actions.screenshake(context)
    -- "Shake the camera for {0}ms at speed {3}, with offset: x={1} and y={2}"
    local offset_x = context:getInteger(1)
    local offset_y = context:getInteger(2)
    local time = context:getInteger(0)
    local speed = context:getInteger(3)

    Wargroove.screenshake(time, {x=offset_x, y=offset_y}, speed)
end


function Actions.setCutsceneMode(context)
    -- "Set cutscene mode to: {0}"
    local active = context:getBoolean(0)

    Wargroove.setCutsceneMode(active)
end


function Actions.playCharacterIntroduction(context)
    -- -- Play introduction for {0} using shout {1}, name {2} and title {3}
    -- Wargroove.playIntroductionForCharacter(context:getString(0), context:getString(1), context:getString(2), context:getString(3))
end


function Actions.pickBlessing(context)
    -- "Pick {1} blessings from {0}. Display choice to player. Effects take place at {2} for {3}. Show title {4}"
    local blessingGroup = context:getString(0)
    local number = context:getInteger(1)
    local location = context:getLocation(2)
    local player = context:getPlayerId(3)
    local title = context:getString(4)

    Wargroove.openBlessingPickMenu(player, blessingGroup, number, title, "blessing")
    while Wargroove.blessingPickMenuIsOpen() do
        coroutine.yield()
    end

    local blessingId = Wargroove.popBlessingPicked()
    local blessing = Wargroove:getBlessing(blessingId)
    blessing(Wargroove, Actions, player, location)
end


function Actions.executeBlessing(context)
    -- "Execute blessing {0} at location {1} for player {2}."
    local blessingId = context:getString(0)
    local location = context:getLocation(1)
    local player = context:getPlayerId(2)

    local blessing = Wargroove:getBlessing(blessingId)
    blessing(Wargroove, Actions, player, location)
end


function Actions.conditionalSkipActions(context)
    -- "Skip {0} actions if {1} is {2} {3}."
    local op = context:getOperator(2)
    local result = op(context:getMapCounter(1), context:getInteger(3))
    if result == true then
        context.gotoFlag = context:getInteger(0)
    end
end


function Actions.unitFactionOverride(context)
    -- "Change {0} from {1} at {2} to faction {3}"
    local units = context:gatherUnits(1, 0, 2)
    local factionOverride = context:getString(3)

    for i, unit in ipairs(units) do
        unit.factionOverride = factionOverride
    end

    Wargroove.updateUnits(units)
    Wargroove.waitFrame()
    Wargroove.clearCaches()
end

function Actions.playShout(context)
    -- Play shout {0} with character {1}
    Wargroove.playShout(context:getString(0), context:getString(1))
end

function Actions.rewardCrystals(context)
    -- Reward player with {0} crystals.
    Wargroove.rewardCrystals(context:getInteger(0))
end

function Actions.setPlayerCounter(context)
    -- Set player counter {0} to {1}.
    Wargroove.setPlayerCounter(context:getString(0), context:getMapCounter(1))
end

function Actions.getPlayerCounter(context)
    -- Set map counter {0} to player counter {1} value.
    local playerCounter = Wargroove.getPlayerCounter(context:getString(1))

    context:setMapCounter(0, playerCounter)
end

function Actions.unlockUnlock(context)
    -- Unlock {0} for player.
    Wargroove.unlockUnlock(context:getString(0))
end

function Actions.unlockAchievement(context)
    -- Unlock achievement {0} 
    Wargroove.unlockAchievement(context:getString(0))
end

function Actions.locationBox(context)
    -- Display location box with title {0} and message {1} (instant = {2})
    Wargroove.showLocationBox(context:getString(0), context:getString(1), context:getBoolean(2))
end


return Actions
