--!strict

--[[
	ObjectPool

	A generic object pool for reusing instances (or other destroyable objects) to reduce allocations
	and improve runtime performance.

	This pool tracks "active" (checked out) objects to protect against:
	- double-return
	- returning foreign objects (not created by this pool)
	- delayed returns after Clear()

	Behavioral notes:
	- `MaxSize` caps the number of *available (idle)* objects retained, not total objects created.
	- `Clear()` destroys both available and active objects, and resets tracking.
	- Returning an object that is not currently active is a no-op.
	- Returning an object after `Destroy()` destroys that object deterministically.

	```lua
	local ObjectPool = require(path.to.ObjectPool)

	local Pool = ObjectPool.new({
		Create = function()
			local Part = Instance.new("Part")
			Part.Anchored = true
			Part.CanCollide = false
			return Part
		end,
		Reset = function(Object)
			Object.Parent = nil
			Object.CFrame = CFrame.new()
		end,
		InitialSize = 50,
		MaxSize = 200,
	})

	local Part = Pool:Get()
	Part.Parent = workspace

	Pool:Return(Part)
	```
]]

export type PoolConfig<T> = {
	Create: () -> T,
	Reset: (Object: T) -> (),
	InitialSize: number?,
	MaxSize: number?,
}

export type ObjectPool<T> = {
	Get: (Self: ObjectPool<T>) -> T,
	Return: (Self: ObjectPool<T>, Object: T) -> (),
	Warm: (Self: ObjectPool<T>, Count: number) -> (),
	GetAvailableCount: (Self: ObjectPool<T>) -> number,
	GetActiveCount: (Self: ObjectPool<T>) -> number,
	Clear: (Self: ObjectPool<T>) -> (),
	Destroy: (Self: ObjectPool<T>) -> (),
}

local DEFAULT_INITIAL_SIZE = 10
local DEFAULT_MAX_SIZE = 100

type DestroyableTable = {
	Destroy: (Self: DestroyableTable) -> (),
}

local function Cleanup(CleanupValue: unknown)
	if CleanupValue == nil then
		return
	end

	local CleanupType = typeof(CleanupValue)

	if CleanupType == "Instance" then
		(CleanupValue :: Instance):Destroy()
		return
	end

	if CleanupType == "RBXScriptConnection" then
		(CleanupValue :: RBXScriptConnection):Disconnect()
		return
	end

	if CleanupType == "table" then
		local CleanupTable = CleanupValue :: { [any]: any }
		local DestroyFunction = CleanupTable.Destroy
		if typeof(DestroyFunction) == "function" then
			(DestroyFunction :: (any) -> ())(CleanupValue)
		end
	end
end

type PoolInternal<T> = {
	Available: { T },
	Active: { [T]: boolean },
	CreateFunction: () -> T,
	ResetFunction: (Object: T) -> (),
	MaxSize: number,
	IsDestroyed: boolean,

	Get: (Self: PoolInternal<T>) -> T,
	Return: (Self: PoolInternal<T>, Object: T) -> (),
	Warm: (Self: PoolInternal<T>, Count: number) -> (),
	GetAvailableCount: (Self: PoolInternal<T>) -> number,
	GetActiveCount: (Self: PoolInternal<T>) -> number,
	Clear: (Self: PoolInternal<T>) -> (),
	Destroy: (Self: PoolInternal<T>) -> (),
}

local PoolMetatable = {}
PoolMetatable.__index = PoolMetatable

local function DestroyObject<T>(Object: T)
	Cleanup(Object :: any)
end

