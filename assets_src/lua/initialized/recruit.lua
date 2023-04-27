local Wargroove = require "wargroove/wargroove"
local Ragnarok = require "initialized/ragnarok"
local Verb = require "wargroove/verb"
local OldRecruit = require "verbs/recruit"

local Recruit = Verb:new()
--local factionExclusiveUnits = {unitId = "pirate_ship", commanders = {"commander_wulfar","commander_vesper","commander_flagship_wulfar","commander_flagship_rival"}}
local raiderShipBuilderList = {}
function Recruit.init()
	OldRecruit.getMaximumRange = Recruit.getMaximumRange
	OldRecruit.canExecuteWithTarget = Recruit.canExecuteWithTarget
	OldRecruit.preExecute = Recruit.preExecute
	OldRecruit.execute = Recruit.execute
	OldRecruit.generateOrders = Recruit.generateOrders
	OldRecruit.getScore = Recruit.getScore
	OldRecruit.canExecuteAnywhere = Recruit.canExecuteAnywhere
end


function Recruit:canExecuteAnywhere(unit)
    return Wargroove.isHuman(unit.playerId)
end

function Recruit:getMaximumRange(unit, endPos)
    return 100
end


function Recruit:getTargetType()
    return "empty"
end

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

function Recruit:allowAIToBuildRaiderShips(playerId)
	raiderShipBuilderList[playerId] = true
end

function Recruit:preExecute(unit, targetPos, strParam, endPos)
    if strParam == nil or strParam == "" then
        return true
    end
	print("Recruit:preExecute")
	print(strParam)
end

function Recruit:canExecuteWithTarget(unit, endPos, targetPos, strParam)
    if strParam == nil or strParam == "" then
        return true
    end
	print("Recruit:canExecuteWithTarget")
	print(strParam)

    -- Check if this can recruit that type of unit
    local ok = false
    for i, uid in ipairs(unit.recruits) do
        if uid == strParam then
            ok = true
        end
    end
    if not ok then
        return false
    end

    -- Check if this player can recruit this type of unit
    if not Wargroove.canPlayerRecruit(unit.playerId, strParam) then
        return false
    end
    local uc = Wargroove.getUnitClass(strParam)
	if strParam ~= "flare" then
		local dist = math.abs(unit.pos.x-targetPos.x)+math.abs(unit.pos.y-targetPos.y)
		if dist > 1 then
			return false
		end
	elseif not Wargroove.isHuman(unit.playerId) or not Wargroove.canStandAt("balloon", targetPos) then
		return false
	end
	if strParam == "pirate_ship" and not Wargroove.isHuman(unit.playerId) then
		if raiderShipBuilderList[unit.playerId] == nil then
			return false
		end
	end
    return Wargroove.canStandAt(strParam, targetPos) and Wargroove.getMoney(unit.playerId) >= uc.cost and Wargroove.canPlayerSeeTile(unit.playerId, targetPos)
end


function Recruit:execute(unit, targetPos, strParam, path)
	--print("Recruit Execute starts here")
	--print(dump(unit,0))
	local uc = Wargroove.getUnitClass(strParam)
	Wargroove.changeMoney(unit.playerId, -uc.cost)
	if strParam ~= "flare" then
		Wargroove.spawnUnit(unit.playerId, targetPos, strParam, true)
		Wargroove.spawnMapAnimation(targetPos, 0, "fx/mapeditor_unitdrop")
		Wargroove.playMapSound("spawn", targetPos)
		Wargroove.playPositionlessSound("recruit")
	else
		--print("Deploy Flare!")
		Wargroove.lockTrackCamera(unit.id)
		--print("-2")
		Wargroove.playMapSound("switch", unit.pos)
		Wargroove.waitTime(0.5)
		--print("-1")
		Wargroove.playMapSound("ballistaAttack", unit.pos)
		Wargroove.waitTime(0.52)
		local spawnedId = Wargroove.spawnUnit(unit.playerId, unit.pos, "flare", false, "summon")
		--print("0")
		local spawn = Wargroove.getUnitById(spawnedId)
		--print("1")

		local facingOverride = ""
		if targetPos.x > unit.pos.x then
			facingOverride = "right"
		elseif targetPos.x < unit.pos.x then
			facingOverride = "left"
		elseif teleportPosition.x < unit.pos.x then
			facingOverride = "left"
		elseif teleportPosition.x > unit.pos.x then
			facingOverride = "right"
		end
		Wargroove.setFacingOverride(spawnedId, facingOverride)
		--print("2")

		local numSteps = 10
		Wargroove.lockTrackCamera(spawnedId)
		Wargroove.setShadowVisible(spawnedId, false)
		Wargroove.setVisibleOverride(spawnedId, true)
		--print("3")
		local eventPackage1 = {}
		eventPackage1.event = function(eventData)
			print("Inititiate Deployment Animation")
			Wargroove.playUnitAnimation(eventData.unitId, "deploy")
			Wargroove.playMapSound("cutscene/clothMovement1", eventData.targetPos)
		end
		--print("3.1")
		eventPackage1.time = 0.5
		--print("3.2")
		eventPackage1.mode = "fromEnd"
		--print("3.3")
		eventPackage1.eventData = {}
		eventPackage1.eventData.unitId = spawnedId
		eventPackage1.eventData.targetPos = targetPos
		--print("4")

		local eventPackage2 = {}
		eventPackage2.event = function(eventData)
			--print("Make swoosh sound")
			--Wargroove.playMapSound("balloonEntry", eventData.targetPos)
		end
		eventPackage2.time = 0.25
		eventPackage2.mode = "fraction"
		eventPackage2.eventData = {}
		eventPackage2.eventData.targetPos = {}
		eventPackage2.eventData.targetPos.x = (targetPos.x+unit.pos.x)/2
		eventPackage2.eventData.targetPos.y = (targetPos.y+unit.pos.y)/2
		--print("5")
		local dist = math.sqrt((spawn.pos.x - targetPos.x)^2+(spawn.pos.y - targetPos.y)^2)
		Ragnarok.moveInArch(spawnedId, unit.pos, targetPos, numSteps, 5+math.sqrt(dist)*2, 10,3,2,{eventPackage1, eventPackage2})
		--print("6")
		Wargroove.unsetShadowVisible(spawnedId)
		Wargroove.unlockTrackCamera()
		Wargroove.unsetVisibleOverride(spawnedId)
		--Wargroove.unsetFacingOverride(spawnedId)
		spawn.pos.facing = facingOverride
		spawn.pos.x = targetPos.x
		spawn.pos.y = targetPos.y
		Wargroove.updateUnit(spawn)
		Wargroove.updateFogOfWar()
		Wargroove.waitTime(0.25)
	end
	Wargroove.notifyEvent("unit_recruit", unit.playerId)
	Wargroove.setMetaLocation("last_recruit", targetPos)
	--print(dump(unit.recruits,0))
	for i,recruit in ipairs(unit.recruits) do
		if recruit==strParam then
			table.remove(unit.recruits,i)
			break
		end
	end
	--print(dump(unit.recruits,0))
	Wargroove.updateUnit(unit)
	--print("post update")
	--print(dump(unit,0))
end


function Recruit:generateOrders(unitId, canMove)
    local unit = Wargroove.getUnitById(unitId)
    return {}
end

function Recruit:getScore(unitId, order)
    local unit = Wargroove.getUnitById(unitId)
    return {score = -1, introspection = {}}
end

return Recruit
