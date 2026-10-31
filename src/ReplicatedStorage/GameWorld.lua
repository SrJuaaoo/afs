-- Shared by Roblox and the offline place build. No web assets or API access required.
local World = {}

local function engine(api)
    return api or {Instance = Instance, Vector3 = Vector3, CFrame = CFrame, Color3 = Color3, Enum = Enum, UDim2 = UDim2}
end

local function tools(api)
    local I, V, C, E, U = api.Instance, api.Vector3, api.Color3, api.Enum, api.UDim2
    local function part(parent, name, size, position, color, material)
        local p = I.new("Part")
        p.Name, p.Size, p.CFrame, p.Color = name, size, api.CFrame.new(position), color
        p.Anchored, p.TopSurface, p.BottomSurface = true, E.SurfaceType.Smooth, E.SurfaceType.Smooth
        p.Material, p.Parent = material or E.Material.SmoothPlastic, parent
        return p
    end
    local function label(parent, value, color, offset)
        local gui = I.new("BillboardGui")
        gui.Name, gui.Size, gui.StudsOffset = "Nameplate", U.fromOffset(230, 56), V.new(0, offset or 3, 0)
        gui.AlwaysOnTop, gui.MaxDistance, gui.Parent = true, 120, parent
        local t = I.new("TextLabel")
        t.Name, t.Size, t.BackgroundTransparency, t.Text = "Caption", U.fromScale(1, 1), 1, value
        t.TextColor3, t.TextStrokeTransparency, t.TextScaled = color or C.new(1, 1, 1), 0.35, true
        t.Font, t.Parent = E.Font.GothamBold, gui
        return t
    end
    local function prompt(parent, action, object)
        local p = I.new("ProximityPrompt")
        p.ActionText, p.ObjectText, p.HoldDuration = action, object, 0.25
        p.MaxActivationDistance, p.RequiresLineOfSight, p.Parent = 14, false, parent
        return p
    end
    return part, label, prompt
end

function World.CreateFighter(parent, definition, name, position, scale, api)
    api = engine(api)
    local V, C, F, E = api.Vector3, api.Color3, api.CFrame, api.Enum
    local part, label = tools(api)
    local model = api.Instance.new("Model")
    model.Name, model.Parent = name, parent
    scale = scale or 1
    local skin, dark = C.fromRGB(255, 217, 183), C.fromRGB(28, 31, 49)
    local function bodyPiece(n, size, offset, color, material)
        local p = part(model, n, size * scale, position + offset * scale, color, material)
        p.CanCollide, p.CanTouch = false, false
        return p
    end
    local body = bodyPiece("Body", V.new(2, 2, 1), V.new(), definition.Color)
    model.PrimaryPart = body
    local head = bodyPiece("Head", V.new(1.45, 1.45, 1.35), V.new(0, 1.7, 0), skin)
    bodyPiece("LeftArm", V.new(0.7, 1.9, 0.8), V.new(-1.4, 0, 0), definition.Color)
    bodyPiece("RightArm", V.new(0.7, 1.9, 0.8), V.new(1.4, 0, 0), definition.Color)
    bodyPiece("LeftHand", V.new(0.72, 0.5, 0.82), V.new(-1.4, -0.8, 0), skin)
    bodyPiece("RightHand", V.new(0.72, 0.5, 0.82), V.new(1.4, -0.8, 0), skin)
    for _, x in {-0.55, 0.55} do
        bodyPiece(x < 0 and "LeftLeg" or "RightLeg", V.new(0.85, 1.65, 0.9), V.new(x, -1.8, 0), dark)
        bodyPiece("Boot", V.new(0.95, 0.45, 1.2), V.new(x, -2.6, -0.1), definition.Color:Lerp(dark, 0.4))
        bodyPiece("Eye", V.new(0.16, 0.18, 0.08), V.new(x * 0.5, 1.8, -0.7), dark)
    end
    bodyPiece("Belt", V.new(2.08, 0.25, 1.08), V.new(0, -0.75, 0), C.fromRGB(255, 212, 88))
    bodyPiece("Collar", V.new(2.04, 0.25, 1.08), V.new(0, 0.9, 0), dark)
    local hair = definition.Color:Lerp(dark, 0.65)
    bodyPiece("Hair", V.new(1.55, 0.55, 1.4), V.new(0, 2.35, 0), hair)
    for i = -1, 1 do
        local spike = bodyPiece("HairSpike", V.new(0.42, 0.85, 0.9), V.new(i * 0.5, 2.7, 0.1), hair)
        spike.CFrame = spike.CFrame * F.Angles(0, 0, i * -0.3)
    end
    local blade = bodyPiece("Blade", V.new(0.2, 3.5, 0.45), V.new(0.75, 0.3, 0.85), C.fromRGB(215, 239, 255), E.Material.Metal)
    blade.CFrame = blade.CFrame * F.Angles(0, 0, -0.4)
    label(head, definition.Name, definition.Color, 2.7 * scale)
    return model
