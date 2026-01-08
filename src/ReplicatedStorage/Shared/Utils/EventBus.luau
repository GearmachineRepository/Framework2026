--!strict

--[[
	EventBus

	A publish/subscribe event system for decoupled communication.

	```lua
	local EventBus = require(path.to.EventBus)
	local bus = EventBus.new(Signal.new)

	bus:Subscribe("PlayerDied", function(data)
		print(data.Player.Name, "died")
	end)

	bus:Publish("PlayerDied", { Player = player })
	```
]]

type Signal = {
	Connect: (self: any, Callback: (...any) -> ()) -> Connection,
	Once: (self: any, Callback: (...any) -> ()) -> Connection,
	Fire: (self: any, ...any) -> (),
	Wait: (self: any) -> ...any,
	DisconnectAll: (self: any) -> (),
	Destroy: (self: any) -> (),
}

type Connection = {
	Disconnect: (self: Connection) -> (),
	Connected: boolean,
}

type SignalConstructor = () -> Signal

export type EventBus = {
	Subscribe: (self: EventBus, EventName: string, Callback: (...any) -> ()) -> Connection,
	SubscribeOnce: (self: EventBus, EventName: string, Callback: (...any) -> ()) -> Connection,
	Publish: (self: EventBus, EventName: string, ...any) -> (),
	Wait: (self: EventBus, EventName: string) -> ...any,
	Clear: (self: EventBus, EventName: string?) -> (),
	HasEvent: (self: EventBus, EventName: string) -> boolean,
	GetEventNames: (self: EventBus) -> { string },
	Destroy: (self: EventBus) -> (),
}

type EventBusInternal = EventBus & {
	_Events: { [string]: Signal },
	_SignalConstructor: SignalConstructor,
}

local EventBus = {}
EventBus.__index = EventBus

--[=[
	Creates a new EventBus with the given Signal constructor.

	```lua
	local bus = EventBus.new(Signal.new)
	```
]=]
function EventBus.new(SignalConstructor: SignalConstructor): EventBus
	local self: EventBusInternal = setmetatable({
		_Events = {},
		_SignalConstructor = SignalConstructor,
	}, EventBus) :: any

	return self
end

--[=[
	Returns `true` if the value is an EventBus.

	```lua
	if EventBus.Is(obj) then
		obj:Publish("Event")
	end
	```
]=]
function EventBus.Is(Value: any): boolean
	return type(Value) == "table" and getmetatable(Value) == EventBus
end

local function GetOrCreateEvent(self: EventBusInternal, EventName: string): Signal
	local Existing = self._Events[EventName]
	if Existing then
		return Existing
	end

	local NewEvent = self._SignalConstructor()
	self._Events[EventName] = NewEvent
	return NewEvent
end

--[=[
	Subscribes to an event. Returns a connection.

	```lua
	local connection = bus:Subscribe("PlayerJoined", function(player)
		print(player.Name, "joined")
	end)
	```
]=]
function EventBus.Subscribe(self: EventBusInternal, EventName: string, Callback: (...any) -> ()): Connection
	local Event = GetOrCreateEvent(self, EventName)
	return Event:Connect(Callback)
end

--[=[
	Subscribes to an event once. Disconnects after first fire.

	```lua
	bus:SubscribeOnce("GameStart", function()
		print("Game started!")
	end)
	```
]=]
function EventBus.SubscribeOnce(self: EventBusInternal, EventName: string, Callback: (...any) -> ()): Connection
	local Event = GetOrCreateEvent(self, EventName)
	return Event:Once(Callback)
end

--[=[
	Publishes an event with the given arguments.

	```lua
	bus:Publish("DamageDealt", {
		Source = attacker,
		Target = target,
		Amount = 50,
	})
	```
]=]
function EventBus.Publish(self: EventBusInternal, EventName: string, ...: any)
	local Event = self._Events[EventName]
	if Event then
		Event:Fire(...)
	end
end

--[=[
	Yields until the event is published.

	```lua
	local data = bus:Wait("GameEnd")
	print("Game ended with result:", data.Result)
	```
]=]
function EventBus.Wait(self: EventBusInternal, EventName: string): ...any
	local Event = GetOrCreateEvent(self, EventName)
	return Event:Wait()
end

--[=[
	Clears an event or all events.

	```lua
	bus:Clear("PlayerDied") -- Clear specific event
	bus:Clear() -- Clear all events
	```
]=]
function EventBus.Clear(self: EventBusInternal, EventName: string?)
	if EventName then
		local Event = self._Events[EventName]
		if Event then
			Event:DisconnectAll()
		end
		self._Events[EventName] = nil
	else
		for _, Event in self._Events do
			Event:DisconnectAll()
		end
		table.clear(self._Events)
	end
end

--[=[
	Returns `true` if the event exists.

	```lua
	if bus:HasEvent("PlayerDied") then
		-- Event has subscribers
	end
	```
]=]
function EventBus.HasEvent(self: EventBusInternal, EventName: string): boolean
	return self._Events[EventName] ~= nil
end

--[=[
	Returns all registered event names.

	```lua
	local events = bus:GetEventNames()
	```
]=]
function EventBus.GetEventNames(self: EventBusInternal): { string }
	local Names = {}
	for EventName in self._Events do
		table.insert(Names, EventName)
	end
	return Names
end

--[=[
	Destroys the EventBus and clears all events.

	```lua
	bus:Destroy()
	```
]=]
function EventBus.Destroy(self: EventBusInternal)
	for _, Event in self._Events do
		Event:Destroy()
	end
	table.clear(self._Events)
end

return EventBus