local UnitBuffSpawns = {}

local BuffSpawns = {}

function BuffSpawns.crystal(Wargroove, unit)
    local effectPositions = Wargroove.getTargetsInRange(unit.pos, 3, "all")
    Wargroove.displayBuffVisualEffect(unit.id, unit.playerId, "units/commanders/emeric/crystal_aura", "spawn", 0.3, effectPositions)
end

function BuffSpawns.smoke_producer(Wargroove, unit)
  local posString = Wargroove.getUnitState(unit, "pos")
  
  local vals = {}
  for val in posString.gmatch(posString, "([^"..",".."]+)") do
      vals[#vals+1] = val
  end
  local center = { x = tonumber(vals[1]), y = tonumber(vals[2])}
  local radius = 2

  local effectPositions = Wargroove.getTargetsInRange(center, radius, "all")
  Wargroove.displayBuffVisualEffectAtPosition(unit.id, center, unit.playerId, "units/commanders/vesper/smoke", "spawn", 0.7, effectPositions, "above_units")
  
  if (radius > 0) then
        local firePositions = Wargroove.getTargetsInRange(center, radius, "all")
        for i, pos in ipairs(firePositions) do
            Wargroove.displayBuffVisualEffectAtPosition(unit.id, pos, unit.playerId, "units/commanders/vesper/smoke_back", "spawn", 0.6, effectPositions, "units", {x = 0, y = 0})
            Wargroove.displayBuffVisualEffectAtPosition(unit.id, pos, unit.playerId, "units/commanders/vesper/smoke_front", "spawn", 0.8, effectPositions, "units", {x = 0, y = 2})
        end
    end
end

function BuffSpawns.area_heal(Wargroove, unit)
    local posString = Wargroove.getUnitState(unit, "pos")
    
    local vals = {}
    for val in posString.gmatch(posString, "([^"..",".."]+)") do
        vals[#vals+1] = val
    end
    local center = { x = tonumber(vals[1]), y = tonumber(vals[2])}
  
    local radius = tonumber(Wargroove.getUnitState(unit, "radius"))

    local effectPositions = Wargroove.getTargetsInRange(center, radius, "all")
    Wargroove.displayBuffVisualEffectAtPosition(unit.id, center, unit.playerId, "units/commanders/twins/area_heal_" .. tostring(radius), "spawn", 0.3, effectPositions)
    
    local firePositions = Wargroove.getTargetsInRange(center, radius, "all")
    for i, pos in ipairs(firePositions) do
        Wargroove.displayBuffVisualEffectAtPosition(unit.id, pos, unit.playerId, "units/commanders/twins/heal_back2", "spawn", 0.5, effectPositions, "units", {x = 0, y = 0})
        Wargroove.displayBuffVisualEffectAtPosition(unit.id, pos, unit.playerId, "units/commanders/twins/heal_back", "spawn", 0.8, effectPositions, "units", {x = 0, y = 0})
        Wargroove.displayBuffVisualEffectAtPosition(unit.id, pos, unit.playerId, "units/commanders/twins/heal_front", "spawn", 0.1, effectPositions, "units", {x = 0, y = 0})
    end
end

function BuffSpawns.area_damage(Wargroove, unit)
    local posString = Wargroove.getUnitState(unit, "pos")
    
    local vals = {}
    for val in posString.gmatch(posString, "([^"..",".."]+)") do
        vals[#vals+1] = val
    end
    local center = { x = tonumber(vals[1]), y = tonumber(vals[2])}
  
    local radius = tonumber(Wargroove.getUnitState(unit, "radius"))

    local effectPositions = Wargroove.getTargetsInRange(center, radius, "all")
    if (radius == 0) then
        Wargroove.displayBuffVisualEffectAtPosition(unit.id, center, unit.playerId, "units/commanders/twins/area_damage", "spawn", 0.3, effectPositions)
    else
        local firePositions = Wargroove.getTargetsInRange(center, radius-1, "all")
        for i, pos in ipairs(firePositions) do
            Wargroove.displayBuffVisualEffectAtPosition(unit.id, pos, unit.playerId, "units/commanders/twins/smoke_back", "spawn", 0.6, effectPositions, "units", {x = 0, y = 0})
            Wargroove.displayBuffVisualEffectAtPosition(unit.id, pos, unit.playerId, "units/commanders/twins/fire_back", "spawn", 1.0, effectPositions, "units", {x = 0, y = 0})
            Wargroove.displayBuffVisualEffectAtPosition(unit.id, pos, unit.playerId, "units/commanders/twins/fire_front", "spawn", 1.0, effectPositions, "units", {x = 0, y = 2})
        end
    end
end

function UnitBuffSpawns:getBuffSpawns()
    return BuffSpawns
end

return UnitBuffSpawns