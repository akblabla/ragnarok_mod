local Wargroove = require "wargroove/wargroove"
local Ragnarok = require "initialized/ragnarok"
local OldBuffs = require "wargroove/unit_buffs"
local VisionTracker = require "initialized/vision_tracker"
local Corners = require "scripts/corners"
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
 

local Buffs = {}
local UnitBuffs = {}
local highAlertAnimation = "ui/icons/high_alert"
local function resetHighAlert(context)
    if (context:checkState("startOfTurn")) then
        for i,unit in pairs(Wargroove.getUnitsAtLocation()) do
            local highAlert = Wargroove.getUnitState(unit,"high_alert")
            if unit.playerId == Wargroove.getCurrentPlayerId() and (highAlert~=nil) and (highAlert == "true") then
                Wargroove.setUnitState(unit, "high_alert", "false")
                Wargroove.updateUnit(unit)
                Wargroove.highAlertBuff(unit)
            end
        end
    end
end


function Buffs.init()
    Ragnarok.addAction(resetHighAlert,"repeating",false)
    OldBuffs.getBuffs = UnitBuffs.getBuffs
end

local ClearBuffs = {}



function Buffs.crystal(Wargroove, unit)
    if Wargroove.isSimulating() then
        return
    end
    
    local effectPositions = Wargroove.getTargetsInRange(unit.pos, 3, "all")
    Wargroove.displayBuffVisualEffect(unit.id, unit.playerId, "units/commanders/emeric/crystal_aura", "idle", 0.3)

    local range = 3
    local positions = Wargroove.getTargetsInRange(unit.pos, range, "all")
    for i, pos in pairs(positions) do
        local u = Wargroove.getUnitAt(pos)

        -- If (and only if) it's your turn, or your ally's, also apply to empty tiles, because your unit might be about to move that.
        -- Otherwise, combat results preview will be wrong.
        -- Likewise, if this happens on an enemy's turn, preview will be wrong.
        -- Note that preview also affects AI's ability to judge moves.
        local includeEmpty = Wargroove.areAllies(Wargroove.getCurrentPlayerId(), unit.playerId)

        if (u == nil and includeEmpty) or (u ~= nil and Wargroove.areAllies(u.playerId, unit.playerId)) then
            local baseDefence = Wargroove.getBaseTerrainDefenceAt(pos)
            local currentDefence = Wargroove.getTerrainDefenceAt(pos)
            local newDefence = math.min(math.max(baseDefence + 3, currentDefence), 4)
            Wargroove.setTerrainDefenceAt(pos, newDefence)

            local baseSkyDefence = Wargroove.getBaseSkyDefence()
            local currentSkyDefence = Wargroove.getSkyDefenceAt(pos)
            local newSkyDefence = math.min(math.max(baseSkyDefence + 3, currentSkyDefence), 4)
            Wargroove.setSkyDefenceAt(pos, newSkyDefence)
        end
    end
end

