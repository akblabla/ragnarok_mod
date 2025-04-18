local Wargroove = require "wargroove/wargroove"
local Verb = require "wargroove/verb"


local Capture = Verb:new()


function Capture:getMaximumRange(unit, endPos)
    return 1
end


function Capture:getTargetType()
    return "unit"
end


function Capture:canExecuteWithTarget(unit, endPos, targetPos, strParam)
    local targetUnit = Wargroove.getUnitAt(targetPos)
    if (Wargroove.getNetworkVersion() == '200000') then
        return targetUnit and targetUnit.unitClass.canBeCaptured and Wargroove.isNeutral(targetUnit.playerId)
    end

    local weapons = unit.unitClass.weapons
    
    if #weapons == 1 and weapons[1].unitIdWhenAttacking ~= "" and weapons[1].unitIdWhenAttacking ~= unit.unitClass then
        print("Capture consideration: UnitIdWhenAttacking")

        if not Wargroove.canStandAt(weapons[1].unitIdWhenAttacking, endPos) then
            return false
        end
    end

    return targetUnit and targetUnit.unitClass.canBeCaptured and (Wargroove.isNeutral(targetUnit.playerId) or not self:canSeeTarget(targetPos))
end


function Capture:execute(unit, targetPos, strParam, path)
    local endPos = unit.pos
    if path and #path > 0 then
        endPos = path[#path]
    end
    Wargroove.startCapture(unit, Wargroove.getUnitAt(targetPos), endPos)
end


return Capture
