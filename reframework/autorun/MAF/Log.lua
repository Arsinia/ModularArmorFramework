local MODULE = {
    _debugMode = false,
    _debugEvents = false
}

function GetHeader()
    return "[MAF][" .. os.date('%H:%M:%S', os.time()) .. "]"
end

function MODULE.Debug(message)
    if not MODULE._debugMode then return end
    print(GetHeader() .. "[DBUG] " .. message)
end

function MODULE.Info(message)
    print(GetHeader() .. "[INFO] " .. message)
end

function MODULE.Warning(message)
    print(GetHeader() .. "[WARN] " .. message)
end

function MODULE.Event(type, name)
    if MODULE._debugEvents then
        print(GetHeader() .. "[EVNT] " .. type .. " # " .. name)
    end
end

function MODULE.Error(message)
    print(GetHeader() .. "[ERRO] " .. message)
end

function MODULE.ToggleDebugMode()
    MODULE._debugMode = not MODULE._debugMode
end

function MODULE.ToggleDebugEventsMode()
    MODULE._debugEvents = not MODULE._debugEvents
end

function MODULE.IsDebug()
    return MODULE._debugMode
end

function MODULE.IsDebugEvents()
    return MODULE._debugEvents
end

function MODULE.LogTable(obj, indent)
    indent = indent or 0

    for k, v in pairs(obj) do
        local padding = string.rep("  ", indent)
        if type(v) == "table" then
            print(padding .. k .. "(table): ")
            MODULE.LogTable(v, indent + 1)
        else
            print(padding .. k .. "(" .. type(k) .. "): " .. tostring(v))
        end
    end
end

function MODULE.DebugTransform(transform, indent)
    indent = indent or 0
    local it = transform
    print(indent)
    repeat
        local go = it:get_GameObject()
        local mesh = go:call("getComponent(System.Type)", sdk.typeof("via.render.Mesh"))
        if mesh == nil then mesh = "" else mesh = mesh:ToString() end
        if go:get_Name():match("^%s*(.-)%s*$") ~= "Sound"
        and  go:get_Name():match("^%s*(.-)%s*$") ~=  "GameObject" 
        and  go:get_Name():match("^%s*(.-)%s*$") ~=  "Decal"
        then
            MODULE.Info(
                string.rep("  ", indent)
                .. go:get_Name():match("^%s*(.-)%s*$")
                .. " - " .. it:get_type_definition():get_full_name():match("^%s*(.-)%s*$")
                .. " - " .. mesh)
        end
        local sub = it:call("get_Child")
        --if sub ~= nil then
        --    MODULE.DebugTransform(sub, indent + 1)
        --end
        it = it:call("get_Next")
    until not it
end


return MODULE
