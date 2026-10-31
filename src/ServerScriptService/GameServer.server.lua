local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local DataStoreService = game:GetService("DataStoreService")
local HttpService = game:GetService("HttpService")
local RunService = game:GetService("RunService")
local Config = require(ReplicatedStorage:WaitForChild("GameConfig"))
local World = require(ReplicatedStorage:WaitForChild("GameWorld"))
local ProfileStore = require(script.Parent:WaitForChild("ProfileStore"))
local remote = Instance.new("RemoteEvent")
remote.Name = "GameEvent"
remote.Parent = ReplicatedStorage
local profiles, targets, cooldowns, enemies, pets = {}, {}, {}, {}, {}
local random = Random.new()
local map = workspace:FindFirstChild("LendasWorld") or World.Build(Config)
map.Parent = workspace
workspace.FallenPartsDestroyHeight = -100
game:GetService("Lighting").ClockTime = 14
game:GetService("Lighting").Brightness = 2

local function send(player)
    local profile = profiles[player]
    if profile then remote:FireClient(player, "State", profile) end
end
local function toast(player, message)
    remote:FireClient(player, "Toast", message)
end
local function root(player)
    return player.Character and player.Character:FindFirstChild("HumanoidRootPart")
end
local function spawnPosition(world)
    return Vector3.new((world - 1) * 650, 6, 55)
end
local function fighter(kind, world)
    return {Uid = HttpService:GenerateGUID(false), Kind = kind, Level = 1, XP = 0, World = world}
end
local function newProfile()
    local starter = fighter("haru", 1)
    return {Coins = 300, World = 1, Unlocked = 1, Inventory = {starter}, Equipped = {starter.Uid}, Kills = 0, QuestClaimed = 0}
end
local function equipped(profile, uid)
    return table.find(profile.Equipped, uid) ~= nil
end
local function rebuildPets(player)
    if pets[player] then pets[player]:Destroy() end
    local folder = Instance.new("Folder")
    folder.Name, folder.Parent = "Equipe_" .. player.UserId, map
    pets[player] = folder
    for _, f in ipairs(profiles[player].Inventory) do
        if equipped(profiles[player], f.Uid) then
            local definition = Config.GetFighter(f.Kind)
            local r = root(player)
            local position = r and r.CFrame.Position or spawnPosition(profiles[player].World)
            local model = World.CreateFighter(folder, definition, f.Uid, position, 0.8)
            model.Head.Nameplate.Caption.Text = definition.Name .. " · Nv. " .. f.Level
        end
    end
end
local function summon(player)
    local p, r = profiles[player], root(player)
    if not p or not r then return end
    local altar = Vector3.new((p.World - 1) * 650 - 30, 4, 20)
    if (r.CFrame.Position - altar).Magnitude > 22 then toast(player, "Aproxime-se da Estrela de Invocação!"); return end
    local cost = Config.Worlds[p.World].SummonCost
    if p.Coins < cost then toast(player, "Moedas insuficientes!"); return end
    if #p.Inventory >= Config.MaxInventory then toast(player, "Inventário cheio! Venda lutadores para liberar espaço."); return end
    p.Coins = p.Coins - cost
    local roll, sum, chosen = random:NextInteger(1, 100), 0, Config.Fighters[1]
    for _, def in ipairs(Config.Fighters) do
        sum = sum + def.Weight
        if roll <= sum then chosen = def; break end
    end
    local f = fighter(chosen.Id, p.World)
    table.insert(p.Inventory, f)
    if #p.Equipped < Config.MaxEquipped then table.insert(p.Equipped, f.Uid); rebuildPets(player) end
    send(player)
    remote:FireClient(player, "Summoned", f)
end
local function travel(player, world)
    local p, r = profiles[player], root(player)
    if not p or not r or type(world) ~= "number" or world % 1 ~= 0 or not Config.Worlds[world] then return end
    if world > p.Unlocked then
        if world ~= p.Unlocked + 1 then toast(player, "Desbloqueie a ilha anterior primeiro!"); return end
        local cost = Config.Worlds[world].Cost
        if p.Coins < cost then toast(player, "Você precisa de " .. cost .. " moedas para esta ilha."); return end
        p.Coins, p.Unlocked = p.Coins - cost, world
    end
    p.World, targets[player] = world, nil
    r.CFrame = CFrame.new(spawnPosition(world))
    send(player)
end

-- The map, prompts and opponents are already present in the downloaded place.
-- Only bind gameplay here; never create a second copy on top of the baked world.
for _, object in ipairs(map:GetDescendants()) do
    if object:IsA("BasePart") then
        local summonWorld = object:GetAttribute("SummonWorld")
        local destination = object:GetAttribute("Destination")
        if summonWorld then
            object.ProximityPrompt.Triggered:Connect(function(player)
                if profiles[player] and profiles[player].World == summonWorld then summon(player) end
            end)
        elseif destination then
            object.ProximityPrompt.Triggered:Connect(function(player)
                local p, r = profiles[player], root(player)
                if p and r and p.World == destination - 1 and (r.CFrame.Position - object.CFrame.Position).Magnitude <= 22 then
                    travel(player, destination)
                end
            end)
        end
    end
