-- Run from the repository root with Lua 5.3+ (or Fengari).
Color3 = {fromRGB = function(r, g, b) return {r = r, g = g, b = b} end}
local Config = dofile("src/ReplicatedStorage/GameConfig.lua")
local total, ids = 0, {}
for _, fighter in ipairs(Config.Fighters) do
    assert(not ids[fighter.Id], "Identificador duplicado")
    ids[fighter.Id] = true
    assert(fighter.Weight > 0 and fighter.Power > 0)
    total = total + fighter.Weight
    assert(Config.GetFighter(fighter.Id) == fighter)
    local initial = Config.Power({Kind = fighter.Id, Level = 1, World = 1})
    assert(initial == fighter.Power)
    assert(Config.Power({Kind = fighter.Id, Level = 2, World = 1}) > initial)
    assert(Config.Power({Kind = fighter.Id, Level = 1, World = 2}) == initial * 3)
end
assert(total == 100, "Probabilidades devem somar 100%")
assert(Config.Worlds[1].Cost == 0 and 300 >= Config.Worlds[1].SummonCost)
for i, world in ipairs(Config.Worlds) do
    assert(world.Health > 0 and world.Reward > 0 and world.SummonCost > 0)
    if i > 1 then assert(world.Cost > Config.Worlds[i - 1].Cost) end
end
print("PASS: probabilidades, IDs, evolução, escala por ilha e economia inicial.")
