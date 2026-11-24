--[[
	STYLELOOK – zeigt die Ausrüstung am Avatar:
	Aura (Glitzer, Feuer, Rauch, Regenbogen), Spur beim Laufen, Hut, Fahrzeug unter den Füßen.
	Wird bei jeder Änderung neu gebaut (GameService.refreshCharacter).
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Logic = require(Shared:WaitForChild("Logic"))

local StyleLook = {}

local GOLD = Color3.fromRGB(255, 205, 60)
local BLACK = Color3.fromRGB(25, 25, 30)

local function weldPart(folder, base, size, offset, color, opts)
	opts = opts or {}
	local p = Instance.new(opts.class or "Part")
	p.Name = opts.name or "Style"
	p.Size = size
	p.Color = color
	p.Material = opts.material or Enum.Material.SmoothPlastic
	p.Transparency = opts.transparency or 0
	p.Reflectance = opts.reflectance or 0
	p.CanCollide = false
	p.CanQuery = false
	p.CanTouch = false
	p.Massless = true
	p.CastShadow = false
	if opts.shape == "ball" then
		local m = Instance.new("SpecialMesh")
		m.MeshType = Enum.MeshType.Sphere
		m.Parent = p
	elseif opts.shape == "cyl" then
		p.Shape = Enum.PartType.Cylinder
	end
	p.CFrame = base.CFrame * offset
	local w = Instance.new("WeldConstraint")
	w.Part0 = base
	w.Part1 = p
	w.Parent = p
	p.Parent = folder
	return p
end

----------------------------------------------------------------------------
-- Hüte
----------------------------------------------------------------------------
local HATS = {}
local function top(head) return head.Size.Y / 2 end

HATS.cap = function(f, head)
	weldPart(f, head, Vector3.new(head.Size.X * 1.05, head.Size.Y * 0.45, head.Size.Z * 1.05), CFrame.new(0, top(head) * 0.75, 0), Color3.fromRGB(230, 50, 60), { shape = "ball" })
	weldPart(f, head, Vector3.new(head.Size.X * 0.9, 0.08, head.Size.Z * 0.6), CFrame.new(0, top(head) * 0.65, -head.Size.Z * 0.6), Color3.fromRGB(230, 50, 60))
end
HATS.headphones = function(f, head)
	for i = 0, 8 do
		local a = math.rad(-90 + i * 22.5)
		weldPart(f, head, Vector3.new(0.18, 0.18, 0.18), CFrame.new(math.sin(a) * head.Size.X * 0.62, math.cos(a) * top(head) * 1.15, 0), BLACK, { shape = "ball" })
	end
	for _, s in ipairs({ -1, 1 }) do
		weldPart(f, head, Vector3.new(0.25, 0.6, 0.6), CFrame.new(s * head.Size.X * 0.6, 0, 0), Color3.fromRGB(255, 79, 216), { shape = "cyl", material = Enum.Material.Neon })
	end
end
HATS.cowboy = function(f, head)
	weldPart(f, head, Vector3.new(0.12, head.Size.X * 2, head.Size.Z * 2), CFrame.new(0, top(head) * 0.9, 0) * CFrame.Angles(0, 0, math.rad(90)), Color3.fromRGB(140, 90, 50), { shape = "cyl" })
	weldPart(f, head, Vector3.new(head.Size.X * 0.85, head.Size.Y * 0.55, head.Size.Z * 0.85), CFrame.new(0, top(head) * 1.25, 0), Color3.fromRGB(140, 90, 50))
	weldPart(f, head, Vector3.new(head.Size.X * 0.87, 0.12, head.Size.Z * 0.87), CFrame.new(0, top(head) * 1.0, 0), BLACK)
end
HATS.halo = function(f, head)
	for i = 0, 11 do
		local a = i / 12 * math.pi * 2
		weldPart(f, head, Vector3.new(0.16, 0.16, 0.16), CFrame.new(math.cos(a) * head.Size.X * 0.45, top(head) + 0.7, math.sin(a) * head.Size.Z * 0.45), GOLD,
			{ shape = "ball", material = Enum.Material.Neon })
	end
end
local function crown(f, head, color, material, gem)
	weldPart(f, head, Vector3.new(0.35, head.Size.X * 0.95, head.Size.Z * 0.95), CFrame.new(0, top(head) + 0.1, 0) * CFrame.Angles(0, 0, math.rad(90)), color,
		{ shape = "cyl", material = material, reflectance = 0.3 })
	for i = 0, 5 do
		local a = i / 6 * math.pi * 2
		weldPart(f, head, Vector3.new(0.18, 0.45, 0.18), CFrame.new(math.cos(a) * head.Size.X * 0.42, top(head) + 0.45, math.sin(a) * head.Size.Z * 0.42), color,
			{ material = material, reflectance = 0.3 })
		weldPart(f, head, Vector3.new(0.14, 0.14, 0.14), CFrame.new(math.cos(a) * head.Size.X * 0.42, top(head) + 0.72, math.sin(a) * head.Size.Z * 0.42), gem,
			{ shape = "ball", material = Enum.Material.Neon })
	end
end
HATS.crown = function(f, head) crown(f, head, GOLD, Enum.Material.Foil, Color3.fromRGB(255, 60, 90)) end
HATS.diamond = function(f, head) crown(f, head, Color3.fromRGB(170, 240, 255), Enum.Material.Glass, Color3.fromRGB(255, 255, 255)) end
HATS.viking = function(f, head)
	weldPart(f, head, Vector3.new(head.Size.X * 1.08, head.Size.Y * 0.7, head.Size.Z * 1.08), CFrame.new(0, top(head) * 0.55, 0), Color3.fromRGB(150, 150, 160),
		{ shape = "ball", material = Enum.Material.Metal })
	for _, s in ipairs({ -1, 1 }) do
		weldPart(f, head, Vector3.new(0.22, 0.8, 0.22), CFrame.new(s * head.Size.X * 0.6, top(head) * 0.9, 0) * CFrame.Angles(0, 0, math.rad(-s * 35)), Color3.fromRGB(245, 240, 225),
			{ shape = "ball" })
	end
end

----------------------------------------------------------------------------
-- Fahrzeuge (unter den Füßen festgeschweißt)
----------------------------------------------------------------------------
local VEHICLES = {}
local function wheels(f, hrp, y, xs, zs, size)
	for _, x in ipairs(xs) do
		for _, z in ipairs(zs) do
			weldPart(f, hrp, Vector3.new(size * 0.6, size, size), CFrame.new(x, y, z), BLACK, { shape = "cyl" })
		end
	end
end
VEHICLES.board = function(f, hrp, def, foot)
	weldPart(f, hrp, Vector3.new(1.4, 0.15, 4), CFrame.new(0, foot + 0.35, 0), Color3.fromRGB(230, 70, 90), { shape = "ball" })
	wheels(f, hrp, foot + 0.12, { -0.5, 0.5 }, { -1.3, 1.3 }, 0.35)
end
VEHICLES.scooter = function(f, hrp, def, foot)
	weldPart(f, hrp, Vector3.new(1.2, 0.2, 3.6), CFrame.new(0, foot + 0.35, 0), Color3.fromRGB(60, 160, 230))
	weldPart(f, hrp, Vector3.new(0.2, 3.2, 0.2), CFrame.new(0, foot + 1.9, -1.6), Color3.fromRGB(80, 80, 90), { material = Enum.Material.Metal })
	weldPart(f, hrp, Vector3.new(1.8, 0.2, 0.2), CFrame.new(0, foot + 3.5, -1.6), BLACK)
	wheels(f, hrp, foot + 0.2, { 0 }, { -1.6, 1.6 }, 0.5)
end
VEHICLES.car = function(f, hrp, def, foot)
	local color = def.gold and GOLD or Color3.fromRGB(230, 40, 50)
	local mat = def.gold and Enum.Material.Foil or Enum.Material.SmoothPlastic
	weldPart(f, hrp, Vector3.new(4.4, 1.4, 8), CFrame.new(0, foot + 1.3, 0), color, { material = mat, reflectance = 0.25 })
	weldPart(f, hrp, Vector3.new(4.2, 0.9, 2.5), CFrame.new(0, foot + 2.3, -1.8), Color3.fromRGB(150, 210, 240), { material = Enum.Material.Glass, transparency = 0.4 })
	weldPart(f, hrp, Vector3.new(4.5, 0.4, 1.4), CFrame.new(0, foot + 2.1, 3.6), BLACK)   -- Spoiler
	wheels(f, hrp, foot + 0.7, { -2.2, 2.2 }, { -2.6, 2.6 }, 1.4)
	for _, s in ipairs({ -1.4, 1.4 }) do
		weldPart(f, hrp, Vector3.new(0.8, 0.4, 0.15), CFrame.new(s, foot + 1.4, -4.05), Color3.fromRGB(255, 250, 200), { material = Enum.Material.Neon })
	end
end
VEHICLES.hover = function(f, hrp, def, foot)
	weldPart(f, hrp, Vector3.new(0.25, 4.2, 4.2), CFrame.new(0, foot + 0.3, 0) * CFrame.Angles(0, 0, math.rad(90)), Color3.fromRGB(62, 242, 255), { shape = "cyl", material = Enum.Material.Neon, transparency = 0.2 })
	local glow = weldPart(f, hrp, Vector3.new(0.2, 0.2, 0.2), CFrame.new(0, foot, 0), Color3.new(1, 1, 1), { transparency = 1 })
	local e = Instance.new("ParticleEmitter")
	e.Color = ColorSequence.new(Color3.fromRGB(62, 242, 255))
	e.Rate = 25
	e.Speed = NumberRange.new(2, 4)
	e.Lifetime = NumberRange.new(0.3, 0.6)
	e.EmissionDirection = Enum.NormalId.Bottom
	e.LightEmission = 1
	e.Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.4), NumberSequenceKeypoint.new(1, 0) })
	e.Parent = glow
