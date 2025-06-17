local UnitPostCombat = require "wargroove/unit_post_combat"
local PostCombatTruncate = {}

local UnitPostCombatTruncate = {}

local OriginalUnitPostCombat = {}

function UnitPostCombatTruncate.init()
    OriginalUnitPostCombat.getPostCombat = UnitPostCombat.getPostCombat
    UnitPostCombat.getPostCombat = UnitPostCombatTruncate.getPostCombat
end

function PostCombatTruncate.kraken(Wargroove, unit, isAttacker, healthAfterCombat)
    print("PostCombatTruncate.kraken")
    return
end

function PostCombatTruncate.tentacle(Wargroove, unit, isAttacker, healthAfterCombat)
    print("PostCombatTruncate.tentacle")
    return
end

function UnitPostCombatTruncate:getPostCombat(unitClassId)
    if PostCombatTruncate[unitClassId] ~= nil then
        print("PostCombatTruncate[".. unitClassId .. "]")
        return PostCombatTruncate[unitClassId]
    else
        print("OriginalUnitPostCombat["..unitClassId.."]")
        return OriginalUnitPostCombat:getPostCombat(unitClassId)
    end
end

return UnitPostCombatTruncate