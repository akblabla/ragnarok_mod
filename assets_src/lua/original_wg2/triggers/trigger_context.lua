local Wargroove = require "wargroove/wargroove"
local TriggerContext = {}


function TriggerContext:checkState(value)
    return self.state == value
end


function TriggerContext:getBoolean(index)
    return tonumber(self.params[index + 1]) ~= 0
end


function TriggerContext:getInteger(index)
    return tonumber(self.params[index + 1])
end


function TriggerContext:getString(index)
    return tostring(self.params[index + 1])
end


function TriggerContext:getOperator(index)
    local op = tonumber(self.params[index + 1]) + 1

    local operators = {
        function(a, b) return a == b end,
        function(a, b) return a ~= b end,
        function(a, b) return a > b end,
        function(a, b) return a < b end,
        function(a, b) return a >= b end,
        function(a, b) return a <= b end
    }

    return operators[op]
end


function TriggerContext:getOperation(index)
    local op = tonumber(self.params[index + 1]) + 1

    local operations = {
        function(a, b) return b end,
        function(a, b) return a + b end,
        function(a, b) return a - b end,
        function(a, b) return a * b end,
        function(a, b) return a / b end
    }

    return operations[op]
end


function TriggerContext:getArithmeticOperation(index)
    local op = tonumber(self.params[index + 1]) + 1

    local operations = {
        function(a, b) return a + b end,
        function(a, b) return a - b end,
        function(a, b) return a * b end,
        function(a, b) return a / b end
    }

    return operations[op]
end


function TriggerContext:getBooleanOperation(index)
    local op = tonumber(self.params[index + 1]) + 1

    local operations = {
        function(a, b) return a or b end,
        function(a, b) return a and (not b) end,
        function(a, b) return a and b end
    }

    return operations[op]
end


function TriggerContext:getMapFlag(index)
    return self.mapFlags[tonumber(self.params[index + 1])] == 1
end


function TriggerContext:setMapFlag(index, value)
    assert(type(value) == "boolean")
    self.mapFlags[tonumber(self.params[index + 1])] = value and 1 or 0
end

function TriggerContext:setMapFlagById(id, value)
    assert(type(value) == "boolean")
    self.mapFlags[id] = value and 1 or 0
end


function TriggerContext:getCampaignFlag(index)
    return self.campaignFlags[tonumber(self.params[index + 1])] == 1
end


function TriggerContext:setCampaignFlag(index, value)
    assert(type(value) == "boolean")
    self.campaignFlags[tonumber(self.params[index + 1])] = value and 1 or 0
end

function TriggerContext:addCampaignCutscene(index)
    table.insert(self.campaignCutscenes, self.params[index + 1])
end

function TriggerContext:setCreditsToPlay(index)
    self.creditsToPlay = self.params[index + 1]
end

function TriggerContext:getMapCounter(index)
    return self.mapCounters[tonumber(self.params[index + 1])] or 0
end


function TriggerContext:setMapCounter(index, value)
    assert(type(value) == "number")
    self.mapCounters[tonumber(self.params[index + 1])] = value
end


function TriggerContext:getUnitClass(index)
    local strValue = tostring(self.params[index + 1])
    local metaUnitClass = Wargroove.getMetaUnitClass(strValue)
    if metaUnitClass ~= nil then
        return metaUnitClass.id
    else
        return strValue
    end
end


function TriggerContext:getMapItem(index)
    return Wargroove.getMapItemById(self.params[index + 1])
end


function TriggerContext:getItemClass(index)
    return tostring(self.params[index + 1])
end

function TriggerContext:getLocation(index)
    return Wargroove.getLocationById(tonumber(self.params[index + 1]))
end

function TriggerContext:getFloodDirection(index)
    return tostring(self.params[index + 1])
end

function TriggerContext:getLocationCompare(index)
    return tostring(self.params[index + 1])
end

function TriggerContext:getLocationHighlight(index)
    return tostring(self.params[index + 1])
end

function TriggerContext:getPlayerColour(index)
    return tostring(self.params[index + 1])
end

function TriggerContext:getPlayerId(index)
    local strValue = tostring(self.params[index + 1])

    if strValue == "any" then
        return nil
    elseif strValue == "neutral" then
        return -1
    elseif strValue == "current" then
        return self.triggerInstancePlayerId
    elseif strValue:sub(1, 1) == "P" then
        return tonumber(strValue:sub(2)) - 1
    else
        return -1
    end
end

function TriggerContext:getTerrain(index)
    return tostring(self.params[index + 1])
end


function TriggerContext:getTeam(index)
    return tonumber(self.params[index + 1])
end


function TriggerContext:getCutscene(index)
    return self.params[index + 1]
end

function TriggerContext:getVerb(index)
    return tostring(self.params[index + 1])
end

function TriggerContext:doesPlayerMatch(playerId, target)
    return (playerId == target) or (target == nil) or (playerId < 0 and target < 0) or (Wargroove.areAllies(playerId, target))
end


function TriggerContext:doesUnitMatch(unitClass, pattern)
    if pattern == "" then
        pattern = "*unit"
    end

    if pattern:sub(1, 1) == "*" then
        -- Pattern match
        if pattern == "*unit" then
            return not unitClass.isStructure
        elseif pattern == "*structure" then
            return unitClass.isStructure
        elseif pattern == "*unit_structure" then
            return true
        elseif pattern == "*commander" then
            return unitClass.isCommander
        elseif pattern == "*non_commander" then
            return not unitClass.isCommander
        else
            return false
        end
    else
        if unitClass.aliasId ~= "" then            
            return unitClass.aliasId == pattern
        else
            return unitClass.id == pattern
        end
    end
end

