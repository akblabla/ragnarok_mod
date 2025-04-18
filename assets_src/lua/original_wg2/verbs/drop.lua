local Wargroove = require "wargroove/wargroove"
local Verb = require "wargroove/verb"


local Drop = Verb:new()


function Drop:getMaximumRange(unit, endPos)
    return 1
end

function Drop:getTargetType()
    return "empty"
end

function Drop:canExecuteWithTarget(unit, endPos, targetPos, strParam)
    if(unit.itemId == nil or unit.itemId == "") then
        return false
    end

    return true
end

function Drop:execute(unit, targetPos, strParam, path)
    print("Item dropped at " .. targetPos.x .. "," ..targetPos.y)

    Wargroove.dropItem(unit, targetPos)

    Wargroove.waitTime(0.1)

    Wargroove.updateUnit(unit)
end


return Drop