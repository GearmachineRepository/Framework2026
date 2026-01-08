--!strict

--[[
	Trove

	Tracks objects for cleanup. Supports instances, connections,
	functions, threads, and tables with Destroy/Disconnect methods.

	```lua
	local trove = Trove.new()

	local part = trove:Add(Instance.new("Part"))
	trove:Connect(workspace.ChildAdded, function(child)
		print(child.Name)
	end)

	trove:Destroy()
	```
]]

local RunService = game:GetService("RunService")

export type Trackable =
	Instance
	| RBXScriptConnection
	| (() -> ())
	| thread
	| { Destroy: (any) -> () }
	| { Disconnect: (any) -> () }
	| { destroy: (any) -> () }
	| { disconnect: (any) -> () }

export type Constructable<T, A...> = { new: (A...) -> T } | (A...) -> T

export type Trove = {
	Add: <T>(self: Trove, Object: T, CleanupMethod: string?) -> T,
	Clone: (self: Trove, Instance: Instance) -> Instance,
	Construct: <T, A...>(self: Trove, Class: Constructable<T, A...>, A...) -> T,
	Connect: (self: Trove, Signal: RBXScriptSignal, Callback: (...any) -> ()) -> RBXScriptConnection,
	Once: (self: Trove, Signal: RBXScriptSignal, Callback: (...any) -> ()) -> RBXScriptConnection,
	BindToRenderStep: (self: Trove, Name: string, Priority: number, Callback: (number) -> ()) -> (),
	AttachToInstance: (self: Trove, Instance: Instance) -> RBXScriptConnection,
	Extend: (self: Trove) -> Trove,
	Remove: (self: Trove, Object: any) -> boolean,
	Pop: (self: Trove, Object: any) -> boolean,
	Clean: (self: Trove) -> (),
	WrapClean: (self: Trove) -> () -> (),
	Destroy: (self: Trove) -> (),
}

type TroveInternal = Trove & {
	_Objects: { [any]: string? },
	_Cleaning: boolean,
}

local Trove = {}
Trove.__index = Trove

local function GetCleanupMethod(Object: any): string?
	local ObjectType = typeof(Object)

	if ObjectType == "Instance" then
		return "Destroy"
	elseif ObjectType == "RBXScriptConnection" then
		return "Disconnect"
	elseif ObjectType == "function" then
		return nil
	elseif ObjectType == "thread" then
		return nil
	elseif ObjectType == "table" then
		if type(Object.Destroy) == "function" then
			return "Destroy"
		elseif type(Object.Disconnect) == "function" then
			return "Disconnect"
		elseif type(Object.destroy) == "function" then
			return "destroy"
		elseif type(Object.disconnect) == "function" then
			return "disconnect"
		end
	end

	return nil
end

local function CleanupObject(Object: any, Method: string?)
	local ObjectType = typeof(Object)

	if ObjectType == "function" then
		Object()
	elseif ObjectType == "thread" then
		task.cancel(Object)
	elseif Method then
		Object[Method](Object)
	end
end

--[=[
	Constructs a new Trove.

	```lua
	local trove = Trove.new()
	```
]=]
function Trove.new(): Trove
	local self: TroveInternal = setmetatable({
		_Objects = {},
		_Cleaning = false,
	}, Trove) :: any

	return self
end

--[=[
	Returns `true` if the given object is a Trove.

	```lua
	if Trove.Is(obj) then
		obj:Clean()
	end
	```
]=]
function Trove.Is(Value: any): boolean
	return type(Value) == "table" and getmetatable(Value) == Trove
end

--[=[
	Adds an object to the trove. Returns the object.

	`Instance` = `Destroy()`
	`RBXScriptConnection` = `Disconnect()`
	`function` = Called directly
	`thread` = `task.cancel()`
	`table` = `Destroy()` or `Disconnect()`

	```lua
	local part = trove:Add(Instance.new("Part"))
	```
]=]
function Trove.Add<T>(self: TroveInternal, Object: T, CleanupMethod: string?): T
	if self._Cleaning then
		error("Cannot add to Trove while cleaning")
	end

	local Method = CleanupMethod or GetCleanupMethod(Object)
	self._Objects[Object] = Method

	return Object
end

