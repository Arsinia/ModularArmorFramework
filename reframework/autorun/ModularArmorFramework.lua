local Const               = require "MAF/Const"
local Cache               = require "MAF/Cache"
local SDK                 = require "MAF/SDK"
local Log                 = require "MAF/Log"
local Utils               = require "MAF/Utils"
local DefinitionManager   = require "MAF/DefinitionManager"
local ConfigurationWindow = require "MAF/Windows/ConfigurationWindow"
local PresetManager       = require "MAF/PresetManager"
local Table               = require("MAF/Table")
local GameStateManager    = require("MAF/GameStateManager")

--Log.ToggleDebugMode()
--Log.ToggleDebugEventsMode()
if not Utils.RunningMonsterHunterWilds() then return end

local modEnabled = true

DefinitionManager.LoadDefinitions()
PresetManager.SetActivePreset(PresetManager.LoadPreset("DEFAULT"))

local function HandleSlingerVisibility(playerObject, isInCombat, isWeaponDrawn, isInCutscene)
    local playerSlingerVisibilityKey = "PlayerSlingerVisibility"
    if PresetManager.GetActivePreset():Get(playerSlingerVisibilityKey) ~= nil then
        local slinger = Cache.GetOrElse(playerSlingerVisibilityKey, function()
            local slingerObject = nil
            pcall(function() slingerObject = playerObject:get_Slinger():get_GameObject() end)
            return slingerObject
        end)

        if slinger then
            local forceShow = (isInCutscene == true and PresetManager.GetActivePreset():Get("PlayerSlingerShowInCutscene")) or
                (isInCombat == true and PresetManager.GetActivePreset():Get("PlayerSlingerShowInCombat"))
                or (isWeaponDrawn == true and PresetManager.GetActivePreset():Get("PlayerSlingerShowWhenWeaponDrawn"))

            if not forceShow and PresetManager.GetActivePreset():Get(playerSlingerVisibilityKey) == true then
                slinger:set_DrawSelf(false)
            else
                slinger:set_DrawSelf(true)
                if not forceShow then
                    PresetManager.GetActivePreset():Set(playerSlingerVisibilityKey, nil)
                end
            end
        end
    end
end

local function HandleWeaponVisibility(playerObject, isInCombat, isWeaponDrawn, isInCutscene)
    local optionName = "PlayerWeaponVisibility"
    if PresetManager.GetActivePreset():Get(optionName) ~= nil then
        local weapon = Cache.GetOrElse(optionName, function()
            local weaponPart = {}
            local parts = { "Wp_Parent", "WpSub_Parent", "Wp_ReserveParent", "WpSub_ReserveParent" }
            local count = 0
            for _, part in ipairs(parts) do
                local obj = nil
                pcall(function() obj = playerObject:find(part):get_GameObject() end)
                if obj then
                    table.insert(weaponPart, obj)
                    count = count + 1
                end
            end
            if count == 0 then return nil else return weaponPart end
        end)

        if weapon then
            local forceShow = (isInCutscene == true and PresetManager.GetActivePreset():Get("PlayerWeaponShowInCutscene")) or
                (isInCombat == true and PresetManager.GetActivePreset():Get("PlayerWeaponShowInCombat"))
                or (isWeaponDrawn == true and PresetManager.GetActivePreset():Get("PlayerWeaponShowWhenDrawn"))

            if not forceShow and PresetManager.GetActivePreset():Get(optionName) == true then
                for _, it in ipairs(weapon) do
                    if it ~= nil then
                        it:set_DrawSelf(false)
                    end
                end
            else
                for _, it in ipairs(weapon) do
                    if it ~= nil then
                        it:set_DrawSelf(true)
                    end
                end
                if not forceShow then
                    PresetManager.GetActivePreset():Set(optionName, nil)
                end
            end
        end
    end
end

local function HandleTalismanFXVisibility(playerObject)
    local optionName = "PlayerTalismanEffect"
    if PresetManager.GetActivePreset():Get(optionName) ~= nil then
        local talisman = SDK.GetPlayerBody():find("no_name_effect")
        if talisman == nil then return end

        talisman = talisman:get_GameObject() or nil
        if talisman ~= nil then
            talisman:set_DrawSelf(not PresetManager.GetActivePreset():Get(optionName))
            if not PresetManager.GetActivePreset():Get(optionName) then
                PresetManager.GetActivePreset():Set(optionName, nil)
            end
        end
    end
end

local function PlayerChangeEquipHandler()
    if not modEnabled then return end
    if GameStateManager.IsOnTitleScreen() or GameStateManager.IsUnknown() then return end
    PresetManager.Apply(GameStateManager.GetPlayerTransforms())
