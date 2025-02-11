local VisionTracker = require "initialized/vision_tracker"
local Wargroove = require "wargroove/wargroove"
local StealthManager = require "scripts/stealth_manager"
local Corners = {}
local Ragnarok = require "initialized/ragnarok"

Corners.__index = Corners
local cornerNameMap = {}
local function getCornerIndex(NE,NW,SE,SW)
    local value = 0
    if NE then
        value = value+1
    end
    if NW then
        value = value+2
    end
    if SE then
        value = value+4
    end
    if SW then
        value = value+8
    end
    return value
end
local function getCornerFromIndex(index)
    local corner = {false,false,false,false}
    if index%2 == 1 then
        corner[1] = true
    end
    if math.floor(index/2)%2 == 1 then
        corner[2] = true
    end
    if math.floor(index/4)%2 == 1 then
        corner[3] = true
    end
    if math.floor(index/8)%2 == 1 then
        corner[4] = true
    end
    return corner
end

local function getCornerName(corners)
    local name = ""
    local underscroll = false
    if corners[1] then
        name = name.."NE"
        underscroll = true
    end
    if corners[2] then
        if underscroll then
            name = name.."_"
        end
        name = name.."NW"
        underscroll = true
    end
    if corners[3] then
        if underscroll then
            name = name.."_"
        end
        name = name.."SE"
        underscroll = true
    end
    if corners[4] then
        if underscroll then
            name = name.."_"
        end
        name = name.."SW"
        underscroll = true
    end
    return name
end

for i=1,15 do
    cornerNameMap[i] = getCornerName(getCornerFromIndex(i))
end
function Corners.init()
    Ragnarok.addAction(Corners.updateAll,"repeating",false)
end
function Corners.updateAll(context)
    for i,unit in ipairs(Wargroove.getUnitsAtLocation(nil)) do
        if unit.unitClassId == "vision_tile" then
            Corners.update(unit)
        end
    end
end

function Corners.getCornerName(corners)
    return cornerNameMap[getCornerIndex(corners[1],corners[2],corners[3],corners[4])]
end

function Corners.getVisionCorner(playerId, pos)
    local corners = {false,false,false,false}
    if Corners.shouldRenderTile(playerId,{x=pos.x,y=pos.y-1}) then
        corners[1] = true
    end
    if Corners.shouldRenderTile(playerId,{x=pos.x-1,y=pos.y-1}) then
        corners[2] = true
    end
    if Corners.shouldRenderTile(playerId,{x=pos.x,y=pos.y}) then
        corners[3] = true
    end
    if Corners.shouldRenderTile(playerId,{x=pos.x-1,y=pos.y}) then
        corners[4] = true
    end
    return corners
end
function Corners.shouldRenderTile(playerId, pos)
    local viewerPosList = VisionTracker.getListOfViewerIds(pos)
    for viewerId, viewerpos in pairs(viewerPosList) do
        local unit = Wargroove.getUnitById(viewerId)
        if (unit~= nil)  and (unit.playerId == playerId) and StealthManager.canBeAlerted(unit) then-- and (StealthManager.isUnitUnaware(unit) or StealthManager.isUnitSearching(unit)) then
            return Wargroove.canCurrentlySeeTile({x=pos.x,y=pos.y})
        end
    end
    return false
end

function Corners.update(cornerUnit)
    local playerId = tonumber(Wargroove.getUnitState(cornerUnit, "playerId"))
    Wargroove.setVisibleOverride(cornerUnit.id, true)
    local corners = Corners.getVisionCorner(playerId, {x=200+cornerUnit.pos.x,y=200+cornerUnit.pos.y})
    local cornerName = Corners.getCornerName(corners)
    if Corners.cornerList[cornerUnit.id] ~= cornerName then
        Wargroove.clearBuffVisualEffect(cornerUnit.id)
        if (cornerName~=nil) and (cornerName ~= "") and (cornerName ~= "NE_NW_SE_SW") then
            Wargroove.displayBuffVisualEffectAtPosition(cornerUnit.id, {x=cornerUnit.pos.x+200-1,y=cornerUnit.pos.y+300-1}, playerId, "units/LoSBorder/"..Corners.getCornerName(corners), "", 0.5, nil, nil, {x = 0, y = 0},true)
        end
        Corners.cornerList[cornerUnit.id] = cornerName
    end
    
end

Corners.cornerList = {}

return Corners
