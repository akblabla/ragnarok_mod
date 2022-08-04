local Wargroove = require "wargroove/wargroove"
local Verb = require "wargroove/verb"
local Ragnarok = require "initialized/ragnarok"
local Combat = require "wargroove/combat"

local spawnFlare = {}

function spawnFlare:getMaximumRange(unit, endPos)
    return 10
end

function spawnFlare:getTargetType()
    return "all"
end

function spawnFlare:canExecuteAnywhere(unit)
    return Ragnarok.getFlareCount(unit.playerId) > 0
end

function spawnFlare:canExecuteWithTarget(unit, endPos, targetPos, strParam)    
    --if not self:canSeeTarget(targetPos) then
    --    return false
    --end
    --local targetUnit = Wargroove.getUnitAt(targetPos)
	--if targetUnit and Wargroove.canPlayerSeeTile(unit.playerId, targetPos) then
	--	return false
	--end
	local u = Wargroove.getUnitAt(targetPos)
	if u and Wargroove.areAllies(u.playerId, unit.playerId) then
		return false
	end
    return true
	--Wargroove.canStandAt(Wargroove.getUnitClass("flare"),targetPos)
end

function spawnFlare:execute(unit, targetPos, strParam, path)
	Ragnarok.removeFlare(unit.playerId)
	--Yoinked from groove_golf
	local facingOverride = "left"
    if targetPos.x > unit.pos.x then
        facingOverride = "right"
    elseif targetPos.x < unit.pos.x then
        facingOverride = "left"
    end

    Wargroove.setFacingOverride(unit.id, facingOverride)
	
    Wargroove.playMapSound("cutscene/throwObject", targetPos)
	local flareId = Wargroove.spawnUnit(unit.playerId, unit.pos, "flare", true, "idle")
	local flare = Wargroove.getUnitById(flareId)
	local numSteps = 10
	Wargroove.lockTrackCamera(flareId)
    Wargroove.setShadowVisible(flareId, false)
	
	local function findNextPosition(iteratorPos,center)
		if iteratorPos.x==center.x and iteratorPos.y==center.y then
			iteratorPos = { x = iteratorPos.x, y = iteratorPos.y - 1}
			return iteratorPos
		end
		if iteratorPos.x>=center.x and iteratorPos.y<center.y then
			iteratorPos = { x = iteratorPos.x + 1, y = iteratorPos.y + 1}
			return iteratorPos
		end
		if iteratorPos.x>center.x and iteratorPos.y>=center.y then
			iteratorPos = { x = iteratorPos.x - 1, y = iteratorPos.y + 1}
			return iteratorPos
		end
		if iteratorPos.x<=center.x and iteratorPos.y>center.y then
			iteratorPos = { x = iteratorPos.x - 1, y = iteratorPos.y - 1}
			return iteratorPos
		end
		if iteratorPos.x+1<center.x and iteratorPos.y<=center.y then
			iteratorPos = { x = iteratorPos.x + 1, y = iteratorPos.y - 1}
			return iteratorPos
		end
		if iteratorPos.x+1==center.x and iteratorPos.y<=center.y then
			iteratorPos = { x = iteratorPos.x + 1, y = iteratorPos.y - 2}
			return iteratorPos
		end
		return iteratorPos
	end
	local iteratorPos = targetPos
	local bounce = false
	local noValidSpot = false
	
	local attempts = 0
	while true do
		attempts = attempts + 1;
		print("Attempt")
		print(attempts)
		print("Iterator Position")
		print(iteratorPos.x)
		print(iteratorPos.y)
		--give up
		if attempts>16 then
			noValidSpot = true
			bounce = false
			break
		end
		local distance = math.abs(iteratorPos.x-unit.pos.x)+math.abs(iteratorPos.y-unit.pos.y)
		--success!
		if Wargroove.getUnitIdAt(iteratorPos) == -1 and Wargroove.canStandAt(flare.unitClassId, iteratorPos) and distance<=spawnFlare:getMaximumRange(unit, path[#path]) then
			break
		end
		iteratorPos = findNextPosition(iteratorPos,targetPos)
		bounce = true
	end
	if bounce then
		print("Throw with followup bounce")
		Ragnarok.moveInArch(flareId, unit.pos, targetPos, numSteps, 20, 10,1.5,1)
	else
		print("Throw with no bounce")
		Ragnarok.moveInArch(flareId, unit.pos, targetPos, numSteps, 10, 10,2.5,1.5)
	end
	if noValidSpot then
		print("No valid spot")
		flare.health = 0
	end
	local u = Wargroove.getUnitAt(targetPos)
	if u then
		print("Do some damage")
		local damage = 5
		print("Damage calculated:")
		print(damage)
		
		u:setHealth(u.health - damage, unit.id)
		print("Damage dealt")
		Wargroove.updateUnit(u)
		print("updated target")
		Wargroove.playUnitAnimation(u.id, "hit")
		print("played cool animation")
		Wargroove.playMapSound("hitWood", targetPos)
		Wargroove.spawnMapAnimation(targetPos, 1, "fx/map_critical_fx", "idle", "over_units", {x = 12, y = 12})
	end
	if bounce then
		print("Bounce!")
		Ragnarok.moveInArch(flareId, targetPos, iteratorPos, numSteps, 7, 10,2.5,1.5)
	end
    Wargroove.unsetShadowVisible(flareId)
    Wargroove.unlockTrackCamera()
	
    flare.pos = { x = iteratorPos.x, y = iteratorPos.y }
    Wargroove.updateUnit(flare)
    Wargroove.updateFogOfWar()
    Wargroove.waitTime(0.25)
end

function spawnFlare:onPostUpdateUnit(unit, targetPos, strParam, path)
    Verb.onPostUpdateUnit(self, unit, targetPos, strParam, path)
    Wargroove.unsetFacingOverride(unit.id)
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
return spawnFlare
