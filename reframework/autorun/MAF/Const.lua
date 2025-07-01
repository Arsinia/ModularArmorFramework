local GameState = require "MAF/GameState"

local GAME_STATE = {
    Unknown = 0,
    Ingame = 1,
    GuildCard = 2,
    SaveSelect = 3,
    TitleScreen = 4,
    Cutscene = 5
}
for key, value in pairs(GAME_STATE) do
    GAME_STATE[value] = key
end

local ARMOR_TYPE = {
    Head = 0,
    Body = 1,
    Arms = 2,
    Waist = 3,
    Legs = 4,
    Slinger = 5
}
for key, value in pairs(ARMOR_TYPE) do
    ARMOR_TYPE[value] = key
end

local GameStates = {
    [1] = GameState:New(0, "Unknown"),
    [2] = GameState:New(1, "Ingame", { "MasterPlayer", "Player_Replica_%d%d", "Otomo_%d%d" }),
    [3] = GameState:New(2, "GuildCard", { "GuildCard_HunterXX", "GuildCard_HunterXY" }),
    [4] = GameState:New(3, "SaveSelect", { "SaveSelect_HunterXY", "SaveSelect_HunterXX" }),
    [5] = GameState:New(4, "TitleScreen", { "Pl000_00" }),
    [6] = GameState:New(5, "Cutscene", { "MasterPlayer" })
}
for key, value in ipairs(GameStates) do
    GameStates[value:GetName()] = GameStates[key]
end

return {
    ARMOR_TYPE = ARMOR_TYPE,
    GAME_STATE = GAME_STATE,
    GameStates = GameStates
}
