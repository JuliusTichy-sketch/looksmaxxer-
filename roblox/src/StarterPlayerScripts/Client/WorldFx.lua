--[[
	WORLDFX – Licht, Nebel und Musik passend zur Welt,
	und versteckt den eigenen "Mog Battle"-Knopf am eigenen Körper.
]]

local Players = game:GetService("Players")
local Lighting = game:GetService("Lighting")
local TweenService = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config"))
local Sounds = require(script.Parent:WaitForChild("Sounds"))

local WorldFx = {}
local player = Players.LocalPlayer
local lastWorld = nil

local function apply(index)
	if index == lastWorld then return end
	lastWorld = index
	local w = Config.Worlds[index]
	if not w then return end
	local L = w.light
	TweenService:Create(Lighting, TweenInfo.new(1.5), {
		ClockTime = L.ClockTime, Ambient = L.Ambient, OutdoorAmbient = L.Ambient,
		FogColor = L.Fog, FogEnd = L.FogEnd,
	}):Play()
	Sounds.setWorld(index)
end

local function hideOwnPrompt(char)
	local hrp = char:WaitForChild("HumanoidRootPart", 10)
	if not hrp then return end
	local pr = hrp:WaitForChild("MogPrompt", 15)
	if pr then pr.Enabled = false end
end

function WorldFx.init()
	apply(player:GetAttribute("World") or 1)
	player:GetAttributeChangedSignal("World"):Connect(function()
		apply(player:GetAttribute("World") or 1)
	end)
	player.CharacterAdded:Connect(hideOwnPrompt)
	if player.Character then
		task.spawn(hideOwnPrompt, player.Character)
	end
end

return WorldFx
