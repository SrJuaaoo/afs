-- Headless server regression with real serialized Instances and simulated Roblox services.
-- This exercises startup/gameplay logic, not Studio rendering, networking or physics.
local fs = require("@lune/fs")
local roblox = require("@lune/roblox")
local luau = require("@lune/luau")
local World = require("../src/ReplicatedStorage/GameWorld")
local ProfileStore = require("../src/ServerScriptService/ProfileStore")
local V, F = roblox.Vector3, roblox.CFrame

local function signal()
    local callbacks = {}
    return {
        Connect = function(_, callback)
            table.insert(callbacks, callback)
            return {Disconnect = function() end}
        end,
        Fire = function(_, ...)
            for _, callback in table.clone(callbacks) do callback(...) end
        end,
    }
end
local signals = {}
local function event(instance, name)
    local key = instance:GetFullName() .. ":" .. name
    signals[key] = signals[key] or signal()
    return signals[key]
end
for class, names in {ProximityPrompt = {"Triggered"}, ClickDetector = {"MouseClick"}, RemoteEvent = {"OnServerEvent"}} do
    for _, name in names do
        roblox.implementProperty(class, name, function(instance) return event(instance, name) end)
    end
end
for _, class in {"ReplicatedStorage", "ServerScriptService", "Model"} do
    roblox.implementMethod(class, "WaitForChild", function(instance, name)
        return assert(instance:FindFirstChild(name), "Filho ausente: " .. name)
    end)
end
-- Lune has no engine pivot methods; model motion is implemented explicitly for this test.
roblox.implementMethod("Model", "GetPivot", function(model) return model.PrimaryPart.CFrame end)
roblox.implementMethod("Model", "PivotTo", function(model, destination)
    local delta = destination * model.PrimaryPart.CFrame:Inverse()
    for _, part in model:GetDescendants() do
        if part:IsA("BasePart") then part.CFrame = delta * part.CFrame end
    end
end)

local function copy(value)
    if type(value) ~= "table" then return value end
    local result = {}
    for k, v in value do result[k] = copy(v) end
    return result
end
local states, messages = {}, {}
roblox.implementMethod("RemoteEvent", "FireClient", function(_, player, action, value)
    messages[player] = messages[player] or {}
    table.insert(messages[player], {Action = action, Value = value})
    if action == "State" then states[player] = copy(value) end
end)

