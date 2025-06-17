local Wargroove = require "wargroove/wargroove"
local Verb = require "wargroove/verb"
local OldDefaultDeath = require "verbs/default_death"
local Ragnarok = require "initialized/ragnarok"

local DefaultDeath = Verb:new()
local OriginalDeath = {}
function DefaultDeath.init()
    OriginalDeath.execute = OldDefaultDeath.execute
	OldDefaultDeath.execute = DefaultDeath.execute

end


function DefaultDeath:execute(unit, targetPos, strParam, path)
    OriginalDeath.execute(OldDefaultDeath, unit, targetPos, strParam, path)
    if Ragnarok.hasCrown(unit) then
        Ragnarok.dropCrown(unit.pos)
    else
        print("DefaultDeath:execute")
        print("unit: "..unit.unitClassId)
        print("item id: "..unit.itemId)
        if (unit.unitClassId == "thief" or unit.unitClassId == "thief_with_gold") and unit.itemId ~= "" and unit.itemId ~= nil then
            
            local ic = Wargroove.getItem(unit.itemId)
            Wargroove.spawnItemAt(ic.id, unit.pos)
        end
    end
end

return DefaultDeath
