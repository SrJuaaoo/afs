-- Run from the repository root with Lune 0.8.9 after building both places.
local fs = require("@lune/fs")
local roblox = require("@lune/roblox")
local luau = require("@lune/luau")

local scripts = {
    {Path = {"ReplicatedStorage", "GameConfig"}, Class = "ModuleScript", Source = "src/ReplicatedStorage/GameConfig.lua"},
    {Path = {"ReplicatedStorage", "GameWorld"}, Class = "ModuleScript", Source = "src/ReplicatedStorage/GameWorld.lua"},
    {Path = {"ServerScriptService", "GameServer"}, Class = "Script", Source = "src/ServerScriptService/GameServer.server.lua"},
    {Path = {"ServerScriptService", "ProfileStore"}, Class = "ModuleScript", Source = "src/ServerScriptService/ProfileStore.lua"},
    {Path = {"StarterPlayer", "StarterPlayerScripts", "GameClient"}, Class = "LocalScript", Source = "src/StarterPlayer/StarterPlayerScripts/GameClient.client.lua"},
}

local function verify(place)
    assert(place.ClassName == "DataModel", "O arquivo deve conter um lugar, não um modelo.")
    local workspace = assert(place:FindFirstChildOfClass("Workspace"), "Workspace ausente")
    assert(workspace.CurrentCamera == workspace.Camera, "Câmera inicial deve apontar para a primeira ilha")
    assert((workspace.Camera.Focus.Position - roblox.Vector3.new(0, 4, 0)).Magnitude < 0.1)
    local map = assert(workspace:FindFirstChild("LendasWorld"), "Mapa deve estar presente antes de executar scripts")
    assert(#map.Ilhas:GetChildren() == 3, "As três ilhas devem estar no arquivo")
    assert(#map.Inimigos:GetChildren() == 15, "Os inimigos devem estar no arquivo")
    assert(#map.GaleriaDeLutadores:GetChildren() == 5, "Os cinco modelos de lutadores devem estar no arquivo")
    for _, folder in {map.Inimigos, map.GaleriaDeLutadores} do
        for _, fighter in folder:GetChildren() do
            for _, limb in {"Body", "Head", "LeftArm", "RightArm", "LeftLeg", "RightLeg"} do
                assert(fighter:FindFirstChild(limb), "Modelo incompleto: " .. fighter.Name .. "." .. limb)
            end
            assert(fighter.PrimaryPart == fighter.Body)
        end
    end
    assert(map.Inicio:IsA("SpawnLocation") and map.Inicio.Neutral, "Ponto de entrada ausente")
    local ground = map.Ilhas["Vila da Aurora"].Terreno
    assert(map.Inicio.CFrame.Position.Y > ground.CFrame.Position.Y + ground.Size.Y / 2)
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
    print("PASS: " .. path .. " · mapa incorporado, câmera, 15 inimigos, cinco lutadores, scripts e regravação.")
end
