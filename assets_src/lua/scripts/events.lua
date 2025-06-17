local VisionTracker = require "initialized/vision_tracker"
local OldEvents = require("wargroove/events")
local Wargroove = require("wargroove/wargroove")
local TriggerContext = require("triggers/trigger_context")
local Resumable = require("wargroove/resumable")
local StealthManager = require("scripts/stealth_manager")
local Pathfinding = require("util/pathfinding")



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
 


local Events = {}

function Events.init()
	OldEvents.reportUnitDeath = Events.reportUnitDeath
	OldEvents.startSession = Events.startSession
	OldEvents.getMatchState = Events.getMatchState
	OldEvents.addToActionsList = Events.addToActionsList
	OldEvents.addToConditionsList = Events.addToConditionsList
	OldEvents.populateTriggerList = Events.populateTriggerList
	OldEvents.doCheckEvents = Events.doCheckEvents
	OldEvents.checkEvents = Events.checkEvents
	OldEvents.checkConditions = Events.checkConditions
	OldEvents.runActions = Events.runActions
	OldEvents.setMapFlag = Events.setMapFlag
	OldEvents.getTriggerKey = Events.getTriggerKey
	OldEvents.canExecuteTrigger = Events.canExecuteTrigger
	OldEvents.executeTrigger = Events.executeTrigger
	OldEvents.isConditionTrue = Events.isConditionTrue
	OldEvents.runAction = Events.runAction
    OldEvents.checkEventsAfter = Events.checkEventsAfter
end

local triggerContext = TriggerContext:new({
    state = "",
    fired = {},
    campaignFlags = {},    
    mapFlags = {},
    mapCounters = {},
    party = {},
    campaignCutscenes = {},
    gotoFlag = nil,
    creditsToPlay = "",
    interactTargetPos = nil
})

local triggerList = nil
local triggerConditions = {}
local triggerActions = {}
local pendingDeadUnits = {}
local pendingVerbsUsed = {}
local pendingInteractionsUsed = {}

function Events.startSession(matchState)
    pendingDeadUnits = {}
    pendingVerbsUsed = {}
    pendingInteractionsUsed = {}

    Events.populateTriggerList()

    function readVariables(name)
        src = matchState[name]
        dst = triggerContext[name]

        for i, var in ipairs(src) do
            dst[var.id] = var.value
        end
    end

    readVariables("mapFlags")
    readVariables("mapCounters")
    readVariables("campaignFlags")

    for i, var in ipairs(matchState.triggersFired) do
        triggerContext.fired[var] = true
    end

    for i, var in ipairs(matchState.party) do
        table.insert(triggerContext.party, var)
    end

    for i, var in ipairs(matchState.campaignCutscenes) do
        table.insert(triggerContext.campaignCutscenes, var)
    end

    triggerContext.creditsToPlay = matchState.creditsToPlay
end


function Events.getMatchState()
    local result = {}

    function writeVariables(name)
        local src = triggerContext[name]
        local dst = {}
        result[name] = dst

        for k, v in pairs(src) do
            table.insert(dst, { id = k, value = v })
        end
    end

    writeVariables("mapFlags")
    writeVariables("mapCounters")
    writeVariables("campaignFlags")

    result.triggersFired = {}
    for k, v in pairs(triggerContext.fired) do
        table.insert(result.triggersFired, k)
    end

    result.party = {}
    for i, var in ipairs(triggerContext.party) do
        table.insert(result.party, var)
    end

    result.campaignCutscenes = {}
    for i, var in ipairs(triggerContext.campaignCutscenes) do
        table.insert(result.campaignCutscenes, var)
    end

    result.creditsToPlay = triggerContext.creditsToPlay

    return result
end

local additionalActions = {}
local additionalConditions = {}

function Events.setInteractTarget(targetPos)
    triggerContext.interactTargetPos = targetPos
end

function Events.addToActionsList(actions)
  table.insert(additionalActions, actions)
end

function Events.addToConditionsList(conditions)
  table.insert(additionalConditions, conditions)
end

