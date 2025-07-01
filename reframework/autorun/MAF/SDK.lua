local Cache = require "MAF/Cache"
local Log = require "MAF/Log"
local Table = require "MAF/Table"

local MODULE = {
    _isGuildCardDrawn = false
}

local nativeSingletonPrefix = "NativeSingleton##"
local managedSingletonPrefix = "ManagedSingleton##"
local methodPrefix = "Method##"
local TypeDefnitionPrefix = "TypeDefinition##"

function MODULE.GetComponent(gameObject, componentType)
    Log.Debug("GetComponent()")
    if gameObject == nil then return nil end

    local method = MODULE.FindMethod("via.GameObject", "getComponent(System.Type)")
    if method then
        return method:call(gameObject, sdk.typeof(componentType))
    end
    return nil
end

function MODULE.FindMethod(typeName, methodName)
    Log.Debug("FindMethod()")
    local method = Cache[methodPrefix .. typeName .. "." .. methodName]
    if method then
        return method
    else
        local type = sdk.find_type_definition(typeName)
        if type == nil then return false end

        method = type:get_method(methodName)
        if method == nil then return false end
        Cache[methodPrefix .. typeName .. "." .. methodName] = method
        return MODULE.FindMethod(typeName, methodName)
    end
end

function MODULE.FindTypeDefinition(typeName)
    Log.Debug("FindTypeDefinition()")
    return Cache.GetOrElse(TypeDefnitionPrefix .. typeName, function()
        return sdk.find_type_definition(typeName)
    end)
end

function MODULE.GetNativeSingleton(singletonName)
    Log.Debug("GetNativeSingleton()")
    return Cache.GetOrElse(nativeSingletonPrefix .. singletonName, function()
        return sdk.get_native_singleton(singletonName)
    end)
end

function MODULE.GetManagedSingleton(singletonName)
    Log.Debug("GetManagedSingleton()")
    return Cache.GetOrElse(managedSingletonPrefix .. singletonName, function()
        return sdk.get_managed_singleton(singletonName)
    end)
end

function MODULE.GetCurrentScene()
    Log.Debug("GetCurrentScene()")
    return Cache.GetOrElse("via.SceneManager__get_CurrentScene", function()
        local sceneManager = MODULE.GetNativeSingleton("via.SceneManager")
        if sceneManager == nil then return end
        return sdk.call_native_func(sceneManager,
            MODULE.FindTypeDefinition("via.SceneManager"), "get_CurrentScene")
    end)
end

function MODULE.GetMainScene()
    Log.Debug("GetMainScene()")
    return Cache.GetOrElse("via.SceneManager__get_MainScene", function()
        local sceneManager = MODULE.GetNativeSingleton("via.SceneManager")
        if sceneManager == nil then return end
        return sdk.call_native_func(sceneManager,
            MODULE.FindTypeDefinition("via.SceneManager"), "get_MainScene")
    end)
end

function MODULE.GetGameFlowManager()
    Log.Debug("GetGameFlowManager()")
    return MODULE.GetManagedSingleton("app.GameFlowManager")
end

function MODULE.GetPlayerManager()
    Log.Debug("GetPlayerManager()")
    return MODULE.GetManagedSingleton("app.PlayerManager")
end

function MODULE.GetMasterPlayer()
    Log.Debug("GetMasterPlayer()")
    return Cache.GetOrElse("PlayerMaster", function()
        if MODULE.GetPlayerManager() == nil then return nil end
        return MODULE.GetPlayerManager():getMasterPlayer()
    end)
end

function MODULE.GetPlayerInfo()
    Log.Debug("GetPlayerInfo()")
    return Cache.GetOrElse("PlayerInfo", function()
        if MODULE.GetMasterPlayer() == nil then return nil end
        return MODULE.GetMasterPlayer():get_field('<Character>k__BackingField')
    end)
end

function MODULE.GetPlayerObject()
    Log.Debug("GetPlayerObject()")
    return Cache.GetOrElse("PlayerObject", function()
        if MODULE.GetMasterPlayer() == nil then return nil end
        return MODULE.GetMasterPlayer():get_Object()
    end)
end

function MODULE.GetPlayerBody()
    Log.Debug("GetPlayerBody()")
    return Cache.GetOrElse("PlayerBody", function()
        if MODULE.GetPlayerObject() == nil then return nil end
        return MODULE.GetComponent(MODULE.GetPlayerObject(), 'via.Transform')
    end)
