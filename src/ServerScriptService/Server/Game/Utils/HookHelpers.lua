--!strict
--[[
	HookHelpers - Utility functions for writing hooks

	These helpers simplify common patterns like:
	- Reacting to state changes
	- Registering modifiers with auto-cleanup
	- Health threshold triggers
]]

type Entity = any
type Connection = { Disconnect: (any) -> () }

local HookHelpers = {}

function HookHelpers.OnStateEnter(Entity: Entity, StateName: string, Callback: () -> ()): () -> ()
	local States = Entity:GetComponent("States")
	if not States then
		return function() end
	end

	local Connection = States.OnStateChanged(StateName, function(IsActive: boolean)
		if IsActive then
			Callback()
		end
	end)

	return function()
		Connection:Disconnect()
	end
end

function HookHelpers.OnStateExit(Entity: Entity, StateName: string, Callback: () -> ()): () -> ()
	local States = Entity:GetComponent("States")
	if not States then
		return function() end
	end

	local Connection = States.OnStateChanged(StateName, function(IsActive: boolean)
		if not IsActive then
			Callback()
		end
	end)

	return function()
		Connection:Disconnect()
	end
end

function HookHelpers.WhileState(Entity: Entity, StateName: string, OnEnter: () -> (), OnExit: () -> ()): () -> ()
	local States = Entity:GetComponent("States")
	if not States then
		return function() end
	end

	local Connection = States.OnStateChanged(StateName, function(IsActive: boolean)
		if IsActive then
			OnEnter()
		else
			OnExit()
		end
	end)

	return function()
		Connection:Disconnect()
	end
end

function HookHelpers.OnStatChanged(Entity: Entity, StatName: string, Callback: (NewValue: number, OldValue: number) -> ()): () -> ()
	local Stats = Entity:GetComponent("Stats")
	if not Stats then
		return function() end
	end

	local Connection = Stats.OnStatChanged(StatName, Callback)

	return function()
		Connection:Disconnect()
	end
end

function HookHelpers.OnHealthBelow(Entity: Entity, Threshold: number, Callback: () -> ()): () -> ()
	local Stats = Entity:GetComponent("Stats")
	if not Stats then
		return function() end
	end

	local HasTriggered = false

	local Connection = Stats.OnStatChanged("Health", function(NewHealth: number)
		local MaxHealth = Stats.GetStat("MaxHealth")
		if MaxHealth <= 0 then
			return
		end

		local Percent = NewHealth / MaxHealth

		if Percent < Threshold and not HasTriggered then
			HasTriggered = true
			Callback()
		elseif Percent >= Threshold then
			HasTriggered = false
		end
	end)

	return function()
		Connection:Disconnect()
	end
end

function HookHelpers.OnHealthAbove(Entity: Entity, Threshold: number, Callback: () -> ()): () -> ()
	local Stats = Entity:GetComponent("Stats")
	if not Stats then
		return function() end
	end

	local HasTriggered = false

	local Connection = Stats.OnStatChanged("Health", function(NewHealth: number)
		local MaxHealth = Stats.GetStat("MaxHealth")
		if MaxHealth <= 0 then
			return
		end

		local Percent = NewHealth / MaxHealth

		if Percent > Threshold and not HasTriggered then
			HasTriggered = true
			Callback()
		elseif Percent <= Threshold then
			HasTriggered = false
		end
	end)

	return function()
		Connection:Disconnect()
	end
end

function HookHelpers.ModifyDamageDealt(Entity: Entity, Modifier: (Damage: number) -> number): () -> ()
	local Modifiers = Entity:GetComponent("Modifiers")
	if not Modifiers then
		return function() end
	end

	return Modifiers.Register("DamageDealt", 100, function(Damage: number)
		return Modifier(Damage)
	end)
end

function HookHelpers.ModifyDamageTaken(Entity: Entity, Modifier: (Damage: number) -> number): () -> ()
	local Modifiers = Entity:GetComponent("Modifiers")
	if not Modifiers then
		return function() end
	end

	return Modifiers.Register("Damage", 100, function(Damage: number)
		return Modifier(Damage)
	end)
end

function HookHelpers.ModifySpeed(Entity: Entity, Modifier: (Speed: number) -> number): () -> ()
	local Modifiers = Entity:GetComponent("Modifiers")
	if not Modifiers then
		return function() end
	end

	return Modifiers.Register("WalkSpeed", 100, function(Speed: number)
		return Modifier(Speed)
	end)
end

function HookHelpers.ModifyStaminaCost(Entity: Entity, Modifier: (Cost: number) -> number): () -> ()
	local Modifiers = Entity:GetComponent("Modifiers")
	if not Modifiers then
		return function() end
	end

	return Modifiers.Register("StaminaCost", 100, function(Cost: number)
		return Modifier(Cost)
	end)
end

function HookHelpers.ModifyValue(Entity: Entity, ModifierType: string, Priority: number, Modifier: (Value: number) -> number): () -> ()
	local Modifiers = Entity:GetComponent("Modifiers")
	if not Modifiers then
		return function() end
	end

	return Modifiers.Register(ModifierType, Priority, function(Value: number)
		return Modifier(Value)
	end)
end

function HookHelpers.CombineCleanups(...: (() -> ())?): () -> ()
	local Cleanups = { ... }

	return function()
		for _, Cleanup in Cleanups do
			if Cleanup then
				pcall(Cleanup)
			end
		end
	end
end

function HookHelpers.Delay(Duration: number, Callback: () -> ()): () -> ()
	local Cancelled = false

	task.delay(Duration, function()
		if not Cancelled then
			Callback()
		end
	end)

	return function()
		Cancelled = true
	end
end

function HookHelpers.Interval(Duration: number, Callback: () -> ()): () -> ()
	local Running = true

	task.spawn(function()
		while Running do
			task.wait(Duration)
			if Running then
				Callback()
			end
		end
	end)

	return function()
		Running = false
	end
end

function HookHelpers.GetHealthPercent(Entity: Entity): number
	local Stats = Entity:GetComponent("Stats")
	if not Stats then
		return 0
	end

	local Health = Stats.GetStat("Health")
	local MaxHealth = Stats.GetStat("MaxHealth")

	if MaxHealth <= 0 then
		return 0
	end

	return Health / MaxHealth
end

function HookHelpers.GetStaminaPercent(Entity: Entity): number
	local Stats = Entity:GetComponent("Stats")
	if not Stats then
		return 0
	end

	local Stamina = Stats.GetStat("Stamina")
	local MaxStamina = Stats.GetStat("MaxStamina")

	if MaxStamina <= 0 then
		return 0
	end

	return Stamina / MaxStamina
end

return HookHelpers