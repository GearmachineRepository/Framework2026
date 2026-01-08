--!strict

export type Symbol = typeof(setmetatable({} :: { Name: string }, {} :: { __tostring: (any) -> string }))

local Symbol = {}

local SymbolMetatable = {
	__tostring = function(self: { Name: string }): string
		return string.format("Symbol(%s)", self.Name)
	end,
}

function Symbol.new(Name: string): Symbol
	local NewSymbol = setmetatable({
		Name = Name,
	}, SymbolMetatable)

	return NewSymbol
end

function Symbol.Is(Value: any): boolean
	if type(Value) ~= "table" then
		return false
	end

	return getmetatable(Value) == SymbolMetatable
end

return Symbol