local Wargroove = require "wargroove/wargroove"
local WargrooveExtra = require "initialized/wargroove_extra"


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

local Ragnarok = {}
local occurences = {}


local actions = {
	start_of_match = {front = {}, back = {}},
	end_of_match = {front = {}, back = {}},
	repeating = {front = {}, back = {}}}

function Ragnarok.init()
	print("Ragnarok.lua loaded")
	local resetOccurencesTrigger = {
		id = "Reset Occurence List",
		enabled = true,
		isIntro = false,
		recurring = "repeat",
		actions = {
			{
				id = "reset_occurence_list",
				parameters = {
				},
				enabled = true,
			}
		},
		conditions = {},
		players = {1, 0, 0, 0, 0, 0, 0, 0}
	}
	Ragnarok.addHiddenTrigger(resetOccurencesTrigger,true)
	local resetRescuesTrigger = {
		id = "Reset Rescue List",
		enabled = true,
		isIntro = false,
		recurring = "repeat",
		actions = {
			{
				id = "reset_rescue_list",
				parameters = {
				},
				enabled = true,
			}
		},
		conditions = {},
		players = {1, 0, 0, 0, 0, 0, 0, 0}
	}
	Ragnarok.addHiddenTrigger(resetRescuesTrigger,true)
	
	--Start of Match Events
	local startFrontActionsTrigger = {
		id = "Run Start Front Actions",
		enabled = true,
		isIntro = false,
		recurring = "start_of_match",
		actions = {
			{
				id = "run_start_front_actions",
				parameters = {
				},
				enabled = true,
			}
		},
		conditions = {},
		players = {1, 0, 0, 0, 0, 0, 0, 0}
	}
	Ragnarok.addHiddenTrigger(startFrontActionsTrigger,false)
	local startBackActionsTrigger = {
		id = "Run Start Back Actions",
		enabled = true,
		isIntro = false,
		recurring = "start_of_match",
		actions = {
			{
				id = "run_start_back_actions",
				parameters = {
				},
				enabled = true,
			}
		},
		conditions = {},
		players = {1, 0, 0, 0, 0, 0, 0, 0}
	}
	Ragnarok.addHiddenTrigger(startBackActionsTrigger,true)
	
	--Repeating Events
	local repeatFrontActionsTrigger = {
		id = "Run Repeat Front Actions",
		enabled = true,
		isIntro = false,
		recurring = "repeat",
		actions = {
			{
				id = "run_repeat_front_actions",
				parameters = {
				},
				enabled = true,
			}
		},
		conditions = {},
		players = {1, 0, 0, 0, 0, 0, 0, 0}
	}
	Ragnarok.addHiddenTrigger(repeatFrontActionsTrigger,false)
	local repeatBackActionsTrigger = {
		id = "Run Repeat Back Actions",
		enabled = true,
		isIntro = false,
		recurring = "repeat",
		actions = {
			{
				id = "run_repeat_back_actions",
				parameters = {
				},
				enabled = true,
			}
		},
		conditions = {},
		players = {1, 0, 0, 0, 0, 0, 0, 0}
	}
	Ragnarok.addHiddenTrigger(repeatBackActionsTrigger,true)
	
	--End of Match Events
	
	local endFrontActionsTrigger = {
		id = "Run End Front Actions",
		enabled = true,
		isIntro = false,
		recurring = "end_of_match",
		actions = {
			{
				id = "run_end_front_actions",
				parameters = {
				},
				enabled = true,
			}
		},
		conditions = {},
		players = {1, 0, 0, 0, 0, 0, 0, 0}
	}
	Ragnarok.addHiddenTrigger(endFrontActionsTrigger,false)
	local endBackActionsTrigger = {
		id = "Run End Back Actions",
		enabled = true,
		isIntro = false,
		recurring = "end_of_match",
		actions = {
			{
				id = "run_end_back_actions",
				parameters = {
				},
				enabled = true,
			}
		},
		conditions = {},
		players = {1, 0, 0, 0, 0, 0, 0, 0}
	}
	Ragnarok.addHiddenTrigger(endBackActionsTrigger,true)
	
	Ragnarok.addAction(Ragnarok.setupGizmos,"start_of_match",false)
	Ragnarok.addAction(Ragnarok.updateGizmos,"repeating",false)
	Ragnarok.addAction(Ragnarok.updateGizmos,"repeating",true)
