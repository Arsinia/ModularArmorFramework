local DefinitionDocument = require("MAF/DefinitionDocument")

local Log = require "MAF/Log"
local Utils = require "MAF/Utils"

local DEFINITION_PATH = [[ModularArmorFramework\\Definitions]]

local MODULE = {
    Definitions = {},

    -- gameobject name to set of relevant definition file names
    PartNameToDefinitionName = {},

    -- ordered list of definition file names
    OrderedDefinitionNames = {},
    Count = 0,
}

function MODULE.GetDefinitions()
    return MODULE.Definitions
end

function MODULE.GetDefinitionNamesForPartNames(partNames)
    local definitionNamesSet = {}
    for _, partName in ipairs(partNames) do
        if MODULE.PartNameToDefinitionNames[partName] then
            for definitionName, _ in pairs(MODULE.PartNameToDefinitionNames[partName]) do
                definitionNamesSet[definitionName] = true
            end
        end
    end
    local definitionNamesList = {}
    for key, _ in pairs(definitionNamesSet) do
        table.insert(definitionNamesList, key)
    end
    return definitionNamesList
end

function MODULE.GetDefinitionNamesForPartName(partName)
    local definitionNamesSet = MODULE.PartNameToDefinitionNames[partName]
    if not definitionNamesSet then return {} end

    local definitionNamesList = {}
    for key, _ in pairs(definitionNamesSet) do
        table.insert(definitionNamesList, key)
    end

    return definitionNamesList
end

function MODULE.ForEachEntry(definitionName, fun)
    if MODULE.Definitions[definitionName] then
        MODULE.Definitions[definitionName]:ForEachEntry(fun, true)
    end
end

function MODULE.ForEachHidden(definitionName, fun)
    if MODULE.Definitions[definitionName] then
        local hidden = MODULE.Definitions[definitionName]:GetHidden()
        if hidden ~= nil then
            for _, h in pairs(hidden) do
                if h ~= nil then
                    fun(h)
                end
            end
        end
    end
end


function MODULE.Traverse(onDocumentHandler)
    for definitionIndex, definitionName in pairs(MODULE.OrderedDefinitionNames) do
        local definition = MODULE.Definitions[definitionName]
        if definition ~= nil and onDocumentHandler ~= nil then
            onDocumentHandler(definitionIndex, definition)
        end
    end
end

function MODULE.LoadDefinitions()
    Log.Info("Loading definitions...")
    local files = fs.glob(DEFINITION_PATH .. [[\\.*json]])

    MODULE.Count = #files
    Log.Info("\t" .. #files .. " definition(s) found:")

    MODULE.Definitions = {}
    MODULE.PartNameToDefinitionNames = {}
    MODULE.OrderedDefinitionNames = {}

    for _, file in ipairs(files) do
        Log.Info("\t\t" .. file)
        local jsonData = json.load_file(file)
        MODULE.Definitions[file] = DefinitionDocument.ParseFromJson(jsonData)
        table.insert(MODULE.OrderedDefinitionNames, file)

        MODULE.Definitions[file]:ForEachEntry(function(index, entry)
            if entry ~= nil and entry:GetType() == "simple" then
                local meshes = Utils.ParseMeshReference(entry:GetMesh())

                for _, v in ipairs(meshes) do
                    -- v["mesh"] = gameobject name (ex. ch03_001_0002)

                    -- MODULE.PartNameToDefinitionNames = gameobject name to set of relevant definition file names
                    if not MODULE.PartNameToDefinitionNames[v["mesh"]] then
                        MODULE.PartNameToDefinitionNames[v["mesh"]] = {}
                    end
                    MODULE.PartNameToDefinitionNames[v["mesh"]][file] = true
                end
            end
        end, true)
    end
end

return MODULE
