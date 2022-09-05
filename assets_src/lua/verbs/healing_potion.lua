local Wargroove = require "wargroove/wargroove"
local Verb = require "wargroove/verb"

local HealingPotion = Verb:new()


local maxHealAmount = 50
local chargesPerPlayerList = {}

function HealingPotion.setCharges(playerId,count)
    chargesPerPlayerList[Wargroove.getPlayerTeam(playerId)] = count
end

function HealingPotion.getCharges(playerId)
	if chargesPerPlayerList[Wargroove.getPlayerTeam(playerId)] ~= nil then
		return chargesPerPlayerList[Wargroove.getPlayerTeam(playerId)]
	end
	return 0
end

function HealingPotion:canExecuteAnywhere(unit)
    return HealingPotion.getCharges(unit.playerId) > 0
end

function HealingPotion:getMaximumRange(unit, endPos)
    return 0
end


function HealingPotion:getTargetType()
    return "unit"
end


function HealingPotion:execute(unit, targetPos, strParam, path)
    local targets = Wargroove.getTargetsInRange(targetPos, 3, "unit")
	Wargroove.playMapSound("potionPop", unit.pos)
    Wargroove.waitTime(0.5)
	
	
    Wargroove.spawnMapAnimation(targetPos, 3, "fx/groove/mercia_groove_fx", "idle", "behind_units", {x = 12, y = 12})

    local function distFromTarget(a)
        return math.abs(a.x - targetPos.x) + math.abs(a.y - targetPos.y)
    end
    table.sort(targets, function(a, b) return distFromTarget(a) < distFromTarget(b) end)

    for i, pos in ipairs(targets) do
        local u = Wargroove.getUnitAt(pos)
        local uc = u.unitClass
        if u ~= nil and Wargroove.areAllies(u.playerId, unit.playerId) and (not uc.isStructure) then
            u:setHealth(u.health + maxHealAmount, unit.id)
            Wargroove.updateUnit(u)
            Wargroove.spawnMapAnimation(pos, 0, "fx/heal_unit")
            Wargroove.playMapSound("unitHealed", pos)
            Wargroove.waitTime(0.2)
        end
    end
	HealingPotion.setCharges(unit.playerId,HealingPotion.getCharges(unit.playerId)-1)
    Wargroove.waitTime(1.0)
end

return HealingPotion