--[=[
	Clones the instance and adds it to the trove.

	```lua
	local clone = trove:Clone(template)
	```
]=]
function Trove.Clone(self: TroveInternal, Template: Instance): Instance
	return self:Add(Template:Clone())
end

--[=[
	Constructs an object and adds it to the trove.
	Accepts a class with `.new()` or a function.

	```lua
	local signal = trove:Construct(Signal)
	local part = trove:Construct(Instance, "Part")
	```
]=]
function Trove.Construct<T, A...>(self: TroveInternal, Class: Constructable<T, A...>, ...: A...): T
	local Object: T

	if type(Class) == "function" then
		Object = Class(...)
	else
		Object = (Class :: any).new(...)
	end

	return self:Add(Object)
end

--[=[
	Connects to a signal and adds the connection to the trove.

	```lua
	trove:Connect(workspace.ChildAdded, function(child)
		print(child.Name)
	end)
	```
]=]
function Trove.Connect(self: TroveInternal, Signal: RBXScriptSignal, Callback: (...any) -> ()): RBXScriptConnection
	return self:Add(Signal:Connect(Callback))
end

--[=[
	Connects to a signal with `:Once()` and adds to the trove.

	```lua
	trove:Once(workspace.ChildAdded, function(child)
		print("First child:", child.Name)
	end)
	```
]=]
function Trove.Once(self: TroveInternal, Signal: RBXScriptSignal, Callback: (...any) -> ()): RBXScriptConnection
	return self:Add(Signal:Once(Callback))
end

--[=[
	Binds to RenderStep and automatically unbinds on cleanup.

	```lua
	trove:BindToRenderStep("MyUpdate", Enum.RenderPriority.Camera.Value, function(dt)
		-- Update logic
	end)
	```
]=]
function Trove.BindToRenderStep(self: TroveInternal, Name: string, Priority: number, Callback: (number) -> ())
	RunService:BindToRenderStep(Name, Priority, Callback)

	self:Add(function()
		RunService:UnbindFromRenderStep(Name)
	end)
end

--[=[
	Attaches the trove to an instance's lifetime.
	Cleans up when the instance is destroyed.

	```lua
	trove:AttachToInstance(part)
	```
]=]
function Trove.AttachToInstance(self: TroveInternal, Target: Instance): RBXScriptConnection
	if not Target:IsDescendantOf(game) then
		error("Instance must be a descendant of game")
	end

	return self:Connect(Target.Destroying, function()
		self:Destroy()
	end)
end

--[=[
	Creates a new Trove and adds it to this trove.

	```lua
	local subTrove = trove:Extend()
	```
]=]
function Trove.Extend(self: TroveInternal): Trove
	return self:Construct(Trove.new)
end

--[=[
	Removes an object from the trove and cleans it up.

	```lua
	trove:Remove(part)
	```
]=]
function Trove.Remove(self: TroveInternal, Object: any): boolean
	local Method = self._Objects[Object]

	if Method == nil and self._Objects[Object] == nil then
		return false
	end

	self._Objects[Object] = nil
	CleanupObject(Object, Method)

	return true
end

--[=[
	Removes an object from the trove without cleaning it up.

	```lua
	local part = trove:Add(Instance.new("Part"))
	trove:Pop(part)
	trove:Clean() -- Part is NOT destroyed
	```
]=]
function Trove.Pop(self: TroveInternal, Object: any): boolean
	if self._Objects[Object] == nil and not rawget(self._Objects, Object) then
		return false
	end

	self._Objects[Object] = nil
	return true
end

--[=[
	Cleans up all objects in the trove.

	```lua
	trove:Clean()
	```
]=]
function Trove.Clean(self: TroveInternal)
	if self._Cleaning then
		return
	end

	self._Cleaning = true

	for Object, Method in self._Objects do
		self._Objects[Object] = nil
		CleanupObject(Object, Method)
	end

	self._Cleaning = false
end

--[=[
	Returns a function that calls `Clean()` when invoked.
	Useful for observer patterns.

	```lua
	return trove:WrapClean()
	```
]=]
function Trove.WrapClean(self: TroveInternal): () -> ()
	return function()
		self:Clean()
	end
end

--[=[
	Alias for `Clean()`.

	```lua
	trove:Destroy()
	```
]=]
function Trove.Destroy(self: TroveInternal)
	self:Clean()
end

return Trove