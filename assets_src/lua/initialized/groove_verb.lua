local Wargroove = require "wargroove/wargroove"
local OldGrooveVerb = require "wargroove/groove_verb"
local function dump(o,level)
    if type(o) == 'table' then
       local s = '\n' .. string.rep("   ", level) .. '{\n'
       for k,v in pairs(o) do
          if type(k) ~= 'number' then k = '"'..k..'"' end
          s = s .. string.rep("   ", level+1) .. '['..k..'] = ' .. dump(v,level+1) .. ',\n'
       end
       return s .. string.rep("   ", level) .. '}'
    else
       return tostring(o)
    end
 end

local GrooveVerb = {}
function GrooveVerb.init()
    OldGrooveVerb.consumeGroove = GrooveVerb.consumeGroove
    OldGrooveVerb.getTier = GrooveVerb.getTier
end

function GrooveVerb:consumeGroove(unit)
    local groove = Wargroove.getGroove(self:getGrooveId(unit))
    unit.grooveChargeOnUse = unit.grooveCharge
    unit.grooveCharge = unit.grooveCharge-groove.grooveCost[GrooveVerb:getTier(unit)]
    if unit.grooveCharge<0 then unit.grooveCharge = 0 end
    Wargroove.updateUnit(unit)
end

function GrooveVerb:getTier(unit)
    return 2;
end


return GrooveVerb