end
for _, model in ipairs(map.Inimigos:GetChildren()) do
    local index = model:GetAttribute("WorldIndex")
    local world = Config.Worlds[index]
    local boss = model:GetAttribute("Boss")
    local health = world.Health * (boss and 8 or 1)
    local body, head = model.Body, model.Head
    local entry = {Model = model, Name = model:GetAttribute("EnemyName"), Body = body, Head = head, World = index, Health = health, MaxHealth = health, Reward = world.Reward * (boss and 6 or 1), Dead = false, Label = head.Nameplate.Caption}
    enemies[model] = entry
    local function selectTarget(player)
        local p, r = profiles[player], root(player)
        if p and r and p.World == index and not entry.Dead and (r.CFrame.Position - body.CFrame.Position).Magnitude <= Config.AttackRange then
            targets[player] = entry
            remote:FireClient(player, "Target", model)
        end
    end
    body.ClickDetector.MouseClick:Connect(selectTarget)
    body.ProximityPrompt.Triggered:Connect(function(player)
        local r = root(player)
        if r and (r.CFrame.Position - body.CFrame.Position).Magnitude <= 22 then selectTarget(player) end
    end)
end

local persistence = ProfileStore.new(DataStoreService, RunService:IsStudio(), game.PlaceId)
local initializing = {}
local function validProfile(p)
    if type(p) ~= "table" or type(p.Inventory) ~= "table" or #p.Inventory > Config.MaxInventory or type(p.Equipped) ~= "table" then return false end
    for _, key in ipairs({"Coins", "World", "Unlocked", "Kills", "QuestClaimed"}) do
        if type(p[key]) ~= "number" or p[key] ~= p[key] or p[key] < 0 or p[key] % 1 ~= 0 then return false end
    end
    if not Config.Worlds[p.World] or not Config.Worlds[p.Unlocked] or p.World > p.Unlocked or #p.Equipped > Config.MaxEquipped then return false end
    local ids = {}
    for _, f in ipairs(p.Inventory) do
        if type(f) ~= "table" or type(f.Uid) ~= "string" or ids[f.Uid] or not Config.GetFighter(f.Kind) or not Config.Worlds[f.World] or type(f.Level) ~= "number" or f.Level < 1 or type(f.XP) ~= "number" or f.XP < 0 then return false end
        ids[f.Uid] = true
    end
    local used = {}
    for _, uid in ipairs(p.Equipped) do
        if not ids[uid] or used[uid] then return false end
        used[uid] = true
    end
    return true
end
local function save(player)
    local p = profiles[player]
    if not p then return end
    local ok, err = persistence:Save(player.UserId, p, player:GetAttribute("SessionOnly"))
    if not ok then warn("Falha ao salvar jogador " .. player.UserId .. ": " .. tostring(err)) end
end
local function initializePlayer(player)
    if initializing[player] or profiles[player] then return end
    initializing[player] = true
    local ok, data, sessionOnly = persistence:Load(player.UserId)
    initializing[player] = nil
    if not ok then
        player:Kick("Não foi possível carregar seu progresso. Tente entrar novamente.")
        return
    end
    player:SetAttribute("SessionOnly", sessionOnly)
    if sessionOnly then warn("Modo Studio: progresso temporário; o mapa e os lutadores continuam disponíveis.") end
    if ok and data ~= nil and not validProfile(data) then player:Kick("Seu progresso precisa de revisão. Contate o desenvolvedor."); return end
    if not player.Parent then return end
    profiles[player] = data or newProfile()
    rebuildPets(player)
    local function characterAdded(character)
        local r = character:WaitForChild("HumanoidRootPart", 10)
        if r and profiles[player] then r.CFrame = CFrame.new(spawnPosition(profiles[player].World)) end
    end
    player.CharacterAdded:Connect(characterAdded)
    if player.Character then task.spawn(characterAdded, player.Character) end
    send(player)
