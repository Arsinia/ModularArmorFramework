local MODULE = {}

function MODULE.In(t, value)
    for k, v in pairs(t) do
        if v == value then
            return true
        end
    end
    return false
end

function MODULE.LikeAny(t, value)
    for k, v in pairs(t) do
        if string.match(value, v) then
            return true
        end
    end
    return false
end

function MODULE.Extend(t, t2)
    for k, v in pairs(t2) do
        t[k] = v
    end
end

function MODULE.ForEach(t, fun)
    for k, v in pairs(t) do
        fun(k, v)
    end
end

function MODULE.DeepMerge(t1, t2)
    for k, v in pairs(t2) do
        if type(v) == "table" and type(t1[k]) == "table" then
            MODULE.DeepMerge(t1[k], v)
        else
            t1[k] = v
        end
    end
    return t1
end

return MODULE
