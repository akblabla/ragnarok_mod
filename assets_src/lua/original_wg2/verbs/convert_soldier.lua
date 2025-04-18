local Wargroove = require "wargroove/wargroove"
local Verb = require "wargroove/verb"

local ConvertSoldier = Verb:new()
local costScoreFactor = 0.5

ConvertSoldier.isInPreExecute = false
ConvertSoldier.schoolLocation = nil

local defaultUnits = {"soldier", "spearman", "dog"}

local conversionUnits = {
    [1] = { "soldier", "spearman", "dog", "wagon", "mage", "archer", "knight", "ballista", "trebuchet", "giant" },
    [2] = { "caravel", "merman", "frog", "travelboat", "harpoonship", "turtle", "kraken", "warship" }
}

function ConvertSoldier:getMaximumRange(unit, endPos)
    return 3
end


function ConvertSoldier:getTargetType()
    if ConvertSoldier.isInPreExecute then
        return "all"
    end

    return "unit"
end


function ConvertSoldier:canExecuteAnywhere(unit)
    for i, u in ipairs(conversionUnits[1]) do
        if u == unit.unitClassId then
            return true
        end
    end
    for i, u in ipairs(conversionUnits[2]) do
        if u == unit.unitClassId then
            return true
        end
    end
    return false
end

local function getSurroundingSchools(unit, pos)
    result = {}
    for i, p in ipairs(Wargroove.getTargetsInRangeAfterMove(unit, pos, pos, 1, "unit")) do
        local school = Wargroove.getUnitAt(p)
        if school and school.unitClassId == "conversion_school" and Wargroove.areAllies(unit.playerId, school.playerId) and not school.hadTurn then
            table.insert(result, school)
        end
    end
    return result
end

function ConvertSoldier:targetsToString(targets)
    local strParam = ""
    local start = true
    for unitId, target in pairs(targets) do
        if start then
            start = false
        else
            strParam = strParam .. ";"
        end

        strParam = strParam .. unitId .. ":" .. target.x .. "," .. target.y
    end
    return strParam
end

function ConvertSoldier:getRecruitableTargets(unit)
    local targetTags = unit.unitClass.tags
    for i, tag in ipairs(targetTags) do
        if tag == "type.ground.light" or tag == "type.ground.medium" or tag == "type.ground.heavy" then
            return 2, conversionUnits[2]
        elseif tag == "type.sea.light" or tag == "type.sea.medium" or tag == "type.sea.heavy" or tag == "type.amphibious.heavy" or tag == "type.amphibious.light" then
            return 1, conversionUnits[1]
        end
    end
    return 0, nil
end

ConvertSoldier.classToConvertTo = nil

function ConvertSoldier:getDiscount(unit)
    local fullCost = Wargroove.getUnitClass(unit.unitClassId, unit.id).cost
    return math.ceil(unit.health * fullCost / 100)
end

function ConvertSoldier:preExecute(unit, targetPos, strParam, endPos)
    ConvertSoldier.isInPreExecute = true

    -- This is a bit awkward, but if we don't directly target, let's select a school first
    local target = Wargroove.getUnitAt(targetPos)
    if target == nil then
        ConvertSoldier.schoolLocation = nil
        Wargroove.selectTarget()

        while Wargroove.waitingForSelectedTarget() do
            coroutine.yield()
        end

        ConvertSoldier.schoolLocation = Wargroove.getSelectedTarget()
        if ConvertSoldier.schoolLocation == nil then
            ConvertSoldier.isInPreExecute = false
            return false, ""
        end
    else
        ConvertSoldier.schoolLocation = targetPos
    end

    local recruitableTable, recruitableUnits = ConvertSoldier:getRecruitableTargets(unit)
    --print(recruitableTable .. " : " .. Wargroove.tableToString(recruitableUnits))

    local discount = ConvertSoldier:getDiscount(unit)
    Wargroove.openRecruitMenu(unit.playerId, unit.id, unit.pos, "conversion_school", recruitableUnits, unit.health/100.0, defaultUnits, "", discount)
    while Wargroove.recruitMenuIsOpen() do
        coroutine.yield()
    end

    local classToConvert = Wargroove.popRecruitedUnitClass()
    if classToConvert == nil then
        ConvertSoldier.isInPreExecute = false
        ConvertSoldier.schoolLocation = nil
        return false, ""
    end
    ConvertSoldier.classToConvertTo = classToConvert
    local classIndex = Wargroove.indexInList(classToConvert, conversionUnits[recruitableTable])

    Wargroove.selectTarget()

    while Wargroove.waitingForSelectedTarget() do
        coroutine.yield()
    end

    local dropTarget = Wargroove.getSelectedTarget()
    if dropTarget == nil then
        ConvertSoldier.classToConvertTo = nil
        ConvertSoldier.isInPreExecute = false
        ConvertSoldier.schoolLocation = nil
        return false, ""
    end

    local result = {}
    result[1] = dropTarget
    result[2] = ConvertSoldier.schoolLocation
    result[3] = { x = recruitableTable, y = classIndex }

    ConvertSoldier.isInPreExecute = false
    ConvertSoldier.schoolLocation = nil
    return true, ConvertSoldier:targetsToString(result)
