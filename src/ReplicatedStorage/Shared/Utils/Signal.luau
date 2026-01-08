--!strict

--[[
	Signal

	A Signal allows events to be dispatched and observed.
	Based on GoodSignal patterns with thread recycling for performance.

	```lua
	local signal = Signal.new()

	signal:Connect(function(message)
		print("Received:", message)
	end)

	signal:Fire("Hello")
	```
]]

export type Connection = {
	Connected: boolean,
	Disconnect: (self: Connection) -> (),
}

export type Signal<T...> = {
	Connect: (self: Signal<T...>, Callback: (T...) -> ()) -> Connection,
	Once: (self: Signal<T...>, Callback: (T...) -> ()) -> Connection,
	Fire: (self: Signal<T...>, T...) -> (),
	FireDeferred: (self: Signal<T...>, T...) -> (),
	Wait: (self: Signal<T...>) -> T...,
	DisconnectAll: (self: Signal<T...>) -> (),
	Destroy: (self: Signal<T...>) -> (),
}

type ConnectionInternal = {
	Connected: boolean,
	Signal: SignalInternal?,
	Callback: ((...any) -> ())?,
	Next: ConnectionInternal?,
	Disconnect: (self: ConnectionInternal) -> (),
}

type SignalInternal = {
	Head: ConnectionInternal?,
	Connect: (self: SignalInternal, Callback: (...any) -> ()) -> ConnectionInternal,
	Once: (self: SignalInternal, Callback: (...any) -> ()) -> ConnectionInternal,
	Fire: (self: SignalInternal, ...any) -> (),
	FireDeferred: (self: SignalInternal, ...any) -> (),
	Wait: (self: SignalInternal) -> ...any,
	DisconnectAll: (self: SignalInternal) -> (),
	Destroy: (self: SignalInternal) -> (),
}

local FreeThread: thread? = nil

local function RunCallback(Callback: (...any) -> (), ...)
	local AcquiredThread = FreeThread
	FreeThread = nil
	Callback(...)
	FreeThread = AcquiredThread
end

local function YieldingThread()
	while true do
		RunCallback(coroutine.yield())
	end
end

local Signal = {}
Signal.__index = Signal

local Connection = {}
Connection.__index = Connection

--[=[
	Disconnects the connection from the signal.

	```lua
	local connection = signal:Connect(function() end)
	connection:Disconnect()
	```
]=]
function Connection.Disconnect(self: ConnectionInternal)
	if not self.Connected then
		return
	end

	self.Connected = false

	local SignalInstance = self.Signal
	if not SignalInstance then
		return
	end

	if SignalInstance.Head == self then
		SignalInstance.Head = self.Next
	else
		local Previous = SignalInstance.Head
		while Previous and Previous.Next ~= self do
			Previous = Previous.Next
		end
		if Previous then
			Previous.Next = self.Next
		end
	end

	self.Signal = nil
	self.Callback = nil
	self.Next = nil
end

--[=[
	Constructs a new Signal.

	```lua
	local signal = Signal.new()
	```
]=]
function Signal.new<T...>(): Signal<T...>
	local self: SignalInternal = setmetatable({
		Head = nil,
	}, Signal) :: any

	return self :: any
end

--[=[
	Wraps an existing RBXScriptSignal.

	```lua
	local signal = Signal.Wrap(workspace.ChildAdded)
	signal:Connect(function(child)
		print(child.Name)
	end)
	```
]=]
function Signal.Wrap<T...>(RbxSignal: RBXScriptSignal): Signal<T...>
	local Wrapper = Signal.new()

	local WrapperConnection = RbxSignal:Connect(function(...)
		(Wrapper :: any):Fire(...)
	end)

	local OriginalDestroy = Wrapper.Destroy
	function Wrapper:Destroy()
		WrapperConnection:Disconnect()
		OriginalDestroy(self)
	end

	return Wrapper :: any
end

--[=[
	Returns `true` if the given object is a Signal.

	```lua
	if Signal.Is(obj) then
		obj:Fire()
	end
	```
]=]
function Signal.Is(Value: any): boolean
	return type(Value) == "table" and getmetatable(Value) == Signal
end

--[=[
	Connects a callback to the signal.

	```lua
	signal:Connect(function(message)
		print(message)
	end)
	```
]=]
function Signal.Connect<T...>(self: SignalInternal, Callback: (T...) -> ()): Connection
	local NewConnection: ConnectionInternal = setmetatable({
		Connected = true,
		Signal = self,
		Callback = Callback,
		Next = self.Head,
	}, Connection) :: any

	self.Head = NewConnection
	return NewConnection :: any
end

--[=[
	Connects a callback that disconnects after firing once.

	```lua
	signal:Once(function(message)
		print("Only prints once:", message)
	end)
	```
]=]
function Signal.Once<T...>(self: SignalInternal, Callback: (T...) -> ()): Connection
	local OnceConnection: ConnectionInternal

	OnceConnection = self:Connect(function(...)
		if OnceConnection.Connected then
			OnceConnection:Disconnect()
			Callback(...)
		end
	end) :: any

	return OnceConnection :: any
end

--[=[
	Fires the signal with the given arguments.
	Uses thread recycling for performance.

	```lua
	signal:Fire("Hello", 123)
	```
]=]
function Signal.Fire<T...>(self: SignalInternal, ...: T...)
	local Current = self.Head
	while Current do
		if Current.Connected and Current.Callback then
			if FreeThread == nil then
				FreeThread = coroutine.create(YieldingThread)
				task.spawn(FreeThread :: thread)
			end
			task.spawn(FreeThread :: thread, Current.Callback, ...)
		end
		Current = Current.Next
	end
end

--[=[
	Fires the signal using `task.defer`.
	Does not use thread recycling.

	```lua
	signal:FireDeferred("Hello")
	```
]=]
function Signal.FireDeferred<T...>(self: SignalInternal, ...: T...)
	local Current = self.Head
	while Current do
		if Current.Connected and Current.Callback then
			task.defer(Current.Callback, ...)
		end
		Current = Current.Next
	end
end

--[=[
	Yields until the signal fires, then returns the arguments.

	```lua
	local message = signal:Wait()
	print("Received:", message)
	```
]=]
function Signal.Wait<T...>(self: SignalInternal): T...
	local WaitingThread = coroutine.running()

	local WaitConnection: ConnectionInternal
	WaitConnection = self:Connect(function(...)
		WaitConnection:Disconnect()
		task.spawn(WaitingThread, ...)
	end) :: any

	return coroutine.yield()
end

--[=[
	Disconnects all connections from the signal.

	```lua
	signal:DisconnectAll()
	```
]=]
function Signal.DisconnectAll(self: SignalInternal)
	local Current = self.Head
	while Current do
		Current.Connected = false
		Current.Signal = nil
		Current.Callback = nil
		Current = Current.Next
	end
	self.Head = nil
end

--[=[
	Destroys the signal and disconnects all connections.

	```lua
	signal:Destroy()
	```
]=]
function Signal.Destroy(self: SignalInternal)
	self:DisconnectAll()
end

return Signal