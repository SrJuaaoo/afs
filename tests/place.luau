-- Run from the repository root with Lune 0.8.9 after building both places.
local fs = require("@lune/fs")
local roblox = require("@lune/roblox")
local luau = require("@lune/luau")

local scripts = {
    {Path = {"ReplicatedStorage", "GameConfig"}, Class = "ModuleScript", Source = "src/ReplicatedStorage/GameConfig.lua"},
    {Path = {"ServerScriptService", "GameServer"}, Class = "Script", Source = "src/ServerScriptService/GameServer.server.lua"},
    {Path = {"StarterPlayer", "StarterPlayerScripts", "GameClient"}, Class = "LocalScript", Source = "src/StarterPlayer/StarterPlayerScripts/GameClient.client.lua"},
}

local function verify(place)
    assert(place.ClassName == "DataModel", "O arquivo deve conter um lugar, não um modelo.")
    assert(place:FindFirstChildOfClass("Workspace"), "Workspace ausente")
    local count = 0
    for _, descendant in place:GetDescendants() do
        if descendant:IsA("LuaSourceContainer") then count += 1 end
    end
    assert(count == #scripts, "Número inesperado de scripts")
    for _, expected in scripts do
        local instance = place
        for _, name in expected.Path do
            instance = assert(instance:FindFirstChild(name), "Objeto ausente: " .. name)
        end
        assert(instance.ClassName == expected.Class, "Classe incorreta: " .. instance:GetFullName())
        assert(instance.Source == fs.readFile(expected.Source), "Script alterado na exportação: " .. expected.Source)
        assert(luau.load(instance.Source), "Falha de compilação Luau: " .. expected.Source)
    end
end

for _, extension in {"rbxl", "rbxlx"} do
    local path = "dist/LendasDoAnime." .. extension
    local bytes = fs.readFile(path)
    if extension == "rbxlx" then
        assert(string.sub(bytes, 1, 7) == "<roblox", "O XML deve começar com a raiz Roblox")
    else
        assert(string.sub(bytes, 1, 8) == "<roblox!", "Cabeçalho binário inválido")
    end
    local place = roblox.deserializePlace(bytes)
    verify(place)
    -- Check a full Roblox binary serialization round trip, not just generic XML parsing.
    verify(roblox.deserializePlace(roblox.serializePlace(place)))
    print("PASS: " .. path .. " · leitura Roblox, serviços, scripts, compilação e regravação.")
end
