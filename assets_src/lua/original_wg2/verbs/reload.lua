local Wargroove = require "wargroove/wargroove"
local Verb = require "wargroove/verb"


local Reload = Verb:new()

local maxAmmo = 3
local stateKey = "ammo"

function Reload:canExecuteAnywhere(unit)
  local ammo = tonumber(Wargroove.getUnitState(unit, stateKey))
  return ammo < maxAmmo
end

local outOfAmmoAnimation = "ui/icons/bullet_out_of_ammo"

function Reload:execute(unit, targetPos, strParam, path)
  local currentAmmo = tonumber(Wargroove.getUnitState(unit, stateKey))
  local newAmmo = math.min(currentAmmo + 3, maxAmmo)
  Wargroove.setUnitState(unit, stateKey, newAmmo)
  Wargroove.playMapSound("riflemanReload", unit.pos)

  Wargroove.playUnitAnimation(unit.id, "reload")

  if Wargroove.hasUnitEffect(unit.id, outOfAmmoAnimation) then
    Wargroove.deleteUnitEffectByAnimation(unit.id, outOfAmmoAnimation)
  end

  Wargroove.waitTime(1.2)
end

function Reload:generateOrders(unitId, canMove)
  local orders = {}

  local unit = Wargroove.getUnitById(unitId)

  if not self:canExecuteAnywhere(unit) then
    return orders
  end

  local unitClass = Wargroove.getUnitClass(unit.unitClassId)
  local movePositions = {}
  if canMove then
      movePositions = Wargroove.getTargetsInRange(unit.pos, unitClass.moveRange, "empty")
  end
  table.insert(movePositions, unit.pos)

  for i, pos in pairs(movePositions) do
    orders[#orders+1] = {targetPosition = pos, strParam = "", movePosition = pos, endPosition = pos}
  end

  return orders
end

function Reload:getScore(unitId, order)
  local unit = Wargroove.getUnitById(unitId)
  local ammo = tonumber(Wargroove.getUnitState(unit, stateKey))
  local score = 0
  if ammo == 0 then
    score = 1.0
  elseif ammo == maxAmmo then
    score = -5.0
  else
    score = 0.5
  end

  return { score = score, healthDelta = 0, introspection = {}}
end

return Reload