end

----------------------------------------------------------------------------
-- Aura & Spur
----------------------------------------------------------------------------
local function auraEffect(f, hrp, def)
	local holder = weldPart(f, hrp, Vector3.new(2, 4, 1), CFrame.new(0, 0, 0), Color3.new(1, 1, 1), { transparency = 1, name = "Aura" })
	if def.style == "fire" then
		local fire = Instance.new("Fire")
		fire.Color = def.color
		fire.SecondaryColor = Color3.fromRGB(255, 220, 80)
		fire.Size = 6
		fire.Heat = 6
		fire.Parent = holder
	elseif def.style == "smoke" then
		local smoke = Instance.new("Smoke")
		smoke.Color = def.color
		smoke.Size = 4
		smoke.RiseVelocity = 2
		smoke.Opacity = 0.25
		smoke.Parent = holder
	end
	local e = Instance.new("ParticleEmitter")
	if def.style == "rainbow" then
		e.Color = ColorSequence.new({
			ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 60, 60)), ColorSequenceKeypoint.new(0.25, Color3.fromRGB(255, 220, 60)),
			ColorSequenceKeypoint.new(0.5, Color3.fromRGB(60, 255, 120)), ColorSequenceKeypoint.new(0.75, Color3.fromRGB(60, 160, 255)),
			ColorSequenceKeypoint.new(1, Color3.fromRGB(220, 80, 255)),
		})
	else
		e.Color = ColorSequence.new(def.color)
	end
	e.Rate = def.strong and 30 or 15
	e.Lifetime = NumberRange.new(0.8, 1.5)
	e.Speed = NumberRange.new(1, 3)
	e.SpreadAngle = Vector2.new(180, 180)
	e.LightEmission = 1
	e.Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, def.strong and 0.6 or 0.4), NumberSequenceKeypoint.new(1, 0) })
	e.Parent = holder
