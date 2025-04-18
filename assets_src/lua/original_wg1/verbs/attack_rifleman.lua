local Wargroove = require "wargroove/wargroove"
local Attack = require "verbs/attack"

local AttackRifleman = Attack:new()

local stateKey = "ammo"

function AttackRifleman:canExecuteAnywhere(unit)
    local weapons = unit.unitClass.weapons
    local ammo = tonumber(Wargroove.getUnitState(unit, stateKey))
    return #weapons > 0 and ammo > 0
end

return AttackRifleman
