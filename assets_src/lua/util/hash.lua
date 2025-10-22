local hash = {}

function hash.sortedTableToString(o)
    if type(o) == 'table' then
        local indexedTable = {}
        for k,v in pairs(o) do
            table.insert(indexedTable,{key = k, value = v})
        end
        table.sort(indexedTable, function(a, b)
            return a.key < b.key -- or > depending on desired sort order
        end)
        local s = '{ '
        for k,v in ipairs(indexedTable) do
            local key = v.key
            local value = v.value
            if type(key) ~= 'number' then key = '"'..key..'"' end
            s = s .. '['..key..'] = ' .. hash.sortedTableToString(value) .. ','
        end
        return s .. '} '
    else
        return tostring(o)
    end
end

function hash.hash(str)
    local h = 5381;

    for c in str:gmatch"." do
        h = math.fmod(((h << 5) + h) + string.byte(c), 2147483648)
    end
    return h
end

return hash