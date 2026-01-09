--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Packages = require(Shared.Packages)
local Packets = require(Shared.Network.Packets)

local Trove = Packages.Trove

local EntityController = {}

local LocalPlayer = Players.LocalPlayer
local Entities: { [Instance]: { Stats: { [string]: number }, States: { [string]: boolean } } } = {}
local ControllerTrove = Trove.new()

function EntityController.Init()
end

function EntityController.Start()
    ControllerTrove:Add(Packets.EntitySpawned.OnClientEvent:Connect(function(Character, Data)
        Entities[Character] = {
            Stats = Data.Stats or {},
            States = Data.States or {},
        }
    end))

    ControllerTrove:Add(Packets.EntityDespawned.OnClientEvent:Connect(function(Character)
        Entities[Character] = nil
    end))

    ControllerTrove:Add(Packets.StatChanged.OnClientEvent:Connect(function(StatName, NewValue, _OldValue)
        local Character = LocalPlayer.Character
        if Character and Entities[Character] then
            Entities[Character].Stats[StatName] = NewValue
        end
    end))

    ControllerTrove:Add(Packets.StateChanged.OnClientEvent:Connect(function(StateName, Value)
        local Character = LocalPlayer.Character
        if Character and Entities[Character] then
            Entities[Character].States[StateName] = Value
        end
    end))
end

function EntityController.GetEntity(Character: Instance)
    return Entities[Character]
end

function EntityController.GetLocalEntity()
    local Character = LocalPlayer.Character
    if not Character then
        return
    end
    return Entities[Character]
end

return EntityController