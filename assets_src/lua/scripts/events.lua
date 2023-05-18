local VisionTracker = require "initialized/vision_tracker"
local OldEvents = require("wargroove/events")
local Wargroove = require("wargroove/wargroove")
local TriggerContext = require("triggers/trigger_context")
local Resumable = require("wargroove/resumable")

local Events = {}
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
 

function Events.init()
	Original.reportUnitDeath = OldEvents.reportUnitDeath
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
end


local triggerContext = TriggerContext:new({
    state = "",
    fired = {},
    campaignFlags = {},    
    mapFlags = {},
    mapCounters = {},
    party = {},
    campaignCutscenes = {},
    creditsToPlay = ""
})

local triggerList = nil
local triggerConditions = {}
local triggerActions = {}
local pendingDeadUnits = {}
local activeDeadUnits = {}


function Events.startSession(matchState)
    pendingDeadUnits = {}

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

function Events.doCheckEvents(state)
    triggerContext.state = state
    triggerContext.deadUnits = pendingDeadUnits

    local newPendingUnits = {}
    for i, unit in ipairs(pendingDeadUnits) do
        if unit.triggeredBy ~= nil then
            table.insert(newPendingUnits, unit)
        end 
    end

    pendingDeadUnits = newPendingUnits

    for triggerNum, trigger in ipairs(triggerList) do
        triggerContext.triggerInstanceTriggerId = triggerNum

        local newPendingUnits = {}
        for j, unit in ipairs(pendingDeadUnits) do
            if unit.triggeredBy == nil or unit.triggeredBy ~= triggerNum then
                table.insert(newPendingUnits, unit)
            end
        end

        pendingDeadUnits = newPendingUnits

        for n = 0, 7 do
            triggerContext.triggerInstancePlayerId = n
            if Events.canExecuteTrigger(trigger) then
                Events.executeTrigger(trigger)
                for j, unit in ipairs(pendingDeadUnits) do
                    if unit.triggeredBy == nil then
                        unit.triggeredBy = triggerNum
                        table.insert(triggerContext.deadUnits, unit)
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
	local orMode = false;
	local isTrue = false;
    for i, cond in ipairs(conditions) do
		if cond.id == "or_group" then
			orMode = true
			isTrue = false
		elseif cond.id == "end_group" then
			orMode = false
			if isTrue == false then
				return false
			end
		else
			if orMode then
				if Events.isConditionTrue(cond) then
					isTrue = true
				end
			else
				if not Events.isConditionTrue(cond) then
					return false
				end
			end
		end
    end
	if orMode == true then
		if isTrue == false then
			return false
		end
	end
    return true
end

function Events.groupActions(actions)
	local groupedActions = {}
	local groupedModes = {}
    local currentGroup = {}
    local currentMode = nil
	local level = 0
    for i, action in pairs(actions) do
		if action.id == "end_group" then
			print("group mode ends")
			level = level - 1
            if level == 0 then
                table.insert(groupedActions, currentGroup)
                table.insert(groupedModes, currentMode)
                currentGroup = {}
			    currentMode = nil
            end
		end
		if level == 0 then
			table.insert(groupedActions, action)
            table.insert(groupedModes, "single")
		else
			table.insert(currentGroup,action)
		end
		if action.id == "run_group_concurrently" then
            if level == 0 then
			    currentMode = "concurrent"
            end
			level = level + 1
		end
		if action.id == "run_group_sequentially" then
            if level == 0 then
			    currentMode = "sequential"
            end
			level = level + 1
		end
    end
	if level>0 then
        table.insert(groupedActions,{mode = currentMode, actions = currentGroup})
        currentMode = nil
	end
    return groupedActions, groupedModes
end
function Events.runConcurrently(currentId, actions)
	print("Events.runConcurrently(actions)")
	local groupedActions,groupedModes = Events.groupActions(actions)
    local coList = {}
    local currentIdList = {}
    for i, actionGroup in ipairs(groupedActions) do
        print("actionGroup")
        print(dump(actionGroup,0))
        print(dump(groupedModes[i],0))
        currentIdList[i] = currentId
        coList[i] = coroutine.create(function (time)
            if (groupedModes[i] == nil) or (groupedModes[i] == "single") then
                Events.runActions(currentId, {actionGroup})
            else
                Events.runActions(currentId, actionGroup)
            end
            return true
         end)
         currentId = currentId+1
    end
    local first = true
    local time = 0
    while next(coList) ~= nil do
        local toBeRemoved = {};
        for i, co in pairs(coList) do
            local errorFree, result
            if first then
                errorFree, result = coroutine.resume(co,time)
            else
                errorFree, result = coroutine.resume(co,time)

            end
            first = false
            if errorFree == false then
                table.insert(toBeRemoved,i)
            end
        end
        for i, id in ipairs(toBeRemoved) do
            coList[id] = nil
        end
        time = coroutine.yield()
        print("TIME")
        print(time)
    end
end

function Events.runActions(currentId, actions)
	local groupedActions,groupedModes = Events.groupActions(actions)
    for i, actionGroup in ipairs(groupedActions) do
        if (groupedModes[i] == nil) or (groupedModes[i] == "single") then
            triggerContext.triggerInstanceActionId = currentId
            Events.runAction(actionGroup)
        elseif groupedModes[i] == "concurrent" then
            Events.runConcurrently(currentId, actionGroup)
        elseif groupedModes[i] == "sequential" then
            Events.runActions(currentId, actionGroup)
        end
        currentId = currentId+1;
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
    if trigger.recurring ~= "repeat" then
        if triggerContext.fired[Events.getTriggerKey(trigger)] ~= nil then
            return false
        end
    end

    -- Check all conditions
    return Events.checkConditions(trigger.conditions)
end


function Events.executeTrigger(trigger)
    triggerContext.fired[Events.getTriggerKey(trigger)] = true
    Events.runActions(1,trigger.actions)
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
	Original.reportUnitDeath(id, attackerUnitId, attackerPlayerId, attackerUnitClass)
end

return Events