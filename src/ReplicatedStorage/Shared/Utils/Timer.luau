--!strict

--[[
	Timer

	Runs code periodically at specified intervals.

	```lua
	local timer = Timer.new(1)
	timer.Tick:Connect(function()
		print("Tick!")
	end)
	timer:Start()
	```
]]

local RunService = game:GetService("RunService")

local Signal = require(script.Parent.Signal)

type TimeFn = () -> number

export type Timer = {
	Interval: number,
	Tick: Signal.Signal<>,
	AllowDrift: boolean,
	UpdateSignal: RBXScriptSignal,
	TimeFunction: TimeFn,
	Start: (self: Timer) -> (),
	StartNow: (self: Timer) -> (),
	Stop: (self: Timer) -> (),
	IsRunning: (self: Timer) -> boolean,
	Destroy: (self: Timer) -> (),
}

type TimerInternal = Timer & {
	_Running: boolean,
	_Connection: RBXScriptConnection?,
	_NextTick: number,
}

local Timer = {}
Timer.__index = Timer

local function GetDefaultSignal(): RBXScriptSignal
	if RunService:IsServer() then
		return RunService.Heartbeat
	else
		return RunService.RenderStepped
	end
end

--[=[
	Creates a new Timer with the specified interval.

	```lua
	local timer = Timer.new(2)
	```
]=]
function Timer.new(Interval: number): Timer
	local self: TimerInternal = setmetatable({
		Interval = Interval,
		Tick = Signal.new(),
		AllowDrift = true,
		UpdateSignal = GetDefaultSignal(),
		TimeFunction = os.clock,
		_Running = false,
		_Connection = nil,
		_NextTick = 0,
	}, Timer) :: any

	return self
end

--[=[
	Creates a simple timer that calls a callback at the interval.

	```lua
	local connection = Timer.Simple(1, function()
		print("Tick")
	end)

	-- With options:
	Timer.Simple(1, callback, true, RunService.Heartbeat, os.clock)
	```
]=]
function Timer.Simple(
	Interval: number,
	Callback: () -> (),
	StartNow: boolean?,
	UpdateSignal: RBXScriptSignal?,
	TimeFn: TimeFn?
): RBXScriptConnection
	local SignalToUse: RBXScriptSignal = (UpdateSignal or GetDefaultSignal()) :: RBXScriptSignal
	local GetTime = TimeFn or os.clock
	local NextTick = GetTime() + Interval

	if StartNow then
		task.spawn(Callback)
	end

	return SignalToUse:Connect(function()
		local CurrentTime = GetTime()
		if CurrentTime >= NextTick then
			NextTick = CurrentTime + Interval
			task.spawn(Callback)
		end
	end)
end

--[=[
	Returns `true` if the value is a Timer.

	```lua
	if Timer.Is(obj) then
		obj:Start()
	end
	```
]=]
function Timer.Is(Value: any): boolean
	return type(Value) == "table" and getmetatable(Value) == Timer
end

--[=[
	Starts the timer.

	```lua
	timer:Start()
	```
]=]
function Timer.Start(self: TimerInternal)
	if self._Running then
		return
	end

	self._Running = true
	self._NextTick = self.TimeFunction() + self.Interval

	self._Connection = self.UpdateSignal:Connect(function()
		local CurrentTime = self.TimeFunction()

		if self.AllowDrift then
			if CurrentTime >= self._NextTick then
				self._NextTick = CurrentTime + self.Interval
				self.Tick:Fire()
			end
		else
			while CurrentTime >= self._NextTick do
				self._NextTick += self.Interval
				self.Tick:Fire()
			end
		end
	end)
end

--[=[
	Starts the timer and fires Tick immediately.

	```lua
	timer:StartNow()
	```
]=]
function Timer.StartNow(self: TimerInternal)
	if self._Running then
		return
	end

	self.Tick:Fire()
	self:Start()
end

--[=[
	Stops the timer.

	```lua
	timer:Stop()
	```
]=]
function Timer.Stop(self: TimerInternal)
	if not self._Running then
		return
	end

	self._Running = false

	if self._Connection then
		self._Connection:Disconnect()
		self._Connection = nil
	end
end

--[=[
	Returns `true` if the timer is running.

	```lua
	if timer:IsRunning() then
		timer:Stop()
	end
	```
]=]
function Timer.IsRunning(self: TimerInternal): boolean
	return self._Running
end

--[=[
	Destroys the timer and stops it.

	```lua
	timer:Destroy()
	```
]=]
function Timer.Destroy(self: TimerInternal)
	self:Stop()
	self.Tick:Destroy()
end

--[=[
	Creates a one-shot delayed callback. Returns cancel function.

	```lua
	local cancel = Timer.Delay(5, function()
		print("5 seconds later")
	end)

	cancel() -- Cancels the callback
	```
]=]
function Timer.Delay(Duration: number, Callback: () -> ()): () -> ()
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

--[=[
	Creates a repeating interval. Returns stop function.

	```lua
	local stop = Timer.Every(1, function()
		print("Every second")
	end)

	stop() -- Stops the interval
	```
]=]
function Timer.Every(Interval: number, Callback: () -> ()): () -> ()
	local Running = true

	task.spawn(function()
		while Running do
			task.wait(Interval)
			if Running then
				Callback()
			end
		end
	end)

	return function()
		Running = false
	end
end

--[=[
	Creates a debounced function that only executes after
	the specified duration has passed without being called.

	```lua
		local debouncedSearch = Timer.Debounce(0.3, function(query)
			performSearch(query)
		end)
	```
]=]
function Timer.Debounce<Arguments..., Returns...>(Duration: number, Callback: (Arguments...) -> Returns...): (Arguments...) -> ()
	local ScheduledThread: thread? = nil

	return function(...: Arguments...)
		if ScheduledThread then
			task.cancel(ScheduledThread)
		end

		ScheduledThread = task.delay(Duration, function(...: Arguments...)
			ScheduledThread = nil
			Callback(...)
		end, ...)
	end
end

--[=[
	Creates a throttled function that executes immediately,
	then ignores calls for the specified duration.

	```lua
		local throttledJump = Timer.Throttle(0.5, function()
			player:Jump()
		end)
	```
]=]
function Timer.Throttle<A..., R...>(Duration: number, Callback: (A...) -> R...): (A...) -> ()
	local LastCall = 0

	return function(...)
		local CurrentTime = os.clock()
		if CurrentTime - LastCall >= Duration then
			LastCall = CurrentTime
			Callback(...)
		end
	end
end

return Timer