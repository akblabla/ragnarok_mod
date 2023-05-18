local Wargroove = require "wargroove/wargroove"
local WargrooveExtra = require "initialized/wargroove_extra"



local Ragnarok = {}
Ragnarok.seaTiles = {"sea","sea_alt", "ocean","reef","cave_sea", "cave_reef","cave_reef","reef_no_hiding"}
Ragnarok.amphibiousTiles = {"river", "cave_river", "beach", "cave_beach", "mangrove"}
Ragnarok.groundTags = {"type.ground.light", "type.ground.heavy"}


local actions = {
	start_of_match = {front = {}, back = {}},
	end_of_match = {front = {}, back = {}},
	repeating = {front = {}, back = {}}}

function Ragnarok.init()
	local resetOccurencesTrigger = {
		id = "Reset Occurence List",
		recurring = "repeat",
		actions = {
			{
				id = "reset_occurence_list",
				parameters = {
				}
			}
		},
		conditions = {},
		players = {1, 0, 0, 0, 0, 0, 0, 0}
	}
	Ragnarok.addHiddenTrigger(resetOccurencesTrigger,true)
	local resetRescuesTrigger = {
		id = "Reset Rescue List",
		recurring = "repeat",
		actions = {
			{
				id = "reset_rescue_list",
				parameters = {
				}
			}
		},
		conditions = {},
		players = {1, 0, 0, 0, 0, 0, 0, 0}
	}
	Ragnarok.addHiddenTrigger(resetRescuesTrigger,true)
	
	--Start of Match Events
	local startFrontActionsTrigger = {
		id = "Run Start Front Actions",
		recurring = "start_of_match",
		actions = {
			{
				id = "run_start_front_actions",
				parameters = {
				}
			}
		},
		conditions = {},
		players = {1, 0, 0, 0, 0, 0, 0, 0}
	}
	Ragnarok.addHiddenTrigger(startFrontActionsTrigger,false)
	local startBackActionsTrigger = {
		id = "Run Start Back Actions",
		recurring = "start_of_match",
		actions = {
			{
				id = "run_start_back_actions",
				parameters = {
				}
			}
		},
		conditions = {},
		players = {1, 0, 0, 0, 0, 0, 0, 0}
	}
	Ragnarok.addHiddenTrigger(startBackActionsTrigger,true)
	
	--Repeating Events
	local repeatFrontActionsTrigger = {
		id = "Run Repeat Front Actions",
		recurring = "repeat",
		actions = {
			{
				id = "run_repeat_front_actions",
				parameters = {
				}
			}
		},
		conditions = {},
		players = {1, 0, 0, 0, 0, 0, 0, 0}
	}
	Ragnarok.addHiddenTrigger(repeatFrontActionsTrigger,false)
	local repeatBackActionsTrigger = {
		id = "Run Repeat Back Actions",
		recurring = "repeat",
		actions = {
			{
				id = "run_repeat_back_actions",
				parameters = {
				}
			}
		},
		conditions = {},
		players = {1, 0, 0, 0, 0, 0, 0, 0}
	}
	Ragnarok.addHiddenTrigger(repeatBackActionsTrigger,true)
	
	--End of Match Events
	
	local endFrontActionsTrigger = {
		id = "Run End Front Actions",
		recurring = "end_of_match",
		actions = {
			{
				id = "run_end_front_actions",
				parameters = {
				}
			}
		},
		conditions = {},
		players = {1, 0, 0, 0, 0, 0, 0, 0}
	}
	Ragnarok.addHiddenTrigger(endFrontActionsTrigger,false)
	local endBackActionsTrigger = {
		id = "Run End Back Actions",
		recurring = "end_of_match",
		actions = {
			{
				id = "run_end_back_actions",
				parameters = {
				}
			}
		},
		conditions = {},
		players = {1, 0, 0, 0, 0, 0, 0, 0}
	}
	Ragnarok.addHiddenTrigger(endBackActionsTrigger,true)
	
	Ragnarok.addAction(Ragnarok.setupGizmos,"start_of_match",false)
	Ragnarok.addAction(Ragnarok.updateGizmos,"repeating",false)
	Ragnarok.addAction(Ragnarok.updateGizmos,"repeating",true)
	Ragnarok.addAction(Ragnarok.regenerateCrownBearer,"repeating",true)
end

