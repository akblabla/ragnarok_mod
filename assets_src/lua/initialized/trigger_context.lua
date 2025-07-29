local Wargroove = require "wargroove/wargroove"
local OldTriggerContext = require "triggers/trigger_context"


local TriggerContext = {}
function TriggerContext.init()
	OldTriggerContext.doesPlayerMatch = TriggerContext.doesPlayerMatch
	OldTriggerContext.gatherVerbsUsed = TriggerContext.gatherVerbsUsed
	
end
function TriggerContext:doesPlayerMatch(playerId, target)
    return (playerId == target) or (target == nil) or (playerId < 0 and target < 0)
end

function TriggerContext:gatherVerbsUsed(playerIndex, unitClassIndex, locationIndex, verbIndex, targetIndex)
    local playerId = self:getPlayerId(playerIndex)
    local unitClass = self:getUnitClass(unitClassIndex)
    local location = self:getLocation(locationIndex)
    local verb = self:getVerb(verbIndex)
    local target = self:getLocation(targetIndex)

    local result = {}

    for i, unit in ipairs(self.verbsUsed) do
        if self:doesUnitVerbMatch(unit, verb) then
            if self:doesPlayerMatch(unit.playerId, playerId) and self:doesUnitMatch(unit.unitClass, unitClass) and self:isInLocation(unit.pos, location) then
                if target ~= nil then
                    -- check against target location
                    local targets = Wargroove.stringToPositions(unit.verbUsed.strParam)
                    table.insert(targets, self.verbsUsed.targetPos)
                    for i, pos in ipairs(targets) do
                        if self:isInLocation(pos, target) then
                            table.insert(result, unit)
                            break
                        end
                    end
                else
                    -- *any* target location
                    table.insert(result, unit)
                end
            end
        end
    end

    return result
end

return TriggerContext