end

local goldRobbed = {}
Ragnarok.crownID = nil
Ragnarok.crownBearerID = nil
local crownAnimation = "ui/icons/fx_crown"
--local crownOffsetAnimation = "ui/icons/fx_crown_offset"
local crownStateKey = "crown"
local fogOfWarRulesEnabled = false

function Ragnarok.canHoldItem(unit)
    if unit.unitClass.isCommander then
        return false
    end
	if unit.itemId ~= "" then
		return false
	end
	return true
end

function Ragnarok.canHoldCrown(unit)
	if unit.itemId ~= "" then
		return false
	end
	return true
end

function Ragnarok.isCombatUnit(unit)
	local weapons = unit.unitClass.weapons
	if next(weapons)~=nil then
		return true
	end
	return false
end

function Ragnarok.getActions()
	return actions
end

function Ragnarok.addAction(action,occurence,front)
	if occurence == "start_of_match" then
		if front then
			table.insert(actions.start_of_match.front,action)
		else
			table.insert(actions.start_of_match.back,action)
		end
	elseif occurence == "end_of_match" then
		if front then
			table.insert(actions.end_of_match.front,action)
		else
			table.insert(actions.end_of_match.back,action)
		end
	elseif occurence == "repeating" then
		if front then
			table.insert(actions.repeating.front,action)
		else
			table.insert(actions.repeating.back,action)
		end
	end
end

local linkedLocations = {}

function Ragnarok.addLinkedLocation(location,locked)
	table.insert(linkedLocations, {location = location, locked = locked})
end

function Ragnarok.getLinkedLocations()
	return linkedLocations
end

function Ragnarok.setFogOfWarRules(fogOn)
	fogOfWarRulesEnabled = fogOn
end

function Ragnarok.usingFogOfWarRules()
	return fogOfWarRulesEnabled
end

function Ragnarok.addHiddenTrigger(trigger, atEnd)
	WargrooveExtra.addHiddenTrigger(trigger, atEnd)
end


function Ragnarok.addGoldRobbed(playerId, amount)
	if goldRobbed[playerId] then
		goldRobbed[playerId] = goldRobbed[playerId]+amount
	else
		goldRobbed[playerId] = amount
	end
end

function Ragnarok.getGoldRobbed(playerId)
	local robbedMoney = goldRobbed[playerId]
	if robbedMoney then return robbedMoney end
	return 0
end


function Ragnarok.getCrownBearer()
	if Ragnarok.crownBearerID ~= nil then
		return Wargroove.getUnitById(Ragnarok.crownBearerID)
	else
		local units = Wargroove.getUnitsAtLocation()
		for i,unit in pairs(units) do
			if Ragnarok.hasCrown(unit) then
				Ragnarok.crownBearerID = unit.id
				return unit
			end
		end
	end
	return nil
end

function Ragnarok.getCrown()
	if Ragnarok.crownID ~= nil then
		return Wargroove.getItem(Ragnarok.crownID)
	else
		local items = Wargroove.getMapItemsAtLocation()
		for i,item in pairs(items) do
			if item.type == "crown" then
				Ragnarok.crownID = item.id
				return item
			end
		end
	end
	return nil
end

function Ragnarok.getCrownPos()
	local crown = Ragnarok.getCrown()
	if crown ~= nil then
		return crown.pos
	end

	local crownBearer = Ragnarok.getCrownBearer()
	if crownBearer ~= nil then
		return crownBearer.pos
	end
	
	return nil
end

function Ragnarok.hasCrown(unit)
	return unit.itemId=="crown"
	--return Wargroove.getUnitState(unit, crownStateKey) ~= nil
end

