--!strict

local Types = require(script.Parent.Types)

type Signal = Types.Signal<any>
type Connection = Types.Connection

local EventBus = {}

local Events: { [string]: Signal } = {}
local SignalConstructor: (() -> Signal)? = nil

function EventBus.Configure(Constructor: () -> Signal)
	SignalConstructor = Constructor
end

function EventBus.GetOrCreateEvent(EventName: string): Signal
	local Existing = Events[EventName]
	if Existing then
		return Existing
	end

	if not SignalConstructor then
		error(Types.EngineName .. " EventBus not configured")
	end

	local NewEvent = SignalConstructor()
	Events[EventName] = NewEvent
	return NewEvent
end

function EventBus.Subscribe(EventName: string, Callback: (...any) -> ()): Connection
	local Event = EventBus.GetOrCreateEvent(EventName)
	return Event:Connect(Callback)
end

function EventBus.SubscribeOnce(EventName: string, Callback: (...any) -> ()): Connection
	local Event = EventBus.GetOrCreateEvent(EventName)
	return Event:Once(Callback)
end

function EventBus.Publish(EventName: string, ...: any)
	local Event = Events[EventName]
	if Event then
		Event:Fire(...)
	end
end

function EventBus.Wait(EventName: string): ...any
	local Event = EventBus.GetOrCreateEvent(EventName)
	return Event:Wait()
end

function EventBus.Clear(EventName: string?)
	if EventName then
		local Event = Events[EventName]
		if Event then
			Event:DisconnectAll()
		end
		Events[EventName] = nil
	else
		for _, Event in Events do
			Event:DisconnectAll()
		end
		table.clear(Events)
	end
end

function EventBus.HasEvent(EventName: string): boolean
	return Events[EventName] ~= nil
end

function EventBus.GetEventNames(): { string }
	local Names = {}
	for EventName in Events do
		table.insert(Names, EventName)
	end
	return Names
end

return EventBus