end
Players.PlayerAdded:Connect(initializePlayer)
for _, player in ipairs(Players:GetPlayers()) do task.spawn(initializePlayer, player) end
remote.OnServerEvent:Connect(function(player, action, value)
    local p = profiles[player]
    if not p or type(action) ~= "string" then return end
    local now = os.clock()
    if now - (cooldowns[player] or 0) < 0.15 then return end
    cooldowns[player] = now
    if action == "Ready" then send(player)
    elseif action == "Summon" then summon(player)
    elseif action == "Travel" then travel(player, value)
    elseif action == "Stop" then targets[player] = nil
    elseif action == "Quest" then
        if p.Kills >= (p.QuestClaimed + 1) * Config.QuestGoal then
            p.QuestClaimed, p.Coins = p.QuestClaimed + 1, p.Coins + Config.QuestReward
            toast(player, "Missão concluída! +" .. Config.QuestReward .. " moedas")
            send(player)
        else toast(player, "Derrote mais inimigos para concluir a missão.") end
    elseif action == "Best" then
        local sorted = table.clone(p.Inventory)
        table.sort(sorted, function(a, b) return Config.Power(a) > Config.Power(b) end)
        p.Equipped = {}
        for i = 1, math.min(Config.MaxEquipped, #sorted) do table.insert(p.Equipped, sorted[i].Uid) end
        rebuildPets(player); send(player)
    elseif (action == "Equip" or action == "Sell") and type(value) == "string" then
        for i, f in ipairs(p.Inventory) do
            if f.Uid == value then
                local slot = table.find(p.Equipped, value)
                if action == "Equip" then
                    if slot then table.remove(p.Equipped, slot)
                    elseif #p.Equipped < Config.MaxEquipped then table.insert(p.Equipped, value)
                    else toast(player, "Equipe no máximo " .. Config.MaxEquipped .. " lutadores.") end
                elseif not slot and #p.Inventory > 1 then
                    p.Coins = p.Coins + math.floor(Config.Power(f) * 2)
                    table.remove(p.Inventory, i)
                else toast(player, "Desequipe o lutador antes de vender. Mantenha ao menos um.") end
                rebuildPets(player); send(player); break
            end
        end
    end
end)
local attackClock = 0
RunService.Heartbeat:Connect(function(dt)
    attackClock = attackClock + dt
    local attack = attackClock >= Config.AttackInterval
    if attack then attackClock = 0 end
    for player, p in pairs(profiles) do
        local r, enemy = root(player), targets[player]
        if enemy and (enemy.Dead or not r or p.World ~= enemy.World or (r.CFrame.Position - enemy.Body.CFrame.Position).Magnitude > Config.AttackRange) then
            targets[player], enemy = nil, nil
            remote:FireClient(player, "Target", nil)
        end
        local folder = pets[player]
        if r and folder then
            for i, model in ipairs(folder:GetChildren()) do
                local pos
                if enemy then
                    local angle = i * math.pi * 2 / math.max(1, #p.Equipped)
                    pos = enemy.Body.CFrame.Position + Vector3.new(math.cos(angle) * 6, 0, math.sin(angle) * 6)
                else pos = (r.CFrame * CFrame.new((i - 2) * 4, -1, 6)).Position end
                local destination = CFrame.lookAt(pos, enemy and enemy.Body.CFrame.Position or pos + r.CFrame.LookVector)
                model:PivotTo(model:GetPivot():Lerp(destination, math.min(dt * 8, 1)))
            end
        end
        if attack and enemy then
            local damage = 0
            for _, f in ipairs(p.Inventory) do if equipped(p, f.Uid) then damage = damage + Config.Power(f) end end
            enemy.Health = math.max(0, enemy.Health - damage)
            enemy.Label.Text = enemy.Name .. "\n" .. enemy.Health .. " / " .. enemy.MaxHealth
            if damage > 0 then remote:FireClient(player, "Damage", enemy.Body.CFrame.Position, damage) end
            if enemy.Health <= 0 and not enemy.Dead then
                enemy.Dead, targets[player] = true, nil
                p.Coins, p.Kills = p.Coins + enemy.Reward, p.Kills + 1
                for _, f in ipairs(p.Inventory) do
                    if equipped(p, f.Uid) then
                        f.XP = f.XP + 1
                        if f.XP >= f.Level * 5 then f.XP, f.Level = 0, f.Level + 1 end
                    end
                end
                for _, child in ipairs(enemy.Model:GetDescendants()) do
                    if child:IsA("BasePart") then child.Transparency, child.CanCollide = 1, false end
                    if child:IsA("ProximityPrompt") then child.Enabled = false end
                end
                enemy.Label.Text = "Renascendo..."
                toast(player, "+" .. enemy.Reward .. " moedas!")
                rebuildPets(player); send(player)
                remote:FireClient(player, "Target", nil)
                task.delay(7, function()
                    enemy.Health, enemy.Dead = enemy.MaxHealth, false
                    enemy.Label.Text = enemy.Name .. "\n" .. enemy.Health .. " / " .. enemy.MaxHealth
                    for _, child in ipairs(enemy.Model:GetDescendants()) do
                        if child:IsA("BasePart") then child.Transparency, child.CanCollide = 0, false end
                        if child:IsA("ProximityPrompt") then child.Enabled = true end
                    end
                end)
            end
        end
    end
end)
Players.PlayerRemoving:Connect(function(player)
    if not player:GetAttribute("SessionOnly") then save(player) end
    profiles[player], targets[player], cooldowns[player], initializing[player] = nil, nil, nil, nil
    if pets[player] then pets[player]:Destroy(); pets[player] = nil end
end)
task.spawn(function()
    while true do
        task.wait(Config.SaveInterval)
        for player in pairs(profiles) do if not player:GetAttribute("SessionOnly") then save(player) end end
    end
end)
game:BindToClose(function()
    local pending = 0
    for player in pairs(profiles) do
        if not player:GetAttribute("SessionOnly") then
            pending = pending + 1
            task.spawn(function() save(player); pending = pending - 1 end)
        end
    end
    local deadline = os.clock() + 25
    while pending > 0 and os.clock() < deadline do task.wait(0.1) end
end)
