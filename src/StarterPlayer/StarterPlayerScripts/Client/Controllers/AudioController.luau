--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local SoundService = game:GetService("SoundService")
local TweenService = game:GetService("TweenService")

local Packages = require(ReplicatedStorage.Shared.Packages)
local Trove = Packages.Trove

local AudioController = {}

local ControllerTrove = Trove.new()
local MusicGroup: SoundGroup
local SfxGroup: SoundGroup
local CurrentMusic: Sound?

local Volumes = {
    Music = 1,
    Sfx = 1,
}

function AudioController.Init()
    MusicGroup = Instance.new("SoundGroup")
    MusicGroup.Name = "Music"
    MusicGroup.Volume = Volumes.Music
    MusicGroup.Parent = SoundService

    SfxGroup = Instance.new("SoundGroup")
    SfxGroup.Name = "Sfx"
    SfxGroup.Volume = Volumes.Sfx
    SfxGroup.Parent = SoundService

    ControllerTrove:Add(MusicGroup)
    ControllerTrove:Add(SfxGroup)
end

function AudioController.Start()
end

function AudioController.PlaySound(SoundId: string, Position: Vector3?): Sound
    local Sound = Instance.new("Sound")
    Sound.SoundId = SoundId
    Sound.SoundGroup = SfxGroup

    if Position then
        local Part = Instance.new("Part")
        Part.Anchored = true
        Part.CanCollide = false
        Part.Transparency = 1
        Part.Size = Vector3.one
        Part.Position = Position
        Part.Parent = workspace
        Sound.Parent = Part
        Sound.Ended:Once(function()
            Part:Destroy()
        end)
    else
        Sound.Parent = SoundService
        Sound.Ended:Once(function()
            Sound:Destroy()
        end)
    end

    Sound:Play()
    return Sound
end

function AudioController.PlayMusic(SoundId: string, FadeTime: number?)
    local Fade = FadeTime or 1

    if CurrentMusic then
        local OldMusic = CurrentMusic
        TweenService:Create(OldMusic, TweenInfo.new(Fade), { Volume = 0 }):Play()
        task.delay(Fade, function()
            OldMusic:Destroy()
        end)
    end

    local NewMusic = Instance.new("Sound")
    NewMusic.SoundId = SoundId
    NewMusic.SoundGroup = MusicGroup
    NewMusic.Looped = true
    NewMusic.Volume = 0
    NewMusic.Parent = SoundService

    CurrentMusic = NewMusic
    NewMusic:Play()
    TweenService:Create(NewMusic, TweenInfo.new(Fade), { Volume = 1 }):Play()
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

function AudioController.SetVolume(Category: "Music" | "Sfx", Volume: number)
    Volumes[Category] = Volume
    if Category == "Music" then
        MusicGroup.Volume = Volume
    else
        SfxGroup.Volume = Volume
    end
end

return AudioController