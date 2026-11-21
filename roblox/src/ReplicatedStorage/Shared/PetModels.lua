--[[
	PETMODELS – baut aus der Beschreibung eines Pets (Config.Pets[..].look)
	eine echte 3D-Figur aus Teilen: Körper, Kopf, Augen, Ohren, Beine, Schwanz, Flügel …
	Wird vom Server (Pets in der Welt) UND vom Client (3D-Vorschau in Menüs) benutzt.

	Die Figur schaut nach vorne (-Z). Der unsichtbare Teil "Root" ist die Mitte.
]]

local Config = require(script.Parent:WaitForChild("Config"))

local PetModels = {}
local PET_SCALE = 1.1
local BLACK = Color3.fromRGB(25, 25, 30)
local WHITE = Color3.new(1, 1, 1)
local ORANGE = Color3.fromRGB(255, 170, 40)
local GOLD = Color3.fromRGB(255, 205, 60)

local function cf(x, y, z, rx, ry, rz)
	return CFrame.new(x, y, z) * CFrame.Angles(math.rad(rx or 0), math.rad(ry or 0), math.rad(rz or 0))
end

----------------------------------------------------------------------------
-- Bauteil erstellen
-- shape: "ball" (Ellipsoid), "block", "cyl" (Zylinder liegend entlang X), "wedge"
----------------------------------------------------------------------------
local function piece(ctx, size, cframe, color, shape, opts)
	opts = opts or {}
	local p = Instance.new(shape == "wedge" and "WedgePart" or "Part")
	p.Anchored = true
	p.CanCollide = false
	p.CanQuery = false
	p.CanTouch = false
	p.CastShadow = false
	p.TopSurface = Enum.SurfaceType.Smooth
	p.BottomSurface = Enum.SurfaceType.Smooth
	p.Size = size
	p.CFrame = cframe
	p.Color = color
	p.Material = Enum.Material.SmoothPlastic
	if shape == "ball" then
		local m = Instance.new("SpecialMesh")
		m.MeshType = Enum.MeshType.Sphere
		m.Parent = p
	elseif shape == "cyl" then
		p.Shape = Enum.PartType.Cylinder
	end
	-- Hauptfarbe: bekommt die Effekte (Glas, Neon, Gold, Fusions-Stufen)
	if opts.main then
		p:SetAttribute("Main", true)
		if ctx.look.glass then
			p.Material = Enum.Material.Glass
			p.Transparency = 0.25
			p.Reflectance = 0.2
		elseif ctx.look.gold then
			p.Material = Enum.Material.Foil
			p.Reflectance = 0.25
		end
	end
	if opts.accent and ctx.look.neon then
		p.Material = Enum.Material.Neon
	end
	if opts.neon then p.Material = Enum.Material.Neon end
	if opts.transparency then p.Transparency = opts.transparency end
	p.Parent = ctx.model
	return p
end

local function ball(ctx, sx, sy, sz, x, y, z, color, opts, rx, ry, rz)
	return piece(ctx, Vector3.new(sx, sy, sz), cf(x, y, z, rx, ry, rz), color, "ball", opts)
end

local function block(ctx, sx, sy, sz, x, y, z, color, opts, rx, ry, rz)
	return piece(ctx, Vector3.new(sx, sy, sz), cf(x, y, z, rx, ry, rz), color, "block", opts)
end

-- zwei Augen mit Glanzpunkt
local function eyes(ctx, x, y, z, size, sideways)
	size = size or 0.2
	for _, s in ipairs({ -1, 1 }) do
		if sideways then
			ball(ctx, size * 0.6, size, size, s * x, y, z, BLACK)
			ball(ctx, size * 0.3, size * 0.35, size * 0.35, s * (x + 0.02), y + size * 0.2, z - size * 0.15, WHITE)
		else
			ball(ctx, size, size, size * 0.6, s * x, y, z, BLACK)
			ball(ctx, size * 0.35, size * 0.35, size * 0.3, s * x + size * 0.15, y + size * 0.2, z - size * 0.25, WHITE)
		end
	end
end

