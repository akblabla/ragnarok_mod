local OldUnitPostCombat = require "wargroove/unit_post_combat"

local UnitPostCombat = {}
local PostCombat = {}
local PostCombatGeneric = {}
local classMap = {}
local originalGetPostCombat

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
local function BurnBonus(Wargroove,unit, target)

    Wargroove.playMapSound("nadia/nadiaGrooveHit", target.pos)
    Wargroove.spawnMapAnimation(target.pos, 1, "units/commanders/nadia/nadia_burn_fx_front", "idle", "over_units", {x = 13, y = 16})
    Wargroove.spawnMapAnimation(target.pos, 1, "units/commanders/nadia/nadia_burn_fx_back", "idle", "units", {x = 13, y = 16})

    if target == nil or target.health<0 then
        return
    end
    local isBurning = Wargroove.getUnitState(target, "burning")
    -- We prevent double burns
    if (isBurning == nil or isBurning == "false") then
        Wargroove.setUnitState(target, "burning", "true")
        Wargroove.updateUnit(target)

        local startingState = {}
        local unitId = {key = "unitId", value = target.id}
        table.insert(startingState, unitId)
        Wargroove.spawnUnit(unit.playerId, {x = -100, y = -100}, "burn", false, "", startingState)

        Wargroove.displayBuffVisualEffect(target.id, target.playerId, "units/commanders/nadia/nadia_constant_burn_fx_back", "spawn", 1.0, nil, "units", {x = 0, y = -1}, false, false)
        Wargroove.displayBuffVisualEffect(target.id, target.playerId, "units/commanders/nadia/nadia_constant_burn_fx_front", "spawn", 1.0, nil, "over_units", {x = 0, y = 3}, false, false)
    end
end

local function StealGoldBonus(Wargroove,unit, target)

    Wargroove.playMapSound("thiefSteal", target.pos)
    Wargroove.spawnMapAnimation(unit.pos, 0, "fx/ransack_2", "default", "over_units", { x = 12, y = 0 })
    Wargroove.spawnMapAnimation(target.pos, 0, "fx/ransack_1", "default", "over_units", { x = 12, y = 0 })
    Wargroove.changeMoney(target.playerId, -100)
    Wargroove.changeMoney(unit.playerId, 100)
end

function UnitPostCombat.init()
    originalGetPostCombat = OldUnitPostCombat.getPostCombat
    OldUnitPostCombat.getPostCombat = UnitPostCombat.getPostCombat
    OldUnitPostCombat.getPostCombatGeneric = UnitPostCombat.getPostCombatGeneric
end



function UnitPostCombat:getPostCombat(unitClassId)
    print("UnitPostCombat:getPostCombat(unitClassId)")
    if PostCombat[unitClassId]~=nil then
        return PostCombat[unitClassId]
    else
        return originalGetPostCombat(OldUnitPostCombat,unitClassId)
    end
	
end

function UnitPostCombat:getPostCombatGeneric()
    return PostCombatGeneric
	
end

local outOfAmmoAnimation = "ui/icons/bullet_out_of_ammo"
function PostCombat.rifleman(Wargroove, unit, isAttacker, healthAfterCombat)
    if not isAttacker then
        return
    end

    local ammo = tonumber(Wargroove.getUnitState(unit, "ammo"))
    local newAmmo = math.max(ammo - 1, 0)
    Wargroove.setUnitState(unit, "ammo", newAmmo)
    Wargroove.updateUnit(unit)

    if (newAmmo == 0) and not Wargroove.hasUnitEffect(unit.id, outOfAmmoAnimation) then
        Wargroove.spawnUnitEffect(unit.id, unit.id, outOfAmmoAnimation, "idle", startAnimation, true, false)
    end
end

function PostCombat.kraken(Wargroove, unit, isAttacker, healthAfterCombat)
    if isAttacker then
        return
    end

    local targetId = Wargroove.getUnitState(unit, "targetId")

    -- If we're tentacling, update all the tentacles to the kraken's health
    if targetId ~= nil then
        local tentaclePositionsString = Wargroove.getUnitState(unit, "tentacles")
        local tentaclePositions = Wargroove.stringToPositions(tentaclePositionsString)

        for i, pos in ipairs(tentaclePositions) do
            local tentacle = Wargroove.getUnitAt(pos)
            tentacle:setHealth(healthAfterCombat, tentacle.id)
            Wargroove.updateUnit(tentacle)
        end
    end
end

function PostCombat.tentacle(Wargroove, unit, isAttacker, healthAfterCombat)
    if isAttacker then
        return
    end

    local parentId = Wargroove.getUnitState(unit, "parentId")

    -- Set tentacles and kraken to the same health
    if parentId ~= nil then
        local parentUnit = Wargroove.getUnitById(tonumber(parentId))
        parentUnit:setHealth(healthAfterCombat, unit.id)

        Wargroove.updateUnit(parentUnit)

        local tentaclePositionsString = Wargroove.getUnitState(parentUnit, "tentacles")
        local tentaclePositions = Wargroove.stringToPositions(tentaclePositionsString)

        for i, pos in ipairs(tentaclePositions) do
            local tentacle = Wargroove.getUnitAt(pos)
            tentacle:setHealth(healthAfterCombat, tentacle.id)
            Wargroove.updateUnit(tentacle)
        end
    end
end


function PostCombatGeneric.attack(Wargroove, unit, isAttacker, healthAfterCombat)
    -- if not isAttacker then
    --     return
    -- end    

    local attacker = Wargroove.lastAttacker
    local defender = Wargroove.lastDefender
    if not isAttacker then
        attacker = Wargroove.lastDefender
        defender = Wargroove.lastAttacker
    end

    if (isAttacker and defender ~= nil and unit.itemId=="fire_arrows") then
        BurnBonus(Wargroove, unit, defender)
    end
    if (defender ~= nil and defender.health<= 0 and attacker.itemId=="cutpurse_pockets") then
        print("defender dump")
        print(dump(defender,0))
        StealGoldBonus(Wargroove, unit, defender)
    end
--[[local isHighAlertToBeRemoved = Wargroove.getUnitState(unit, "high_alert")
	if (isHighAlertToBeRemoved ~= nil) and (isHighAlertToBeRemoved == "to_be_removed") then
		isHighAlertToBeRemoved = true
	else
		isHighAlertToBeRemoved = false
	end
	if isHighAlertToBeRemoved then
		Wargroove.setUnitState(unit,"high_alert","false")
		Wargroove.highAlertBuff(unit)
		Wargroove.updateUnit(unit)
	end]]
end

return UnitPostCombat