--!strict

local Types = require(script.Types)
local EventBus = require(script.EventBus)
local Entity = require(script.Core.Entity)
local EntityBuilder = require(script.Core.EntityBuilder)
local ComponentLoader = require(script.Core.ComponentLoader)
local UpdateSystem = require(script.Systems.UpdateSystem)

type InitConfig = {
	Components: Instance,
	Signal: () -> Types.Signal<any>,
	Maid: () -> Types.Maid,
	Archetypes: { [string]: { string } }?,
}

local Ensemble = {}

local Initialized = false

function Ensemble.Init(Config: InitConfig)
	if Initialized then
		error(Types.EngineName .. " Already initialized")
	end

	if not Config.Components then
		error(Types.EngineName .. " Config.Components is required")
	end

	if not Config.Signal then
		error(Types.EngineName .. " Config.Signal is required")
	end

	if not Config.Maid then
		error(Types.EngineName .. " Config.Maid is required")
	end

	EventBus.Configure(Config.Signal)
	ComponentLoader.Configure(Config.Components)

	EntityBuilder.SetMaidConstructor(Config.Maid)
	EntityBuilder.SetEventBus(EventBus)

	if Config.Archetypes then
		EntityBuilder.SetArchetypes(Config.Archetypes)
	end

	UpdateSystem.Configure(ComponentLoader, EventBus)
	UpdateSystem.Start()

	Initialized = true

	print(Types.EngineName .. " Initialized")
	print(string.format("%s  Components: %d", Types.EngineName, #ComponentLoader.GetAllNames()))
end

function Ensemble.CreateEntity(Character: Model, Context: Types.EntityContext?): Types.EntityBuilder
	if not Initialized then
		error(Types.EngineName .. " Not initialized")
	end

	return EntityBuilder.Create(Character, Context)
end

function Ensemble.GetEntity(Character: Model): Types.Entity?
	return Entity.Get(Character)
end

function Ensemble.GetAllEntities(): { Types.Entity }
	return Entity.GetAll()
end

function Ensemble.DestroyEntity(Character: Model)
	local EntityInstance = Entity.Get(Character)
	if EntityInstance then
		EventBus.Publish("EntityDestroyed", {
			Entity = EntityInstance,
			Character = Character,
		})
		EntityInstance:Destroy()
	end
end

Ensemble.Events = EventBus
Ensemble.Types = Types

return Ensemble