function Events.populateTriggerList()
    triggerList = Wargroove.getMapTriggers()

    local Actions = require("triggers/actions")
    local Conditions = require("triggers/conditions")

    Conditions.populate(triggerConditions)
    Actions.populate(triggerActions)

    for i, action in ipairs(additionalActions) do
      action.populate(triggerActions)
    end

    for i, condition in ipairs(additionalConditions) do
      condition.populate(triggerConditions)
    end
end
local checkEventsAfter = false

function Events.checkEventsAfter()
    checkEventsAfter = true
end

function Events.doCheckEvents(state)
    triggerContext.state = state
    triggerContext.deadUnits = pendingDeadUnits
    triggerContext.verbsUsed = pendingVerbsUsed
    triggerContext.interactionsUsed = pendingInteractionsUsed

    local newPendingUnits = {}
    for i, unit in ipairs(pendingDeadUnits) do
        if unit.triggeredBy ~= nil then
            table.insert(newPendingUnits, unit)
        end 
    end

    local newPendingVerbs = {}
    for i, unit in ipairs(pendingVerbsUsed) do
        if unit.verbTriggeredBy ~= nil then
            table.insert(newPendingVerbs, unit)
        end
    end

    local newPendingInteractions = {}
    for i, unit in ipairs(pendingInteractionsUsed) do
        if unit.verbTriggeredBy ~= nil then
            table.insert(newPendingInteractions, unit)
        end
    end

    pendingDeadUnits = newPendingUnits
    pendingVerbsUsed = newPendingVerbs
    pendingInteractionsUsed = newPendingInteractions
    checkEventsAfter = true
    while (checkEventsAfter) do
        checkEventsAfter = false
        for triggerNum, trigger in ipairs(triggerList) do
            triggerContext.triggerInstanceTriggerId = triggerNum

            local newPendingUnits = {}
            for j, unit in ipairs(pendingDeadUnits) do
                if unit.triggeredBy == nil or unit.triggeredBy ~= triggerNum then
                    table.insert(newPendingUnits, unit)
                end
            end

            local newPendingVerbs = {}
            for j, unit in ipairs(pendingVerbsUsed) do
                if unit.verbTriggeredBy == nil or unit.verbTriggeredBy ~= triggerNum then
                    table.insert(newPendingVerbs, unit)
                end
            end

            local newPendingInteractions = {}
            for j, unit in ipairs(pendingInteractionsUsed) do
                if unit.interactionTriggeredBy == nil or unit.interactionTriggeredBy ~= triggerNum then
                    table.insert(newPendingInteractions, unit)
                end
            end

            pendingDeadUnits = newPendingUnits
            pendingVerbsUsed = newPendingVerbs
            pendingInteractionsUsed = newPendingInteractions

            for n = 0, 7 do
                triggerContext.triggerInstancePlayerId = n
                if trigger.enabled and Events.canExecuteTrigger(trigger) then
                    Events.executeTrigger(trigger)
                    for j, unit in ipairs(pendingDeadUnits) do
                        if unit.triggeredBy == nil then
                            unit.triggeredBy = triggerNum
                            table.insert(triggerContext.deadUnits, unit)
                        end
                    end
                    for j, unit in ipairs(pendingVerbsUsed) do
                        if unit.verbTriggeredBy == nil then
                            unit.verbTriggeredBy = triggerNum
                            table.insert(triggerContext.verbsUsed, unit)
                        end
                    end
                    for j, unit in ipairs(pendingInteractionsUsed) do
                        if unit.interactionTriggeredBy == nil then
                            unit.interactionTriggeredBy = triggerNum
                            table.insert(triggerContext.interactionsUsed, unit)
                        end
                    end
                end
            end
        end
    end
end


function Events.checkEvents(state)
    return Resumable.run(function ()
       Events.doCheckEvents(state) 
    end)
end

function Events.checkConditions(conditions)
    for i, cond in ipairs(conditions) do
        if not Events.isConditionTrue(cond) and cond.enabled then
            return false
        end
    end
    return true
end

