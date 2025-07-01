local Preset = {}
Preset.__index = Preset
Preset.__type = "Preset"

function Preset:New(presetName, state)
    local obj = {
        Name = presetName,
        State = state or {}
    }
    setmetatable(obj, self)
    return obj
end

function Preset:GetName()
    return self.Name
end

function Preset:Reset()
    self.State = {}
end

function Preset:GetState()
    return self.State
end

function Preset:Get(key)
    if key == nil then return nil end
    return self.State[key]
end

function Preset:Set(key, value)
    if key == nil then return nil end
    self.State[key] = value
end

function Preset:ToObject()
    return {
        Name = self.Name,
        State = self.State
    }
end

function Preset:FromObject(obj)
    local name = obj["Name"] or nil
    local state = obj["State"] or nil
    if not name or not state then return nil end
    return Preset:New(name, state)
end

return Preset