-- Heiligenschein aus leuchtenden Kugeln
local function halo(ctx, y)
	for i = 0, 9 do
		local a = i / 10 * math.pi * 2
		ball(ctx, 0.12, 0.12, 0.12, math.cos(a) * 0.45, y, math.sin(a) * 0.45 - 0.3, GOLD, { neon = true })
	end
end

local function shades(ctx, y, z)
	block(ctx, 0.78, 0.18, 0.06, 0, y, z, BLACK)
	block(ctx, 0.3, 0.16, 0.04, -0.2, y - 0.03, z - 0.02, Color3.fromRGB(40, 40, 60))
	block(ctx, 0.3, 0.16, 0.04, 0.2, y - 0.03, z - 0.02, Color3.fromRGB(40, 40, 60))
end

----------------------------------------------------------------------------
-- Baupläne
----------------------------------------------------------------------------
local PLANS = {}

-- Vierbeiner (Katze, Hund, Hamster, Löwe, Bär, Fuchs, Elefant …)
PLANS.quad = function(ctx, L)
	local c1, c2 = L.c1, L.c2
	ball(ctx, 1.4, 1.1, 1.8, 0, 0, 0.1, c1, { main = true })
	ball(ctx, 0.9, 0.8, 0.5, 0, -0.05, -0.7, c2, { accent = true })
	if L.hump then ball(ctx, 0.9, 0.7, 0.9, 0, 0.6, 0.25, c1, { main = true }) end
	-- Kopf
	local hy, hz = 0.6, -0.95
	if L.mane then ball(ctx, 1.55, 1.5, 0.9, 0, hy, hz + 0.3, c2, { accent = true }) end
	ball(ctx, 1.1, 1.0, 1.0, 0, hy, hz, c1, { main = true })
	ball(ctx, 0.55, 0.4, 0.4, 0, hy - 0.17, hz - 0.45, c2, { accent = true })
	ball(ctx, 0.16, 0.12, 0.1, 0, hy - 0.08, hz - 0.65, BLACK)
	eyes(ctx, 0.24, hy + 0.1, hz - 0.42, 0.2)
	if L.patches then
		for _, s in ipairs({ -1, 1 }) do ball(ctx, 0.3, 0.36, 0.1, s * 0.24, hy + 0.08, hz - 0.4, c2, nil, 0, 0, s * 20) end
		eyes(ctx, 0.24, hy + 0.1, hz - 0.44, 0.16)
	end
	if L.mask then block(ctx, 0.85, 0.22, 0.1, 0, hy + 0.1, hz - 0.43, c2) eyes(ctx, 0.24, hy + 0.1, hz - 0.46, 0.17) end
	if L.cucumber then
		for _, s in ipairs({ -1, 1 }) do ball(ctx, 0.3, 0.3, 0.06, s * 0.24, hy + 0.1, hz - 0.49, Color3.fromRGB(120, 200, 90)) end
	end
	if L.shades then shades(ctx, hy + 0.12, hz - 0.5) end
	-- Ohren
	local ears = L.ears or "round"
	for _, s in ipairs({ -1, 1 }) do
		if ears == "round" then
			ball(ctx, 0.36, 0.36, 0.15, s * 0.36, hy + 0.45, hz + 0.05, c1, { main = true })
		elseif ears == "pointy" then
			ball(ctx, 0.26, 0.55, 0.18, s * 0.3, hy + 0.55, hz + 0.05, c1, { main = true }, 0, 0, -s * 18)
		elseif ears == "long" then
			ball(ctx, 0.24, 0.95, 0.16, s * 0.2, hy + 0.85, hz + 0.1, c1, { main = true }, 0, 0, -s * 8)
		elseif ears == "floppy" then
			ball(ctx, 0.26, 0.6, 0.15, s * 0.56, hy - 0.02, hz + 0.05, c2, { accent = true }, 0, 0, s * 20)
		elseif ears == "big" then
			ball(ctx, 0.65, 0.65, 0.12, s * 0.55, hy + 0.4, hz + 0.05, c1, { main = true })
			ball(ctx, 0.45, 0.45, 0.08, s * 0.55, hy + 0.4, hz - 0.01, c2, { accent = true })
		end
	end
	if L.horn then ball(ctx, 0.14, 0.7, 0.14, 0, hy + 0.65, hz - 0.25, GOLD, { neon = true }, -15, 0, 0) end
	if L.horns then
		for _, s in ipairs({ -1, 1 }) do ball(ctx, 0.12, 0.6, 0.12, s * 0.25, hy + 0.6, hz + 0.05, Color3.fromRGB(230, 220, 200), nil, -20, 0, -s * 25) end
	end
	if L.trunk then
		ball(ctx, 0.28, 0.9, 0.28, 0, hy - 0.5, hz - 0.55, c1, { main = true }, 25, 0, 0)
		for _, s in ipairs({ -1, 1 }) do ball(ctx, 0.12, 0.5, 0.12, s * 0.25, hy - 0.45, hz - 0.45, WHITE, nil, 40, 0, 0) end
	end
	-- Muster
	if L.stripes then
		for _, z in ipairs({ -0.35, 0.15, 0.65 }) do ball(ctx, 1.44, 0.18, 0.2, 0, 0.15, z, c2, nil, 0, 0, 0) end
	end
	if L.spots then
		local spots = { { 0.4, 0.35, -0.2 }, { -0.35, 0.4, 0.3 }, { 0.2, 0.5, 0.6 }, { -0.5, 0.1, -0.3 }, { 0.55, 0.05, 0.45 } }
		for _, p in ipairs(spots) do ball(ctx, 0.24, 0.24, 0.24, p[1], p[2], p[3], c2) end
	end
	-- Beine
	for _, p in ipairs({ { -0.45, -0.6 }, { 0.45, -0.6 }, { -0.45, 0.75 }, { 0.45, 0.75 } }) do
		ball(ctx, 0.36, 0.65, 0.36, p[1], -0.55, p[2], c1, { main = true })
	end
	-- Schwanz
	local tail = L.tail or "short"
	if tail == "short" then
		ball(ctx, 0.35, 0.35, 0.35, 0, 0.15, 1.0, c2, { accent = true })
	elseif tail == "long" then
		ball(ctx, 0.18, 0.18, 1.1, 0, 0.35, 1.35, c1, { main = true }, -30, 0, 0)
	elseif tail == "fluffy" then
		ball(ctx, 0.6, 0.6, 1.15, 0, 0.55, 1.3, c1, { main = true }, -45, 0, 0)
		ball(ctx, 0.4, 0.4, 0.5, 0, 0.95, 1.6, c2, { accent = true })
	elseif tail == "curl" then
		ball(ctx, 0.42, 0.42, 0.42, 0, 0.55, 1.0, c2, { accent = true })
	end
	if L.halo then halo(ctx, hy + 0.95) end
