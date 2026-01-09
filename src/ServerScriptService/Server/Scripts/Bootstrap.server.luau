--!strict

local ServerScriptService = game:GetService("ServerScriptService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Server = ServerScriptService:WaitForChild("Server")
local Shared = ReplicatedStorage:WaitForChild("Shared")
local Packages = require(Shared.Packages)

local Loader = Packages.Loader
local Ensemble = require(Server.Ensemble)
local HookLoader = require(Server.HookUtil.HookLoader)

HookLoader.Configure(Server.Hooks)

Ensemble.Init({
	Components = Server.Components,
	Archetypes = {
		Player = { "Stats", "States", "Modifiers", "Combat", "Inventory" },
		Enemy = { "Stats", "States", "Modifiers", "Combat" },
	},
})

local Services = Loader.LoadChildren(Server.Services)
Loader.SpawnAll(Services, "Init")
Loader.SpawnAll(Services, "Start")

print("[Server] Bootstrap complete")