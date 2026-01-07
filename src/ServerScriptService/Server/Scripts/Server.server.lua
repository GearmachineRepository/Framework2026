--!strict

local Players = game:GetService("Players")
local ServerScriptService = game:GetService("ServerScriptService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Server = ServerScriptService:WaitForChild("Server")
local Shared = ReplicatedStorage:WaitForChild("Shared")

local Ensemble = require(Server.Ensemble)
local Signal = require(Shared.Utils.Signal)
local Maid = require(Shared.Utils.Maid)
local HookLoader = require(Server.Game.Utils.HookLoader)
local HookComponent = require(Server.Game.Components.HookComponent)

HookLoader.Configure(Server.Game.Hooks)

Ensemble.Init({
	Components = Server.Game.Components,
	Signal = Signal.new,
	Archetypes = {
		Player = { "States", "Stats", "Modifiers", "Hooks", "Damage" },
		Enemy = { "States", "Stats", "Modifiers", "Damage" },
	},
})

local STATE_CONFIG = {
	Attacking = { Default = false, Replicate = true, Conflicts = { "Blocking" } },
	Blocking = { Default = false, Replicate = true, Conflicts = { "Attacking" } },
	Stunned = { Default = false, Replicate = true },
	Invulnerable = { Default = false, Replicate = true },
	InCombat = { Default = false, Replicate = true },
}

local STAT_CONFIG = {
	Health = { Default = 100, Min = 0, Max = 100, Replicate = true },
	MaxHealth = { Default = 100, Min = 1, Replicate = true },
	Stamina = { Default = 100, Min = 0, Max = 100, Replicate = true },
	MaxStamina = { Default = 100, Min = 1, Replicate = true },
}

local PlayerMaids: { [Player]: any } = {}

local function SpawnCharacter(Player: Player, PlayerData: any)
	local Character = Player.Character
	if not Character then
		return
	end

	if Ensemble.GetEntity(Character) then
		return
	end

	local Humanoid = Character:WaitForChild("Humanoid", 5) :: Humanoid?
	if not Humanoid then
		warn("No Humanoid for", Player.Name)
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

	local Hooks = HookComponent.From(Entity)
	if Hooks then
		Hooks.Register("Regeneration")
	end
end

Players.PlayerAdded:Connect(function(Player: Player)
	local PlayerMaid = Maid.new()
	PlayerMaids[Player] = PlayerMaid

	local PlayerData = {}

	Player.CharacterAdded:Connect(function()
		SpawnCharacter(Player, PlayerData)
	end)

	Player.CharacterRemoving:Connect(function(Character)
		Ensemble.DestroyEntity(Character)
	end)

	if Player.Character then
		SpawnCharacter(Player, PlayerData)
	end
end)

Players.PlayerRemoving:Connect(function(Player: Player)
	local PlayerMaid = PlayerMaids[Player]
	if PlayerMaid then
		PlayerMaid:DoCleaning()
		PlayerMaids[Player] = nil
	end

	local Character = Player.Character
	if Character then
		Ensemble.DestroyEntity(Character)
	end
end)