end

-- Vögel
PLANS.bird = function(ctx, L)
	local c1, c2 = L.c1, L.c2
	local style = L.style or "default"
	local hy, hz = 0.85, -0.15
	if style == "longleg" or style == "swan" then
		ball(ctx, 0.95, 0.75, 1.2, 0, 0.3, 0.1, c1, { main = true })
		ball(ctx, 0.18, 0.9, 0.18, 0, 0.95, -0.35, c1, { main = true }, style == "swan" and -25 or -10, 0, 0)
		hy, hz = 1.45, -0.55
		ball(ctx, 0.42, 0.42, 0.48, 0, hy, hz, c1, { main = true })
		ball(ctx, 0.14, 0.12, 0.42, 0, hy - 0.06, hz - 0.36, c2, { accent = true }, 15, 0, 0)
		eyes(ctx, 0.16, hy + 0.06, hz - 0.12, 0.1, true)
		if style == "longleg" then
			for _, s in ipairs({ -1, 1 }) do ball(ctx, 0.08, 1.0, 0.08, s * 0.15, -0.45, 0.05, c1) end
		else
			ball(ctx, 0.5, 0.18, 0.5, 0, 1.75, -0.55, GOLD, { neon = true })   -- kleine Krone
		end
		for _, s in ipairs({ -1, 1 }) do ball(ctx, 0.2, 0.6, 0.9, s * 0.5, 0.35, 0.2, c2, { accent = true }, 0, 0, s * 15) end
	else
		ball(ctx, 1.0, 1.2, 1.0, 0, 0, 0, c1, { main = true })
		ball(ctx, 0.78, 0.75, 0.75, 0, hy, hz, style == "eagle" and c2 or c1, { main = style ~= "eagle" })
		local beakColor = (style == "eagle") and Color3.fromRGB(255, 200, 40) or ORANGE
		ball(ctx, 0.2, 0.16, 0.42, 0, hy - 0.08, hz - 0.42, beakColor, nil, 15, 0, 0)
		if style == "owl" then
			for _, s in ipairs({ -1, 1 }) do
				ball(ctx, 0.34, 0.34, 0.1, s * 0.18, hy + 0.08, hz - 0.33, c2, { accent = true })
				ball(ctx, 0.16, 0.35, 0.12, s * 0.25, hy + 0.42, hz, c1, { main = true }, 0, 0, -s * 15)
			end
			eyes(ctx, 0.18, hy + 0.08, hz - 0.4, 0.18)
		else
			eyes(ctx, 0.2, hy + 0.1, hz - 0.33, 0.15)
		end
		if style == "penguin" then
			ball(ctx, 0.75, 1.0, 0.5, 0, -0.05, -0.3, c2, { accent = true })
		else
			ball(ctx, 0.7, 0.8, 0.45, 0, -0.1, -0.32, c2, { accent = true })
		end
		-- Flügel
		local spread = (style == "eagle" or style == "phoenix") and 55 or 15
		local wingLen = (style == "eagle" or style == "phoenix") and 1.2 or 0.75
		for _, s in ipairs({ -1, 1 }) do
			ball(ctx, 0.22, wingLen, 0.7, s * (0.5 + (spread > 20 and 0.35 or 0)), 0.1 + (spread > 20 and 0.3 or 0), 0.05, style == "penguin" and c1 or c2,
				{ accent = style ~= "penguin", main = style == "penguin" }, 0, 0, s * spread)
		end
		-- Schwanz
		if style == "peacock" then
			for i = -3, 3 do
				local col = (i % 2 == 0) and c1 or c2
				local f = ball(ctx, 0.22, 1.3, 0.08, i * 0.24, 0.6, 0.6, col, { accent = true }, -15, 0, -i * 14)
				ball(ctx, 0.14, 0.14, 0.04, i * 0.38, 1.12, 0.55, GOLD, { neon = true })
				f.Name = "Feder"
			end
		elseif style == "crest" or style == "phoenix" then
			for i = -1, 1 do ball(ctx, 0.12, 0.45, 0.12, i * 0.1, hy + 0.45, hz + 0.1, c2, { accent = true }, -20, 0, -i * 25) end
			for i = -1, 1 do ball(ctx, 0.18, 0.12, 0.9, i * 0.15, -0.1, 0.75, i == 0 and c1 or c2, { accent = true }, 15, i * 12, 0) end
		else
			ball(ctx, 0.5, 0.15, 0.5, 0, -0.25, 0.6, c2, { accent = true }, 15, 0, 0)
		end
		for _, s in ipairs({ -1, 1 }) do ball(ctx, 0.18, 0.12, 0.3, s * 0.22, -0.65, -0.12, ORANGE) end
		if style == "phoenix" then
			local f = Instance.new("Fire")
			f.Size = 3
			f.Heat = 3
			f.Color = c1
			f.SecondaryColor = c2
			f.Parent = ctx.root
		end
	end
	if L.shades then shades(ctx, hy + 0.1, hz - 0.36) end
	if L.halo then halo(ctx, hy + 0.65) end
