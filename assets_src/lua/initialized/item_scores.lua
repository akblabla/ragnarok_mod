local Wargroove = require "wargroove/wargroove"
local OldItemScores = require "wargroove/item_scores"


local ItemScores = {}
function ItemScores.init()
	OldItemScores.generateOrders = ItemScores.generateOrders
	
end

function ItemScores.crown(unitId, order)
    local unit = Wargroove.getUnitById(unitId)
    local score = -1
    if unit.health > 20 then
        return orders
    end
    local score = 200
    return {score = score, introspection = {}}
end

return ItemScores
