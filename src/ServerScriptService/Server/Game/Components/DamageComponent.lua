--!strict

local StateComponent = require(script.Parent.StateComponent)
local StatComponent = require(script.Parent.StatComponent)
local ModifierComponent = require(script.Parent.ModifierComponent)

local DamageComponent = {}

DamageComponent.ComponentName = "Damage"
DamageComponent.Dependencies = { "States", "Stats", "Modifiers" }

type DamageInstance = {
	TakeDamage: (Amount: number, Source: Player?, Direction: Vector3?) -> (),
	DealDamage: (Target: any, BaseDamage: number) -> number,
	IsInvulnerable: () -> boolean,
	Destroy: () -> (),
}

function DamageComponent.Create(Entity: any, _Context: any): DamageInstance
	local States = StateComponent.From(Entity)
	local Stats = StatComponent.From(Entity)
	local Modifiers = ModifierComponent.From(Entity)
	local Humanoid = Entity.Humanoid

	local function IsInvulnerable(): boolean
		if not States then
			return false
		end
		return States.GetState("Invulnerable")
	end

	local function TakeDamage(Amount: number, Source: Player?, Direction: Vector3?)
		if IsInvulnerable() then
			return
		end

		local ModifiedDamage = Amount

		if Modifiers then
			ModifiedDamage = Modifiers.Apply("DamageTaken", Amount, {
				Source = Source,
				Direction = Direction,
			})
		end

		local NewHealth = math.max(0, Humanoid.Health - ModifiedDamage)
		Humanoid.Health = NewHealth

		if Stats then
			Stats.SetStat("Health", NewHealth)
		end
	end

	local function DealDamage(Target: any, BaseDamage: number): number
		local FinalDamage = BaseDamage

		if Modifiers then
			FinalDamage = Modifiers.Apply("DamageDealt", BaseDamage, {
				Target = Target,
			})
		end

		local TargetDamage = Target:GetComponent("Damage")
		if TargetDamage then
			TargetDamage.TakeDamage(FinalDamage, Entity.Player, nil)
		end

		return FinalDamage
	end

	local function Destroy()
	end

	return {
		TakeDamage = TakeDamage,
		DealDamage = DealDamage,
		IsInvulnerable = IsInvulnerable,
		Destroy = Destroy,
	}
end

export type Type = typeof(DamageComponent.Create(nil :: any, nil :: any))

function DamageComponent.From(Entity: any): Type?
	return Entity:GetComponent("Damage")
end

return DamageComponent