end

-- Meerestiere (Fisch, Delfin, Hai, Wal)
PLANS.sea = function(ctx, L)
	local c1, c2 = L.c1, L.c2
	local style = L.style or "fish"
	if style == "fish" then
		ball(ctx, 0.7, 0.95, 1.4, 0, 0, 0, c1, { main = true })
		ball(ctx, 0.72, 0.3, 0.5, 0, 0.1, -0.1, c2, { accent = true })
		ball(ctx, 0.1, 0.95, 0.6, 0, 0, 0.85, c1, { main = true })
		ball(ctx, 0.1, 0.45, 0.55, 0, 0.5, 0.1, c2, { accent = true }, -20, 0, 0)
		eyes(ctx, 0.3, 0.15, -0.45, 0.18, true)
	else
		local big = style == "whale"
		local sx, sy, sz = big and 1.5 or 0.85, big and 1.3 or 0.85, big and 2.4 or 2.0
		ball(ctx, sx, sy, sz, 0, 0, 0, c1, { main = true })
		ball(ctx, sx * 0.75, sy * 0.55, sz * 0.8, 0, -sy * 0.22, -0.05, c2, { accent = true })
		if style == "dolphin" then ball(ctx, 0.3, 0.25, 0.55, 0, -0.05, -1.15, c1, { main = true }) end
		local dorsal = style == "shark" and 0.95 or (big and 0.4 or 0.6)
		ball(ctx, 0.12, dorsal, 0.55, 0, sy * 0.5 + dorsal * 0.3, 0.1, c1, { main = true }, 20, 0, 0)
		if style == "shark" then
			ball(ctx, 0.12, 1.0, 0.55, 0, 0.2, sz * 0.55, c1, { main = true }, 25, 0, 0)
			block(ctx, 0.45, 0.06, 0.12, 0, -0.25, -0.88, WHITE)
		else
			ball(ctx, sx * 1.15, 0.12, 0.55, 0, 0, sz * 0.55, c1, { main = true })
		end
		for _, s in ipairs({ -1, 1 }) do ball(ctx, 0.55, 0.1, 0.3, s * sx * 0.55, -0.2, -0.2, c1, { main = true }, 0, 0, s * 25) end
		eyes(ctx, sx * 0.42, 0.1, -sz * 0.32, big and 0.18 or 0.16, true)
	end
	if L.halo then halo(ctx, 0.9) end
