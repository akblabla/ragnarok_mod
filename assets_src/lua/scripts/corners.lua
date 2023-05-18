local VisionTracker = require "initialized/vision_tracker"
local Wargroove = require "wargroove/wargroove"
local Corners = {}

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

function Corners.getCornerName(corners)
    return cornerNameMap[getCornerIndex(corners[1],corners[2],corners[3],corners[4])]
end

function Corners.getVisionCorner(playerId, pos)
    local corners = {false,false,false,false}
    if VisionTracker.canSeeTile(playerId,{x=pos.x,y=pos.y-1}) then
        corners[1] = true
    end
    if VisionTracker.canSeeTile(playerId,{x=pos.x-1,y=pos.y-1}) then
        corners[2] = true
    end
    if VisionTracker.canSeeTile(playerId,{x=pos.x,y=pos.y}) then
        corners[3] = true
    end
    if VisionTracker.canSeeTile(playerId,{x=pos.x-1,y=pos.y}) then
        corners[4] = true
    end
    return corners
end

Corners.cornerList = {}

return Corners