end

function MODULE.HashCalc32(str)
    Log.Debug("HashCalc32()")
    if type(str) == "string" and tonumber(str) == nil then
        ---@diagnostic disable-next-line: undefined-field
        local mumrur = Cache.GetOrElse("via.murmur_hash", function()
            return sdk.create_instance("via.murmur_hash")
        end)

        local method = MODULE.FindMethod("via.murmur_hash", "calc32")
        if method then
            return method:call(mumrur, str)
        end
    end
    return nil
end

function MODULE.IsFemale()
    Log.Debug("IsFemale()")
    return Cache.GetOrElse("IsFemale", function()
        if MODULE.GetPlayerInfo() == nil then return nil end
        return MODULE.GetPlayerInfo():get_IsFemale()
    end)
end

function MODULE.IsMale()
    Log.Debug("IsMale()")
    local isFemale = MODULE.IsFemale()
    return isFemale and not isFemale or isFemale
end

function MODULE.IsSetup()
    Log.Debug("IsSetup()")
    return Cache.GetOrElse("IsSetup", function()
        if MODULE.GetPlayerInfo() == nil then return nil end
        return MODULE.GetPlayerInfo():get_IsSetUp()
    end)
end

function MODULE.GetMesh(transform, meshName)
    Log.Debug("GetMesh()")
    if transform == nil then return nil end
    if meshName == nil then return nil end

    return Cache.GetOrElse("MESH[" .. meshName .. "]", function()
        if transform == nil then return nil end
        local result = transform:find(meshName)
        if result == nil then
            local child = transform:get_Child()
            if child ~= nil then
                result = child:find(meshName)
            end
        end

        if result == nil then return nil end
        return MODULE.GetComponent(result, 'via.render.Mesh')
    end)
end

function MODULE:FindGameObjectByName(root, gameObjectName, type)
    Log.Debug("FindGameObjectByName()")
    if root == nil then return nil end
    if gameObjectName == nil then return nil end
    if type == nil then return nil end
    return Cache.GetOrElse(root:ToString(), function()
        local result = root:find(gameObjectName)
        if result == nil then
            local child = root:get_Child()
            if child ~= nil then
                result = child:find(gameObjectName)
            end
        end

        if result == nil then return nil end
        return MODULE.GetComponent(result, type)
    end)
end

function MODULE.IsLoading()
    Log.Debug("IsLoading()")
    return Cache.GetOrElse("app.GameFlowManager__get_Loading()", function()
        local gameflowManager = MODULE.GetGameFlowManager()
        local method = MODULE.FindMethod("app.GameFlowManager", "get_Loading()")
        if method and gameflowManager then
            return method:call(gameflowManager)
        end
        return nil
    end)
end

function MODULE.HookMethod(typeName, methodName, preFunction, postFunction)
    Log.Debug("HookMethod()")
    local method = MODULE.FindMethod(typeName, methodName)
    if method then
        sdk.hook(method, preFunction, postFunction)
    end
end

function MODULE.IsGuildCardActive()
    Log.Debug("IsGuildCardActive()")
    return MODULE._isGuildCardDrawn
end

function MODULE.FindAllInScene(scene, typeName)
    if scene == nil then return nil end
    if typeName == nil then typeName = "via.Transform" end

    local sceneFindComponents = Cache.GetOrElse("via.Scene__findComponents", function()
        return sdk.find_type_definition('via.Scene'):get_method('findComponents(System.Type)')
    end)

    ---@diagnostic disable-next-line: need-check-nil
    local list = sceneFindComponents:call(scene, sdk.typeof(typeName))
    list = list and list:get_elements() or {}
    return list
end

function MODULE.FindInScene(scene, name, typeName)
    if scene == nil then return nil end
    if name == nil or (type(name) ~= "string" and type(name) ~= "table") then return nil end
    if typeName == nil then typeName = "via.Transform" end

    ---@diagnostic disable-next-line: need-check-nil
    local list = MODULE.FindAllInScene(scene, typeName)
    if not list then return nil end

    if type(name) == "string" then
        name = { name }
    end

    for _, transform in ipairs(list) do
        local go = transform:get_GameObject()
        local go_name = go:get_Name()
        if Table.In(name, go_name) then
            if transform:get_Child() ~= nil then
                return transform
            end
        end
    end
    return nil
end

return MODULE