end

PLANS.crab = function(ctx, L)
	local c1, c2 = L.c1, L.c2
	ball(ctx, 1.4, 0.65, 1.0, 0, 0, 0, c1, { main = true })
	ball(ctx, 1.0, 0.3, 0.7, 0, -0.2, 0, c2, { accent = true })
	for _, s in ipairs({ -1, 1 }) do
		ball(ctx, 0.08, 0.4, 0.08, s * 0.25, 0.4, -0.3, c1)
		ball(ctx, 0.2, 0.2, 0.2, s * 0.25, 0.62, -0.3, WHITE)
		ball(ctx, 0.1, 0.1, 0.06, s * 0.25, 0.63, -0.4, BLACK)
		ball(ctx, 0.55, 0.42, 0.6, s * 0.95, 0.15, -0.55, c1, { main = true }, 0, s * 20, 0)
		ball(ctx, 0.2, 0.2, 0.35, s * 1.15, 0.25, -0.85, c2, { accent = true })
		for k = -1, 1 do ball(ctx, 0.65, 0.12, 0.12, s * 0.85, -0.25, k * 0.3 + 0.1, c1, nil, 0, 0, -s * 30) end
	end
end

PLANS.scorpion = function(ctx, L)
	local c1, c2 = L.c1, L.c2
	ball(ctx, 1.0, 0.5, 1.4, 0, 0, 0, c1, { main = true })
	eyes(ctx, 0.15, 0.2, -0.65, 0.12)
	for _, s in ipairs({ -1, 1 }) do
		ball(ctx, 0.4, 0.3, 0.55, s * 0.75, 0.05, -0.85, c1, { main = true }, 0, s * 25, 0)
		for k = -1, 1 do ball(ctx, 0.6, 0.1, 0.1, s * 0.6, -0.2, k * 0.35, c2, nil, 0, 0, -s * 30) end
	end
	local pts = { { 0, 0.25, 0.8 }, { 0, 0.6, 1.0 }, { 0, 1.0, 0.95 }, { 0, 1.3, 0.7 } }
	for i, p in ipairs(pts) do ball(ctx, 0.4 - i * 0.05, 0.4 - i * 0.05, 0.4 - i * 0.05, p[1], p[2], p[3], c1, { main = true }) end
	ball(ctx, 0.14, 0.35, 0.14, 0, 1.35, 0.42, c2, { accent = true }, 60, 0, 0)
