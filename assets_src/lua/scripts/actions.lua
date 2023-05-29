local Wargroove = require "wargroove/wargroove"
local Combat = require "wargroove/combat"
local Events = require "wargroove/events"
local Resumable = require"wargroove/resumable"
local Ragnarok = require "initialized/ragnarok"
local Rescue = require "verbs/rescue"
local Recruit = require "initialized/recruit"
local AIManager = require "initialized/ai_manager"
local StealthManager = require "scripts/stealth_manager"
local VisionTracker = require "initialized/vision_tracker"
local Pathfinding = require "util/pathfinding"
local Corners = require "scripts/corners"
local Stats = require "util/stats"

local Actions = {}

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


-- This is called by the game when the map is loaded.
function Actions.init()
  Events.addToActionsList(Actions)
end

function Actions.populate(dst)
    dst["ai_set_no_building_attacking"] = Actions.setNoBuildingAttacking
    dst["enable_hiring"] = Actions.enableHiring
    dst["set_state"] = Actions.setState
    dst["transfer_gold_robbed"] = Actions.transferGoldRobbed
	dst["log_message"] = Actions.logMessage
	dst["message_counter"] = Actions.messageCounter
	dst["dialogue_box_with_counter"] = Actions.dialogueBoxWithCounter
	dst["change_objective_with_3_counters"] = Actions.changeObjectiveWith3Counters
	dst["give_crown"] = Actions.giveCrown
	dst["link_gizmo_state_with_activators"] = Actions.linkGizmoStateWithActivators
	dst["gizmo_active_when_stood_on"] = Actions.gizmoActiveWhenStoodOn
	dst["gizmo_toggle_when_stood_on"] = Actions.gizmoToggleStateWhenMovedTo
	dst["invert_gizmo"] = Actions.invertGizmo
	dst["set_threat_at_location"] = Actions.setThreatAtLocation
	dst["spawn_unit"] = Actions.spawnUnit
	dst["split_into"] = Actions.splitInto
	dst["spawn_unit_in_transport"] = Actions.spawnUnitInsideTransport
	dst["spawn_unit_close"] = Actions.spawnUnitClose
	dst["force_action"] = Actions.forceAction
	dst["place_crown"] = Actions.placeCrown
	dst["modify_flare_count"] = Actions.modifyFlareCount
	dst["modify_healing_potion_count"] = Actions.modifyHealingPotionCount
	dst["enable_AI_fog_limitations"] = Actions.enableAIFogLimitations
	dst["reveal_all"] = Actions.revealAll
	dst["reveal_all_but_hidden"] = Actions.revealAllButHidden
	dst["reveal_all_but_over"] = Actions.revealAllButOver
	dst["set_override_visibility"] = Actions.setOverrideVisibility
	dst["unset_override_visibility"] = Actions.unsetOverrideVisibility
	dst["allow_pirate_ships"] = Actions.allowPirateShips
    dst["ai_set_restriction"] = Actions.aiSetRestriction
	dst["set_location_to_vision"] = Actions.setLocationToVision
	dst["set_location_to_spawned"] = Actions.setLocationToSpawned
	dst["dialogue_box_unit"] = Actions.dialogueBoxUnit
	dst["set_match_seed"] = Actions.setMatchSeed
	dst["set_priority_target"] = Actions.setPriorityTarget
    dst["display_path"] = Actions.displayPath
    dst["let_neutral_units_move"] = Actions.letNeutralUnitsMove
	dst["set_hide_and_seek"] = Actions.setHideAndSeek
    dst["set_hide_and_seek_bravery"] = Actions.setHideAndSeekBravery
    dst["set_position_as_goal"] = Actions.setPositionAsGoal
    dst["set_awareness"] = Actions.setAwareness
    dst["limit_bounds"] = Actions.limitBounds
--    dst["set_awareness_wave"] = Actions.setAwarenessWave
    dst["update_awareness"] = Actions.updateAwareness
    dst["set_current_position_as_goal"] = Actions.setCurrentPositionAsGoal
    dst["give_bounty"] = Actions.giveBounty
    dst["force_move"] = Actions.forceMove
    dst["force_attack"] = Actions.forceAttack
    dst["ai_set_profile"] = Actions.setAIProfileWithBuild
    dst["run_group_sequentially"] = Actions.runGroupSequentially
    dst["run_group_concurrently"] = Actions.runGroupConcurrently
    dst["end_group"] = Actions.endGroup
	--Hidden actions
	dst["run_start_front_actions"] = Actions.runStartFrontActions
	dst["run_start_back_actions"] = Actions.runStartBackActions
	dst["run_repeat_front_actions"] = Actions.runRepeatFrontActions
	dst["run_repeat_back_actions"] = Actions.runRepeatBackActions
	dst["run_end_front_actions"] = Actions.runEndFrontActions
	dst["run_end_back_actions"] = Actions.runEndBackActions
	dst["reset_occurence_list"] = Actions.resetOccurenceList
	dst["reset_rescue_list"] = Actions.resetRescueList
end



function Actions.aiSetRestriction(context)
    -- "Set AI restriction of {0} at {1} for {2}: Set {3} to {4}"
    local restriction = context:getString(3)
    print(restriction)
    local value = context:getBoolean(4)
    local units = context:gatherUnits(2, 0, 1)

    for i, unit in ipairs(units) do
        Wargroove.setAIRestriction(unit.id, restriction, value)
    end

    Wargroove.updateUnits(units)
end

