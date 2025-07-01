local GameState = {}
GameState.__index = GameState
GameState.__type = "GameState"


function GameState:New(id, name, transforms)
    local obj = {
        ID = id,
        Name = name,
        Transforms = transforms or {}
    }
    setmetatable(obj, self)
    return obj
end

function GameState:GetID()
    return self.ID
end

function GameState:GetName()
    return self.Name
end

function GameState:GetTransforms()
    return self.Transforms
end

return GameState