function Buffs.smoke_producer(Wargroove, unit)
    local posString = Wargroove.getUnitState(unit, "pos")
    
    local vals = {}
    for val in posString.gmatch(posString, "([^"..",".."]+)") do
        vals[#vals+1] = val
    end
    local center = { x = tonumber(vals[1]), y = tonumber(vals[2])}

    local radius = 2
    
    if (not Wargroove.isSimulating()) then
        local effectPositions = Wargroove.getTargetsInRange(center, radius, "all")
        Wargroove.displayBuffVisualEffectAtPosition(unit.id, center, unit.playerId, "units/commanders/vesper/smoke", "idle", 0.3, effectPositions, "above_units")

        if (radius > 0) then
            local firePositions = Wargroove.getTargetsInRange(center, radius, "all")
            for i, pos in ipairs(firePositions) do
            Wargroove.displayBuffVisualEffectAtPosition(unit.id, pos, unit.playerId, "units/commanders/vesper/smoke_back", "", 0.6, effectPositions, "units", {x = 0, y = 0})
            Wargroove.displayBuffVisualEffectAtPosition(unit.id, pos, unit.playerId, "units/commanders/vesper/smoke_front", "", 0.8, effectPositions, "units", {x = 0, y = 2})
            end
        end
    end

    local positions = Wargroove.getTargetsInRange(center, radius, "unit")
    for i, pos in pairs(positions) do      
        local u = Wargroove.getUnitAt(pos)    
        u.canBeAttacked = false
    end
end

function ClearBuffs.smoke_producer(Wargroove, unit)
    local mapSize = Wargroove.getMapSize()
    for x0 = 0, mapSize.x do
        for y0 = 0, mapSize.y do
            local unit = Wargroove.getUnitAt({x = x0, y = y0})
            if unit ~= nil then
                unit.canBeAttacked = true
            end
        end
    end
end

function Buffs.area_heal(Wargroove, unit)
    if Wargroove.isSimulating() then
        return
    end

    local posString = Wargroove.getUnitState(unit, "pos")
    
    local vals = {}
    for val in posString.gmatch(posString, "([^"..",".."]+)") do
        vals[#vals+1] = val
    end
    local center = { x = tonumber(vals[1]), y = tonumber(vals[2])}
    local radius = tonumber(Wargroove.getUnitState(unit, "radius"))
  
    local effectPositions = Wargroove.getTargetsInRange(center, radius, "all")
    Wargroove.displayBuffVisualEffectAtPosition(unit.id, center, unit.playerId, "units/commanders/twins/area_heal_" .. tostring(radius), "idle", 0.3, effectPositions)

    local firePositions = Wargroove.getTargetsInRange(center, radius, "all")
    for i, pos in ipairs(firePositions) do
      Wargroove.displayBuffVisualEffectAtPosition(unit.id, pos, unit.playerId, "units/commanders/twins/heal_back2", "", 0.8, effectPositions, "units", {x = 0, y = 0})
      Wargroove.displayBuffVisualEffectAtPosition(unit.id, pos, unit.playerId, "units/commanders/twins/heal_back", "", 0.8, effectPositions, "units", {x = 0, y = 0})
      Wargroove.displayBuffVisualEffectAtPosition(unit.id, pos, unit.playerId, "units/commanders/twins/heal_front", "", 0.1, effectPositions, "units", {x = 0, y = 0})
    end

    local centerRadius = math.max(radius - 1, 0)
    local result = Buffs.createAreaThreatMap(Wargroove, center, radius, centerRadius, -0.2, -0.05)
    Wargroove.setThreatMap(unit.id, result)
end

function Buffs.area_damage(Wargroove, unit)
    if Wargroove.isSimulating() then
        return
    end

    local posString = Wargroove.getUnitState(unit, "pos")
    
    local vals = {}
    for val in posString.gmatch(posString, "([^"..",".."]+)") do
        vals[#vals+1] = val
    end
    local center = { x = tonumber(vals[1]), y = tonumber(vals[2])}
    local radius = tonumber(Wargroove.getUnitState(unit, "radius"))
  
    local effectPositions = Wargroove.getTargetsInRange(center, radius, "all")
    Wargroove.displayBuffVisualEffectAtPosition(unit.id, center, unit.playerId, "units/commanders/twins/area_damage", "idle_" .. tostring(radius), 0.3, effectPositions, "", {}, true)

    if (radius > 0) then
        local firePositions = Wargroove.getTargetsInRange(center, radius-1, "all")
        for i, pos in ipairs(firePositions) do
            Wargroove.displayBuffVisualEffectAtPosition(unit.id, pos, unit.playerId, "units/commanders/twins/smoke_back", "spawn", 0.6, effectPositions, "units", {x = 0, y = 0})
            Wargroove.displayBuffVisualEffectAtPosition(unit.id, pos, unit.playerId, "units/commanders/twins/fire_back", "spawn", 1.0, effectPositions, "units", {x = 0, y = 0})
            Wargroove.displayBuffVisualEffectAtPosition(unit.id, pos, unit.playerId, "units/commanders/twins/fire_front", "spawn", 1.0, effectPositions, "units", {x = 0, y = 2})
        end
    end

    local maxRadius = 3
    local result = Buffs.createAreaThreatMap(Wargroove, center, maxRadius, radius, 100, 1)
    Wargroove.setThreatMap(unit.id, result)
end

function Buffs.createAreaThreatMap(Wargroove, center, maxRadius, radius, centerValue, outerValue)
    local mapSize = Wargroove.getMapSize()

    local result = {}
    local x0 = center.x
    local y0 = center.y
    for yo = -maxRadius, maxRadius do
        for xo = -maxRadius, maxRadius do
            local distance = math.abs(xo) + math.abs(yo)            
            if distance <= maxRadius then
                local x = x0 + xo
                local y = y0 + yo
                if (x >= 0) and (y >= 0) and (x < mapSize.x) and (y < mapSize.y) then
                    local value = 0
                    if distance <= radius then
                        value = centerValue
                    else
                        value = outerValue
                    end
                    table.insert(result, {position = {x = x, y = y},  value = value})
                end
            end
        end
    end
    return result
end

local outOfAmmoAnimation = "ui/icons/bullet_out_of_ammo"

function Buffs.rifleman(Wargroove, unit)
    if Wargroove.isSimulating() then
        return
    end

    if (Wargroove.getUnitState(unit, "ammo") == nil) then
        Wargroove.setUnitState(unit, "ammo", 2)
        Wargroove.updateUnit(unit)
    end

    if (Wargroove.getUnitState(unit, "ammo") == "0") then
        if not Wargroove.hasUnitEffect(unit.id, outOfAmmoAnimation) then
            Wargroove.spawnUnitEffect(unit.id, outOfAmmoAnimation, "idle", startAnimation, true, false)
        end
    elseif Wargroove.hasUnitEffect(unit.id, outOfAmmoAnimation) then
        Wargroove.deleteUnitEffectByAnimation(unit.id, outOfAmmoAnimation)
    end
end

function Buffs.thief(Wargroove, unit)
    if Wargroove.isSimulating() then
        return
    end

    if (Wargroove.getUnitState(unit, "gold") == nil) then
        Wargroove.setUnitState(unit, "gold", 0)
        Wargroove.updateUnit(unit)
    end
end

function Buffs.thief_with_gold(Wargroove, unit)
    if Wargroove.isSimulating() then
        return
    end
    
    if (Wargroove.getUnitState(unit, "gold") == nil) then
        Wargroove.setUnitState(unit, "gold", 300)
        Wargroove.updateUnit(unit)
    end
end

function Buffs.travelboat(Wargroove, unit)
    if Wargroove.isSimulating() then
        return
    end

    if (Wargroove.getUnitState(unit, "gold") == nil) then
        Wargroove.setUnitState(unit, "gold", 0)
        Wargroove.updateUnit(unit)
    end
end

function Buffs.travelboat_with_gold(Wargroove, unit)
    if Wargroove.isSimulating() then
        return
    end
    
    if (Wargroove.getUnitState(unit, "gold") == nil) then
        Wargroove.setUnitState(unit, "gold", 300)
        Wargroove.updateUnit(unit)
    end
end

function Buffs.vision_tile(Wargroove, unit)
    if (not Wargroove.isSimulating()) then
        Corners.update(unit)
    end
end
function Buffs.fog(Wargroove, unit)
    if (not Wargroove.isSimulating()) then
--        Wargroove.displayBuffVisualEffectAtPosition(unit.id, {x=0,y=0}, unit.playerId, "units/fog/fog", "", 0.75, nil, nil, {x = 0, y = 2400},true)
    end
end

function ClearBuffs.vision_tile(Wargroove, unit)
    Wargroove.clearBuffVisualEffect(unit.id)
end

function UnitBuffs:getBuffs()
    return Buffs
end

function UnitBuffs:getClearBuffs()
    return ClearBuffs
end

return Buffs