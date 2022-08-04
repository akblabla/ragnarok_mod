local Wargroove = require "wargroove/wargroove"
local GrooveVerb = require "wargroove/groove_verb"
local Combat = require "wargroove/combat"

local Broadside = GrooveVerb:new()

local targetList ={}
local maxDist = 4
local arcTime = 0.4
local timeBetweenShots = 0.15
local projVel = 33
local minimumSeperation = 0.01
local chosenDirection = {x=0,y=0}
local areaListPreset = {{{x = 1, y = -1}, {x = 2, y = -2}, {x = 2, y = -1},{x = 3, y = -3},{x = 3, y = -2}},
					{{x = 1, y = -1}, {x = 1, y = 0},{x = 2, y = -2}, {x = 2, y = -1}, {x = 2, y = 0},{x = 3, y = -1}},
					{{x = 1, y = -1}, {x = 1, y = 0},{x = 1, y = 1},{x = 2, y = 0}, {x = 2, y = 1}, {x = 3, y = 0}},
					{{x = 1, y = 0},{x = 1, y = 1},{x = 2, y = 2}, {x = 2, y = 1}, {x = 3, y = 1}},
					{{x = 1, y = 1},{x = 2, y = 2}, {x = 3, y = 2},{x = 3, y = 3}}}

Broadside.isInPreExecute = false
function Broadside:getMaximumRange(unit, endPos)
  if Broadside.isInPreExecute then
    return maxDist*2
  end

  return 1
end


function Broadside:getTargetType()
    return "all"
end


function Broadside:canExecuteWithTarget(unit, endPos, targetPos, strParam)
    if not self:canSeeTarget(targetPos) then
        return false
    end
	if targetPos.x == endPos.x and targetPos.y == endPos.y then
		return false
	end
	local origin = {x = endPos.x, y = endPos.y}
	if Broadside.isInPreExecute then
		if not self:isInCone(origin, chosenDirection, targetPos) or (targetPos.x==origin.x and targetPos.y==origin.y) then
		  return false
		end
	end
	return true
end

function Broadside:atan2(a, b)
    local result
    if (b > 0) then
        result = math.atan(a/b)
    elseif (b < 0) and (a >= 0) then
        result = math.atan(a/b) + math.pi
    elseif (b < 0) and (a < 0) then
        result = math.atan(a/b) - math.pi
    elseif (b == 0) and (a > 0) then
        result = math.pi / 2
    elseif (b == 0) and (a < 0) then
        result = 0 - (math.pi / 2 )
    elseif (b == 0) and (a == 0) then
        result = nil
	end
    return result
end

function Broadside:preExecute(unit, targetPos, strParam, endPos)
	print("preexcution starts here")
	chosenDirection = {x = targetPos.x-endPos.x, y = targetPos.y-endPos.y}
	print(dump(chosenDirection,1))
    Broadside.isInPreExecute = true

    Wargroove.selectTarget()

    while Wargroove.waitingForSelectedTarget() do
        coroutine.yield()
    end

    local destination = Wargroove.getSelectedTarget()

    if (destination == nil) then
        Broadside.isInPreExecute = false
        return false, ""
    end
    
    Wargroove.setSelectedTarget(targetPos)

    Broadside.isInPreExecute = false

    return true
end

function Broadside:execute(unit, targetPos, strParam, path)
    Wargroove.setIsUsingGroove(unit.id, true)
    Wargroove.updateUnit(unit)

	local direction = chosenDirection
    Wargroove.playPositionlessSound("battleStart")
    Wargroove.playGrooveCutscene(unit.id)
    Wargroove.waitTime(0.5)
	if direction.y == 0 then
		Wargroove.playUnitAnimation(unit.id, "run_down")
	else
		Wargroove.playUnitAnimation(unit.id, "run")
	end
    Wargroove.playMapSound("broadside", unit.pos)
	local animationString = ""
	if direction.x == 1 then animationString = "right" end
	if direction.x == -1 then animationString = "left" end
	if direction.y == 1 then animationString = "down" end
	if direction.y == -1 then animationString = "up" end
	Wargroove.spawnMapAnimation(unit.pos, 1, "fx/broadside", animationString, "over_units", {x = 12, y = 12})
    Wargroove.playGrooveEffect()

	
    targetList = {}
	--print(dump(areaListPreset,0))
	self:getTargetsFromAreaList(unit,unit.pos, direction, areaListPreset)
	print("got here 1")
	print(dump(targetList,1))
	table.sort(targetList, function (k1, k2) return k1.timing < k2.timing end )
	print("got here 2")
	print(dump(targetList,1))
	local lastDistance = 0;
    for i, target in ipairs(targetList) do
		if lastDistance+minimumSeperation<target.timing then
			Wargroove.waitTime(target.timing-lastDistance)
			lastDistance = target.timing
			print("got here 3")
		end
		print("got here 4")
        local u = Wargroove.getUnitAt(target.pos)
        if u and Wargroove.areEnemies(u.playerId, unit.playerId) then
			print("got here 5")
			local directionalDistance = 0
			if direction.y == 0 then
				directionalDistance = math.abs(targetPos.x-target.pos.x)
			else
				directionalDistance = math.abs(targetPos.y-target.pos.y)
			end
			print("got here 6")
            local damage = Combat:getGrooveAttackerDamage(unit, u, "random", unit.pos, target.pos, path, nil) * (1/3)
			print("got here 7")
            u:setHealth(u.health - damage, unit.id)
            Wargroove.updateUnit(u)
            Wargroove.playUnitAnimation(u.id, "hit")
			print("got here 8")
			Wargroove.spawnMapAnimation(target.pos, 1, "fx/map_critical_fx", "idle", "over_units", {x = 12, y = 12})
			print(dump(u,0))
        end
		print("got here 9")
    end
	
	
    Wargroove.waitTime(1.0)
