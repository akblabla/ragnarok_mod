local Wargroove = require "wargroove/wargroove"
local ItemVerb = require "wargroove/item_verb"
local Combat = require "wargroove/combat"

local ItemStaffOfThorns = ItemVerb:new()


function ItemStaffOfThorns:getMaximumRange(unit, endPos)
    return 3
end

function ItemStaffOfThorns:getTargetType()
  return "all"
end

function ItemStaffOfThorns:canExecuteWithTarget(unit, endPos, targetPos, strParam)
    if not self:canSeeTarget(targetPos) then
        return false
    end

    -- Ignore endPos as target
    if(targetPos.x == endPos.x and targetPos.y == endPos.y) then
        return false
    end

    -- Only return valid if it's either horizontal or vertical
    if(targetPos.x == endPos.x or targetPos.y == endPos.y) then
        return true
    end

    return false
end

function ItemStaffOfThorns:buildTargetsString(targets)
    local result = ""
    for i, target in ipairs(targets) do
        result = result .. target.x .. "," .. target.y
        if i ~= #targets then
            result = result .. ";"
        end
    end
    return result
end

function ItemStaffOfThorns:buildTargetsFromEndTarget(unitPos, targetPos)
    local xChange = math.abs(targetPos.x - unitPos.x)
    local yChange = math.abs(targetPos.y - unitPos.y)
    local positions = {}

    if xChange ~= 0 then
        local dir = 1;
        if(targetPos.x < unitPos.x) then
            dir = -1;
        end

        for i=1,xChange do
            positions[#positions+1] = {x = unitPos.x + (i * dir), y = unitPos.y}
        end
    end

    if yChange ~= 0 then
        local dir = 1;
        if(targetPos.y < unitPos.y) then
            dir = -1;
        end

        for i=1,yChange do
            positions[#positions+1] = {x = unitPos.x, y = unitPos.y + (i * dir)}
        end
    end

    return positions
end

function ItemStaffOfThorns:preExecute(unit, targetPos, strParam, endPos)
    Wargroove.selectTarget()

    while Wargroove.waitingForSelectedTarget() do
        coroutine.yield()
    end

    local target = Wargroove.getSelectedTarget()
    if(target == nil) then
        return false, ""
    end

    local targets = self:buildTargetsFromEndTarget(endPos, target)
    
    return true, self:buildTargetsString(targets);
end

function ItemStaffOfThorns:getFacing(unit, target)
    if (unit.pos.x < target.x) then
        return "right"
    elseif (unit.pos.x > target.x) then
        return "left"
    else
        return ""
    end
end

function ItemStaffOfThorns:execute(unit, targetPos, strParam, path)
    local targets = self:parseTargets(strParam)

    Wargroove.playPositionlessSound("battleStart")

    local startFacing = self:getFacing(unit, targets[1])
    if (startFacing ~= "") then
        Wargroove.setFacingOverride(unit.id, startFacing)
    end

    Wargroove.playUnitAnimation(unit.id, "groove")
    Wargroove.waitTime(1.5)
    
    local damageNerf = 0.5

    for i, target in ipairs(targets) do
        Wargroove.spawnMapAnimation(target, 0, "fx/items/thorns", "spawn", "over_units", {x = 6, y = -15})
        Wargroove.waitTime(0.5)

        local u = Wargroove.getUnitAt(target)

        if u then
            print("Unit: " .. u.id)
            
            -- This needs proper thought re: damage resolution, currently a hack
            local baseDamage = Wargroove.getWeaponDamageForceGround("staff_of_thorns_weapon", u)
            local damage = Combat:solveDamage(baseDamage, 1, 1, 0, 0, 1.0, 1.0) * damageNerf
            
            print("Damage: " .. damage)

            u:setHealth(u.health - damage, unit.id)
            Wargroove.updateUnit(u)
            Wargroove.playUnitAnimation(u.id, "hit")
        end

        print("Loop: " .. i)

        Wargroove.waitTime(0.2)
        
        -- Decrease damage with each target
        damageNerf = damageNerf * 0.7
    end

    Wargroove.waitTime(0.5)
end

return ItemStaffOfThorns