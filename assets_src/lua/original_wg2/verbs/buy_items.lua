local Wargroove = require "wargroove/wargroove"
local Verb = require "wargroove/verb"

local BuyItems = Verb:new()


function BuyItems:getMaximumRange(unit, endPos)
    return 1
end


function BuyItems:getTargetType()
    return "empty"
end


function BuyItems:canExecuteWithTarget(unit, endPos, targetPos, strParam)
    if strParam == nil or strParam == "" then
        return true
    end

    local params = Wargroove.splitString(strParam, ",")
    if #params < 2 then
        return false
    end

    local ic = Wargroove.getItem(params[1])

    local merchantDiscount = 1.0
    if Wargroove.isInList(params[1], unit.merchantDiscounts) then
        merchantDiscount = unit.merchantDiscountMultiplier
    end

    if params[2] == "crystal" then
        return true
    else
        return Wargroove.getMoney(unit.playerId) >= (ic.cost *  merchantDiscount)
    end
end


function BuyItems:execute(unit, targetPos, strParam, path)
    local params = Wargroove.splitString(strParam, ",")
    if #params < 2 then
        return
    end

    local ic = Wargroove.getItem(params[1])

    local merchantDiscount = 1.0
    if Wargroove.isInList(params[1], unit.merchantDiscounts) then
        merchantDiscount = unit.merchantDiscountMultiplier
    end

    if params[2] == "crystal" then
        Wargroove.rewardCrystals(-ic.crystalCost)
    else
        Wargroove.changeMoney(unit.playerId, -(ic.cost * merchantDiscount))
    end
    
    Wargroove.spawnItemAt(ic.id, targetPos)
    if Wargroove.canCurrentlySeeTile(targetPos) then
        Wargroove.spawnMapAnimation(targetPos, 0, "fx/mapeditor_unitdrop")
        Wargroove.playMapSound("spawn", targetPos)
    end

    Wargroove.reportItemPurchased(unit.id, params[1])
end


return BuyItems
