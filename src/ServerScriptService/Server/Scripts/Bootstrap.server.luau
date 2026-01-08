--!strict

local Players = game:GetService("Players")
local ServerScriptService = game:GetService("ServerScriptService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Server = ServerScriptService:WaitForChild("Server")
local Shared = ReplicatedStorage:WaitForChild("Shared")
local Packages = require(ReplicatedStorage.Shared.Packages)
local HookLoader = require(Server.HookUtil.HookLoader)

local Loader = Packages.Loader
local Trove = Packages.Trove

HookLoader.Configure(Server.Hooks)

local Ensemble = require(Server.Ensemble)

Ensemble.Init({
	Components = Server.Components,
	Archetypes = {
		Player = { "States", "Stats", "Modifiers", "Hooks", "Damage" },
		Enemy = { "States", "Stats", "Modifiers", "Damage" },
	},
})

local Services = Loader.LoadChildren(Server.Services)
Loader.SpawnAll(Services, "Start")

local STATE_CONFIG = require(Shared.Config.StateConfig)
local STAT_CONFIG = require(Shared.Config.StatConfig)

local PlayerTroves: { [Player]: any } = {}

local function SpawnCharacter(Player: Player, PlayerData: { [string]: any })
	local Character = Player.Character
	if not Character then
		return
	end

	if Ensemble.GetEntity(Character) then
		return
	end

	local Humanoid = Character:WaitForChild("Humanoid", 5) :: Humanoid?
	if not Humanoid then
		warn("[Bootstrap] No Humanoid for", Player.Name)
		return
	end

	local Entity = Ensemble.CreateEntity(Character, {
		Player = Player,
		Data = PlayerData,
		EventBus = Ensemble.Events,
		StateConfig = STATE_CONFIG,
		StatConfig = STAT_CONFIG,
	})
		:WithArchetype("Player")
		:Build()

	local Hooks = Entity:GetComponent("Hooks")
	if Hooks then
		Hooks.Register("Regeneration")
	end
end

local function OnPlayerAdded(Player: Player)
	local PlayerTrove = Trove.new()
	PlayerTroves[Player] = PlayerTrove

	local PlayerData = {}

	PlayerTrove:Connect(Player.CharacterAdded, function()
		SpawnCharacter(Player, PlayerData)
	end)

	PlayerTrove:Connect(Player.CharacterRemoving, function(Character)
		Ensemble.DestroyEntity(Character)
	end)

	if Player.Character then
		SpawnCharacter(Player, PlayerData)
	end
end

local function OnPlayerRemoving(Player: Player)
	local PlayerTrove = PlayerTroves[Player]
	if PlayerTrove then
		PlayerTrove:Destroy()
		PlayerTroves[Player] = nil
	end

	local Character = Player.Character
	if Character then
		Ensemble.DestroyEntity(Character)
	end
end

for _, Player in Players:GetPlayers() do
	task.spawn(OnPlayerAdded, Player)
end

Players.PlayerAdded:Connect(OnPlayerAdded)
Players.PlayerRemoving:Connect(OnPlayerRemoving)

print("[Server] Bootstrap complete")