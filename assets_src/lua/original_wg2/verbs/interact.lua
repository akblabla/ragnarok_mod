local Wargroove = require "wargroove/wargroove"
local Verb = require "wargroove/verb"


local Interact = Verb:new()


function Interact:getMaximumRange(unit, endPos)
    return 1
end


function Interact:getTargetType()
    return "all"
end

function Interact:preExecute(unit, targetPos, strParam, endPos)
    print("Interact pre")
    Wargroove.setInteractTarget(targetPos)
    Wargroove.checkTriggers("startOfInteract")

    while Wargroove.interactionsMenuIsOpen() do
        coroutine.yield()
    end

    local interactVerb = Wargroove.getInteractionsVerb()
    if interactVerb == "cancel" then
        return false, ""
    end

    return true, interactVerb
end

function Interact:canExecuteWithTarget(unit, endPos, targetPos, strParam)
    local locs = Wargroove.getLocationIdsAt(targetPos.x, targetPos.y)

    for i, locId in ipairs(locs) do
        local loc = Wargroove.getLocationById(locId)

        if loc and loc.interactable then
            return true
        end
    end

    return false
end


function Interact:execute(unit, targetPos, strParam, path)
    print("Executing custom interaction: " .. strParam)

    Wargroove.reportInteractionUsed(unit.id, strParam, targetPos, path)
end


return Interact
