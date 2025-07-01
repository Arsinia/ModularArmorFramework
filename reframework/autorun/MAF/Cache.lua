local MODULE = {
    _data = {}
}

function MODULE.Reset()
    MODULE._data = {}
end

function MODULE.Get(key)
    if key == nil then return nil end
    return MODULE._data[key]
end

function MODULE.GetOrElse(key, fun, bypassCache, lastChance)
    local resource = nil
    if bypassCache ~= true then
        resource = MODULE._data[key]
        if resource ~= nil then
            return resource
        else
            if lastChance ~= true then
                return MODULE.GetOrElse(key, fun, true, true)
            end
        end
    end

    if fun == nil then return nil end
    resource = fun()

    if resource ~= nil then
        MODULE.Set(key, resource)
    end

    return resource
end

function MODULE.Set(key, value)
    if key == nil then return nil end
    MODULE._data[key] = value
end

function MODULE.Delete(key)
    if MODULE._data[key] == nil then return end
    MODULE.Set(key, nil)
end

setmetatable(MODULE, {
    __index = function(t, key)
        return MODULE.Get(key)
    end,
    __newindex = function(t, key, value)
        MODULE.Set(key, value)
    end
})

return MODULE
