local DefinitionEntry = {}
DefinitionEntry.__index = DefinitionEntry
DefinitionEntry.__type = "DefinitionEntry"


function DefinitionEntry:New(id, name, mesh, type, description, default, inverted)
    local obj = {
        ID = id,
        Name = name,
        Description = description or "",
        Mesh = mesh,
        Type = type or "simple",
        Default = default or false,
        Inverted = inverted or true
    }
    setmetatable(obj, self)
    return obj
end

function DefinitionEntry:GetID()
    return self.ID
end

function DefinitionEntry:GetName()
    return self.Name
end

function DefinitionEntry:GetMesh()
    return self.Mesh
end

function DefinitionEntry:GetDescription()
    return self.Description
end

function DefinitionEntry:SetDescription(value)
    self.Description = value
end

function DefinitionEntry:GetInverted()
    return self.Inverted
end

function DefinitionEntry:GetDefault()
    return self.Default
end

function DefinitionEntry:GetType()
    return self.Type
end
return DefinitionEntry
