--!strict

export type Option<T> = {
	IsSome: (self: Option<T>) -> boolean,
	IsNone: (self: Option<T>) -> boolean,
	Unwrap: (self: Option<T>) -> T,
	UnwrapOr: (self: Option<T>, Default: T) -> T,
	UnwrapOrElse: (self: Option<T>, Fn: () -> T) -> T,
	Expect: (self: Option<T>, Message: string) -> T,
	ExpectNone: (self: Option<T>, Message: string) -> (),
	Match: (self: Option<T>, Handlers: { Some: (T) -> (), None: () -> () }) -> (),
	Map: (self: Option<T>, Fn: (T) -> any) -> any,
	AndThen: (self: Option<T>, Fn: (T) -> any) -> any,
	Or: (self: Option<T>, Other: Option<T>) -> Option<T>,
	OrElse: (self: Option<T>, Fn: () -> Option<T>) -> Option<T>,
	XOr: (self: Option<T>, Other: Option<T>) -> Option<T>,
	Filter: (self: Option<T>, Predicate: (T) -> boolean) -> Option<T>,
	Contains: (self: Option<T>, Value: T) -> boolean,
}

type OptionInternal = Option<any> & {
	_Value: any,
	_HasValue: boolean,
}

local Option = {}
Option.__index = Option

local NONE_INSTANCE: OptionInternal? = nil

--[=[
	Creates an Option containing a value.
]=]
function Option.Some<T>(Value: T): Option<T>
	local self: OptionInternal = setmetatable({
		_Value = Value,
		_HasValue = true,
	}, Option) :: any

	return self :: any
end

--[=[
	Creates an empty Option.
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
]=]
function Option.Wrap<T>(Value: T?): Option<T>
	if Value == nil then
		return Option.None()
	end
	return Option.Some(Value)
end

--[=[
	Returns `true` if the value is an Option.
]=]
function Option.Is(Value: any): boolean
	return type(Value) == "table" and getmetatable(Value) == Option
end

--[=[
	Returns `true` if the Option contains a value.
]=]
function Option:IsSome(): boolean
	return (self :: OptionInternal)._HasValue
end

--[=[
	Returns `true` if the Option is empty.
]=]
function Option:IsNone(): boolean
	return not (self :: OptionInternal)._HasValue
end

--[=[
	Returns the contained value. Throws if None.
]=]
function Option:Unwrap(): any
	local Self = self :: OptionInternal
	if not Self._HasValue then
		error("Attempted to unwrap a None value")
	end
	return Self._Value
end

--[=[
	Returns the contained value or the default.
]=]
function Option:UnwrapOr(Default: any): any
	local Self = self :: OptionInternal
	if Self._HasValue then
		return Self._Value
	end
	return Default
end

--[=[
	Returns the contained value or computes it from a function.
]=]
function Option:UnwrapOrElse(Fn: () -> any): any
	local Self = self :: OptionInternal
	if Self._HasValue then
		return Self._Value
	end
	return Fn()
end

--[=[
	Returns the contained value or throws with message.
]=]
function Option:Expect(Message: string): any
	local Self = self :: OptionInternal
	if not Self._HasValue then
		error(Message)
	end
	return Self._Value
end

--[=[
	Throws an error with message if the value is not None.
]=]
function Option:ExpectNone(Message: string)
	local Self = self :: OptionInternal
	if Self._HasValue then
		error(Message)
	end
end

--[=[
	Pattern matches on the Option.
]=]
function Option:Match(Handlers: { Some: (any) -> (), None: () -> () })
	local Self = self :: OptionInternal
	if Self._HasValue then
		Handlers.Some(Self._Value)
	else
		Handlers.None()
	end
end

--[=[
	Maps the contained value through a function.
]=]
function Option:Map(Fn: (any) -> any): any
	local Self = self :: OptionInternal
	if not Self._HasValue then
		return Option.None()
	end
	return Option.Some(Fn(Self._Value))
end

--[=[
	Chains Option-returning functions.
]=]
function Option:AndThen(Fn: (any) -> any): any
	local Self = self :: OptionInternal
	if not Self._HasValue then
		return Option.None()
	end
	return Fn(Self._Value)
end

--[=[
	Returns self if Some, otherwise returns Other.
]=]
function Option:Or(Other: any): any
	local Self = self :: OptionInternal
	if Self._HasValue then
		return self
	end
	return Other
end

--[=[
	Returns self if Some, otherwise computes from function.
]=]
function Option:OrElse(Fn: () -> any): any
	local Self = self :: OptionInternal
	if Self._HasValue then
		return self
	end
	return Fn()
end

--[=[
	Returns None if both options have values or both are None.
	Otherwise returns the option that has a value.
]=]
function Option:XOr(Other: any): any
	local Self = self :: OptionInternal
	local OtherInternal = Other :: OptionInternal

	if Self._HasValue and not OtherInternal._HasValue then
		return self
	elseif not Self._HasValue and OtherInternal._HasValue then
		return Other
	end

	return Option.None()
end

--[=[
	Returns self if this option has a value and the predicate returns true.
	Otherwise, returns None.
]=]
function Option:Filter(Predicate: (any) -> boolean): any
	local Self = self :: OptionInternal
	if not Self._HasValue then
		return Option.None()
	end

	if Predicate(Self._Value) then
		return self
	end

	return Option.None()
end

--[=[
	Returns `true` if Option contains the specified value.
]=]
function Option:Contains(Value: any): boolean
	local Self = self :: OptionInternal
	if not Self._HasValue then
		return false
	end
	return Self._Value == Value
end

return Option