end

function ConvertSoldier:canExecuteAt(unit, endPos)
    if not Verb.canExecuteAt(self, unit, endPos) then
        return false
    end

    local schools = getSurroundingSchools(unit, endPos)
    if #schools > 0 then
        return true
    end

    return false
end

function ConvertSoldier:canExecuteWithTarget(unit, endPos, targetPos, strParam)
    if ConvertSoldier.isInPreExecute then
        if ConvertSoldier.schoolLocation == nil then
            local school = Wargroove.getUnitAt(targetPos)

            if school and school.unitClassId == "conversion_school" and Wargroove.areAllies(unit.playerId, school.playerId) then
                return true
            end

            return false
        else
            local dropPositions = Wargroove.getTargetsInRange(ConvertSoldier.schoolLocation, 1, "empty")

            for i, pos in pairs(dropPositions) do
                if targetPos.x == pos.x and targetPos.y == pos.y and Wargroove.canStandAt(ConvertSoldier.classToConvertTo, pos) then
                    return true
                end
            end
            return false
        end
    else
        if strParam and strParam ~= "" then
            -- This happens during execute, so we presume it's valid
            return true
        else
            -- this is for any target filtering BEFORE we have selected a school
            local school = Wargroove.getUnitAt(targetPos)
            if school and school.unitClassId == "conversion_school" and Wargroove.areAllies(unit.playerId, school.playerId) then
                return true
            end
        end
    end

    return false
end

function ConvertSoldier:execute(unit, targetPos, strParam, path)
    local targets = Wargroove.stringToPositions(strParam)

    -- the unit class is "encoded" in the third target X/Y
    if #targets > 2 and targets[3].y > 0 then
        ConvertSoldier.classToConvertTo = conversionUnits[targets[3].x][targets[3].y]
    end

    local uc = Wargroove.getUnitClass(ConvertSoldier.classToConvertTo)
    local discount = ConvertSoldier:getDiscount(unit)
    local cost = math.max(uc.cost * (unit.health/100) - discount, 0)

    Wargroove.changeMoney(unit.playerId, -cost)

    local remove_anim = "fx/mapeditor_unitdrop"
    local add_anim = "fx/unit_splash"

    Wargroove.spawnMapAnimation(unit.pos, 0, remove_anim)
    Wargroove.waitTime(0.1)

    unit.pos.x = -100
    unit.pos.y = -100
    Wargroove.updateUnit(unit)
    
    Wargroove.waitTime(0.4)
    Wargroove.spawnMapAnimation(targets[1], 0, add_anim)

    if unit.itemId ~= "" then
        unit.itemId = ""
    end
    unit.pos.x = targets[1].x
    unit.pos.y = targets[1].y
    unit.unitClassId = ConvertSoldier.classToConvertTo

    if not Wargroove.isConquestMode() then
        unit.hadTurn = true
    end

    Wargroove.updateUnit(unit)

    if not Wargroove.isConquestMode() then
        local school = Wargroove.getUnitAt(targets[2])
        school.hadTurn = true
        Wargroove.updateUnit(school)
    end

    ConvertSoldier.classToConvertTo = nil
