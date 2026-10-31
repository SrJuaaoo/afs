local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local DataStoreService = game:GetService("DataStoreService")
local HttpService = game:GetService("HttpService")
local RunService = game:GetService("RunService")
local Config = require(ReplicatedStorage:WaitForChild("GameConfig"))
local remote = Instance.new("RemoteEvent")
remote.Name = "GameEvent"
remote.Parent = ReplicatedStorage
local store = DataStoreService:GetDataStore("LendasDoAnime_v1")
local profiles, targets, cooldowns, enemies, pets = {}, {}, {}, {}, {}
local random = Random.new()
local map = Instance.new("Folder")
map.Name = "LendasWorld"
map.Parent = workspace
workspace.FallenPartsDestroyHeight = -100
game:GetService("Lighting").ClockTime = 14
game:GetService("Lighting").Brightness = 2

local function part(name, size, position, color, parent)
    local p = Instance.new("Part")
    p.Name, p.Size, p.Position, p.Color = name, size, position, color
    p.Anchored, p.TopSurface, p.BottomSurface = true, Enum.SurfaceType.Smooth, Enum.SurfaceType.Smooth
    p.Parent = parent or map
    return p
end
local function label(adornee, text, color, offset)
    local gui = Instance.new("BillboardGui")
    gui.Size, gui.StudsOffset, gui.AlwaysOnTop = UDim2.fromOffset(240, 60), Vector3.new(0, offset or 5, 0), true
    gui.Parent = adornee
    local t = Instance.new("TextLabel")
    t.Size, t.BackgroundTransparency, t.Text = UDim2.fromScale(1, 1), 1, text
    t.TextColor3, t.TextStrokeTransparency, t.TextScaled = color or Color3.new(1, 1, 1), 0.4, true
    t.Font, t.Parent = Enum.Font.GothamBold, gui
    return t
end
local function prompt(parent, action, object, callback)
    local p = Instance.new("ProximityPrompt")
    p.ActionText, p.ObjectText, p.HoldDuration = action, object, 0.25
    p.MaxActivationDistance, p.RequiresLineOfSight, p.Parent = 14, false, parent
    p.Triggered:Connect(callback)
end
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
            local model = Instance.new("Model")
            model.Name, model.Parent = f.Uid, folder
            local body = part("Body", Vector3.new(1.6, 2, 1), spawnPosition(1), definition.Color, model)
            local head = part("Head", Vector3.new(1.2, 1.2, 1.2), body.Position + Vector3.new(0, 1.6, 0), Color3.fromRGB(255, 217, 183), model)
            body.CanCollide, head.CanCollide = false, false
            model.PrimaryPart = body
            label(head, definition.Name .. " · Nv. " .. f.Level, definition.Color, 2.5)
        end
    end
end
local function summon(player)
    local p, r = profiles[player], root(player)
    if not p or not r then return end
    local altar = Vector3.new((p.World - 1) * 650 - 30, 4, 20)
    if (r.Position - altar).Magnitude > 22 then toast(player, "Aproxime-se da Estrela de Invocação!"); return end
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

for index, world in ipairs(Config.Worlds) do
    local x = (index - 1) * 650
    part(world.Name, Vector3.new(190, 4, 190), Vector3.new(x, 0, 0), world.Color)
    part("Caminho", Vector3.new(20, 0.2, 155), Vector3.new(x, 2.1, 0), Color3.fromRGB(225, 215, 194))
    local sign = part("Placa", Vector3.new(1, 1, 1), Vector3.new(x, 10, 75), world.Color)
    sign.Transparency, sign.CanCollide = 1, false
    label(sign, world.Name, Color3.new(1, 1, 1), 0)
    local altar = part("Estrela", Vector3.new(5, 5, 5), Vector3.new(x - 30, 5, 20), Color3.fromRGB(255, 215, 80))
    altar.Material, altar.Shape = Enum.Material.Neon, Enum.PartType.Ball
    label(altar, "INVOCAÇÃO\n" .. world.SummonCost .. " moedas", Color3.fromRGB(255, 232, 130))
    prompt(altar, "Invocar", "Estrela · " .. world.SummonCost .. " moedas", summon)
    if index < #Config.Worlds then
        local portal = part("Portal", Vector3.new(12, 14, 2), Vector3.new(x, 9, -80), Config.Worlds[index + 1].Color)
        portal.Material, portal.CanCollide = Enum.Material.Neon, false
        label(portal, Config.Worlds[index + 1].Name .. "\n" .. Config.Worlds[index + 1].Cost .. " moedas", nil, 10)
        prompt(portal, "Viajar / desbloquear", Config.Worlds[index + 1].Name, function(player) travel(player, index + 1) end)
    end
    for n = 1, 12 do
        local angle = n * math.pi / 6
        local pos = Vector3.new(x + math.cos(angle) * 78, 8, math.sin(angle) * 78)
        part("Tronco", Vector3.new(3, 12, 3), pos, Color3.fromRGB(101, 74, 62))
        local canopy = part("Copa", Vector3.new(15, 15, 15), pos + Vector3.new(0, 10, 0), world.Color:Lerp(Color3.fromRGB(30, 90, 75), 0.4))
        canopy.Shape = Enum.PartType.Ball
    end
    for n = 1, 5 do
        local boss = n == 5
        local pos = Vector3.new(x + ((n - 1) % 3 - 1) * 28, 6, -12 - math.floor((n - 1) / 3) * 32)
        local model = Instance.new("Model")
        model.Name, model.Parent = boss and "Chefe " .. world.Enemy or world.Enemy, map
        local body = part("Body", boss and Vector3.new(6, 7, 4) or Vector3.new(3, 4, 2), pos, boss and Color3.fromRGB(166, 64, 104) or Color3.fromRGB(65, 64, 90), model)
        local head = part("Head", Vector3.new(2.5, 2.5, 2.5), pos + Vector3.new(0, boss and 5 or 3, 0), Color3.fromRGB(200, 177, 190), model)
        model.PrimaryPart = body
        local health = world.Health * (boss and 8 or 1)
        local entry = {Model = model, Body = body, Head = head, World = index, Health = health, MaxHealth = health, Reward = world.Reward * (boss and 6 or 1), Dead = false}
        entry.Label = label(head, model.Name .. "\n" .. health .. " / " .. health, nil, 4)
        enemies[model] = entry
        local click = Instance.new("ClickDetector")
        click.MaxActivationDistance, click.Parent = Config.AttackRange, body
        click.MouseClick:Connect(function(player)
            local p, r = profiles[player], root(player)
            if p and r and p.World == index and not entry.Dead and (r.Position - body.Position).Magnitude <= Config.AttackRange then
                targets[player] = entry
                remote:FireClient(player, "Target", model)
            end
        end)
        prompt(body, "Atacar", model.Name, function(player)
            local p, r = profiles[player], root(player)
            if p and r and p.World == index and not entry.Dead and (r.Position - body.Position).Magnitude <= 22 then
                targets[player] = entry
                remote:FireClient(player, "Target", model)
            end
        end)
    end
