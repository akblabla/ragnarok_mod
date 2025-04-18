local Wargroove = require "wargroove/wargroove"
local Conditions = {}

function Conditions.populate(dst)
    dst["start_of_turn"] = Conditions.startOfTurn
    dst["end_of_turn"] = Conditions.endOfTurn
    dst["end_of_unit_turn"] = Conditions.endOfUnitTurn
    dst["check_map_flag"] = Conditions.checkMapFlag
    dst["check_map_counter"] = Conditions.checkMapCounter
    dst["check_campaign_flag"] = Conditions.checkCampaignFlag
    dst["check_party_member"] = Conditions.checkPartyMember
    dst["current_turn_number"] = Conditions.currentTurnNumber
    dst["check_funds"] = Conditions.checkFunds
    dst["unit_presence"] = Conditions.unitPresence
    dst["player_turn"] = Conditions.playerTurn
    dst["number_of_opponents"] = Conditions.numberOfOpponents
    dst["unit_lost"] = Conditions.unitLost
    dst["unit_killed"] = Conditions.unitKilled
    dst["unit_health"] = Conditions.unitHealth
    dst["unit_groove"] = Conditions.unitGroove
    dst["unit_visible"] = Conditions.unitVisible
    dst["player_victorious"] = Conditions.playerVictorious
    dst["number_of_stars_map"] = Conditions.numberOfStars
    dst["number_of_stars_campaign"] = Conditions.numberOfStars
    dst["number_of_stars_after_victory"] = Conditions.numberOfStarsAfterVictory
    dst["check_gizmo_state"] = Conditions.checkGizmoState
    dst["counter_compare"] = Conditions.counterCompare
end

function Conditions.startOfTurn(context)
    -- "At the start of the turn"
    return context:checkState("startOfTurn")
end


function Conditions.endOfTurn(context)
    -- "At the end of the turn"
    return context:checkState("endOfTurn")
end


function Conditions.endOfUnitTurn(context)
    -- "At the end of a unit's turn"
    return context:checkState("endOfUnitTurn")
end


function Conditions.checkMapFlag(context)
    -- "Is map flag {0} {1}?"
    return context:getMapFlag(0) == context:getBoolean(1)
end


function Conditions.checkCampaignFlag(context)
    -- "Is campaign flag {0} {1}?"
    return context:getCampaignFlag(0) == context:getBoolean(1)
end


function Conditions.checkPartyMember(context)
    -- "Is {0}'s presence in party equal {1}?"
    return context:isInParty(0) == context:getBoolean(1)
end


function Conditions.checkMapCounter(context)
    -- "Is counter {0} {1} {2}?"
    local op = context:getOperator(1)
    return op(context:getMapCounter(0), context:getInteger(2))
end


function Conditions.currentTurnNumber(context)
    -- "Is the current turn day {0} {1}?"
    local op = context:getOperator(0)
    return op(Wargroove.getTurnNumber(), context:getInteger(1))
end


function Conditions.playerTurn(context)
    -- "Is it {0}'s turn?"
    return Wargroove.getCurrentPlayerId() == context:getPlayerId(0)
end


function Conditions.checkFunds(context)
    -- "Are the funds for {0} {1} {2}?"
    local playerId = context:getPlayerId(0)
    local operator = context:getOperator(1)
    local value = context:getInteger(2)
    local money = Wargroove.getMoney(playerId)

    return operator(money, value)
end