function Events.runActions(actions, isIntro)
    local i=1
    while i<=#actions do
        triggerContext.triggerInstanceActionId = i
        local action = actions[i]

        if action.enabled then
            --print("Running action #"..i)
            Events.runAction(action)
            coroutine.yield()
        end

        -- Check for goto flag being set, which jumps the current action position
        if triggerContext.gotoFlag ~= nil then
            local newIndex = i + triggerContext.gotoFlag + 1
            newIndex = math.max(0, newIndex)
            newIndex = math.min(#actions, newIndex)

            i = newIndex
            triggerContext.gotoFlag = nil
        else
            i = i + 1
        end
    end
end


function Events.setMapFlag(flagId, value)
    triggerContext:setMapFlagById(flagId, value)
end


function Events.getTriggerKey(trigger)
    local key = trigger.id
    if trigger.recurring == "oncePerPlayer" then
        key = key .. ":" .. tostring(triggerContext.triggerInstancePlayerId)
    end
    return key
end


function Events.canExecuteTrigger(trigger)
    -- Check if this trigger supports this player
    if trigger.players[triggerContext.triggerInstancePlayerId + 1] ~= 1 then
        return false
    end

    if trigger.recurring ~= 'start_of_match' then
        if triggerContext:checkState('startOfMatch') then
            return false
        end        
    elseif not triggerContext:checkState('startOfMatch') then
        return false
    end

    if trigger.recurring ~= 'end_of_match' then
        if triggerContext:checkState('endOfMatch') then
            return false
        end        
    elseif not triggerContext:checkState('endOfMatch') then
        return false
    end

    -- Check if it already ran
    if trigger.recurring ~= "repeat" and trigger.recurring ~= "start_of_interact" and trigger.recurring ~= "unit_selected" then
        if triggerContext.fired[Events.getTriggerKey(trigger)] ~= nil then
            return false
        end
    end

    if trigger.recurring ~= 'start_of_interact' then
        if triggerContext:checkState('startOfInteract') then
            return false
        end
    elseif not triggerContext:checkState('startOfInteract') then
        return false
    end

    if trigger.recurring ~= 'unit_selected' then
        if triggerContext:checkState('unitSelected') then
            return false
        end
    elseif not triggerContext:checkState('unitSelected') then
        return false
    end

    -- Check all conditions
    return Events.checkConditions(trigger.conditions)
end


function Events.executeTrigger(trigger)
    triggerContext.fired[Events.getTriggerKey(trigger)] = true
    triggerContext.spawnedUnits = {}
    local applySkippable = Wargroove.areIntroEventsSkippable() and trigger.isIntro

    if not applySkippable then
        Events.runActions(trigger.actions, trigger.isIntro)
    else
        print("Skipping intro trigger actions "..trigger.id)
    end
end

function Events.isConditionTrue(condition)
    local f = triggerConditions[condition.id]
    if f == nil then
        print("Condition not implemented: " .. condition.id)
    else
        triggerContext.params = condition.parameters
        return f(triggerContext)
    end
end


function Events.runAction(action)
    local f = triggerActions[action.id]
    if f == nil then
        print("Action not implemented: " .. action.id)
    else
        --print("Executing action " .. action.id)
        triggerContext.params = action.parameters
        f(triggerContext)
    end
end


function Events.reportUnitDeath(id, attackerUnitId, attackerPlayerId, attackerUnitClass)
    local unit = Wargroove.getUnitById(id)
	VisionTracker.removeUnitFromVisionMatrix(unit)
	Wargroove.updateFogOfWar()
    StealthManager.reportDeadUnit(id)
    unit.attackerId = attackerUnitId
    unit.attackerPlayerId = attackerPlayerId
    unit.attackerUnitClass = attackerUnitClass
    table.insert(pendingDeadUnits, unit)
    Wargroove.setMetaUnitClass("last_death", unit.unitClass)
end

function Events.reportVerbUsed(id, verb, isGrooveVerb, targetPos, strParam, path)
    local unit = Wargroove.getUnitById(id)
    unit.verbUsed = {
        verb = verb,
        isGroove = isGrooveVerb,
        strParam = strParam,
        path = path
    }
    table.insert(pendingVerbsUsed, unit)
end

function Events.reportInteractionUsed(id, verb, targetPos, path)
    local unit = Wargroove.getUnitById(id)
    unit.interactionUsed = {
        verb = verb,
        targetPos = targetPos,
        path = path
    }
    table.insert(pendingInteractionsUsed, unit)
end
return Events