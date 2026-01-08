--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Shared = ReplicatedStorage:WaitForChild("Shared")

local StatConfig = require(Shared.Config.StatConfig)
local StatTypes = require(Shared.Types.Enums.StatEnums)

return {
	Stats = {
		[StatTypes.HEALTH] = StatConfig[StatTypes.HEALTH].Default,
		[StatTypes.MAX_HEALTH] = StatConfig[StatTypes.MAX_HEALTH].Default,
		[StatTypes.STAMINA] = StatConfig[StatTypes.STAMINA].Default,
		[StatTypes.MAX_STAMINA] = StatConfig[StatTypes.MAX_STAMINA].Default,
		[StatTypes.POSTURE] = StatConfig[StatTypes.POSTURE].Default,
		[StatTypes.MAX_POSTURE] = StatConfig[StatTypes.MAX_POSTURE].Default,
		[StatTypes.PHYSICAL_RESISTANCE] = StatConfig[StatTypes.PHYSICAL_RESISTANCE].Default,

		[StatTypes.BODY_FATIGUE] = StatConfig[StatTypes.BODY_FATIGUE].Default,
		[StatTypes.MAX_BODY_FATIGUE] = StatConfig[StatTypes.MAX_BODY_FATIGUE].Default,
		[StatTypes.HUNGER] = StatConfig[StatTypes.HUNGER].Default,
		[StatTypes.MAX_HUNGER] = StatConfig[StatTypes.MAX_HUNGER].Default,
		[StatTypes.FAT] = StatConfig[StatTypes.FAT].Default,

		MaxStamina_XP = 0,
		Durability_XP = 0,
		RunSpeed_XP = 0,
		StrikingPower_XP = 0,
		StrikeSpeed_XP = 0,
		Muscle_XP = 0,

		MaxStamina_Stars = 0,
		Durability_Stars = 0,
		RunSpeed_Stars = 0,
		StrikingPower_Stars = 0,
		StrikeSpeed_Stars = 0,
		Muscle_Stars = 0,

		MaxStamina_Points = 25,
		Durability_Points = 25,
		RunSpeed_Points = 25,
		StrikingPower_Points = 25,
		StrikeSpeed_Points = 25,
		Muscle_Points = 25,
	},

	Backpack = {},
	Hotbar = {},
	Traits = {},
	Hooks = {},

	Clan = {
		ClanName = "None",
		ClanRarity = 0,
	},

	Appearance = {
		Gender = "Male",
		HairColor = Color3.new(0, 0, 0),
		EyeColor = Color3.new(0, 0, 0),
		Face = "Default",
		Height = 1.0,
	},

	Skills = {},
	EquippedMode = "None",
}