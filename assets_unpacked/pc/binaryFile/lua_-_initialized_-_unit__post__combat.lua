local OldUnitPostCombat = require "wargroove/unit_post_combat"

local UnitPostCombat = {}
local PostCombat = {}
local PostCombatGeneric = {}
local classMap = {}

function UnitPostCombat.init()
  OldUnitPostCombat.getPostCombat = UnitPostCombat.getPostCombat
  OldUnitPostCombat.getPostCombatGeneric = UnitPostCombat.getPostCombatGeneric
end



function UnitPostCombat:getPostCombat(unitClassId)
    return PostCombat[unitClassId]
	
end

function UnitPostCombat:getPostCombatGeneric()
    return PostCombatGeneric
	
end

local outOfAmmoAnimation = "ui/icons/bullet_out_of_ammo"
function PostCombat.rifleman(Wargroove, unit, isAttacker)
    if not isAttacker then
        return
    end

    local ammo = tonumber(Wargroove.getUnitState(unit, "ammo"))
    local newAmmo = math.max(ammo - 1, 0)
    Wargroove.setUnitState(unit, "ammo", newAmmo)
    Wargroove.updateUnit(unit)

    if (newAmmo == 0) and not Wargroove.hasUnitEffect(unit.id, outOfAmmoAnimation) then
        Wargroove.spawnUnitEffect(unit.id, outOfAmmoAnimation, "idle", startAnimation, true, false)
    end
end

function PostCombatGeneric.attack(Wargroove, unit, isAttacker)
    if not isAttacker then
        return
    end    
	local isHighAlertToBeRemoved = Wargroove.getUnitState(unit, "high_alert")
	if (isHighAlertToBeRemoved ~= nil) and (isHighAlertToBeRemoved == "to_be_removed") then
		isHighAlertToBeRemoved = true
	else
		isHighAlertToBeRemoved = false
	end
	if isHighAlertToBeRemoved then
		Wargroove.setUnitState(unit,"high_alert","false")
		Wargroove.highAlertBuff(unit)
		Wargroove.updateUnit(unit)
	end
end

return UnitPostCombat