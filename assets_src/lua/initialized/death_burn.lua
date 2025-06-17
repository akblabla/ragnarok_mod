local Wargroove = require "wargroove/wargroove"
local OldDeathBurn = require "verbs/death_burn"
local Verb = require "wargroove/verb"

local DeathBurn = Verb:new()

function DeathBurn.init()
	OldDeathBurn.execute = DeathBurn.execute
end

function DeathBurn:execute(unit, targetPos, strParam, path)
    local targetId = Wargroove.getUnitState(unit, "unitId")
    local targetUnit = Wargroove.getUnitById(tonumber(targetId))

    if targetUnit then
        local isBurning = Wargroove.getUnitState(targetUnit, "burning")

        if isBurning == "true" and targetUnit.health > 0 and (targetUnit.playerId ~= -1) and targetUnit.damageTakenPercent > 0 then
            Wargroove.trackCameraTo(targetUnit.pos)
            Wargroove.waitTime(0.5)

            Wargroove.playUnitAnimation(targetUnit, "hit")
            local damageAmount = 30
            targetUnit:setHealth(targetUnit.health - damageAmount, unit.id)
            Wargroove.updateUnit(targetUnit)

            -- Only spawn when health > 0, otherwise the player will have a unit on their team that can stop victory conditions triggering
            if targetUnit.health > 0 then
                local startingState = {}
                local unitId = {key = "unitId", value = targetUnit.id}
                table.insert(startingState, unitId)
                Wargroove.spawnUnit(targetUnit.playerId, {x = -100, y = -100}, "burn", false, "", startingState)
            end
            return
        end

        if isBurning == "false" then
            Wargroove.clearBuffVisualEffect(targetUnit.id)
        end
    end

    Wargroove.waitTime(0.5)
end

return DeathBurn
