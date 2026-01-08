--!strict

--[[
	Loader

	Loads and manages ModuleScripts with optional lifecycle methods.

	```lua
	local modules = Loader.LoadChildren(script.Parent.Services)
	Loader.CallAll(modules, "Init")
	Loader.SpawnAll(modules, "Start")
	```
]]

export type PredicateFn = (Module: ModuleScript) -> boolean

local Loader = {}

--[=[
	Loads all ModuleScript children of the parent.
	Returns a dictionary of module name to module.

	```lua
	local services = Loader.LoadChildren(ServerScriptService.Services)
	```
]=]
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

--[=[
	Loads all ModuleScript descendants of the parent.

	```lua
	local modules = Loader.LoadDescendants(ReplicatedStorage.Shared)
	```
]=]
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

--[=[
	Returns a predicate that matches module names against a pattern.

	```lua
	local services = Loader.LoadChildren(folder, Loader.MatchesName("Service$"))
	```
]=]
function Loader.MatchesName(Pattern: string): PredicateFn
	return function(Module: ModuleScript): boolean
		return string.match(Module.Name, Pattern) ~= nil
	end
end

--[=[
	Calls a method on all loaded modules synchronously.

	```lua
	Loader.CallAll(services, "Init")
	```
]=]
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

--[=[
	Calls a method on all loaded modules in separate threads.

	```lua
	Loader.SpawnAll(services, "Start")
	```
]=]
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

--[=[
	Loads modules and provides Init/Start lifecycle helpers.

	```lua
	local bootstrap = Loader.Bootstrap(script.Parent.Services)
	bootstrap:Init()
	bootstrap:Start()
	```
]=]
function Loader.Bootstrap(Parent: Instance, Predicate: PredicateFn?): {
	Modules: { [string]: any },
	Init: () -> (),
	Start: () -> (),
	Get: (Name: string) -> any?,
}
	local LoadedModules = Loader.LoadChildren(Parent, Predicate)
	local Initialized: { [string]: boolean } = {}
	local Started: { [string]: boolean } = {}

	return {
		Modules = LoadedModules,

		Init = function()
			for ModuleName, Module in LoadedModules do
				if Initialized[ModuleName] then
					continue
				end

				Initialized[ModuleName] = true

				if type(Module) ~= "table" or type(Module.Init) ~= "function" then
					continue
				end

				local Success, ErrorMessage = pcall(Module.Init)
				if not Success then
					warn(string.format("[Loader] %s.Init failed: %s", ModuleName, tostring(ErrorMessage)))
				end
			end
		end,

		Start = function()
			for ModuleName, Module in LoadedModules do
				if Started[ModuleName] then
					continue
				end

				Started[ModuleName] = true

				if type(Module) ~= "table" or type(Module.Start) ~= "function" then
					continue
				end

				task.spawn(function()
					local Success, ErrorMessage = pcall(Module.Start)
					if not Success then
						warn(string.format("[Loader] %s.Start failed: %s", ModuleName, tostring(ErrorMessage)))
					end
				end)
			end
		end,

		Get = function(Name: string): any?
			return LoadedModules[Name]
		end,
	}
end

return Loader