end

local processing = false
re.on_frame(function()
    if not modEnabled then return end
    if processing then return end
    if not GameStateManager.IsIngame() and not GameStateManager.IsInCutscene() and not GameStateManager.IsOnTitleScreen() then return end
    processing = true
    local transforms = nil

    if GameStateManager.IsOnTitleScreen() then
        PresetManager.Apply(GameStateManager.GetPlayerTransforms())
    end

    local function errorHandler()
        GameStateManager.SetState("Unknown")
        Cache.Reset()
    end

    transforms = SDK.GetPlayerBody()
    if not transforms then
        processing = false
        return
    end

    local success = false
    local isWeaponDrawn = false
    local isInCombat = false

    success, _ = xpcall(function() isWeaponDrawn = SDK.GetPlayerInfo():get_IsWeaponOn() end, errorHandler)
    if not success then
        processing = false
        return
    end

    success, _ = xpcall(function() isInCombat = SDK.GetPlayerInfo():get_IsCombat() end, errorHandler)
    if not success then
        processing = false
        return
    end

    HandleTalismanFXVisibility(transforms)
    HandleSlingerVisibility(transforms, isInCombat, isWeaponDrawn, GameStateManager.IsInCutscene())
    HandleWeaponVisibility(transforms, isInCombat, isWeaponDrawn, GameStateManager.IsInCutscene())

    processing = false
end)


GameStateManager.OnPlayerChangeEquip(PlayerChangeEquipHandler)
PlayerChangeEquipHandler()

-- Debug feature : print all transforms in current scene
-- local function LogCurrentSceneTransforms(scene)
--     local list = SDK.FindAllInScene(scene)
--     if not list then return end

--     local filter = {
--         "GameObject",
--         "Dummy",
--         "^11_",
--         "^Sm_",
--         "^GIPC_",
--         ".*Dialogue.*",
--         ".*Concert.*",
--         ".*Grid.*",
--         ".*Shadow.*",
--         "Rope.*",
--         "Net",
--         "Bottle",
--         "Belt",
--         "Ms.*",
--         ".*Collider.*",
--         ".*AirShip.*",
--         "Tip",
--         "fire",
--         ".*Rescue.*",
--         "HeadToHip",
--         "Emit.*",
--         "^sm%d%d_.*",
--         "^Gm%d%d%d_.*",
--         "^Session.*",
--         "Lamm",
--         "GUI",
--         ".*Decal.*",
--         ".*decal.*",
--         ".*Local.*",
--         ".*Rain.*",
--         ".*rain.*",
--         ".*Reverb.*",
--         ".*village.*",
--         ".*Operation.*",
--         ".*Layout.*",
--         ".*Dev.*",
--         "^Event_.*",
--         "^st%d%d%d",
--         "^evc_.*",
--         "TimeLine",
--         "no_name_effect",
--         "UniversalPositionRoot",
--         ".*Stage.*",
--         "^CommonSky.*",
--         "^Cloudscape.*",
--         "MainMoon",
--         "^MainLayer.*",
--         "Sound",
--         "Light",
--         "VFX",
--         "Effect",
--         "Fog",
--         ".*Foliage.*",
--         "Npc.*",
--         "NPC.*",
--         "Facilities",
--         "Tent_Obj",
--         "Title_Tent",
--         "^EventFsmController_",
--         ".*Point.*",
--         ".*Route.*",
--         ".*Path.*",
--         ".*Ground.*",
--         ".*Collection.*",
--         "EnvBase",
--         "BGM",
--         ".*System",
--         "^Fade.*",
--         "DebugWindowDipSynchronizer",
--         "DevCreator",
--         "Creator",
--         "ExtraContentsCollector",
--         "Data",
--         "CatalogActivator",
--         "FluidSimulator",
--         "StandAlone",
--         "Accessory",
--         "DualHeightFieldTrail",
--         ".*BAB$",
--         "GlobalMaterialParam",
--         "BurningMap",
--         ".*epve_.*",
--         ".*evpe_.*",
--         ".*epvs_.*",
--         ".*epvr_.*",
--         ".*evc_.*",
--         "^evc.*",
--         ".*evm_.*",
--         ".*evm.*",
--         ".*Catalog.*",
--         ".*Control.*",
--         "Acc%d%d%d_.*",
--         "^Rein_",
--         "^Saddle_",
--         "^WeaponBag_",
--         "^CLSP_",
--         "SndEnvBase",
--         "SStoCopyRight",
--         "SStoThumbnail",
--         "Album",
--         "NavSafePos",
--         ".*System",
--         ".*Manager",
--         "DelayJob",
--         ".*Dacal.*",
--         "^MS_",
--         "suna1",
--         "Wind",
--         "Voxel",
--         "^CC.*",
--         ".*Story.*",
--         ".*Relief.*",
--         "^Sh%d%d%d_",
--         "^SND_",
--         ".*Weather.*",
--         ".%House.*",
--         ".*Enemy.*",
--         ".*Animal.*",
--         "EnvBABUpdater",
--         "CreateBurntRTT",
--         "Graphics",
--         "AnalysisLog",
--         ".*Network.*",
--         "SendException",
--         "BenchMarkDataSender",
--         "^Net_",
--         ".*Service",
--         "WebSocket",
--         "MatchMake",
--         "STM",
--         "BG",
--         "Default",
--         "atmos",
--         "^Basic00_",
--         "^Wall_",
--         "^Chimney_",
--         ".*_desert_.*",
--         ".*_night_.*",
--         ".*_tent_.*",
--         ".*_default_.*",
--         ".*Obstacle.*",
--         "PT00_00_000_00",
--         ".*_leg_.*",
--         "Night",
--         "Desert",
--         "^a%d%d",
--         "XB1",
--         "PSN",
--         ".*Context",
--         "SingletonObject",
--         "EPVRoot",
--         "AppInitializer",
--         "GAObject",
--         "Listener_Position",
--         ".*Camera.*",
--         ".*Controller",
--         ".*Activator"
--     }

