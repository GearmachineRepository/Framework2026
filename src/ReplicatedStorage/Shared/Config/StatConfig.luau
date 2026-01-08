--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Shared = ReplicatedStorage:WaitForChild("Shared")

local StatEnums = require(Shared.Types.Enums.StatEnums)

export type StatDefinition = {
	Default: number,
	Min: number?,
	Max: number?,
	MaxStat: string?,
	Replicate: boolean?,
}

export type StatConfig = { [string]: StatDefinition }

local StatConfig: StatConfig = {
	[StatEnums.HEALTH] = {
		Default = 100,
		Min = 0,
		MaxStat = StatEnums.MAX_HEALTH,
		Replicate = true,
	},

	[StatEnums.MAX_HEALTH] = {
		Default = 100,
		Min = 1,
		Max = 9999,
		Replicate = true,
	},

	[StatEnums.STAMINA] = {
		Default = 75,
		Min = 0,
		MaxStat = StatEnums.MAX_STAMINA,
		Replicate = true,
	},

	[StatEnums.MAX_STAMINA] = {
		Default = 75,
		Min = 1,
		Max = 9999,
		Replicate = true,
	},

	[StatEnums.POSTURE] = {
		Default = 0,
		Min = 0,
		MaxStat = StatEnums.MAX_POSTURE,
		Replicate = true,
	},

	[StatEnums.MAX_POSTURE] = {
		Default = 100,
		Min = 1,
		Max = 9999,
		Replicate = true,
	},

	[StatEnums.HUNGER] = {
		Default = 75,
		Min = 0,
		MaxStat = StatEnums.MAX_HUNGER,
		Replicate = true,
	},

	[StatEnums.MAX_HUNGER] = {
		Default = 75,
		Min = 1,
		Max = 9999,
		Replicate = true,
	},

	[StatEnums.BODY_FATIGUE] = {
		Default = 0,
		Min = 0,
		MaxStat = StatEnums.MAX_BODY_FATIGUE,
		Replicate = true,
	},

	[StatEnums.MAX_BODY_FATIGUE] = {
		Default = 100,
		Min = 1,
		Max = 9999,
		Replicate = true,
	},

	[StatEnums.PHYSICAL_RESISTANCE] = {
		Default = 0,
		Min = 0,
		Max = 100,
		Replicate = true,
	},

	[StatEnums.ARMOR] = {
		Default = 0,
		Min = 0,
		Replicate = true,
	},

	[StatEnums.FAT] = {
		Default = 0,
		Min = 0,
		Replicate = false,
	},

	[StatEnums.MUSCLE] = {
		Default = 0,
		Min = 0,
		Replicate = false,
	},

	[StatEnums.RUN_SPEED] = {
		Default = 28,
		Min = 0,
		Replicate = false,
	},

	[StatEnums.STRIKING_POWER] = {
		Default = 0,
		Min = 0,
		Replicate = false,
	},

	[StatEnums.STRIKE_SPEED] = {
		Default = 0,
		Min = 0,
		Replicate = false,
	},

	[StatEnums.DURABILITY] = {
		Default = 0,
		Min = 0,
		Replicate = false,
	},
}

return StatConfig