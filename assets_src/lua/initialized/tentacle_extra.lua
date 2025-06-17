local OldTentacle = require "verbs/tentacle"
local Wargroove = require "wargroove/wargroove"

local OriginalTentacle = {}
local TentacleExtra = {}

function TentacleExtra.init()
    OriginalTentacle.canExecuteWithTarget = OldTentacle.canExecuteWithTarget
    OldTentacle.canExecuteWithTarget = TentacleExtra.canExecuteWithTarget

    OriginalTentacle.canSeeTarget = OldTentacle.canSeeTarget
end


function TentacleExtra:canExecuteWithTarget(unit, endPos, targetPos, strParam)
    local canExecute = OriginalTentacle:canExecuteWithTarget(unit, endPos, targetPos, strParam)

    local targetUnit = Wargroove.getUnitAt(targetPos)

    if targetUnit and targetUnit.unitClass.isCommander then
        return false
    end

    return canExecute
end

return TentacleExtra