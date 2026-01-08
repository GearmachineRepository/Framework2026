--!strict

local RunService = game:GetService("RunService")

export type Timer = {
	Start: (self: Timer) -> (),
	Stop: (self: Timer) -> (),
	IsRunning: (self: Timer) -> boolean,
	GetElapsed: (self: Timer) -> number,
	Destroy: (self: Timer) -> (),
}

type TimerInternal = Timer & {
	_Interval: number,
	_Callback: () -> (),
	_Running: boolean,
	_Connection: RBXScriptConnection?,
	_Accumulator: number,
	_UpdateSignal: RBXScriptSignal,
}

local Timer = {}
Timer.__index = Timer

local function GetUpdateSignal(): RBXScriptSignal
	if RunService:IsServer() then
		return RunService.Heartbeat
	else
		return RunService.RenderStepped
	end
end

function Timer.new(Interval: number, Callback: () -> (), Immediate: boolean?): Timer
	local self: TimerInternal = setmetatable({
		_Interval = Interval,
		_Callback = Callback,
		_Running = false,
		_Connection = nil,
		_Accumulator = if Immediate then Interval else 0,
		_UpdateSignal = GetUpdateSignal(),
	}, Timer) :: any

	return self
end

function Timer.Start(self: TimerInternal)
	if self._Running then
		return
	end

	self._Running = true

	self._Connection = self._UpdateSignal:Connect(function(DeltaTime: number)
		self._Accumulator = self._Accumulator + DeltaTime

		while self._Accumulator >= self._Interval do
			self._Accumulator = self._Accumulator - self._Interval
			task.spawn(self._Callback)
		end
	end)
end

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

function Timer.IsRunning(self: TimerInternal): boolean
	return self._Running
end

function Timer.GetElapsed(self: TimerInternal): number
	return self._Accumulator
end

function Timer.Destroy(self: TimerInternal)
	self:Stop()
end

local TimerModule = {}

function TimerModule.new(Interval: number, Callback: () -> (), Immediate: boolean?): Timer
	return Timer.new(Interval, Callback, Immediate)
end

function TimerModule.Simple(Duration: number, Callback: () -> ()): () -> ()
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

function TimerModule.Every(Interval: number, Callback: () -> ()): () -> ()
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

function TimerModule.Debounce<A..., R...>(Duration: number, Callback: (A...) -> R...): (A...) -> ()
	local LastCall = 0

	return function(...)
		local CurrentTime = os.clock()

		if CurrentTime - LastCall >= Duration then
			LastCall = CurrentTime
			Callback(...)
		end
	end
end

function TimerModule.Throttle<A..., R...>(Duration: number, Callback: (A...) -> R...): (A...) -> ()
	local Scheduled = false
	local LastArgs: { any }? = nil

	return function(...)
		LastArgs = { ... }

		if not Scheduled then
			Scheduled = true

			task.delay(Duration, function()
				Scheduled = false
				if LastArgs then
					Callback(table.unpack(LastArgs))
					LastArgs = nil
				end
			end)
		end
	end
end

return TimerModule