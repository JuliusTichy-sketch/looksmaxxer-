--[[
	WORLDFX – Licht, Atmosphäre, Wolken, Bloom und Musik passend zur Welt,
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

-- Nachbearbeitung für eine realistischere Optik (wie in großen Roblox-Spielen)
local fx = {}
local function ensure(className, parent, name)
	local inst = parent:FindFirstChild(name)
	if not inst then
		local ok, created = pcall(function()
			local i = Instance.new(className)
			i.Name = name
			i.Parent = parent
			return i
		end)
		if ok then inst = created end
	end
	return inst
end

local function setupPost()
	fx.atmo = ensure("Atmosphere", Lighting, "LMX_Atmosphere")
	fx.bloom = ensure("BloomEffect", Lighting, "LMX_Bloom")
	fx.cc = ensure("ColorCorrectionEffect", Lighting, "LMX_Color")
	fx.rays = ensure("SunRaysEffect", Lighting, "LMX_SunRays")
	fx.depth = ensure("DepthOfFieldEffect", Lighting, "LMX_Depth")
	fx.clouds = ensure("Clouds", workspace.Terrain, "LMX_Clouds")
	pcall(function()
		Lighting.Brightness = 2.6
		Lighting.EnvironmentDiffuseScale = 1
		Lighting.EnvironmentSpecularScale = 1
		Lighting.ShadowSoftness = 0.25
		fx.bloom.Intensity = 0.7
		fx.bloom.Size = 28
		fx.bloom.Threshold = 1.4
		fx.rays.Intensity = 0.07
		fx.rays.Spread = 0.6
		fx.depth.FarIntensity = 0.12
		fx.depth.FocusDistance = 60
		fx.depth.InFocusRadius = 80
		fx.depth.NearIntensity = 0
	end)
end

local function apply(index)
	if index == lastWorld then return end
	lastWorld = index
	local w = Config.Worlds[index]
	if not w then return end
	local L = w.light
	local night = L.ClockTime < 6 or L.ClockTime > 19
	TweenService:Create(Lighting, TweenInfo.new(1.5), {
		ClockTime = L.ClockTime, Ambient = L.Ambient, OutdoorAmbient = L.Ambient:Lerp(Color3.new(1, 1, 1), 0.15),
		FogColor = L.Fog, FogEnd = L.FogEnd,
	}):Play()
	pcall(function()
		local info = TweenInfo.new(1.5)
		if fx.atmo then
			TweenService:Create(fx.atmo, info, {
				Density = night and 0.42 or 0.3, Offset = 0.15, Haze = night and 2.2 or 1.4, Glare = night and 0 or 0.6,
				Color = L.Fog, Decay = L.Fog:Lerp(Color3.new(0, 0, 0), 0.45),
			}):Play()
		end
		if fx.cc then
			TweenService:Create(fx.cc, info, {
				Saturation = 0.15, Contrast = 0.1, Brightness = night and 0.02 or 0,
				TintColor = Color3.new(1, 1, 1):Lerp(L.Fog, 0.12),
			}):Play()
		end
		if fx.bloom then fx.bloom.Threshold = night and 1.1 or 1.4 end
		if fx.clouds then
			fx.clouds.Enabled = index ~= #Config.Worlds   -- im Weltall keine Wolken
			fx.clouds.Cover = night and 0.45 or 0.62
			fx.clouds.Density = 0.55
			fx.clouds.Color = night and L.Fog or Color3.new(1, 1, 1)
		end
	end)
	Sounds.setWorld(index)
end

local function hideOwnPrompt(char)
	local hrp = char:WaitForChild("HumanoidRootPart", 10)
	if not hrp then return end
	-- eigene Knöpfe (Mog Battle, Handeln) am eigenen Körper ausblenden
	for _, name in ipairs({ "MogPrompt", "TradePrompt" }) do
		local pr = hrp:WaitForChild(name, 15)
		if pr then pr.Enabled = false end
	end
end

function WorldFx.init()
	setupPost()
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
