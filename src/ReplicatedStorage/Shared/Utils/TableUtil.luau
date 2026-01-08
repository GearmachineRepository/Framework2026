--!strict

--[[
	TableUtil

	A collection of table utility functions.
	All functions treat tables as immutable except SwapRemove and Lock.

	```lua
	local filtered = TableUtil.Filter(data, function(value)
		return value > 10
	end)
	```
]]

local HttpService = game:GetService("HttpService")

local TableUtil = {}

--[=[
	Creates a copy of the table.
	Pass `true` for deep copy.
	Pass a third argument `true` to preserve metatables.

	```lua
		local copy = TableUtil.Copy(original)
		local deepCopy = TableUtil.Copy(original, true)
		local withMeta = TableUtil.Copy(original, true, true)
	```
]=]
function TableUtil.Copy(Source: any, Deep: boolean?, PreserveMetatable: boolean?): any
	if type(Source) ~= "table" then
		return Source
	end

	local Result = {}

	for Key, Value in Source do
		if Deep and type(Value) == "table" then
			Result[Key] = TableUtil.Copy(Value, true, PreserveMetatable)
		else
			Result[Key] = Value
		end
	end

	if PreserveMetatable then
		setmetatable(Result, getmetatable(Source))
	end

	return Result
end

--[=[
	One-way sync that adds missing keys from template.
	Preserves extra keys in source. Use for player data.

	```lua
	local template = {kills = 0, deaths = 0}
	local data = {kills = 10, custom = "value"}
	local result = TableUtil.Reconcile(data, template)
	-- {kills = 10, deaths = 0, custom = "value"}
	```
]=]
function TableUtil.Reconcile(Source: any, Template: any): any
	if type(Source) ~= "table" or type(Template) ~= "table" then
		return Source
	end

	local Result = TableUtil.Copy(Source, false)

	for Key, TemplateValue in Template do
		local SourceValue = Result[Key]

		if SourceValue == nil then
			if type(TemplateValue) == "table" then
				Result[Key] = TableUtil.Copy(TemplateValue, true)
			else
				Result[Key] = TemplateValue
			end
		elseif type(SourceValue) == "table" and type(TemplateValue) == "table" then
			Result[Key] = TableUtil.Reconcile(SourceValue, TemplateValue)
		end
	end

	return Result
end

--[=[
	Two-way sync that matches source to template exactly.
	Removes keys not in template. Use with caution.

	```lua
	local template = {kills = 0, deaths = 0}
	local data = {kills = 10, oldKey = "removed"}
	local result = TableUtil.Sync(data, template)
	-- {kills = 10, deaths = 0}
	```
]=]
function TableUtil.Sync(Source: any, Template: any): any
	if type(Source) ~= "table" or type(Template) ~= "table" then
		return Source
	end

	local Result = {}

	for Key, TemplateValue in Template do
		local SourceValue = Source[Key]

		if SourceValue ~= nil then
			if type(SourceValue) == "table" and type(TemplateValue) == "table" then
				Result[Key] = TableUtil.Sync(SourceValue, TemplateValue)
			else
				Result[Key] = SourceValue
			end
		elseif type(TemplateValue) == "table" then
			Result[Key] = TableUtil.Copy(TemplateValue, true)
		else
			Result[Key] = TemplateValue
		end
	end

	return Result
end

--[=[
	O(1) removal by swapping with last element.
	Mutates the table. Does not preserve order.

	```lua
	local t = {"A", "B", "C", "D"}
	TableUtil.SwapRemove(t, 2)
	-- {"A", "D", "C"}
	```
]=]
function TableUtil.SwapRemove<V>(Source: { V }, Index: number)
	local Length = #Source
	Source[Index] = Source[Length]
	Source[Length] = nil
end

--[=[
	Finds value and performs SwapRemove.
	Returns the index if found.

	```lua
	local t = {"A", "B", "C"}
	TableUtil.SwapRemoveFirstValue(t, "B")
	```
]=]
function TableUtil.SwapRemoveFirstValue<V>(Source: { V }, Value: V): number?
	local Index = table.find(Source, Value)

	if Index then
		TableUtil.SwapRemove(Source, Index)
	end

	return Index
end

--[=[
	Maps each value through a predicate function.

	```lua
	local doubled = TableUtil.Map({1, 2, 3}, function(v)
		return v * 2
	end)
	-- {2, 4, 6}
	```
]=]
function TableUtil.Map<K, V, R>(Source: { [K]: V }, Predicate: (Value: V, Key: K) -> R): { [K]: R }
	local Result = {}

	for Key, Value in Source do
		Result[Key] = Predicate(Value, Key)
	end

	return Result
