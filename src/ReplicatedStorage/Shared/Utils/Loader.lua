--!strict

local Loader = {}

export type PredicateFn = (Module: ModuleScript) -> boolean

function Loader.LoadChildren(Parent: Instance, Predicate: PredicateFn?): { [string]: any }
	local Loaded: { [string]: any } = {}

	for _, Child in Parent:GetChildren() do
		if not Child:IsA("ModuleScript") then
			continue
		end

		if Predicate and not Predicate(Child) then
			continue
		end

		local Success, Result = pcall(require, Child)
		if Success then
			Loaded[Child.Name] = Result
		else
			warn(string.format("[Loader] Failed to require '%s': %s", Child.Name, tostring(Result)))
		end
	end

	return Loaded
end

function Loader.LoadDescendants(Parent: Instance, Predicate: PredicateFn?): { [string]: any }
	local Loaded: { [string]: any } = {}

	for _, Descendant in Parent:GetDescendants() do
		if not Descendant:IsA("ModuleScript") then
			continue
		end

		if Predicate and not Predicate(Descendant) then
			continue
		end

		local Success, Result = pcall(require, Descendant)
		if Success then
			Loaded[Descendant.Name] = Result
		else
			warn(string.format("[Loader] Failed to require '%s': %s", Descendant.Name, tostring(Result)))
		end
	end

	return Loaded
end

function Loader.MatchesName(Pattern: string): PredicateFn
	return function(Module: ModuleScript): boolean
		return string.match(Module.Name, Pattern) ~= nil
	end
end

function Loader.CallAll(LoadedModules: { [string]: any }, MethodName: string, ...: any)
	for ModuleName, Module in LoadedModules do
		if type(Module) ~= "table" then
			continue
		end

		local Method = Module[MethodName]
		if type(Method) ~= "function" then
			continue
		end

		local Success, ErrorMessage = pcall(Method, ...)
		if not Success then
			warn(string.format("[Loader] %s.%s failed: %s", ModuleName, MethodName, tostring(ErrorMessage)))
		end
	end
end

function Loader.SpawnAll(LoadedModules: { [string]: any }, MethodName: string, ...: any)
	local Args = { ... }

	for ModuleName, Module in LoadedModules do
		if type(Module) ~= "table" then
			continue
		end

		local Method = Module[MethodName]
		if type(Method) ~= "function" then
			continue
		end

		task.spawn(function()
			local Success, ErrorMessage = pcall(Method, table.unpack(Args))
			if not Success then
				warn(string.format("[Loader] %s.%s failed: %s", ModuleName, MethodName, tostring(ErrorMessage)))
			end
		end)
	end
end

return Loader