function Ragnarok.removeCrown()
	local crown = Ragnarok.getCrown()
	if crown ~= nil then
		Wargroove.consumeItemAt(crown.pos)
	end
	local crownBearer = Ragnarok.getCrownBearer()
	if crownBearer ~= nil then
		WargrooveExtra.unequipItem(crownBearer)
	end
	Ragnarok.crownID = nil
	Ragnarok.crownBearerID = nil
end

function Ragnarok.dropCrown(targetPos)
	Ragnarok.removeCrown()

    local ic = Wargroove.getItem("crown")
	Wargroove.spawnItemAt(ic.id, targetPos)
	Wargroove.waitFrame()
--	Ragnarok.crownID = Wargroove.getMapItemIdAt(targetPos.x, targetPos.y)
	
	Ragnarok.crownBearerID = nil
	Ragnarok.crownID = nil
--	return Ragnarok.crownID
	return nil
end

function Ragnarok.grabCrown(unit)
	Ragnarok.removeCrown()
	Wargroove.equipItem(unit, "crown")
	Ragnarok.crownBearerID = unit.id
end

local activator = {}
local gizmoModeList = {}
local lockedGizmos = {}
local invertedVisualGizmos = {}
local invertedOutputGizmos = {}

local gizmoSoundMapOn = {
	["pressure_plate"] = "cutscene/stoneScrape1",
	["drawbridge_left"] = "cutscene/drawbridgeDrop",
	["drawbridge_right"] = "cutscene/drawbridgeDrop",
	["drawbridge_top"] = "cutscene/drawbridgeDrop",
	["drawbridge_down"] = "cutscene/drawbridgeDrop",
	["lever"] = "switch",
	["broken_wall"] = "strongholdDieRed",
	["broken_wall_vertical"] = "strongholdDieRed"
}
local gizmoSoundMapOff = {
	["pressure_plate"] = "cutscene/stoneScrape2",
	["drawbridge_left"] = "cutscene/drawbridgeRaise",
	["drawbridge_right"] = "cutscene/drawbridgeRaise",
	["drawbridge_top"] = "cutscene/drawbridgeRaise",
	["drawbridge_down"] = "cutscene/drawbridgeRaise",
	["lever"] = "switch"
}

function Ragnarok.setupGizmos(context)
    for i, gizmo in pairs(Wargroove.getGizmosAtLocation(nil)) do
		if gizmo.type == "pressure_plate" then
			gizmoModeList[Ragnarok.generateGizmoKey(gizmo)] = "stoodOn"
		end
		if gizmo.type == "lever" then
			gizmoModeList[Ragnarok.generateGizmoKey(gizmo)] = "stoodOn"
		end
    end
end


function Ragnarok.updateGizmos(context)
    for i, gizmo in pairs(Wargroove.getGizmosAtLocation(nil)) do
		if gizmoModeList[Ragnarok.generateGizmoKey(gizmo)] ~= nil then
			if gizmoModeList[Ragnarok.generateGizmoKey(gizmo)] == "stoodOn" then
				Ragnarok.gizmoActivateWhenStoodOn(gizmo)
			end
		end
    end
	for i, linkedLocation in ipairs(Ragnarok.getLinkedLocations()) do
		Ragnarok.linkGizmoStateWithActivators(linkedLocation)
	end
end

function Ragnarok.linkGizmoStateWithActivators(linkedLocation)
	local isActivated = true
	local anyActivators = false
	local actuators = {}
    for i, gizmo in ipairs(Wargroove.getGizmosAtLocation(linkedLocation.location)) do
		if Ragnarok.isActivator(gizmo) then
			anyActivators = true
			if gizmo:getState() == false then
				isActivated = false
			end
		else
			table.insert(actuators, gizmo)
		end
    end
	if anyActivators and actuators and Ragnarok.wouldAnyStatesChange(actuators, isActivated) then
		Wargroove.waitTime(0.1)
		Wargroove.playMapSound("cutscene/swordSheath", actuators[1].pos)
		Wargroove.waitTime(0.3)
		Ragnarok.setStates(actuators, isActivated, true)
		if isActivated and linkedLocation.locked then
			for i, gizmo in ipairs(Wargroove.getGizmosAtLocation(linkedLocation.location)) do
				lockedGizmos[Ragnarok.generateGizmoKey(gizmo)] = true
			end
			
		end
	end
