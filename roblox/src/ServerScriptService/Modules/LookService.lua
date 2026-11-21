--[[
	LOOKSERVICE – dein Avatar verändert sich sichtbar mit den Upgrades.
	Am Anfang: richtig hässlich. Mit jeder Stufe wird es langsam besser.

	Kategorie (Summe der Stufen, max. 250)   → was man sieht
	Skincare     → Pickel verschwinden (bis 40), kränklich-grüne Haut wird normal (bis 40), ab 120 glänzende Haut
	Haare        → struppige Haare verschwinden (bis 42), ab 60 Glanz, ab 150 goldene Strähne, ab 230 Krone
	Fitness      → von schmächtig (0,85) zu breiten Schultern (1,45)
	Haltung      → von krummem Buckel zu aufrechter Haltung (bis 55)
	Schlaf       → Augenringe verschwinden (bis 30)
	Style        → Ketchup-Fleck weg (ab 3), Uhr (20), Parfum-Wolke (40), Goldkette (60), Sonnenbrille (120), Umhang (200)
	Zähne        → grüne Mundgeruch-Wolke weg (ab 10), ab 80 blitzendes Lächeln
	Selbstbewusstsein → nervöse Schweißtropfen weg (ab 15), ab 100 Sterne um den Kopf
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Logic = require(Shared:WaitForChild("Logic"))

local LookService = {}

local SICK = Color3.fromRGB(150, 175, 110)     -- kränkliche Hautfarbe am Anfang
local GOLD = Color3.fromRGB(255, 205, 60)
local BLACK = Color3.fromRGB(20, 20, 25)

-- Teil erstellen und fest an ein Körperteil schweißen
local function attach(folder, base, size, offset, color, opts)
	opts = opts or {}
	local p = Instance.new("Part")
	p.Name = opts.name or "Look"
	p.Size = size
	p.Color = color
	p.Material = opts.material or Enum.Material.SmoothPlastic
	p.Transparency = opts.transparency or 0
	p.CanCollide = false
	p.CanQuery = false
	p.CanTouch = false
	p.Massless = true
	p.CastShadow = false
	p.Anchored = false
	if opts.ball then
		local m = Instance.new("SpecialMesh")
		m.MeshType = Enum.MeshType.Sphere
		m.Parent = p
	end
	p.CFrame = base.CFrame * offset
	local w = Instance.new("WeldConstraint")
	w.Part0 = base
	w.Part1 = p
	w.Parent = p
	p.Parent = folder
	return p
end

local function emitter(parentPart, color, rate, opts)
	opts = opts or {}
	local e = Instance.new("ParticleEmitter")
	e.Color = ColorSequence.new(color)
	e.Rate = rate
	e.Lifetime = opts.lifetime or NumberRange.new(0.8, 1.4)
	e.Speed = opts.speed or NumberRange.new(0.5, 1.5)
	e.SpreadAngle = opts.spread or Vector2.new(180, 180)
	e.Size = opts.size or NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.3), NumberSequenceKeypoint.new(1, 0) })
	e.LightEmission = opts.light or 0.5
	e.Acceleration = opts.acceleration or Vector3.new(0, 0, 0)
	e.EmissionDirection = opts.direction or Enum.NormalId.Top
	if opts.transparency then e.Transparency = opts.transparency end
	e.Parent = parentPart
	return e
end

-- Körperhaltung über die Gelenke (nur R15)
local function setMotor(motor, angleDeg)
	if not motor or not motor:IsA("Motor6D") then return end
	local orig = motor:GetAttribute("OrigC0")
	if not orig then
		orig = motor.C0
		motor:SetAttribute("OrigC0", orig)
	end
	motor.C0 = orig * CFrame.Angles(math.rad(-angleDeg), 0, 0)
end

