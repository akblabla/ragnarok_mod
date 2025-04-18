local UnitPostCombat = {}

local PostCombat = {}

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

function UnitPostCombat:getPostCombat(unitClassId)
    return PostCombat[unitClassId]
end

return UnitPostCombat