end

function Ragnarok.setState(gizmo, state, playSound)
	if lockedGizmos[Ragnarok.generateGizmoKey(gizmo)] == true then
		return {changedState = false, soundPlayed = false}
	end
	if playSound == nil then playSound = true end
	local changedState = Ragnarok.getInternalGizmoState(gizmo) ~= state
	local soundPlayed
	if changedState then
		local soundOn = gizmoSoundMapOn[gizmo.type]
		local soundOff = gizmoSoundMapOff[gizmo.type]
		if soundOn and state then
			soundPlayed = soundOn
		end
		if soundOff and not state then
			soundPlayed = soundOff
		end
	end
	if playSound then
		Wargroove.playMapSound(soundPlayed, gizmo.pos)
	end
	local key = Ragnarok.generateGizmoKey(gizmo)
	gizmo:setState(not(state  == (invertedVisualGizmos[key]==true)))
	return {changedState = changedState, soundPlayed = soundPlayed}
end

function Ragnarok.wouldStateChange(gizmo, state)
	if lockedGizmos[Ragnarok.generateGizmoKey(gizmo)] == true then
		return false
	end
	local changedState = Ragnarok.getInternalGizmoState(gizmo) ~= state
	return changedState
end

function Ragnarok.wouldAnyStatesChange(gizmos, state)
	local changedState = false
    for i, gizmo in ipairs(gizmos) do
		changedState = changedState or Ragnarok.wouldStateChange(gizmo,state)
    end
	return changedState
end

function Ragnarok.setStates(gizmos, state, playSound)
--	print("Ragnarok.setStates starts here") 
--	print(state) 
	if playSound == nil then playSound = true end
	local changedState = false
	local soundsPlayed = {}
	local soundCount = 0
    for i, gizmo in ipairs(gizmos) do
		local result = Ragnarok.setState(gizmo,state, false)
		local sound = result.soundPlayed
		changedState = changedState or result.changedState
		if sound and playSound and soundsPlayed[sound] == nil then
			--print(sound)
			--print(soundsPlayed[sound])
			Wargroove.playMapSound(sound, gizmo.pos)
			soundsPlayed[sound] = true
			soundCount = soundCount + 1
		end
    end
	return changedState
end

function Ragnarok.setActivator(gizmo,state)
	local key = Ragnarok.generateGizmoKey(gizmo)
    activator[key] = true
	if state == false then activator[key] = nil end
end

function Ragnarok.invertVisualGizmo(gizmo)
	gizmo:setState(not gizmo:getState())
	local key = Ragnarok.generateGizmoKey(gizmo)
	if invertedVisualGizmos[gizmo] then invertedVisualGizmos[key] = nil
	else invertedVisualGizmos[key] = true
	end
end

function Ragnarok.invertOutputGizmo(gizmo)
	local key = Ragnarok.generateGizmoKey(gizmo)
	if invertedOutputGizmos[gizmo] then invertedOutputGizmos[key] = nil
	else invertedOutputGizmos[key] = true
	end
end

function Ragnarok.getInternalGizmoState(gizmo)
	local key = Ragnarok.generateGizmoKey(gizmo)
	local result = gizmo:getState()
	--invert visual
	result = not(result  == (invertedVisualGizmos[key]==true))
	return result
end

function Ragnarok.getGizmoState(gizmo)
	local key = Ragnarok.generateGizmoKey(gizmo)
	local result = Ragnarok.getInternalGizmoState(gizmo)
	--invert output
	result = not(result  == (invertedOutputGizmos[key]==true))
	return result
end

function Ragnarok.generateGizmoKey(gizmo)
	return gizmo.pos.x*1000+gizmo.pos.y --Should work as long as people don't make maps taller than 1000 tiles.
end

function Ragnarok.isActivator(gizmo)
	local key = Ragnarok.generateGizmoKey(gizmo)
	return activator[key] == true
end