function LookService.apply(player, char, data)
	local head = char:FindFirstChild("Head")
	local hum = char:FindFirstChildOfClass("Humanoid")
	local torso = char:FindFirstChild("UpperTorso") or char:FindFirstChild("Torso")
	if not head or not hum or not torso then return end

	local function cat(id) return Logic.catLevels(data.levels, id) end
	local skin, hair, fit, sleep = cat("skin"), cat("hair"), cat("fit"), cat("sleep")
	local posture, style, teeth, conf = cat("posture"), cat("style"), cat("teeth"), cat("conf")

	local old = char:FindFirstChild("GlowUpLook")
	if old then old:Destroy() end
	local folder = Instance.new("Folder")
	folder.Name = "GlowUpLook"
	folder.Parent = char

	local hs = head.Size
	local front = -hs.Z / 2 - 0.03

	-- 1) SKINCARE: Hautfarbe & Pickel & Glanz
	if player:HasAppearanceLoaded() then
		local tint = 0.55 * (1 - math.min(1, skin / 40))
		for _, p in ipairs(char:GetChildren()) do
			if p:IsA("BasePart") and p.Name ~= "HumanoidRootPart" then
				local orig = p:GetAttribute("OrigColor")
				if not orig then
					orig = p.Color
					p:SetAttribute("OrigColor", orig)
				end
				p.Color = orig:Lerp(SICK, tint)
			end
		end
	end
	local pimpleSpots = { { -0.55, 0.3 }, { 0.6, 0.42 }, { -0.4, -0.35 }, { 0.5, -0.3 }, { 0.1, 0.62 }, { -0.7, -0.05 }, { 0.72, 0.05 }, { 0.2, -0.55 } }
	local pimples = math.max(0, #pimpleSpots - math.floor(skin / 5))
	for i = 1, pimples do
		local sp = pimpleSpots[i]
		attach(folder, head, Vector3.new(0.16, 0.16, 0.1), CFrame.new(sp[1] * hs.X / 2, sp[2] * hs.Y / 2, front), Color3.fromRGB(205, 60, 60), { ball = true, name = "Pickel" })
	end
	if skin >= 120 then
		local glowPart = attach(folder, head, Vector3.new(0.2, 0.2, 0.2), CFrame.new(0, 0, 0), Color3.new(1, 1, 1), { transparency = 1 })
		emitter(glowPart, Color3.fromRGB(255, 255, 255), math.min(8, (skin - 100) / 20), { size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.18), NumberSequenceKeypoint.new(1, 0) }), light = 1 })
	end

	-- 2) HAARE: struppig → gepflegt → Glanz → goldene Strähne → Krone
	local spikes = math.max(0, 7 - math.floor(hair / 6))
	for i = 1, spikes do
		local a = (i - (spikes + 1) / 2) * 22
		attach(folder, head, Vector3.new(0.14, 0.75, 0.14), CFrame.new(0, hs.Y / 2, 0) * CFrame.Angles(math.rad((i % 2 == 0) and 15 or -12), 0, math.rad(a)) * CFrame.new(0, 0.35, 0),
			Color3.fromRGB(70, 50, 35), { name = "Strähne" })
	end
	if hair >= 60 then
		local shine = attach(folder, head, Vector3.new(0.2, 0.2, 0.2), CFrame.new(0, hs.Y / 2 + 0.2, 0), Color3.new(1, 1, 1), { transparency = 1 })
		emitter(shine, Color3.fromRGB(255, 255, 255), 2, { size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.15), NumberSequenceKeypoint.new(1, 0) }), light = 1 })
	end
	if hair >= 150 then
		attach(folder, head, Vector3.new(0.25, 0.25, hs.Z * 0.9), CFrame.new(hs.X * 0.18, hs.Y / 2 + 0.08, 0) * CFrame.Angles(0, 0, math.rad(-15)), GOLD, { material = Enum.Material.Neon, ball = true, name = "Goldsträhne" })
	end
	if hair >= 230 then
		for i = 0, 7 do
			local a = i / 8 * math.pi * 2
			attach(folder, head, Vector3.new(0.18, 0.4, 0.18), CFrame.new(math.cos(a) * hs.X * 0.4, hs.Y / 2 + 0.55, math.sin(a) * hs.Z * 0.4), GOLD, { material = Enum.Material.Neon, name = "Krone" })
		end
	end

	-- 3) FITNESS: schmächtig → breit (nur R15)
	local width = 0.85 + math.min(0.6, fit / 250 * 0.6)
	pcall(function()
		local ws = hum:FindFirstChild("BodyWidthScale")
		local ds = hum:FindFirstChild("BodyDepthScale")
		if ws then ws.Value = width end
		if ds then ds.Value = 0.9 + (width - 0.85) * 0.6 end
	end)

	-- 4) HALTUNG: Buckel → aufrecht (nur R15)
	local slouch = math.max(0, 22 - posture * 0.4)
	pcall(function()
		local upper = char:FindFirstChild("UpperTorso")
		setMotor(upper and upper:FindFirstChild("Waist"), slouch)
		setMotor(head:FindFirstChild("Neck"), slouch * 0.8)
	end)

	-- 5) SCHLAF: Augenringe
	if sleep < 30 then
		local tr = 0.15 + (sleep / 30) * 0.85
		for _, s in ipairs({ -1, 1 }) do
			attach(folder, head, Vector3.new(hs.X * 0.22, hs.Y * 0.08, 0.08), CFrame.new(s * hs.X * 0.2, -hs.Y * 0.02, front), Color3.fromRGB(80, 50, 85),
				{ ball = true, transparency = tr, name = "Augenring" })
		end
	end

	-- 6) STYLE
	if style < 3 then
		attach(folder, torso, Vector3.new(0.55, 0.45, 0.06), CFrame.new(torso.Size.X * 0.2, torso.Size.Y * 0.15, -torso.Size.Z / 2 - 0.03), Color3.fromRGB(170, 40, 25),
			{ ball = true, name = "Ketchupfleck" })
	end
	local leftArm = char:FindFirstChild("LeftLowerArm") or char:FindFirstChild("Left Arm")
	if style >= 20 and leftArm then
		attach(folder, leftArm, Vector3.new(leftArm.Size.X + 0.08, 0.25, leftArm.Size.Z + 0.08), CFrame.new(0, -leftArm.Size.Y * 0.3, 0), GOLD,
			{ material = Enum.Material.Foil, name = "Uhr" })
	end
	if style >= 40 then
		local scent = attach(folder, torso, Vector3.new(0.2, 0.2, 0.2), CFrame.new(0, torso.Size.Y * 0.4, 0), Color3.new(1, 1, 1), { transparency = 1 })
		emitter(scent, Color3.fromRGB(255, 150, 220), 3, { speed = NumberRange.new(1, 2), light = 0.3 })
	end
	if style >= 60 then
		for i = 0, 9 do
			local a = math.rad(200 + i * 14)
			attach(folder, torso, Vector3.new(0.13, 0.13, 0.13), CFrame.new(math.cos(a) * torso.Size.X * 0.28, torso.Size.Y * 0.42 + math.sin(a) * 0.35, -torso.Size.Z / 2 - 0.05),
				GOLD, { material = Enum.Material.Neon, ball = true, name = "Kette" })
		end
	end
	if style >= 120 then
		attach(folder, head, Vector3.new(hs.X * 0.85, 0.2, 0.08), CFrame.new(0, hs.Y * 0.42, -hs.Z * 0.35) * CFrame.Angles(math.rad(-30), 0, 0), BLACK, { name = "Sonnenbrille" })
	end
	if style >= 200 then
		attach(folder, torso, Vector3.new(torso.Size.X * 1.1, torso.Size.Y * 1.7, 0.12), CFrame.new(0, -torso.Size.Y * 0.35, torso.Size.Z / 2 + 0.1) * CFrame.Angles(math.rad(8), 0, 0),
			Color3.fromRGB(120, 30, 160), { material = Enum.Material.Fabric, name = "Umhang" })
	end

	-- 7) ZÄHNE: Mundgeruch → blitzendes Lächeln
	local mouth = attach(folder, head, Vector3.new(0.2, 0.2, 0.2), CFrame.new(0, -hs.Y * 0.25, front - 0.1), Color3.new(1, 1, 1), { transparency = 1 })
	if teeth < 10 then
		emitter(mouth, Color3.fromRGB(140, 200, 60), 4, { direction = Enum.NormalId.Front, speed = NumberRange.new(1, 2),
			size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.25), NumberSequenceKeypoint.new(1, 0.7) }), light = 0,
			transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.3), NumberSequenceKeypoint.new(1, 1) }) })
	elseif teeth >= 80 then
		emitter(mouth, Color3.fromRGB(255, 255, 255), 1.5, { speed = NumberRange.new(0, 0.2), light = 1,
			size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0), NumberSequenceKeypoint.new(0.5, 0.35), NumberSequenceKeypoint.new(1, 0) }),
			lifetime = NumberRange.new(0.4, 0.6) })
	end

	-- 8) SELBSTBEWUSSTSEIN: Schweißtropfen → Sterne
	if conf < 15 then
		local sweat = attach(folder, head, Vector3.new(0.2, 0.2, 0.2), CFrame.new(hs.X * 0.45, hs.Y * 0.3, 0), Color3.new(1, 1, 1), { transparency = 1 })
		emitter(sweat, Color3.fromRGB(120, 200, 255), 3, { direction = Enum.NormalId.Bottom, acceleration = Vector3.new(0, -8, 0), speed = NumberRange.new(0.5, 1),
			size = NumberSequence.new(0.15), light = 0.2 })
	elseif conf >= 100 then
		local stars = attach(folder, head, Vector3.new(0.2, 0.2, 0.2), CFrame.new(0, hs.Y * 0.8, 0), Color3.new(1, 1, 1), { transparency = 1 })
		emitter(stars, Color3.fromRGB(255, 220, 80), math.min(6, conf / 40), { speed = NumberRange.new(1, 2), light = 1,
			size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.3), NumberSequenceKeypoint.new(1, 0) }) })
	end
end

return LookService
