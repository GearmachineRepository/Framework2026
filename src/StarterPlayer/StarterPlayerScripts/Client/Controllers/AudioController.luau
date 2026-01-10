--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local SoundService = game:GetService("SoundService")
local TweenService = game:GetService("TweenService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Packages = require(Shared.Packages)
local Packets = require(Shared.Network.Packets)
local AudioTypes = require(Shared.Types.AudioTypes)

local Trove = Packages.Trove

type SoundConfig = AudioTypes.SoundConfig
type MusicConfig = AudioTypes.MusicConfig

local AudioController = {}

local ControllerTrove = Trove.new()
local MusicGroup: SoundGroup
local SfxGroup: SoundGroup
local CurrentMusic: Sound?

local SettingsController: any = nil

local function GetSfxVolume(): number
	if SettingsController then
		return SettingsController.GetSetting("SfxVolume") :: number
	end
	return 1
end

local function GetMusicVolume(): number
	if SettingsController then
		return SettingsController.GetSetting("MusicVolume") :: number
	end
	return 1
end

function AudioController.Init()
	MusicGroup = Instance.new("SoundGroup")
	MusicGroup.Name = "Music"
	MusicGroup.Volume = 1
	MusicGroup.Parent = SoundService

	SfxGroup = Instance.new("SoundGroup")
	SfxGroup.Name = "Sfx"
	SfxGroup.Volume = 1
	SfxGroup.Parent = SoundService

	ControllerTrove:Add(MusicGroup)
	ControllerTrove:Add(SfxGroup)
end

function AudioController.Start()
	local Controllers = script.Parent
	SettingsController = require(Controllers.SettingsController)

	ControllerTrove:Add(SettingsController.SettingChanged:Connect(function(Key: string, Value: any)
		if Key == "MusicVolume" then
			MusicGroup.Volume = Value :: number
		elseif Key == "SfxVolume" then
			SfxGroup.Volume = Value :: number
		end
	end))

	MusicGroup.Volume = GetMusicVolume()
	SfxGroup.Volume = GetSfxVolume()

	ControllerTrove:Add(Packets.PlaySound.OnClientEvent:Connect(function(SoundId: string, Position: Vector3?, Config: SoundConfig?)
		AudioController.PlaySound(SoundId, Position, Config)
	end))

	ControllerTrove:Add(Packets.PlayMusic.OnClientEvent:Connect(function(SoundId: string, Config: MusicConfig?)
		AudioController.PlayMusic(SoundId, Config)
	end))

	ControllerTrove:Add(Packets.StopMusic.OnClientEvent:Connect(function(FadeTime: number?)
		AudioController.StopMusic(FadeTime)
	end))
end

function AudioController.PlaySound(SoundId: string, Position: Vector3?, Config: SoundConfig?): Sound
	local SoundConfig = Config or AudioTypes.DEFAULT_SOUND_CONFIG

	local NewSound = Instance.new("Sound")
	NewSound.SoundId = SoundId
	NewSound.SoundGroup = SfxGroup
	NewSound.Volume = SoundConfig.Volume or 1
	NewSound.PlaybackSpeed = SoundConfig.PlaybackSpeed or 1
	NewSound.TimePosition = SoundConfig.TimePosition or 0
	NewSound.Looped = SoundConfig.Looped or false

	if Position then
		NewSound.RollOffMode = AudioTypes.GetRollOffMode(SoundConfig.RollOffMode)
		NewSound.RollOffMinDistance = SoundConfig.RollOffMinDistance or 10
		NewSound.RollOffMaxDistance = SoundConfig.RollOffMaxDistance or 100

		local Part = Instance.new("Part")
		Part.Anchored = true
		Part.CanCollide = false
		Part.CanQuery = false
		Part.CanTouch = false
		Part.Transparency = 1
		Part.Size = Vector3.one
		Part.Position = Position
		Part.Parent = workspace

		NewSound.Parent = Part

		NewSound.Ended:Once(function()
			Part:Destroy()
		end)
	else
		NewSound.Parent = SoundService

		NewSound.Ended:Once(function()
			NewSound:Destroy()
		end)
	end

	NewSound:Play()
	return NewSound
end

function AudioController.PlayMusic(SoundId: string, Config: MusicConfig?)
	local MusicConfig = Config or AudioTypes.DEFAULT_MUSIC_CONFIG
	local FadeTime = MusicConfig.FadeTime or 1

	if CurrentMusic then
		local OldMusic = CurrentMusic
		TweenService:Create(OldMusic, TweenInfo.new(FadeTime), { Volume = 0 }):Play()
		task.delay(FadeTime, function()
			OldMusic:Destroy()
		end)
	end

	local NewMusic = Instance.new("Sound")
	NewMusic.SoundId = SoundId
	NewMusic.SoundGroup = MusicGroup
	NewMusic.Looped = if MusicConfig.Looped ~= nil then MusicConfig.Looped else true
	NewMusic.Volume = 0
	NewMusic.PlaybackSpeed = MusicConfig.PlaybackSpeed or 1
	NewMusic.Parent = SoundService

	CurrentMusic = NewMusic
	NewMusic:Play()

	local TargetVolume = MusicConfig.Volume or 1
	TweenService:Create(NewMusic, TweenInfo.new(FadeTime), { Volume = TargetVolume }):Play()
end

function AudioController.StopMusic(FadeTime: number?)
	if not CurrentMusic then
		return
	end

	local Fade = FadeTime or 1
	local Music = CurrentMusic
	CurrentMusic = nil

	TweenService:Create(Music, TweenInfo.new(Fade), { Volume = 0 }):Play()
	task.delay(Fade, function()
		Music:Destroy()
	end)
end

function AudioController.SetMusicVolume(Volume: number)
	MusicGroup.Volume = math.clamp(Volume, 0, 1)
end

function AudioController.SetSfxVolume(Volume: number)
	SfxGroup.Volume = math.clamp(Volume, 0, 1)
end

function AudioController.GetMusicGroup(): SoundGroup
	return MusicGroup
end

function AudioController.GetSfxGroup(): SoundGroup
	return SfxGroup
end

return AudioController