local cantAttackBuildingsSet = {}
local goldRobbed = {}
Ragnarok.crownID = nil
Ragnarok.crownPos = nil
Ragnarok.crownBearerID = nil
local crownAnimation = "ui/icons/fx_crown"
local crownOffsetAnimation = "ui/icons/fx_crown_offset"
local crownStateKey = "crown"
local flareCountTable = {}
local fogOfWarRulesEnabled = false
local occurences = {}

function Ragnarok.getActions()
	return actions
end

function Ragnarok.regenerateCrownBearer(context)
	if Ragnarok.crownBearerID ~= nil and context:checkState("startOfTurn") then
		local crownBearer = Wargroove.getUnitById(Ragnarok.crownBearerID)
		local currentTurnPlayerId = Wargroove.getCurrentPlayerId()
		if currentTurnPlayerId == crownBearer.playerId or currentTurnPlayerId == Wargroove.getPlayerChildOf(crownBearer.playerId) then
			if crownBearer.health<crownBearer.unitClass.maxHealth then
                Wargroove.playMapSound("unitHealed", crownBearer.pos)
				crownBearer:setHealth(crownBearer.health+20,Ragnarok.crownBearerID)
				Wargroove.updateUnit(crownBearer)
                Wargroove.spawnMapAnimation(crownBearer.pos, 0, "fx/heal_unit")
                Wargroove.waitTime(0.2)
			end
		end
	end
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


function Ragnarok.resetOccurences()
	occurences = {}
end

function Ragnarok.didItOccur(occation)
	--print("didItOccur starts here")
	--print(occation)
	--print(dump(occurences,1))
	return occurences[occation] ~= nil
end

function Ragnarok.reportOccation(occation)
	--print("reportOccation starts here")
	--print(Ragnarok.didItOccur(occation))
	occurences[occation] = true
	--print(dump(occurences,1))
	--print(Ragnarok.didItOccur(occation))
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

function Ragnarok.addAIToCantAttackBuildings(playerId)
	cantAttackBuildingsSet[tostring(playerId)] = true
end

function Ragnarok.addGoldRobbed(playerId, amount)
	--print("addGoldRobbed starts here")
	--print("Player Id:")
	--print(playerId)
	--print("type")
	--print(type(playerId))
	--print("Amount To be deposited:")
	--print(amount)
	--print("type")
	--print(type(amount))
	if goldRobbed[playerId] then
		--print("Total Deposited:")
		--print(goldRobbed[playerId])
		--print("type")
		--print(type(goldRobbed[playerId]))
		goldRobbed[playerId] = goldRobbed[playerId]+amount
	else
		--print("No Player with ID")
		goldRobbed[playerId] = amount
	end
	--print(goldRobbed[playerId])
end

function Ragnarok.getGoldRobbed(playerId)
	--print("getGoldRobbed starts here")
	local robbedMoney = goldRobbed[playerId]
	--print(robbedMoney)
	--print("type")
	--print(type(robbedMoney))
	if robbedMoney then return robbedMoney end
	return 0
end

function Ragnarok.cantAttackBuildings(playerId)
	if cantAttackBuildingsSet[tostring(playerId)] then return true end
	return false
end

function Ragnarok.getCrownPos()
	if Ragnarok.crownID ~= nil then
		local crown = Wargroove.getUnitById(Ragnarok.crownID)
		if crown ~= nil then
			return Ragnarok.crownPos
		end
	end

	if Ragnarok.crownBearerID ~= nil then
		local crownBearer = Wargroove.getUnitById(Ragnarok.crownBearerID)
		if crownBearer ~= nil then
			return crownBearer.pos
		end
	end
	
	return nil
end

function Ragnarok.hasCrown(unit)
	return Ragnarok.crownBearerID and Ragnarok.crownBearerID == unit.id 
end

function Ragnarok.removeCrown()
--	print("removeCrown function starts here")
--	print(Ragnarok.crownBearerID)
	if Ragnarok.crownID ~= nil then
		local crown = Wargroove.getUnitById(Ragnarok.crownID)
		if crown ~= nil then
			crown.health = 0
			Wargroove.updateUnit(crown)
		end
	end
	if Ragnarok.crownBearerID then
		local crownBearer = Wargroove.getUnitById(Ragnarok.crownBearerID)
--		print(dump(crownBearer,0))
		if crownBearer ~= nil then
			for i, _stateKey in ipairs(crownBearer.state) do
				if (_stateKey.key == crownStateKey) then
					_stateKey.value = nil
					_stateKey.key = nil
					_stateKey = nil
				end
			end

			if Wargroove.hasUnitEffect(crownBearer.id, crownAnimation) then
				Wargroove.deleteUnitEffectByAnimation(crownBearer.id, crownAnimation)
			end
			Wargroove.updateUnit(crownBearer)
		end
	end
	Ragnarok.crownID = nil
	Ragnarok.crownBearerID = nil