function Conditions.unitPresence(context)
    -- "Does {0} have {1} {2} of {3} at {4}?"
    local operator = context:getOperator(1)
    local value = context:getInteger(2)
    local units = context:gatherUnits(0, 3, 4)

    return operator(#units, value)
end


function Conditions.unitHealth(context)
    -- "Does {0} have {1} {2} of {3} at {4} with {5} {6}% health?"
    local operator = context:getOperator(1)
    local value = context:getInteger(2)
    local units = context:gatherUnits(0, 3, 4)
    local operator2 = context:getOperator(5)
    local value2 = context:getInteger(6)

    local nMatching = 0
    for i, unit in ipairs(units) do
        if operator2(unit.health, value2) then
            nMatching = nMatching + 1
        end
    end

    return operator(nMatching, value)
end


function Conditions.unitGroove(context)
    -- "Does {0} have {1} {2} of {3} at {4} with {5} {6}% groove?"
    local operator = context:getOperator(1)
    local value = context:getInteger(2)
    local units = context:gatherUnits(0, 3, 4)
    local operator2 = context:getOperator(5)
    local value2 = context:getInteger(6)

    local nMatching = 0
    for i, unit in ipairs(units) do
        if (unit.unitClass.maxGroove > 0) then
            local groove = math.floor(unit.grooveCharge * 100 / unit.unitClass.maxGroove + 0.5)
            if operator2(groove, value2) then
                nMatching = nMatching + 1
            end
        end
    end

    return operator(nMatching, value)
end


function Conditions.numberOfOpponents(context)
    -- "{0} has {1} {2} opponents in the game."
    local playerId = context:getPlayerId(0)
    local operator = context:getOperator(1)
    local value = context:getInteger(2)

    return operator(Wargroove.getNumberOfOpponents(playerId), value)
end


function Conditions.unitLost(context)
    -- "{0} owned by {1} is lost at {2}."
    local playerId = context:getPlayerId(1)
    local unitClass = context:getUnitClass(0)
    local location = context:getLocation(2)

    return #context:gatherDeadUnits(1, 0, 2) > 0
end


function Conditions.unitKilled(context)
    -- "{0} owned by {1} kills {2} owned by {3} at {4}."
    local unitClass = context:getUnitClass(0)
    local playerId = context:getPlayerId(1)
    local units = context:gatherDeadUnits(3, 2, 4)
    
    for i, unit in ipairs(units) do
        if unit.attackerId >= 0 then
            if context:doesPlayerMatch(unit.attackerPlayerId, playerId) and context:doesUnitMatch(Wargroove.getUnitClass(unit.attackerUnitClass), unitClass) then
                return true
            end
        end
    end
    
    return false
end

function Conditions.unitVisible(context)
    -- "{0} owned by {1} at {2} can be seen by {3}."
    local units = context:gatherUnits(1, 0, 2)
    local playerSeer = context:getPlayerId(3)
    for i, unit in ipairs(units) do
        if Wargroove.canPlayerSeeTile(playerSeer, unit.pos) then
            return true
        end
    end

    return false
end

function Conditions.playerVictorious(context)
    -- "Player {0} is victorioius."
    return Wargroove.isPlayerVictorious(context:getPlayerId(0))
end

function Conditions.numberOfStars(context)
    -- "Triggers if the game has at least {0} stars unlocked."
    local numStars = context:getInteger(0)
    return Wargroove.getNumberOfStars() > numStars;
end

function Conditions.numberOfStarsAfterVictory(context)
    -- "Triggers if the player will have {0} {1} stars unlocked if he completes the map now."
    local operator = context:getOperator(0)
    local numStars = context:getInteger(1)
    return operator(Wargroove.getNumberOfStarsAfterVictory(Wargroove.getTurnNumber()), numStars)
end

function Conditions.checkGizmoState(context)
    -- "Do {0} {1} gizmos at location {2} have state {3}?"
    local operator = context:getOperator(0)
    local value = context:getInteger(1)
    local location = context:getLocation(2)
    local state = context:getBoolean(3)
    
    local count = 0

    for i, gizmo in ipairs(Wargroove.getGizmosAtLocation(location)) do
        if gizmo:getState() == state then
            count = count + 1
        end
    end

    return operator(count, value)
end

function Conditions.counterCompare(context)
    -- "Is {0} {1} {2}?"
    local op = context:getOperator(1)
    return op(context:getMapCounter(0), context:getMapCounter(2))
end

return Conditions