end

PLANS.octopus = function(ctx, L)
	local c1, c2 = L.c1, L.c2
	ball(ctx, 1.25, 1.3, 1.2, 0, 0.45, 0, c1, { main = true })
	eyes(ctx, 0.28, 0.4, -0.55, 0.24)
	for i = 0, 7 do
		local a = i / 8 * math.pi * 2
		ball(ctx, 0.25, 0.85, 0.25, math.cos(a) * 0.5, -0.35, math.sin(a) * 0.5, i % 2 == 0 and c1 or c2, { main = i % 2 == 0, accent = i % 2 == 1 },
			math.sin(a) * 25, 0, -math.cos(a) * 25)
	end
end

PLANS.turtle = function(ctx, L)
	local c1, c2 = L.c1, L.c2
	ball(ctx, 1.5, 0.95, 1.7, 0, 0.15, 0, c2, { accent = true })
	for _, p in ipairs({ { 0, 0.6, 0 }, { 0.4, 0.45, 0.4 }, { -0.4, 0.45, 0.4 }, { 0.4, 0.45, -0.4 }, { -0.4, 0.45, -0.4 } }) do
		ball(ctx, 0.42, 0.12, 0.42, p[1], p[2], p[3], c1:Lerp(BLACK, 0.25))
	end
	ball(ctx, 1.3, 0.3, 1.5, 0, -0.25, 0, c1, { main = true })
	ball(ctx, 0.6, 0.55, 0.7, 0, 0.05, -1.0, c1, { main = true })
	eyes(ctx, 0.18, 0.15, -1.3, 0.14)
	for _, p in ipairs({ { -0.6, -0.65 }, { 0.6, -0.65 }, { -0.6, 0.65 }, { 0.6, 0.65 } }) do
		ball(ctx, 0.4, 0.35, 0.45, p[1], -0.35, p[2], c1, { main = true })
	end
	if L.halo then halo(ctx, 1.0) end
end

PLANS.snake = function(ctx, L)
	local c1, c2 = L.c1, L.c2
	local pts = { { 0, -0.4, 0.9 }, { 0.35, -0.35, 0.55 }, { 0.1, -0.3, 0.15 }, { -0.3, -0.2, -0.15 }, { -0.15, 0.05, -0.45 } }
	for i, p in ipairs(pts) do
		local s = 0.45 + i * 0.06
		ball(ctx, s, s, s, p[1], p[2], p[3], i % 2 == 0 and c2 or c1, { main = i % 2 == 1, accent = i % 2 == 0 })
	end
	ball(ctx, 0.7, 0.55, 0.85, 0, 0.35, -0.75, c1, { main = true })
	eyes(ctx, 0.2, 0.5, -1.05, 0.15)
	block(ctx, 0.06, 0.03, 0.35, 0, 0.25, -1.25, Color3.fromRGB(230, 40, 60))
end

PLANS.frog = function(ctx, L)
	local c1, c2 = L.c1, L.c2
	ball(ctx, 1.35, 0.85, 1.25, 0, 0, 0, c1, { main = true })
	ball(ctx, 1.0, 0.5, 0.9, 0, -0.2, -0.15, c2, { accent = true })
	for _, s in ipairs({ -1, 1 }) do
		ball(ctx, 0.42, 0.42, 0.42, s * 0.35, 0.45, -0.4, c1, { main = true })
		ball(ctx, 0.3, 0.3, 0.2, s * 0.35, 0.5, -0.56, WHITE)
		ball(ctx, 0.15, 0.15, 0.1, s * 0.35, 0.5, -0.65, BLACK)
		ball(ctx, 0.45, 0.32, 0.85, s * 0.62, -0.32, 0.3, c1, { main = true })
		ball(ctx, 0.25, 0.4, 0.25, s * 0.45, -0.4, -0.45, c1, { main = true })
	end
	block(ctx, 0.7, 0.05, 0.05, 0, 0.0, -0.62, Color3.fromRGB(60, 30, 30))
end