end

function Broadside:getTargetsInCone(pos, direction, targetType)
    local mapSize = Wargroove.getMapSize()

    local result = {}
    local x0 = pos.x
    local y0 = pos.y
    for yo = -maxDist, maxDist do
        for xo = -maxDist, maxDist do
			local x = x0 + xo
			local y = y0 + yo
			if self:isInCone(pos, direction, {x = x, y = y}) then
				if (x >= 0) and (y >= 0) and (x < mapSize.x) and (y < mapSize.y) then
					if (targetType == "all") then
						table.insert(result, { x = x, y = y})
					else
						local unitId = Wargroove.getUnitIdAtXY(x, y)
						if (targetType == "unit" and unitId ~= -1) or (targetType == "empty" and unitId == -1) then
							table.insert(result, { x = x, y = y})
						end
					end
				end
            end
        end
    end
    return result
end

function Broadside:isInCone(origin, direction, pos)

  local absXDiff = math.abs(origin.x-pos.x)
  local absYDiff = math.abs(origin.y-pos.y)
  if pos.x > origin.x and direction.x < 0 then
    return false
  elseif pos.x < origin.x and direction.x > 0 then
    return false
  elseif pos.y > origin.y and direction.y < 0 then
    return false
  elseif pos.y < origin.y and direction.y > 0 then
    return false
  end
  if (direction.y == 0) then
    if absXDiff < absYDiff or absXDiff >= maxDist then
      return false
    end
  else
    if absXDiff > absYDiff or absYDiff >= maxDist then
      return false
    end
  end
  return true
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

function Broadside:getTargetsFromAreaList(unit,originPos, direction, areaList)
	print("got here -5")
    for i, area in ipairs(areaList) do
		print("got here -4")
		for j, tile in ipairs(area) do
			print(dump(tile,1))
			local _tile = {x = tile.x, y = tile.y}
			print(dump(direction,1))
			print(dump(originPos,1))
			
			--rotate tiles around origin
			_tile.x = tile.x*direction.x-tile.y*direction.y + originPos.x
			_tile.y = tile.x*direction.y+tile.y*direction.x + originPos.y
			print(dump(_tile,1))
			print("got here -3")
			if self:canSeeTarget(_tile) then
				local u = Wargroove.getUnitAt(_tile)
				print("got here -2.25")
				if (u ~= nil) and Wargroove.areEnemies(u.playerId, unit.playerId) then
					print("got here -2.5")
					local distance = math.sqrt((u.pos.y-originPos.y)^2+(u.pos.x-originPos.x)^2)
					print("got here -2")
					table.insert(targetList, {pos = u.pos, timing = timeBetweenShots*(i-1)+distance/projVel})
					print("got here -1")
				end
			end
		end
	end
	print("got here 0")
end

function Broadside:getSweepTargets(pos, targetPos, direction, targetList)
	local angle = self:atan2(pos.y-targetPos.y,pos.x-targetPos.x)
	local startAngle = self:atan2(direction.y,direction.x)-math.pi*0.5
	
	local nfmod = function(a,b) return a - b * math.floor(a / b)	end
	
	if angle == nil then
		angle = self:atan2(direction.y,direction.x)
	end
	angle = nfmod(angle-startAngle,2*math.pi)
	local distance = math.sqrt((pos.y-targetPos.y)^2+(pos.x-targetPos.x)^2)
	table.insert(targetList, {pos = pos, timing = arcTime*angle/(math.pi*0.8)+distance/projVel})
end

return Broadside
