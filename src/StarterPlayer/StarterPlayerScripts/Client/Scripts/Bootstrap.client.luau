--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Packages = require(Shared.Packages)
local Client = Players.LocalPlayer.PlayerScripts:WaitForChild("Client")

local Loader = Packages.Loader

local Controllers = Loader.LoadChildren(Client.Controllers)


Loader.SpawnAll(Controllers, "Init")
Loader.SpawnAll(Controllers, "Start")

print("[Client] Bootstrap complete")