--Local stuff
local function findCentreOfLocation(location)
    local centre = { x = 0, y = 0 }
    for i, pos in ipairs(location.positions) do
        centre.x = centre.x + pos.x
        centre.y = centre.y + pos.y
    end
    centre.x = centre.x / #(location.positions)
    centre.y = centre.y / #(location.positions)
    local bestSqrDist = 100^2
    local bestPos = { x = 0, y = 0 }
    for i, pos in ipairs(location.positions) do
        local sqrDist = (pos.x-centre.x)^2+(pos.y-centre.y)^2
        if sqrDist < bestSqrDist then
            bestPos.x = pos.x
            bestPos.y = pos.y
            bestSqrDist = sqrDist
        end
    end
    return bestPos
end

local function spawnUnitCompareBestLocation(a, b)
--	return a.dist < b.dist
	if a.dist ~= b.dist then return a.dist < b.dist end
	if a.pos.y ~= b.pos.y then return a.pos.y < b.pos.y end
	return a.pos.x < b.pos.x
end
--

function Actions.setNoBuildingAttacking(context)
    local targetPlayer = context:getPlayerId(0)
	Ragnarok.addAIToCantAttackBuildings(targetPlayer)
end

function Actions.enableHiring(context)
    -- "Let player {0} hire villagers."
    local playerId = context:getPlayerId(0)
	local Hire = require "verbs/hire"
    Hire.enableForPlayer(playerId)
end

function Actions.allowPirateShips(context)
    -- "Let AI of player {0} build raider ships."
    local targetPlayer = context:getPlayerId(0)
	Recruit:allowAIToBuildRaiderShips(targetPlayer)
end

function Actions.enableAIFogLimitations(context)
    -- "Enable AI fog Limitations"
	Ragnarok.setFogOfWarRules(true)
end

function Actions.resetOccurenceList(context)
    -- "Hidden action"
	Ragnarok.resetOccurences()
end

function Actions.resetRescueList(context)
    -- "Hidden action"
	Rescue.resetRescued()
end

function Actions.runStartFrontActions(context)
    -- "Hidden action"
	local actions = Ragnarok.getActions().start_of_match.front
    for i, action in ipairs(actions) do
        action(context)
    end
end

function Actions.runStartBackActions(context)
    -- "Hidden action"
	local actions = Ragnarok.getActions().start_of_match.back
    for i, action in ipairs(actions) do
        action(context)
    end
end

function Actions.runRepeatFrontActions(context)
    -- "Hidden action"
	local actions = Ragnarok.getActions().repeating.front
    for i, action in ipairs(actions) do
        action(context)
    end
end

function Actions.runRepeatBackActions(context)
    -- "Hidden action"
	local actions = Ragnarok.getActions().repeating.back
    for i, action in ipairs(actions) do
        action(context)
    end
end

function Actions.runEndFrontActions(context)
    -- "Hidden action"
	local actions = Ragnarok.getActions().end_of_match.front
    for i, action in ipairs(actions) do
        action(context)
    end
end

function Actions.runEndBackActions(context)
    -- "Hidden action"
	local actions = Ragnarok.getActions().end_of_match.back
    for i, action in ipairs(actions) do
        action(context)
    end
end

function Actions.setOverrideVisibility(context)
    -- "Override visibility to {3} for unit type(s) {0} at location {1} owned by player {2}."

    -- The context contains an ordered table of values and has accessor methods for various types.
    local units = context:gatherUnits(2, 0, 1)  -- A useful function for gathering units of type, location, and player
    local visible = context:getBoolean(3)
    for i, unit in ipairs(units) do
        Wargroove.setVisibleOverride(unit.id, visible)
    end
end

function Actions.unsetOverrideVisibility(context)
    -- "Disable Override visibility for unit type(s) {0} at location {1} owned by player {2}."

    -- The context contains an ordered table of values and has accessor methods for various types.
    local units = context:gatherUnits(2, 0, 1)  -- A useful function for gathering units of type, location, and player
    for i, unit in ipairs(units) do
        Wargroove.unsetVisibleOverride(unit.id)
    end
end
function Actions.revealAll(context)
    -- "Spawn an eye at location {1} for player {0} seeing all."
    -- local allUnits = Wargroove.getAllUnitIds()
    -- for i, id in ipairs(allUnits) do
		-- Wargroove.setVisibleOverride(id, true)
    -- end
	-- Wargroove.updateFogOfWar(0)
	-- coroutine.yield()
	-- coroutine.yield()
    local playerId = context:getPlayerId(0)
    local location = context:getLocation(1)
    local revealerId = Wargroove.spawnUnit(playerId, findCentreOfLocation(location), "reveal_all", false)
	Wargroove.setVisibleOverride(revealerId, false)

	Wargroove.setShadowVisible(revealerId, false)
	coroutine.yield()
	coroutine.yield()
	Wargroove.updateFogOfWar(0)
    -- Wargroove.clearCaches()
	-- coroutine.yield()
	-- coroutine.yield()
	-- Wargroove.updateFogOfWar(0)
	-- coroutine.yield()
	-- coroutine.yield()
    -- Wargroove.clearCaches()
	-- Wargroove.removeUnit(revealerId)
    -- for i, id in ipairs(allUnits) do
		-- Wargroove.unsetVisibleOverride(id)
    -- end
end

