local Resumable = {}

local runningCoroutines = {}


function Resumable.run(f)
    local co = coroutine.create(f)
    
    local ok
    local result
    ok, result = coroutine.resume(co)
    if not ok then
        error(result)
    end

    if coroutine.status(co) == "suspended" then
        table.insert(runningCoroutines, co)
        return true
    else
        return false
    end
end


function Resumable.resumeExecution(time)
    -- print("trying to resume thread")
    local lastCoroutine = #runningCoroutines
    coroutine.resume(runningCoroutines[lastCoroutine], time)
    if coroutine.status(runningCoroutines[lastCoroutine]) == "dead" then
        table.remove(runningCoroutines, lastCoroutine)
        return false
    else
        return true
    end
end

return Resumable