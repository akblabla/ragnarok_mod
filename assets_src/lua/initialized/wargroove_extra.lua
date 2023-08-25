local OldWargroove = require "wargroove/wargroove"
local UnitPostCombat = require "wargroove/unit_post_combat"
--local VisionTracker = require "initialized/vision_tracker"

local WargrooveExtra = {}
local originalGetMapTriggers
local originalApplyBuffs
local originalDoPostCombat
function WargrooveExtra.init()
	originalGetMapTriggers = OldWargroove.getMapTriggers
	OldWargroove.getMapTriggers = WargrooveExtra.getMapTriggers
--	OldWargroove.waitTime = WargrooveExtra.waitTime
	
	originalApplyBuffs = OldWargroove.applyBuffs
	OldWargroove.applyBuffs = WargrooveExtra.applyBuffs

	OldWargroove.highAlertBuff = WargrooveExtra.highAlertBuff
	
	originalDoPostCombat= OldWargroove.doPostCombat
	OldWargroove.doPostCombat = WargrooveExtra.doPostCombat

	OldWargroove.removeUnitState = WargrooveExtra.removeUnitState
end

local hiddenTriggersStart = {}
local hiddenTriggersEnd = {}

local highAlertAnimation = "ui/icons/high_alert"
local highAlertEntity = {}
function WargrooveExtra:doPostCombat(unitId, isAttacker)
    local unit = OldWargroove.getUnitById(unitId)
    if unit == nil then
        return
    end

    local postCombat = UnitPostCombat:getPostCombat(unit.unitClassId)
    if (postCombat ~= nil) then
        postCombat(OldWargroove, unit, isAttacker)
    end
	local postCombatGeneric = UnitPostCombat:getPostCombatGeneric()
	for i,method in pairs(postCombatGeneric) do
		method(OldWargroove, unit, isAttacker)
	end
end

function WargrooveExtra.highAlertBuff(unit)

    if OldWargroove.isSimulating() then
        return
    end
	if (OldWargroove.getUnitState(unit, "high_alert") == nil) then
        OldWargroove.setUnitState(unit, "high_alert", "false")
        OldWargroove.updateUnit(unit)
    end
	local isHighAlert = OldWargroove.getUnitState(unit, "high_alert")
	if (isHighAlert ~= nil) and (isHighAlert ~= "false") then
		isHighAlert = true
	else
		isHighAlert = false
	end
	if (isHighAlert) then
		if not OldWargroove.hasUnitEffect(unit.id, highAlertAnimation) then
			highAlertEntity[unit.id] = OldWargroove.spawnUnitEffect(unit.id, highAlertAnimation, "idle", "spawn", true, false)
		end
	elseif OldWargroove.hasUnitEffect(unit.id, highAlertAnimation)  then
		if highAlertEntity[unit.id] ~= nil then
			OldWargroove.deleteUnitEffect(highAlertEntity[unit.id], "death")
		else
			OldWargroove.deleteUnitEffectByAnimation(unit.id, highAlertAnimation, "death")
		end
	end
end

local crownAnimation = "ui/icons/fx_crown"
function WargrooveExtra.crownBuff(unit)

    if OldWargroove.isSimulating() then
        return
    end
	local hasCrown = OldWargroove.getUnitState(unit, "crown") ~= nil
	if (hasCrown) then
		if not OldWargroove.hasUnitEffect(unit.id, crownAnimation) then
			local crownEffectEntityId = OldWargroove.spawnUnitEffect(unit.id, crownAnimation, "idle", nil, true, false)
			OldWargroove.setUnitState(unit, "crownEffectEntityId", crownEffectEntityId)
		end
	elseif OldWargroove.hasUnitEffect(unit.id, crownAnimation)  then
		local crownEffectEntityId = OldWargroove.getUnitState(unit, "crownEffectEntityId")
		if crownEffectEntityId~=nil then
			OldWargroove.deleteUnitEffect(crownEffectEntityId, "death")
		else
			OldWargroove.deleteUnitEffectByAnimation(unit.id, crownAnimation, "death")

		end
	end
end

function WargrooveExtra.applyBuffs()
	for i,id in pairs(OldWargroove.getAllUnitIds()) do
		local unit = OldWargroove.getUnitById(id)
		WargrooveExtra.highAlertBuff(unit)
		WargrooveExtra.crownBuff(unit)
	end
    originalApplyBuffs()
end

function WargrooveExtra.addHiddenTrigger(trigger, atEnd)
	if atEnd == true then
		table.insert(hiddenTriggersEnd, trigger) 
	else
		table.insert(hiddenTriggersStart, trigger) 
	end
end

function WargrooveExtra.getMapTriggers()
	local originalTriggers = originalGetMapTriggers()
	local combinedTriggers = {}
	for i,v in ipairs(hiddenTriggersStart) do
		table.insert(combinedTriggers, v) 
	end
	for i,v in ipairs(originalTriggers) do
		table.insert(combinedTriggers, v) 
	end
	for i,v in ipairs(hiddenTriggersEnd) do
		table.insert(combinedTriggers, v) 
	end
    return combinedTriggers
end

-- function WargrooveExtra.spawnUnit(playerId, pos, unitType, turnSpent, startAnimation, startingState, factionOverride)  
	-- local unitId = originalSpawnUnit(playerId, pos, unitType, turnSpent, startAnimation, startingState, factionOverride)  
	-- local unit = Wargroove.getUnitById(unitId)
	-- local visibleTiles = VisionTracker.calculateVisionOfUnit(unit)
	-- local team = Wargroove.getPlayerTeam(playerId)
	-- for i, pos in pairs(visibleTiles) do
		-- incrementNumberOfViewers(team,pos)
	-- end
    -- return unitId
-- end


-- function WargrooveExtra.updateUnit(unit)
	-- local oldUnit = getUnitById(unit.id)
	-- local visibleTiles = VisionTracker.calculateVisionOfUnit(oldUnit)
	-- local team = Wargroove.getPlayerTeam(oldUnit.playerId)
	-- for i, pos in pairs(visibleTiles) do
		-- decrementNumberOfViewers(team,pos)
	-- end
    -- api.updateUnit(unit)
	-- visibleTiles = VisionTracker.calculateVisionOfUnit(unit)
	-- team = Wargroove.getPlayerTeam(unit.playerId)
	-- for i, pos in pairs(visibleTiles) do
		-- incrementNumberOfViewers(team,pos)
	-- end
    -- Wargroove.clearUnitPositionCache()
-- end

function WargrooveExtra.removeUnitState(unit, key)
    for i, stateKey in pairs(unit.state) do
        if (stateKey.key == key) then
			table.remove(unit.state,i)
            return
        end
    end
end


function WargrooveExtra.waitTime(time)
	print("WargrooveExtra.waitTime(time)")
	local currentTime = 0
    local timeStamp = currentTime+ time
	print("timeStamp")
	print(timeStamp)
    while currentTime < timeStamp do
		print("now")
		print(currentTime)
		currentTime = currentTime +1.0/60.0
        coroutine.yield()
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

return WargrooveExtra
