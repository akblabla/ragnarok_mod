local UnitPreCombat = {}

local PreCombat = {}

local maxAir = 2

function PreCombat.turtle_submerged(Wargroove, attacker, defender, isAttacker)
    if not isAttacker then
        defender.unitClassId = "turtle"

        Wargroove.setUnitState(defender, "air", maxAir)
        Wargroove.updateUnit(defender)
    else
        Wargroove.setUnitState(attacker, "air", 0)
        Wargroove.updateUnit(attacker)
    end
end

function PreCombat.griffin_flying(Wargroove, attacker, defender, isAttacker)
    if isAttacker then
        Wargroove.playUnitAnimation(attacker.id, "touchdown")
        Wargroove.waitTime(0.5)

        attacker.unitClassId = "griffin_walking"
        attacker.hadTurn = true
        Wargroove.updateUnit(attacker)
    end
end

function UnitPreCombat:getPreCombat(unitClassId)
    return PreCombat[unitClassId]
end

return UnitPreCombat