function Ragnarok.gizmoActivateWhenStoodOn(gizmo)
--	print("gizmoActivateWhenStoodOn()")
	Ragnarok.setActivator(gizmo, true)
	local unit = Wargroove.getUnitAt(gizmo.pos)
	local pos = Ragnarok.getCrownPos()
	local isCrown = pos and (pos.x == gizmo.pos.x) and (pos.y == gizmo.pos.y)
	local isPressed = isCrown or unit ~= nil
--	print(isPressed)
--	print(gizmo.type)
	Ragnarok.setState(gizmo,isPressed)
end

function Ragnarok.printCrownInfo()
   print("Printing Crown Stuff")
   print("crownID:",Ragnarok.crownID)
   print("crownBearerID:",Ragnarok.crownBearerID)
   print("")
end

function Ragnarok.moveInArch(unitId, startPos, targetPos, numSteps, speed, gravity, xyGamma, zGamma, eventPackages)

	print("Ragnarok.moveInArch start")
	if not xyGamma then
		xyGamma = 1
	end
	if not zGamma then
		zGamma = 1
	end
	
    local steps = {}
	local deltaSteps = {}
	
    local xDiff = targetPos.x - startPos.x
    local yDiff = targetPos.y - startPos.y
    local xStep = xDiff / numSteps
    local yStep = yDiff / numSteps
	local dist = math.sqrt(xDiff^2+yDiff^2)
	local tEnd = dist/speed
	--use z = 1/2at^2+bt
	--find b by constraining that at the mid section of the journey, the differential of z over time is zero.
	--dz/dt = at+b
	--0 = 1/2a(tEnd)+b
	local a = gravity
	local b = -1/2*a*tEnd
	
    for i = 1,numSteps do
		local progress = i/numSteps
		local z = 1/2*a*(tEnd*(1-(1-progress)^zGamma))^2+b*tEnd*(1-(1-progress)^zGamma)
        steps[i] = {x = xDiff * (1-(1-progress)^xyGamma), y = yDiff * (1-(1-progress)^xyGamma) + z}
		if i > 1 then
			deltaSteps[i] = {x = steps[i].x-steps[i-1].x, y = steps[i].y-steps[i-1].y}
		else
			deltaSteps[i] = steps[i]
		end
    end
	local doneEvents = {}
    for i = 1, numSteps do
		--print("Checking Event Packages")
		if eventPackages ~= nil then
			for j, eventPackage in pairs(eventPackages) do
				if doneEvents[j] == nil then
					--print("Event " .. tostring(j))
					--print(tostring(i/numSteps)..">="..tostring(eventPackage.time).." fraction")
					--print(tostring(i/numSteps*tEnd)..">="..tostring(eventPackage.time).." fraction")
					--print(tostring(i/numSteps*tEnd)..">="..tostring(tEnd-eventPackage.time).." fraction")
					
					if (i/numSteps>=eventPackage.time and eventPackage.mode == "fraction") or
					(i/numSteps*tEnd>=eventPackage.time and eventPackage.mode == "fromStart") or
					(i/numSteps*tEnd>=tEnd-eventPackage.time and eventPackage.mode == "fromEnd") then
						--print("Executing " .. tostring(j))
						eventPackage.event(eventPackage.eventData)
						--print("Done " .. tostring(j))
						doneEvents[j] = true
					end
				end
			end
		end
		Wargroove.moveUnitToOverride(unitId, startPos, steps[i].x, steps[i].y, math.max(math.sqrt(deltaSteps[i].x^2+deltaSteps[i].y^2)*numSteps/tEnd,1))
		while (Wargroove.isLuaMoving(unitId)) do
			coroutine.yield()
		end
    end
	--print("Checking for missed Event Packages")
	if eventPackages ~= nil then
		for i, eventPackage in pairs(eventPackages) do
			if doneEvents[i] == nil then
				--print("Found: " .. tostring(i))
				eventPackage.event(eventPackage.eventData)
			end
		end
	end
end

function Ragnarok.didItOccur(occation)
	return occurences[occation] ~= nil
end

function Ragnarok.reportOccation(occation)
	occurences[occation] = true
end

return Ragnarok
