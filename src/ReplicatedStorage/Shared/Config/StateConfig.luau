--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Shared = ReplicatedStorage:WaitForChild("Shared")

local StateEnums = require(Shared.Enums.StateEnums)

export type StateDefinition = {
	Default: boolean?,
	Replicate: boolean?,
	Conflicts: { string }?,
}

export type StateConfig = { [string]: StateDefinition }

local StateConfig: StateConfig = {
	[StateEnums.ATTACKING] = {
		Default = false,
		Replicate = true,
		Conflicts = { StateEnums.BLOCKING, StateEnums.STUNNED, StateEnums.DODGING },
	},

	[StateEnums.BLOCKING] = {
		Default = false,
		Replicate = true,
		Conflicts = { StateEnums.ATTACKING, StateEnums.STUNNED, StateEnums.DODGING },
	},

	[StateEnums.PARRYING] = {
		Default = false,
		Replicate = true,
		Conflicts = { StateEnums.ATTACKING, StateEnums.BLOCKING },
	},

	[StateEnums.STUNNED] = {
		Default = false,
		Replicate = true,
		Conflicts = { StateEnums.ATTACKING, StateEnums.BLOCKING, StateEnums.DODGING },
	},

	[StateEnums.INVULNERABLE] = {
		Default = false,
		Replicate = true,
	},

	[StateEnums.GUARD_BROKEN] = {
		Default = false,
		Replicate = true,
		Conflicts = { StateEnums.BLOCKING, StateEnums.PARRYING },
	},

	[StateEnums.DODGING] = {
		Default = false,
		Replicate = true,
		Conflicts = { StateEnums.ATTACKING, StateEnums.BLOCKING },
	},

	[StateEnums.SPRINTING] = {
		Default = false,
		Replicate = true,
		Conflicts = { StateEnums.BLOCKING },
	},

	[StateEnums.JOGGING] = {
		Default = false,
		Replicate = true,
	},

	[StateEnums.RAGDOLLED] = {
		Default = false,
		Replicate = true,
		Conflicts = { StateEnums.ATTACKING, StateEnums.BLOCKING, StateEnums.DODGING },
	},

	[StateEnums.DOWNED] = {
		Default = false,
		Replicate = true,
	},

	[StateEnums.KILLED] = {
		Default = false,
		Replicate = true,
	},

	[StateEnums.IN_COMBAT] = {
		Default = false,
		Replicate = true,
	},

	[StateEnums.STAGGERED] = {
		Default = false,
		Replicate = true,
		Conflicts = { StateEnums.ATTACKING, StateEnums.BLOCKING },
	},

	[StateEnums.EXHAUSTED] = {
		Default = false,
		Replicate = true,
	},

	[StateEnums.MOVEMENT_LOCKED] = {
		Default = false,
		Replicate = true,
	},

	[StateEnums.PERFECT_GUARD_WINDOW] = {
		Default = false,
		Replicate = false,
	},

	[StateEnums.COUNTER_WINDOW] = {
		Default = false,
		Replicate = false,
	},

	[StateEnums.RIPOSTE_WINDOW] = {
		Default = false,
		Replicate = true,
	},

	[StateEnums.MODE_ACTIVE] = {
		Default = false,
		Replicate = true,
	},

	[StateEnums.IN_CUTSCENE] = {
		Default = false,
		Replicate = true,
		Conflicts = { StateEnums.ATTACKING, StateEnums.BLOCKING, StateEnums.DODGING },
	},
}

return StateConfig