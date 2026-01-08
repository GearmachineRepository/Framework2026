--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Shared = ReplicatedStorage:WaitForChild("Shared")
local Packet = require(Shared.Packages.Packet)

local Packets = {
	StatChanged = Packet(
		"StatChanged",
		Packet.String,
		Packet.NumberF32,
		Packet.NumberF32
	),

	StateChanged = Packet(
		"StateChanged",
		Packet.String,
		Packet.Boolean8
	),

	DamageDealt = Packet(
		"DamageDealt",
		Packet.NumberF32,
		Packet.Instance,
		Packet.Vector3F32
	),

	EffectTriggered = Packet(
		"EffectTriggered",
		Packet.String,
		Packet.Instance,
		Packet.Any
	),

	CombatAction = Packet(
		"CombatAction",
		Packet.String,
		Packet.Any
	),

	EntitySpawned = Packet(
		"EntitySpawned",
		Packet.Instance,
		{ Stats = Packet.Any, States = Packet.Any }
	),

	EntityDespawned = Packet(
		"EntityDespawned",
		Packet.Instance
	),

	RequestPlayerData = Packet(
		"RequestPlayerData"
	):Response(Packet.Any),

	RequestAction = Packet(
		"RequestAction",
		Packet.String,
		Packet.Any
	):Response(Packet.Boolean8, Packet.Any),
}

return Packets