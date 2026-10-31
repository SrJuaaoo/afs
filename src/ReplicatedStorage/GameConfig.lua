local Config = {}
Config.Title = "LENDAS DO ANIME"
Config.MaxEquipped = 3
Config.MaxInventory = 120
Config.AttackRange = 65
Config.AttackInterval = 0.8
Config.SaveInterval = 60
Config.Worlds = {
    {Name = "Vila da Aurora", Cost = 0, SummonCost = 100, Color = Color3.fromRGB(65, 196, 143), Enemy = "Sentinela Sombria", Health = 80, Reward = 35},
    {Name = "Deserto Celeste", Cost = 2500, SummonCost = 650, Color = Color3.fromRGB(244, 183, 76), Enemy = "Guardião das Areias", Health = 700, Reward = 240},
    {Name = "Cidadela Lunar", Cost = 18000, SummonCost = 3500, Color = Color3.fromRGB(147, 116, 244), Enemy = "Cavaleiro do Eclipse", Health = 4500, Reward = 1500},
}
Config.Fighters = {
    {Id = "haru", Name = "Haru da Brisa", Rarity = "Comum", Weight = 55, Power = 8, Color = Color3.fromRGB(126, 195, 233)},
    {Id = "akemi", Name = "Akemi das Chamas", Rarity = "Raro", Weight = 28, Power = 16, Color = Color3.fromRGB(80, 153, 255)},
    {Id = "raiden", Name = "Raiden do Trovão", Rarity = "Épico", Weight = 12, Power = 34, Color = Color3.fromRGB(182, 104, 255)},
    {Id = "hoshi", Name = "Hoshi Estelar", Rarity = "Lendário", Weight = 4, Power = 80, Color = Color3.fromRGB(255, 193, 68)},
    {Id = "yume", Name = "Yume do Infinito", Rarity = "Mítico", Weight = 1, Power = 200, Color = Color3.fromRGB(255, 91, 146)},
}
Config.QuestGoal = 10
Config.QuestReward = 500
function Config.GetFighter(id)
    for _, fighter in ipairs(Config.Fighters) do
        if fighter.Id == id then return fighter end
    end
end
function Config.Power(fighter)
    local base = Config.GetFighter(fighter.Kind)
    return math.floor(base.Power * (1 + (fighter.Level - 1) * 0.2) * (3 ^ (fighter.World - 1)))
end
return Config
