--!strict

local RunService = game:GetService("RunService")

export type Destroyable = { Destroy: (self: any) -> () }
export type Disconnectable = { Disconnect: (self: any) -> () }
export type Constructable<T, A...> = { new: (A...) -> T } | (A...) -> T

export type CleanupTask =
	Instance
	| RBXScriptConnection
	| (() -> ())
	| thread
	| Destroyable
	| Disconnectable

export type Trove = {
	Add: <T>(self: Trove, Object: T, CleanupMethod: string?) -> T,
	Connect: (self: Trove, Signal: RBXScriptSignal, Handler: (...any) -> ()) -> RBXScriptConnection,
	Once: (self: Trove, Signal: RBXScriptSignal, Handler: (...any) -> ()) -> RBXScriptConnection,
	Construct: <T, A...>(self: Trove, Class: Constructable<T, A...>, A...) -> T,
	Clone: (self: Trove, Template: Instance) -> Instance,
	BindToRenderStep: (self: Trove, Name: string, Priority: number, Handler: (DeltaTime: number) -> ()) -> (),
	AttachToInstance: (self: Trove, Target: Instance) -> RBXScriptConnection,
	Extend: (self: Trove) -> Trove,
	Remove: (self: Trove, Object: any) -> boolean,
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

function Trove.new(): Trove
	local self: TroveInternal = setmetatable({
		_Objects = {},
		_Cleaning = false,
	}, Trove) :: any

	return self
end

function Trove.Add<T>(self: TroveInternal, Object: T, CleanupMethod: string?): T
	if self._Cleaning then
		error("Cannot add to Trove while cleaning")
	end

	local Method = CleanupMethod or GetCleanupMethod(Object)
	self._Objects[Object] = Method

	return Object
end

function Trove.Connect(self: TroveInternal, Signal: RBXScriptSignal, Handler: (...any) -> ()): RBXScriptConnection
	return self:Add(Signal:Connect(Handler))
end

function Trove.Once(self: TroveInternal, Signal: RBXScriptSignal, Handler: (...any) -> ()): RBXScriptConnection
	return self:Add(Signal:Once(Handler))
end

function Trove.Construct<T, A...>(self: TroveInternal, Class: Constructable<T, A...>, ...: A...): T
	local Object: T

	if type(Class) == "function" then
		Object = Class(...)
	else
		Object = (Class :: any).new(...)
	end

	return self:Add(Object)
end

function Trove.Clone(self: TroveInternal, Template: Instance): Instance
	return self:Add(Template:Clone())
end

function Trove.BindToRenderStep(self: TroveInternal, Name: string, Priority: number, Handler: (DeltaTime: number) -> ())
	RunService:BindToRenderStep(Name, Priority, Handler)

	self:Add(function()
		RunService:UnbindFromRenderStep(Name)
	end)
end

function Trove.AttachToInstance(self: TroveInternal, Target: Instance): RBXScriptConnection
	if not Target:IsDescendantOf(game) then
		error("Instance must be a descendant of game")
	end

	return self:Connect(Target.Destroying, function()
		self:Destroy()
	end)
end

function Trove.Extend(self: TroveInternal): Trove
	return self:Construct(Trove.new)
end

function Trove.Remove(self: TroveInternal, Object: any): boolean
	local Method = self._Objects[Object]

	if Method == nil and self._Objects[Object] == nil then
		return false
	end

	self._Objects[Object] = nil
	CleanupObject(Object, Method)

	return true
end

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

function Trove.WrapClean(self: TroveInternal): () -> ()
	return function()
		self:Clean()
	end
end

function Trove.Destroy(self: TroveInternal)
	self:Clean()
end

return {
	new = Trove.new,
}