end

local function trailEffect(f, hrp, def)
	local a0 = Instance.new("Attachment")
	a0.Name = "TrailTop"
	a0.Position = Vector3.new(0, 0.8, 0.4)
	a0.Parent = hrp
	local a1 = Instance.new("Attachment")
	a1.Name = "TrailBottom"
	a1.Position = Vector3.new(0, -1.6, 0.4)
	a1.Parent = hrp
	local tr = Instance.new("Trail")
	tr.Attachment0 = a0
	tr.Attachment1 = a1
	tr.Lifetime = 0.7
	tr.LightEmission = 0.8
	tr.Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.2), NumberSequenceKeypoint.new(1, 1) })
	if def.rainbow then
		tr.Color = ColorSequence.new({
			ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 60, 60)), ColorSequenceKeypoint.new(0.33, Color3.fromRGB(255, 220, 60)),
			ColorSequenceKeypoint.new(0.66, Color3.fromRGB(60, 200, 255)), ColorSequenceKeypoint.new(1, Color3.fromRGB(220, 80, 255)),
		})
	else
		tr.Color = ColorSequence.new(def.c1, def.c2)
	end
	tr.Parent = f
	-- Attachments mit aufräumen, wenn der Ordner gelöscht wird
	f.Destroying:Connect(function()
		a0:Destroy()
		a1:Destroy()
	end)
end

----------------------------------------------------------------------------
-- Anwenden
----------------------------------------------------------------------------
function StyleLook.apply(player, char, data, riding)
	local head = char:FindFirstChild("Head")
	local hrp = char:FindFirstChild("HumanoidRootPart")
	local hum = char:FindFirstChildOfClass("Humanoid")
	if not head or not hrp or not hum then return end
	local old = char:FindFirstChild("StyleLook")
	if old then old:Destroy() end
	local f = Instance.new("Folder")
	f.Name = "StyleLook"
	f.Parent = char

	local cos = data.cosmetics or {}
	local hat = Logic.hatById[cos.hat or ""]
	if hat and HATS[hat.id] then HATS[hat.id](f, head) end
	local aura = Logic.auraById[cos.aura or ""]
	if aura then auraEffect(f, hrp, aura) end
	local trail = Logic.trailById[cos.trail or ""]
	if trail then trailEffect(f, hrp, trail) end
	if riding then
		local v = Logic.vehicleById[data.vehicle or ""]
		if v and VEHICLES[v.plan] then
			local foot = -(hrp.Size.Y / 2 + hum.HipHeight)
			VEHICLES[v.plan](f, hrp, v, foot)
		end
	end
end

return StyleLook