local function runScenario(placeId)
    table.clear(signals)
    local place = roblox.deserializePlace(fs.readFile("dist/LendasDoAnime.rbxl"))
    local workspace = place:FindFirstChildOfClass("Workspace")
    local storage = place:FindFirstChildOfClass("ReplicatedStorage")
    local source = place:FindFirstChildOfClass("ServerScriptService").GameServer
    local Config = luau.load(storage.GameConfig.Source, {environment = {Color3 = roblox.Color3, ipairs = ipairs, math = math}})()
    local clock, jobs, guid, requests = 0, {}, 0, 0
    local function spawn(callback, ...)
        local thread = type(callback) == "thread" and callback or coroutine.create(callback)
        local ok, seconds = coroutine.resume(thread, ...)
        assert(ok, tostring(seconds))
        if coroutine.status(thread) ~= "dead" then
            table.insert(jobs, {At = clock + (seconds or 0), Thread = thread})
        end
        return thread
    end
    local function newPlayer(id)
        local character = roblox.Instance.new("Model")
        character.Name, character.Parent = "Player" .. id, workspace
        local root = roblox.Instance.new("Part")
        root.Name, root.CFrame, root.Parent = "HumanoidRootPart", F.new(0, 6, 55), character
        local attributes = {}
        return {
            UserId = id, Parent = true, Character = character, CharacterAdded = signal(),
            SetAttribute = function(_, key, value) attributes[key] = value end,
            GetAttribute = function(_, key) return attributes[key] end,
            Kick = function(self, reason) self.Kicked = reason end,
        }
    end
    local existing = newPlayer(101 + placeId)
    local players = {PlayerAdded = signal(), PlayerRemoving = signal(), GetPlayers = function() return {existing} end}
    local runService = {Heartbeat = signal(), IsStudio = function() return true end}
    local services = {
        Players = players, RunService = runService, ReplicatedStorage = storage,
        Lighting = place:FindFirstChildOfClass("Lighting"),
        DataStoreService = {GetDataStore = function()
            requests += 1
            error("You must publish this place to the web to access DataStore.")
        end},
        HttpService = {GenerateGUID = function() guid += 1; return "fighter-" .. guid end},
    }
    local game = {PlaceId = placeId, GetService = function(_, name) return assert(services[name], name) end, BindToClose = function() end}
    local env = {
        game = game, workspace = workspace, script = source,
        Instance = roblox.Instance, Vector3 = V, CFrame = F,
        Random = {new = function() return {NextInteger = function() return 1 end} end},
        require = function(module)
            if module.Name == "GameConfig" then return Config end
            if module.Name == "ProfileStore" then return ProfileStore end
            if module.Name == "GameWorld" then return {
                Build = function(config) return World.Build(config, roblox) end,
                CreateFighter = function(parent, def, name, position, scale)
                    return World.CreateFighter(parent, def, name, position, scale, roblox)
                end,
            } end
            error("Módulo inesperado: " .. module.Name)
        end,
        task = {
            spawn = spawn, wait = function(seconds) return coroutine.yield(seconds) end,
            delay = function(seconds, callback) table.insert(jobs, {At = clock + seconds, Callback = callback}) end,
        },
        os = {clock = function() return clock end},
        warn = function() end, ipairs = ipairs, pairs = pairs, pcall = pcall,
        type = type, tostring = tostring, math = math, table = table,
    }
    local function advance(seconds)
        clock += seconds
        local due = table.clone(jobs)
        table.clear(jobs)
        for _, job in due do
            if job.At <= clock then
                if job.Thread then spawn(job.Thread) else spawn(job.Callback) end
            else table.insert(jobs, job) end
        end
        runService.Heartbeat:Fire(seconds)
    end
    luau.load(source.Source, {environment = env})()
    local map = workspace.LendasWorld
    assert(existing.Kicked == nil and existing:GetAttribute("SessionOnly"))
    assert(states[existing] and states[existing].Coins == 300, "Jogador existente deve receber seu perfil")
    assert(#map["Equipe_" .. existing.UserId]:GetChildren() == 1, "Lutador inicial deve aparecer")
    assert(#map.Inimigos:GetChildren() == 15 and #map.Ilhas:GetChildren() == 3)
    if placeId == 0 then assert(requests == 0) else assert(requests == 1) end
    local copies = 0
    for _, object in workspace:GetChildren() do if object.Name == "LendasWorld" then copies += 1 end end
    assert(copies == 1, "Servidor não deve duplicar o mapa pronto")

    local later = newPlayer(202 + placeId)
    players.PlayerAdded:Fire(later)
    assert(states[later] and #map["Equipe_" .. later.UserId]:GetChildren() == 1)
    local enemy = map.Inimigos.Enemy_1_1
    existing.Character.HumanoidRootPart.CFrame = enemy.Body.CFrame * F.new(0, 0, 10)
    event(enemy.Body.ClickDetector, "MouseClick"):Fire(existing)
    for _ = 1, 10 do advance(0.8) end
    assert(states[existing].Coins == 335 and states[existing].Kills == 1, "Combate deve dar moedas e uma vitória: " .. states[existing].Coins .. " moedas; " .. enemy.Head.Nameplate.Caption.Text)
    assert(states[later].Coins == 300 and states[later].Kills == 0, "Perfis devem ser independentes")
    assert(enemy.Body.Transparency == 1 and not enemy.Body.ProximityPrompt.Enabled)
    advance(7)
    assert(enemy.Body.Transparency == 0 and enemy.Body.ProximityPrompt.Enabled, "Inimigo deve renascer")

    local altar = map.Ilhas["Vila da Aurora"].Estrela
    existing.Character.HumanoidRootPart.CFrame = altar.CFrame * F.new(0, 0, 5)
    event(altar.ProximityPrompt, "Triggered"):Fire(existing)
    assert(states[existing].Coins == 235 and #states[existing].Inventory == 2, "Invocação deve funcionar sem DataStore")
    assert(#map["Equipe_" .. existing.UserId]:GetChildren() == 2)
    local remote = storage.GameEvent
    advance(0.2)
    event(remote, "OnServerEvent"):Fire(existing, "Travel", 2)
    assert(states[existing].Unlocked == 1 and states[existing].Coins == 235, "Sem moedas, ilha deve continuar bloqueada")
    advance(0.2)
    event(remote, "OnServerEvent"):Fire(existing, "Equip", states[existing].Equipped[1])
    assert(#states[existing].Equipped == 1 and #map["Equipe_" .. existing.UserId]:GetChildren() == 1)
    players.PlayerRemoving:Fire(existing)
    assert(map:FindFirstChild("Equipe_" .. existing.UserId) == nil)
    print("PASS: servidor com PlaceId=" .. placeId .. " · entrada, equipe, combate, recompensa, renascimento, invocação e inventário.")
end

runScenario(0)
runScenario(123)