end

--[=[
	Filters values based on predicate.

	```lua
	local adults = TableUtil.Filter(people, function(person)
		return person.Age >= 18
	end)
	```
]=]
function TableUtil.Filter<K, V>(Source: { [K]: V }, Predicate: (Value: V, Key: K) -> boolean): { [K]: V }
	local Result = {}

	for Key, Value in Source do
		if Predicate(Value, Key) then
			Result[Key] = Value
		end
	end

	return Result
end

--[=[
	Reduces table to a single value.

	```lua
	local sum = TableUtil.Reduce({1, 2, 3, 4}, function(acc, v)
		return acc + v
	end, 0)
	-- 10
	```
]=]
function TableUtil.Reduce<K, V, R>(Source: { [K]: V }, Predicate: (Accumulator: R, Value: V, Key: K) -> R, Initial: R): R
	local Accumulator = Initial

	for Key, Value in Source do
		Accumulator = Predicate(Accumulator, Value, Key)
	end

	return Accumulator
end

--[=[
	Finds first value matching predicate.

	```lua
	local found = TableUtil.Find(items, function(item)
		return item.Id == targetId
	end)
	```
]=]
function TableUtil.Find<K, V>(Source: { [K]: V }, Predicate: (Value: V, Key: K) -> boolean): (V?, K?)
	for Key, Value in Source do
		if Predicate(Value, Key) then
			return Value, Key
		end
	end

	return nil, nil
end

--[=[
	Returns true if all values pass predicate.

	```lua
	local allPositive = TableUtil.Every(numbers, function(n)
		return n > 0
	end)
	```
]=]
function TableUtil.Every<K, V>(Source: { [K]: V }, Predicate: (Value: V, Key: K) -> boolean): boolean
	for Key, Value in Source do
		if not Predicate(Value, Key) then
			return false
		end
	end

	return true
end

--[=[
	Returns true if any value passes predicate.

	```lua
	local hasNegative = TableUtil.Some(numbers, function(n)
		return n < 0
	end)
	```
]=]
function TableUtil.Some<K, V>(Source: { [K]: V }, Predicate: (Value: V, Key: K) -> boolean): boolean
	for Key, Value in Source do
		if Predicate(Value, Key) then
			return true
		end
	end

	return false
end

--[=[
	Returns array of all keys.

	```lua
	local keys = TableUtil.Keys({a = 1, b = 2})
	-- {"a", "b"}
	```
]=]
function TableUtil.Keys<K, V>(Source: { [K]: V }): { K }
	local Result = {}

	for Key in Source do
		table.insert(Result, Key)
	end

	return Result
end

--[=[
	Returns array of all values.

	```lua
	local values = TableUtil.Values({a = 1, b = 2})
	-- {1, 2}
	```
]=]
function TableUtil.Values<K, V>(Source: { [K]: V }): { V }
	local Result = {}

	for _, Value in Source do
		table.insert(Result, Value)
	end

	return Result
end

--[=[
	Merges tables into target.

	```lua
	local merged = TableUtil.Assign({a = 1}, {b = 2}, {c = 3})
	-- {a = 1, b = 2, c = 3}
	```
]=]
function TableUtil.Assign(Target: any, ...: { [any]: any }): any
	local Sources = { ... }

	for _, Source in Sources do
		for Key, Value in Source do
			Target[Key] = Value
		end
	end

	return Target
end

--[=[
	Extends an array with another array.

	```lua
	local extended = TableUtil.Extend({1, 2}, {3, 4})
	-- {1, 2, 3, 4}
	```
]=]
function TableUtil.Extend<V>(Target: { V }, Extension: { V }): { V }
	local Result = table.clone(Target)

	for _, Value in Extension do
		table.insert(Result, Value)
	end

	return Result
end

--[=[
	Reverses an array.

	```lua
	local reversed = TableUtil.Reverse({1, 2, 3})
	-- {3, 2, 1}
	```
]=]
function TableUtil.Reverse<V>(Source: { V }): { V }
	local Result = {}
	local Length = #Source

	for Index = Length, 1, -1 do
		table.insert(Result, Source[Index])
	end

	return Result
end

--[=[
	Shuffles an array randomly.

	```lua
	local shuffled = TableUtil.Shuffle({1, 2, 3, 4, 5})
	```
]=]
function TableUtil.Shuffle<V>(Source: { V }, RandomGenerator: Random?): { V }
	local Result = table.clone(Source)
	local Generator = RandomGenerator or Random.new()

	for Index = #Result, 2, -1 do
		local Target = Generator:NextInteger(1, Index)
		Result[Index], Result[Target] = Result[Target], Result[Index]
	end

	return Result
