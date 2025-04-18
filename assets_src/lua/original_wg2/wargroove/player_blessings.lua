local PlayerBlessings = {}

local Blessings = {}

local function getUnlockedFundsAmount(Wargroove, value)
    local capitalOne = Wargroove.checkConquestUnlock("starting_capital_one_unlock")
    local capitalTwo = Wargroove.checkConquestUnlock("starting_capital_two_unlock")
    
    if capitalTwo then
        return value + 200
    elseif capitalOne then
        return value + 100
    end

    return value
end

local function spawnItemForRandomUnit(Wargroove, itemId, playerId)
    local units = Wargroove.getAllUnitsForPlayer(playerId)

    local validUnits = {}

    for i, unit in ipairs(units) do
        if not unit.unitClass.isCommander and unit.itemId == "" and unit.pos.x >= 0 then
            table.insert(validUnits, unit)
        end
    end

    if #units >= 1 then
        local unitIdx = Wargroove.randomIntegerFromTable({ validUnits[1], itemId, playerId, #validUnits }, 1, #validUnits)
        local unit = validUnits[unitIdx]
        Wargroove.equipItem(unit, itemId)
        Wargroove.updateUnit(unit)
    end
end

local function spawnUnlockedItems(Wargroove, playerId)
    local armorOne = Wargroove.checkConquestUnlock("starting_armor_one_unlock")
    local armorTwo = Wargroove.checkConquestUnlock("starting_armor_two_unlock")
    local weaponOne = Wargroove.checkConquestUnlock("starting_weapon_one_unlock")
    local weaponTwo = Wargroove.checkConquestUnlock("starting_weapon_two_unlock")

    local spawnArmor = ""
    if armorTwo then
        spawnArmor = "heavy_armor"
    elseif armorOne then
        spawnArmor = "hardened_armor"
    end
    if spawnArmor ~= "" then
        spawnItemForRandomUnit(Wargroove, spawnArmor, playerId)
    end

    local spawnWeapon = ""
    if weaponTwo then
        spawnWeapon = "strong_arm"
    elseif weaponOne then
        spawnWeapon = "thiefs_dagger"
    end
    if spawnWeapon ~= "" then
        spawnItemForRandomUnit(Wargroove, spawnWeapon, playerId)
    end
end

local function checkGrooveBoostUnlock(Wargroove, commander)
    local grooveBoost = Wargroove.checkConquestUnlock("commander_groove_boost_unlock")

    if grooveBoost then
        Wargroove.waitTime(0.2)

        Wargroove.spawnMapAnimation(commander.pos, 0, "units/commanders/groove_powerup_back", "", "behind_units")
        Wargroove.spawnMapAnimation(commander.pos, 0, "units/commanders/groove_powerup_front", "", "over_units")

        local grooveBoostAmount = 100
        local groove = Wargroove.getGroove(commander.grooveId)
        if commander.grooveCharge < groove.grooveCost[1] then
            grooveBoostAmount = groove.grooveCost[1]
        elseif commander.grooveCharge >= groove.grooveCost[1] then
            grooveBoostAmount = groove.grooveCost[2]
        end

        commander.grooveCharge = math.min(grooveBoostAmount, commander.unitClass.maxGroove)

        Wargroove.updateUnit(commander)
        Wargroove.clearCaches()
    end
end


local function startingFormation(id, Wargroove, Actions, playerId, location)
    local units = Wargroove.getBlessingFormation("startingFormation"..id)

    for _, unit in ipairs(units) do
        Actions.doSpawnUnit(1, unit, playerId, location, false, true, true, false)
    end

    local amount = getUnlockedFundsAmount(Wargroove, Wargroove.getBlessingFunds("startingFormation"..id))
    if amount > 0 then
        Wargroove.changeMoney(playerId, amount)
        Wargroove.playPositionlessSound("thiefGoldObtained")
    end

    spawnUnlockedItems(Wargroove, playerId)
end

function Blessings.startingFormation01(Wargroove, Actions, playerId, location)
    startingFormation("01", Wargroove, Actions, playerId, location)
end

function Blessings.startingFormation02(Wargroove, Actions, playerId, location)
    startingFormation("02", Wargroove, Actions, playerId, location)
end

function Blessings.startingFormation03(Wargroove, Actions, playerId, location)
    startingFormation("03", Wargroove, Actions, playerId, location)
end

function Blessings.startingFormation04(Wargroove, Actions, playerId, location)
    startingFormation("04", Wargroove, Actions, playerId, location)
end

function Blessings.startingFormation05(Wargroove, Actions, playerId, location)
    startingFormation("05", Wargroove, Actions, playerId, location)
end

function Blessings.startingFormation06(Wargroove, Actions, playerId, location)
    startingFormation("06", Wargroove, Actions, playerId, location)
end

function Blessings.startingFormation07(Wargroove, Actions, playerId, location)
    startingFormation("07", Wargroove, Actions, playerId, location)
end

function Blessings.startingFormation08(Wargroove, Actions, playerId, location)
    startingFormation("08", Wargroove, Actions, playerId, location)
end

function Blessings.startingFormation09(Wargroove, Actions, playerId, location)
    startingFormation("09", Wargroove, Actions, playerId, location)
end

function Blessings.startingFormation10(Wargroove, Actions, playerId, location)
    startingFormation("10", Wargroove, Actions, playerId, location)
end

function Blessings.startingFormation11(Wargroove, Actions, playerId, location)
    startingFormation("11", Wargroove, Actions, playerId, location)
end

function Blessings.startingFormation12(Wargroove, Actions, playerId, location)
    startingFormation("12", Wargroove, Actions, playerId, location)
end

function Blessings.startingFormation13(Wargroove, Actions, playerId, location)
    startingFormation("13", Wargroove, Actions, playerId, location)
end

function Blessings.startingFormation14(Wargroove, Actions, playerId, location)
    startingFormation("14", Wargroove, Actions, playerId, location)
end

function Blessings.startingFormation15(Wargroove, Actions, playerId, location)
    startingFormation("15", Wargroove, Actions, playerId, location)
end

function Blessings.startingFormation16(Wargroove, Actions, playerId, location)
    startingFormation("16", Wargroove, Actions, playerId, location)
end

function Blessings.startingFormation17(Wargroove, Actions, playerId, location)
    startingFormation("17", Wargroove, Actions, playerId, location)
end

function Blessings.startingFormation18(Wargroove, Actions, playerId, location)
    startingFormation("18", Wargroove, Actions, playerId, location)
end

function Blessings.startingFormation19(Wargroove, Actions, playerId, location)
    startingFormation("19", Wargroove, Actions, playerId, location)
end

function Blessings.startingFormation20(Wargroove, Actions, playerId, location)
    startingFormation("20", Wargroove, Actions, playerId, location)
end

function Blessings.startingFormation21(Wargroove, Actions, playerId, location)
    startingFormation("21", Wargroove, Actions, playerId, location)
end

function Blessings.startingFormation22(Wargroove, Actions, playerId, location)
    startingFormation("22", Wargroove, Actions, playerId, location)
end

function Blessings.startingFormation23(Wargroove, Actions, playerId, location)
    startingFormation("23", Wargroove, Actions, playerId, location)
end

function Blessings.startingFormation24(Wargroove, Actions, playerId, location)
    startingFormation("24", Wargroove, Actions, playerId, location)
end

function Blessings.startingFormation25(Wargroove, Actions, playerId, location)
    startingFormation("25", Wargroove, Actions, playerId, location)
end

function Blessings.startingFormation26(Wargroove, Actions, playerId, location)
    startingFormation("26", Wargroove, Actions, playerId, location)
end

function Blessings.startingFormation27(Wargroove, Actions, playerId, location)
    startingFormation("27", Wargroove, Actions, playerId, location)
end

function Blessings.startingFormation28(Wargroove, Actions, playerId, location)
    startingFormation("28", Wargroove, Actions, playerId, location)
end

function Blessings.startingFormation29(Wargroove, Actions, playerId, location)
    startingFormation("29", Wargroove, Actions, playerId, location)
end

function Blessings.startingFormation30(Wargroove, Actions, playerId, location)
    startingFormation("30", Wargroove, Actions, playerId, location)
end

function Blessings.startingFormation31(Wargroove, Actions, playerId, location)
    startingFormation("31", Wargroove, Actions, playerId, location)
end

function Blessings.startingFormation32(Wargroove, Actions, playerId, location)
    startingFormation("32", Wargroove, Actions, playerId, location)
end

function Blessings.startingFormation33(Wargroove, Actions, playerId, location)
    startingFormation("33", Wargroove, Actions, playerId, location)
end

function Blessings.startingFormation34(Wargroove, Actions, playerId, location)
    startingFormation("34", Wargroove, Actions, playerId, location)
end

function Blessings.startingFormation35(Wargroove, Actions, playerId, location)
    startingFormation("35", Wargroove, Actions, playerId, location)
end

function Blessings.startingFormation36(Wargroove, Actions, playerId, location)
    startingFormation("36", Wargroove, Actions, playerId, location)
end

function Blessings.startingFormation37(Wargroove, Actions, playerId, location)
    startingFormation("37", Wargroove, Actions, playerId, location)
end

function Blessings.startingFormation38(Wargroove, Actions, playerId, location)
    startingFormation("38", Wargroove, Actions, playerId, location)
end

function Blessings.startingFormation39(Wargroove, Actions, playerId, location)
    startingFormation("39", Wargroove, Actions, playerId, location)
end

function Blessings.startingFormation40(Wargroove, Actions, playerId, location)
    startingFormation("40", Wargroove, Actions, playerId, location)
end

function Blessings.startingFormation41(Wargroove, Actions, playerId, location)
    startingFormation("41", Wargroove, Actions, playerId, location)
end

function Blessings.startingFormation42(Wargroove, Actions, playerId, location)
    startingFormation("42", Wargroove, Actions, playerId, location)
end

function Blessings.startingFormation43(Wargroove, Actions, playerId, location)
    startingFormation("43", Wargroove, Actions, playerId, location)
end

function Blessings.startingFormation44(Wargroove, Actions, playerId, location)
    startingFormation("44", Wargroove, Actions, playerId, location)
end

function Blessings.startingFormation45(Wargroove, Actions, playerId, location)
    startingFormation("45", Wargroove, Actions, playerId, location)
end

function Blessings.startingFormation46(Wargroove, Actions, playerId, location)
    startingFormation("46", Wargroove, Actions, playerId, location)
end

function Blessings.startingFormation47(Wargroove, Actions, playerId, location)
    startingFormation("47", Wargroove, Actions, playerId, location)
end

function Blessings.startingFormation48(Wargroove, Actions, playerId, location)
    startingFormation("48", Wargroove, Actions, playerId, location)
end

function Blessings.startingFormation49(Wargroove, Actions, playerId, location)
    startingFormation("49", Wargroove, Actions, playerId, location)
end

function Blessings.startingFormation50(Wargroove, Actions, playerId, location)
    startingFormation("50", Wargroove, Actions, playerId, location)
end

function Blessings.blessing01_condition(Wargroove, playerId, unit)
    if unit.playerId == playerId and unit.unitClassId == "soldier" then
        return true
    end
    return false
end

function Blessings.blessing01_action(Wargroove, playerId, unit)
    Wargroove.displayBuffVisualEffect(unit.id, unit.playerId, "fx/general_unit_effect", "spawn", 0.6, {}, "over_units", {x = 0, y = 0}, false, false)
    Wargroove.pushUnitClassModifier(unit.id, "movement_range_bonus")
    Wargroove.updateUnit(unit)
end

function Blessings.blessing01(Wargroove, Actions, playerId, location)
    Wargroove.registerPlayerBlessing("blessing01", playerId)
end

function Blessings.blessing02(Wargroove, Actions, playerId, location)
    local units = Wargroove.getAllUnitsForPlayer(playerId)

    Wargroove.playPositionlessSound("unitHealed")

    for _, unit in ipairs(units) do
        Wargroove.spawnMapAnimation(unit.pos, 0, "fx/heal_unit")
        unit:setHealth(100, unit.id)
        Wargroove.updateUnit(unit)
    end
end

function Blessings.blessing03_condition(Wargroove, playerId, unit)
    if unit.playerId == playerId and unit.unitClassId == "archer" then
        return true
    end
    return false
end

function Blessings.blessing03_action(Wargroove, playerId, unit)
    Wargroove.displayBuffVisualEffect(unit.id, unit.playerId, "fx/general_unit_effect", "spawn", 0.6, {}, "over_units", {x = 0, y = 0}, false, false)
    Wargroove.pushUnitClassModifier(unit.id, "tornado_boost")
    Wargroove.updateUnit(unit)
end

function Blessings.blessing03(Wargroove, Actions, playerId, location)
    Wargroove.registerPlayerBlessing("blessing03", playerId)
end

function Blessings.blessing04(Wargroove, Actions, playerId, location)
    local units = {
        {id="soldier", count=2}
    }

    for _, unit in ipairs(units) do
        Actions.doSpawnUnit(unit.count, unit.id, playerId, location, false, true, true, false)
    end
end

function Blessings.blessing05_condition(Wargroove, playerId, unit)
    if unit.playerId == playerId and unit.unitClassId == "mage" then
        return true
    end
    return false
end

function Blessings.blessing05_action(Wargroove, playerId, unit)
    Wargroove.displayBuffVisualEffect(unit.id, unit.playerId, "fx/general_unit_effect", "spawn", 0.6, {}, "over_units", {x = 0, y = 0}, false, false)
    Wargroove.pushUnitClassModifier(unit.id, "inspire_high")
    Wargroove.updateUnit(unit)
end

function Blessings.blessing05(Wargroove, Actions, playerId, location)
    Wargroove.registerPlayerBlessing("blessing05", playerId)
end

function Blessings.blessing06_condition(Wargroove, playerId, unit)
    if unit.playerId == playerId and unit.unitClassId == "soldier" then
        return true
    end
    return false
end

function Blessings.blessing06_action(Wargroove, playerId, unit)
    Wargroove.displayBuffVisualEffect(unit.id, unit.playerId, "fx/general_unit_effect", "spawn", 0.6, {}, "over_units", {x = 0, y = 0}, false, false)
    Wargroove.pushUnitClassModifier(unit.id, "soldier_dmg_boost")
    Wargroove.updateUnit(unit)
end

function Blessings.blessing06(Wargroove, Actions, playerId, location)
    -- All soldiers deal 50% more damage
    Wargroove.registerPlayerBlessing("blessing06", playerId)
end

function Blessings.blessing07(Wargroove, Actions, playerId, location)
    local units = Wargroove.getAllUnitsForPlayer(playerId)
    
    -- Your *current* soldiers turn into spearman
    for _, unit in ipairs(units) do
        if unit.playerId == playerId and unit.unitClassId == "soldier" then
            unit.unitClassId = "spearman"
            Wargroove.updateUnit(unit)

            Wargroove.spawnMapAnimation(unit.pos, 0, "fx/mapeditor_unitdrop")
            Wargroove.playMapSound("spawn", unit.pos)
        end
    end
end

function Blessings.blessing08_condition(Wargroove, playerId, unit)
    if unit.playerId == playerId and unit.unitClass.isCommander then
        return true
    end
    return false
end

function Blessings.blessing08_action(Wargroove, playerId, unit)
    Wargroove.displayBuffVisualEffect(unit.id, unit.playerId, "fx/general_unit_effect", "spawn", 0.6, {}, "over_units", {x = 0, y = 0}, false, false)
    Wargroove.pushUnitClassModifier(unit.id, "inspire_high")
    Wargroove.updateUnit(unit)
end

function Blessings.blessing08(Wargroove, Actions, playerId, location)
    -- Your commander receives +2 move range
    Wargroove.registerPlayerBlessing("blessing08", playerId)
end

function Blessings.blessing09_condition(Wargroove, playerId, unit)
    if unit.playerId == playerId and unit.unitClassId == "mage" then
        return true
    end
    return false
end

function Blessings.blessing09_action(Wargroove, playerId, unit)
    Wargroove.displayBuffVisualEffect(unit.id, unit.playerId, "fx/general_unit_effect", "spawn", 0.6, {}, "over_units", {x = 0, y = 0}, false, false)
    Wargroove.pushUnitClassModifier(unit.id, "mage_discount")
    Wargroove.updateUnit(unit)
end

function Blessings.blessing09(Wargroove, Actions, playerId, location)
    -- Mages heal costs 50% less
    Wargroove.registerPlayerBlessing("blessing09", playerId)
end

function Blessings.blessing10_condition(Wargroove, playerId, unit)
    if unit.playerId == playerId and unit.unitClassId == "archer" then
        return true
    end
    return false
end

function Blessings.blessing10_action(Wargroove, playerId, unit)
    Wargroove.displayBuffVisualEffect(unit.id, unit.playerId, "fx/general_unit_effect", "spawn", 0.6, {}, "over_units", {x = 0, y = 0}, false, false)
    Wargroove.pushUnitClassModifier(unit.id, "specialized_archers")
    Wargroove.updateUnit(unit)
end

function Blessings.blessing10(Wargroove, Actions, playerId, location)
    -- Your archers can no longer move and attack in the same turn, but deal 2x damage.
    Wargroove.registerPlayerBlessing("blessing10", playerId)
end

function Blessings.blessing11(Wargroove, Actions, playerId, location)
    -- You receive 400 gold immediately
    local units = Wargroove.getAllUnitsForPlayer(playerId)
    for _, unit in ipairs(units) do
        if unit.playerId == playerId and unit.unitClass.isCommander then
            Wargroove.spawnMapAnimation(unit.pos, 0, "fx/ransack_1", "default", "over_units", { x = 12, y = 0 })
            break
        end
    end

    Wargroove.changeMoney(playerId, 400)
    Wargroove.playPositionlessSound("thiefGoldObtained")
end

function Blessings.blessing12(Wargroove, Actions, playerId, location)
    -- Your commander deals 25% more damage.
    local units = Wargroove.getAllUnitsForPlayer(playerId)
    for _, unit in ipairs(units) do
        if unit.playerId == playerId and unit.unitClass.isCommander then
            Wargroove.pushUnitClassModifier(unit.id, "commander_dmg_boost")
            Wargroove.updateUnit(unit)
        end
    end
end

function Blessings.blessing13_condition(Wargroove, playerId, unit)
    if unit.playerId == playerId and unit.unitClassId == "mage" then
        return true
    end
    return false
end

function Blessings.blessing13_action(Wargroove, playerId, unit)
    Wargroove.displayBuffVisualEffect(unit.id, unit.playerId, "fx/general_unit_effect", "spawn", 0.6, {}, "over_units", {x = 0, y = 0}, false, false)
    Wargroove.pushUnitClassModifier(unit.id, "mage_dmg_boost_low")
    Wargroove.updateUnit(unit)
end

function Blessings.blessing13(Wargroove, Actions, playerId, location)
    -- Mages deal 1.25x damage
    Wargroove.registerPlayerBlessing("blessing13", playerId)
end

function Blessings.blessing14_condition(Wargroove, playerId, unit)
    if unit.playerId == playerId and unit.unitClassId == "harpy" then
        return true
    end
    return false
end

function Blessings.blessing14_action(Wargroove, playerId, unit)
    Wargroove.displayBuffVisualEffect(unit.id, unit.playerId, "fx/general_unit_effect", "spawn", 0.6, {}, "over_units", {x = 0, y = 0}, false, false)
    Wargroove.pushUnitClassModifier(unit.id, "movement_range_bonus")
    Wargroove.updateUnit(unit)
end

function Blessings.blessing14(Wargroove, Actions, playerId, location)
    -- Harpies move 1 tile further
    Wargroove.registerPlayerBlessing("blessing14", playerId)
end

function Blessings.blessing15(Wargroove, Actions, playerId, location)
    local units = {
        {id="griffin_walking", count=2}
    }

    for _, unit in ipairs(units) do
        Actions.doSpawnUnit(unit.count, unit.id, playerId, location, false, true, true, false)
    end
end

function Blessings.blessing16_condition(Wargroove, playerId, unit)
    if unit.playerId == playerId and unit.unitClassId == "archer" then
        return true
    end
    return false
end

function Blessings.blessing16_action(Wargroove, playerId, unit)
    Wargroove.displayBuffVisualEffect(unit.id, unit.playerId, "fx/general_unit_effect", "spawn", 0.6, {}, "over_units", {x = 0, y = 0}, false, false)
    Wargroove.pushUnitClassModifier(unit.id, "archer_air_dmg_boost")
    Wargroove.updateUnit(unit)
end

function Blessings.blessing16(Wargroove, Actions, playerId, location)
    -- Your archers deal 1.5x damage to air units
    Wargroove.registerPlayerBlessing("blessing16", playerId)
end

function Blessings.blessing17_condition(Wargroove, playerId, unit)
    if unit.playerId == playerId and unit.unitClassId == "harpy" then
        return true
    end
    return false
end

function Blessings.blessing17_action(Wargroove, playerId, unit)
    Wargroove.displayBuffVisualEffect(unit.id, unit.playerId, "fx/general_unit_effect", "spawn", 0.6, {}, "over_units", {x = 0, y = 0}, false, false)
    Wargroove.pushUnitClassModifier(unit.id, "harpy_claws")
    Wargroove.updateUnit(unit)
end

function Blessings.blessing17(Wargroove, Actions, playerId, location)
    -- Your harpies deal 2x damage but can only attack ground
    Wargroove.registerPlayerBlessing("blessing17", playerId)
end

function Blessings.blessing18_condition(Wargroove, playerId, unit)
    if unit.playerId == playerId and unit.unitClassId == "spearman" then
        return true
    end
    return false
end

function Blessings.blessing18_action(Wargroove, playerId, unit)
    Wargroove.displayBuffVisualEffect(unit.id, unit.playerId, "fx/general_unit_effect", "spawn", 0.6, {}, "over_units", {x = 0, y = 0}, false, false)
    Wargroove.pushUnitClassModifier(unit.id, "movement_range_bonus")
    Wargroove.updateUnit(unit)
end

function Blessings.blessing18(Wargroove, Actions, playerId, location)
    -- Spearman move 1 tile further
    Wargroove.registerPlayerBlessing("blessing18", playerId)
end

function Blessings.blessing19_condition(Wargroove, playerId, unit)
    if unit.playerId == playerId and unit.unitClassId == "merman" then
        return true
    end
    return false
end

function Blessings.blessing19_action(Wargroove, playerId, unit)
    Wargroove.displayBuffVisualEffect(unit.id, unit.playerId, "fx/general_unit_effect", "spawn", 0.6, {}, "over_units", {x = 0, y = 0}, false, false)
    Wargroove.pushUnitClassModifier(unit.id, "movement_range_bonus")
    Wargroove.updateUnit(unit)
end

function Blessings.blessing19(Wargroove, Actions, playerId, location)
    -- Merman move 1 tiles further
    Wargroove.registerPlayerBlessing("blessing19", playerId)
end

function Blessings.blessing20(Wargroove, Actions, playerId, location)
    local units = {
        {id="caravel", count=2}
    }

    for _, unit in ipairs(units) do
        Actions.doSpawnUnit(unit.count, unit.id, playerId, location, false, true, true, false)
    end
end

function Blessings.blessing21_condition(Wargroove, playerId, unit)
    if unit.playerId == playerId and unit.unitClassId == "caravel" then
        return true
    end
    return false
end

function Blessings.blessing21_action(Wargroove, playerId, unit)
    Wargroove.displayBuffVisualEffect(unit.id, unit.playerId, "fx/general_unit_effect", "spawn", 0.6, {}, "over_units", {x = 0, y = 0}, false, false)
    Wargroove.pushUnitClassModifier(unit.id, "caravel_crit_change")
    Wargroove.updateUnit(unit)
end

function Blessings.blessing21(Wargroove, Actions, playerId, location)
    -- Caravel crit changes to: If below 50, crit
    Wargroove.registerPlayerBlessing("blessing21", playerId)
end

function Blessings.blessing22_condition(Wargroove, playerId, unit)
    if unit.playerId == playerId and unit.unitClassId == "merman" then
        return true
    end
    return false
end

function Blessings.blessing22_action(Wargroove, playerId, unit)
    Wargroove.displayBuffVisualEffect(unit.id, unit.playerId, "fx/general_unit_effect", "spawn", 0.6, {}, "over_units", {x = 0, y = 0}, false, false)
    Wargroove.pushUnitClassModifier(unit.id, "merman_assault")
    Wargroove.updateUnit(unit)
end

function Blessings.blessing22(Wargroove, Actions, playerId, location)
    -- Merman can attack air units
    Wargroove.registerPlayerBlessing("blessing22", playerId)
end

function Blessings.blessing23_condition(Wargroove, playerId, unit)
    if unit.playerId == playerId and unit.unitClassId == "harpoonship" then
        return true
    end
    return false
end

function Blessings.blessing23_action(Wargroove, playerId, unit)
    Wargroove.displayBuffVisualEffect(unit.id, unit.playerId, "fx/general_unit_effect", "spawn", 0.6, {}, "over_units", {x = 0, y = 0}, false, false)
    Wargroove.pushUnitClassModifier(unit.id, "harpoon_assault")
    Wargroove.updateUnit(unit)
end

function Blessings.blessing23(Wargroove, Actions, playerId, location)
    -- Merman can attack air units
    Wargroove.registerPlayerBlessing("blessing23", playerId)
end

function Blessings.blessing24_condition(Wargroove, playerId, unit)
    if unit.playerId == playerId and unit.unitClassId == "merman" then
        return true
    end
    return false
end

function Blessings.blessing24_action(Wargroove, playerId, unit)
    Wargroove.displayBuffVisualEffect(unit.id, unit.playerId, "fx/general_unit_effect", "spawn", 0.6, {}, "over_units", {x = 0, y = 0}, false, false)
    Wargroove.pushUnitClassModifier(unit.id, "tornado_boost")
    Wargroove.updateUnit(unit)
end

function Blessings.blessing24(Wargroove, Actions, playerId, location)
    -- Merman can attack air units
    Wargroove.registerPlayerBlessing("blessing24", playerId)
end

function Blessings.blessing25_condition(Wargroove, playerId, unit)
    if unit.playerId == playerId and unit.unitClassId == "harpoonship" then
        return true
    end
    return false
end

function Blessings.blessing25_action(Wargroove, playerId, unit)
    Wargroove.displayBuffVisualEffect(unit.id, unit.playerId, "fx/general_unit_effect", "spawn", 0.6, {}, "over_units", {x = 0, y = 0}, false, false)
    Wargroove.pushUnitClassModifier(unit.id, "tornado_boost")
    Wargroove.updateUnit(unit)
end

function Blessings.blessing25(Wargroove, Actions, playerId, location)
    -- Merman can attack air units
    Wargroove.registerPlayerBlessing("blessing25", playerId)
end

function Blessings.blessing26_condition(Wargroove, playerId, unit)
    if unit.playerId == playerId and unit.unitClass.isCommander then
        return true
    end
    return false
end

function Blessings.blessing26_action(Wargroove, playerId, unit)
    Wargroove.displayBuffVisualEffect(unit.id, unit.playerId, "fx/general_unit_effect", "spawn", 0.6, {}, "over_units", {x = 0, y = 0}, false, false)
    Wargroove.pushUnitClassModifier(unit.id, "burden")
    Wargroove.updateUnit(unit)
end

function Blessings.blessing26(Wargroove, Actions, playerId, location)
    -- Your commander moves 1 tile less far.
    Wargroove.registerPlayerBlessing("blessing26", playerId)
end

function Blessings.blessing27_condition(Wargroove, playerId, unit)
    if unit.playerId == playerId and unit.unitClass.isCommander then
        return true
    end
    return false
end

function Blessings.blessing27_action(Wargroove, playerId, unit)
    Wargroove.displayBuffVisualEffect(unit.id, unit.playerId, "fx/general_unit_effect", "spawn", 0.6, {}, "over_units", {x = 0, y = 0}, false, false)
    Wargroove.pushUnitClassModifier(unit.id, "sickness")
    Wargroove.updateUnit(unit)
end

function Blessings.blessing27(Wargroove, Actions, playerId, location)
    -- Your Commander receives 25% more damage.
    Wargroove.registerPlayerBlessing("blessing27", playerId)
end

function Blessings.blessing28_condition(Wargroove, playerId, unit)
    if unit.playerId == playerId and (unit.unitClassId == "barracks" or unit.unitClassId == "port" or unit.unitClassId == "tower" or unit.unitClassId == "hideout") then
        return true
    end
    return false
end

function Blessings.blessing28_action(Wargroove, playerId, unit)
    Wargroove.displayBuffVisualEffect(unit.id, unit.playerId, "fx/general_unit_effect", "spawn", 0.6, {}, "over_units", {x = 0, y = 0}, false, false)
    Wargroove.pushUnitClassModifier(unit.id, "capitalism")
    Wargroove.updateUnit(unit)
end

function Blessings.blessing28(Wargroove, Actions, playerId, location)
    -- Recruiting units costs 10% more.
    Wargroove.registerPlayerBlessing("blessing28", playerId)
end

function Blessings.blessing29_condition(Wargroove, playerId, unit)
    if unit.playerId == playerId and unit.unitClassId == "soldier" then
        return true
    end
    return false
end

function Blessings.blessing29_action(Wargroove, playerId, unit)
    Wargroove.displayBuffVisualEffect(unit.id, unit.playerId, "fx/general_unit_effect", "spawn", 0.6, {}, "over_units", {x = 0, y = 0}, false, false)
    Wargroove.pushUnitClassModifier(unit.id, "sickness")
    Wargroove.updateUnit(unit)
end

function Blessings.blessing29(Wargroove, Actions, playerId, location)
    -- Your soldiers moves 1 tile less far.
    Wargroove.registerPlayerBlessing("blessing29", playerId)
end

function Blessings.blessing30_condition(Wargroove, playerId, unit)
    if unit.playerId == playerId and unit.unitClassId == "dog" then
        return true
    end
    return false
end

function Blessings.blessing30_action(Wargroove, playerId, unit)
    Wargroove.displayBuffVisualEffect(unit.id, unit.playerId, "fx/general_unit_effect", "spawn", 0.6, {}, "over_units", {x = 0, y = 0}, false, false)
    Wargroove.pushUnitClassModifier(unit.id, "critical_curse")
    Wargroove.updateUnit(unit)
end

function Blessings.blessing30(Wargroove, Actions, playerId, location)
    -- Your dogs no longer deal critical damage.
    Wargroove.registerPlayerBlessing("blessing30", playerId)
end

function Blessings.blessing31_condition(Wargroove, playerId, unit)
    if unit.playerId == playerId and (unit.unitClassId == "harpy" or unit.unitClassId == "witch" or unit.unitClassId == "dragon" or unit.unitClassId == "balloon") then
        return true
    end
    return false
end

function Blessings.blessing31_action(Wargroove, playerId, unit)
    Wargroove.displayBuffVisualEffect(unit.id, unit.playerId, "fx/general_unit_effect", "spawn", 0.6, {}, "over_units", {x = 0, y = 0}, false, false)
    Wargroove.pushUnitClassModifier(unit.id, "sickness")
    Wargroove.updateUnit(unit)
end

function Blessings.blessing31(Wargroove, Actions, playerId, location)
    -- Your air units move 1 tile less far.
    Wargroove.registerPlayerBlessing("blessing31", playerId)
end

function Blessings.blessing32_condition(Wargroove, playerId, unit)
    if unit.playerId == playerId and unit.unitClassId == "archer" then
        return true
    end
    return false
end

function Blessings.blessing32_action(Wargroove, playerId, unit)
    Wargroove.displayBuffVisualEffect(unit.id, unit.playerId, "fx/general_unit_effect", "spawn", 0.6, {}, "over_units", {x = 0, y = 0}, false, false)
    Wargroove.pushUnitClassModifier(unit.id, "attack_miss")
    Wargroove.updateUnit(unit)
end

function Blessings.blessing32(Wargroove, Actions, playerId, location)
    -- Your archers have 50% chance of missing, dealing no damage.
    Wargroove.registerPlayerBlessing("blessing32", playerId)
end

function Blessings.blessing33_condition(Wargroove, playerId, unit)
    if unit.playerId == playerId and unit.unitClassId == "archer" then
        return true
    end
    return false
end

function Blessings.blessing33_action(Wargroove, playerId, unit)
    Wargroove.displayBuffVisualEffect(unit.id, unit.playerId, "fx/general_unit_effect", "spawn", 0.6, {}, "over_units", {x = 0, y = 0}, false, false)
    Wargroove.pushUnitClassModifier(unit.id, "attack_no_air")
    Wargroove.updateUnit(unit)
end

function Blessings.blessing33(Wargroove, Actions, playerId, location)
    -- Archers can no longer attack air units.
    Wargroove.registerPlayerBlessing("blessing33", playerId)
end

function Blessings.blessing34_condition(Wargroove, playerId, unit)
    if unit.playerId == playerId and unit.unitClassId == "mage" then
        return true
    end
    return false
end

function Blessings.blessing34_action(Wargroove, playerId, unit)
    Wargroove.displayBuffVisualEffect(unit.id, unit.playerId, "fx/general_unit_effect", "spawn", 0.6, {}, "over_units", {x = 0, y = 0}, false, false)
    Wargroove.pushUnitClassModifier(unit.id, "no_heal")
    Wargroove.updateUnit(unit)
end

function Blessings.blessing34(Wargroove, Actions, playerId, location)
    -- Your mages can no longer heal.
    Wargroove.registerPlayerBlessing("blessing34", playerId)
end

function Blessings.blessing35(Wargroove, Actions, playerId, location)
    local units = Wargroove.getAllUnitsForPlayer(playerId)

    local validUnits = {}

    for i, unit in ipairs(units) do
        if not unit.unitClass.isCommander then
            table.insert(validUnits, unit)
        end
    end

    if #validUnits >= 1 then
        local unitIdx = Wargroove.randomIntegerFromTable({ validUnits[1] }, 1, #validUnits)

        local unit = validUnits[unitIdx]

        Wargroove.trackCameraTo(unit.pos)
        Wargroove.waitTime(0.3)

        Wargroove.spawnMapAnimation(unit.pos, 0, "fx/mapeditor_unitdrop")
        Wargroove.playMapSound("spawn", unit.pos)
        Wargroove.removeUnit(unit.id)
        Wargroove.clearCaches()

        Wargroove.waitTime(0.6)
    end
end

function Blessings.blessing36(Wargroove, Actions, playerId, location)
    local units = Wargroove.getAllUnitsForPlayer(playerId)

    local unitsWithItem = {}

    for i, unit in ipairs(units) do
        if unit.itemId ~= "" then
            table.insert(unitsWithItem, unit)
        end
    end

    local itemsToDestroy = math.min(#unitsWithItem, 2)

    for i=1, itemsToDestroy, 1 do
        local unitIdx = Wargroove.randomIntegerFromTable({ unitsWithItem[1] }, 1, #unitsWithItem)
        local unit = unitsWithItem[unitIdx]

        Wargroove.trackCameraTo(unit.pos)
        Wargroove.waitTime(0.3)

        Wargroove.unequipItem(unit)
        Wargroove.spawnPaletteSwappedMapAnimation(unit.pos, 0, "fx/drain_unit")

        Wargroove.waitTime(0.3)

        table.remove(unitsWithItem, unitIdx)
    end
end

function Blessings.blessing37_condition(Wargroove, playerId, unit)
    if unit.playerId == playerId and unit.unitClassId == "archer" then
        return true
    end
    return false
end

function Blessings.blessing37_action(Wargroove, playerId, unit)
    Wargroove.displayBuffVisualEffect(unit.id, unit.playerId, "fx/general_unit_effect", "spawn", 0.6, {}, "over_units", {x = 0, y = 0}, false, false)
    Wargroove.pushUnitClassModifier(unit.id, "slowness")
    Wargroove.updateUnit(unit)
end

function Blessings.blessing37(Wargroove, Actions, playerId, location)
    -- Your archers can't attack and move in the same turn.
    Wargroove.registerPlayerBlessing("blessing37", playerId)
end

function Blessings.blessing38_condition(Wargroove, playerId, unit)
    if unit.playerId == playerId and unit.unitClassId == "spearman" then
        return true
    end
    return false
end

function Blessings.blessing38_action(Wargroove, playerId, unit)
    Wargroove.displayBuffVisualEffect(unit.id, unit.playerId, "fx/general_unit_effect", "spawn", 0.6, {}, "over_units", {x = 0, y = 0}, false, false)
    Wargroove.pushUnitClassModifier(unit.id, "sickness_dmg")
    Wargroove.updateUnit(unit)
end

function Blessings.blessing38(Wargroove, Actions, playerId, location)
    -- Your spearman deal 25% less damage.
    Wargroove.registerPlayerBlessing("blessing38", playerId)
end

function Blessings.blessing39_condition(Wargroove, playerId, unit)
    if unit.playerId == playerId and unit.unitClassId == "spearman" then
        return true
    end
    return false
end

function Blessings.blessing39_action(Wargroove, playerId, unit)
    Wargroove.displayBuffVisualEffect(unit.id, unit.playerId, "fx/general_unit_effect", "spawn", 0.6, {}, "over_units", {x = 0, y = 0}, false, false)
    Wargroove.pushUnitClassModifier(unit.id, "critical_curse")
    Wargroove.updateUnit(unit)
end

function Blessings.blessing39(Wargroove, Actions, playerId, location)
    -- Your spearman no longer deal critical damage.
    Wargroove.registerPlayerBlessing("blessing39", playerId)
end

function Blessings.blessing40(Wargroove, Actions, playerId, location)
    local multiplier = Wargroove.getKillRewardMultiplier()

    Wargroove.setKillRewardMultiplier(multiplier - 0.25)
end

function Blessings.blessing41(Wargroove, Actions, playerId, location)
    Wargroove.setPlayerCounter("recruit_decline", 1)
end

function Blessings.blessing42(Wargroove, Actions, playerId, location)
    local currentMoney = Wargroove.getMoney(playerId)

    local units = Wargroove.getAllUnitsForPlayer(playerId)
    local commander = nil
    for _, unit in ipairs(units) do
        if unit.playerId == playerId and unit.unitClass.isCommander then
            commander = unit
            break
        end
    end

    Wargroove.changeMoney(playerId, -currentMoney*0.5)
    Wargroove.spawnMapAnimation(commander.pos, 0, "fx/ransack_1", "default", "over_units", { x = 12, y = 0 })
    Wargroove.playPositionlessSound("thiefSteal")
end

function Blessings.blessing43(Wargroove, Actions, playerId, location)
    -- Your commander deals 50% more damage.
    local units = Wargroove.getAllUnitsForPlayer(playerId)
    for _, unit in ipairs(units) do
        if unit.playerId == playerId and unit.unitClass.isCommander then
            Wargroove.pushUnitClassModifier(unit.id, "commander_dmg_boost_high")
            Wargroove.updateUnit(unit)
        end
    end
end

function Blessings.healing01(Wargroove, Actions, playerId, location)
    local units = Wargroove.getAllUnitsForPlayer(playerId)
    local healAmount = 20;

    Wargroove.playPositionlessSound("unitHealed")

    for _, unit in ipairs(units) do
        Wargroove.spawnMapAnimation(unit.pos, 0, "fx/heal_unit")
        unit:setHealth(unit.health + healAmount, unit.id)
        Wargroove.updateUnit(unit)
    end
end

function Blessings.healEvent01(Wargroove, Actions, playerId, location)
    local units = Wargroove.getCommanderUnitsForPlayer(playerId)

    Wargroove.playPositionlessSound("unitHealed")

    for _, unit in ipairs(units) do
        Wargroove.spawnMapAnimation(unit.pos, 0, "fx/heal_unit")
        unit:setHealth(100, unit.id)
        Wargroove.updateUnit(unit)
    end
end


function Blessings.healEvent02(Wargroove, Actions, playerId, location)
    local units = Wargroove.getAllUnitsForPlayer(playerId)
    local healAmount = 20;

    Wargroove.playPositionlessSound("unitHealed")

    for _, unit in ipairs(units) do
        if not unit.unitClass.isCommander then
            Wargroove.spawnMapAnimation(unit.pos, 0, "fx/heal_unit")
            unit:setHealth(unit.health + healAmount, unit.id)
            Wargroove.updateUnit(unit)
        end
    end
end

function Blessings.healEvent01_upgraded(Wargroove, Actions, playerId, location)
    local units = Wargroove.getCommanderUnitsForPlayer(playerId)

    Wargroove.playPositionlessSound("unitHealed")

    for _, commander in ipairs(units) do
        Wargroove.spawnMapAnimation(commander.pos, 0, "units/commanders/groove_powerup_back", "", "behind_units")
        Wargroove.spawnMapAnimation(commander.pos, 0, "units/commanders/groove_powerup_front", "", "over_units")

        local grooveBoostAmount = 100
        local groove = Wargroove.getGroove(commander.grooveId)
        if commander.grooveCharge < groove.grooveCost[1] then
            grooveBoostAmount = groove.grooveCost[1]
        elseif commander.grooveCharge >= groove.grooveCost[1] then
            grooveBoostAmount = groove.grooveCost[2]
        end

        commander.grooveCharge = math.min(grooveBoostAmount, commander.unitClass.maxGroove)

        Wargroove.waitTime(0.3)
        commander:setHealth(100, commander.id)

        Wargroove.updateUnit(commander)
    end
end


function Blessings.healEvent02_upgraded(Wargroove, Actions, playerId, location)
    local units = Wargroove.getAllUnitsForPlayer(playerId)
    local healAmount = 30;

    Wargroove.playPositionlessSound("unitHealed")

    for _, unit in ipairs(units) do
        if not unit.unitClass.isCommander then
            Wargroove.spawnMapAnimation(unit.pos, 0, "fx/heal_unit")
            unit:setHealth(unit.health + healAmount, unit.id)
            Wargroove.updateUnit(unit)
        end
    end
end

local function executeAdditionalBlessing(Wargroove, Actions, playerId, location)
    local additionalBlessingId = Wargroove.popAdditionalBlessingPicked()
    if additionalBlessingId ~= nil then
        local blessing = Wargroove:getBlessing(additionalBlessingId)
        blessing(Wargroove, Actions, playerId, location)
    end
end

function Blessings.startingCommander_mercia(Wargroove, Actions, playerId, location)
    Wargroove.setPlayerColour(playerId, "red")
    Wargroove.setPlayerCommander(playerId, "mercia")

    local units = Wargroove.getUnitsAtLocation(location)

    local unitClassId = "commander_mercia"
    local finalUnit = nil
    for i, unit in ipairs(units) do
        finalUnit = unit
        unit.unitClassId = unitClassId
    end

    Wargroove.updateUnits(units)

    Wargroove.waitFrame()
    Wargroove.clearCaches()

    Wargroove.playUnitAnimation(finalUnit.id, "groove")
    Wargroove.playMapSound("mercia/merciaGroove", finalUnit.pos)
    Wargroove.waitTime(2.1)
    Wargroove.playGrooveEffect()

    checkGrooveBoostUnlock(Wargroove, units[1])

    executeAdditionalBlessing(Wargroove, Actions, playerId, Wargroove.getLocationByName("additional_blessing"))
end

function Blessings.startingCommander_valder(Wargroove, Actions, playerId, location)
    Wargroove.setPlayerColour(playerId, "blue")
    Wargroove.setPlayerCommander(playerId, "valder")

    local units = Wargroove.getUnitsAtLocation(location)

    local unitClassId = "commander_valder"
    local finalUnit = nil
    for i, unit in ipairs(units) do
        finalUnit = unit
        unit.unitClassId = unitClassId
    end

    Wargroove.updateUnits(units)
    Wargroove.waitFrame()
    Wargroove.clearCaches()

    Wargroove.playUnitAnimation(finalUnit.id, "groove")
    Wargroove.playMapSound("valder/valderGroove", finalUnit.pos)
    Wargroove.waitTime(1.7)

    Wargroove.playGrooveEffect()

    checkGrooveBoostUnlock(Wargroove, units[1])

    executeAdditionalBlessing(Wargroove, Actions, playerId, Wargroove.getLocationByName("additional_blessing"))
end

function Blessings.startingCommander_nadia(Wargroove, Actions, playerId, location)
    Wargroove.setPlayerColour(playerId, "black")
    Wargroove.setPlayerCommander(playerId, "nadia")

    local units = Wargroove.getUnitsAtLocation(location)

    local unitClassId = "commander_nadia"
    local finalUnit = nil
    for i, unit in ipairs(units) do
        finalUnit = unit
        unit.unitClassId = unitClassId
    end

    Wargroove.updateUnits(units)
    Wargroove.waitFrame()
    Wargroove.clearCaches()

    Wargroove.playMapSound("nadia/nadiaGroove", finalUnit.pos)
    Wargroove.playUnitAnimation(finalUnit.id, "groove")
    Wargroove.waitTime(1.25)
    Wargroove.playGrooveEffect()

    checkGrooveBoostUnlock(Wargroove, units[1])

    executeAdditionalBlessing(Wargroove, Actions, playerId, Wargroove.getLocationByName("additional_blessing"))
end

function Blessings.startingCommander_sedge(Wargroove, Actions, playerId, location)
    Wargroove.setPlayerColour(playerId, "green")
    Wargroove.setPlayerCommander(playerId, "sedge")

    local units = Wargroove.getUnitsAtLocation(location)

    local unitClassId = "commander_sedge"
    local finalUnit = nil
    for i, unit in ipairs(units) do
        finalUnit = unit
        unit.unitClassId = unitClassId
    end

    Wargroove.updateUnits(units)
    Wargroove.waitFrame()
    Wargroove.clearCaches()

    Wargroove.playUnitAnimation(finalUnit.id, "groove_1")
    Wargroove.playMapSound("sedge/sedgeGroove", finalUnit.pos)
    Wargroove.waitTime(1)

    Wargroove.setVisibleOverride(finalUnit.id, false)
    Wargroove.waitTime(0.8)

    Wargroove.unsetVisibleOverride(finalUnit.id)
    Wargroove.playUnitAnimation(finalUnit.id, "groove_2")
    Wargroove.waitTime(0.4)

    Wargroove.playGrooveEffect()

    checkGrooveBoostUnlock(Wargroove, units[1])

    executeAdditionalBlessing(Wargroove, Actions, playerId, Wargroove.getLocationByName("additional_blessing"))
end

function Blessings.startingCommander_caesar(Wargroove, Actions, playerId, location)
    Wargroove.setPlayerColour(playerId, "red")
    Wargroove.setPlayerCommander(playerId, "caesar")

    local units = Wargroove.getUnitsAtLocation(location)

    local unitClassId = "commander_caesar"
    local finalUnit = nil
    for i, unit in ipairs(units) do
        finalUnit = unit
        unit.unitClassId = unitClassId
    end

    Wargroove.updateUnits(units)
    Wargroove.waitFrame()
    Wargroove.clearCaches()

    Wargroove.playUnitAnimation(finalUnit.id, "groove")
    Wargroove.playMapSound("caesar/caesarGroove", finalUnit.pos)
    Wargroove.waitTime(1.9)
    Wargroove.playMapSound("caesar/caesarGrooveInspired", finalUnit.pos)

    Wargroove.playGrooveEffect()

    checkGrooveBoostUnlock(Wargroove, units[1])

    executeAdditionalBlessing(Wargroove, Actions, playerId, Wargroove.getLocationByName("additional_blessing"))
end

function Blessings.startingCommander_emeric(Wargroove, Actions, playerId, location)
    Wargroove.setPlayerColour(playerId, "red")
    Wargroove.setPlayerCommander(playerId, "emeric")

    local units = Wargroove.getUnitsAtLocation(location)

    local unitClassId = "commander_emeric"
    local finalUnit = nil
    for i, unit in ipairs(units) do
        finalUnit = unit
        unit.unitClassId = unitClassId
    end

    Wargroove.updateUnits(units)
    Wargroove.waitFrame()
    Wargroove.clearCaches()

    Wargroove.playUnitAnimation(finalUnit.id, "groove")
    Wargroove.playMapSound("emeric/emericGroove", finalUnit.pos)
    Wargroove.waitTime(1.3)
    Wargroove.playGrooveEffect()

    checkGrooveBoostUnlock(Wargroove, units[1])

    executeAdditionalBlessing(Wargroove, Actions, playerId, Wargroove.getLocationByName("additional_blessing"))
end

function Blessings.startingCommander_darkmercia(Wargroove, Actions, playerId, location)
    Wargroove.setPlayerColour(playerId, "purple")
    Wargroove.setPlayerCommander(playerId, "darkmercia")

    local units = Wargroove.getUnitsAtLocation(location)

    local unitClassId = "commander_darkmercia"
    local finalUnit = nil
    for i, unit in ipairs(units) do
        finalUnit = unit
        unit.unitClassId = unitClassId
    end

    Wargroove.updateUnits(units)
    Wargroove.waitFrame()
    Wargroove.clearCaches()

    Wargroove.playUnitAnimation(finalUnit.id, "groove")
    Wargroove.playMapSound("darkmercia/darkmerciaGroove", finalUnit.pos)
    Wargroove.waitTime(2.4)

    Wargroove.playGrooveEffect()

    checkGrooveBoostUnlock(Wargroove, units[1])

    executeAdditionalBlessing(Wargroove, Actions, playerId, Wargroove.getLocationByName("additional_blessing"))
end

function Blessings.startingCommander_ragna(Wargroove, Actions, playerId, location)
    Wargroove.setPlayerColour(playerId, "blue")
    Wargroove.setPlayerCommander(playerId, "ragna")

    local units = Wargroove.getUnitsAtLocation(location)

    local unitClassId = "commander_ragna"
    local finalUnit = nil
    for i, unit in ipairs(units) do
        finalUnit = unit
        unit.unitClassId = unitClassId
    end

    Wargroove.updateUnits(units)
    Wargroove.waitFrame()
    Wargroove.clearCaches()

    Wargroove.playUnitAnimation(finalUnit.id, "groove_1")
    Wargroove.waitTime(1.4)
    Wargroove.playMapSound("ragna/ragnaGrooveLanding", finalUnit.pos)
    Wargroove.playUnitAnimation(finalUnit.id, "groove_2")
    Wargroove.waitTime(0.4)

    Wargroove.playGrooveEffect()

    checkGrooveBoostUnlock(Wargroove, units[1])

    executeAdditionalBlessing(Wargroove, Actions, playerId, Wargroove.getLocationByName("additional_blessing"))
end

function Blessings.startingCommander_vesper(Wargroove, Actions, playerId, location)
    Wargroove.setPlayerColour(playerId, "black")
    Wargroove.setPlayerCommander(playerId, "vesper")

    local units = Wargroove.getUnitsAtLocation(location)

    local unitClassId = "commander_vesper"
    local finalUnit = nil
    for i, unit in ipairs(units) do
        finalUnit = unit
        unit.unitClassId = unitClassId
    end

    Wargroove.updateUnits(units)
    Wargroove.waitFrame()
    Wargroove.clearCaches()

    Wargroove.playMapSound("vesper/vesperGroove", finalUnit.pos)
    Wargroove.waitTime(1.0)

    Wargroove.playGrooveEffect()

    checkGrooveBoostUnlock(Wargroove, units[1])

    executeAdditionalBlessing(Wargroove, Actions, playerId, Wargroove.getLocationByName("additional_blessing"))
end

function Blessings.startingCommander_wulfar(Wargroove, Actions, playerId, location)
    Wargroove.setPlayerColour(playerId, "black")
    Wargroove.setPlayerCommander(playerId, "wulfar_pirate")

    local units = Wargroove.getUnitsAtLocation(location)

    local unitClassId = "commander_wulfar_pirate"
    local finalUnit = nil
    for i, unit in ipairs(units) do
        finalUnit = unit
        unit.unitClassId = unitClassId
    end

    Wargroove.updateUnits(units)
    Wargroove.waitFrame()
    Wargroove.clearCaches()

    Wargroove.playMapSound("wulfar/wulfarGroove", finalUnit.pos)
    Wargroove.waitTime(2.1)

    Wargroove.playGrooveEffect()

    checkGrooveBoostUnlock(Wargroove, units[1])

    executeAdditionalBlessing(Wargroove, Actions, playerId, Wargroove.getLocationByName("additional_blessing"))
end

function Blessings.startingCommander_twins(Wargroove, Actions, playerId, location)
    Wargroove.setPlayerColour(playerId, "black")
    Wargroove.setPlayerCommander(playerId, "twins")

    local units = Wargroove.getUnitsAtLocation(location)

    local unitClassId = "commander_twins"
    local finalUnit = nil
    for i, unit in ipairs(units) do
        finalUnit = unit
        unit.unitClassId = unitClassId
    end

    Wargroove.updateUnits(units)
    Wargroove.waitFrame()
    Wargroove.clearCaches()

    Wargroove.playUnitAnimation(finalUnit.id, "groove2")
    Wargroove.playMapSound("twins/orlaGroove", finalUnit.pos)
    Wargroove.waitTime(1.9)

    Wargroove.playGrooveEffect()

    checkGrooveBoostUnlock(Wargroove, units[1])

    executeAdditionalBlessing(Wargroove, Actions, playerId, Wargroove.getLocationByName("additional_blessing"))
end

function Blessings.startingCommander_sigrid(Wargroove, Actions, playerId, location)
    Wargroove.setPlayerColour(playerId, "blue")
    Wargroove.setPlayerCommander(playerId, "sigrid")

    local units = Wargroove.getUnitsAtLocation(location)

    local unitClassId = "commander_sigrid"
    local finalUnit = nil
    for i, unit in ipairs(units) do
        finalUnit = unit
        unit.unitClassId = unitClassId
    end

    Wargroove.updateUnits(units)
    Wargroove.waitFrame()
    Wargroove.clearCaches()

    Wargroove.playMapSound("sigrid/sigridGroove", finalUnit.pos)
    Wargroove.waitTime(0)

    Wargroove.spawnMapAnimation(finalUnit.pos, 0, "fx/groove/sigrid_groove_fx", "groove", "over_units", { x = 12, y = 12 }, "right")

    Wargroove.waitTime(1.0)
    Wargroove.unsetFacingOverride(finalUnit.id)

    Wargroove.playGrooveEffect()

    checkGrooveBoostUnlock(Wargroove, units[1])

    executeAdditionalBlessing(Wargroove, Actions, playerId, Wargroove.getLocationByName("additional_blessing"))
end

function Blessings.startingCommander_elodie(Wargroove, Actions, playerId, location)
    Wargroove.setPlayerColour(playerId, "purple")
    Wargroove.setPlayerCommander(playerId, "elodie")

    local units = Wargroove.getUnitsAtLocation(location)

    local unitClassId = "commander_elodie"
    local finalUnit = nil
    for i, unit in ipairs(units) do
        finalUnit = unit
        unit.unitClassId = unitClassId
    end

    Wargroove.updateUnits(units)
    Wargroove.waitFrame()
    Wargroove.clearCaches()

    Wargroove.playMapSound("elodie/elodieGroove", finalUnit.pos)
    Wargroove.waitTime(1.9)

    Wargroove.playGrooveEffect()

    checkGrooveBoostUnlock(Wargroove, units[1])

    executeAdditionalBlessing(Wargroove, Actions, playerId, Wargroove.getLocationByName("additional_blessing"))
end

function Blessings.startingCommander_pistil(Wargroove, Actions, playerId, location)
    Wargroove.setPlayerColour(playerId, "orange")
    Wargroove.setPlayerCommander(playerId, "pistil")

    local units = Wargroove.getUnitsAtLocation(location)

    local unitClassId = "commander_pistil"
    local finalUnit = nil
    for i, unit in ipairs(units) do
        finalUnit = unit
        unit.unitClassId = unitClassId
    end

    Wargroove.updateUnits(units)
    Wargroove.waitFrame()
    Wargroove.clearCaches()

    Wargroove.playGrooveEffect()

    checkGrooveBoostUnlock(Wargroove, units[1])

    executeAdditionalBlessing(Wargroove, Actions, playerId, Wargroove.getLocationByName("additional_blessing"))
end

function Blessings.startingCommander_tenri(Wargroove, Actions, playerId, location)
    Wargroove.setPlayerColour(playerId, "yellow")
    Wargroove.setPlayerCommander(playerId, "tenri")

    local units = Wargroove.getUnitsAtLocation(location)

    local unitClassId = "commander_tenri"
    local finalUnit = nil
    for i, unit in ipairs(units) do
        finalUnit = unit
        unit.unitClassId = unitClassId
    end

    Wargroove.updateUnits(units)
    Wargroove.waitFrame()
    Wargroove.clearCaches()

    Wargroove.playUnitAnimation(finalUnit.id, "groove")
    Wargroove.playMapSound("tenri/tenriGroove", finalUnit.pos)
    Wargroove.waitTime(1.2)

    Wargroove.playGrooveEffect()

    checkGrooveBoostUnlock(Wargroove, units[1])

    executeAdditionalBlessing(Wargroove, Actions, playerId, Wargroove.getLocationByName("additional_blessing"))
end

function Blessings.startingCommander_koji(Wargroove, Actions, playerId, location)
    Wargroove.setPlayerColour(playerId, "yellow")
    Wargroove.setPlayerCommander(playerId, "koji")

    local units = Wargroove.getUnitsAtLocation(location)

    local unitClassId = "commander_koji"
    local finalUnit = nil
    for i, unit in ipairs(units) do
        finalUnit = unit
        unit.unitClassId = unitClassId
    end

    Wargroove.updateUnits(units)
    Wargroove.waitFrame()
    Wargroove.clearCaches()

    Wargroove.playUnitAnimation(finalUnit.id, "groove")
    Wargroove.playMapSound("koji/kojiGroove", finalUnit.pos)
    Wargroove.waitTime(1.1)    
    Wargroove.playMapSound("koji/kojiDroneSpawn", finalUnit.pos)

    Wargroove.playGrooveEffect()

    checkGrooveBoostUnlock(Wargroove, units[1])

    executeAdditionalBlessing(Wargroove, Actions, playerId, Wargroove.getLocationByName("additional_blessing"))
end

function Blessings.startingCommander_ryota(Wargroove, Actions, playerId, location)
    Wargroove.setPlayerColour(playerId, "yellow")
    Wargroove.setPlayerCommander(playerId, "ryota")

    local units = Wargroove.getUnitsAtLocation(location)

    local unitClassId = "commander_ryota"
    local finalUnit = nil
    for i, unit in ipairs(units) do
        finalUnit = unit
        unit.unitClassId = unitClassId
    end

    Wargroove.updateUnits(units)
    Wargroove.waitFrame()
    Wargroove.clearCaches()

    Wargroove.playUnitAnimation(finalUnit.id, "groove")
    Wargroove.playMapSound("ryota/ryotaGroove", finalUnit.pos)
    Wargroove.waitTime(0.85)

    Wargroove.playGrooveEffect()

    checkGrooveBoostUnlock(Wargroove, units[1])

    executeAdditionalBlessing(Wargroove, Actions, playerId, Wargroove.getLocationByName("additional_blessing"))
end

function Blessings.startingCommander_rhomb(Wargroove, Actions, playerId, location)
    Wargroove.setPlayerColour(playerId, "orange")
    Wargroove.setPlayerCommander(playerId, "rhomb")

    local units = Wargroove.getUnitsAtLocation(location)

    local unitClassId = "commander_rhomb"
    local finalUnit = nil
    for i, unit in ipairs(units) do
        finalUnit = unit
        unit.unitClassId = unitClassId
    end

    Wargroove.updateUnits(units)
    Wargroove.waitFrame()
    Wargroove.clearCaches()

    Wargroove.playGrooveEffect()

    checkGrooveBoostUnlock(Wargroove, units[1])

    executeAdditionalBlessing(Wargroove, Actions, playerId, Wargroove.getLocationByName("additional_blessing"))
end

function Blessings.startingCommander_lytra(Wargroove, Actions, playerId, location)
    Wargroove.setPlayerColour(playerId, "orange")
    Wargroove.setPlayerCommander(playerId, "lytra")

    local units = Wargroove.getUnitsAtLocation(location)

    local unitClassId = "commander_lytra"
    local finalUnit = nil
    for i, unit in ipairs(units) do
        finalUnit = unit
        unit.unitClassId = unitClassId
    end

    Wargroove.updateUnits(units)
    Wargroove.waitFrame()
    Wargroove.clearCaches()

    Wargroove.playGrooveEffect()

    checkGrooveBoostUnlock(Wargroove, units[1])

    executeAdditionalBlessing(Wargroove, Actions, playerId, Wargroove.getLocationByName("additional_blessing"))
end


function Blessings.startingCommander_mercival(Wargroove, Actions, playerId, location)
    Wargroove.setPlayerColour(playerId, "red")
    Wargroove.setPlayerCommander(playerId, "mercival")

    local units = Wargroove.getUnitsAtLocation(location)

    local unitClassId = "commander_mercival"
    local finalUnit = nil
    for i, unit in ipairs(units) do
        finalUnit = unit
        unit.unitClassId = unitClassId
    end

    Wargroove.updateUnits(units)
    Wargroove.waitFrame()
    Wargroove.clearCaches()

    Wargroove.playGrooveEffect()

    checkGrooveBoostUnlock(Wargroove, units[1])

    executeAdditionalBlessing(Wargroove, Actions, playerId, Wargroove.getLocationByName("additional_blessing"))
end


function Blessings.startingCommander_nuru(Wargroove, Actions, playerId, location)
    Wargroove.setPlayerColour(playerId, "green")
    Wargroove.setPlayerCommander(playerId, "nuru")

    local units = Wargroove.getUnitsAtLocation(location)

    local unitClassId = "commander_nuru"
    local finalUnit = nil
    for i, unit in ipairs(units) do
        finalUnit = unit
        unit.unitClassId = unitClassId
    end

    Wargroove.updateUnits(units)
    Wargroove.waitFrame()
    Wargroove.clearCaches()

    Wargroove.playGrooveEffect()

    checkGrooveBoostUnlock(Wargroove, units[1])

    executeAdditionalBlessing(Wargroove, Actions, playerId, Wargroove.getLocationByName("additional_blessing"))
end


function Blessings.startingCommander_greenfinger(Wargroove, Actions, playerId, location)
    Wargroove.setPlayerColour(playerId, "green")
    Wargroove.setPlayerCommander(playerId, "greenfinger")

    local units = Wargroove.getUnitsAtLocation(location)

    local unitClassId = "commander_greenfinger"
    local finalUnit = nil
    for i, unit in ipairs(units) do
        finalUnit = unit
        unit.unitClassId = unitClassId
    end

    Wargroove.updateUnits(units)
    Wargroove.waitFrame()
    Wargroove.clearCaches()

    Wargroove.playGrooveEffect()

    checkGrooveBoostUnlock(Wargroove, units[1])

    executeAdditionalBlessing(Wargroove, Actions, playerId, Wargroove.getLocationByName("additional_blessing"))
end


function Blessings.unitDoubling01(Wargroove, Actions, playerId, location)
    local dropLocation = Wargroove.getLocationByName("unit_duplicate_area")
    
    local unit = Wargroove.getUnitsAtLocation(location)[1]
    local spawnPoint = Wargroove.findCentreOfLocation(dropLocation)

    local newId = Wargroove.spawnUnit(playerId, spawnPoint, unit.unitClassId, false)
    local newUnit = Wargroove.getUnitById(newId)
    if unit.itemId ~= "" then
        Wargroove.equipItem(newUnit, unit.itemId)
    end

    newUnit.health = unit.health
    Wargroove.updateUnit(newUnit)
end

function Blessings.tollEvent01(Wargroove, Actions, playerId, location)
    local units = Wargroove.getUnitsAtLocation(location)

    local validUnits = {}
    
    for _, unit in ipairs(units) do
        if not unit.unitClass.isCommander then
            table.insert(validUnits, unit)
        end
    end

    local idx = Wargroove.randomInteger(tostring(playerId)..tostring(#validUnits), 1, #validUnits)
    local targetUnit = validUnits[idx]

    targetUnit.playerId = playerId

    Wargroove.updateUnit(targetUnit)
    Wargroove.waitFrame()
    Wargroove.clearCaches()
end

function Blessings.assassinsEmporiumEvent01(Wargroove, Actions, playerId, location)
    local unitSpawnOptions = { "soldier", "spearman", "dog" }
    local itemSpawnOptions = { "strong_arm", "thiefs_hand", "heavy_armor" }

    local unitIdx = Wargroove.randomIntegerFromTable({ playerId, location.id, unitSpawnOptions[1], unitSpawnOptions[2], unitSpawnOptions[3] }, 1, #unitSpawnOptions)
    local itemIdx = Wargroove.randomIntegerFromTable({ playerId, location.id, itemSpawnOptions[1], itemSpawnOptions[2], itemSpawnOptions[3] }, 1, #itemSpawnOptions)

    Actions.doSpawnUnit(1, unitSpawnOptions[unitIdx], playerId, location, false, true, true, false)

    local units = Wargroove.getUnitsAtLocation(location)
    Wargroove.equipItem(units[1], itemSpawnOptions[itemIdx])

    Wargroove.changeMoney(playerId, -100)
    Wargroove.playPositionlessSound("thiefSteal")
end

function Blessings.commanderGenericGroove(Wargroove, Actions, playerId, location)
    local units = Wargroove.getUnitsAtLocation(location)

    local unit = units[1]

    Wargroove.playUnitAnimation(unit.id, "groove")

    if unit.unitClassId == "commander_darkmercia" then
        Wargroove.playMapSound("darkmercia/darkmerciaGroove", finalUnit.pos)
        Wargroove.waitTime(2.4)
    elseif unit.unitClassId == "commander_caesar" then
        Wargroove.playMapSound("caesar/caesarGroove", unit.pos)
        Wargroove.spawnMapAnimation(unit.pos, 1, "fx/groove/caesar_groove_fx")
        Wargroove.waitTime(1.9)
        Wargroove.playMapSound("caesar/caesarGrooveInspired", unit.pos)
    elseif unit.unitClassId == "commander_elodie" then
        Wargroove.playMapSound("elodie/elodieGroove", unit.pos)
        Wargroove.waitTime(1.9)
    elseif unit.unitClassId == "commander_emeric" then
        Wargroove.playMapSound("emeric/emericGroove", unit.pos)
        Wargroove.waitTime(1.3)
    elseif unit.unitClassId == "commander_greenfinger" then
        Wargroove.playMapSound("greenfinger/greenfingerGroove", unit.pos)
        Wargroove.waitTime(1.0)
    elseif unit.unitClassId == "commander_koji" then
        Wargroove.playMapSound("koji/kojiGroove", unit.pos)
        Wargroove.waitTime(1.1)    
        Wargroove.playMapSound("koji/kojiDroneSpawn", unit.pos)
    elseif unit.unitClassId == "commander_lytra" then
    
    elseif unit.unitClassId == "commander_mercia" then
        Wargroove.playMapSound("mercia/merciaGroove", unit.pos)
        Wargroove.waitTime(2.1)
    elseif unit.unitClassId == "commander_mercival" then
        Wargroove.playMapSound("mercival/mercivalGroove", unit.pos)
        Wargroove.waitTime(3.0)
    elseif unit.unitClassId == "commander_nadia" then
        Wargroove.playMapSound("nadia/nadiaGroove", unit.pos)
        Wargroove.waitTime(1.25)
    elseif unit.unitClassId == "commander_nuru" then
        Wargroove.playMapSound("nuru/nuruGroove", unit.pos)
        Wargroove.waitTime(1.7)
    elseif unit.unitClassId == "commander_pistil" then
    
    elseif unit.unitClassId == "commander_ragna" then
        Wargroove.playUnitAnimation(unit.id, "groove_1")
        Wargroove.waitTime(1.4)
        Wargroove.playMapSound("ragna/ragnaGrooveLanding", unit.pos)
        Wargroove.playUnitAnimation(unit.id, "groove_2")
        Wargroove.waitTime(0.4)
    elseif unit.unitClassId == "commander_rhomb" then
    
    elseif unit.unitClassId == "commander_ryota" then
        Wargroove.playMapSound("ryota/ryotaGroove", unit.pos)
        Wargroove.waitTime(0.85)
    elseif unit.unitClassId == "commander_sedge" then
        Wargroove.playUnitAnimation(unit.id, "groove_1")
        Wargroove.playMapSound("sedge/sedgeGroove", unit.pos)
        Wargroove.waitTime(1)
        Wargroove.playUnitAnimation(unit.id, "groove_2")
    elseif unit.unitClassId == "commander_sigrid" then
        Wargroove.playMapSound("sigrid/sigridGroove", unit.pos)
        Wargroove.waitTime(0)

        Wargroove.spawnMapAnimation(unit.pos, 0, "fx/groove/sigrid_groove_fx", "groove", "over_units", { x = 12, y = 12 }, "right")

        Wargroove.waitTime(1.0)
        Wargroove.unsetFacingOverride(unit.id)
    elseif unit.unitClassId == "commander_tenri" then
        Wargroove.playMapSound("tenri/tenriGroove", unit.pos)
        Wargroove.waitTime(1.2)
    elseif unit.unitClassId == "commander_twins" then
        Wargroove.playUnitAnimation(unit.id, "groove2")
        Wargroove.playMapSound("twins/orlaGroove", unit.pos)
        Wargroove.waitTime(1.9)
    elseif unit.unitClassId == "commander_valder" then
        Wargroove.playMapSound("valder/valderGroove", unit.pos)
        Wargroove.waitTime(1.7)
    elseif unit.unitClassId == "commander_vesper" then
        Wargroove.playMapSound("vesper/vesperGroove", unit.pos)
        Wargroove.waitTime(1.0)
    elseif unit.unitClassId == "commander_wulfar" or unit.unitClassId == "commander_wulfar_pirate"  then
        Wargroove.playMapSound("wulfar/wulfarGroove", unit.pos)
        Wargroove.waitTime(2.1)
    end

    Wargroove.playGrooveEffect()
end

function Blessings.activateDeathGauntletShield(Wargroove, Actions, playerId, location)
    local units = Wargroove.getUnitsAtLocation(location)

    local unit = units[1]

    Wargroove.playUnitAnimation(unit.id, "shield_spawn", "shield_idle")
    Wargroove.waitTime(1.8)
end

function Blessings.deactivateDeathGauntletShield(Wargroove, Actions, playerId, location)
    local units = Wargroove.getUnitsAtLocation(location)

    local unit = units[1]

    Wargroove.playUnitAnimation(unit.id, "shield_despawn", "idle")
    Wargroove.waitTime(1.8)

end

function Blessings.spawnDeathGauntletGrowth(Wargroove, Actions, playerId, location)
    local pos = Wargroove.findCentreOfLocation(location)
    Wargroove.spawnUnit(playerId, pos, "growth", false, "spawn")
end

function Blessings.siegedVillageHigh(Wargroove, Actions, playerId, location)
    local items = { "guiding_light", "crystal_drop", "heavy_armor", "heavy_armor" }

    local itemIdx = Wargroove.randomIntegerFromTable({ playerId, location.id, items[1], items[2], items[3], items[4] }, 1, #items)
    Wargroove.spawnItem(location, items[itemIdx])
end

function Blessings.siegedVillageLow(Wargroove, Actions, playerId, location)
    local goldReward = 250

    local units = Wargroove.getAllUnitsForPlayer(playerId)
    for _, unit in ipairs(units) do
        if unit.playerId == playerId and unit.unitClass.isCommander then
            Wargroove.spawnMapAnimation(unit.pos, 0, "fx/ransack_1", "default", "over_units", { x = 12, y = 0 })
            break
        end
    end

    Wargroove.changeMoney(playerId, goldReward)
    Wargroove.playPositionlessSound("thiefGoldObtained")
end

function Blessings.bathPositive(Wargroove, Actions, playerId, location)
    local healAmount = 30
    local units = Wargroove.getAllUnitsForPlayer(playerId)

    Wargroove.playPositionlessSound("unitHealed")

    for _, unit in ipairs(units) do
        Wargroove.spawnMapAnimation(unit.pos, 0, "fx/heal_unit")
        unit:setHealth(unit.health + healAmount, unit.id)
        Wargroove.updateUnit(unit)
    end
end

function Blessings.bathNegative(Wargroove, Actions, playerId, location)
    local damageAmount = -20
    local units = Wargroove.getAllUnitsForPlayer(playerId)

    Wargroove.playPositionlessSound("darkmercia/darkmerciaGrooveUnitDrained")

    for _, unit in ipairs(units) do
        Wargroove.spawnPaletteSwappedMapAnimation(unit.pos, 0, "fx/drain_unit")
        unit:setHealth(unit.health + damageAmount, unit.id)
        Wargroove.updateUnit(unit)
    end
end

function Blessings.flightSchoolEvent01(Wargroove, Actions, playerId, location)
    local unitSpawnOptions = { "harpy", "griffin_walking", "balloon" }
    local itemSpawnOptions = { "thiefs_hand", "", "", "", "inexperience", "inexperience" }
    local healthSpawnOptions = { 100, 100, 100, 80, 80, 80, 60 }

    local unitIdx = Wargroove.randomIntegerFromTable({ playerId, location.id, unitSpawnOptions[1], unitSpawnOptions[2], unitSpawnOptions[3] }, 1, #unitSpawnOptions)
    local itemIdx = Wargroove.randomIntegerFromTable({ playerId, location.id, itemSpawnOptions[1], itemSpawnOptions[2], itemSpawnOptions[3] }, 1, #itemSpawnOptions)
    local healthIdx = Wargroove.randomIntegerFromTable({ playerId, location.id, itemSpawnOptions[1], unitSpawnOptions[2], healthSpawnOptions[3] }, 1, #healthSpawnOptions)

    Actions.doSpawnUnit(1, unitSpawnOptions[unitIdx], playerId, location, false, true, true, false)

    local units = Wargroove.getUnitsAtLocation(location)
    if itemSpawnOptions[itemIdx] ~= "" then
        Wargroove.equipItem(units[1], itemSpawnOptions[itemIdx])
    end

    units[1]:setHealth(healthSpawnOptions[healthIdx], -1)
    Wargroove.updateUnit(units[1])
end

function Blessings.unitTransformerEventUnit(Wargroove, Actions, playerId, location)
    local unitSpawnOptions = { "soldier", "soldier", "spearman", "spearman", "dog", "dog", "mage", "mage", "knight", "knight", "griffin_walking", "villager", "villager" }

    local unit = Wargroove.getUnitsAtLocation(location)[1]
    for i=#unitSpawnOptions,1,-1 do
        if unitSpawnOptions[i] == unit.unitClassId then
            table.remove(unitSpawnOptions, i)
        end
    end
    
    local unitIdx = Wargroove.randomIntegerFromTable({ playerId, location.id, unitSpawnOptions[1], unitSpawnOptions[2], unitSpawnOptions[3] }, 1, #unitSpawnOptions)
    unit.unitClassId = unitSpawnOptions[unitIdx]

    Wargroove.spawnMapAnimation(unit.pos, 0, "fx/mapeditor_unitdrop")
    Wargroove.playMapSound("spawn", unit.pos)

    Wargroove.updateUnit(unit)
end


function Blessings.unitTransformerEventCO(Wargroove, Actions, playerId, location)
    local unitSpawnOptions = { "commander_valder", "commander_ragna", "commander_vesper", "commander_wulfar", "commander_twins", "commander_sigrid", "commander_elodie", "commander_sedge", "commander_pistil" }
    local commanderOptions = { "valder", "ragna", "vesper", "wulfar", "twins", "sigrid", "elodie", "sedge", "pistil" }

    local unit = Wargroove.getUnitsAtLocation(location)[1]
    for i=#unitSpawnOptions,1,-1 do
        if unitSpawnOptions[i] == unit.unitClassId then
            table.remove(unitSpawnOptions, i)
            table.remove(commanderOptions, i)
        end
    end
    
    local unitIdx = Wargroove.randomIntegerFromTable({ playerId, location.id, unitSpawnOptions[1], unitSpawnOptions[2], unitSpawnOptions[3] }, 1, #unitSpawnOptions)
    unit.unitClassId = unitSpawnOptions[unitIdx]
    Wargroove.setPlayerCommander(playerId, commanderOptions[unitIdx])

    Wargroove.spawnMapAnimation(unit.pos, 0, "fx/mapeditor_unitdrop")
    Wargroove.playMapSound("spawn", unit.pos)

    Wargroove.updateUnit(unit)
end

function Blessings.tenriFakeGroove(Wargroove, Actions, playerId, location)
    local unit = Wargroove.getAllUnitsOfType(playerId, "commander_tenri")[1]
    if unit == nil then
        return
    end
    
    local targetUnit = nil
    for i, u in ipairs(Wargroove.getUnitsAtLocation(location)) do
        if u.unitClassId == "commander_ryota" then
            targetUnit = u
            break
        end
    end 
    
    local targetLocation = Wargroove.getLocationByName("RyotaTeleportDynamic")
    local teleportPosition = Wargroove.findPlaceInLocation(targetLocation, "commander_ryota")[1].pos
    if teleportPosition == nil then
        return
    end

    print(Wargroove.tableToString(targetLocation))
    print(Wargroove.tableToString(teleportPosition))
    
    Wargroove.playPositionlessSound("battleStart")
    Wargroove.playGrooveCutscene(unit.id)

    Wargroove.playUnitAnimation(unit.id, "groove")
    Wargroove.playMapSound("tenri/tenriGroove", unit.pos)
    Wargroove.waitTime(1.2)
    Wargroove.playGrooveEffect()

    local tornadoFrontEntityId = Wargroove.spawnUnitEffect(targetUnit.id, targetUnit.id, "units/commanders/tenri/tornado_front", "idle", "spawn", true)
    local tornadoBackEntityId = Wargroove.spawnUnitEffect(targetUnit.id, targetUnit.id, "units/commanders/tenri/tornado_back", "idle", "spawn", false)
    Wargroove.playMapSound("tenri/tenriGrooveTornado", targetUnit.pos)

    Wargroove.waitTime(0.4)

    Wargroove.moveUnitToOverride(targetUnit.id, targetUnit.pos, 0, -0.5, 3)

    while (Wargroove.isLuaMoving(targetUnit.id)) do
        coroutine.yield()
    end

    Wargroove.moveUnitToOverride(targetUnit.id, teleportPosition, 0, -0.5, 5)

    while (Wargroove.isLuaMoving(targetUnit.id)) do
        coroutine.yield()
    end
    
    Wargroove.moveUnitToOverride(targetUnit.id, teleportPosition, 0, 0, 3)

    while (Wargroove.isLuaMoving(targetUnit.id)) do
        coroutine.yield()
    end

    targetUnit.pos = { x = teleportPosition.x, y = teleportPosition.y }
    Wargroove.updateUnit(targetUnit)

    Wargroove.deleteUnitEffect(tornadoFrontEntityId, "death")
    Wargroove.deleteUnitEffect(tornadoBackEntityId, "death")

    Wargroove.waitTime(0.5)
end

function Blessings.shipyardEvent(Wargroove, Actions, playerId, location)
    local units = Wargroove.getAllUnitsForPlayer(playerId)
    local healAmountMin = 20;
    local healAmountMax = 40;

    Wargroove.playPositionlessSound("unitHealed")

    for i, unit in ipairs(units) do
        if Wargroove.doesUnitHaveTag(unit, { "type.sea.light", "type.sea.medium", "type.sea.heavy"}) then
            
            local healAmount = Wargroove.randomIntegerFromTable({unit.pos, unit.unitClassId, i}, healAmountMin, healAmountMax)

            Wargroove.spawnMapAnimation(unit.pos, 0, "fx/heal_unit")
            unit:setHealth(unit.health + healAmount, unit.id)
            Wargroove.updateUnit(unit)
        end
    end
end

function Blessings.ancientTempleEvent(Wargroove, Actions, playerId, location)
    local units = Wargroove.getAllUnitsForPlayer(playerId)
    for _, unit in ipairs(units) do
        if unit.playerId == playerId and unit.unitClass.isCommander then
            Wargroove.spawnMapAnimation(unit.pos, 0, "units/commanders/groove_powerup_back", "", "behind_units")
            Wargroove.spawnMapAnimation(unit.pos, 0, "units/commanders/groove_powerup_front", "", "over_units")

            Wargroove.waitTime(0.6)

            unit:setGroove(unit.unitClass.maxGroove)
            Wargroove.updateUnit(unit)
        end
    end
end

function Blessings.prisonEvent(Wargroove, Actions, playerId, location)
    local unitOptions = { "soldier", "spearman", "archer", "griffin_walking" }

    local optionIdx = Wargroove.randomIntegerFromTable({location.name, playerId, unitOptions[1]}, 1, #unitOptions)

    local units = Wargroove.getUnitsAtLocation(location)
    for _, unit in ipairs(units) do
        if unit.unitClassId == "villager" then
            unit.unitClassId = unitOptions[optionIdx]
            unit.playerId = playerId
            Wargroove.updateUnit(unit)
            Wargroove.spawnMapAnimation(unit.pos, 0, "fx/mapeditor_unitdrop")
        end
    end
end

function Blessings.organActivation(Wargroove, Actions, playerId, location)
    local unit = Wargroove.getUnitsAtLocation(location)[1]

    Wargroove.playUnitAnimation(unit.id, "activate", "activated")
    Wargroove.waitTime(0.7)

    unit.unitClassId = "organ"
    Wargroove.updateUnit(unit)
end

function Blessings.organUpActivation(Wargroove, Actions, playerId, location)
    local unit = Wargroove.getUnitsAtLocation(location)[1]

    Wargroove.playUnitAnimation(unit.id, "activate", "activated")
    Wargroove.waitTime(0.7)

    unit.unitClassId = "organ_up"
    Wargroove.updateUnit(unit)
end

function Blessings.organChargeUp(Wargroove, Actions, playerId, location)
    local unit = Wargroove.getUnitsAtLocation(location)[1]

    Wargroove.trackCameraTo(unit.pos)
    Wargroove.playUnitAnimation(unit.id, "attack", "attack_idle")

    Wargroove.waitTime(0.4)

    local facing = "down"
    if unit.pos.y < 18 then
        facing = "down"
    elseif unit.pos.x > 20 then
        facing = "right"
    elseif unit.pos.x < 15 then
        facing = "left"
    end

    Wargroove.playUnitAnimation(unit.id, "idle")

    local highlightLocation = Wargroove.getLocationByName("boss_attack_area_" .. facing)
    Wargroove.highlightLocation(highlightLocation.id, "boss_attack_area_" .. facing, "red", false, false, false, false)
    local safeArea = Wargroove.getLocationByName("boss_safe_area_" .. facing)
    Wargroove.highlightLocation(safeArea.id, "safe_space", "green", false, false, false, false)
    Wargroove.trackCameraTo(highlightLocation.centre)

    Wargroove.waitTime(1.0)
end

function Blessings.healingPadPositive(Wargroove, Actions, playerId, location)
    local unit = Wargroove.getUnitsAtLocation(location)[1]

    Wargroove.trackCameraTo(unit.pos)

    Wargroove.playPositionlessSound("unitHealed")

    Wargroove.spawnMapAnimation(unit.pos, 0, "fx/heal_unit")
    unit:setHealth(unit.health + 50, unit.id)
    Wargroove.updateUnit(unit)
end

function Blessings.healingPadNegative(Wargroove, Actions, playerId, location)
    local unit = Wargroove.getUnitsAtLocation(location)[1]

    Wargroove.trackCameraTo(unit.pos)

    Wargroove.playMapSound("darkmercia/darkmerciaGrooveUnitDrained", unit.pos)

    Wargroove.spawnPaletteSwappedMapAnimation(unit.pos, 0, "fx/drain_unit")
    unit:setHealth(unit.health - 50, unit.id)
    
    if unit.health <= 0 then
        Wargroove.removeUnit(unit.id)
    else
        Wargroove.updateUnit(unit)
    end
end

function Blessings.breakawayEvent(Wargroove, Actions, playerId, location)
    local terrain = "sea"
    local animation = "fx/map_effects/ground_break_dungeon"
    local time = 250
    local removeDecorations = true
    local fxOverUnits = false
    local numberToDrop = 5

    local positions = {}
    
    local loopCount = 0 
    while #positions < numberToDrop do
        local idx = Wargroove.randomIntegerFromTable({ terrain, time, location, loopCount, positions }, 1, #location.positions)
        loopCount = loopCount + 1

        if Wargroove.getTerrainNameAt(location.positions[idx]) ~= "sea" then
            table.insert(positions, location.positions[idx])
        end
    end

    local tempPositions = {}
    local dropCount = Wargroove.randomInteger(animation..tostring(i)..tostring(dropCount), 1, 4)
    local dropCounter = 0
    local lastUnitId = -1
    
    -- If we don't do this, we'll crash since we'll get state confusion
    local doIndividualDeathCheck = true
    if time == 0 then
        doIndividualDeathCheck = false
    end

    local highlightLocation = Wargroove.getLocationByName("_breakaway_area")
    Wargroove.setLocationArea(highlightLocation.id, positions)
    Wargroove.highlightLocation(highlightLocation.id, "danger_space", "red", false, false, false, false)

    Wargroove.waitTime(1.5)

    Wargroove.highlightLocation(highlightLocation.id, "none", "red", false, false, false, false)

    for i, pos in ipairs(positions) do
        local animVariation = Wargroove.randomInteger(animation..tostring(pos.x)..tostring(pos.y), 1, 3)

        if animation ~= "" then
            if fxOverUnits then
                Wargroove.spawnMapAnimation(pos, 0, animation..tostring(animVariation), "over_units")
            else
                Wargroove.spawnMapAnimation(pos, 0, animation..tostring(animVariation))
            end
        end

        table.insert(tempPositions, pos)
        dropCounter = dropCounter + 1
        
        if dropCounter == dropCount then
            if time ~= 0 then
                Wargroove.waitTime(time * 0.001)
            end

            for _, tmpPos in ipairs(tempPositions) do
                if Wargroove.getUnitAt(tmpPos) ~= nil then
                    lastUnitId = Wargroove.getUnitIdAt(tmpPos)
                end

                Wargroove.setTerrainType(tmpPos, terrain, removeDecorations)
            end

            if doIndividualDeathCheck and lastUnitId ~= -1 then
                local lastUnit = Wargroove.getUnitById(lastUnitId)

                Wargroove.doLuaDeathCheck(lastUnitId)
                lastUnitId = -1
                coroutine.yield()
            end

            tempPositions = {}
            dropCounter = 0
            dropCount = Wargroove.randomInteger(animation..tostring(i)..tostring(dropCount), 1, 4)
        end
    end

    if dropCounter > 0 then
        if time ~= 0 then
            Wargroove.waitTime(time * 0.001)
        end
        for _, tmpPos in ipairs(tempPositions) do
            if Wargroove.getUnitAt(tmpPos) ~= nil then
                lastUnitId = Wargroove.getUnitIdAt(tmpPos)
            end

            Wargroove.setTerrainType(tmpPos, terrain, removeDecorations)
        end
    end

    if lastUnitId ~= -1 then
        Wargroove.doLuaDeathCheck(lastUnitId)
        coroutine.yield()
    end

    Wargroove.showMapUI(true)
    Wargroove.waitTime(1.25)

    -- Reward player
    Wargroove.changeMoney(playerId, 250)
    Wargroove.playPositionlessSound("thiefGoldObtained")

    local units = Wargroove.getAllUnitsForPlayer(playerId)
    for _, unit in ipairs(units) do
        if unit.playerId == playerId and unit.unitClass.isCommander then
            Wargroove.spawnMapAnimation(unit.pos, 0, "fx/ransack_1", "default", "over_units", { x = 12, y = 0 })
            break
        end
    end

    Wargroove.waitTime(1.0)
    Wargroove.showMapUI(false)
end

function Blessings.smugglerHeal(Wargroove, Actions, playerId, location)
    local units = Wargroove.getAllUnitsForPlayer(playerId)
    local healAmount = 30;

    Wargroove.playPositionlessSound("unitHealed")

    for _, unit in ipairs(units) do
        Wargroove.spawnMapAnimation(unit.pos, 0, "fx/heal_unit")
        unit:setHealth(unit.health + healAmount, unit.id)
        Wargroove.updateUnit(unit)
    end
end

function Blessings.soldierTraining(Wargroove, Actions, playerId, location)
    local units = Wargroove.getAllUnitsForPlayer(playerId)

    for _, unit in ipairs(units) do
        if unit.unitClassId == "soldier" then
            Wargroove.spawnMapAnimation(unit.pos, 0, "fx/groove/inspire_unit")
            Wargroove.pushUnitClassModifier(unit.id, "movement_range_bonus")
            Wargroove.updateUnit(unit)
        end
    end
end

function Blessings.spearmanTraining(Wargroove, Actions, playerId, location)
    local units = Wargroove.getAllUnitsForPlayer(playerId)

    for _, unit in ipairs(units) do
        if unit.unitClassId == "spearman" then
            Wargroove.spawnMapAnimation(unit.pos, 0, "fx/groove/inspire_unit")
            Wargroove.pushUnitClassModifier(unit.id, "movement_range_bonus")
            Wargroove.updateUnit(unit)
        end
    end
end

function Blessings.archerTraining(Wargroove, Actions, playerId, location)
    local units = Wargroove.getAllUnitsForPlayer(playerId)

    for _, unit in ipairs(units) do
        if unit.unitClassId == "archer" then
            Wargroove.spawnMapAnimation(unit.pos, 0, "fx/groove/inspire_unit")
            Wargroove.pushUnitClassModifier(unit.id, "archer_dmg_boost")
            Wargroove.updateUnit(unit)
        end
    end
end

function Blessings.dogTraining(Wargroove, Actions, playerId, location)
    local units = Wargroove.getAllUnitsForPlayer(playerId)

    for _, unit in ipairs(units) do
        if unit.unitClassId == "dog" then
            Wargroove.spawnMapAnimation(unit.pos, 0, "fx/groove/inspire_unit")
            Wargroove.pushUnitClassModifier(unit.id, "dog_dmg_boost")
            Wargroove.updateUnit(unit)
        end
    end
end

function Blessings.mageTraining(Wargroove, Actions, playerId, location)
    local units = Wargroove.getAllUnitsForPlayer(playerId)

    for _, unit in ipairs(units) do
        if unit.unitClassId == "mage" then
            Wargroove.spawnMapAnimation(unit.pos, 0, "fx/groove/inspire_unit")
            Wargroove.pushUnitClassModifier(unit.id, "mage_training")
            Wargroove.updateUnit(unit)
        end
    end
end

function Blessings.itemDuplicationPositive(Wargroove, Actions, playerId, location)
    local dropLocation = Wargroove.getLocationByName("unit_duplicate_area")
    
    local unit = Wargroove.getUnitsAtLocation(location)[1]
    local itemId = unit.itemId
    local spawnPoint = Wargroove.findCentreOfLocation(dropLocation)

    Wargroove.spawnItemAt(itemId, spawnPoint)
end

function Blessings.itemDuplicationNegative(Wargroove, Actions, playerId, location)
    local unit = Wargroove.getUnitsAtLocation(location)[1]
    
    Wargroove.unequipItem(unit)
    Wargroove.updateUnit(unit)
end

function Blessings.vineSpawn(Wargroove, Actions, playerId, location)
    Wargroove.playMapSound("greenfinger/greenfingerGroove", location.positions[1])
    for _, pos in ipairs(location.positions) do
        local unit = Wargroove.getUnitAt(pos)

        if unit == nil then
            Wargroove.spawnUnit(playerId, pos, "vine_boss", true, "spawn")
            Wargroove.waitTime(0.05)
        end
    end
    Wargroove.clearCaches()
end

function Blessings.makeUnattackable(Wargroove, Actions, playerId, location)
    for _, pos in ipairs(location.positions) do
        local unit = Wargroove.getUnitAt(pos)

        if unit ~= nil then
            unit.canBeAttacked = false
            Wargroove.updateUnit(unit)

            print("Setting to unattackable " .. unit.unitClassId)
        end
    end
    Wargroove.clearCaches()
end

function PlayerBlessings:getBlessing(Wargroove, blessingId)
    return Blessings[blessingId]
end

return PlayerBlessings