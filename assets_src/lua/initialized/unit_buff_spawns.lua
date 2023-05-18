local Wargroove = require "wargroove/wargroove"
local OldBuffSpawns = require "wargroove/unit_buff_spawns"
local VisionTracker = require "initialized/vision_tracker"
local Corners = require "scripts/corners"

local BuffSpawns = {}
local UnitBuffSpawns = {}
function UnitBuffSpawns.init()
    OldBuffSpawns.getBuffSpawns = UnitBuffSpawns.getBuffSpawns
end


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

-- function BuffSpawns.stealth_rules(Wargroove, unit)
--     local corners = Corners.getVisionCorner(unit.playerId, {x=200+unit.pos.x,y=200+unit.pos.y})
--     local cornerName = Corners.getCornerName(corners)
--     if Corners.cornerList[unit.id] ~= cornerName then
--         if (cornerName~=nil) and (cornerName ~= "") and (cornerName ~= "NE_NW_SE_SW") then
--             Wargroove.displayBuffVisualEffectAtPosition(unit.id, {x=unit.pos.x+200-1,y=unit.pos.y+300-1}, unit.playerId, "units/LoSBorder/"..Corners.getCornerName(corners), "", 0.5, nil, "units", {x = 0, y = 0},true)
--         end
--         Corners.cornerList[unit.id] = cornerName
--     end
-- end
function UnitBuffSpawns:getBuffSpawns()
    return BuffSpawns
end

return UnitBuffSpawns