local idOffset = 0
function Actions.revealAllButHidden(context)
    -- "Spawn an eye at location {1} for player {0} seeing all except hidden tiles."
    local playerId = context:getPlayerId(0)
    local location = context:getLocation(1)
	local spawnLocation = findCentreOfLocation(location)
	local hidingSpotId = Wargroove.getUnitIdAtXY(spawnLocation.x, spawnLocation.y)
	local oldHidingSpot = Wargroove.getUnitById(hidingSpotId)
    local revealerId = Wargroove.spawnUnit(playerId, spawnLocation, "reveal_all_but_hidden", false)
	Wargroove.clearCaches()
	if hidingSpotId ~= Wargroove.getUnitIdAtXY(spawnLocation.x, spawnLocation.y) then
		Wargroove.removeUnit(hidingSpotId)
		Wargroove.removeUnit(revealerId)
		hidingSpotId = Wargroove.spawnUnit(playerId, spawnLocation, hidingSpot.unitClassId, false)
		hidingSpot = Wargroove.getUnitById(hidingSpotId)
		hidingSpot.pos.x = oldHidingSpot.pos.x
		hidingSpot.pos.y = oldHidingSpot.pos.y
		Wargroove.updateUnit(hidingSpot)
		revealerId = Wargroove.spawnUnit(playerId, spawnLocation, "reveal_all_but_hidden", false)
	end
	Wargroove.setVisibleOverride(revealerId, false)

	Wargroove.setShadowVisible(revealerId, false)
	coroutine.yield()
	coroutine.yield()
	Wargroove.updateFogOfWar(0)
end

function Actions.revealAllButOver(context)
    -- "Spawn an eye at location {1} for player {0} seeing all it has direct line of sight to."
    local playerId = context:getPlayerId(0)
    local location = context:getLocation(1)
    local revealerId = Wargroove.spawnUnit(playerId, findCentreOfLocation(location), "reveal_all_but_over", false)
	Wargroove.setVisibleOverride(revealerId, false)

	Wargroove.setShadowVisible(revealerId, false)
	coroutine.yield()
	coroutine.yield()
	Wargroove.updateFogOfWar(0)
end

function Actions.setLocationToVision(context)
    -- "Set location {0} to the vision of player {1}."
    local location = context:getLocation(0)
    local playerId = context:getPlayerId(1)

	local mapSize = Wargroove.getMapSize()
	local allTiles = {}
	for x=0, mapSize.x-1 do
		for y=0, mapSize.y-1 do
			allTiles[x+mapSize.x*y+1] = {x=x,y=y}
		end
	end
	local visibleTiles = {}
	for j, checkedTile in ipairs(allTiles) do
		if VisionTracker.canSeeTile(playerId,checkedTile) then
			table.insert(visibleTiles,checkedTile)
		end
	end
	location:setArea(visibleTiles)
end

function Actions.setLocationToSpawned(context)
    -- "Set location {0} to the spawned units this update."
    local location = context:getLocation(0)
    print("Actions.setLocationToSpawned(context)")
    print(dump(context.spawnedUnits,0))
	location:setArea(context.spawnedUnits)
end

function Actions.setState(context)
    -- "Add set state {3} to {4} for unit type(s) {0} at location {1} owned by player {2}."

    -- The context contains an ordered table of values and has accessor methods for various types.
    local units = context:gatherUnits(2, 0, 1)  -- A useful function for gathering units of type, location, and player
    local stateKey = context:getString(3)       -- Gets a string
    local stateValue = context:getString(4)
    for i, unit in ipairs(units) do
        Wargroove.setUnitState(unit, stateKey, stateValue)
        Wargroove.updateUnit(unit)
    end
end

function Actions.giveCrown(context)
    -- "Give the crown to units of type {0} at location {1} owned by player {2}."

    -- The context contains an ordered table of values and has accessor methods for various types.
    local units = context:gatherUnits(2, 0, 1)  -- A useful function for gathering units of type, location, and player
    for i, unit in ipairs(units) do
        Ragnarok.grabCrown(unit)
		return
    end
end

function Actions.placeCrown(context)
    -- "Place the crown location {0}."
    local location = context:getLocation(0)
    local centerPos = findCentreOfLocation(location)
	Ragnarok.dropCrown(centerPos)
end

function Actions.setMatchSeed(context)
    -- "Set Match Seed to {0}."
    local seed = context:getInteger(0)
	Wargroove.setMatchSeed(seed)
end
function Actions.setPriorityTarget(context)
    -- "Give units of type {0} at location {1} owned by player {2} {4} orders to go to location {3}."
    local targetPos = findCentreOfLocation(context:getLocation(3))
    local order = context:getString(4)
    local units = context:gatherUnits(2, 0, 1)
    for i, unit in ipairs(units) do
        print("new order")
        print(order)
        print(unit.playerId) 
        print(unit.id) 
        print(unit.unitClassId) 
        if order == "attack move" then
            AIManager.attackMoveOrder(unit.id,targetPos)
        end
        if order == "move" then
            AIManager.moveOrder(unit.id,targetPos)
        end
        if order == "road move" then
            AIManager.roadMoveOrder(unit.id,targetPos)
        end
        if order == "retreat" then
            AIManager.retreatOrder(unit.id)
        end
        if order == "clear" then
            AIManager.clearOrder(unit.id)
        end
        print(dump(AIManager.getOrder(unit.id),0)) 
    end
end