end
local spawn = Instance.new("SpawnLocation")
spawn.Size, spawn.Position, spawn.Anchored, spawn.Neutral = Vector3.new(10, 1, 10), spawnPosition(1) - Vector3.new(0, 3, 0), true, true
spawn.Color, spawn.Parent = Color3.fromRGB(240, 240, 255), map
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
    local ok, err = pcall(function() store:SetAsync("Player_" .. player.UserId, p) end)
    if not ok then warn("Falha ao salvar jogador " .. player.UserId .. ": " .. tostring(err)) end
end
Players.PlayerAdded:Connect(function(player)
    local ok, data = pcall(function() return store:GetAsync("Player_" .. player.UserId) end)
    if not ok then
        if RunService:IsStudio() then
            data = nil
            player:SetAttribute("SessionOnly", true)
            warn("DataStore indisponível no Studio; progresso somente nesta sessão.")
        else player:Kick("Não foi possível carregar seu progresso. Tente entrar novamente."); return end
    end
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
end)
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
        if enemy and (enemy.Dead or not r or p.World ~= enemy.World or (r.Position - enemy.Body.Position).Magnitude > Config.AttackRange) then
            targets[player], enemy = nil, nil
            remote:FireClient(player, "Target", nil)
        end
        local folder = pets[player]
        if r and folder then
            for i, model in ipairs(folder:GetChildren()) do
                local pos
                if enemy then
                    local angle = i * math.pi * 2 / math.max(1, #p.Equipped)
                    pos = enemy.Body.Position + Vector3.new(math.cos(angle) * 6, 0, math.sin(angle) * 6)
                else pos = (r.CFrame * CFrame.new((i - 2) * 4, -1, 6)).Position end
                local destination = CFrame.lookAt(pos, enemy and enemy.Body.Position or pos + r.CFrame.LookVector)
                model:PivotTo(model:GetPivot():Lerp(destination, math.min(dt * 8, 1)))
            end
        end
        if attack and enemy then
            local damage = 0
            for _, f in ipairs(p.Inventory) do if equipped(p, f.Uid) then damage = damage + Config.Power(f) end end
            enemy.Health = math.max(0, enemy.Health - damage)
            enemy.Label.Text = enemy.Model.Name .. "\n" .. enemy.Health .. " / " .. enemy.MaxHealth
            if damage > 0 then remote:FireClient(player, "Damage", enemy.Body.Position, damage) end
            if enemy.Health <= 0 and not enemy.Dead then
                enemy.Dead, targets[player] = true, nil
                p.Coins, p.Kills = p.Coins + enemy.Reward, p.Kills + 1
                for _, f in ipairs(p.Inventory) do
                    if equipped(p, f.Uid) then
                        f.XP = f.XP + 1
                        if f.XP >= f.Level * 5 then f.XP, f.Level = 0, f.Level + 1 end
                    end
                end
                for _, child in ipairs(enemy.Model:GetChildren()) do if child:IsA("BasePart") then child.Transparency, child.CanCollide = 1, false end end
                enemy.Label.Text = "Renascendo..."
                toast(player, "+" .. enemy.Reward .. " moedas!")
                rebuildPets(player); send(player)
                remote:FireClient(player, "Target", nil)
                task.delay(7, function()
                    enemy.Health, enemy.Dead = enemy.MaxHealth, false
                    enemy.Label.Text = enemy.Model.Name .. "\n" .. enemy.Health .. " / " .. enemy.MaxHealth
                    for _, child in ipairs(enemy.Model:GetChildren()) do if child:IsA("BasePart") then child.Transparency, child.CanCollide = 0, true end end
                end)
            end
        end
    end
end)
Players.PlayerRemoving:Connect(function(player)
    if not player:GetAttribute("SessionOnly") then save(player) end
    profiles[player], targets[player], cooldowns[player] = nil, nil, nil
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
