--!strict

--[[
	Option

	Represents an optional value that may or may not exist.
	Avoids nil ambiguity and provides safe value access.

	```lua
	local function findPlayer(name): Option<Player>
		local player = Players:FindFirstChild(name)
		return if player then Option.Some(player) else Option.None()
	end

	findPlayer("Bob"):Match({
		Some = function(player) print("Found:", player.Name) end,
		None = function() print("Not found") end,
	})
	```
]]

export type Option<T> = {
	IsSome: (self: Option<T>) -> boolean,
	IsNone: (self: Option<T>) -> boolean,
	Unwrap: (self: Option<T>) -> T,
	UnwrapOr: (self: Option<T>, Default: T) -> T,
	UnwrapOrElse: (self: Option<T>, Fn: () -> T) -> T,
	Expect: (self: Option<T>, Message: string) -> T,
	Match: (self: Option<T>, Handlers: { Some: (T) -> (), None: () -> () }) -> (),
	Map: (self: Option<T>, Fn: (T) -> any) -> any,
	AndThen: (self: Option<T>, Fn: (T) -> any) -> any,
	Or: (self: Option<T>, Other: Option<T>) -> Option<T>,
	OrElse: (self: Option<T>, Fn: () -> Option<T>) -> Option<T>,
	Contains: (self: Option<T>, Value: T) -> boolean,
}

type OptionInternal<T> = Option<T> & {
	_Value: T?,
	_HasValue: boolean,
}

local Option = {}
Option.__index = Option

local NONE_INSTANCE: OptionInternal<any>? = nil

--[=[
	Creates an Option containing a value.

	```lua
	local opt = Option.Some(42)
	```
]=]
function Option.Some<T>(Value: T): Option<T>
	local self: OptionInternal<T> = setmetatable({
		_Value = Value,
		_HasValue = true,
	}, Option) :: any

	return self
end

--[=[
	Creates an empty Option.

	```lua
	local opt = Option.None()
	```
]=]
function Option.None<T>(): Option<T>
	if not NONE_INSTANCE then
		NONE_INSTANCE = setmetatable({
			_Value = nil,
			_HasValue = false,
		}, Option) :: any
	end
	return NONE_INSTANCE :: any
end

--[=[
	Wraps a value that might be nil into an Option.

	```lua
	local opt = Option.Wrap(maybeNilValue)
	```
]=]
function Option.Wrap<T>(Value: T?): Option<T>
	if Value == nil then
		return Option.None()
	end
	return Option.Some(Value)
end

--[=[
	Returns `true` if the value is an Option.

	```lua
	if Option.Is(value) then
		print(value:IsSome())
	end
	```
]=]
function Option.Is(Value: any): boolean
	return type(Value) == "table" and getmetatable(Value) == Option
end

--[=[
	Returns `true` if the Option contains a value.

	```lua
	if opt:IsSome() then
		print(opt:Unwrap())
	end
	```
]=]
function Option.IsSome<T>(self: OptionInternal<T>): boolean
	return self._HasValue
end

--[=[
	Returns `true` if the Option is empty.

	```lua
	if opt:IsNone() then
		print("No value")
	end
	```
]=]
function Option.IsNone<T>(self: OptionInternal<T>): boolean
	return not self._HasValue
end

--[=[
	Returns the contained value. Throws if None.

	```lua
	local value = opt:Unwrap()
	```
]=]
function Option.Unwrap<T>(self: OptionInternal<T>): T
	if not self._HasValue then
		error("Attempted to unwrap a None value")
	end
	return self._Value :: T
end

--[=[
	Returns the contained value or the default.

	```lua
	local value = opt:UnwrapOr(0)
	```
]=]
function Option.UnwrapOr<T>(self: OptionInternal<T>, Default: T): T
	if self._HasValue then
		return self._Value :: T
	end
	return Default
end

--[=[
	Returns the contained value or computes it from a function.

	```lua
	local value = opt:UnwrapOrElse(function()
		return computeDefault()
	end)
	```
]=]
function Option.UnwrapOrElse<T>(self: OptionInternal<T>, Fn: () -> T): T
	if self._HasValue then
		return self._Value :: T
	end
	return Fn()
end

--[=[
	Returns the contained value or throws with message.

	```lua
	local player = opt:Expect("Player should exist")
	```
]=]
function Option.Expect<T>(self: OptionInternal<T>, Message: string): T
	if not self._HasValue then
		error(Message)
	end
	return self._Value :: T
end

--[=[
	Pattern matches on the Option.

	```lua
	opt:Match({
		Some = function(value) print("Got:", value) end,
		None = function() print("Empty") end,
	})
	```
]=]
function Option.Match<T>(self: OptionInternal<T>, Handlers: { Some: (T) -> (), None: () -> () })
	if self._HasValue then
		Handlers.Some(self._Value :: T)
	else
		Handlers.None()
	end
end

--[=[
	Maps the contained value through a function.

	```lua
	local doubled = opt:Map(function(n) return n * 2 end)
	```
]=]
function Option.Map<T>(self: OptionInternal<T>, Fn: (T) -> any): any
	if not self._HasValue then
		return Option.None()
	end
	return Option.Some(Fn(self._Value :: T))
end

--[=[
	Chains Option-returning functions.

	```lua
	local result = opt:AndThen(function(value)
		return Option.Some(value * 2)
	end)
	```
]=]
function Option.AndThen<T>(self: OptionInternal<T>, Fn: (T) -> any): any
	if not self._HasValue then
		return Option.None()
	end
	return Fn(self._Value :: T)
end

--[=[
	Returns self if Some, otherwise returns Other.

	```lua
	local result = opt:Or(Option.Some(defaultValue))
	```
]=]
function Option.Or<T>(self: OptionInternal<T>, Other: Option<T>): Option<T>
	if self._HasValue then
		return self
	end
	return Other
end

--[=[
	Returns self if Some, otherwise computes from function.

	```lua
	local result = opt:OrElse(function()
		return Option.Some(computeDefault())
	end)
	```
]=]
function Option.OrElse<T>(self: OptionInternal<T>, Fn: () -> Option<T>): Option<T>
	if self._HasValue then
		return self
	end
	return Fn()
end

--[=[
	Returns `true` if Option contains the specified value.

	```lua
	if opt:Contains(42) then
		print("Has 42")
	end
	```
]=]
function Option.Contains<T>(self: OptionInternal<T>, Value: T): boolean
	if not self._HasValue then
		return false
	end
	return self._Value == Value
end

return Option