--[[
	SOUNDS – spielt Soundeffekte und Hintergrundmusik.
	Die Sound-IDs stehen in Config.Sounds / Config.Music.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local SoundService = game:GetService("SoundService")

local Config = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config"))

local Sounds = { sfx = true, music = true }
local cache = {}
local currentMusic = nil

local music = Instance.new("Sound")
music.Name = "Musik"
music.Looped = true
music.Volume = 0.3
music.Parent = SoundService

function Sounds.play(name)
	if not Sounds.sfx then return end
	local id = Config.Sounds[name]
	if not id or id == "" then return end
	local s = cache[name]
	if not s then
		s = Instance.new("Sound")
		s.Name = name
		s.SoundId = id
		s.Volume = 0.6
		s.Parent = SoundService
		cache[name] = s
	end
	SoundService:PlayLocalSound(s)
end

function Sounds.setWorld(index)
	local id = Config.Music[index] or ""
	if id == currentMusic then return end
	currentMusic = id
	music:Stop()
	if id ~= "" and Sounds.music then
		music.SoundId = id
		music:Play()
	end
end

function Sounds.setMusic(on)
	Sounds.music = on
	if on and currentMusic and currentMusic ~= "" then
		music.SoundId = currentMusic
		music:Play()
	else
		music:Stop()
	end
end

function Sounds.setSfx(on)
	Sounds.sfx = on
end

return Sounds