PLANS.dragon = function(ctx, L)
	local L2 = {}
	for k, v in pairs(L) do L2[k] = v end
	L2.ears = "none"
	L2.tail = "long"
	L2.horns = true
	PLANS.quad(ctx, L2)
	for _, s in ipairs({ -1, 1 }) do
		ball(ctx, 0.12, 1.3, 1.5, s * 0.95, 0.85, 0.25, L.c2, { accent = true }, 0, 0, s * 45)
	end
	for i = 0, 3 do ball(ctx, 0.15, 0.35, 0.2, 0, 0.6, -0.25 + i * 0.35, L.c2, { accent = true }) end
end

PLANS.moai = function(ctx, L)
	local c1, c2 = L.c1, L.c2
	block(ctx, 1.15, 0.5, 0.85, 0, -0.75, 0, c1, { main = true })
	block(ctx, 1.0, 1.6, 0.9, 0, 0.3, 0, c1, { main = true })
	block(ctx, 1.06, 0.28, 1.0, 0, 0.95, -0.05, c2, { accent = true })
	block(ctx, 0.28, 0.65, 0.35, 0, 0.35, -0.55, c1, { main = true })
	for _, s in ipairs({ -1, 1 }) do block(ctx, 0.25, 0.1, 0.05, s * 0.25, 0.7, -0.46, BLACK) end
	block(ctx, 0.45, 0.06, 0.05, 0, -0.1, -0.46, BLACK)
	if L.halo then halo(ctx, 1.4) end
end

PLANS.ghost = function(ctx, L)
	ball(ctx, 1.2, 1.4, 1.2, 0, 0.1, 0, L.c1, { main = true, transparency = 0.25 })
	for i = 0, 3 do
		local a = i / 4 * math.pi * 2
		ball(ctx, 0.5, 0.5, 0.5, math.cos(a) * 0.35, -0.55, math.sin(a) * 0.35, L.c1, { main = true, transparency = 0.25 })
	end
	eyes(ctx, 0.22, 0.25, -0.55, 0.22)
	ball(ctx, 0.2, 0.25, 0.08, 0, -0.1, -0.58, BLACK)
	local light = Instance.new("PointLight")
	light.Color = L.c2
	light.Range = 8
	light.Parent = ctx.root
end

PLANS.alien = function(ctx, L)
	ball(ctx, 1.3, 1.05, 1.05, 0, 0.55, 0, L.c1, { main = true })
	for _, s in ipairs({ -1, 1 }) do
		ball(ctx, 0.38, 0.22, 0.12, s * 0.28, 0.5, -0.48, L.c2, nil, 0, 0, s * 25)
		ball(ctx, 0.04, 0.5, 0.04, s * 0.25, 1.2, 0, L.c1)
		ball(ctx, 0.15, 0.15, 0.15, s * 0.25, 1.45, 0, Color3.fromRGB(255, 120, 240), { neon = true })
	end
	ball(ctx, 0.6, 0.8, 0.5, 0, -0.35, 0, L.c1, { main = true })
	for _, s in ipairs({ -1, 1 }) do ball(ctx, 0.18, 0.6, 0.18, s * 0.42, -0.35, 0, L.c1, nil, 0, 0, s * 25) end
end

PLANS.star = function(ctx, L)
	for i = 0, 4 do
		local a = math.rad(i * 72)
		ball(ctx, 0.42, 1.0, 0.32, math.sin(a) * 0.5, math.cos(a) * 0.5, 0, i % 2 == 0 and L.c1 or L.c2, { main = i % 2 == 0, accent = i % 2 == 1 }, 0, 0, -i * 72)
	end
	ball(ctx, 0.75, 0.75, 0.42, 0, 0, 0, L.c1, { main = true })
	eyes(ctx, 0.15, 0.1, -0.22, 0.14)
	block(ctx, 0.25, 0.05, 0.05, 0, -0.12, -0.22, BLACK)
end

PLANS.planet = function(ctx, L)
	ball(ctx, 1.45, 1.45, 1.45, 0, 0.1, 0, L.c1, { main = true })
	for _, p in ipairs({ { 0.35, 0.45, -0.45 }, { -0.5, 0.0, -0.4 }, { 0.2, -0.35, -0.55 } }) do ball(ctx, 0.5, 0.4, 0.3, p[1], p[2], p[3], L.c2) end
	ball(ctx, 2.6, 0.06, 2.6, 0, 0.1, 0, Color3.fromRGB(255, 230, 160), { neon = true, transparency = 0.35 }, 0, 0, 18)
	eyes(ctx, 0.22, 0.25, -0.68, 0.16)
