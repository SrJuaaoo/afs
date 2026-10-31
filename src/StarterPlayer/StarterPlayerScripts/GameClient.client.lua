local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local Debris = game:GetService("Debris")
local player = Players.LocalPlayer
local Config = require(ReplicatedStorage:WaitForChild("GameConfig"))
local remote = ReplicatedStorage:WaitForChild("GameEvent")
local state, activeTab = nil, nil
local colors = {Background = Color3.fromRGB(15, 20, 37), Panel = Color3.fromRGB(25, 33, 55), Text = Color3.fromRGB(239, 244, 255), Muted = Color3.fromRGB(159, 175, 203), Accent = Color3.fromRGB(75, 224, 174)}
local gui = Instance.new("ScreenGui")
gui.Name, gui.ResetOnSpawn, gui.ZIndexBehavior = "LendasUI", false, Enum.ZIndexBehavior.Sibling
gui.Parent = player:WaitForChild("PlayerGui")
local function corner(object, radius)
    local c = Instance.new("UICorner")
    c.CornerRadius, c.Parent = UDim.new(0, radius or 12), object
end
local function frame(parent, size, position, color)
    local f = Instance.new("Frame")
    f.Size, f.Position, f.BackgroundColor3, f.BorderSizePixel, f.Parent = size, position, color or colors.Panel, 0, parent
    corner(f)
    return f
end
local function text(parent, value, size, position, fontSize, color)
    local t = Instance.new("TextLabel")
    t.Size, t.Position, t.Text, t.TextSize = size, position, value, fontSize or 16
    t.BackgroundTransparency, t.TextColor3, t.Font = 1, color or colors.Text, Enum.Font.GothamBold
    t.TextWrapped, t.Parent = true, parent
    return t
end
local function button(parent, value, size, position, callback, color)
    local b = Instance.new("TextButton")
    b.Size, b.Position, b.Text, b.TextSize = size, position, value, 15
    b.BackgroundColor3, b.TextColor3, b.Font = color or colors.Accent, colors.Background, Enum.Font.GothamBold
    b.BorderSizePixel, b.TextWrapped, b.Parent = 0, true, parent
    corner(b, 9)
    b.Activated:Connect(callback)
    return b
end
local function number(n)
    if n >= 1000000 then return string.format("%.1f mi", n / 1000000) end
    if n >= 1000 then return string.format("%.1f mil", n / 1000) end
    return tostring(n)
end
local header = frame(gui, UDim2.new(1, -32, 0, 76), UDim2.fromOffset(16, 12), colors.Background)
local title = text(header, Config.Title, UDim2.new(0.5, 0, 0, 30), UDim2.fromOffset(12, 9), 21)
title.TextXAlignment = Enum.TextXAlignment.Left
local subtitle = text(header, "INVOQUE. EVOLUA. CONQUISTE.", UDim2.new(0.5, 0, 0, 20), UDim2.fromOffset(12, 41), 11, colors.Muted)
subtitle.TextXAlignment = Enum.TextXAlignment.Left
local coins = text(header, "Carregando...", UDim2.new(0.46, 0, 0, 30), UDim2.new(0.53, 0, 0, 9), 19, Color3.fromRGB(255, 213, 93))
local power = text(header, "", UDim2.new(0.46, 0, 0, 20), UDim2.new(0.53, 0, 0, 43), 12, colors.Muted)
local nav = frame(gui, UDim2.new(1, -32, 0, 54), UDim2.new(0, 16, 1, -68), colors.Background)
local modal = frame(gui, UDim2.new(0.9, 0, 0.64, 0), UDim2.fromScale(0.05, 0.19), colors.Background)
local constraint = Instance.new("UISizeConstraint")
constraint.MaxSize, constraint.Parent = Vector2.new(820, 620), modal
modal.AnchorPoint, modal.Position, modal.Visible = Vector2.new(0.5, 0.5), UDim2.fromScale(0.5, 0.51), false
local heading = text(modal, "", UDim2.new(1, -75, 0, 45), UDim2.fromOffset(15, 6), 23)
heading.TextXAlignment = Enum.TextXAlignment.Left
button(modal, "X", UDim2.fromOffset(36, 34), UDim2.new(1, -46, 0, 10), function() modal.Visible = false; activeTab = nil end, Color3.fromRGB(255, 117, 141))
local content = Instance.new("ScrollingFrame")
content.Position, content.Size = UDim2.fromOffset(12, 60), UDim2.new(1, -24, 1, -72)
content.BackgroundTransparency, content.BorderSizePixel, content.ScrollBarThickness = 1, 0, 5
content.AutomaticCanvasSize, content.CanvasSize, content.Parent = Enum.AutomaticSize.Y, UDim2.new(), modal
local layout = Instance.new("UIListLayout")
layout.Padding, layout.SortOrder, layout.Parent = UDim.new(0, 10), Enum.SortOrder.LayoutOrder, content
local toastLabel = text(gui, "", UDim2.new(0.9, 0, 0, 48), UDim2.fromScale(0.05, 0.12), 18, Color3.fromRGB(255, 230, 135))
toastLabel.TextStrokeTransparency = 0.45
local toastSequence = 0
local function toast(message)
    toastSequence = toastSequence + 1
    local sequence = toastSequence
    toastLabel.Text = message
    task.delay(4, function() if sequence == toastSequence then toastLabel.Text = "" end end)
