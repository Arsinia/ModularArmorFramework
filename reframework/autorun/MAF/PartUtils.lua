local SDK = require "MAF/SDK"
local Utils = require "MAF/Utils"
local Log = require "MAF/Log"

local MODULE = {
}

function MODULE.SetState(mesh, partIndice, state)
    if mesh == nil then return false end
    if partIndice == nil then return false end

    if type(partIndice) == "table" then
        for _, pi in ipairs(partIndice) do
            mesh:setPartsEnable(tonumber(pi), state)
        end
    else
        mesh:setPartsEnable(tonumber(partIndice), state)
    end
    return true
end

function MODULE.GetState(mesh, partIndice)
    if mesh == nil then return false end
    if partIndice == nil then return false end

    return mesh:getPartsEnable(tonumber(partIndice))
end

function MODULE.Hide(mesh, partIndice)
    return MODULE.SetState(mesh, partIndice, false)
end

function MODULE.Show(mesh, partIndice)
    return MODULE.SetState(mesh, partIndice, true)
end

function MODULE.ApplyAll(transform, meshData, state)
    if transform == nil then return nil end
    if meshData == nil then return nil end
    if state == nil then return nil end

    local foundMesh = Utils.ParseMeshReference(meshData)
    if foundMesh == nil then return nil end
    local meshes = foundMesh["mesh"] and { foundMesh } or foundMesh

    for _, v in ipairs(meshes) do
        local mesh = SDK.GetMesh(transform, v["mesh"])

        local new_value = (v["inverted"] and not state) or (state and not v["inverted"])
        if mesh then
            MODULE.SetState(mesh, v["group"], new_value)
        end
    end
end

function MODULE.ShowAll(transform, meshData)
    if transform == nil then return nil end
    if meshData == nil then return nil end

    local foundMesh = Utils.ParseMeshReference(meshData)
    if foundMesh == nil then return nil end

    local meshes = foundMesh["mesh"] and { foundMesh } or foundMesh
    for _, v in ipairs(meshes) do
        local mesh = SDK.GetMesh(transform, v["mesh"])
        if mesh then
            MODULE.SetState(mesh, v["group"], true)
        end
    end
end

return MODULE
