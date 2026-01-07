--!strict

local ServerScriptService = game:GetService("ServerScriptService")

local Types = require(ServerScriptService.Server.Ensemble.Types)

type StatConfig = Types.StatConfig
type EntityContext = Types.EntityContext
type Entity = Types.Entity

local StatComponent = {}

StatComponent.ComponentName = "Stats"
StatComponent.Dependencies = {}

type StatInstance = {
	GetStat: (StatName: string) -> number,
	SetStat: (StatName: string, Value: number) -> (),
	ModifyStat: (StatName: string, Delta: number) -> (),
	GetAllStats: () -> { [string]: number },
	OnStatChanged: (StatName: string, Callback: (NewValue: number, OldValue: number) -> ()) -> () -> (),
	Destroy: () -> (),
}

local UPDATE_THRESHOLD = 0.001

function StatComponent.From(Entity: Entity): Type?
	return Entity:GetComponent("Stats")
end

function StatComponent.Create(Entity: Entity, Context: EntityContext): StatInstance
	local Config: StatConfig = Context.StatConfig or {}
	local CurrentStats: { [string]: number } = {}
	local StatCallbacks: { [string]: { (NewValue: number, OldValue: number) -> () } } = {}
	local Character = Entity.Character

	for StatName, Definition in Config do
		CurrentStats[StatName] = Definition.Default
		StatCallbacks[StatName] = {}

		if Definition.Replicate ~= false and Character then
			Character:SetAttribute(StatName, Definition.Default)
		end
	end

	local function ClampValue(StatName: string, Value: number): number
		local Definition = Config[StatName]
		if not Definition then
			return Value
		end

		local Clamped = Value

		if Definition.Min ~= nil then
			Clamped = math.max(Definition.Min, Clamped)
		end

		if Definition.Max ~= nil then
			Clamped = math.min(Definition.Max, Clamped)
		end

		return Clamped
	end

	local function GetStat(StatName: string): number
		return CurrentStats[StatName] or 0
	end

	local function SetStat(StatName: string, Value: number)
		local ClampedValue = ClampValue(StatName, Value)
		local OldValue = CurrentStats[StatName] or 0

		if math.abs(ClampedValue - OldValue) < UPDATE_THRESHOLD then
			return
		end

		CurrentStats[StatName] = ClampedValue

		local Definition = Config[StatName]
		if Definition and Definition.Replicate ~= false and Character then
			Character:SetAttribute(StatName, ClampedValue)
		end

		local Callbacks = StatCallbacks[StatName]
		if Callbacks then
			for _, Callback in Callbacks do
				task.spawn(Callback, ClampedValue, OldValue)
			end
		end
	end

	local function ModifyStat(StatName: string, Delta: number)
		local Current = GetStat(StatName)
		SetStat(StatName, Current + Delta)
	end

	local function GetAllStats(): { [string]: number }
		return table.clone(CurrentStats)
	end

	local function OnStatChanged(StatName: string, Callback: (NewValue: number, OldValue: number) -> ()): () -> ()
		if not StatCallbacks[StatName] then
			StatCallbacks[StatName] = {}
		end

		table.insert(StatCallbacks[StatName], Callback)

		return function()
			local Callbacks = StatCallbacks[StatName]
			if Callbacks then
				local Index = table.find(Callbacks, Callback)
				if Index then
					table.remove(Callbacks, Index)
				end
			end
		end
	end

	local function Destroy()
		table.clear(CurrentStats)
		table.clear(StatCallbacks)
	end

	return {
		GetStat = GetStat,
		SetStat = SetStat,
		ModifyStat = ModifyStat,
		GetAllStats = GetAllStats,
		OnStatChanged = OnStatChanged,
		Destroy = Destroy,
	}
end

export type Type = typeof(StatComponent.Create(nil :: any, nil :: any))

return StatComponent