--[[
	Checks out an object from the pool.

	If an idle object is available, it is reused. Otherwise, a new object is created.

	Errors if the pool has been destroyed.
]]
function PoolMetatable.Get<T>(Self: PoolInternal<T>): T
	if Self.IsDestroyed then
		error("ObjectPool is destroyed", 2)
	end

	local Object: T

	if #Self.Available > 0 then
		Object = table.remove(Self.Available, #Self.Available) :: T
	else
		Object = Self.CreateFunction()
	end

	Self.Active[Object] = true
	return Object
end

--[[
	Returns an object to the pool.

	If the object is not currently active (foreign object or double-return), this is a no-op.

	If the available pool is at capacity, the object is destroyed instead of retained.

	If the pool has been destroyed, the object is destroyed deterministically.
]]
function PoolMetatable.Return<T>(Self: PoolInternal<T>, Object: T)
	if Self.IsDestroyed then
		DestroyObject(Object)
		return
	end

	if Self.Active[Object] ~= true then
		return
	end

	Self.Active[Object] = nil
	Self.ResetFunction(Object)

	if #Self.Available < Self.MaxSize then
		table.insert(Self.Available, Object)
	else
		DestroyObject(Object)
	end
end

--[[
	Pre-allocates objects into the available pool.

	`Count` is capped to `MaxSize`. This only affects idle objects; it does not limit the number of
	active objects that can be checked out concurrently.

	No-op if the pool has been destroyed.
]]
function PoolMetatable.Warm<T>(Self: PoolInternal<T>, Count: number)
	if Self.IsDestroyed then
		return
	end

	local Target = math.min(Count, Self.MaxSize)
	local ToCreate = Target - #Self.Available
	if ToCreate <= 0 then
		return
	end

	for _ = 1, ToCreate do
		local Object = Self.CreateFunction()
		Self.ResetFunction(Object)
		table.insert(Self.Available, Object)
	end
end

--[[
	Returns the number of idle objects currently available in the pool.
]]
function PoolMetatable.GetAvailableCount<T>(Self: PoolInternal<T>): number
	return #Self.Available
end

--[[
	Returns the number of objects currently checked out (active).

	This is derived from the internal active-set, not from any external tracking.
]]
function PoolMetatable.GetActiveCount<T>(Self: PoolInternal<T>): number
	local Count = 0
	for _ in pairs(Self.Active) do
		Count += 1
	end
	return Count
end

--[[
	Destroys all objects in the pool (both active and available) and resets tracking.

	After `Clear()`, any later `Return()` calls for objects that were previously active will be ignored
	(because they are no longer tracked as active).

	No-op if the pool has been destroyed.
]]
function PoolMetatable.Clear<T>(Self: PoolInternal<T>)
	if Self.IsDestroyed then
		return
	end

	for Object in pairs(Self.Active) do
		DestroyObject(Object)
	end
	table.clear(Self.Active)

	for Index = #Self.Available, 1, -1 do
		local Object = Self.Available[Index]
		DestroyObject(Object)
	end
	table.clear(Self.Available)
end

--[[
	Destroys the pool.

	- Marks the pool as destroyed
	- Clears all objects
	- After destruction, `Get()` errors and `Return()` destroys the provided object
]]
function PoolMetatable.Destroy<T>(Self: PoolInternal<T>)
	if Self.IsDestroyed then
		return
	end

	Self.IsDestroyed = true
	Self:Clear()
end

local function CreatePool<T>(Config: PoolConfig<T>): ObjectPool<T>
	local InitialSize = Config.InitialSize or DEFAULT_INITIAL_SIZE
	local MaxSize = Config.MaxSize or DEFAULT_MAX_SIZE

	if MaxSize <= 0 then
		error("MaxSize must be > 0", 2)
	end

	if InitialSize < 0 then
		error("InitialSize must be >= 0", 2)
	end

	local PoolInternalObject: PoolInternal<T> = {
		Available = {},
		Active = {},
		CreateFunction = Config.Create,
		ResetFunction = Config.Reset,
		MaxSize = MaxSize,
		IsDestroyed = false,

		Get = PoolMetatable.Get,
		Return = PoolMetatable.Return,
		Warm = PoolMetatable.Warm,
		GetAvailableCount = PoolMetatable.GetAvailableCount,
		GetActiveCount = PoolMetatable.GetActiveCount,
		Clear = PoolMetatable.Clear,
		Destroy = PoolMetatable.Destroy,
	}

	local PoolObject = (setmetatable(PoolInternalObject, PoolMetatable) :: any) :: ObjectPool<T>
	PoolObject:Warm(math.min(InitialSize, MaxSize))

	return PoolObject
end

--[[
	Creates a new ObjectPool.

	```lua
	local Pool = ObjectPool.new({
		Create = function()
			return Instance.new("Part")
		end,
		Reset = function(Object)
			Object.Parent = nil
		end,
	})
	```
]]
local function New<T>(Config: PoolConfig<T>): ObjectPool<T>
	return CreatePool(Config)
end

return {
	new = New,
}
