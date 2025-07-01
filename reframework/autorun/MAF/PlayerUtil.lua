local SDK = require "MAF/SDK"
local Log = require "MAF/Log"
local Utils = require "MAF/Utils"
local Const = require "MAF/Const"
local Cache = require "MAF/Cache"
local GameStateManager = require "MAF/GameStateManager"

local MODULE = {
    BodyPart = {
        Arms = nil,
        Body = nil,
        Head = nil,
        Legs = nil,
        Waist = nil
    }
}
MODULE.__type = "PlayerUtil"



local function getParts(charac, partid)
    local result = nil
    pcall(function()
        result = charac:getParts(partid)
    end)
    return result
end

function MODULE.Update()
    local playerInfo = SDK.GetPlayerInfo()
    if playerInfo == nil then return end

    local newPart = getParts(playerInfo, Const.ARMOR_TYPE["Arms"])
    if newPart ~= nil and MODULE.BodyPart.Arms ~= newPart then
        Cache.Delete("MESH[" .. newPart:get_Name() .. "]")
    end
    MODULE.BodyPart.Arms = newPart

    newPart = getParts(playerInfo, Const.ARMOR_TYPE["Body"])
    if newPart ~= nil and MODULE.BodyPart.Body ~= newPart then
        Cache.Delete("MESH[" .. newPart:get_Name() .. "]")
    end
    MODULE.BodyPart.Body = newPart

    newPart = getParts(playerInfo, Const.ARMOR_TYPE["Head"])
    if newPart ~= nil and MODULE.BodyPart.Head ~= newPart then
        Cache.Delete("MESH[" .. newPart:get_Name() .. "]")
    end
    MODULE.BodyPart.Head = newPart

    newPart = getParts(playerInfo, Const.ARMOR_TYPE["Legs"])
    if newPart ~= nil and MODULE.BodyPart.Legs ~= newPart then
        Cache.Delete("MESH[" .. newPart:get_Name() .. "]")
    end
    MODULE.BodyPart.Legs = newPart

    newPart = getParts(playerInfo, Const.ARMOR_TYPE["Waist"])
    if newPart ~= nil and MODULE.BodyPart.Waist ~= newPart then
        Cache.Delete("MESH[" .. newPart:get_Name() .. "]")
    end
    MODULE.BodyPart.Waist = newPart
end

function GetCharacterFromTransform(transform)
    local result = nil
    pcall(function()
        result = transform:get_GameObject():get_field('<Character>k__BackingField')
    end)
    return result
end

function MODULE.GetPart(i, transform)
    if not (i >= 0 and i <= 5) then return nil end
    if transform ~= nil then
        transform = GetCharacterFromTransform(transform)
    end

    if transform == nil then
        transform = SDK.GetPlayerInfo()
    end

    if transform == nil then return nil end
    return getParts(transform, i)
end

function MODULE.GetArms(transform)
    if transform then
        local charac = GetCharacterFromTransform(transform)
        return getParts(charac, Const.ARMOR_TYPE["Arms"])
    end
    return MODULE.BodyPart.Arms
end

function MODULE.GetBody(transform)
    if transform then
        local charac = GetCharacterFromTransform(transform)
        return getParts(charac, Const.ARMOR_TYPE["Body"])
    end
    return MODULE.BodyPart.Body
end

function MODULE.GetHead(transform)
    if transform then
        local charac = GetCharacterFromTransform(transform)
        return getParts(charac, Const.ARMOR_TYPE["Head"])
    end
    return MODULE.BodyPart.Head
end

function MODULE.GetLegs(transform)
    if transform then
        local charac = GetCharacterFromTransform(transform)
        return getParts(charac, Const.ARMOR_TYPE["Legs"])
    end
    return MODULE.BodyPart.Legs
end

function MODULE.GetWaist(transform)
    if transform then
        local charac = GetCharacterFromTransform(transform)
        return getParts(charac, Const.ARMOR_TYPE["Waist"])
    end
    return MODULE.BodyPart.Waist
end

function MODULE.ForEachBodyPart(fun, transform)
    if transform ~= nil then
        for i = 1, 5 do
            local part = getParts(transform, i)
            fun(i, part)
        end
    else
        for key, entry in pairs(MODULE.BodyPart) do
            if entry ~= nil then
                fun(entry)
            end
        end
    end
end

GameStateManager.OnPlayerChangeEquip(MODULE.Update)
MODULE.Update()
return MODULE
