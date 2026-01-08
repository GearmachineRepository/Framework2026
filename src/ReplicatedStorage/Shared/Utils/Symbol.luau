--!strict

--[[
	Symbol

	Creates unique identifiers that can be used as table keys.
	Two symbols with the same name are not equal.

	```lua
	local NONE = Symbol.new("None")
	local data = { [NONE] = true }
	```
]]

export type Symbol = typeof(setmetatable(
	{} :: { Name: string },
	{} :: { __tostring: (any) -> string }
))

local Symbol = {}

local SymbolMetatable = {
	__tostring = function(self: { Name: string }): string
		return string.format("Symbol(%s)", self.Name)
	end,
}

--[=[
	Creates a new Symbol with the given name.

	```lua
	local NONE = Symbol.new("None")
	local LOADING = Symbol.new("Loading")
	```
]=]
function Symbol.new(Name: string): Symbol
	local NewSymbol = setmetatable({
		Name = Name,
	}, SymbolMetatable)

	return NewSymbol
end

--[=[
	Returns `true` if the value is a Symbol.

	```lua
	if Symbol.Is(value) then
		print(tostring(value))
	end
	```
]=]
function Symbol.Is(Value: any): boolean
	if type(Value) ~= "table" then
		return false
	end

	return getmetatable(Value) == SymbolMetatable
end

return Symbol