end

function ConvertSoldier:generateOrders(unitId, canMove)
    local orders = {}

    local unit = Wargroove.getUnitById(unitId)
    local unitClass = Wargroove.getUnitClass(unit.unitClassId)

    if not self:canExecuteAnywhere(unit) then
        return orders
    end

    local recruitableTable, recruitableUnits = ConvertSoldier:getRecruitableTargets(unit);
    if recruitableUnits == nil or #recruitableUnits < 1 then
        return orders
    end

    -- Build a lookup table, with indices into "recruitableUnits", with
    -- the units the AI player can afford to convert to.
    --print("AI : convert_soldier orders for " .. unit.id)
    local affordableUnitsLookup = {}
    local money = Wargroove.getMoney(unit.playerId)
    local discount = ConvertSoldier:getDiscount(unit)
    for i, recruit in ipairs(recruitableUnits) do
        local uc = Wargroove.getUnitClass(recruit)
        local cost = math.max(uc.cost * (unit.health/100) - discount, 0)
        -- TODO: check why cost is sometimes 0
        if (cost > 0) and (money >= cost) then
            table.insert(affordableUnitsLookup, i)
        end
    end

    if #affordableUnitsLookup < 1 then
        return orders
    end

    -- Build a second table with the unit Ids (names). We want to pass
    -- that to AI functions down below.
    local affordableUnits = {}
    for i, idx in ipairs(affordableUnitsLookup) do
        table.insert(affordableUnits, recruitableUnits[i])
    end

    local movePositions = {}
    if canMove then
        movePositions = Wargroove.getTargetsInRange(unit.pos, unitClass.moveRange, "empty")
    end
    table.insert(movePositions, unit.pos)

    for i, pos in ipairs(movePositions) do
        -- any schools in reach?
        local schools = getSurroundingSchools(unit, pos)
        for j, school in ipairs(schools) do
            -- let the AI decide what to recruit
            local unitToRecruit = Wargroove.getBestUnitToRecruit(affordableUnits, defaultUnits)
            if unitToRecruit ~= "" then
                -- Find index in "recruitableUnits".
                -- We want to pass that in our AI order.
                local r = 1
                while (r <= #recruitableUnits) and (recruitableUnits[r] ~= unitToRecruit) do
                    r = r + 1
                end
                local recruitableUnit = recruitableUnits[r]
                --print("  - best to recruit (lookup): " .. recruitableUnit)

                -- potential drop positions
                local dropPositions = Wargroove.getTargetsInRange(school.pos, 1, "empty")
                for k, dropPos in ipairs(dropPositions) do
                    -- ignore/block the move position
                    if pos.x ~= dropPos.y and pos.y ~= dropPos.y then
                        if Wargroove.canStandAt(recruitableUnit, dropPos) then
                            local result = {}
                            result[1] = dropPos
                            result[2] = school.pos
                            result[3] = { x = recruitableTable, y = r }
                            local strParam = ConvertSoldier:targetsToString(result)
                            table.insert(orders, {
                                targetPosition = school.pos,
                                strParam = strParam,
                                movePosition = pos,
                                endPosition = pos
                            })
                        end
                    end
                end
            end
        end
    end

    return orders
end

function ConvertSoldier:getScore(unitId, order)
    local unit = Wargroove.getUnitById(unitId)

    local targets = Wargroove.stringToPositions(order.strParam)
    local convertTo = conversionUnits[targets[3].x][targets[3].y]

    -- what's the converted unit (at health of current unit) worth?
    local convertedValue = Wargroove.getAIUnitRecruitScore(convertTo, order.targetPosition)
    convertedValue = unit.health * convertedValue / 100
    -- what's the current unit worth?
    local currentValue = Wargroove.getAIUnitValueWithHealth(unit.id, unit.pos, unit.health)

    local score = convertedValue - currentValue
    --print("  AI score for convert to " .. convertTo .." is " .. score)

    return {score = score, introspection = {}}
end

return ConvertSoldier