end
local function row(height)
    return frame(content, UDim2.new(1, -8, 0, height or 85), UDim2.new(), colors.Panel)
end
local render
local function open(tab)
    activeTab = tab
    modal.Visible = true
    render()
end
render = function()
    if not state then return end
    coins.Text = "MOEDAS  " .. number(state.Coins)
    local damage = 0
    for _, f in ipairs(state.Inventory) do if table.find(state.Equipped, f.Uid) then damage = damage + Config.Power(f) end end
    power.Text = "Poder: " .. number(damage) .. "  •  Equipe: " .. #state.Equipped .. "/" .. Config.MaxEquipped
    if not activeTab then return end
    for _, child in ipairs(content:GetChildren()) do if child:IsA("GuiObject") then child:Destroy() end end
    if activeTab == "Lutadores" then
        heading.Text = "Seus lutadores · " .. #state.Inventory .. "/" .. Config.MaxInventory
        local top = row(48)
        button(top, "Equipar melhores", UDim2.new(1, -20, 1, -10), UDim2.fromOffset(10, 5), function() remote:FireServer("Best") end)
        local sorted = table.clone(state.Inventory)
        table.sort(sorted, function(a, b) return Config.Power(a) > Config.Power(b) end)
        for _, f in ipairs(sorted) do
            local def, r = Config.GetFighter(f.Kind), row(105)
            local equipped = table.find(state.Equipped, f.Uid) ~= nil
            local name = text(r, def.Name .. " · Nv. " .. f.Level, UDim2.new(1, -20, 0, 28), UDim2.fromOffset(10, 4), 17, def.Color)
            name.TextXAlignment = Enum.TextXAlignment.Left
            local detail = text(r, def.Rarity .. "  •  Poder " .. number(Config.Power(f)) .. "  •  XP " .. f.XP .. "/" .. f.Level * 5, UDim2.new(1, -20, 0, 20), UDim2.fromOffset(10, 33), 12, colors.Muted)
            detail.TextXAlignment = Enum.TextXAlignment.Left
            button(r, equipped and "Desequipar" or "Equipar", UDim2.new(0.48, -10, 0, 32), UDim2.fromOffset(10, 63), function() remote:FireServer("Equip", f.Uid) end, equipped and Color3.fromRGB(132, 162, 215) or colors.Accent)
            button(r, "Vender · " .. number(math.floor(Config.Power(f) * 2)), UDim2.new(0.48, -10, 0, 32), UDim2.new(0.52, 0, 0, 63), function()
                heading.Text = "Confirmar venda de " .. def.Name .. "?"
                for _, child in ipairs(content:GetChildren()) do if child:IsA("GuiObject") then child:Destroy() end end
                local confirm = row(100)
                text(confirm, "Esta venda é permanente.", UDim2.new(1, -20, 0, 38), UDim2.fromOffset(10, 4), 16)
                button(confirm, "Confirmar venda", UDim2.new(0.48, -10, 0, 38), UDim2.fromOffset(10, 50), function() remote:FireServer("Sell", f.Uid) end, Color3.fromRGB(255, 141, 154))
                button(confirm, "Cancelar", UDim2.new(0.48, -10, 0, 38), UDim2.new(0.52, 0, 0, 50), render)
            end, Color3.fromRGB(255, 174, 143))
        end
    elseif activeTab == "Ilhas" then
        heading.Text = "Explore as ilhas"
        for i, world in ipairs(Config.Worlds) do
            local r = row(105)
            text(r, world.Name, UDim2.new(1, -20, 0, 32), UDim2.fromOffset(10, 5), 20, world.Color)
            text(r, i <= state.Unlocked and "Ilha desbloqueada" or "Desbloqueio: " .. number(world.Cost) .. " moedas", UDim2.new(1, -20, 0, 24), UDim2.fromOffset(10, 37), 13, colors.Muted)
            button(r, state.World == i and "Você está aqui" or (i <= state.Unlocked and "Viajar" or "Desbloquear e viajar"), UDim2.new(1, -20, 0, 30), UDim2.fromOffset(10, 67), function() remote:FireServer("Travel", i) end, world.Color)
        end
    elseif activeTab == "Invocar" then
        local world = Config.Worlds[state.World]
        heading.Text = "Estrela · " .. world.Name
        local r = row(115)
        text(r, "Aproxime-se da estrela dourada na ilha.\nCada invocação custa " .. number(world.SummonCost) .. " moedas.", UDim2.new(1, -20, 0, 60), UDim2.fromOffset(10, 3), 16)
        button(r, "INVOCAR LUTADOR", UDim2.new(1, -20, 0, 38), UDim2.fromOffset(10, 68), function() remote:FireServer("Summon") end, Color3.fromRGB(255, 211, 94))
        for _, def in ipairs(Config.Fighters) do
            local chance = row(50)
            text(chance, def.Name .. " · " .. def.Rarity .. " · " .. def.Weight .. "%", UDim2.new(1, -20, 1, 0), UDim2.fromOffset(10, 0), 15, def.Color)
        end
    elseif activeTab == "Missões" then
        heading.Text = "Missão · Patrulha das ilhas"
        local r = row(160)
        local progress = math.min(Config.QuestGoal, math.max(0, state.Kills - state.QuestClaimed * Config.QuestGoal))
        text(r, "Derrote " .. Config.QuestGoal .. " inimigos\nProgresso: " .. progress .. "/" .. Config.QuestGoal .. "\nRecompensa: " .. Config.QuestReward .. " moedas", UDim2.new(1, -20, 0, 90), UDim2.fromOffset(10, 6), 18)
        button(r, "Resgatar recompensa", UDim2.new(1, -20, 0, 40), UDim2.fromOffset(10, 108), function() remote:FireServer("Quest") end)
        local help = row(110)
        text(help, "COMO JOGAR\nToque ou clique no corpo de um inimigo para enviar sua equipe. Aproxime-se para manter o combate. Lutadores equipados ganham XP a cada vitória.", UDim2.new(1, -24, 1, -12), UDim2.fromOffset(12, 6), 14, colors.Muted)
    end
