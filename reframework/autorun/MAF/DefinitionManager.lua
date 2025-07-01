local DefinitionDocument = require("MAF/DefinitionDocument")

local Log = require "MAF/Log"
local Table = require "MAF/Table"
local Cache = require "MAF/Cache"

local DEFINITION_PATH = [[ModularArmorFramework\\Definitions]]

local MODULE = {
    Definitions = {},
    PartIndex = nil,
    EntryIndex = nil,
    HiddenIndex = nil,
    Count = 0,
}

function MODULE.GetDefinitions()
    return MODULE.Definitions
end

function MODULE.ForEachDefinition(fun)
    if fun == nil then return end
    for index, definition in ipairs(MODULE.Definitions) do
        fun(index, definition)
    end
end

function MODULE.ForEachEntry(fun)
    if fun == nil then return end
    for _, definition in ipairs(MODULE.Definitions) do
        definition:ForEachEntry(fun, true)
    end
end

function MODULE.ForEachHidden(fun)
    if fun == nil then return end
    for _, definition in ipairs(MODULE.Definitions) do
        local hidden = definition:GetHidden()
        if hidden ~= nil then
            for _, h in ipairs(hidden) do
                if h ~= nil then
                    fun(h)
                end
            end
        end
    end
end

function MODULE.Traverse(onDocumentHandler)
    if onDocumentHandler == nil then return end
    if MODULE.Definitions == nil then return end

    for definitionIndex, definition in ipairs(MODULE.Definitions) do
        if definition ~= nil then
            onDocumentHandler(definitionIndex, definition)
        end
    end
end

function MODULE.ForEachPartEntry(partName, fun)
    if partName == nil or type(partName) ~= "string" then return nil end
    if fun == nil then return end

    local partIndex = MODULE.PartIndex[partName]
    if partIndex == nil then return end

    for _, entry_id in ipairs(partIndex) do
        fun(entry_id, MODULE.EntryIndex[entry_id])
    end
end

function MODULE.BuildIndexes()
    local entryIndex = {}
    local partIndex = {}

    MODULE.ForEachEntry(function(_, entry)
        entryIndex[entry:GetID()] = entry

        for _, mesh in ipairs(entry:GetMesh()) do
            local mesh_base = mesh:match("!?([^/]+)")

            if not partIndex[mesh_base] then
                partIndex[mesh_base] = {}
            end

            table.insert(partIndex[mesh_base], entry:GetID())
        end
    end)

    MODULE.EntryIndex = entryIndex
    MODULE.PartIndex = partIndex
end

function MODULE.IsHidden(partName)
    if partName == nil or type(partName) ~= "string" then return nil end
    for _, v in ipairs(MODULE.HiddenIndex) do
        if v == partName then
            return true
        end
    end
    return false
end

function MODULE.GetPartEntries(partName)
    if partName == nil or type(partName) ~= "string" then return nil end
    return Cache.GetOrElse(partName .. "[entries]", function()
        local result = {}
        for _, entryId in ipairs(MODULE.PartIndex[partName]) do
            Table.Extend(result, MODULE.EntryIndex[entryId])
        end
        return result
    end)
end

function MODULE.LoadDefinitions()
    Log.Info("Loading definitions...")
    local files = fs.glob(DEFINITION_PATH .. [[\\.*json]])

    MODULE.Count = #files
    Log.Info("\t" .. #files .. " definition(s) found:")

    local result = {}
    local hiddenIndex = {}
    for _, file in ipairs(files) do
        Log.Info("\t\t" .. file)
        local jsonData = json.load_file(file)

        for _, val in ipairs(jsonData["hidden"]) do
            table.insert(hiddenIndex, val)
        end

        table.insert(result, DefinitionDocument.ParseFromJson(jsonData))
    end
    MODULE.Definitions = result
    MODULE.HiddenIndex = hiddenIndex
    MODULE.BuildIndexes()
end

return MODULE
