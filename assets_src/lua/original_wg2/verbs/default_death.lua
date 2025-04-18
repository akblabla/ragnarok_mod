local Wargroove = require "wargroove/wargroove"
local Verb = require "wargroove/verb"
local Combat = require "wargroove/combat"

local DefaultDeath = Verb:new()

local deathReward = 0.25
local itemDeathReward = 0.5
local eliteCrystalReward = {2, 3, 5}
local bossCrystalReward = {10, 15, 20}

local maxCrystalsDrops = {3, 5, 8}

local function dropCrystal(pos)
    Wargroove.spawnMapAnimation(pos, 1, "fx/map_effects/crystal_drop2_fx", "idle", "units", {x = 12, y = 16})
    Wargroove.waitTime(0.1)
end

local function dropCrystalRewards(crystals, unit)
    Wargroove.waitTime(0.3)

    local targets = Wargroove.getTargetsInRange(unit.pos, 3, "empty")
    local function distFromTarget(a)
        return math.abs(a.x - unit.pos.x) + math.abs(a.y - unit.pos.y)
    end
    table.sort(targets, function(a, b) return distFromTarget(a) < distFromTarget(b) end)

    for i=1,crystals,1 do
        if i < #targets then
            dropCrystal(targets[i])
        end
    end

    Wargroove.playMapSound("mageSpell", unit.pos)

    Wargroove.rewardCrystals(crystals)
end

function DefaultDeath:execute(unit, targetPos, strParam, path)
    --print("Default Death!")

    if unit.tentacled then
        local krakenId = Wargroove.getUnitState(unit, "parentId")
        local kraken = Wargroove.getUnitById(tonumber(krakenId))

        local tentaclePositionsString = Wargroove.getUnitState(kraken, "tentacles")
        local tentaclePositions = Wargroove.stringToPositions(tentaclePositionsString)
        
        for i, pos in ipairs(tentaclePositions) do
            local tentacle = Wargroove.getUnitAt(pos)
            
            tentacle:setHealth(0, tentacle.id, true)
            Wargroove.removeUnit(tentacle.id)
        end
        
        Wargroove.deleteUnitEffectByAnimation(unit.id, "units/kraken/cherrystone/map_kraken_tentacle_cherrystone", "")
        Wargroove.setUnitState(kraken, "tentacles", "")
        Wargroove.setUnitState(kraken, "targetId", nil)
        Wargroove.updateUnit(kraken)
        
        Wargroove.playUnitAnimation(kraken.id, "idle")
    end

    if Wargroove.isConquestMode() then
        if not Wargroove.isHuman(unit.playerId) and unit.attackerId >= 0 then
            
            Wargroove.spawnMapAnimation(unit.pos, 0, "fx/ransack_1", "default", "over_units", { x = 12, y = 0 })
            
            local difficulty = Wargroove.getConquestDifficulty() + 1

            if unit.itemId ~= "" or unit.unitClass.isCommander then
                Wargroove.changeMoney(0, unit.unitClass.cost * itemDeathReward * Wargroove.getKillRewardMultiplier())

                if unit.grooveId ~= "" then
                    dropCrystalRewards(bossCrystalReward[difficulty], unit)
                else
                    dropCrystalRewards(eliteCrystalReward[difficulty], unit)
                end
            else
                local drops = Wargroove.getPlayerCounter("crystalDrops")

                if drops < maxCrystalsDrops[difficulty] then
                    -- Do a rng roll to see if we should drop a crystal, 1 in 10 chance.
                    local roll = Wargroove.randomIntegerFromTable({ unit.id, unit.unitClassId, unit.pos.x, unit.pos.y, Wargroove.getTurnNumber(), Wargroove.getCurrentPlayerId(), drops }, 1, 100)
                    if roll <= 10 then
                        print("Crystals dropped in conquest so far: " .. drops)
                        dropCrystalRewards(1, unit)

                        Wargroove.setPlayerCounter("crystalDrops", drops+1)
                    end
                end

                Wargroove.changeMoney(0, unit.unitClass.cost * deathReward * Wargroove.getKillRewardMultiplier())
            end

        end
    end
end

function DefaultDeath:shouldSetMetaLocations()
    return false
end

return DefaultDeath