end

function Ragnarok.dropCrown(targetPos)
	--print("dropCrown function starts here")
	Ragnarok.removeCrown()
	--print("removed Crown")
	--local startingState = {}
    --local pos = {key = "pos", value = "" .. targetPos.x .. "," .. targetPos.y}
    --table.insert(startingState, pos)
	Ragnarok.crownID = Wargroove.spawnUnit(-1, {x = targetPos.x-100, y = targetPos.y-100}, "crown", false)
	Wargroove.setVisibleOverride(Ragnarok.crownID, true)
	--print("Spawned Crown")
	Wargroove.spawnUnitEffect(Ragnarok.crownID, crownOffsetAnimation, "idle", nil, true, false)
	--print("Added Crown Effect")
	
	Ragnarok.crownPos = targetPos
	--print("Crown Position updated")
	Ragnarok.crownBearerID = nil
	--print("Nobody is carrying the crown anymore")
	return Ragnarok.crownID
end

function Ragnarok.grabCrown(unit)
--	print("grabCrown function starts here")
	Ragnarok.removeCrown()
	Wargroove.setUnitState(unit, crownStateKey, "")
	if not Wargroove.hasUnitEffect(unit.id, crownAnimation) then
		Wargroove.spawnUnitEffect(unit.id, crownAnimation, "idle", nil, true, false)
	end
	Ragnarok.crownBearerID = unit.id
	Wargroove.updateUnit(unit)
	return
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
--	print("Ragnarok.setupGizmos(context)")
    for i, gizmo in pairs(Wargroove.getGizmosAtLocation(nil)) do
		if gizmo.type == "pressure_plate" then
--			print("Found pressure_plate")
			gizmoModeList[Ragnarok.generateGizmoKey(gizmo)] = "stoodOn"
		end
		if gizmo.type == "lever" then
--			print("Found lever")
			gizmoModeList[Ragnarok.generateGizmoKey(gizmo)] = "stoodOn"
		end
    end
end


function Ragnarok.updateGizmos(context)
--	print("Ragnarok.updateGizmos(context)")
    for i, gizmo in pairs(Wargroove.getGizmosAtLocation(nil)) do
		if gizmoModeList[Ragnarok.generateGizmoKey(gizmo)] ~= nil then
			if gizmoModeList[Ragnarok.generateGizmoKey(gizmo)] == "stoodOn" then
--				print("Gizmo type: " .. gizmo.type)
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
	-- print("Ragnarok.setState(gizmo, state, playSound)") 
	-- print("Gizmo type: " .. gizmo.type)
	-- print("New State: " .. tostring(state))
	if lockedGizmos[Ragnarok.generateGizmoKey(gizmo)] == true then
		return {changedState = false, soundPlayed = false}
	end
	if playSound == nil then playSound = true end
	--print("Ragnarok.setState(gizmo,state) starts here")
	--print(invertedVisualGizmos[Ragnarok.generateGizmoKey(gizmo)]) 
	local changedState = Ragnarok.getInternalGizmoState(gizmo) ~= state
	local soundPlayed
--	print(changedState)
	if changedState then
--		print("changedState") 
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
--		print("playSound") 
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
   print("crownPos:")
   print(dump(Ragnarok.crownPos,1))
   print("crownBearerID:",Ragnarok.crownBearerID)
   print("")
end

function Ragnarok.setFlareCount(playerId, count)
	flareCountTable[playerId] = count
end

function Ragnarok.addFlare(playerId)
	if flareCountTable[playerId] then
		flareCountTable[playerId] = flareCountTable[playerId] + 1
	else
		flareCountTable[playerId] = 1
	end
end

function Ragnarok.removeFlare(playerId)
	if flareCountTable[playerId] then
		flareCountTable[playerId] = math.max(flareCountTable[playerId] - 1,0)
	else
		flareCountTable[playerId] = 0
	end
end

function Ragnarok.getFlareCount(playerId)
	if flareCountTable[playerId] then
		return flareCountTable[playerId]
	end
	return 0
end

function Ragnarok.moveInArch(unitId, startPos, targetPos, numSteps, speed, gravity, xyGamma, zGamma, eventPackages)

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

function dump(o,level)
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

return Ragnarok