--     for _, transform in ipairs(list) do
--         pcall(function()
--             local go = transform:get_GameObject()
--             local name = go:get_Name()
--             if not Table.LikeAny(filter, name) then
--                 print(name)
--             end
--         end)
--     end
--     return nil
-- end

-- local debug_key = 0x48 -- H
-- local key_state = {
--     [debug_key] = false
-- }
-- re.on_frame(function()
--     if reframework:is_key_down(debug_key) then
--         if not key_state[debug_key] then
--             key_state[debug_key] = true
--             LogCurrentSceneTransforms(SDK.GetCurrentScene())
--         end
--     else
--         key_state[debug_key] = false
--     end
-- end)




----------------------------------------------------------------------------
-- Following code cause memory leaks !
-------------------------------------------------------------------------------
-- local function create_resource(resource_path, resource_type)
--     resource_path = resource_path:lower()
--     resource_path = resource_path:match("^.+%[@?(.+)%]") or resource_path
--     local ext = resource_path:match("^.+%.(.+)$")

--     resource_type = (resource_type.get_full_name and resource_type:get_full_name() or resource_type):gsub("Holder", "")

--     local new_resource = sdk.create_resource(resource_type, resource_path)
--     new_resource = new_resource and new_resource:add_ref()
--     if not new_resource then return end

--     local new_rs_address = new_resource and new_resource:get_address()
--     if type(new_rs_address) == "number" then
--         local holder = sdk.create_instance(resource_type .. "Holder", true)
--         if holder then
--             holder = holder:add_ref()
--             holder:call(".ctor()")
--             holder:write_qword(0x10, new_rs_address)
--             return holder
--         end
--     end
-- end

-- local newMeshName = "ch03_014_0012"



-- pu:Update()

-- local function ResetAppareance()
--     pu:ForEachBodyPart(function(bodyPart)
--         local meshName = bodyPart:get_Name()
--         print(meshName)
--         local bodyMesh = SDK.GetComponent(bodyPart, "via.render.Mesh")
--         local mesh_res = create_resource(Utils.GetMeshResourcePath(meshName), "via.render.MeshResource")
--         local mdf_res = create_resource(Utils.GetMaterialResourcePath(meshName), "via.render.MeshMaterialResource")
--         bodyMesh:setMesh(mesh_res)
--         bodyMesh:set_Material(mdf_res)
--     end)
-- end

-- local function ApplyAppearance(bodyPart, meshName)
--     local bodyMesh = SDK.GetComponent(bodyPart, "via.render.Mesh")
--     local mesh_res = create_resource(Utils.GetMeshResourcePath(meshName), "via.render.MeshResource")
--     local mdf_res = create_resource(Utils.GetMaterialResourcePath(meshName), "via.render.MeshMaterialResource")
--     bodyMesh:setMesh(mesh_res)
--     bodyMesh:set_Material(mdf_res)
-- end

-- local newMeshName = "ch03_014_0012"

-- q

-- for i=0,50000 do
--     create_resource(Utils.GetMeshResourcePath(newMeshName), "via.render.MeshResource")
--     create_resource(Utils.GetMaterialResourcePath(newMeshName), "via.render.MeshMaterialResource")
-- end
--local mesh = SDK.GetComponent(pu:GetBody(), "via.render.Mesh")
--mesh:getMesh():release()
