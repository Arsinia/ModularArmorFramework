local SDK = require "MAF/SDK"
local Log = require "MAF/Log"
local Const = require "MAF/Const"
local Cache = require "MAF/Cache"
local Table = require "MAF/Table"

MODULE = {
    State = Const.GameStates["Unknown"]
}

function MODULE.OnPlayerChangeCustomizeEquip(preFunction, postFunction)
    Log.Debug("OnPlayerChangeCustomizeEquip()")
    return SDK.HookMethod("app.HunterCharacter", "onEquipCustomizeEnd()", preFunction, postFunction)
end

function MODULE.OnLoading(preFunction, postFunction)
    Log.Debug("OnLoading()")
    SDK.HookMethod("app.EnemyManager", "evSceneLoadBefore(System.Boolean)", preFunction, postFunction)
end

function MODULE.AfterLoading(preFunction, postFunction)
    Log.Debug("AfterLoading()")
    SDK.HookMethod("app.EnemyManager", "evSceneLoadEndCore(app.FieldDef.STAGE)", preFunction, postFunction)
end

function MODULE.OnPlayerChangeEquip(handler)
    local hooks = json.load_file([[ModularArmorFramework/Settings/Hooks.json]])
    for _, hook in pairs(hooks) do
        SDK.HookMethod(hook["type"], hook["method"], nil, function()
            if handler ~= nil then
                Log.Event(hook["type"], hook["method"])
                handler()
            end

            if hook["state"] ~= nil and Const.GameStates[hook["state"]] ~= nil then
                MODULE.SetState(Const.GameStates[hook["state"]])
            end
        end)
    end
end

function MODULE.ResolvePlayerTransform(filter)
    local list = SDK.FindAllInScene(SDK.GetCurrentScene(), "via.Transform")
    if not list then return nil end

    local result = {}
    for _, transform in ipairs(list) do
        local go = transform:get_GameObject()
        if go ~= nil then
            local go_name = go:get_Name()
            if go_name ~= nil and Table.LikeAny(filter, go_name) then
                if transform:get_Child() ~= nil then
                    table.insert(result, transform)
                end
            end
        end
    end
    return result
end

function MODULE.GetPlayerTransforms()
    local cache_key = "__MAF_TRACKED_TRANFORMS__"
    local result = Cache.Get(cache_key)
    if result ~= nil then return result end

    return Cache.GetOrElse(cache_key, function()
        return MODULE.ResolvePlayerTransform(MODULE.State:GetTransforms())
    end)
end

function MODULE.SetState(state)
    if MODULE.State ~= nil and (state == MODULE.State or state == MODULE.State:GetName()) then return end
    if type(state) == "string" then
        local state_name = state
        state = Const.GameStates[state_name]
        if state == nil then
            Log.Error("State name unknown: " .. state_name)
        end
    end

    MODULE.State = state
    Cache.Reset()
    Log.Info("New state: " .. MODULE.State:GetName())
end

function MODULE.GetStateName()
    if MODULE.State then
        return MODULE.State:GetName()
    end
    return nil
end

function MODULE.IsIngame() return MODULE.State == Const.GameStates["Ingame"] end

function MODULE.IsOnTitleScreen() return MODULE.State == Const.GameStates["TitleScreen"] end

function MODULE.IsOnSaveSelectScreen() return MODULE.State == Const.GameStates["SaveSelect"] end

function MODULE.IsOnGuildCard() return MODULE.State == Const.GameStates["GuildCard"] end

function MODULE.IsInCutscene() return MODULE.State == Const.GameStates["Cutscene"] end

function MODULE.IsUnknown() return MODULE.State == Const.GameStates["Unknown"] end

-- Character Save select screen
SDK.HookMethod("app.GUI010102", "onOpen", nil, function() MODULE.SetState("SaveSelect") end)
SDK.HookMethod("app.GUI010102", "onDestroy", nil, function() MODULE.SetState("Ingame") end)

-- Guild card screen
SDK.HookMethod("app.GUI040200", "onOpen", nil, function() MODULE.SetState("GuildCard") end)
SDK.HookMethod("app.GUI040200", "onDestroy", nil, function() MODULE.SetState("Ingame") end)

-- Title Screen
SDK.HookMethod("app.GUI010101", ".ctor", nil, function() MODULE.SetState("TitleScreen") end)

-- Art gallery
SDK.HookMethod("app.CutSceneGalleryManager", "updateState_Ready", nil, function() MODULE.SetState("Cutscene") end)
SDK.HookMethod("app.CutSceneGalleryManager", "updateState_End", nil, function() MODULE.SetState("Unknown") end)

return MODULE
