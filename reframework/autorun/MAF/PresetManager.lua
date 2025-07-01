local Preset = require "MAF/Preset"
local SDK = require "MAF/SDK"
local PlayerUtil = require "MAF/PlayerUtil"
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
        local it = transform:get_Child()
        while it ~= nil do
            local partName = it:get_GameObject():get_Name()
            if string.match(partName, "^ch0[23457]_%d%d%d_%d%d%d%d$") then
                DefinitionManager.ForEachPartEntry(partName, function(entry_id, entry)
                    -- For each mesh/part of the entry
                    for _, meshReference in ipairs(entry:GetMesh()) do
                        local meshData = Utils.ParseMeshReference(meshReference)
                        if meshData then
                            local mesh = SDK.GetMesh(transform, meshData.mesh)
                            if mesh then
                                --mesh:setPartsEnable(meshData.group, true)

                                -- Show mesh by default, hide it if it's a hidden mesh
                                local isHidden = DefinitionManager.IsHidden(meshData.name)
                                mesh:setPartsEnable(meshData.group, not isHidden)

                                -- If entry is activated, hide the mesh (show the mesh if mesh is inverted)
                                local entry_enabled = MODULE.ActivePreset:Get(entry_id) or false
                                if entry_enabled then
                                    mesh:setPartsEnable(meshData.group, meshData.inverted)
                                end
                            end
                        end
                    end
                end)
            end
            it = it:call('get_Next')
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