end

--[=[
	Returns a random sample of the array.

	```lua
	local sample = TableUtil.Sample({1, 2, 3, 4, 5}, 3)
	```
]=]
function TableUtil.Sample<V>(Source: { V }, SampleSize: number, RandomGenerator: Random?): { V }
	local Shuffled = TableUtil.Shuffle(Source, RandomGenerator)
	local Result = {}

	for Index = 1, math.min(SampleSize, #Shuffled) do
		table.insert(Result, Shuffled[Index])
	end

	return Result
end

--[=[
	Flattens nested arrays to specified depth.

	```lua
	local flat = TableUtil.Flat({{1, 2}, {3, {4, 5}}}, 1)
	-- {1, 2, 3, {4, 5}}
	```
]=]
function TableUtil.Flat<V>(Source: { { V } }, Depth: number?): { V }
	local Result = {}
	local MaxDepth = Depth or 1

	local function FlattenRecursive(Array: { any }, CurrentDepth: number)
		for _, Value in Array do
			if type(Value) == "table" and CurrentDepth < MaxDepth then
				FlattenRecursive(Value, CurrentDepth + 1)
			else
				table.insert(Result, Value)
			end
		end
	end

	FlattenRecursive(Source, 0)
	return Result
end

--[=[
	Maps then flattens the result.

	```lua
	local result = TableUtil.FlatMap({1, 2, 3}, function(v)
		return {v, v * 2}
	end)
	-- {1, 2, 2, 4, 3, 6}
	```
]=]
function TableUtil.FlatMap<V, R>(Source: { V }, Predicate: (Value: V, Index: number) -> { R }): { R }
	return TableUtil.Flat(TableUtil.Map(Source, Predicate), 1)
end

--[=[
	Truncates array to specified length.

	```lua
	local truncated = TableUtil.Truncate({1, 2, 3, 4, 5}, 3)
	-- {1, 2, 3}
	```
]=]
function TableUtil.Truncate<V>(Source: { V }, Length: number): { V }
	local Result = {}

	for Index = 1, math.min(Length, #Source) do
		Result[Index] = Source[Index]
	end

	return Result
end

--[=[
	Iterates multiple tables in parallel.

	```lua
	for key, values in TableUtil.Zip({1, 2}, {"a", "b"}) do
		print(key, values[1], values[2])
	end
	```
]=]
function TableUtil.Zip(...: { any }): () -> (any, { any })
	local Tables = { ... }
	local Index = 0
	local MaxLength = 0

	for _, Tbl in Tables do
		MaxLength = math.max(MaxLength, #Tbl)
	end

	return function()
		Index += 1
		if Index > MaxLength then
			return nil, nil :: any
		end

		local Values = {}
		for TableIndex, Tbl in Tables do
			Values[TableIndex] = Tbl[Index]
		end

		return Index, Values
	end
end

--[=[
	Deep freezes the table using table.freeze.

	```lua
	local frozen = TableUtil.Lock({nested = {value = 1}})
	frozen.nested.value = 2 -- Error!
	```
]=]
function TableUtil.Lock(Source: any): any
	if type(Source) ~= "table" then
		return Source
	end

	for _, Value in Source do
		if type(Value) == "table" then
			TableUtil.Lock(Value)
		end
	end

	return table.freeze(Source :: any)
end

--[=[
	Returns true if table is empty.

	```lua
	TableUtil.IsEmpty({}) -- true
	TableUtil.IsEmpty({1}) -- false
	```
]=]
function TableUtil.IsEmpty(Source: { [any]: any }): boolean
	return next(Source) == nil
end

--[=[
	Returns the number of elements in a table.
	Works for both arrays and dictionaries.

	```lua
	TableUtil.Count({a = 1, b = 2}) -- 2
	```
]=]
function TableUtil.Count(Source: { [any]: any }): number
	local Total = 0

	for _ in Source do
		Total += 1
	end

	return Total
end

--[=[
	Encodes table to JSON string.

	```lua
	local json = TableUtil.EncodeJSON({name = "test"})
	```
]=]
function TableUtil.EncodeJSON(Value: any): string
	return HttpService:JSONEncode(Value)
end

--[=[
	Decodes JSON string to table.

	```lua
	local data = TableUtil.DecodeJSON('{"name":"test"}')
	```
]=]
function TableUtil.DecodeJSON(Value: string): any
	return HttpService:JSONDecode(Value)
end

return TableUtil