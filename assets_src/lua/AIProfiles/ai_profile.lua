local Wargroove = require "wargroove/wargroove"


local AIProfile = {}

local AIProfileObject = nil


function AIProfile.init()
    -- print("AIProfile.init()")
    -- for playerId = 0,Wargroove.getNumPlayers(false) do
    --     local profile = AIProfile.getProfileState(playerId)
    --     if profile ~= nil then
    --         AIProfile.setProfile(playerId, profile)
    --     end
    -- end
end

function AIProfile.setProfile(playerId, profile)
    if profile == "mangrove_madness" then
        local AIProfile = require "AIProfiles/mangroveMadness"
        AIProfile.setProfile()
    end
    if profile == "city_passive" then
        local AIProfile = require "AIProfiles/cityPassive"
        AIProfile.setProfile()
    end
    if profile == "city_war" then
        local AIProfile = require "AIProfiles/cityWar"
        AIProfile.setProfile()
    end
    if profile == "rival_pirate" then
        local AIProfile = require "AIProfiles/rivalPirate"
        AIProfile.setProfile()
    end
    AIProfile.setProfileState(playerId, profile)
    Wargroove.setAIProfile(playerId, profile)
end


function AIProfile.checkForProfile(playerId)
    local profile = AIProfile.getProfileState(playerId)
    if profile ~= nil then
        AIProfile.setProfile(playerId, profile)
    end
end

function AIProfile.getAIProfileObject()
	if AIProfileObject == nil then
        for i,unit in pairs(Wargroove.getUnitsAtLocation()) do
            if unit.unitClassId == "ai_profile" then
                AIProfileObject = unit
                return AIProfileObject
            end
        end
        local id = Wargroove.spawnUnit(-1, {x=-50,y=-50}, "ai_profile", false)
        AIProfileObject = Wargroove.getUnitById(id)
        return AIProfileObject
    else
        return AIProfileObject
    end
end

function AIProfile.setProfileState(playerId, profile)
    local AIProfileObject = AIProfile.getAIProfileObject()
    Wargroove.setUnitState(AIProfileObject,"profile"..tostring(playerId),profile)
    Wargroove.updateUnit(AIProfileObject)
end

function AIProfile.getProfileState(playerId)
    local AIProfileObject = AIProfile.getAIProfileObject()
    local profile = Wargroove.getUnitState(AIProfileObject,"profile"..tostring(playerId))
    if profile == nil then
        return nil
    else
        return profile
    end
end

function AIProfile.setCanAttackBuildings(playerId, canAttack)
    local AIProfileObject = AIProfile.getAIProfileObject()
    if canAttack then
        Wargroove.setUnitState(AIProfileObject,"canAttackBuildings"..tostring(playerId),"true")
    else
        Wargroove.setUnitState(AIProfileObject,"canAttackBuildings"..tostring(playerId),"false")
    end
    Wargroove.updateUnit(AIProfileObject)
end


function AIProfile.canAttackBuildings(playerId)
    local AIProfileObject = AIProfile.getAIProfileObject()
    local canAttack = Wargroove.getUnitState(AIProfileObject,"canAttackBuildings"..tostring(playerId))
    if canAttack == nil then
        return true
    else
        return canAttack == "true"
    end
end
return AIProfile
