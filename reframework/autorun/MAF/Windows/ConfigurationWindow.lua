local SDK = require "MAF/SDK"
local GameStateManager = require "MAF/GameStateManager"
local DefinitionManager = require "MAF/DefinitionManager"
local PresetManager = require "MAF/PresetManager"

local MODULE = {
    IsOpen = false,
    presetSelect = 1
}

function MODULE.OnDrawUI()
    if imgui.button("Modular Armor Framework") then
        MODULE.IsOpen = true
    end
end

function MODULE.OnFrame()
    if not MODULE.IsOpen then return end

    imgui.set_next_window_size(Vector2f.new(620, 512), 1024)
    if imgui.begin_window("Modular Armor##MAF", true) then
        MODULE.QuickToolbar()
        --MODULE.AboutSection()
        --MODULE.HelpSection()
        MODULE.ConfigurationSection()
        --MODULE.PresetSection()

        MODULE.ArmorSettingsSection()
    else
        MODULE.IsOpen = false
    end
    imgui.end_window()
end

function MODULE.HandleSimpleOption(entry)
    local id = entry:GetID()
    if id == nil then return end

    local mesh = entry:GetMesh()
    if mesh == nil then return end

    local name = entry:GetName()
    if name == nil then return end

    local inverted = entry:GetInverted()
    if inverted == nil then inverted = true end

    local default = entry:GetDefault()
    if default == nil then default = not inverted end

    local changed = false
    local value = PresetManager.GetActivePreset():Get(id) or default
    changed, value = imgui.checkbox(name, value)

    if changed then
        PresetManager.GetActivePreset():Set(id, value)
        PresetManager.Apply(GameStateManager.GetPlayerTransforms())
    end
end

function MODULE.HelpSection()
    if imgui.collapsing_header("Help##MAF_ConfigWindow") then
    end
end

function MODULE.AboutSection()
    if imgui.collapsing_header("About##MAF_ConfigWindow") then
    end
end

function MODULE.DrawSimpleCheckboxOption(label, optionName)
    local changed, value = imgui.checkbox(label,
        PresetManager.GetActivePreset():Get(optionName) or false)
    if changed then
        PresetManager.GetActivePreset():Set(optionName, value)
    end
end

function MODULE.ConfigurationSection()
    if imgui.collapsing_header("Player settings##MAF_ConfigWindow") then
        imgui.indent(4)

        MODULE.DrawSimpleCheckboxOption("Hide talisman FX", "PlayerTalismanEffect")

        MODULE.DrawSimpleCheckboxOption("Hide Slinger", "PlayerSlingerVisibility")
        imgui.indent(16)
        MODULE.DrawSimpleCheckboxOption("... except in cutscene##ShowSlingerInCutscene", "PlayerSlingerShowInCutscene")
        MODULE.DrawSimpleCheckboxOption("... except in combat##ShowSlingerInCombat", "PlayerSlingerShowInCombat")
        MODULE.DrawSimpleCheckboxOption("... except when weapon is drawn##ShowSlingerWhenDrawnWeapon",
            "PlayerSlingerShowWhenWeaponDrawn")
        imgui.unindent(16)

        MODULE.DrawSimpleCheckboxOption("Hide Weapon", "PlayerWeaponVisibility")
        imgui.indent(16)
        MODULE.DrawSimpleCheckboxOption("... except in cutscene##ShowWeaponInCutscene", "PlayerWeaponShowInCutscene")
        MODULE.DrawSimpleCheckboxOption("... except in combat##ShowWeaponInCombat", "PlayerWeaponShowInCombat")
        MODULE.DrawSimpleCheckboxOption("... except when drawn##ShowDrawnWeapon", "PlayerWeaponShowWhenDrawn")
        imgui.unindent(16)

        imgui.unindent(4)
    end
end

function MODULE.OnSave()
    PresetManager.SavePreset()
end

function MODULE.OnReset()
    PresetManager.Reset()
    PresetManager.Apply(GameStateManager.GetPlayerTransforms())
end

function MODULE.OnLoad()
    PresetManager.SetActivePreset(PresetManager.LoadPreset("DEFAULT"))
    PresetManager.Apply(GameStateManager.GetPlayerTransforms())
end

function MODULE.PresetSection()
    if imgui.collapsing_header("Presets##MAF_PresetWindow") then
        imgui.indent(4)
        imgui.text("Current preset :")
        imgui.same_line()
        imgui.text(PresetManager.GetActivePreset():GetName())

        if imgui.button("Save current settings") then
            PresetManager.SavePreset()
        end
        imgui.spacing()
        imgui.text("Preset name : ")
        imgui.input_text()
        imgui.same_line()
        if imgui.button("Create") then
        end
        imgui.spacing()


        local list = PresetManager.GetPresetNamesList()
        imgui.text("Preset : ")
        imgui.same_line()
        local changed, value = imgui.combo("", MODULE.presetSelect, list)
        if changed then
            MODULE.presetSelect = value
        end
        if imgui.button("Load") then
            MODULE.OnLoad()
        end
        imgui.same_line()
        if imgui.button("Delete") then end


        imgui.unindent(4)
    end
end

function MODULE.QuickToolbar()
    imgui.spacing()
    imgui.indent(8)
    imgui.text("Current settings :")
    if imgui.button("Save") then MODULE.OnSave() end
    imgui.same_line()
    if imgui.button("Reload") then MODULE.OnLoad() end
    imgui.same_line()
    if imgui.button("Reset") then MODULE.OnReset() end
    imgui.unindent(8)
    imgui.spacing()
end

function MODULE.OnEntryHandler(index, entry)
    MODULE.HandleSimpleOption(entry)
end

function MODULE.OnCategoryHandle(index, category)
    imgui.indent(12)
    if imgui.tree_node(category:GetLabel() .. "##MAF_Category_" .. category:GetID()) then
        category:Traverse(
            function(subcategoryIndex, subcategory) MODULE.OnCategoryHandle(subcategoryIndex, subcategory) end,
            function(entryIndex, entry)
                imgui.indent(12)
                MODULE.OnEntryHandler(entryIndex, entry)
                imgui.unindent(12)
            end
        )

        imgui.tree_pop()
    end
    imgui.unindent(12)
end

function MODULE.OnDocumentHandler(index, definition)
    imgui.indent(12)
    if imgui.collapsing_header(definition:GetName()) then
        definition:Traverse(
            function(categoryIndex, category) MODULE.OnCategoryHandle(categoryIndex, category) end,
            function(entryIndex, entry) MODULE.OnEntryHandler(entryIndex, entry) end
        )
    end
    imgui.unindent(12)
end

function MODULE.ArmorSettingsSection()
    if imgui.collapsing_header("Armor settings##MAF_ConfigWindow") then
        DefinitionManager.Traverse(function(index, definition)
            MODULE.OnDocumentHandler(index, definition)
        end)
    end
end

re.on_draw_ui(function() MODULE.OnDrawUI() end)
re.on_frame(function() MODULE.OnFrame() end)

return MODULE