end

PLANS.blob = function(ctx, L)
	ball(ctx, 1.35, 1.0, 1.3, 0, -0.1, 0, L.c1, { main = true })
	ball(ctx, 0.35, 0.2, 0.2, -0.3, 0.25, -0.5, WHITE, { transparency = 0.3 })
	ball(ctx, 0.5, 0.5, 0.5, 0.35, 0.45, 0.2, L.c2, { accent = true })
	eyes(ctx, 0.22, 0.1, -0.6, 0.18)
end

----------------------------------------------------------------------------
-- Pet bauen
----------------------------------------------------------------------------
-- forWorld = true: Teile fest verschweißen (dann muss nur "Root" bewegt werden – viel schneller)
function PetModels.build(def, tier, forWorld)
	tier = tier or 1
	local look = def.look or { plan = "blob", c1 = Color3.fromRGB(200, 200, 200), c2 = WHITE }
	local model = Instance.new("Model")
	model.Name = def.name
	local root = Instance.new("Part")
	root.Name = "Root"
	root.Size = Vector3.new(0.2, 0.2, 0.2)
	root.Transparency = 1
	root.Anchored = true
	root.CanCollide = false
	root.CanQuery = false
	root.CanTouch = false
	root.CFrame = CFrame.new()
	root.Parent = model
	model.PrimaryPart = root

	local ctx = { model = model, root = root, look = look }
	local plan = PLANS[look.plan] or PLANS.blob
	local ok, err = pcall(plan, ctx, look)
	if not ok then warn("[PetModels]", def.name, err) end

	-- Fusions-Stufen: Gold, Regenbogen, Diamant
	local tierInfo = Config.PetTiers[tier]
	if tier >= 2 then
		for _, p in ipairs(model:GetDescendants()) do
			if p:IsA("BasePart") and p:GetAttribute("Main") then
				if tier == 2 then
					p.Color = tierInfo.color
					p.Material = Enum.Material.Foil
					p.Reflectance = 0.3
				elseif tier == 3 then
					p.Color = tierInfo.color      -- der Client lässt diese Teile in Regenbogenfarben leuchten
					p.Material = Enum.Material.SmoothPlastic
				elseif tier == 4 then
					p.Color = tierInfo.color
					p.Material = Enum.Material.Glass
					p.Transparency = 0.2
					p.Reflectance = 0.35
				end
			end
		end
	end

	-- Glitzer & Licht für seltene Pets
	local rarity = Config.Rarities[def.rarity]
	if rarity and (rarity.order >= 5 or tier >= 2) then
		local light = Instance.new("PointLight")
		light.Color = tierInfo.color or rarity.color
		light.Range = 6
		light.Brightness = 0.8
		light.Parent = root
		local sparkle = Instance.new("ParticleEmitter")
		sparkle.Rate = rarity.order >= 7 and 10 or 4
		sparkle.Lifetime = NumberRange.new(0.6, 1.2)
		sparkle.Speed = NumberRange.new(0.5, 1.5)
		sparkle.SpreadAngle = Vector2.new(180, 180)
		sparkle.LightEmission = 1
		sparkle.Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.25), NumberSequenceKeypoint.new(1, 0) })
		sparkle.Color = ColorSequence.new(tierInfo.color or rarity.color)
		sparkle.Parent = root
	end

	local scale = PET_SCALE * (look.size or 1) * (1 + (tier - 1) * 0.12)
	pcall(function() model:ScaleTo(scale) end)

	if forWorld then
		for _, p in ipairs(model:GetDescendants()) do
			if p:IsA("BasePart") and p ~= root then
				local weld = Instance.new("WeldConstraint")
				weld.Part0 = root
				weld.Part1 = p
				weld.Parent = p
				p.Anchored = false
				p.Massless = true
			end
		end
	end
	return model
end

return PetModels
