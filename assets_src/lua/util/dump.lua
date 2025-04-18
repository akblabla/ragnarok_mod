local function dump(o,level)
    if level==nil then
        level = 0
    end
    if type(o) == 'table' then
        local s = '\n' .. string.rep("   ", level) .. '{\n'
        for k,v in pairs(o) do
            if type(k) ~= 'number' then k = '"'..k..'"' end
            s = s .. string.rep("   ", level+1) .. '['..k..'] = ' .. dump(v,level+1) .. ',\n'
        end
        return s .. string.rep("   ", level) .. '}'
    else
        return tostring(o)
    end
end
return dump

