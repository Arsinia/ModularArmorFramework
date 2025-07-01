local SDK = require "MAF/SDK"
local Cache = require "MAF/Cache"
local Log = require "MAF/Log"
local random = math.random

local MODULE = {
}

function MODULE.NewUUID()
    local template = 'xxxxxxxx-xxxx-xxxx-yxxx-xxxxxxxxxxxx'
    return string.gsub(template, '[xy]', function(c)
        local v = (c == 'x') and random(0, 0xf) or random(8, 0xb)
        return string.format('%x', v)
    end)
end

function MODULE.ParseMeshReference(meshReference)
    if Cache.Get(meshReference) ~= nil then return Cache.Get(meshReference) end

    local result = {}
    if type(meshReference) == "table" then return nil end
    local mesh, group = meshReference:match("^!?([^/]+)/(%d*)$")
    local inverted = meshReference:sub(1, 1) == "!"
    result = { mesh = mesh, group = tonumber(group), inverted = inverted, name = mesh .. "/" .. group }
    Cache.Set(meshReference, result)
    return result
end

function MODULE.RunningMonsterHunterWilds()
    return reframework:get_game_name() == "mhwilds"
end

function GetResourcePath(meshName, ext)
    local parts = {}
    for part in meshName:gmatch("[^_]+") do
        table.insert(parts, part)
    end

    if #parts < 3 then return nil end
    local path = string.format("Art/Model/Character/%s/%s/%s/%s/%s.%s",
        parts[1], parts[2], parts[3]:sub(1, 3), parts[3]:sub(4, 4), meshName, ext)
    return path
end

function MODULE.GetMeshResourcePath(meshName)
    return GetResourcePath(meshName, "mesh")
end

function MODULE.GetMaterialResourcePath(meshName)
    return GetResourcePath(meshName, "mdf2")
end

-- re.on_application_entry("StartScene", function()
--     print("StartScene")
--     if MODULE._isReady then return end
--     MODULE._isReady = MODULE.RunningMonsterHunterWilds()
-- end)

-- re.on_script_reset(function()
--     local pb = MODULE.GetPlayerBody(true)
--     print(pb)
--     if pb ~= nil then
--         MODULE._isReady = true
--     else
--         MODULE._isReady = false
--     end
-- end)



-- local EnumValToNameMapCache = {}
-- local EnumNameToValMapCache = {}
-- local function GetEnumMap(enumTypeName, cache)
--     if cache and EnumValToNameMapCache[enumTypeName] ~= nil and EnumNameToValMapCache[enumTypeName] ~= nil then
--         return EnumValToNameMapCache[enumTypeName], EnumNameToValMapCache[enumTypeName]
--     end

--     local t = sdk.find_type_definition(enumTypeName)
--     if not t then
--         return {}, {}
--     end

--     local fields = t:get_fields()
--     local valToName = {}
--     local nameToVal = {}

--     for i, field in ipairs(fields) do
--         if field:is_static() then
--             local name = field:get_name()
--             local raw_value = field:get_data(nil)
--             valToName[raw_value] = name
--             nameToVal[name] = raw_value
--         end
--     end

--     if cache then
--         EnumValToNameMapCache[enumTypeName] = valToName
--         EnumNameToValMapCache[enumTypeName] = nameToVal
--     end
--     return valToName, nameToVal
-- end

-- local KeyboardKeyIndex = GetEnumMap("ace.ACE_MKB_KEY.INDEX")
-- local KeyboardKeyIndex_ToValue = {}
-- for idx, name in pairs(KeyboardKeyIndex) do
--     KeyboardKeyIndex_ToValue[name] = idx
--     print(idx, name)
-- end
-- local KeyboardManager = sdk.get_managed_singleton("ace.MouseKeyboardManager")
-- local function KeyOn(key)
--     return KeyboardManager:get_MainMouseKeyboard():isOn(KeyboardKeyIndex_ToValue[key])
-- end

local sleep_end_time = nil
local sleep_callback = nil

re.on_frame(function()
    if sleep_end_time and os.clock() >= sleep_end_time then
        local result = sleep_callback and sleep_callback() -- Exécute le callback et récupère le retour
        sleep_end_time = nil
        sleep_callback = nil
        return result -- Retourne le résultat du callback
    end
end)

function MODULE.Sleep(duration, callback)
    local new_end_time = os.clock() + duration

    if not sleep_end_time or new_end_time > sleep_end_time then
        sleep_end_time = new_end_time -- Prolonge la durée si nécessaire
    end

    if callback then
        sleep_callback = callback -- Met à jour le callback si fourni
    end
end

return MODULE
