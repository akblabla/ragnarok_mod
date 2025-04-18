local Wargroove = require "wargroove/wargroove"
local GrooveVerb = require "wargroove/groove_verb"

local TeleportBeam = GrooveVerb:new()

local costMultiplier = { 1.0, 0.0 }
local recruitModifiers = { "", "recruit_discount" }

local defaultUnits = {"soldier", "spearman", "dog"}

function getCost(tier, cost)
    return math.floor(cost * costMultiplier[tier] + 0.5)
end

function TeleportBeam:getMaximumRange(unit, endPos)
    return 1
end


function TeleportBeam:getTargetType()
    return "all"
end

function TeleportBeam:recruitsContain(recruits, unit)
    for i, recruit in pairs(recruits) do
        if recruit == unit then 
           return true
        end
     end
     return false
end

function TeleportBeam:getRecruitableTargets(unit)
    local allUnits = Wargroove.getAllUnitsForPlayer(unit.playerId, true)
    local recruitableUnits = {}
    local allowedUnitClasses = Wargroove.getTroopUnitClasses()

    for i, unit in pairs(allUnits) do
        for i, recruit in pairs(unit.recruits) do

            if not TeleportBeam.recruitsContain(self, allowedUnitClasses, recruit) then
                goto skipToNextUnit
            end
            
            if not TeleportBeam.recruitsContain(self, recruitableUnits, recruit) then
                recruitableUnits[#recruitableUnits + 1] = recruit
            end

            ::skipToNextUnit::
        end
    end

    if #recruitableUnits == 0 then
        recruitableUnits = defaultUnits
    end

    return recruitableUnits
end

TeleportBeam.classToRecruit = nil

function TeleportBeam:canExecuteWithTarget(unit, endPos, targetPos, strParam)
    local tier = self:getCurrentGrooveTier(unit)
    if not self:canSeeTarget(targetPos) then
        return false
    end

    local classToRecruit = TeleportBeam.classToRecruit
    if classToRecruit == nil then
        classToRecruit = strParam
    end

    local u = Wargroove.getUnitAt(targetPos)
    if (classToRecruit == "") then
        return u == nil
    end

    -- Check if this player can recruit this type of unit
    local isDefault = false
    for i, unitClass in ipairs(defaultUnits) do
        if (unitClass == classToRecruit) then
            isDefault = true
        end
    end
    if not isDefault and not Wargroove.canPlayerRecruit(unit.playerId, classToRecruit) then
        return false
    end

    local uc = Wargroove.getUnitClass(classToRecruit)
    return (endPos.x ~= targetPos.x or endPos.y ~= targetPos.y) and (u == nil or unit.id == u.id) and Wargroove.canStandAt(classToRecruit, targetPos) and Wargroove.getMoney(unit.playerId) >= getCost(tier, uc.cost)
end

function TeleportBeam:preExecute(unit, targetPos, strParam, endPos)
    local tier = self:getCurrentGrooveTier(unit)
    local recruitableUnits = TeleportBeam.getRecruitableTargets(self, unit);

    Wargroove.openRecruitMenu(unit.playerId, unit.id, unit.pos, unit.unitClassId, recruitableUnits, costMultiplier[tier], defaultUnits, "floran");

    while Wargroove.recruitMenuIsOpen() do
        coroutine.yield()
    end

    TeleportBeam.classToRecruit = Wargroove.popRecruitedUnitClass();

    if TeleportBeam.classToRecruit == nil then
        return false, ""
    end

    Wargroove.selectTarget()

    while Wargroove.waitingForSelectedTarget() do
        coroutine.yield()
    end

    local target = Wargroove.getSelectedTarget()

    if (target == nil) then
        TeleportBeam.classToRecruit = nil
        return false, ""
    end

    return true, TeleportBeam.classToRecruit
end


function TeleportBeam:execute(unit, targetPos, strParam, path)
    local tier = self:getCurrentGrooveTier(unit)
    TeleportBeam.classToRecruit = nil

    if strParam == "" then
        print("TeleportBeam was not given a class to recruit.")
        return
    end

    local facingOverride = ""
    if targetPos.x > unit.pos.x then
        facingOverride = "right"
    elseif targetPos.x < unit.pos.x then
        facingOverride = "left"
    end

    if facingOverride ~= "" then
        Wargroove.setFacingOverride(unit.id, facingOverride)
    end

    Wargroove.setIsUsingGroove(unit.id, true)
    Wargroove.updateUnit(unit)

    if tier == 2 then
        Wargroove.playGrooveChargeUp(unit.pos, unit.playerId)
    end

    Wargroove.playPositionlessSound("battleStart")
    Wargroove.playGrooveCutscene(unit.id, tier)

    Wargroove.playUnitAnimation(unit.id, "groove")
    Wargroove.playMapSound("nuru/nuruGroove", unit.pos)
    Wargroove.waitTime(1.7)

    Wargroove.playGrooveEffect()

    Wargroove.spawnPaletteSwappedMapAnimation(targetPos, 0, "fx/groove/nuru_groove_fx", unit.playerId)
    Wargroove.playMapSound("cutscene/teleportIn", targetPos)

    Wargroove.waitTime(0.2)

    local uc = Wargroove.getUnitClass(strParam)
    Wargroove.changeMoney(unit.playerId, -getCost(tier, uc.cost))
    Wargroove.spawnUnit(unit.playerId, targetPos, strParam, false, "", "", "floran")

    Wargroove.waitTime(1.0)

    if recruitModifiers[tier] ~= "" then
        local barracks = Wargroove.getAllUnitsOfType(unit.playerId, "barracks")
        local towers = Wargroove.getAllUnitsOfType(unit.playerId, "tower")
        local ports = Wargroove.getAllUnitsOfType(unit.playerId, "port")
        local hideouts = Wargroove.getAllUnitsOfType(unit.playerId, "hideout")
        
        local modifier = recruitModifiers[tier]

        for _, barrack in ipairs(barracks) do
            Wargroove.pushUnitClassModifier(barrack.id, modifier)
            Wargroove.pushBuff(1, barrack, unit.playerId, "recruit_discount_spawn", "recruit_discount", "recruit_discount_death")
        end
        for _, tower in ipairs(towers) do
            Wargroove.pushUnitClassModifier(tower.id, modifier)
            Wargroove.pushBuff(1, tower, unit.playerId, "recruit_discount_spawn", "recruit_discount", "recruit_discount_death")
        end
        for _, port in ipairs(ports) do
            Wargroove.pushUnitClassModifier(port.id, modifier)
            Wargroove.pushBuff(1, port, unit.playerId, "recruit_discount_spawn", "recruit_discount", "recruit_discount_death")
        end
        for _, hideout in ipairs(hideouts) do
            Wargroove.pushUnitClassModifier(hideout.id, modifier)
            Wargroove.pushBuff(1, hideout, unit.playerId, "recruit_discount_spawn", "recruit_discount", "recruit_discount_death")
        end
    end

    Wargroove.unsetFacingOverride(unit.id)

    strParam = ""

    Wargroove.logAnalyticsAction("UnitAbility", unit.playerId, "groove", unit.unitClassId)
end

function TeleportBeam:generateOrders(unitId, canMove)
    local orders = {}
    
    local unit = Wargroove.getUnitById(unitId)
    local tier = self:getCurrentGrooveTier(unit)
    local unitClass = Wargroove.getUnitClass(unit.unitClassId)
    local movePositions = {}
    if canMove then
        movePositions = Wargroove.getTargetsInRange(unit.pos, unitClass.moveRange, "empty")
    end
    table.insert(movePositions, unit.pos)

    local recruitableTargets = TeleportBeam.getRecruitableTargets(self, unit)
    local affordableTargets = {}
    for i, recruit in ipairs(recruitableTargets) do
        local uc = Wargroove.getUnitClass(recruit)
        if (Wargroove.getMoney(unit.playerId) >= getCost(tier, uc.cost)) then
            table.insert(affordableTargets, recruit)
        end
    end
    local unitToRecruit = Wargroove.getBestUnitToRecruit(affordableTargets, defaultUnits)

    if unitToRecruit == "" then
        return orders
    end

    for i, pos in pairs(movePositions) do
        local targetPositions = Wargroove.getTargetsInRangeAfterMove(unit, pos, pos, 1, "empty")
        for j, targetPos in pairs(targetPositions) do
            if targetPos ~= pos then
                if Wargroove.canStandAt(unitToRecruit, targetPos) and self:canSeeTarget(targetPos) then                
                    orders[#orders+1] = {targetPosition = targetPos, strParam = unitToRecruit, movePosition = pos, endPosition = pos}
                end
            end
        end
    end

    return orders
end

function TeleportBeam:getScore(unitId, order)
    local unit = Wargroove.getUnitById(unitId)
    local score = Wargroove.getAIUnitRecruitScore(order.strParam, order.targetPosition)
    return {score = score, introspection = {}}
end


return TeleportBeam
