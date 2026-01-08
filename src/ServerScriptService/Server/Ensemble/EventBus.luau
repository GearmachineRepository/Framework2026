--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Signal = require(ReplicatedStorage:WaitForChild("Shared").Utils.Signal)
local Types = require(script.Parent.Types)

type SignalType = Signal.Signal<...any>
type Connection = Signal.Connection
type EventBus = Types.EventBus

local EventBus = {}
EventBus.__index = EventBus

type EventBusInternal = {
	_Events: { [string]: SignalType },
}

--[=[
	Creates a new EventBus instance.

	```lua
	local bus = EventBus.new()
	```
]=]
function EventBus.new(): EventBus
	local self: EventBusInternal = setmetatable({
		_Events = {},
	}, EventBus) :: any

	return self :: any
end

--[=[
	Returns `true` if the value is an EventBus.
]=]
function EventBus.Is(Value: any): boolean
	return type(Value) == "table" and getmetatable(Value) == EventBus
end

local function GetOrCreateEvent(self: EventBusInternal, EventName: string): SignalType
	local Existing = self._Events[EventName]
	if Existing then
		return Existing
	end

	local NewEvent = Signal.new()
	self._Events[EventName] = NewEvent
	return NewEvent
end

--[=[
	Subscribes to an event.

	```lua
	bus:Subscribe("PlayerDied", function(player)
		print(player.Name, "died")
	end)
	```
]=]
function EventBus.Subscribe(self: EventBusInternal, EventName: string, Callback: (...any) -> ()): Connection
	local Event = GetOrCreateEvent(self, EventName)
	return Event:Connect(Callback)
end

--[=[
	Subscribes to an event once.

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
	Publishes an event with arguments.

	```lua
	bus:Publish("PlayerDied", player)
	```
]=]
function EventBus.Publish(self: EventBusInternal, EventName: string, ...: any)
	local Event = self._Events[EventName]
	if Event then
		Event:Fire(...)
	end
end

--[=[
	Waits for an event to fire.

	```lua
	local player = bus:Wait("PlayerDied")
	```
]=]
function EventBus.Wait(self: EventBusInternal, EventName: string): ...any
	local Event = GetOrCreateEvent(self, EventName)
	return Event:Wait()
end

--[=[
	Clears one or all events.

	```lua
	bus:Clear("PlayerDied")
	bus:Clear()
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
	Returns `true` if an event exists.
]=]
function EventBus.HasEvent(self: EventBusInternal, EventName: string): boolean
	return self._Events[EventName] ~= nil
end

--[=[
	Returns all event names.
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
]=]
function EventBus.Destroy(self: EventBusInternal)
	for _, Event in self._Events do
		Event:Destroy()
	end
	table.clear(self._Events)
end

return EventBus