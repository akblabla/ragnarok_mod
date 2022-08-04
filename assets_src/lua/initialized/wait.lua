local Wargroove = require "wargroove/wargroove"
local OldWait = require "verbs/wait"
local Combat = require "wargroove/combat"


local Wait = {}
function Wait.init()
end

function Wait:canExecute(unit, endPos, targetPos, strParam)

    local moveDistance = math.abs(endPos.x - unit.pos.x) + math.abs(endPos.y - unit.pos.y)
    return moveDistance < 3
end


return Wait