end

function World.Build(config, api)
    api = engine(api)
    local I, V, C, F, E = api.Instance, api.Vector3, api.Color3, api.CFrame, api.Enum
    local part, label, prompt = tools(api)
    local map = I.new("Folder")
    map.Name = "LendasWorld"
    map:SetAttribute("Version", 2)
    local sea = part(map, "Oceano", V.new(1700, 2, 450), V.new(650, -12, 0), C.fromRGB(42, 142, 185), E.Material.Glass)
    sea.Transparency = 0.25
    local islands = I.new("Folder")
    islands.Name, islands.Parent = "Ilhas", map
    local enemyFolder = I.new("Folder")
    enemyFolder.Name, enemyFolder.Parent = "Inimigos", map
    local showcases = I.new("Folder")
    showcases.Name, showcases.Parent = "GaleriaDeLutadores", map
    for index, world in ipairs(config.Worlds) do
        local x = (index - 1) * 650
        local island = I.new("Model")
        island.Name, island.Parent = world.Name, islands
        island:SetAttribute("WorldIndex", index)
        part(island, "Rocha", V.new(192, 12, 192), V.new(x, -6, 0), C.fromRGB(81, 91, 113), E.Material.Slate)
        part(island, "Terreno", V.new(190, 4, 190), V.new(x, 0, 0), world.Color, index == 2 and E.Material.Sand or E.Material.Grass)
        part(island, "Avenida", V.new(20, 0.25, 155), V.new(x, 2.15, 0), C.fromRGB(228, 217, 193), E.Material.Cobblestone)
        part(island, "Praca", V.new(120, 0.3, 18), V.new(x, 2.2, 20), C.fromRGB(228, 217, 193), E.Material.Cobblestone)
        local sign = part(island, "BoasVindas", V.new(26, 5, 1), V.new(x, 13, 76), C.fromRGB(34, 41, 62), E.Material.Wood)
        label(sign, world.Name .. "\nLENDAS DO ANIME", C.new(1, 1, 1), 0)
        for _, dx in {-12, 12} do part(island, "Poste", V.new(1, 12, 1), V.new(x + dx, 7, 76), C.fromRGB(85, 64, 52), E.Material.Wood) end
        local pedestal = part(island, "Altar", V.new(12, 3, 12), V.new(x - 30, 3.5, 20), C.fromRGB(53, 59, 85), E.Material.Marble)
        local altar = part(island, "Estrela", V.new(4, 4, 4), pedestal.CFrame.Position + V.new(0, 4.5, 0), C.fromRGB(255, 215, 80), E.Material.Neon)
        altar.Shape = E.PartType.Ball
        altar:SetAttribute("SummonWorld", index)
        label(altar, "INVOCAÇÃO\n" .. world.SummonCost .. " moedas", C.fromRGB(255, 232, 130), 5)
        prompt(altar, "Invocar", "Estrela · " .. world.SummonCost .. " moedas")
        if index < #config.Worlds then
            local color = config.Worlds[index + 1].Color
            for _, dx in {-8, 8} do part(island, "PilarDoPortal", V.new(3, 18, 4), V.new(x + dx, 11, -80), C.fromRGB(53, 59, 85), E.Material.Marble) end
            part(island, "ArcoDoPortal", V.new(22, 3, 5), V.new(x, 20, -80), color)
            local portal = part(island, "Portal", V.new(12, 14, 1), V.new(x, 9, -80), color, E.Material.Neon)
            portal.CanCollide, portal.Transparency = false, 0.35
            portal:SetAttribute("Destination", index + 1)
            label(portal, config.Worlds[index + 1].Name .. "\n" .. config.Worlds[index + 1].Cost .. " moedas", nil, 9)
            prompt(portal, "Viajar / desbloquear", config.Worlds[index + 1].Name)
        end
        for n = 1, 12 do
            local angle = n * math.pi / 6
            -- Keep the arrival arch and destination portal clear.
            if n ~= 3 and n ~= 9 then
                local pos = V.new(x + math.cos(angle) * 83, 8, math.sin(angle) * 83)
                part(island, "Tronco", V.new(3, 12, 3), pos, C.fromRGB(101, 74, 62), E.Material.Wood)
                local canopy = part(island, "Copa", V.new(15, 15, 15), pos + V.new(0, 10, 0), world.Color:Lerp(C.fromRGB(30, 90, 75), 0.35))
                canopy.Shape = E.PartType.Ball
            end
        end
        for n, offset in ipairs({V.new(-62, 0, -48), V.new(-62, 0, 59), V.new(48, 0, -63)}) do
            local pos = V.new(x, 0, 0) + offset
            part(island, "Casa", V.new(19, 15, 16), pos + V.new(0, 9.5, 0), C.fromRGB(233, 220, 198), E.Material.Brick)
            part(island, "Telhado", V.new(23, 4, 20), pos + V.new(0, 19, 0), world.Color:Lerp(C.fromRGB(47, 52, 83), 0.6), E.Material.Slate)
            part(island, "Porta", V.new(4, 8, 0.3), pos + V.new(0, 6, 8.2), C.fromRGB(82, 60, 54), E.Material.Wood)
            for _, dx in {-6, 6} do part(island, "Janela", V.new(3, 4, 0.4), pos + V.new(dx, 11, 8.2), C.fromRGB(255, 224, 139), E.Material.Neon) end
        end
        for n = 1, 5 do
            local boss = n == 5
            local pos = V.new(x + ((n - 1) % 3 - 1) * 28, boss and 7.6 or 5, -12 - math.floor((n - 1) / 3) * 32)
            local name = boss and "Chefe " .. world.Enemy or world.Enemy
            local color = boss and C.fromRGB(184, 67, 108) or C.fromRGB(81, 81, 120)
            local model = World.CreateFighter(enemyFolder, {Name = name, Color = color}, "Enemy_" .. index .. "_" .. n, pos, boss and 1.8 or 1, api)
            model:SetAttribute("EnemyName", name)
            model:SetAttribute("WorldIndex", index)
            model:SetAttribute("Boss", boss)
            local health = world.Health * (boss and 8 or 1)
            model.Head.Nameplate.Caption.Text = name .. "\n" .. health .. " / " .. health
            local click = I.new("ClickDetector")
            click.MaxActivationDistance, click.Parent = config.AttackRange, model.Body
            prompt(model.Body, "Atacar", name)
        end
        if index == 1 then
            for n, def in ipairs(config.Fighters) do
                local pos = V.new(x + 63, 7, 52 - (n - 1) * 19)
                part(island, "PedestalDeLutador", V.new(9, 2, 9), pos - V.new(0, 4, 0), def.Color, E.Material.Marble)
                local display = World.CreateFighter(showcases, def, def.Id, pos, 1, api)
                display:SetAttribute("DisplayOnly", true)
                display.Head.Nameplate.Caption.Text = def.Name .. "\n" .. def.Rarity .. " · " .. def.Weight .. "%"
            end
        end
    end
    local spawn = I.new("SpawnLocation")
    spawn.Name, spawn.Size, spawn.CFrame = "Inicio", V.new(10, 1, 10), F.new(0, 2.75, 55)
    spawn.Anchored, spawn.Neutral, spawn.Duration = true, true, 0
    spawn.Color, spawn.Parent = C.fromRGB(239, 232, 208), map
    return map
end

return World