function TriggerContext:doesItemMatch(item, pattern)
    if pattern == "" then
        pattern = "*item"
    end

    if pattern:sub(1, 1) == "*" then
        return true;
    else
        return item.type == pattern
    end
end

function TriggerContext:doesUnitVerbMatch(unit, pattern)
    if pattern == "" then
        pattern = "*verb"
    end

    if pattern:sub(1, 1) == "*" then
        return true;
    else
        return unit.verbUsed.verb == pattern
    end
end

function TriggerContext:doesUnitInteractionMatch(unit, pattern)
    if pattern == "" then
        pattern = "*verb"
    end

    if pattern:sub(1, 1) == "*" then
        return true
    else
        return unit.interactionUsed.verb == pattern
    end
end

function TriggerContext:isInLocation(position, location)
    if location == nil then
        return true
    end

    for i, p in ipairs(location.positions) do
        if position.x == p.x and position.y == p.y then
            return true
        end
    end
    
    return false
end


function TriggerContext:boolOpLocations(lhp, rhp, op)
    local area = {}
    local area1 = {}
    local area2 = {}
    local size = Wargroove.getMapSize()

    local function xyToId(x, y)
        return x + size.x * y
    end

    local function posToId(pos)
        return xyToId(pos.x, pos.y)
    end

    for i, p in ipairs(lhp:getArea()) do
        area1[posToId(p)] = true
    end
    for i, p in ipairs(rhp:getArea()) do
        area2[posToId(p)] = true
    end

    for y = 0, size.y - 1 do
        for x = 0, size.x - 1 do
            local a = area1[xyToId(x, y)] or false
            local b = area2[xyToId(x, y)] or false
            if op(a, b) then
                table.insert(area, {x = x, y = y})
            end
        end
    end
    return area
end

function TriggerContext:gatherUnits(playerIndex, unitClassIndex, locationIndex)
    local playerId = self:getPlayerId(playerIndex)
    local unitClass = self:getUnitClass(unitClassIndex)
    local location = self:getLocation(locationIndex)

    return self:doGatherUnits(playerId, unitClass, location)
end


function TriggerContext:doGatherUnits(playerId, unitClass, location)
    local result = {}
    for i, unit in ipairs(Wargroove.getUnitsAtLocation(location)) do
        if self:doesPlayerMatch(unit.playerId, playerId) and self:doesUnitMatch(unit.unitClass, unitClass) and not unit.inTransport then
            table.insert(result, unit)
        end
        for i, transportedUnitId in ipairs(unit.loadedUnits) do
            local transportedUnit = Wargroove.getUnitById(transportedUnitId)
            if self:doesPlayerMatch(transportedUnit.playerId, playerId) and self:doesUnitMatch(transportedUnit.unitClass, unitClass) then
                table.insert(result, transportedUnit)
            end
        end
    end

    return result
end


function TriggerContext:gatherDeadUnits(playerIndex, unitClassIndex, locationIndex)
    local playerId = self:getPlayerId(playerIndex)
    local unitClass = self:getUnitClass(unitClassIndex)
    local location = self:getLocation(locationIndex)

    local result = {}
    
    for i, unit in ipairs(self.deadUnits) do
        if self:doesPlayerMatch(unit.playerId, playerId) and self:doesUnitMatch(unit.unitClass, unitClass) and self:isInLocation(unit.pos, location) then
            table.insert(result, unit)
        end
    end

    return result
end


function TriggerContext:gatherItems(playerIndex, itemClassIndex, locationIndex)
    local itemClass = self:getItemClass(itemClassIndex)
    local location = self:getLocation(locationIndex)

    return self:doGatherItems(itemClass, location)
end


function TriggerContext:doGatherItems(itemClass, location)
    local result = {}
    for i, item in ipairs(Wargroove.getMapItemsAtLocation(location)) do
        if self:doesItemMatch(item, itemClass) then
            table.insert(result, item)
        end
    end

    return result
end


function TriggerContext:isInParty(characterIndex)
    local character = self:getString(characterIndex)
    for i, member in ipairs(self.party) do
        if member == character then
            return true
        end
    end
    return false
end

function TriggerContext:setPartyMember(characterIndex, inParty)
    local character = self:getString(characterIndex)
    local curIdx = -1
    for i, member in ipairs(self.party) do
        if member == character then
            curIdx = i
        end
    end

    if inParty then
        -- Add to party
        if curIdx == -1 then
            table.insert(self.party, character)
        end
    else
        -- Remove from party
        if curIdx ~= -1 then
            table.remove(self.party, curIdx)
        end
    end
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
                    if #targets == 0 and unit.verbUsed.strParam == "" then
                        -- If strParam is empty, use the units own position
                        -- TODO: I don't know if this is a good idea!
                        table.insert(targets, unit.pos)
                    end
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

function TriggerContext:gatherInteractionsUsed(playerIndex, unitClassIndex, locationIndex, targetIndex, verbIndex)
    local playerId = self:getPlayerId(playerIndex)
    local unitClass = self:getUnitClass(unitClassIndex)
    local location = self:getLocation(locationIndex)
    local target = self:getLocation(targetIndex)
    local verb = self:getVerb(verbIndex)

    local result = {}

    for i, unit in ipairs(self.interactionsUsed) do
        if self:doesUnitInteractionMatch(unit, verb) then
            if self:doesPlayerMatch(unit.playerId, playerId) and self:doesUnitMatch(unit.unitClass, unitClass) and self:isInLocation(unit.pos, location) and self:isInLocation(unit.interactionUsed.targetPos, target) then
                table.insert(result, unit)
            end
        end
    end

    return result
end

function TriggerContext:new(o)
    o = o or {}
    setmetatable(o, self)
    self.__index = self
    return o
end

return TriggerContext