end
for i, tab in ipairs({"Lutadores", "Invocar", "Ilhas", "Missões"}) do
    button(nav, tab, UDim2.new(0.25, -10, 1, -12), UDim2.new((i - 1) * 0.25, 5, 0, 6), function() open(tab) end, i == 2 and Color3.fromRGB(255, 211, 94) or colors.Accent)
end
local stop = button(gui, "PARAR ATAQUE", UDim2.fromOffset(160, 34), UDim2.new(0.5, -80, 1, -112), function() remote:FireServer("Stop") end, Color3.fromRGB(255, 141, 154))
stop.Visible = false
local highlight = Instance.new("Highlight")
highlight.FillTransparency, highlight.OutlineColor, highlight.Parent = 0.85, colors.Accent, workspace
local reveal = frame(gui, UDim2.fromScale(0.84, 0.32), UDim2.fromScale(0.08, 0.33), colors.Background)
reveal.Visible = false
local revealTitle = text(reveal, "", UDim2.new(1, -24, 0.35, 0), UDim2.fromOffset(12, 12), 25)
local revealDetail = text(reveal, "", UDim2.new(1, -24, 0.25, 0), UDim2.new(0, 12, 0.4, 0), 18)
button(reveal, "Continuar", UDim2.new(1, -32, 0, 40), UDim2.new(0, 16, 1, -52), function() reveal.Visible = false end)
remote.OnClientEvent:Connect(function(action, value, extra)
    if action == "State" then
        local first = state == nil
        state = value
        render()
        if first then
            toast("Bem-vindo! Clique em um inimigo ou abra Missões para aprender.")
            if player:GetAttribute("SessionOnly") then toast("Modo Studio: progresso apenas nesta sessão.") end
        end
    elseif action == "Toast" then toast(value)
    elseif action == "Target" then highlight.Adornee, stop.Visible = value, value ~= nil
    elseif action == "Summoned" then
        local def = Config.GetFighter(value.Kind)
        revealTitle.Text, revealTitle.TextColor3 = def.Name, def.Color
        revealDetail.Text = def.Rarity .. " · Poder " .. number(Config.Power(value))
        reveal.Visible = true
    elseif action == "Damage" then
        local anchor = Instance.new("Part")
        anchor.Anchored, anchor.CanCollide, anchor.Transparency, anchor.Size = true, false, 1, Vector3.new(1, 1, 1)
        anchor.Position, anchor.Parent = value + Vector3.new(0, 5, 0), workspace
        local board = Instance.new("BillboardGui")
        board.Size, board.AlwaysOnTop, board.Parent = UDim2.fromOffset(160, 50), true, anchor
        local amount = text(board, "−" .. number(extra), UDim2.fromScale(1, 1), UDim2.new(), 30, Color3.fromRGB(255, 219, 107))
        amount.TextStrokeTransparency = 0.2
        TweenService:Create(anchor, TweenInfo.new(0.8), {Position = anchor.Position + Vector3.new(0, 4, 0)}):Play()
        TweenService:Create(amount, TweenInfo.new(0.8), {TextTransparency = 1}):Play()
        Debris:AddItem(anchor, 1)
    end
end)
task.spawn(function()
    while not state do remote:FireServer("Ready"); task.wait(1) end
end)