function Actions.displayPath(context)
    -- "Display path for units of type {0} at location {1} owned by player {2}"
    local units = context:gatherUnits(2, 0, 1)
    for i, unit in ipairs(units) do
        local path = AIManager.getPath(unit.id)
        local playerId = unit.playerId
        if playerId ==-1 then
            playerId = 0
        end
        if path~=nil then
            Wargroove.trackCameraTo(path[#path])
            local lastTile = nil
            for j, tile in ipairs(path) do
                local nextTile = path[j+1]
                if lastTile~=nil then
                    if nextTile~=nil then
                        local cornerPos = {x = 24*(lastTile.x+nextTile.x-2*tile.x)/8,y = 24*(lastTile.y+nextTile.y-2*tile.y)/8}
                        Wargroove.displayBuffVisualEffectAtPosition(unit.id, tile, playerId, "units/PathArrows/C", "spawn", 1, nil, nil, cornerPos)
                        Wargroove.waitTime(0.05)    
                    else
                        Wargroove.displayBuffVisualEffectAtPosition(unit.id, tile, playerId, "units/PathArrows/X", "spawn", 1)
                    end
                else
                    Wargroove.displayBuffVisualEffectAtPosition(unit.id, tile, playerId, "units/PathArrows/C", "spawn", 1)
                    Wargroove.waitTime(0.05)
                end
                lastTile = tile
            end
            Wargroove.waitTime(0.5)
            Wargroove.clearBuffVisualEffect(unit.id)
            break
        end
    end
end

function Actions.letNeutralUnitsMove(context)
    -- "Let neutral units move using orders"
    AIManager.letNeutralUnitsMove()
end

local bountyMap = {
    soldier = 50,
    spearman = 100,
    mage = 125,
    archer = 150,
    knight = 150,
    rifleman = 200,
    ballista = 200,
    balloon = 100,
    harpoonship = 150,
    harpy = 150,
    merman = 100,
    thief = 100,
    travelboat = 300,
    trebuchet = 200,
    wagon = 300,
    warship = 200,
    witch = 150,
    villager = 100
}

function Actions.giveBounty(context)
    -- "Give units of type {0} at location {1} owned by player {2} a bounty."
    local units = context:gatherUnits(2, 0, 1)
    for i, unit in ipairs(units) do
        if bountyMap[unit.unitClassId] ~= nil then
            Wargroove.setUnitState(unit, "gold", bountyMap[unit.unitClassId])
            Wargroove.updateUnit(unit)
        end
    end
end

function Actions.forceMove(context)
    -- "Move units of type {0} at location {1} owned by player {2} to location {3}."
    local units = context:gatherUnits(2, 0, 1)
    local location = context:getLocation(3)
    local center = findCentreOfLocation(location)
    local coList = {}
    for i, unit in pairs(units) do
        coList[i] = coroutine.create(function ()
            local path = Pathfinding.AStar(unit, center)
            Pathfinding.forceMoveAlongPath(unit.id, path)
            return true
         end)
    end
    while next(coList) ~= nil do
        local toBeRemoved = {};
        for i, co in pairs(coList) do
            local errorFree, result = coroutine.resume(co)
            if errorFree == false then
                table.insert(toBeRemoved,i)
            end
        end
        for i, id in ipairs(toBeRemoved) do
            coList[id] = nil
        end
        coroutine.yield()
    end
end

function Actions.forceAttack(context)
    -- "Force units of type {0} at location {1} owned by player {2} to attack units of type {3} at location {4} owned by player {5}."
    local units = context:gatherUnits(2, 0, 1)
    local targets = context:gatherUnits(5, 3, 4)
    local unit = units[1]
    local target = targets[1]
    if (unit == nil) or (target == nil) then
        return
    end
    --- Telegraph
    if (not Wargroove.isLocalPlayer(unit.playerId)) and Wargroove.canCurrentlySeeTile(target.pos) then
        Wargroove.spawnMapAnimation(target.pos, 0, "ui/grid/selection_cursor", "target", "over_units", {x = -4, y = -4})
        Wargroove.waitTime(0.5)
    end
    local originalPos = unit.pos
    local dist = math.sqrt((target.pos.x-unit.pos.x)^2 + (target.pos.y-unit.pos.y)^2)
    Wargroove.playMapSound("unitAttack",target.pos)
    Wargroove.moveUnitToOverride(unit.id, unit.pos, 0.5*(target.pos.x-unit.pos.x)/dist, 0.5*(target.pos.y-unit.pos.y)/dist, 4)
    while Wargroove.isLuaMoving(unit.id) do
      coroutine.yield()
    end
    local results = Combat:solveCombat(unit.id, target.id, {originalPos}, "random")
    unit:setHealth(results.attackerHealth,target.id)
    if results.attackerHealth<= 0 then
        Wargroove.playUnitDeathAnimation(unit.id)
        if (unit.unitClass.isCommander) then
            Wargroove.playMapSound("commanderDie", unit.pos)
        end
    end
    
    if target.health>results.defenderHealth then
        Wargroove.playUnitAnimation(target.id,"hit")
        Wargroove.playMapSound("hitOrganic",target.pos)
    end
    target:setHealth(results.defenderHealth,unit.id)
    if results.defenderHealth<= 0 then
        Wargroove.playUnitDeathAnimation(target.id)
        if (target.unitClass.isCommander) then
            Wargroove.playMapSound("commanderDie", target.pos)
        end
    end
    --Wargroove.startCombat(unit, target, {unit.pos})
    Wargroove.updateUnit(unit)
    Wargroove.updateUnit(target)
    Wargroove.moveUnitToOverride(unit.id, unit.pos, 0, 0, 4)
    Wargroove.waitTime(1)
    if results.attackerHealth<= 0 then
        Wargroove.removeUnit(unit.id)
    end
    if results.defenderHealth<= 0 then
        Wargroove.removeUnit(target.id)
    end

    Wargroove.setMetaLocationArea("last_move_path", {unit.pos})
    Wargroove.setMetaLocation("last_unit", unit.pos)
end

function Actions.runGroupSequentially(context)
end

function Actions.runGroupConcurrently(context)
end

function Actions.endGroup(context)
end

function Actions.setCurrentPositionAsGoal(context)
    -- "Make units of type {0} at location {1} owned by player {2} stand guard."
    local units = context:gatherUnits(2, 0, 1)
    for i, unit in ipairs(units) do
        StealthManager.setAIGoalPos("road_move",unit.id,unit.pos)
    end
end

function Actions.setPositionAsGoal(context)
    -- "Make units of type {0} at location {1} owned by player {2} {5} towards {3} at {4} tiles per turn."
    local units = context:gatherUnits(2, 0, 1)
    local location = context:getLocation(3)
    local maxSpeed = context:getInteger(4)
    local order = context:getString(5)
    local center = findCentreOfLocation(location)
    for i, unit in ipairs(units) do
        AIManager.order(order, unit.id, center, maxSpeed)
        StealthManager.setAIGoalPos(order, unit.id,center,maxSpeed)
    end
end

function Actions.setAwareness(context)
    -- "Sets awareness of units of type {0} at location {1} owned by player {2} to {3} from {5}. (Force = {4})"
    local units = context:gatherUnits(2, 0, 1)
    local string = context:getString(3)
    local force = context:getBoolean(4)
    local location = context:getLocation(5)
    local center = findCentreOfLocation(location)
    for i, unit in ipairs(units) do
        StealthManager.setLastKnownLocation(unit.id, center)
        if string == "fleeing" then
            StealthManager.makeFleeing(unit.id)
        elseif string == "alerted" then
            StealthManager.makeAlerted(unit.id,force)
        elseif string == "searching" then
            StealthManager.makeSearching(unit.id,force)
        elseif string == "unaware" then
            StealthManager.makeUnaware(unit.id)
        end
    end
    local function comp(a, b)
        local sqrDistA = (a.pos.x-center.x)^2+(a.pos.y-center.y)^2
        local sqrDistB = (b.pos.x-center.x)^2+(b.pos.y-center.y)^2
        return sqrDistA<sqrDistB
    end
    table.sort(units, comp)
    local lastDist = nil
    for i, unit in ipairs(units) do
        local dist = math.sqrt((unit.pos.x-center.x)^2+(unit.pos.y-center.y)^2)
        if lastDist~= nil then
           Wargroove.waitTime((dist-lastDist)/20) 
        end
        StealthManager.updateAwareness(unit.id)
        lastDist = dist
    end
end

function Actions.updateAwareness(context)
    -- "Update awareness"
    local units = Wargroove.getUnitsAtLocation();
    for i, unit in ipairs(units) do
        if unit.playerId == 0 then
            StealthManager.awarenessCheck(unit.id,{unit.pos})
        end
    end
    StealthManager.updateAwarenessAll()
end
function Actions.setHideAndSeek(context)
    -- "Is hide and seek rules for player {1} enabled {0}"
    local active = context:getBoolean(0)
    local player = context:getPlayerId(1)
    StealthManager.setActive(player,active)
    for x = 0,Wargroove.getMapSize().x do
        for y = 0,Wargroove.getMapSize().y do
            local unitId = Wargroove.spawnUnit(player,{x=-200+x,y=-200+y},"stealth_rules",false)
            
            local corners = Corners.getVisionCorner(player, {x=x,y=y})
            local cornerName = Corners.getCornerName(corners)
            if Corners.cornerList[unitId] ~= cornerName then
                if (cornerName~=nil) and (cornerName ~= "") and (cornerName ~= "NE_NW_SE_SW") then
                    Wargroove.displayBuffVisualEffectAtPosition(unitId, {x=x-1,y=y+100-1}, player, "units/LoSBorder/"..Corners.getCornerName(corners), "", 0.5, nil, nil, {x = 0, y = 0},true)
                end
                Corners.cornerList[unitId] = cornerName
            end
        end
    end
    for i,unit in ipairs(Wargroove.getUnitsAtLocation(nil)) do
        if not StealthManager.isCivilian(unit.unitClassId) then
            StealthManager.setAIGoalPos(unit.id,unit.pos)
        end
    end
end
function Actions.setHideAndSeekBravery(context)
    -- "Set hide and seek bravery for player {1} to {0}"
    local bravery = context:getInteger(0)
    local player = context:getPlayerId(1)
    StealthManager.setBravery(player, bravery)
end
function Actions.limitBounds(context)
    -- "Limit playable area for player {1} to {0}"
    local location = context:getLocation(0)
    local player = context:getPlayerId(1)
 
    local Verb = require "initialized/a_new_verb"
    Verb.setBorderLands(location, player)
end

function Actions.transferGoldRobbed(context)
    -- "Transfer gold robbed by {0}: {1}{2}"
    local playerId = context:getPlayerId(0)
    local transfer = context:getString(1)
    local value = context:getMapCounter(2)

	if transfer == "store" then
		context:setMapCounter(2, Ragnarok.getGoldRobbed(playerId))
	end
end

local HealingPotion = require "verbs/healing_potion"
function Actions.modifyHealingPotionCount(context)
    -- "Modify the number of healing potions owned by {0}"
    local playerId = context:getPlayerId(0)
    local operation = context:getOperation(1)
    local value = context:getInteger(2)
    local previous = HealingPotion.getCharges(playerId)
	HealingPotion.setCharges(playerId, operation(previous, value))
end


function Actions.setAIProfileWithBuild(context)
    -- "Set the AI profile with a custom build order for {0} to {1}."
    local targetPlayer = context:getPlayerId(0)
    local profile = context:getString(1)
    if profile == "mangrove_madness" then
        local AIProfile = require "AIProfiles/mangroveMadness"
        AIProfile.setProfile()
    end
    if profile == "city_passive" then
        local AIProfile = require "AIProfiles/cityPassive"
        AIProfile.setProfile()
    end
    if profile == "city_war" then
        local AIProfile = require "AIProfiles/cityWar"
        AIProfile.setProfile()
    end
    
    Wargroove.setAIProfile(targetPlayer, profile)
end

function Actions.modifyFlareCount(context)
    -- "Modify the number of flares owned by {0}: {1}{2}"
    local playerId = context:getPlayerId(0)
    local operation = context:getOperation(1)
    local value = context:getInteger(2)
    local previous = Ragnarok.getFlareCount(playerId)
	Ragnarok.setFlareCount(playerId, operation(previous, value))
end

function Actions.logMessage(context)
    -- "Write to log message: {0}"
    print(context:getString(0))
end

function Actions.messageCounter(context)
    -- "Display message: \"{0}\" and then counter {1}."
    local value = context:getMapCounter(1)
    Wargroove.showMessage(context:getString(0) .. tostring(value))
end

function Actions.dialogueBoxWithCounter(context)
    -- "Display dialogue box with {0} {1} saying \"{2}\" with shout: {3}. Use counter {4}."
    Wargroove.showDialogueBox(context:getString(0), context:getString(1), context:getString(2) .. tostring(context:getMapCounter(4)), context:getString(3))
end

function Actions.changeObjectiveWith3Counters(context)
    -- "Sets the map objective to {0} ({1}) {2} ({3}) {4}."
	local counter1 = math.floor(context:getMapCounter(0)+0.5)
	local counter1enroute = math.floor(context:getMapCounter(1)+0.5)
	local counter2 = math.floor(context:getMapCounter(2)+0.5)
	local counter2enroute = math.floor(context:getMapCounter(3)+0.5)
	local counter3 = math.floor(context:getMapCounter(4)+0.5)
	local superString = "Win the Pirate Bout!\nStolen by Wulfar: "..tostring(counter1)
	if counter1enroute ~= 0 then
		superString = superString.." ("..tostring(counter1enroute).." enroute)"
	end
	superString = superString.."\nStolen by Rival: "..tostring(counter2)
	if counter2enroute ~= 0 then
		superString = superString.." ("..tostring(counter2enroute).." enroute)"
	end
	superString = superString.."\nVillage Gold: "..tostring(counter3)

    Wargroove.changeObjective(superString)
end

function Actions.linkGizmoStateWithActivators(context)
    -- "Link all gizmos with the activators at location {0}. (Lock when activated? = {1})"
    local location = context:getLocation(0)
    local locked = context:getBoolean(1)
	Ragnarok.addLinkedLocation(location,locked)
end

function Actions.gizmoActiveWhenStoodOn(context)
    -- "Activate Gizmos at location {0} if a unit or crown stands on them. (Invert? = {1})"
	local location = context:getLocation(0)
    local inverted = context:getBoolean(1)
	
    for i, gizmo in ipairs(Wargroove.getGizmosAtLocation(location)) do
		Ragnarok.setActivator(gizmo, true)
		local unit = Wargroove.getUnitAt(gizmo.pos)
		local crownPos = Ragnarok.getCrownPos()
		local isCrown = crownPos and (crownPos.x == gizmo.pos.x) and (crownPos.y == gizmo.pos.y)
		local isPressed = isCrown or unit ~= nil
		Ragnarok.setState(gizmo,isPressed)
    end
end

local toggleClear = {}

function Actions.gizmoToggleStateWhenMovedTo(context)
    -- "Gizmos toggle when unit moves to location {0}."
	local location = context:getLocation(0)
	--local lastMovePathLocation =  Wargroove.getLocationById(4)
	local lastUnitUsedLocation =  Wargroove.getLocationById(-5)
    for i, gizmo in ipairs(Wargroove.getGizmosAtLocation(location)) do
		if toggleClear[Ragnarok.generateGizmoKey(gizmo)] == nil then
			toggleClear[Ragnarok.generateGizmoKey(gizmo)] = Wargroove.getUnitAt(gizmo.pos) == nil
		end
		Ragnarok.setActivator(gizmo, true)
		local atPath = false
		local lastUnitUsed = nil
		for i, gizmoAtPath in ipairs(Wargroove.getGizmosAtLocation(lastUnitUsedLocation)) do
			if Ragnarok.generateGizmoKey(gizmoAtPath) == Ragnarok.generateGizmoKey(gizmo) then
				atPath = true
				lastUnitUsed = Wargroove.getUnitAt(gizmoAtPath.pos)
				break
			end
		end
		if lastUnitUsed ~= nil and toggleClear[Ragnarok.generateGizmoKey(gizmo)] ~= (Wargroove.getUnitAt(gizmo.pos) == nil) then
			Ragnarok.setState(gizmo,not Ragnarok.getGizmoState(gizmo))
		end
		toggleClear[Ragnarok.generateGizmoKey(gizmo)] = Wargroove.getUnitAt(gizmo.pos) == nil
    end

end

function Actions.invertGizmo(context)
    -- "Invert active states of gizmos at location {0} (only output? = {1})"
	local location = context:getLocation(0)
	local onlyOutput = context:getBoolean(1)
	
    for i, gizmo in ipairs(Wargroove.getGizmosAtLocation(location)) do
		if onlyOutput then
			Ragnarok.invertOutputGizmo(gizmo)
		else
			Ragnarok.invertVisualGizmo(gizmo)
		end
    end

end


function Actions.setThreatAtLocation(context)
    -- "Sets the threat level of {0} to {1}, sourcing the owner as {2} at {3} owned by {4}"
    local units = context:gatherUnits(2, 3, 4)  -- A useful function for gathering units of type, location, and player
	local location = context:getLocation(0)
    local value = context:getInteger(1)
    local result = {}
	local chosenUnit = nil
	for i, unit in ipairs(units) do
		 chosenUnit = unit
	end
	if chosenUnit then
		for i, pos in ipairs(location.positions) do
			 table.insert(result, {position = {x = pos.x, y = pos.y},  value = value})
		end
		Wargroove.setThreatMap(chosenUnit.id, result)
	end
end



function Actions.spawnUnitInsideTransport(context)
    -- "Give units of type {0} at location {1} owned by player {2} unit type {3} owned by player {4} with {5} hp."
    local units = context:gatherUnits(2, 0, 1)
    local unitClassId = context:getUnitClass(3)
    local playerId = context:getPlayerId(4)
    local hp = context:getInteger(5)

    for i, transport in pairs(units) do
        print("transport")
        print(dump(transport,0))
        print("Spawning in")
        local pos = {x=-10,y=-10}
        while Wargroove.getUnitAt(pos)~= nil do
            pos.x = pos.x+1
        end
        local unitId = Wargroove.spawnUnit(playerId, pos, unitClassId, false)
        Wargroove.clearCaches()
        local unit = Wargroove.getUnitAt(pos)

        table.insert(transport.loadedUnits, unitId)
        unit.inTransport = true
        unit.transportedBy = transport.id
        unit.health = hp
        Wargroove.updateUnit(transport)
        unit.pos = { x = -100, y = -100 }
        Wargroove.updateUnit(unit)
        print("transport Post Update")
        print(dump(transport,0))
        print("unit Post Update")
        print(dump(unit,0))
    end
end

function Actions.spawnUnit(context)
    -- "Spawn {0} at {1} for {2} (silent = {3})"
    local unitClassId = context:getUnitClass(0)
    local location = context:getLocation(1)
    local playerId = context:getPlayerId(2)
    local silent = context:getBoolean(3)

    local candidates = {}

    if location == nil then
        -- No location, use centre of map
        local mapSize = Wargroove.getMapSize()
        local cX = math.floor(mapSize.x / 2)
        local cY = math.floor(mapSize.y / 2)
        for x = 0, mapSize.x - 1 do
            for y = 0, mapSize.y - 1 do
                local pos = { x = x, y = y }
                if Wargroove.getUnitIdAt(pos) == -1 and Wargroove.canStandAt(unitClassId, pos) then
                    local dx = x - cX
                    local dy = y - cY
                    local dist = math.abs(dx) + math.abs(dy)
                    table.insert(candidates, { pos = pos, dist = dist })
                end
            end
        end
    else
        -- Find the centre of the location
        local centre = findCentreOfLocation(location)

        -- All candidates
        for i, pos in ipairs(location.positions) do
            if Wargroove.getUnitIdAt(pos) == -1 and Wargroove.canStandAt(unitClassId, pos) then
                local dx = pos.x - centre.x
                local dy = pos.y - centre.y
                local dist = math.abs(dx) + math.abs(dy)
                table.insert(candidates, { pos = pos, dist = dist })
            end
        end
    end

    -- Sort candidates
    table.sort(candidates, spawnUnitCompareBestLocation)

    -- Spawn at the best candidate
    if #candidates > 0 then
        local pos = candidates[1].pos
        if not silent then
            Wargroove.trackCameraTo(pos)
        end
        local unitId = Wargroove.spawnUnit(playerId, pos, unitClassId, false)
        table.insert(context.spawnedUnits,pos)
        print("spawned unit")
        print(dump(context.spawnedUnits,0))
		local spawnedUnit = Wargroove.getUnitById(unitId);
		local mapSize = Wargroove.getMapSize()
		if pos.x>(mapSize.x/2) then
			-- spawnedUnit.startPos.facing = 1
			-- spawnedUnit.pos.facing = 1
			Wargroove.setFacingOverride(unitId, "left")
		else
			-- spawnedUnit.startPos.facing = 0
			-- spawnedUnit.pos.facing = 0
			Wargroove.setFacingOverride(unitId, "right")
		end
		--Wargroove.updateUnit(spawnedUnit)
        Wargroove.clearCaches()
        if silent or (not Wargroove.canCurrentlySeeTile(pos)) then
            -- Need to wait two frames to prevent being able to spawn on top of other units
            Wargroove.waitFrame()
            Wargroove.waitFrame()
        else
            Wargroove.spawnMapAnimation(pos, 0, "fx/mapeditor_unitdrop")
            Wargroove.playMapSound("spawn", pos)
            Wargroove.waitTime(0.5)
        end
    end
end

function Actions.splitInto(context)
    -- "Split {0} at {1} for {2} if on full health into {3}"
    local units = context:gatherUnits(2,0,1)
    local unitClassId = context:getUnitClass(3)
    for i,unit in pairs(units) do
        if unit.health == 100 then
            local pos = Pathfinding.findClosestOpenSpot(unitClassId,unit.pos)
            if pos ~= nil then
                Wargroove.trackCameraTo(pos)
                unit.health = 50
                Wargroove.updateUnit(unit)
                local unitId = Wargroove.spawnUnit(unit.playerId, pos, unitClassId, false)
                local mapSize = Wargroove.getMapSize()
                if pos.x>(mapSize.x/2) then
                    Wargroove.setFacingOverride(unitId, "left")
                else
                    Wargroove.setFacingOverride(unitId, "right")
                end
                Wargroove.clearCaches()
                if (not Wargroove.canCurrentlySeeTile(pos)) then
                    -- Need to wait two frames to prevent being able to spawn on top of other units
                    Wargroove.waitFrame()
                    Wargroove.waitFrame()
                else
                    Wargroove.spawnMapAnimation(pos, 0, "fx/mapeditor_unitdrop")
                    Wargroove.playMapSound("spawn", pos)
                    Wargroove.waitTime(0.5)
                end
            end
        end
    end
end

function Actions.spawnUnitClose(context)
    -- "Spawn {0} at {1} as close as possible for {2} (silent = {3})"
    local unitClassId = context:getUnitClass(0)
    local location = context:getLocation(1)
    local playerId = context:getPlayerId(2)
    local silent = context:getBoolean(3)

    local candidates = {}

    if location == nil then
        -- No location, use centre of map
        local mapSize = Wargroove.getMapSize()
        local cX = math.floor(mapSize.x / 2)
        local cY = math.floor(mapSize.y / 2)
        for x = 0, mapSize.x - 1 do
            for y = 0, mapSize.y - 1 do
                local pos = { x = x, y = y }
                if Wargroove.getUnitIdAt(pos) == -1 and Wargroove.canStandAt(unitClassId, pos) then
                    local dx = x - cX
                    local dy = y - cY
                    local dist = math.abs(dx) + math.abs(dy)
                    table.insert(candidates, { pos = pos, dist = dist })
                end
            end
        end
    else
        -- Find the centre of the location
        local centre = findCentreOfLocation(location)

        -- All candidates
        for i, pos in ipairs(location.positions) do
            if Wargroove.getUnitIdAt(pos) == -1 and Wargroove.canStandAt(unitClassId, pos) then
                local dx = pos.x - centre.x
                local dy = pos.y - centre.y
                local dist = math.abs(dx) + math.abs(dy)
                table.insert(candidates, { pos = pos, dist = dist })
            end
        end
    end

    -- Sort candidates
    table.sort(candidates, spawnUnitCompareBestLocation)

    -- Spawn at the best candidate
    if #candidates > 0 then
        local pos = candidates[1].pos
        if not silent then
            Wargroove.trackCameraTo(pos)
        end
        local unitId = Wargroove.spawnUnit(playerId, pos, unitClassId, false)
        table.insert(context.spawnedUnits,pos)
		local spawnedUnit = Wargroove.getUnitById(unitId);
		local mapSize = Wargroove.getMapSize()
		if pos.x>(mapSize.x/2) then
			-- spawnedUnit.startPos.facing = 1
			-- spawnedUnit.pos.facing = 1
			Wargroove.setFacingOverride(unitId, "left")
		else
			-- spawnedUnit.startPos.facing = 0
			-- spawnedUnit.pos.facing = 0
			Wargroove.setFacingOverride(unitId, "right")
		end
		--Wargroove.updateUnit(spawnedUnit)
        Wargroove.clearCaches()
        if silent or (not Wargroove.canCurrentlySeeTile(pos)) then
            -- Need to wait two frames to prevent being able to spawn on top of other units
            Wargroove.waitFrame()
            Wargroove.waitFrame()
        else
            Wargroove.spawnMapAnimation(pos, 0, "fx/mapeditor_unitdrop")
            Wargroove.playMapSound("spawn", pos)
            Wargroove.waitTime(0.5)
        end
    else

        local targetCenterPos = findCentreOfLocation(location)
        local pos = Pathfinding.findClosestOpenSpot(unitClassId,targetCenterPos)
        if pos ~= nil then
            if not silent then
                Wargroove.trackCameraTo(pos)
            end
            local mapSize = Wargroove.getMapSize()
            if pos.x>(mapSize.x/2) then
                pos.facing = 1
            else
                pos.facing = 0
            end
            local unitId = Wargroove.spawnUnit(playerId, pos, unitClassId, false)
            table.insert(context.spawnedUnits,pos)
            local mapSize = Wargroove.getMapSize()
            if pos.x>(mapSize.x/2) then
                -- spawnedUnit.startPos.facing = 1
                -- spawnedUnit.pos.facing = 1
                Wargroove.setFacingOverride(unitId, "left")
            else
                -- spawnedUnit.startPos.facing = 0
                -- spawnedUnit.pos.facing = 0
                Wargroove.setFacingOverride(unitId, "right")
            end
            Wargroove.clearCaches()
            if (not silent) and Wargroove.canCurrentlySeeTile(pos) then
                Wargroove.spawnMapAnimation(pos, 0, "fx/mapeditor_unitdrop")
                Wargroove.playMapSound("spawn", pos)
                Wargroove.waitTime(0.5)
            end
        end
    end
end

function Actions.forceAction(context)
    Actions.doForceAction(context, false)
end

function Actions.doForceAction(context, queue)
    -- "Force a unit at location {0} to do action {1} from location {2} targeting location {3}. Auto end: {4} On failure, display dialouge box with {5} {6} saying {7}"

    local fromLocation = context:getLocation(0)
    local action = context:getString(1)
    local toLocation = context:getLocation(2)
    local targetLocation = context:getLocation(3)    
    local autoEnd = context:getBoolean(4)
    local expression = context:getString(5)
    local commander = context:getString(6)
    local dialogue = context:getString(7)

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
        Wargroove.queueForceAction(selectableUnits, toPositions, targetPositions, action, autoEnd, expression, commander, dialogue)
    else
        Wargroove.forceAction(selectableUnits, toPositions, targetPositions, action, autoEnd, expression, commander, dialogue)
    end
end
local unitExpressionMap = {}
function Actions.dialogueBoxUnit(context)
    -- "Display dialogue box from {0} at {1} for {2} being {3} saying {4}"
    local units = context:gatherUnits(2, 0, 1)
	local iter = pairs(units)
	local unit = iter(units)
	if unit ~= nil then
 --       Wargroove.highlightLocation(location.id, "arrow", "red", false, false, false, false, false)
        Wargroove.trackCameraTo(unit.pos)
	end
    Wargroove.showDialogueBox(context:getString(3), "mercia", context:getString(4), "")
end

return Actions
