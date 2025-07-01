local DefinitionCategory = require "MAF/DefinitionCategory"

local DefinitionDocument = {}
DefinitionDocument.__index = DefinitionDocument
DefinitionDocument.__type = "DefinitionDocument"


function DefinitionDocument:New(id, name, hidden, description)
    local obj = {
        ID = id,
        Name = name,
        Hidden = hidden or {},
        Description = description or "",
        InnerCategory = DefinitionCategory:New(nil, nil)
    }
    setmetatable(obj, self)
    return obj
end

function DefinitionDocument:GetID()
    return self.ID
end

function DefinitionDocument:GetName()
    return self.Name
end

function DefinitionDocument:GetHidden()
    return self.Hidden
end

function DefinitionDocument:GetDescription()
    return self.Description
end

function DefinitionDocument:SetDescription(value)
    self.Description = value
end

function DefinitionDocument:AddCategory(category)
    return self.InnerCategory:AddCategory(category)
end

function DefinitionDocument:AddEntry(entry)
    return self.InnerCategory:AddAddEntryCategory(entry)
end

function DefinitionDocument:AddCategories(categories)
    return self.InnerCategory:AddCategories(categories)
end

function DefinitionDocument:AddEntries(entries)
    return self.InnerCategory:AddEntries(entries)
end

function DefinitionDocument:ForEachCategory(fun, includeSubEntries)
    return self.InnerCategory:ForEachCategory(fun, includeSubEntries)
end

function DefinitionDocument:ForEachEntry(fun, includeSubEntries)
    return self.InnerCategory:ForEachEntry(fun, includeSubEntries)
end

function DefinitionDocument:RemoveCategory(id)
    return self.InnerCategory:RemoveCategory(id)
end

function DefinitionDocument:RemoveEntry(id)
    return self.InnerCategory:RemoveEntry(id)
end

function DefinitionDocument:Traverse(onCategoryHandler, onEntryHandler)
    self.InnerCategory:Traverse(onCategoryHandler, onEntryHandler)
end

function DefinitionDocument.ParseFromJson(jsonData)
    if jsonData == nil then return nil end
    local id = jsonData["id"] or ""
    local name = jsonData["name"] or ""
    local hidden = jsonData["hidden"] or {}
    local description = jsonData["Description"] or ""

    local innerCategory = DefinitionCategory.ParseFromJson(jsonData)
    local instance = DefinitionDocument:New(id, name, hidden, description)
    instance.InnerCategory = innerCategory
    return instance
end

return DefinitionDocument
