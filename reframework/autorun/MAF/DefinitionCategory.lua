local DefinitionEntry = require "MAF/DefinitionEntry"

local DefinitionCategory = {}
DefinitionCategory.__index = DefinitionCategory
DefinitionCategory.__type = "DefinitionCategory"


function DefinitionCategory:New(id, label)
    local obj = {
        ID = id,
        Label = label,
        Categories = {},
        Entries = {}
    }
    setmetatable(obj, self)
    return obj
end

function DefinitionCategory:GetID()
    return self.ID
end

function DefinitionCategory:GetLabel()
    return self.Label
end

function DefinitionCategory:GetCategories()
    return self.Categories
end

function DefinitionCategory:GetEntries()
    return self.Entries
end

function DefinitionCategory:AddCategory(category)
    if category == nil then return end
    table.insert(self.Categories, category)
end

function DefinitionCategory:AddEntry(entry)
    if entry == nil then return end
    table.insert(self.Entries, entry)
end

function DefinitionCategory:AddCategories(categories)
    if categories == nil then return end
    for _, category in ipairs(categories) do
        table.insert(self.Categories, category)
    end
end

function DefinitionCategory:AddEntries(entries)
    if entries == nil then return end
    for _, entry in ipairs(entries) do
        table.insert(self.Entries, entry)
    end
end

function DefinitionCategory:ForEachCategory(fun, includeSubEntries)
    if fun == nil then return end
    if includeSubEntries == nil then return end

    for index, category in ipairs(self.Categories) do
        if category ~= nil then
            fun(index, category)
        end
    end
    if includeSubEntries then
        for _, category in ipairs(self.Categories) do
            category:ForEachCategory(fun, includeSubEntries)
        end
    end
end

function DefinitionCategory:ForEachEntry(fun, includeSubEntries)
    if fun == nil then return end
    if includeSubEntries == nil then return end

    if self.Entries ~= nil then
        for index, entry in ipairs(self.Entries) do
            if entry ~= nil then
                fun(index, entry)
            end
        end
    end

    if includeSubEntries then
        if self.Categories ~= nil then
            for categoryIndex, category in ipairs(self.Categories) do
                category:ForEachEntry(fun, includeSubEntries)
            end
        end
    end
end

function DefinitionCategory:RemoveCategory(id)
    self:ForEachCategory(function(index, category)
        if category:GetID() == id then table.remove(self.Categories, index) end
    end)
end

function DefinitionCategory:RemoveEntry(id)
    self:ForEachEntry(function(index, entry)
        if entry ~= nil and entry:GetID() == id then
            table.remove(self.Entries, index)
        end
    end)
end

function DefinitionCategory:Traverse(onCategoryHandler, onEntryHandler)
    if onCategoryHandler == nil and onEntryHandler == nil then return end
    if self.Categories ~= nil then
        for categoryIndex, category in ipairs(self.Categories) do
            if category ~= nil and onCategoryHandler ~= nil then
                onCategoryHandler(categoryIndex, category)
            end
        end
    end

    if self.Entries ~= nil then
        for entryIndex, entry in ipairs(self.Entries) do
            if entry ~= nil and onEntryHandler ~= nil then
                onEntryHandler(entryIndex, entry)
            end
        end
    end
end

function DefinitionCategory.ParseFromJson(jsonData)
    if jsonData == nil then return nil end
    local id = jsonData["id"] or ""
    local label = jsonData["label"] or ""

    local instance = DefinitionCategory:New(id, label)

    if jsonData["categories"] ~= nil then
        local categories = {}
        for _, category in ipairs(jsonData["categories"]) do
            local parsedCategory = DefinitionCategory.ParseFromJson(category)
            table.insert(categories, parsedCategory)
        end
        instance.Categories = categories
    end

    if jsonData["entries"] ~= nil then
        local entries = {}
        for _, entry in ipairs(jsonData["entries"]) do
            local newEntry = DefinitionEntry:New(entry["id"], entry["name"], entry["mesh"], entry["type"],
                entry["description"])
            table.insert(entries, newEntry)
        end
        instance.Entries = entries
    end

    return instance
end

return DefinitionCategory
