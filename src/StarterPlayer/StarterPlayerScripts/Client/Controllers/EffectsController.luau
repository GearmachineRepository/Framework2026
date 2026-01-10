--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Packages = require(Shared.Packages)
local Packets = require(Shared.Network.Packets)
local ObjectPool = require(Shared.Utils.ObjectPool)

local Trove = Packages.Trove
local Signal = Packages.Signal

export type EffectConfig = {
	Scale: number?,
	Duration: number?,
	Color: Color3?,
	Direction: Vector3?,
	QualityMultiplier: number?,
	[string]: any,
}

export type PoolConfig = ObjectPool.PoolConfig<Instance>

export type EffectDefinition = {
	Create: ((Position: Vector3, Config: EffectConfig) -> Instance?)?,
	Configure: ((Object: Instance, Position: Vector3, Config: EffectConfig) -> ())?,
	Duration: number?,
	PoolConfig: PoolConfig?,
}

type EffectPool = ObjectPool.ObjectPool<Instance>

local EffectsController = {}

local ControllerTrove: typeof(Trove.new()) = Trove.new()
local LocalPlayer = Players.LocalPlayer :: Player
local RegisteredEffects: { [string]: EffectDefinition } = {}
local EffectPools: { [string]: EffectPool } = {}
local SettingsController: any = nil

EffectsController.EffectSpawned = Signal.new()

local function GetVfxQuality(): number
	if SettingsController then
		return SettingsController.GetSetting("VfxQuality") :: number
	end
	return 1
end

local function GetVfxRenderDistance(): number
	if SettingsController then
		local Value = SettingsController.GetSetting("VfxRenderDistance") :: number
		return Value * 200
	end
	return 200
end

local function GetPlayerPosition(): Vector3?
	local Character = LocalPlayer.Character
	if not Character then
		return nil
	end

	local Root = Character:FindFirstChild("HumanoidRootPart") :: BasePart?
	if not Root then
		return nil
	end

	return Root.Position
end

local function IsWithinRenderDistance(Position: Vector3): boolean
	local PlayerPosition = GetPlayerPosition()
	if not PlayerPosition then
		return true
	end

	local MaxDistance = GetVfxRenderDistance()
	return (Position - PlayerPosition).Magnitude <= MaxDistance
end

local function BuildEffectConfig(Config: EffectConfig?, QualityMultiplier: number): EffectConfig
	local Result: EffectConfig = {
		QualityMultiplier = QualityMultiplier,
	}

	if Config then
		for Key, Value in Config do
			Result[Key] = Value
		end
		Result.QualityMultiplier = QualityMultiplier
	end

	return Result
end

function EffectsController.Init()
	local Client = LocalPlayer.PlayerScripts:WaitForChild("Client")
	local Effects = Client:WaitForChild("Effects")
	local Definitions = require(Effects.EffectDefinitions) :: { [string]: EffectDefinition }

	for EffectName, Definition in Definitions do
		EffectsController.RegisterEffect(EffectName, Definition)
	end
end

function EffectsController.Start()
	local Controllers = script.Parent
	SettingsController = require(Controllers.SettingsController)

	ControllerTrove:Add(Packets.SpawnEffect.OnClientEvent:Connect(function(EffectName: unknown, Position: unknown, Config: unknown)
		if typeof(EffectName) ~= "string" then
			return
		end

		if typeof(Position) ~= "Vector3" then
			return
		end

		local TypedConfig: EffectConfig? = nil
		if typeof(Config) == "table" then
			TypedConfig = Config :: EffectConfig
		end

		EffectsController.SpawnEffect(EffectName, Position, TypedConfig)
	end))
end

function EffectsController.RegisterEffect(EffectName: string, Definition: EffectDefinition)
	if Definition.PoolConfig and not Definition.Configure then
		warn(string.format("[EffectsController] Effect '%s' has PoolConfig but no Configure function", EffectName))
		return
	end

	if not Definition.Create and not Definition.Configure then
		warn(string.format("[EffectsController] Effect '%s' must have Create or Configure function", EffectName))
		return
	end

	RegisteredEffects[EffectName] = Definition

	if Definition.PoolConfig then
		EffectPools[EffectName] = ObjectPool.new(Definition.PoolConfig)
	end
end

function EffectsController.UnregisterEffect(EffectName: string)
	RegisteredEffects[EffectName] = nil

	local Pool = EffectPools[EffectName]
	if Pool then
		Pool:Destroy()
		EffectPools[EffectName] = nil
	end
end

function EffectsController.SpawnEffect(EffectName: string, Position: Vector3, Config: EffectConfig?): Instance?
	if not IsWithinRenderDistance(Position) then
		return nil
	end

	local Definition = RegisteredEffects[EffectName]
	if not Definition then
		warn(string.format("[EffectsController] Unknown effect: %s", EffectName))
		return nil
	end

	local QualityMultiplier = GetVfxQuality()
	local AdjustedConfig = BuildEffectConfig(Config, QualityMultiplier)
	local Duration = (Config and Config.Duration) or Definition.Duration or 2

	local EffectInstance: Instance?
	local Pool = EffectPools[EffectName]

	if Pool and Definition.Configure then
		local PooledObject = Pool:Get()
		Definition.Configure(PooledObject, Position, AdjustedConfig)
		PooledObject.Parent = workspace
		EffectInstance = PooledObject

		EffectsController.EffectSpawned:Fire(EffectName, PooledObject, Position)

		task.delay(Duration, function()
			Pool:Return(PooledObject)
		end)
	elseif Definition.Create then
		EffectInstance = Definition.Create(Position, AdjustedConfig)

		if EffectInstance then
			EffectsController.EffectSpawned:Fire(EffectName, EffectInstance, Position)

			task.delay(Duration, function()
				if EffectInstance and EffectInstance.Parent then
					EffectInstance:Destroy()
				end
			end)
		end
	end

	return EffectInstance
end

function EffectsController.GetPool(EffectName: string): EffectPool?
	return EffectPools[EffectName]
end

function EffectsController.HasEffect(EffectName: string): boolean
	return RegisteredEffects[EffectName] ~= nil
end

function EffectsController.GetQualityMultiplier(): number
	return GetVfxQuality()
end

function EffectsController.ApplyQualityToCount(BaseCount: number): number
	local Multiplier = GetVfxQuality()
	return math.max(1, math.floor(BaseCount * Multiplier))
end

function EffectsController.IsWithinRenderDistance(Position: Vector3): boolean
	return IsWithinRenderDistance(Position)
end

return EffectsController