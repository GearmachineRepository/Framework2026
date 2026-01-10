--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Packages = require(Shared.Packages)

local Shake = Packages.Shake

local CameraController = {}

local Camera = Workspace.CurrentCamera
local ActiveShakes: { [string]: typeof(Shake.new()) } = {}
local SettingsController: any = nil

local function IsScreenShakeEnabled(): boolean
	if SettingsController then
		return SettingsController.IsScreenShakeEnabled()
	end
	return true
end

function CameraController.Start()
	local Controllers = script.Parent
	SettingsController = require(Controllers.SettingsController)
end

function CameraController.SetMode(Mode: string, Target: Instance?)
	if not Camera then
		return
	end

	if Mode == "Default" then
		Camera.CameraType = Enum.CameraType.Custom
	elseif Mode == "Locked" and Target then
		Camera.CameraType = Enum.CameraType.Scriptable
	end
end

function CameraController.Shake(Key: string, Amplitude: number, Duration: number)
	if not IsScreenShakeEnabled() then
		return
	end

	local ExistingShake = ActiveShakes[Key]
	if ExistingShake then
		ExistingShake:Stop()
	end

	local NewShake = Shake.new()
	NewShake.FadeInTime = 0
	NewShake.FadeOutTime = Duration * 0.3
	NewShake.SustainTime = Duration * 0.7
	NewShake.Frequency = 0.1
	NewShake.Amplitude = Amplitude
	NewShake.PositionInfluence = Vector3.new(0.1, 0.1, 0.1)
	NewShake.RotationInfluence = Vector3.new(0.02, 0.02, 0.02)

	ActiveShakes[Key] = NewShake
	NewShake:Start()

	NewShake:OnSignal(RunService.RenderStepped, function(Position, Rotation, Done)
		if not Camera then
			return
		end
		Camera.CFrame *= CFrame.new(Position) * CFrame.Angles(Rotation.X, Rotation.Y, Rotation.Z)
		if Done then
			ActiveShakes[Key] = nil
		end
	end)
end

function CameraController.StopShake(Key: string)
	local ExistingShake = ActiveShakes[Key]
	if ExistingShake then
		ExistingShake:Stop()
		ActiveShakes[Key] = nil
	end
end

function CameraController.StopAllShakes()
	for Key, ShakeInstance in ActiveShakes do
		ShakeInstance:Stop()
		ActiveShakes[Key] = nil
	end
end

return CameraController