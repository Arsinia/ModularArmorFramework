local Preset = require "MAF/Preset"
local SDK = require "MAF/SDK"
local PlayerUtil = require "MAF/PlayerUtil"
local PartUtils = require "MAF/PartUtils"
local Utils = require "MAF/Utils"
local DefinitionManager = require "MAF/DefinitionManager"
local GameStateManager = require "MAF/GameStateManager"

local STATES_ROOT = [[ModularArmorFramework\\States]]
local DEFAULT_PRESET = Preset:New("DEFAULT")

local MODULE = {
    ActivePreset = DEFAULT_PRESET,
    Presets = {},
}

function MODULE.Apply(transforms)
    if transforms == nil then return end
    if not type(transforms) == "table" then
        transforms = { transforms }
    end

    for _, transform in ipairs(transforms) do

        -- Get all part names that we should consider
        local partNames = {}
        local it = transform:get_Child()
        while it ~= nil do
            table.insert(partNames, it:get_GameObject():get_Name())
            it = it:call('get_Next')
        end

        -- Get all definitions with parts that we are considering, all others are irrelevant
        local definitionNames = DefinitionManager.GetDefinitionNamesForPartNames(partNames)

        -- Process entries in each relevant definition
        for _, definitionName in pairs(definitionNames) do

            -- Show all referenced meshes
            DefinitionManager.ForEachEntry(definitionName, function(index, entry)
                if entry ~= nil and entry:GetType() == "simple" then
                    PartUtils.ShowAll(transform, entry:GetMesh())
                end
            end)

            -- Hide all marked initially hidden
            DefinitionManager.ForEachHidden(definitionName, function(hidden)
                local part = Utils.ParseMeshReferenceLine(hidden)
                local mesh = SDK.GetMesh(transform, part["mesh"])

                PartUtils.Hide(mesh, part["group"])
            end)

            -- Set visibility based on selection
            DefinitionManager.ForEachEntry(definitionName, function(index, entry)
                if entry ~= nil and entry:GetType() == "simple" then

                    local inverted = entry:GetInverted()
                    local value = MODULE.GetActivePreset():Get(entry:GetID())
                    if value then
                        PartUtils.ApplyAll(transform, entry:GetMesh(), not inverted)
                    end
                end
            end)
        end
    end
end

function MODULE.CreatePreset(presetName)
    local preset = Preset:New(presetName)
    table.insert(MODULE.Presets, preset)
    return preset
end

function MODULE.SetActivePreset(preset)
    if preset == nil then preset = MODULE.ActivePreset end
    MODULE.ActivePreset = preset

    MODULE.Apply(GameStateManager.GetPlayerTransforms())
end

function MODULE.GetActivePreset()
    return MODULE.ActivePreset
end

function MODULE.SavePreset(preset)
    if preset == nil then preset = MODULE.ActivePreset end
    local filepath = STATES_ROOT .. [[\\]] .. preset.Name .. [[.json]]
    json.dump_file(filepath, preset:ToObject())
end

function MODULE.LoadPreset(presetName)
    local obj = json.load_file(STATES_ROOT .. [[\\]] .. presetName .. [[.json]]) or {}
    local preset = Preset:FromObject(obj)
    table.insert(MODULE.Presets, preset)
    return preset
end

function MODULE.Reset()
    return MODULE.ActivePreset:Reset()
end

function MODULE.ForEach(fun)
    if fun == nil or type(fun) ~= "function" then return end

    for index, value in ipairs(MODULE.Presets) do
        if value ~= nil then
            fun(index, value)
        end
    end
end

function MODULE.GetPresetNamesList()
    local ret = {}
    for _, preset in ipairs(MODULE.Presets) do
        table.insert(ret, preset:GetName())
    end
    return ret
end

function MODULE.GetPresentByIndex(index)
    return MODULE.Presets[index]
end

return MODULE
