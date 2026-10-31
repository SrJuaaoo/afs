local fs = require("@lune/fs")
local roblox = require("@lune/roblox")
local luau = require("@lune/luau")
local World = require("../src/ReplicatedStorage/GameWorld")
local Config = luau.load(fs.readFile("src/ReplicatedStorage/GameConfig.lua"), {
    environment = {Color3 = roblox.Color3, math = math, ipairs = ipairs},
})()

local map = World.Build(Config, roblox)
if not fs.isDir("assets") then fs.writeDir("assets") end
fs.writeFile("assets/LendasWorld.rbxm", roblox.serializeModel({map}))
local camera = roblox.Instance.new("Camera")
camera.Name = "Camera"
camera.CFrame = roblox.CFrame.lookAt(roblox.Vector3.new(110, 95, 145), roblox.Vector3.new(0, 4, 0))
camera.Focus = roblox.CFrame.new(0, 4, 0)
fs.writeFile("assets/Camera.rbxm", roblox.serializeModel({camera}))
print("Mapa pronto: " .. #map:GetDescendants() .. " objetos; três ilhas, 15 inimigos e cinco lutadores de exposição.")
