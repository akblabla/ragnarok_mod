local Wargroove = require "wargroove/wargroove"
local GrooveVerb = require "wargroove/groove_verb"

local Gadgets = GrooveVerb:new()

Gadgets.itemToSpawn = nil

function Gadgets:getMaximumRange(unit, endPos)
    return 1
end

function Gadgets:getTargetType()
    return "all"
end

function Gadgets:preExecute(unit, targetPos, strParam, endPos)
    local itemsOptions = {"potion01", "axe", "money_bag", "potion02", "beer", "soul_poison"};
    
    -- setup rng string
    local values = { unit.id, unit.unitClassId, unit.pos.x, unit.pos.y, Wargroove.getTurnNumber(), Wargroove.getCurrentPlayerId() }
    local str = ""
    for i, v in ipairs(values) do
        str = str .. tostring(v) .. ":"
    end

    -- pick 3 random items out of all possible options
    local finalItems = {}
    for i=1,3,1 do
        local pick = Wargroove.randomInteger(str, 1, #itemsOptions)

        table.insert(finalItems, itemsOptions[pick])
        table.remove(itemsOptions, pick)
    end

    Wargroove.openItemPickMenu(unit.playerId, finalItems)

    while Wargroove.itemPickMenuIsOpen() do
        coroutine.yield()
    end

    Gadgets.itemToSpawn = Wargroove.popItemPickedClass();

    if Gadgets.itemToSpawn == nil then
        return false, ""
    end

    Wargroove.selectTarget()

    while Wargroove.waitingForSelectedTarget() do
        coroutine.yield()
    end

    local target = Wargroove.getSelectedTarget()

    if (target == nil) then
        Gadgets.itemToSpawn = nil
        return false, ""
    end

    return true, Gadgets.itemToSpawn
end


function Gadgets:canExecuteWithTarget(unit, endPos, targetPos, strParam)
    if not self:canSeeTarget(targetPos) then
        return false
    end

    return (endPos.x ~= targetPos.x or endPos.y ~= targetPos.y) and (u == nil or unit.id == u.id) and Wargroove.canStandAt("soldier", targetPos)
end


function Gadgets:execute(unit, targetPos, strParam, path)
    Gadgets.itemToSpawn = nil

    if strParam == "" then
        print("Gadgets was not given a class to recruit.")
        return
    end

    local facingOverride = ""
    if targetPos.x > unit.pos.x then
        facingOverride = "right"
    elseif targetPos.x < unit.pos.x then
        facingOverride = "left"
    end

    if facingOverride ~= "" then
        Wargroove.setFacingOverride(unit.id, facingOverride)
    end

    Wargroove.setIsUsingGroove(unit.id, true)
    Wargroove.updateUnit(unit)

    Wargroove.playPositionlessSound("battleStart")
    Wargroove.playGrooveCutscene(unit.id)

    Wargroove.playUnitAnimation(unit.id, "groove")
    Wargroove.playMapSound("nuru/nuruGroove", unit.pos)
    Wargroove.waitTime(1.7)

    Wargroove.playGrooveEffect()

    Wargroove.spawnItemAt(strParam, targetPos)
    Wargroove.unsetFacingOverride(unit.id)

    strParam = ""

    Wargroove.waitTime(1.0)
end


return Gadgets
