--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Packages = require(Shared.Packages)
local Packets = require(Shared.Network.Packets)

local Trove = Packages.Trove

local EntityController = {}

type Stats = { [string]: number }
type States = { [string]: boolean }

type EntityData = {
	Stats: Stats,
	States: States,
}

type EntityMap = { [Instance]: EntityData }

local LocalPlayer = Players.LocalPlayer :: Player
local Entities: EntityMap = {}
local ControllerTrove = Trove.new()

-- Update all packet events to use strict types when new luau solver resolves this issue.

function EntityController.Start()
	ControllerTrove:Add(Packets.EntitySpawned.OnClientEvent:Connect(function(Character, Data)
		local TypedCharacter = Character :: Instance
		local TypedData = Data :: { Stats: Stats?, States: States? }
		Entities[TypedCharacter] = {
			Stats = TypedData.Stats or {},
			States = TypedData.States or {},
		}
	end))

	ControllerTrove:Add(Packets.EntityDespawned.OnClientEvent:Connect(function(Character)
		local TypedCharacter = Character :: Instance
		Entities[TypedCharacter] = nil
	end))

	ControllerTrove:Add(Packets.StatChanged.OnClientEvent:Connect(function(StatName, NewValue, _OldValue)
		local TypedStatName = StatName :: string
		local TypedNewValue = NewValue :: number
		local Character = LocalPlayer.Character
		if Character and Entities[Character] then
			Entities[Character].Stats[TypedStatName] = TypedNewValue
		end
	end))

	ControllerTrove:Add(Packets.StateChanged.OnClientEvent:Connect(function(StateName, Value)
		local TypedStateName = StateName :: string
		local TypedValue = Value :: boolean
		local Character = LocalPlayer.Character
		if Character and Entities[Character] then
			Entities[Character].States[TypedStateName] = TypedValue
		end
	end))
end

function EntityController.GetEntity(Character: Instance): EntityData?
	return Entities[Character]
end

function EntityController.GetLocalEntity(): EntityData?
	local Character = LocalPlayer.Character
	if not Character then
		return nil
	end
	return Entities[Character]
end

return EntityController