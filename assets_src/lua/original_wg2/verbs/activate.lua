local Wargroove = require "wargroove/wargroove"
local Capture = require "verbs/capture"


local Activate = Capture:new()

function Activate:canExecuteWithTarget(unit, endPos, targetPos, strParam)
    local targetUnit = Wargroove.getUnitAt(targetPos)
    local weapons = unit.unitClass.weapons

    if not targetUnit then
        return false
    end

    if #weapons == 1 and weapons[1].unitIdWhenAttacking ~= "" and weapons[1].unitIdWhenAttacking ~= unit.unitClass then
        print("Capture consideration: UnitIdWhenAttacking")

        if not Wargroove.canStandAt(weapons[1].unitIdWhenAttacking, endPos) then
            return false
        end
    end

    -- print("Can be activated: "..tostring(targetUnit.unitClass.canBeActivated))

    return targetUnit and targetUnit.unitClass.canBeActivated and (Wargroove.isNeutral(targetUnit.playerId) or not self:canSeeTarget(targetPos))
end


return Activate
