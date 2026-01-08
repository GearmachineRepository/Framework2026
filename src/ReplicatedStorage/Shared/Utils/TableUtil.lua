--!strict

local HttpService = game:GetService("HttpService")

local TableUtil = {}

function TableUtil.Copy(Source: any, Deep: boolean?): any
	if type(Source) ~= "table" then
		return Source
	end

	local Result = {}

	for Key, Value in Source do
		if Deep and type(Value) == "table" then
			Result[Key] = TableUtil.Copy(Value, true)
		else
			Result[Key] = Value
		end
	end

	return Result
end

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

function TableUtil.Map<K, V, R>(Source: { [K]: V }, Predicate: (Value: V, Key: K) -> R): { [K]: R }
	local Result = {}

	for Key, Value in Source do
		Result[Key] = Predicate(Value, Key)
	end

	return Result
end

function TableUtil.Filter<K, V>(Source: { [K]: V }, Predicate: (Value: V, Key: K) -> boolean): { [K]: V }
	local Result = {}

	for Key, Value in Source do
		if Predicate(Value, Key) then
			Result[Key] = Value
		end
	end

	return Result
end

function TableUtil.Reduce<K, V, R>(Source: { [K]: V }, Predicate: (Accumulator: R, Value: V, Key: K) -> R, Initial: R): R
	local Accumulator = Initial

	for Key, Value in Source do
		Accumulator = Predicate(Accumulator, Value, Key)
	end

	return Accumulator
end

function TableUtil.Find<K, V>(Source: { [K]: V }, Predicate: (Value: V, Key: K) -> boolean): (V?, K?)
	for Key, Value in Source do
		if Predicate(Value, Key) then
			return Value, Key
		end
	end

	return nil, nil
end

function TableUtil.Every<K, V>(Source: { [K]: V }, Predicate: (Value: V, Key: K) -> boolean): boolean
	for Key, Value in Source do
		if not Predicate(Value, Key) then
			return false
		end
	end

	return true
end

function TableUtil.Some<K, V>(Source: { [K]: V }, Predicate: (Value: V, Key: K) -> boolean): boolean
	for Key, Value in Source do
		if Predicate(Value, Key) then
			return true
		end
	end

	return false
end

function TableUtil.Keys<K, V>(Source: { [K]: V }): { K }
	local Result = {}

	for Key in Source do
		table.insert(Result, Key)
	end

	return Result
end

function TableUtil.Values<K, V>(Source: { [K]: V }): { V }
	local Result = {}

	for _, Value in Source do
		table.insert(Result, Value)
	end

	return Result
end

function TableUtil.Assign(Target: any, ...: { [any]: any }): any
	local Sources = { ... }

	for _, Source in Sources do
		for Key, Value in Source do
			Target[Key] = Value
		end
	end

	return Target
end

function TableUtil.Extend<V>(Target: { V }, Extension: { V }): { V }
	local Result = table.clone(Target)

	for _, Value in Extension do
		table.insert(Result, Value)
	end

	return Result
end

function TableUtil.Reverse<V>(Source: { V }): { V }
	local Result = {}
	local Length = #Source

	for Index = Length, 1, -1 do
		table.insert(Result, Source[Index])
	end

	return Result
end

function TableUtil.Shuffle<V>(Source: { V }, RandomGenerator: Random?): { V }
	local Result = table.clone(Source)
	local Generator = RandomGenerator or Random.new()

	for Index = #Result, 2, -1 do
		local Target = Generator:NextInteger(1, Index)
		Result[Index], Result[Target] = Result[Target], Result[Index]
	end

	return Result
end

function TableUtil.Sample<V>(Source: { V }, SampleSize: number, RandomGenerator: Random?): { V }
	local Shuffled = TableUtil.Shuffle(Source, RandomGenerator)
	local Result = {}

	for Index = 1, math.min(SampleSize, #Shuffled) do
		table.insert(Result, Shuffled[Index])
	end

	return Result
end

function TableUtil.SwapRemove<V>(Source: { V }, Index: number)
	local Length = #Source
	Source[Index] = Source[Length]
	Source[Length] = nil
end

function TableUtil.SwapRemoveValue<V>(Source: { V }, Value: V): number?
	local Index = table.find(Source, Value)

	if Index then
		TableUtil.SwapRemove(Source, Index)
	end

	return Index
end

function TableUtil.Flatten<V>(Source: { { V } }, Depth: number?): { V }
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

function TableUtil.Truncate<V>(Source: { V }, Length: number): { V }
	local Result = {}

	for Index = 1, math.min(Length, #Source) do
		Result[Index] = Source[Index]
	end

	return Result
end

function TableUtil.IsEmpty(Source: { [any]: any }): boolean
	return next(Source) == nil
end

function TableUtil.Count(Source: { [any]: any }): number
	local Total = 0

	for _ in Source do
		Total = Total + 1
	end

	return Total
end

function TableUtil.Freeze(Source: any): any
	if type(Source) ~= "table" then
		return Source
	end

	for _, Value in Source do
		if type(Value) == "table" then
			TableUtil.Freeze(Value)
		end
	end

	return table.freeze(Source :: any)
end

function TableUtil.EncodeJSON(Value: any): string
	return HttpService:JSONEncode(Value)
end

function TableUtil.DecodeJSON(Value: string): any
	return HttpService:JSONDecode(Value)
end

return TableUtil