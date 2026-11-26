--[[
	MAPBUILDER – baut beim Serverstart alle 8 Welten automatisch auf:
	Boden, Deko je nach Thema, Geschenkbox-Stand, Rivale, Boss, Portale,
	Ranglisten-Tafel und Info-Tafel.

	Tipp: Du kannst die Karte später in Studio von Hand verschönern.
	Starte dazu das Spiel (Play), kopiere Workspace > Map, stoppe,
	füge sie ein und lösche dann den Aufruf von MapBuilder in "Main".
]]

local Players = game:GetService("Players")
local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config"))
local Util = require(Shared:WaitForChild("Util"))
local Logic = require(Shared:WaitForChild("Logic"))

local MapBuilder = {}
MapBuilder.eggPrompts = {}    -- { prompt, egg, count }
MapBuilder.npcs = {}          -- { prompt, def, world, isBoss }
MapBuilder.portals = {}       -- { prompt, target }
MapBuilder.boardRows = {}     -- Textzeilen der Ranglisten-Tafel
MapBuilder.minigames = { gyms = {}, courses = {} }   -- Parkour, Rennen, Gym-Stationen

local S = Config.WORLD_SIZE
local HALF = S / 2
local WHITE = Color3.new(1, 1, 1)
local currentFolder = nil

----------------------------------------------------------------------------
-- Bau-Helfer
----------------------------------------------------------------------------
local function part(props)
	local p = Instance.new(props.Class or "Part")
	p.Anchored = true
	p.TopSurface = Enum.SurfaceType.Smooth
	p.BottomSurface = Enum.SurfaceType.Smooth
	if props.Shape then p.Shape = props.Shape end
	if props.Size then p.Size = props.Size end
	for k, v in pairs(props) do
		if k ~= "Class" and k ~= "Parent" and k ~= "Shape" and k ~= "Size" then
			p[k] = v
		end
	end
	p.Parent = props.Parent or currentFolder
	return p
end

local function textLabel(parent, text, color, font)
	local l = Instance.new("TextLabel")
	l.Size = UDim2.new(1, 0, 1, 0)
	l.BackgroundTransparency = 1
	l.TextScaled = true
	l.RichText = true
	l.Font = font or Enum.Font.FredokaOne
	l.TextColor3 = color or WHITE
	l.TextStrokeTransparency = 0.3
	l.Text = text
	l.Parent = parent
	return l
end

local function billboard(parent, text, w, h, offsetY, color)
	local bb = Instance.new("BillboardGui")
	bb.Size = UDim2.new(w, 0, h, 0)
	bb.StudsOffset = Vector3.new(0, offsetY, 0)
	bb.MaxDistance = 220
	bb.LightInfluence = 0
	bb.Parent = parent
	local l = textLabel(bb, text, color)
	return bb, l
end

local function surfaceSign(p, face, text, bg, fg)
	local sg = Instance.new("SurfaceGui")
	sg.Face = face
	sg.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
	sg.PixelsPerStud = 30
	sg.LightInfluence = 0
	sg.Parent = p
	local frame = Instance.new("Frame")
	frame.Size = UDim2.new(1, 0, 1, 0)
	frame.BackgroundColor3 = bg or Color3.fromRGB(20, 5, 35)
	frame.BackgroundTransparency = bg and 0 or 1
	frame.Parent = sg
	local l = textLabel(frame, text, fg)
	return sg, l
end

local function prompt(parent, action, object, hold, key)
	local pr = Instance.new("ProximityPrompt")
	pr.ActionText = action
	pr.ObjectText = object or ""
	pr.HoldDuration = hold or 0
	pr.MaxActivationDistance = 14
	pr.RequiresLineOfSight = false
	if key then pr.KeyboardKeyCode = key end
	pr.Parent = parent
	return pr
end

-- Plätze, an denen keine Deko stehen soll (relativ zur Weltmitte)
local RESERVED = {
	{ 0, 0, 55 }, { 95, -55, 70 }, { -85, -40, 50 }, { 0, -160, 40 },
	{ 200, 0, 30 }, { -200, 0, 30 }, { 0, 100, 30 }, { -45, 60, 18 },
	{ -150, 120, 48 }, { -150, -110, 48 }, { 40, 62, 14 },
	{ -170, 60, 22 }, { -170, 110, 22 }, { -170, 160, 22 }, { -170, 205, 22 },
}
local currentReserved = {}
local currentMaxZ = nil      -- am Strand: ab hier beginnt das Meer   -- zusätzliche Sperrflächen der Welt, die gerade gebaut wird
local function isFree(x, z, radius)
	for _, r in ipairs(currentReserved) do
		local dx, dz = x - r[1], z - r[2]
		if math.sqrt(dx * dx + dz * dz) < r[3] + radius then
			return false
		end
	end
	for _, r in ipairs(RESERVED) do
		local dx, dz = x - r[1], z - r[2]
		if math.sqrt(dx * dx + dz * dz) < r[3] + radius then
			return false
		end
	end
	return true
end
local function freeSpot(rng, radius, minDist, maxDist)
	for _ = 1, 60 do
		-- Abstand zum Rand, damit nichts in Bergen/Dünen am Weltrand steckt
		local x = rng:NextNumber(-HALF + radius + 22, HALF - radius - 22)
		local z = rng:NextNumber(-HALF + radius + 22, HALF - radius - 22)
		local d = math.sqrt(x * x + z * z)
		if d >= (minDist or 0) and d <= (maxDist or 9999) and (not currentMaxZ or z + radius < currentMaxZ) and isFree(x, z, radius) then
			return x, z
		end
	end
	return nil
end

----------------------------------------------------------------------------
-- Deko-Bausteine
----------------------------------------------------------------------------
local function tree(O, x, z, color, scale)
	scale = scale or 1
	local leaf = color or Color3.fromRGB(63, 143, 69)
	part({ Size = Vector3.new(1.6, 11, 1.6) * scale, CFrame = CFrame.new(O + Vector3.new(x, 5.5 * scale, z)), Color = Color3.fromRGB(105, 70, 45), Material = Enum.Material.Wood })
	part({ Size = Vector3.new(0.7, 4, 0.7) * scale, CFrame = CFrame.new(O + Vector3.new(x + 1.2 * scale, 8 * scale, z)) * CFrame.Angles(0, 0, math.rad(-40)), Color = Color3.fromRGB(105, 70, 45), Material = Enum.Material.Wood })
	local blobs = { { 0, 13, 0, 9 }, { 2.6, 11.5, 1.2, 6.5 }, { -2.4, 11.8, -1, 6.8 }, { 0.6, 15.5, -0.8, 6 }, { -1, 12, 2.4, 6 } }
	for i, b in ipairs(blobs) do
		local shade = (i % 2 == 0) and 0.12 or -0.05
		part({ Shape = Enum.PartType.Ball, Size = Vector3.new(b[4], b[4], b[4]) * scale, CFrame = CFrame.new(O + Vector3.new(x + b[1] * scale, b[2] * scale, z + b[3] * scale)),
			Color = leaf:Lerp(shade > 0 and Color3.new(1, 1, 0.6) or Color3.new(0, 0.2, 0), math.abs(shade)), Material = Enum.Material.Grass })
	end
end

local function palm(O, x, z, rng)
	local tilt = math.rad(rng:NextNumber(-12, 12))
	part({ Shape = Enum.PartType.Cylinder, Size = Vector3.new(16, 1.6, 1.6),
		CFrame = CFrame.new(O + Vector3.new(x, 8, z)) * CFrame.Angles(0, 0, math.rad(90) + tilt), Color = Color3.fromRGB(150, 105, 60), Material = Enum.Material.Wood })
	for k = 0, 4 do
		local a = math.rad(k * 72)
		part({ Size = Vector3.new(1, 0.5, 8), CFrame = CFrame.new(O + Vector3.new(x, 16, z)) * CFrame.Angles(0, a, 0) * CFrame.new(0, 0, -4) * CFrame.Angles(math.rad(-20), 0, 0),
			Color = Color3.fromRGB(60, 170, 70), Material = Enum.Material.Grass })
	end
end

local function lamp(O, x, z)
	part({ Size = Vector3.new(0.8, 14, 0.8), CFrame = CFrame.new(O + Vector3.new(x, 7, z)), Color = Color3.fromRGB(60, 60, 70), Material = Enum.Material.Metal })
	local bulb = part({ Shape = Enum.PartType.Ball, Size = Vector3.new(2.2, 2.2, 2.2), CFrame = CFrame.new(O + Vector3.new(x, 14.5, z)), Color = Color3.fromRGB(255, 225, 140), Material = Enum.Material.Neon })
	local light = Instance.new("PointLight")
	light.Range = 18
	light.Brightness = 1.2
	light.Color = Color3.fromRGB(255, 220, 160)
	light.Parent = bulb
end

local BUILDING_COLORS = {
	Color3.fromRGB(91, 95, 151), Color3.fromRGB(242, 132, 130), Color3.fromRGB(192, 133, 82), Color3.fromRGB(77, 144, 142),
	Color3.fromRGB(127, 200, 216), Color3.fromRGB(179, 136, 255), Color3.fromRGB(233, 196, 106), Color3.fromRGB(110, 110, 130),
}

local function building(O, x, z, w, d, h, color, material, signText, accent)
	part({ Size = Vector3.new(w, h, d), CFrame = CFrame.new(O + Vector3.new(x, h / 2, z)), Color = color, Material = material or Enum.Material.SmoothPlastic })
	part({ Size = Vector3.new(w + 1, 1.5, d + 1), CFrame = CFrame.new(O + Vector3.new(x, h + 0.75, z)), Color = color:Lerp(Color3.new(0, 0, 0), 0.35) })
	-- Fensterreihen auf allen vier Seiten
	local floors = math.floor(h / 10)
	for f = 1, floors do
		local y = f * 10 - 4
		part({ Size = Vector3.new(w * 0.8, 3, d + 0.4), CFrame = CFrame.new(O + Vector3.new(x, y, z)), Color = accent or Color3.fromRGB(255, 240, 190), Material = Enum.Material.Neon, Transparency = 0.25 })
		part({ Size = Vector3.new(w + 0.4, 3, d * 0.8), CFrame = CFrame.new(O + Vector3.new(x, y, z)), Color = accent or Color3.fromRGB(255, 240, 190), Material = Enum.Material.Neon, Transparency = 0.25 })
	end
	if signText then
		-- Schild auf der Seite, die zur Weltmitte zeigt
		local face, offset
		if math.abs(x) > math.abs(z) then
			if x > 0 then face, offset = Enum.NormalId.Left, Vector3.new(-w / 2 - 0.6, 0, 0)
			else face, offset = Enum.NormalId.Right, Vector3.new(w / 2 + 0.6, 0, 0) end
		else
			if z > 0 then face, offset = Enum.NormalId.Front, Vector3.new(0, 0, -d / 2 - 0.6)
			else face, offset = Enum.NormalId.Back, Vector3.new(0, 0, d / 2 + 0.6) end
		end
		local signPart = part({ Size = Vector3.new(math.abs(offset.Z) > 0 and w * 0.8 or 1, 6, math.abs(offset.X) > 0 and d * 0.8 or 1),
			CFrame = CFrame.new(O + Vector3.new(x, math.min(h - 4, 14), z) + offset), Color = Color3.fromRGB(20, 5, 35) })
		surfaceSign(signPart, face, signText, Color3.fromRGB(20, 5, 35), WHITE)
	end
end

local function rock(O, x, z, size, color)
	part({ Shape = Enum.PartType.Ball, Size = Vector3.new(size, size * 0.7, size), CFrame = CFrame.new(O + Vector3.new(x, size * 0.2, z)),
		Color = color or Color3.fromRGB(120, 120, 125), Material = Enum.Material.Slate })
end

----------------------------------------------------------------------------
-- Themen der Welten
----------------------------------------------------------------------------
local THEMES = {}

THEMES.city = function(O, w, rng)
	for _, horizontal in ipairs({ true, false }) do
		local road = horizontal and Vector3.new(S, 0.2, 24) or Vector3.new(24, 0.2, S)
		part({ Size = road, CFrame = CFrame.new(O + Vector3.new(0, horizontal and 0.1 or 0.12, 0)), Color = Color3.fromRGB(55, 55, 60), Material = Enum.Material.Asphalt })
		for _, side in ipairs({ -1, 1 }) do
			local walk = horizontal and Vector3.new(S, 0.5, 4) or Vector3.new(4, 0.5, S)
			local off = horizontal and Vector3.new(0, 0.25, side * 14) or Vector3.new(side * 14, 0.25, 0)
			part({ Size = walk, CFrame = CFrame.new(O + off), Color = Color3.fromRGB(190, 188, 182), Material = Enum.Material.Concrete })
		end
		for k = -11, 11 do
			if math.abs(k) > 1 then
				local dash = horizontal and Vector3.new(6, 0.22, 0.5) or Vector3.new(0.5, 0.22, 6)
				local pos = horizontal and Vector3.new(k * 20, 0.13, 0) or Vector3.new(0, 0.14, k * 20)
				part({ Size = dash, CFrame = CFrame.new(O + pos), Color = Color3.fromRGB(245, 245, 240) })
			end
		end
	end
	local names = { "💪 IRON GYM", "✂️ SALON GLOW", "☕ CAFÉ MEWING", "🛍️ DRIP MALL", "🦷 DR. STRAHLEWEISS", "🪞 SELFIE-STUDIO", "🏋️ PROTEIN-BAR", "💈 BARBER" }
	for i = 1, 16 do
		local wdt, dep = rng:NextNumber(26, 40), rng:NextNumber(26, 40)
		local x, z = freeSpot(rng, math.max(wdt, dep) / 2 + 4, 90)
		if x and math.abs(x) > 20 and math.abs(z) > 20 then
			building(O, x, z, wdt, dep, rng:NextNumber(28, 90), BUILDING_COLORS[rng:NextInteger(1, #BUILDING_COLORS)], nil, names[i])
		end
	end
	for i = 1, 18 do
		local x, z = freeSpot(rng, 2, 40)
		if x then lamp(O, x, z) end
	end
	for _ = 1, 16 do
		local x, z = freeSpot(rng, 6, 60)
		if x then tree(O, x, z) end
	end
end

THEMES.beach = function(O, w, rng)
	-- Meer (man kann ein Stück hineinlaufen)
	pcall(function()
		workspace.Terrain:FillBlock(CFrame.new(O + Vector3.new(0, -14, 190)), Vector3.new(S, 4, 120), Enum.Material.Sand)
		workspace.Terrain:FillBlock(CFrame.new(O + Vector3.new(0, -6, 190)), Vector3.new(S, 12, 120), Enum.Material.Water)
	end)
	for _ = 1, 26 do
		local x, z = freeSpot(rng, 5, 60)
		if x and z < 120 then palm(O, x, z, rng) end
	end
	local umbrellaColors = { Color3.fromRGB(255, 80, 120), Color3.fromRGB(255, 200, 0), Color3.fromRGB(0, 200, 220), Color3.fromRGB(120, 220, 90) }
	for _ = 1, 12 do
		local x, z = freeSpot(rng, 6, 60)
		if x and z < 120 then
			part({ Size = Vector3.new(0.5, 9, 0.5), CFrame = CFrame.new(O + Vector3.new(x, 4.5, z)), Color = WHITE })
			part({ Shape = Enum.PartType.Cylinder, Size = Vector3.new(0.6, 12, 12), CFrame = CFrame.new(O + Vector3.new(x, 9, z)) * CFrame.Angles(0, 0, math.rad(90)),
				Color = umbrellaColors[rng:NextInteger(1, #umbrellaColors)] })
			part({ Size = Vector3.new(4, 0.2, 7), CFrame = CFrame.new(O + Vector3.new(x + 3, 0.15, z + 2)), Color = umbrellaColors[rng:NextInteger(1, #umbrellaColors)] })
		end
	end
	-- Muscle Beach: Hantel-Deko
	for k = -2, 2 do
		local x, z = 130 + k * 12, -110
		part({ Shape = Enum.PartType.Cylinder, Size = Vector3.new(8, 0.6, 0.6), CFrame = CFrame.new(O + Vector3.new(x, 1.2, z)), Color = Color3.fromRGB(80, 80, 80), Material = Enum.Material.Metal })
		part({ Shape = Enum.PartType.Cylinder, Size = Vector3.new(1, 2.6, 2.6), CFrame = CFrame.new(O + Vector3.new(x - 3.5, 1.3, z)), Color = Color3.fromRGB(30, 30, 30) })
		part({ Shape = Enum.PartType.Cylinder, Size = Vector3.new(1, 2.6, 2.6), CFrame = CFrame.new(O + Vector3.new(x + 3.5, 1.3, z)), Color = Color3.fromRGB(30, 30, 30) })
	end
	local signPart = part({ Size = Vector3.new(30, 6, 1), CFrame = CFrame.new(O + Vector3.new(130, 9, -125)), Color = Color3.fromRGB(20, 5, 35) })
	part({ Size = Vector3.new(1, 9, 1), CFrame = CFrame.new(O + Vector3.new(118, 4.5, -125)), Color = Color3.fromRGB(150, 105, 60) })
	part({ Size = Vector3.new(1, 9, 1), CFrame = CFrame.new(O + Vector3.new(142, 4.5, -125)), Color = Color3.fromRGB(150, 105, 60) })
	surfaceSign(signPart, Enum.NormalId.Back, "🏋️ MUSCLE BEACH", Color3.fromRGB(20, 5, 35), WHITE)
end

THEMES.mountain = function(O, w, rng)
	-- Berge am Rand mit Schneekappen
	for k = 1, 14 do
		local a = (k / 14) * math.pi * 2
		local size = rng:NextNumber(90, 150)
		local radius = size * 0.55
		-- Mittelpunkt hinter der Weltgrenze: die Berge sind Kulisse und verschlucken keine Deko oder Portale
		local r = HALF + radius * 0.75
		local x, z = math.cos(a) * r, math.sin(a) * r
		do
			local center = O + Vector3.new(x, -radius * 0.2, z)
			pcall(function()
				workspace.Terrain:FillBall(center, radius, Enum.Material.Rock)
				workspace.Terrain:FillBall(center + Vector3.new(0, radius * 0.62, 0), radius * 0.48, Enum.Material.Snow)
			end)
		end
	end
	for _ = 1, 30 do
		local x, z = freeSpot(rng, 5, 60, HALF - 60)
		if x then
			part({ Size = Vector3.new(1.6, 6, 1.6), CFrame = CFrame.new(O + Vector3.new(x, 3, z)), Color = Color3.fromRGB(110, 70, 40), Material = Enum.Material.Wood })
			for t = 0, 2 do
				local s = 9 - t * 2.5
				part({ Shape = Enum.PartType.Ball, Size = Vector3.new(s, s, s), CFrame = CFrame.new(O + Vector3.new(x, 6 + t * 4, z)), Color = Color3.fromRGB(35, 100, 55), Material = Enum.Material.Grass })
			end
		end
	end
	for _ = 1, 18 do
		local x, z = freeSpot(rng, 5, 60)
		if x then rock(O, x, z, rng:NextNumber(4, 10)) end
	end
	-- Protein-Wasserfall (Deko)
	part({ Size = Vector3.new(14, 60, 2), CFrame = CFrame.new(O + Vector3.new(-120, 30, -238)), Color = Color3.fromRGB(240, 235, 225), Material = Enum.Material.Neon, Transparency = 0.3 })
	part({ Shape = Enum.PartType.Cylinder, Size = Vector3.new(1, 30, 30), CFrame = CFrame.new(O + Vector3.new(-120, 0.4, -222)) * CFrame.Angles(0, 0, math.rad(90)),
		Color = Color3.fromRGB(240, 235, 225), Material = Enum.Material.Glass, Transparency = 0.2, CanCollide = false })
end

THEMES.temple = function(O, w, rng)
	-- Moai-Statuen im Kreis
	for k = 1, 10 do
		local a = (k / 10) * math.pi * 2
		local x, z = math.cos(a) * 150, math.sin(a) * 150
		if isFree(x, z, 8) then
			local cf = CFrame.new(O + Vector3.new(x, 0, z)) * CFrame.Angles(0, math.atan2(x, z), 0)
			part({ Size = Vector3.new(8, 12, 6), CFrame = cf * CFrame.new(0, 6, 0), Color = Color3.fromRGB(110, 105, 100), Material = Enum.Material.Slate })
			part({ Size = Vector3.new(7, 11, 7), CFrame = cf * CFrame.new(0, 17.5, 0), Color = Color3.fromRGB(120, 115, 108), Material = Enum.Material.Slate })
			part({ Size = Vector3.new(7.2, 2, 7.6), CFrame = cf * CFrame.new(0, 20, 0), Color = Color3.fromRGB(100, 95, 90), Material = Enum.Material.Slate })
			part({ Class = "WedgePart", Size = Vector3.new(2, 4, 2), CFrame = cf * CFrame.new(0, 17, -4.4) * CFrame.Angles(0, math.rad(180), 0), Color = Color3.fromRGB(110, 105, 100), Material = Enum.Material.Slate })
		end
	end
	-- Tempeltreppe hinter dem Boss
	for step = 0, 6 do
		part({ Size = Vector3.new(90 - step * 10, 3, 14), CFrame = CFrame.new(O + Vector3.new(0, 1.5 + step * 3, -205 - step * 4)), Color = Color3.fromRGB(190, 175, 140), Material = Enum.Material.Sandstone })
	end
	-- Fackeln
	for _ = 1, 16 do
		local x, z = freeSpot(rng, 2, 50)
		if x then
			part({ Size = Vector3.new(1, 7, 1), CFrame = CFrame.new(O + Vector3.new(x, 3.5, z)), Color = Color3.fromRGB(90, 60, 40), Material = Enum.Material.Wood })
			local fire = part({ Shape = Enum.PartType.Ball, Size = Vector3.new(2, 2, 2), CFrame = CFrame.new(O + Vector3.new(x, 7.5, z)), Color = Color3.fromRGB(255, 140, 30), Material = Enum.Material.Neon })
			local f = Instance.new("Fire")
			f.Size = 3
			f.Heat = 5
			f.Parent = fire
		end
	end
	for _ = 1, 14 do
		local x, z = freeSpot(rng, 6, 60)
		if x then tree(O, x, z, Color3.fromRGB(80, 160, 70)) end
	end
end

THEMES.fashion = function(O, w, rng)
	-- Laufsteg
	part({ Size = Vector3.new(14, 2, 90), CFrame = CFrame.new(O + Vector3.new(0, 1, -95)), Color = WHITE, Material = Enum.Material.Marble })
	part({ Size = Vector3.new(0.6, 0.3, 90), CFrame = CFrame.new(O + Vector3.new(-6.8, 2.1, -95)), Color = w.accent, Material = Enum.Material.Neon })
	part({ Size = Vector3.new(0.6, 0.3, 90), CFrame = CFrame.new(O + Vector3.new(6.8, 2.1, -95)), Color = w.accent, Material = Enum.Material.Neon })
	local names = { "👗 COUTURE", "👠 SCHUHE", "🕶️ BRILLEN", "👜 TASCHEN", "💍 SCHMUCK", "🧥 MÄNTEL", "🎩 HÜTE", "💄 BEAUTY" }
	for i = 1, 14 do
		local wdt = rng:NextNumber(26, 36)
		local x, z = freeSpot(rng, wdt / 2 + 4, 90)
		if x then
			building(O, x, z, wdt, wdt, rng:NextNumber(26, 60), Color3.fromRGB(35, 30, 45), Enum.Material.SmoothPlastic, names[i], w.accent)
		end
	end
	for _ = 1, 14 do
		local x, z = freeSpot(rng, 2, 40)
		if x then
			part({ Size = Vector3.new(0.8, 16, 0.8), CFrame = CFrame.new(O + Vector3.new(x, 8, z)), Color = Color3.fromRGB(30, 30, 30) })
			local spot = part({ Shape = Enum.PartType.Ball, Size = Vector3.new(2.5, 2.5, 2.5), CFrame = CFrame.new(O + Vector3.new(x, 16.5, z)), Color = w.accent, Material = Enum.Material.Neon })
			local l = Instance.new("PointLight")
			l.Color = w.accent
			l.Range = 22
			l.Parent = spot
		end
	end
end

THEMES.hollywood = function(O, w, rng)
	for k = -3, 3 do
		local r = rng:NextNumber(60, 95)
		part({ Shape = Enum.PartType.Ball, Size = Vector3.new(r * 2, r * 2, r * 2), CFrame = CFrame.new(O + Vector3.new(k * 70, -r * 0.4, -300)),
			Color = Color3.fromRGB(120, 140, 70), Material = Enum.Material.Grass, CanCollide = false })
	end
	local signPart = part({ Size = Vector3.new(130, 20, 1), CFrame = CFrame.new(O + Vector3.new(0, 45, -255)), Transparency = 1, CanCollide = false })
	surfaceSign(signPart, Enum.NormalId.Back, "G L O W Y W O O D", nil, WHITE)
	-- Roter Teppich zum Boss
	part({ Size = Vector3.new(10, 0.3, 100), CFrame = CFrame.new(O + Vector3.new(0, 0.15, -90)), Color = Color3.fromRGB(200, 20, 40), Material = Enum.Material.Fabric })
	for z = -45, -135, -15 do
		for _, x in ipairs({ -8, 8 }) do
			part({ Size = Vector3.new(0.6, 3, 0.6), CFrame = CFrame.new(O + Vector3.new(x, 1.5, z)), Color = Color3.fromRGB(212, 175, 55), Material = Enum.Material.Metal })
		end
	end
	-- Walk of Fame Sterne
	for _ = 1, 36 do
		local x, z = freeSpot(rng, 2, 50)
		if x then
			part({ Size = Vector3.new(4, 0.2, 4), CFrame = CFrame.new(O + Vector3.new(x, 0.12, z)) * CFrame.Angles(0, math.rad(45), 0), Color = Color3.fromRGB(255, 120, 160), Material = Enum.Material.Neon, Transparency = 0.3 })
		end
	end
	for i = 1, 10 do
		local wdt = rng:NextNumber(24, 34)
		local x, z = freeSpot(rng, wdt / 2 + 4, 90)
		if x then building(O, x, z, wdt, wdt, rng:NextNumber(24, 50), BUILDING_COLORS[rng:NextInteger(1, #BUILDING_COLORS)], nil, i <= 4 and ({ "🎬 STUDIO 1", "🍿 KINO", "📸 PAPARAZZI", "⭐ STAR-HOTEL" })[i] or nil) end
	end
	for _ = 1, 12 do
		local x, z = freeSpot(rng, 5, 60)
		if x then palm(O, x, z, rng) end
	end
end

THEMES.dubai = function(O, w, rng)
	-- Wolkenkratzer aus Gold und Glas
	for i = 1, 14 do
		local wdt = rng:NextNumber(18, 30)
		local x, z = freeSpot(rng, wdt / 2 + 4, 110)
		if x then
			local h = rng:NextNumber(110, 240)
			local gold = rng:NextNumber() < 0.5
			building(O, x, z, wdt, wdt, h, gold and Color3.fromRGB(212, 175, 55) or Color3.fromRGB(120, 170, 210),
				gold and Enum.Material.Foil or Enum.Material.Glass, nil, Color3.fromRGB(255, 240, 200))
		end
	end
	-- Der höchste Turm hinter dem Boss
	part({ Size = Vector3.new(24, 330, 24), CFrame = CFrame.new(O + Vector3.new(0, 165, -225)), Color = Color3.fromRGB(200, 210, 225), Material = Enum.Material.Glass })
	part({ Size = Vector3.new(4, 60, 4), CFrame = CFrame.new(O + Vector3.new(0, 360, -225)), Color = Color3.fromRGB(212, 175, 55), Material = Enum.Material.Neon })
	for _ = 1, 16 do
		local x, z = freeSpot(rng, 5, 60)
		if x then palm(O, x, z, rng) end
	end
end

THEMES.galaxy = function(O, w, rng)
	-- Leuchtendes Gitter im Boden
	for k = -4, 4 do
		part({ Size = Vector3.new(S, 0.2, 0.6), CFrame = CFrame.new(O + Vector3.new(0, 0.1, k * 55)), Color = w.accent, Material = Enum.Material.Neon, Transparency = 0.4 })
		part({ Size = Vector3.new(0.6, 0.2, S), CFrame = CFrame.new(O + Vector3.new(k * 55, 0.1, 0)), Color = w.accent, Material = Enum.Material.Neon, Transparency = 0.4 })
	end
	-- Schwebende Planeten
	local planetColors = { Color3.fromRGB(255, 120, 200), Color3.fromRGB(90, 200, 255), Color3.fromRGB(255, 200, 80), Color3.fromRGB(150, 255, 160), Color3.fromRGB(200, 120, 255) }
	for k = 1, 10 do
		local r = rng:NextNumber(10, 38)
		local a = rng:NextNumber(0, math.pi * 2)
		local dist = rng:NextNumber(120, 240)
		local pos = O + Vector3.new(math.cos(a) * dist, rng:NextNumber(70, 170), math.sin(a) * dist)
		part({ Shape = Enum.PartType.Ball, Size = Vector3.new(r, r, r), CFrame = CFrame.new(pos), Color = planetColors[(k % #planetColors) + 1], Material = Enum.Material.Neon, CanCollide = false })
		if k % 3 == 0 then
			part({ Shape = Enum.PartType.Cylinder, Size = Vector3.new(0.6, r * 1.9, r * 1.9), CFrame = CFrame.new(pos) * CFrame.Angles(math.rad(20), 0, math.rad(90)),
				Color = WHITE, Material = Enum.Material.Neon, Transparency = 0.5, CanCollide = false })
		end
	end
	-- Sterne
	for _ = 1, 90 do
		local s = rng:NextNumber(0.6, 1.8)
		part({ Size = Vector3.new(s, s, s), CFrame = CFrame.new(O + Vector3.new(rng:NextNumber(-HALF, HALF), rng:NextNumber(80, 260), rng:NextNumber(-HALF, HALF))),
			Color = WHITE, Material = Enum.Material.Neon, CanCollide = false })
	end
	-- Kristalle
	for _ = 1, 18 do
		local x, z = freeSpot(rng, 4, 60)
		if x then
			local h = rng:NextNumber(6, 18)
			part({ Class = "WedgePart", Size = Vector3.new(3, h, 3), CFrame = CFrame.new(O + Vector3.new(x, h / 2, z)) * CFrame.Angles(0, rng:NextNumber(0, 6), 0),
				Color = planetColors[rng:NextInteger(1, #planetColors)], Material = Enum.Material.Neon, Transparency = 0.2 })
		end
	end
end

----------------------------------------------------------------------------
-- ZUSÄTZLICHE DEKORATION (damit die Welten voller und lebendiger wirken)
----------------------------------------------------------------------------
local function ellipsoid(props)
	local p = part(props)
	local m = Instance.new("SpecialMesh")
	m.MeshType = Enum.MeshType.Sphere
	m.Parent = p
	return p
end

local SLOGANS = { "DRINK WATER 💧", "MEWING IS LIFE 🗿", "SKINCARE > ALLES 🧴", "8 STUNDEN SCHLAF 😴", "SMILE MORE 😁",
	"GLOW UP SEASON ✨", "LEON IST ÜBERALL 👑", "PROTEIN 💪", "SONNENCREME! ☀️", "ZAHNSEIDE RETTET LEBEN 🧵" }
local FLOWER_COLORS = { Color3.fromRGB(255, 90, 120), Color3.fromRGB(255, 220, 80), Color3.fromRGB(170, 110, 255), Color3.fromRGB(255, 255, 255), Color3.fromRGB(255, 150, 60) }
local CAR_COLORS = { Color3.fromRGB(230, 57, 70), Color3.fromRGB(58, 134, 255), Color3.fromRGB(255, 200, 40), Color3.fromRGB(40, 40, 45), Color3.fromRGB(240, 240, 240), Color3.fromRGB(42, 157, 143) }

local function cloud(O, rng)
	local c = O + Vector3.new(rng:NextNumber(-HALF, HALF), rng:NextNumber(95, 150), rng:NextNumber(-HALF, HALF))
	for k = 1, 5 do
		local r = rng:NextNumber(12, 22)
		part({ Shape = Enum.PartType.Ball, Size = Vector3.new(r, r, r), CFrame = CFrame.new(c + Vector3.new((k - 3) * 9, rng:NextNumber(-3, 3), rng:NextNumber(-5, 5))),
			Color = Color3.fromRGB(255, 255, 255), Material = Enum.Material.SmoothPlastic, Transparency = 0.15, CanCollide = false, CastShadow = false })
	end
end

local function bench(O, x, z, rot)
	local base = CFrame.new(O + Vector3.new(x, 0, z)) * CFrame.Angles(0, rot, 0)
	part({ Size = Vector3.new(7, 0.5, 2), CFrame = base * CFrame.new(0, 1.6, 0), Color = Color3.fromRGB(150, 95, 55), Material = Enum.Material.WoodPlanks })
	part({ Size = Vector3.new(7, 1.6, 0.4), CFrame = base * CFrame.new(0, 2.6, 0.8), Color = Color3.fromRGB(150, 95, 55), Material = Enum.Material.WoodPlanks })
	for _, s in ipairs({ -3, 3 }) do part({ Size = Vector3.new(0.4, 1.6, 1.8), CFrame = base * CFrame.new(s, 0.8, 0), Color = Color3.fromRGB(50, 50, 55), Material = Enum.Material.Metal }) end
end

local function bush(O, x, z, color, size)
	size = size or 4
	ellipsoid({ Size = Vector3.new(size * 1.3, size, size * 1.2), CFrame = CFrame.new(O + Vector3.new(x, size * 0.35, z)), Color = color or Color3.fromRGB(60, 150, 70), Material = Enum.Material.Grass })
end

local function flowerbed(O, x, z, rng)
	part({ Size = Vector3.new(7, 0.8, 4), CFrame = CFrame.new(O + Vector3.new(x, 0.4, z)), Color = Color3.fromRGB(110, 75, 45), Material = Enum.Material.Ground })
	for k = 1, 8 do
		local col = FLOWER_COLORS[rng:NextInteger(1, #FLOWER_COLORS)]
		part({ Shape = Enum.PartType.Ball, Size = Vector3.new(0.9, 0.9, 0.9), CFrame = CFrame.new(O + Vector3.new(x + rng:NextNumber(-3, 3), 1.2, z + rng:NextNumber(-1.6, 1.6))), Color = col })
	end
end

local function trashcan(O, x, z)
	part({ Shape = Enum.PartType.Cylinder, Size = Vector3.new(3, 2.2, 2.2), CFrame = CFrame.new(O + Vector3.new(x, 1.5, z)) * CFrame.Angles(0, 0, math.rad(90)), Color = Color3.fromRGB(60, 120, 80), Material = Enum.Material.Metal })
	part({ Shape = Enum.PartType.Cylinder, Size = Vector3.new(0.3, 2.4, 2.4), CFrame = CFrame.new(O + Vector3.new(x, 3.1, z)) * CFrame.Angles(0, 0, math.rad(90)), Color = Color3.fromRGB(40, 90, 60), Material = Enum.Material.Metal })
end

local function bigSign(O, x, z, text, rot, color)
	local base = CFrame.new(O + Vector3.new(x, 0, z)) * CFrame.Angles(0, rot, 0)
	for _, s in ipairs({ -8, 8 }) do part({ Size = Vector3.new(1, 14, 1), CFrame = base * CFrame.new(s, 7, 0), Color = Color3.fromRGB(60, 60, 70), Material = Enum.Material.Metal }) end
	local panel = part({ Size = Vector3.new(22, 8, 0.8), CFrame = base * CFrame.new(0, 15, 0), Color = color or Color3.fromRGB(255, 79, 216) })
	surfaceSign(panel, Enum.NormalId.Front, text, color or Color3.fromRGB(255, 79, 216), WHITE)
	surfaceSign(panel, Enum.NormalId.Back, text, color or Color3.fromRGB(255, 79, 216), WHITE)
end

local function car(O, x, z, rot, color, luxury)
	local base = CFrame.new(O + Vector3.new(x, 0, z)) * CFrame.Angles(0, rot, 0)
	local mat = luxury and Enum.Material.Foil or Enum.Material.SmoothPlastic
	part({ Size = Vector3.new(5, 1.8, 10), CFrame = base * CFrame.new(0, 1.7, 0), Color = color, Material = mat, Reflectance = luxury and 0.3 or 0.1 })
	part({ Size = Vector3.new(4.4, 1.6, 5), CFrame = base * CFrame.new(0, 3.3, 0.6), Color = Color3.fromRGB(150, 200, 230), Material = Enum.Material.Glass, Transparency = 0.3 })
	for _, p in ipairs({ { -2.4, -3.2 }, { 2.4, -3.2 }, { -2.4, 3.2 }, { 2.4, 3.2 } }) do
		part({ Shape = Enum.PartType.Cylinder, Size = Vector3.new(0.8, 2, 2), CFrame = base * CFrame.new(p[1], 1, p[2]), Color = Color3.fromRGB(25, 25, 25) })
	end
	for _, s in ipairs({ -1.6, 1.6 }) do part({ Size = Vector3.new(0.9, 0.5, 0.2), CFrame = base * CFrame.new(s, 1.9, -5.05), Color = Color3.fromRGB(255, 250, 200), Material = Enum.Material.Neon }) end
end

local function statue(O, x, z, color, rot)
	local base = CFrame.new(O + Vector3.new(x, 0, z)) * CFrame.Angles(0, rot or 0, 0)
	part({ Size = Vector3.new(6, 3, 6), CFrame = base * CFrame.new(0, 1.5, 0), Color = Color3.fromRGB(230, 225, 215), Material = Enum.Material.Marble })
	local mat = Enum.Material.Foil
	part({ Size = Vector3.new(4.5, 4, 2), CFrame = base * CFrame.new(0, 8.5, 0), Color = color, Material = mat, Reflectance = 0.3 })   -- Brust (breit!)
	part({ Size = Vector3.new(2.2, 3.5, 1.6), CFrame = base * CFrame.new(-1, 4.8, 0), Color = color, Material = mat, Reflectance = 0.3 })
	part({ Size = Vector3.new(2.2, 3.5, 1.6), CFrame = base * CFrame.new(1, 4.8, 0), Color = color, Material = mat, Reflectance = 0.3 })
	part({ Size = Vector3.new(1.4, 4, 1.4), CFrame = base * CFrame.new(-3.1, 9.5, 0) * CFrame.Angles(0, 0, math.rad(-150)), Color = color, Material = mat, Reflectance = 0.3 })   -- Bizeps-Pose
	part({ Size = Vector3.new(1.4, 4, 1.4), CFrame = base * CFrame.new(3.1, 9.5, 0) * CFrame.Angles(0, 0, math.rad(150)), Color = color, Material = mat, Reflectance = 0.3 })
	part({ Size = Vector3.new(2.2, 2.6, 2.4), CFrame = base * CFrame.new(0, 11.8, 0), Color = color, Material = mat, Reflectance = 0.3 })   -- kantiger Kopf
	part({ Size = Vector3.new(2.4, 0.8, 2.6), CFrame = base * CFrame.new(0, 10.8, -0.1), Color = color, Material = mat, Reflectance = 0.3 })  -- Kiefer
end

local function fountain(O, x, z)
	part({ Shape = Enum.PartType.Cylinder, Size = Vector3.new(2, 18, 18), CFrame = CFrame.new(O + Vector3.new(x, 1, z)) * CFrame.Angles(0, 0, math.rad(90)), Color = Color3.fromRGB(220, 220, 225), Material = Enum.Material.Marble })
	part({ Shape = Enum.PartType.Cylinder, Size = Vector3.new(0.4, 15.5, 15.5), CFrame = CFrame.new(O + Vector3.new(x, 2.05, z)) * CFrame.Angles(0, 0, math.rad(90)), Color = Color3.fromRGB(90, 190, 240), Material = Enum.Material.Glass, Transparency = 0.3 })
	part({ Size = Vector3.new(1.5, 6, 1.5), CFrame = CFrame.new(O + Vector3.new(x, 4, z)), Color = Color3.fromRGB(220, 220, 225), Material = Enum.Material.Marble })
	local top = part({ Shape = Enum.PartType.Ball, Size = Vector3.new(2, 2, 2), CFrame = CFrame.new(O + Vector3.new(x, 7.5, z)), Color = Color3.fromRGB(150, 220, 255), Material = Enum.Material.Glass, Transparency = 0.3 })
	local water = Instance.new("ParticleEmitter")
	water.Color = ColorSequence.new(Color3.fromRGB(180, 230, 255))
	water.Rate = 25
	water.Speed = NumberRange.new(6, 9)
	water.Lifetime = NumberRange.new(0.8, 1.1)
	water.SpreadAngle = Vector2.new(25, 25)
	water.Acceleration = Vector3.new(0, -20, 0)
	water.Size = NumberSequence.new(0.4)
	water.EmissionDirection = Enum.NormalId.Top
	water.Parent = top
end

-- Wetter / Teilchen in der Luft (Schnee, Blüten, Sterne …)
local function airParticles(O, color, size, speed, rate)
	local p = part({ Size = Vector3.new(S, 1, S), CFrame = CFrame.new(O + Vector3.new(0, 70, 0)), Transparency = 1, CanCollide = false, CanQuery = false })
	local e = Instance.new("ParticleEmitter")
	e.Color = ColorSequence.new(color)
	e.Size = NumberSequence.new(size)
	e.Rate = rate or 40
	e.Speed = NumberRange.new(speed, speed * 1.5)
	e.Lifetime = NumberRange.new(10, 14)
	e.EmissionDirection = Enum.NormalId.Bottom
	e.SpreadAngle = Vector2.new(15, 15)
	e.LightEmission = 0.4
	e.Parent = p
end

local THEME_DECO = {}

THEME_DECO.city = function(O, w, rng)
	for k = 1, 12 do
		local alongX = k % 2 == 0
		local pos = rng:NextNumber(70, 165) * (rng:NextNumber() < 0.5 and -1 or 1)
		local lane = (rng:NextNumber() < 0.5 and -6 or 6)
		if alongX then car(O, pos, lane, math.rad(90), CAR_COLORS[rng:NextInteger(1, #CAR_COLORS)])
		else car(O, lane, pos, 0, CAR_COLORS[rng:NextInteger(1, #CAR_COLORS)]) end
	end
	for _ = 1, 10 do
		local x, z = freeSpot(rng, 2, 50)
		if x then
			part({ Shape = Enum.PartType.Cylinder, Size = Vector3.new(2.6, 1.3, 1.3), CFrame = CFrame.new(O + Vector3.new(x, 1.3, z)) * CFrame.Angles(0, 0, math.rad(90)), Color = Color3.fromRGB(220, 40, 40) })
			part({ Shape = Enum.PartType.Ball, Size = Vector3.new(1.4, 1.4, 1.4), CFrame = CFrame.new(O + Vector3.new(x, 2.7, z)), Color = Color3.fromRGB(220, 40, 40) })
		end
	end
	local x, z = freeSpot(rng, 6, 80)
	if x then statue(O, x, z, Color3.fromRGB(255, 205, 60), math.atan2(x, z)) end
	local fx, fz = freeSpot(rng, 10, 80)
	if fx then fountain(O, fx, fz) end
end

THEME_DECO.beach = function(O, w, rng)
	local boardColors = { Color3.fromRGB(255, 90, 120), Color3.fromRGB(0, 200, 220), Color3.fromRGB(255, 220, 60), Color3.fromRGB(120, 220, 90) }
	for _ = 1, 12 do
		local x, z = freeSpot(rng, 2, 50)
		if x and z < 115 then
			ellipsoid({ Size = Vector3.new(2, 8, 0.4), CFrame = CFrame.new(O + Vector3.new(x, 3.5, z)) * CFrame.Angles(math.rad(-10), rng:NextNumber(0, 6), 0),
				Color = boardColors[rng:NextInteger(1, #boardColors)] })
		end
	end
	for _ = 1, 7 do
		local x, z = freeSpot(rng, 5, 50)
		if x and z < 115 then
			part({ Size = Vector3.new(6, 2, 6), CFrame = CFrame.new(O + Vector3.new(x, 1, z)), Color = Color3.fromRGB(225, 200, 140), Material = Enum.Material.Sand })
			for _, p in ipairs({ { -2.5, -2.5 }, { 2.5, -2.5 }, { -2.5, 2.5 }, { 2.5, 2.5 } }) do
				part({ Shape = Enum.PartType.Cylinder, Size = Vector3.new(3.5, 1.6, 1.6), CFrame = CFrame.new(O + Vector3.new(x + p[1], 2.5, z + p[2])) * CFrame.Angles(0, 0, math.rad(90)),
					Color = Color3.fromRGB(225, 200, 140), Material = Enum.Material.Sand })
			end
		end
	end
	for k = 1, 5 do
		local x = rng:NextNumber(-200, 200)
		local z = rng:NextNumber(150, 225)
		local base = CFrame.new(O + Vector3.new(x, 0.8, z)) * CFrame.Angles(0, rng:NextNumber(0, 6), 0)
		part({ Size = Vector3.new(5, 2, 12), CFrame = base, Color = Color3.fromRGB(250, 250, 250) })
		part({ Size = Vector3.new(0.5, 10, 0.5), CFrame = base * CFrame.new(0, 6, 0), Color = Color3.fromRGB(120, 80, 50), Material = Enum.Material.Wood })
		part({ Class = "WedgePart", Size = Vector3.new(0.2, 8, 5), CFrame = base * CFrame.new(0, 6, 2.6), Color = k % 2 == 0 and Color3.fromRGB(255, 90, 120) or Color3.fromRGB(255, 255, 255) })
	end
	-- Rettungsturm
	local tx, tz = 60, 100
	for _, p in ipairs({ { -3, -3 }, { 3, -3 }, { -3, 3 }, { 3, 3 } }) do
		part({ Size = Vector3.new(0.8, 10, 0.8), CFrame = CFrame.new(O + Vector3.new(tx + p[1], 5, tz + p[2])), Color = Color3.fromRGB(250, 250, 250) })
	end
	part({ Size = Vector3.new(8, 5, 8), CFrame = CFrame.new(O + Vector3.new(tx, 12.5, tz)), Color = Color3.fromRGB(230, 50, 50) })
	part({ Size = Vector3.new(9, 0.8, 9), CFrame = CFrame.new(O + Vector3.new(tx, 15.4, tz)), Color = Color3.fromRGB(250, 250, 250) })
	for _ = 1, 10 do
		local x, z = freeSpot(rng, 2, 45)
		if x and z < 115 then
			part({ Shape = Enum.PartType.Ball, Size = Vector3.new(2, 2, 2), CFrame = CFrame.new(O + Vector3.new(x, 1, z)), Color = boardColors[rng:NextInteger(1, #boardColors)] })
		end
	end
end

THEME_DECO.mountain = function(O, w, rng)
	airParticles(O, Color3.fromRGB(255, 255, 255), 0.5, 4, 60)
	for _ = 1, 7 do
		local x, z = freeSpot(rng, 5, 60, HALF - 60)
		if x then
			local base = CFrame.new(O + Vector3.new(x, 0, z)) * CFrame.Angles(0, rng:NextNumber(0, 6), 0)
			local col = ({ Color3.fromRGB(230, 90, 60), Color3.fromRGB(60, 130, 220), Color3.fromRGB(240, 200, 60) })[rng:NextInteger(1, 3)]
			part({ Class = "WedgePart", Size = Vector3.new(6, 4, 3), CFrame = base * CFrame.new(0, 2, -1.5), Color = col })
			part({ Class = "WedgePart", Size = Vector3.new(6, 4, 3), CFrame = base * CFrame.new(0, 2, 1.5) * CFrame.Angles(0, math.rad(180), 0), Color = col })
		end
	end
	for _ = 1, 5 do
		local x, z = freeSpot(rng, 3, 60)
		if x then
			for k = 0, 2 do
				part({ Shape = Enum.PartType.Cylinder, Size = Vector3.new(3, 0.6, 0.6), CFrame = CFrame.new(O + Vector3.new(x, 0.3, z)) * CFrame.Angles(0, math.rad(k * 60), 0), Color = Color3.fromRGB(110, 70, 40), Material = Enum.Material.Wood })
			end
			local fireBase = part({ Size = Vector3.new(1, 1, 1), CFrame = CFrame.new(O + Vector3.new(x, 0.8, z)), Transparency = 1, CanCollide = false })
			local f = Instance.new("Fire")
			f.Size = 4
			f.Parent = fireBase
		end
	end
	for _ = 1, 7 do
		local x, z = freeSpot(rng, 3, 50)
		if x then
			for k, r in ipairs({ 3.6, 2.7, 1.9 }) do
				part({ Shape = Enum.PartType.Ball, Size = Vector3.new(r, r, r), CFrame = CFrame.new(O + Vector3.new(x, ({ 1.6, 4.4, 6.6 })[k], z)), Color = Color3.fromRGB(250, 250, 255), Material = Enum.Material.Snow })
			end
			part({ Size = Vector3.new(0.3, 0.3, 1.2), CFrame = CFrame.new(O + Vector3.new(x, 6.6, z - 1.2)), Color = Color3.fromRGB(255, 140, 30) })
		end
	end
	for _ = 1, 2 do
		local x, z = freeSpot(rng, 10, 90)
		if x then
			building(O, x, z, 16, 12, 10, Color3.fromRGB(130, 85, 50), Enum.Material.WoodPlanks, nil, Color3.fromRGB(255, 220, 150))
			part({ Class = "WedgePart", Size = Vector3.new(17, 6, 7), CFrame = CFrame.new(O + Vector3.new(x, 14, z - 3)), Color = Color3.fromRGB(240, 245, 255), Material = Enum.Material.Snow })
			part({ Class = "WedgePart", Size = Vector3.new(17, 6, 7), CFrame = CFrame.new(O + Vector3.new(x, 14, z + 3)) * CFrame.Angles(0, math.rad(180), 0), Color = Color3.fromRGB(240, 245, 255), Material = Enum.Material.Snow })
		end
	end
end

THEME_DECO.temple = function(O, w, rng)
	airParticles(O, Color3.fromRGB(255, 180, 210), 0.5, 3, 40)
	for _ = 1, 18 do
		local x, z = freeSpot(rng, 2, 50)
		if x then
			part({ Size = Vector3.new(0.6, 6, 0.6), CFrame = CFrame.new(O + Vector3.new(x, 3, z)), Color = Color3.fromRGB(60, 40, 30), Material = Enum.Material.Wood })
			local lan = ellipsoid({ Size = Vector3.new(2, 2.6, 2), CFrame = CFrame.new(O + Vector3.new(x, 6.8, z)), Color = Color3.fromRGB(230, 50, 40), Material = Enum.Material.Neon })
			local l = Instance.new("PointLight")
			l.Color = Color3.fromRGB(255, 120, 80)
			l.Range = 12
			l.Parent = lan
		end
	end
	for _ = 1, 12 do
		local x, z = freeSpot(rng, 6, 60)
		if x then tree(O, x, z, Color3.fromRGB(255, 170, 205), 1.1) end
	end
	for _ = 1, 9 do
		local x, z = freeSpot(rng, 3, 60)
		if x then
			for k = 1, 5 do
				local h = rng:NextNumber(10, 18)
				part({ Size = Vector3.new(0.8, h, 0.8), CFrame = CFrame.new(O + Vector3.new(x + rng:NextNumber(-1.5, 1.5), h / 2, z + rng:NextNumber(-1.5, 1.5))),
					Color = Color3.fromRGB(110, 170, 60), Material = Enum.Material.Grass })
			end
		end
	end
	for _, pos in ipairs({ { 0, -110 }, { -150, 20 } }) do
		local base = CFrame.new(O + Vector3.new(pos[1], 0, pos[2]))
		for _, s in ipairs({ -7, 7 }) do part({ Size = Vector3.new(1.6, 16, 1.6), CFrame = base * CFrame.new(s, 8, 0), Color = Color3.fromRGB(210, 40, 30) }) end
		part({ Size = Vector3.new(20, 1.6, 2.2), CFrame = base * CFrame.new(0, 16.5, 0), Color = Color3.fromRGB(30, 25, 25) })
		part({ Size = Vector3.new(17, 1.2, 1.6), CFrame = base * CFrame.new(0, 13.5, 0), Color = Color3.fromRGB(210, 40, 30) })
	end
	local px, pz = freeSpot(rng, 14, 70)
	if px then
		part({ Shape = Enum.PartType.Cylinder, Size = Vector3.new(0.6, 24, 24), CFrame = CFrame.new(O + Vector3.new(px, 0.3, pz)) * CFrame.Angles(0, 0, math.rad(90)),
			Color = Color3.fromRGB(70, 150, 200), Material = Enum.Material.Glass, Transparency = 0.25, CanCollide = false })
		for _ = 1, 6 do
			ellipsoid({ Size = Vector3.new(0.8, 0.6, 1.8), CFrame = CFrame.new(O + Vector3.new(px + rng:NextNumber(-8, 8), 0.5, pz + rng:NextNumber(-8, 8))) * CFrame.Angles(0, rng:NextNumber(0, 6), 0),
				Color = rng:NextNumber() < 0.5 and Color3.fromRGB(255, 140, 50) or Color3.fromRGB(255, 255, 255), CanCollide = false })
		end
	end
end

THEME_DECO.fashion = function(O, w, rng)
	airParticles(O, Color3.fromRGB(255, 200, 240), 0.3, 2, 25)
	for _ = 1, 12 do
		local x, z = freeSpot(rng, 2, 45)
		if x then
			local base = CFrame.new(O + Vector3.new(x, 0, z)) * CFrame.Angles(0, rng:NextNumber(0, 6), 0)
			part({ Shape = Enum.PartType.Cylinder, Size = Vector3.new(0.3, 2.5, 2.5), CFrame = base * CFrame.new(0, 0.15, 0) * CFrame.Angles(0, 0, math.rad(90)), Color = Color3.fromRGB(30, 30, 30) })
			part({ Size = Vector3.new(0.3, 3, 0.3), CFrame = base * CFrame.new(0, 1.6, 0), Color = Color3.fromRGB(30, 30, 30) })
			part({ Size = Vector3.new(2.2, 2.8, 1.1), CFrame = base * CFrame.new(0, 4.4, 0), Color = FLOWER_COLORS[rng:NextInteger(1, #FLOWER_COLORS)] })
			part({ Shape = Enum.PartType.Ball, Size = Vector3.new(1.2, 1.2, 1.2), CFrame = base * CFrame.new(0, 6.4, 0), Color = Color3.fromRGB(245, 240, 235) })
		end
	end
	for _ = 1, 8 do
		local x, z = freeSpot(rng, 3, 50)
		if x then
			part({ Size = Vector3.new(6, 0.3, 0.3), CFrame = CFrame.new(O + Vector3.new(x, 5, z)), Color = Color3.fromRGB(200, 200, 210), Material = Enum.Material.Metal })
			for _, s in ipairs({ -2.8, 2.8 }) do part({ Size = Vector3.new(0.3, 5, 0.3), CFrame = CFrame.new(O + Vector3.new(x + s, 2.5, z)), Color = Color3.fromRGB(200, 200, 210), Material = Enum.Material.Metal }) end
			for k = -2, 2 do
				part({ Size = Vector3.new(0.4, 2.6, 1.6), CFrame = CFrame.new(O + Vector3.new(x + k * 1.1, 3.5, z)), Color = FLOWER_COLORS[rng:NextInteger(1, #FLOWER_COLORS)], Material = Enum.Material.Fabric })
			end
		end
	end
	for _ = 1, 2 do
		local x, z = freeSpot(rng, 10, 80)
		if x then fountain(O, x, z) end
	end
end

THEME_DECO.hollywood = function(O, w, rng)
	for _ = 1, 8 do
		local x, z = freeSpot(rng, 3, 50)
		if x then
			local base = CFrame.new(O + Vector3.new(x, 0, z)) * CFrame.Angles(0, rng:NextNumber(0, 6), 0)
			for k = 0, 2 do part({ Size = Vector3.new(0.3, 5, 0.3), CFrame = base * CFrame.Angles(0, math.rad(k * 120), 0) * CFrame.new(0, 2.3, 0.8) * CFrame.Angles(math.rad(15), 0, 0), Color = Color3.fromRGB(40, 40, 40) }) end
			part({ Size = Vector3.new(2, 1.8, 3), CFrame = base * CFrame.new(0, 5.4, 0), Color = Color3.fromRGB(30, 30, 30) })
			part({ Shape = Enum.PartType.Cylinder, Size = Vector3.new(1.2, 1.2, 1.2), CFrame = base * CFrame.new(0, 5.4, -1.9) * CFrame.Angles(0, math.rad(90), 0), Color = Color3.fromRGB(80, 80, 90) })
		end
	end
	for _ = 1, 6 do
		local x, z = freeSpot(rng, 2, 45)
		if x then
			local base = CFrame.new(O + Vector3.new(x, 0, z)) * CFrame.Angles(0, rng:NextNumber(0, 6), 0)
			part({ Size = Vector3.new(2.4, 0.3, 2), CFrame = base * CFrame.new(0, 2.2, 0), Color = Color3.fromRGB(30, 30, 30), Material = Enum.Material.Fabric })
			part({ Size = Vector3.new(2.4, 1.6, 0.2), CFrame = base * CFrame.new(0, 3.4, 0.9), Color = Color3.fromRGB(30, 30, 30), Material = Enum.Material.Fabric })
			for _, s in ipairs({ -1.1, 1.1 }) do part({ Size = Vector3.new(0.2, 2.2, 2), CFrame = base * CFrame.new(s, 1.1, 0), Color = Color3.fromRGB(150, 100, 60), Material = Enum.Material.Wood }) end
		end
	end
	for _ = 1, 4 do
		local x, z = freeSpot(rng, 6, 70)
		if x then statue(O, x, z, Color3.fromRGB(255, 205, 60), math.atan2(x, z)) end
	end
	for _ = 1, 3 do
		local x, z = freeSpot(rng, 10, 90)
		if x then
			part({ Size = Vector3.new(10, 7, 22), CFrame = CFrame.new(O + Vector3.new(x, 3.5, z)), Color = Color3.fromRGB(235, 235, 240), Material = Enum.Material.Metal })
			surfaceSign(part({ Size = Vector3.new(8, 2, 0.3), CFrame = CFrame.new(O + Vector3.new(x, 6, z - 11.2)), Color = Color3.fromRGB(20, 5, 35) }), Enum.NormalId.Front, "⭐ STAR", Color3.fromRGB(20, 5, 35), WHITE)
		end
	end
end

THEME_DECO.dubai = function(O, w, rng)
	for _ = 1, 9 do
		local x, z = freeSpot(rng, 6, 50)
		if x then car(O, x, z, rng:NextNumber(0, 6), rng:NextNumber() < 0.6 and Color3.fromRGB(212, 175, 55) or Color3.fromRGB(250, 250, 250), true) end
	end
	for _ = 1, 8 do
		local a = rng:NextNumber(0, math.pi * 2)
		local r = rng:NextNumber(HALF + 15, HALF + 45)
		ellipsoid({ Size = Vector3.new(rng:NextNumber(40, 70), rng:NextNumber(10, 18), rng:NextNumber(30, 50)), CFrame = CFrame.new(O + Vector3.new(math.cos(a) * r, 0, math.sin(a) * r)),
			Color = Color3.fromRGB(230, 200, 140), Material = Enum.Material.Sand })
	end
	for _ = 1, 5 do
		local x, z = freeSpot(rng, 4, 60)
		if x then
			local base = CFrame.new(O + Vector3.new(x, 0, z)) * CFrame.Angles(0, rng:NextNumber(0, 6), 0)
			local col = Color3.fromRGB(200, 160, 100)
			ellipsoid({ Size = Vector3.new(2.4, 2.4, 5), CFrame = base * CFrame.new(0, 4.5, 0), Color = col })
			ellipsoid({ Size = Vector3.new(2, 2, 2.4), CFrame = base * CFrame.new(0, 6, 0.2), Color = col })
			ellipsoid({ Size = Vector3.new(0.8, 3, 0.8), CFrame = base * CFrame.new(0, 6, -2.6) * CFrame.Angles(math.rad(-20), 0, 0), Color = col })
			ellipsoid({ Size = Vector3.new(1.2, 1.2, 1.8), CFrame = base * CFrame.new(0, 7.6, -3.2), Color = col })
			for _, p in ipairs({ { -0.8, -1.8 }, { 0.8, -1.8 }, { -0.8, 1.8 }, { 0.8, 1.8 } }) do
				part({ Size = Vector3.new(0.5, 3.8, 0.5), CFrame = base * CFrame.new(p[1], 1.9, p[2]), Color = col })
			end
		end
	end
	for _ = 1, 3 do
		local x, z = freeSpot(rng, 10, 80)
		if x then fountain(O, x, z) end
	end
	for _ = 1, 2 do
		local x, z = freeSpot(rng, 6, 80)
		if x then statue(O, x, z, Color3.fromRGB(212, 175, 55), math.atan2(x, z)) end
	end
end

THEME_DECO.galaxy = function(O, w, rng)
	airParticles(O, Color3.fromRGB(220, 200, 255), 0.4, 1.5, 50)
	-- Rakete
	local rx, rz = 150, 120
	part({ Shape = Enum.PartType.Cylinder, Size = Vector3.new(40, 10, 10), CFrame = CFrame.new(O + Vector3.new(rx, 22, rz)) * CFrame.Angles(0, 0, math.rad(90)), Color = Color3.fromRGB(240, 240, 245), Material = Enum.Material.Metal })
	ellipsoid({ Size = Vector3.new(10, 14, 10), CFrame = CFrame.new(O + Vector3.new(rx, 44, rz)), Color = Color3.fromRGB(230, 50, 60) })
	for k = 0, 3 do
		part({ Class = "WedgePart", Size = Vector3.new(1, 10, 6), CFrame = CFrame.new(O + Vector3.new(rx, 5, rz)) * CFrame.Angles(0, math.rad(k * 90), 0) * CFrame.new(0, 0, 7), Color = Color3.fromRGB(230, 50, 60) })
	end
	part({ Shape = Enum.PartType.Ball, Size = Vector3.new(3.5, 3.5, 3.5), CFrame = CFrame.new(O + Vector3.new(rx, 30, rz - 5)), Color = Color3.fromRGB(120, 200, 255), Material = Enum.Material.Neon })
	for _ = 1, 4 do
		local pos = O + Vector3.new(rng:NextNumber(-200, 200), rng:NextNumber(50, 90), rng:NextNumber(-200, 200))
		part({ Size = Vector3.new(3, 3, 4), CFrame = CFrame.new(pos), Color = Color3.fromRGB(200, 200, 210), Material = Enum.Material.Metal, CanCollide = false })
		for _, s in ipairs({ -1, 1 }) do
			part({ Size = Vector3.new(7, 0.2, 3), CFrame = CFrame.new(pos + Vector3.new(s * 5.5, 0, 0)), Color = Color3.fromRGB(40, 70, 160), Material = Enum.Material.Glass, CanCollide = false })
		end
	end
	for _ = 1, 16 do
		local s = rng:NextNumber(3, 9)
		part({ Shape = Enum.PartType.Ball, Size = Vector3.new(s, s * 0.8, s), CFrame = CFrame.new(O + Vector3.new(rng:NextNumber(-220, 220), rng:NextNumber(15, 60), rng:NextNumber(-220, 220))),
			Color = Color3.fromRGB(110, 95, 130), Material = Enum.Material.Slate, CanCollide = false })
	end
	for _ = 1, 12 do
		local x, z = freeSpot(rng, 3, 50)
		if x then
			local h = rng:NextNumber(4, 9)
			part({ Size = Vector3.new(0.5, h, 0.5), CFrame = CFrame.new(O + Vector3.new(x, h / 2, z)), Color = Color3.fromRGB(80, 200, 160) })
			part({ Shape = Enum.PartType.Ball, Size = Vector3.new(2.2, 2.2, 2.2), CFrame = CFrame.new(O + Vector3.new(x, h + 0.6, z)), Color = Color3.fromRGB(255, 100, 220), Material = Enum.Material.Neon })
		end
	end
end

-- Für ALLE Welten: Wolken, Bänke, Büsche, Blumen, Mülleimer, Werbetafeln
local function decorate(O, w, rng)
	if w.theme ~= "galaxy" then
		for _ = 1, 10 do cloud(O, rng) end
	end
	local natural = (w.theme == "mountain" or w.theme == "temple" or w.theme == "beach")
	for _ = 1, 12 do
		local x, z = freeSpot(rng, 4, 45)
		if x then bench(O, x, z, rng:NextNumber(0, 6)) end
	end
	if w.theme ~= "galaxy" then
		for _ = 1, 20 do
			local x, z = freeSpot(rng, 3, 45)
			if x then bush(O, x, z, natural and Color3.fromRGB(70, 140, 60) or Color3.fromRGB(60, 160, 80), rng:NextNumber(3, 5)) end
		end
		for _ = 1, 10 do
			local x, z = freeSpot(rng, 4, 45)
			if x then flowerbed(O, x, z, rng) end
		end
	end
	if not natural then
		for _ = 1, 8 do
			local x, z = freeSpot(rng, 2, 40)
			if x then trashcan(O, x, z) end
		end
	end
	for k = 1, 4 do
		local x, z = freeSpot(rng, 12, 90)
		if x then bigSign(O, x, z, SLOGANS[((math.floor(w.mult * 7) + k) % #SLOGANS) + 1], math.atan2(x, z) + math.pi, w.accent) end
	end
	local extra = THEME_DECO[w.theme]
	if extra then extra(O, w, rng) end
end


local GROUND_MATERIAL = {
	city = Enum.Material.Concrete, beach = Enum.Material.Sand, mountain = Enum.Material.Grass, temple = Enum.Material.Grass,
	fashion = Enum.Material.Pavement, hollywood = Enum.Material.Sandstone, dubai = Enum.Material.Sand, galaxy = Enum.Material.Slate,
}
-- Welten mit echtem Gelände (Terrain) als Boden
local TERRAIN_GROUND = { beach = Enum.Material.Sand, mountain = Enum.Material.Snow, temple = Enum.Material.Grass, dubai = Enum.Material.Sand }

----------------------------------------------------------------------------
-- NPCs (Rivalen & Bosse)
----------------------------------------------------------------------------
local npcFolder = nil

local function makeNPC(def, position, isBoss)
	local scale = def.scale or 1
	local model = nil
	local ok = pcall(function()
		local desc = Instance.new("HumanoidDescription")
		desc.HeadColor = def.skin
		desc.LeftArmColor = def.skin
		desc.RightArmColor = def.skin
		desc.TorsoColor = def.shirt
		desc.LeftLegColor = def.pants
		desc.RightLegColor = def.pants
		desc.HeightScale = scale
		desc.WidthScale = scale * (isBoss and 1.15 or 1)
		desc.DepthScale = scale
		desc.HeadScale = scale
		model = Players:CreateHumanoidModelFromDescription(desc, Enum.HumanoidRigType.R15)
	end)
	if not ok or not model then
		-- Notlösung: einfache Figur aus Blöcken
		model = Instance.new("Model")
		local body = Instance.new("Part")
		body.Name = "HumanoidRootPart"
		body.Size = Vector3.new(2, 5, 1) * scale
		body.Color = def.shirt
		body.Anchored = true
		body.Parent = model
		local head = Instance.new("Part")
		head.Name = "Head"
		head.Size = Vector3.new(1.6, 1.6, 1.6) * scale
		head.Color = def.skin
		head.Anchored = true
		head.CFrame = body.CFrame * CFrame.new(0, 3.3 * scale, 0)
		head.Parent = model
		model.PrimaryPart = body
	end
	model.Name = def.name
	local hrp = model:FindFirstChild("HumanoidRootPart")
	local hum = model:FindFirstChildOfClass("Humanoid")
	if hum then
		hum.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None
	end
	model:PivotTo(CFrame.new(position + Vector3.new(0, 3 * scale, 0)) * CFrame.Angles(0, math.rad(180), 0))
	if hrp then hrp.Anchored = true end
	model.Parent = npcFolder

	local head = model:FindFirstChild("Head") or hrp
	local title
	if def.final then
		title = "<font color='#ffd166'>💀 LEON · ENDBOSS</font>"
	elseif isBoss then
		title = "<font color='#ff5d73'>👑 BOSS</font>"
	else
		title = "<font color='#ffb36b'>⚔️ RIVALE</font>"
	end
	billboard(head, title .. "\n" .. def.name .. "\n<font size='14' color='#ffd166'>Stufe " .. def.level .. " · ♻️ " .. def.rebirths .. "</font>",
		8, 3.2, 3 * scale, WHITE)

	if isBoss and hrp then
		local sparkle = Instance.new("ParticleEmitter")
		sparkle.Rate = def.final and 40 or 15
		sparkle.LightEmission = 1
		sparkle.Lifetime = NumberRange.new(1, 2)
		sparkle.Speed = NumberRange.new(2, 4)
		sparkle.SpreadAngle = Vector2.new(180, 180)
		sparkle.Color = ColorSequence.new(def.final and Color3.fromRGB(255, 209, 102) or Color3.fromRGB(255, 93, 115))
		sparkle.Parent = hrp
	end

	local pr = prompt(hrp or head, isBoss and "Boss herausfordern" or "Mog Battle", def.name, isBoss and 1 or 0.4)
	return pr
end

----------------------------------------------------------------------------
-- Eine Welt bauen
----------------------------------------------------------------------------
----------------------------------------------------------------------------
-- 🎉 EVENT-PLATZ (Glow City)
----------------------------------------------------------------------------
local function eventPlaza(O)
	local P = O + Vector3.new(-150, 0, 120)
	local ev = Logic.activeEvent(os.time())
	local color = ev and ev.color or Color3.fromRGB(120, 110, 140)
	part({ Shape = Enum.PartType.Cylinder, Size = Vector3.new(0.6, 78, 78), CFrame = CFrame.new(P + Vector3.new(0, 0.3, 0)) * CFrame.Angles(0, 0, math.rad(90)),
		Color = color, Material = Enum.Material.SmoothPlastic, Transparency = 0.15 })
	for _, s in ipairs({ -14, 14 }) do
		part({ Size = Vector3.new(3, 22, 3), CFrame = CFrame.new(P + Vector3.new(s, 11, 36)), Color = color, Material = Enum.Material.Neon })
	end
	local arch = part({ Size = Vector3.new(34, 6, 2), CFrame = CFrame.new(P + Vector3.new(0, 24, 36)), Color = Color3.fromRGB(20, 5, 35) })
	if not ev then
		local lines = {}
		for _, e in ipairs(Config.Events) do
			table.insert(lines, e.emoji .. " " .. e.name .. " ab " .. string.format("%02d.%02d.", e.from[2], e.from[1]))
		end
		surfaceSign(arch, Enum.NormalId.Back, "🎉 EVENT-PLATZ", Color3.fromRGB(20, 5, 35), WHITE)
		local info = part({ Size = Vector3.new(26, 12, 0.6), CFrame = CFrame.new(P + Vector3.new(0, 8, 0)), Color = Color3.fromRGB(20, 5, 35) })
		surfaceSign(info, Enum.NormalId.Back, "<b>Nächste Events</b>\n" .. table.concat(lines, "\n"), Color3.fromRGB(20, 5, 35), WHITE)
		return
	end
	surfaceSign(arch, Enum.NormalId.Back, ev.emoji .. " " .. string.upper(ev.name) .. " " .. ev.emoji, Color3.fromRGB(20, 5, 35), WHITE)
	-- passende Deko
	local rng = Random.new(42)
	for k = 1, 8 do
		local a = k / 8 * math.pi * 2
		local p = P + Vector3.new(math.cos(a) * 33, 0, math.sin(a) * 33)
		if ev.id == "winter" then
			for t = 0, 3 do
				local r = 9 - t * 2
				part({ Shape = Enum.PartType.Ball, Size = Vector3.new(r, r * 0.8, r), CFrame = CFrame.new(p + Vector3.new(0, 3 + t * 3.2, 0)), Color = Color3.fromRGB(30, 110, 50), Material = Enum.Material.Grass })
			end
			part({ Shape = Enum.PartType.Ball, Size = Vector3.new(1.6, 1.6, 1.6), CFrame = CFrame.new(p + Vector3.new(0, 14.5, 0)), Color = Color3.fromRGB(255, 220, 80), Material = Enum.Material.Neon })
			for g = 1, 3 do
				part({ Size = Vector3.new(2, 2, 2), CFrame = CFrame.new(p + Vector3.new(rng:NextNumber(-4, 4), 1, rng:NextNumber(-4, 4))),
					Color = ({ Color3.fromRGB(230, 40, 40), Color3.fromRGB(40, 120, 230), Color3.fromRGB(240, 200, 40) })[g] })
			end
		elseif ev.id == "halloween" then
			part({ Shape = Enum.PartType.Ball, Size = Vector3.new(4.5, 3.6, 4.5), CFrame = CFrame.new(p + Vector3.new(0, 1.8, 0)), Color = Color3.fromRGB(255, 130, 20) })
			part({ Size = Vector3.new(0.5, 1, 0.5), CFrame = CFrame.new(p + Vector3.new(0, 4, 0)), Color = Color3.fromRGB(60, 120, 40) })
			local glow = part({ Size = Vector3.new(0.5, 0.5, 0.5), CFrame = CFrame.new(p + Vector3.new(0, 2, 0)), Transparency = 1, CanCollide = false })
			local l = Instance.new("PointLight")
			l.Color = Color3.fromRGB(255, 140, 30)
			l.Range = 12
			l.Parent = glow
			part({ Size = Vector3.new(3, 4, 0.8), CFrame = CFrame.new(p + Vector3.new(4, 2, 2)), Color = Color3.fromRGB(120, 120, 125), Material = Enum.Material.Slate })
		else
			palm(O, p.X - O.X, p.Z - O.Z, rng)
		end
	end
	-- Event-Box
	local egg = Config.Eggs[ev.eggIndex]
	local ep = P + Vector3.new(16, 0, -8)
	part({ Shape = Enum.PartType.Cylinder, Size = Vector3.new(2, 13, 13), CFrame = CFrame.new(ep + Vector3.new(0, 1, 0)) * CFrame.Angles(0, 0, math.rad(90)), Color = Color3.fromRGB(40, 20, 60) })
	local box = part({ Name = "Geschenkbox", Size = Vector3.new(7, 7, 7), CFrame = CFrame.new(ep + Vector3.new(0, 6, 0)) * CFrame.Angles(0, math.rad(20), 0), Color = ev.color, Material = Enum.Material.Glass, Reflectance = 0.2 })
	part({ Size = Vector3.new(7.2, 7.2, 0.9), CFrame = box.CFrame, Color = Color3.new(1, 1, 1), Material = Enum.Material.Neon })
	part({ Size = Vector3.new(0.9, 7.2, 7.2), CFrame = box.CFrame, Color = Color3.new(1, 1, 1), Material = Enum.Material.Neon })
	billboard(box, ev.emoji .. " " .. egg.name .. "\n<font color='#ffd166'>" .. egg.cost .. " " .. ev.token .. "</font>\n<font size='14'>5 exklusive Event-Pets!</font>", 12, 4.6, 7, WHITE)
	table.insert(MapBuilder.eggPrompts, { prompt = prompt(box, "Öffnen", egg.name, 0.25), egg = egg, count = 1 })
	table.insert(MapBuilder.eggPrompts, { prompt = prompt(box, "3x öffnen", egg.name, 0.25, Enum.KeyCode.F), egg = egg, count = 3 })
	table.insert(MapBuilder.eggPrompts, { prompt = prompt(box, "Inhalt ansehen", egg.name, 0, Enum.KeyCode.R), egg = egg, info = true })
	-- Event-Boss
	local def = {}
	for k, v in pairs(ev.boss) do def[k] = v end
	def.event = ev.id
	part({ Shape = Enum.PartType.Cylinder, Size = Vector3.new(4, 24, 24), CFrame = CFrame.new(P + Vector3.new(-16, 2, -10)) * CFrame.Angles(0, 0, math.rad(90)), Color = ev.color, Material = Enum.Material.Neon, Transparency = 0.3 })
	table.insert(MapBuilder.npcs, { prompt = makeNPC(def, P + Vector3.new(-16, 4, -10), true), def = def, world = 1, isBoss = true })
end

----------------------------------------------------------------------------
-- 🧗 DACH-PARKOUR (Glow City)
----------------------------------------------------------------------------
local function obbyCourse(O)
	local base = O + Vector3.new(-150, 0, -110)
	local pad = part({ Size = Vector3.new(10, 1, 10), CFrame = CFrame.new(base + Vector3.new(0, 0.5, 34)), Color = Color3.fromRGB(255, 120, 40), Material = Enum.Material.Neon })
	billboard(pad, "🧗 DACH-PARKOUR\n<font size='15'>Spring bis zum goldenen Pokal!</font>", 14, 4, 6, WHITE)
	local startPrompt = prompt(pad, "Parkour starten", "Dach-Parkour", 0)
	local checkpoints, first, last = {}, nil, nil
	local n = 26
	for i = 1, n do
		local a = i * 0.36
		local pos = base + Vector3.new(math.cos(a) * 30, 6 + i * 3, math.sin(a) * 30)
		local isCp = (i % 7 == 0)
		local p = part({ Size = isCp and Vector3.new(7, 1, 7) or Vector3.new(5, 1, 5), CFrame = CFrame.new(pos),
			Color = isCp and Color3.fromRGB(80, 230, 120) or Color3.fromHSV(i / n * 0.8, 0.55, 1), Material = isCp and Enum.Material.Neon or Enum.Material.SmoothPlastic })
		if i == 1 then first = p end
		if isCp then
			table.insert(checkpoints, p)
			billboard(p, "🚩 " .. #checkpoints, 3, 2, 3, WHITE)
		end
		last = pos
	end
	local finishPos = base + Vector3.new(math.cos((n + 1) * 0.36) * 30, 6 + (n + 1) * 3, math.sin((n + 1) * 0.36) * 30)
	local finish = part({ Size = Vector3.new(10, 1, 10), CFrame = CFrame.new(finishPos), Color = Color3.fromRGB(255, 205, 60), Material = Enum.Material.Neon })
	part({ Shape = Enum.PartType.Cylinder, Size = Vector3.new(3, 1.4, 1.4), CFrame = CFrame.new(finishPos + Vector3.new(0, 2, 0)) * CFrame.Angles(0, 0, math.rad(90)),
		Color = Color3.fromRGB(255, 205, 60), Material = Enum.Material.Foil })
	part({ Shape = Enum.PartType.Ball, Size = Vector3.new(3, 3, 3), CFrame = CFrame.new(finishPos + Vector3.new(0, 4.4, 0)), Color = Color3.fromRGB(255, 205, 60), Material = Enum.Material.Foil })
	billboard(finish, "🏆 ZIEL", 6, 2.4, 7, Color3.fromRGB(255, 209, 102))
	MapBuilder.minigames.obby = { start = startPrompt, first = first, checkpoints = checkpoints, finish = finish }
end

----------------------------------------------------------------------------
-- 🏁 LAUFSTEG-RENNEN (Mailand)
----------------------------------------------------------------------------
local function raceTrack(O)
	local x, z0, z1 = -170, 210, 30
	local len = z0 - z1
	part({ Size = Vector3.new(16, 0.4, len), CFrame = CFrame.new(O + Vector3.new(x, 0.2, (z0 + z1) / 2)), Color = Color3.fromRGB(245, 245, 245), Material = Enum.Material.Marble })
	for _, s in ipairs({ -8.5, 8.5 }) do
		part({ Size = Vector3.new(1, 2.5, len), CFrame = CFrame.new(O + Vector3.new(x + s, 1.25, (z0 + z1) / 2)), Color = Color3.fromRGB(255, 120, 200), Material = Enum.Material.Neon, Transparency = 0.2 })
	end
	for z = z0 - 30, z1 + 20, -28 do
		part({ Size = Vector3.new(15, 1.6, 1), CFrame = CFrame.new(O + Vector3.new(x, 0.8, z)), Color = Color3.fromRGB(30, 30, 35) })
	end
	local start = part({ Size = Vector3.new(15, 8, 1), CFrame = CFrame.new(O + Vector3.new(x, 4, z0 - 3)), Color = Color3.fromRGB(80, 230, 120), Material = Enum.Material.Neon, Transparency = 0.6, CanCollide = false })
	billboard(start, "🏁 LAUFSTEG-RENNEN\n<font size='15'>Lauf durchs grüne Tor – so schnell du kannst!</font>", 16, 4, 7, WHITE)
	local finish = part({ Size = Vector3.new(15, 8, 1), CFrame = CFrame.new(O + Vector3.new(x, 4, z1 + 2)), Color = Color3.fromRGB(255, 255, 255), Material = Enum.Material.Neon, Transparency = 0.6, CanCollide = false })
	for k = 0, 7 do
		part({ Size = Vector3.new(1.9, 0.3, 2), CFrame = CFrame.new(O + Vector3.new(x - 7 + k * 2, 0.45, z1 + 2)), Color = (k % 2 == 0) and Color3.new(0, 0, 0) or Color3.new(1, 1, 1) })
	end
	billboard(finish, "🏁 ZIEL", 6, 2.4, 6, WHITE)
	MapBuilder.minigames.race = { start = start, finish = finish }
end

----------------------------------------------------------------------------
-- 💪 GYM-STATION
----------------------------------------------------------------------------
local function gymStation(O)
	local P = O + Vector3.new(40, 0, 62)
	part({ Size = Vector3.new(4, 1.6, 9), CFrame = CFrame.new(P + Vector3.new(0, 1.6, 0)), Color = Color3.fromRGB(30, 30, 35), Material = Enum.Material.Fabric })
	for _, s in ipairs({ -3, 3 }) do
		part({ Size = Vector3.new(0.4, 5, 0.4), CFrame = CFrame.new(P + Vector3.new(s, 2.5, -3)), Color = Color3.fromRGB(80, 80, 90), Material = Enum.Material.Metal })
	end
	local bar = part({ Shape = Enum.PartType.Cylinder, Size = Vector3.new(9, 0.4, 0.4), CFrame = CFrame.new(P + Vector3.new(0, 5, -3)), Color = Color3.fromRGB(190, 190, 200), Material = Enum.Material.Metal })
	for _, s in ipairs({ -4, 4 }) do
		part({ Shape = Enum.PartType.Cylinder, Size = Vector3.new(0.6, 2.6, 2.6), CFrame = CFrame.new(P + Vector3.new(s, 5, -3)), Color = Color3.fromRGB(20, 20, 20) })
	end
	billboard(bar, "💪 GYM-TRAINING\n<font size='15'>+50 % Aura (Gym-Pump)</font>", 12, 3.6, 4, WHITE)
	table.insert(MapBuilder.minigames.gyms, prompt(bar, "Trainieren", "Gym-Station", 0.3))
end

----------------------------------------------------------------------------
-- 🧗 PARKOUR-STRECKEN (eine pro Welt ab Welt 2) – wie in beliebten Obby-Spielen
----------------------------------------------------------------------------
local GRAVITY = 196.2

-- Punkte entlang einer Linie mit Schlängeln; jumps[i] = Extra-Höhe nach Punkt i (dort liegt ein Sprungfeld)
local function linePoints(from, to, n, wiggle, freq, y0, yStep, jumps)
	local pts = {}
	local dir = (to - from)
	local perp = Vector3.new(-dir.Z, 0, dir.X).Unit
	local extra = 0
	for i = 1, n do
		local t = i / n
		local base = from + dir * t + perp * (math.sin(i * freq) * wiggle)
		pts[i] = Vector3.new(base.X, y0 + i * yStep + extra, base.Z)
		if jumps and jumps[i] then extra = extra + jumps[i] end
	end
	return pts
end

-- Punkte als Spirale um einen Mittelpunkt (Berg, Turm)
local function spiralPoints(center, radius, n, step, y0, yStep, jumps)
	local pts = {}
	local extra = 0
	for i = 1, n do
		local a = i * step
		pts[i] = center + Vector3.new(math.cos(a) * radius, y0 + i * yStep + extra, math.sin(a) * radius)
		if jumps and jumps[i] then extra = extra + jumps[i] end
	end
	return pts
end

local function trophy(pos)
	part({ Shape = Enum.PartType.Cylinder, Size = Vector3.new(3, 1.4, 1.4), CFrame = CFrame.new(pos + Vector3.new(0, 2, 0)) * CFrame.Angles(0, 0, math.rad(90)),
		Color = Color3.fromRGB(255, 205, 60), Material = Enum.Material.Foil })
	part({ Shape = Enum.PartType.Ball, Size = Vector3.new(3, 3, 3), CFrame = CFrame.new(pos + Vector3.new(0, 4.4, 0)), Color = Color3.fromRGB(255, 205, 60), Material = Enum.Material.Foil })
end

--[[ def:
	id, title, emoji, hint, start (Vector3, relativ), points {Vector3 = Mitte der Oberkante},
	size (Plattform), color(i), material, cpEvery, jumps {[i] = Extra-Höhe}, build(pos, i, size) = eigene Plattform,
	finish (Vector3), finishBuild(pos) optional, reward, killParts {Part}
]]
local function course(O, def)
	local startPad = part({ Size = Vector3.new(10, 1, 10), CFrame = CFrame.new(O + def.start + Vector3.new(0, 0.5, 0)), Color = Color3.fromRGB(255, 120, 40), Material = Enum.Material.Neon })
	billboard(startPad, def.emoji .. " " .. def.title .. "\n<font size='15'>" .. def.hint .. "</font>", 18, 4.5, 6, WHITE)
	local startPrompt = prompt(startPad, "Parkour starten", def.title, 0)
	local checkpoints, first = {}, nil
	local pts = def.points
	for i, p in ipairs(pts) do
		local P = O + p
		local isCp = def.cpEvery and (i % def.cpEvery == 0)
		local isPad = def.jumps and def.jumps[i]
		local plat
		if isCp or isPad then
			plat = part({ Size = Vector3.new(8, 1, 8), CFrame = CFrame.new(P - Vector3.new(0, 0.5, 0)),
				Color = isPad and Color3.fromRGB(255, 79, 216) or Color3.fromRGB(80, 230, 120), Material = Enum.Material.Neon })
			if def.build then def.build(P - Vector3.new(0, 1, 0), i, Vector3.new(8, 1, 8), true) end
		elseif def.build then
			plat = def.build(P, i, def.size or Vector3.new(5, 1, 5), false)
		else
			plat = part({ Size = def.size or Vector3.new(5, 1, 5), CFrame = CFrame.new(P - Vector3.new(0, 0.5, 0)), Color = def.color and def.color(i) or Color3.fromHSV(i / #pts, 0.5, 1),
				Material = def.material or Enum.Material.SmoothPlastic })
		end
		if i == 1 then first = plat end
		if isCp then
			table.insert(checkpoints, plat)
			billboard(plat, "🚩 " .. #checkpoints, 3, 2, 3, WHITE)
		end
		if isPad and pts[i + 1] then
			-- Sprungfeld: schleudert dich zur nächsten (höheren) Plattform
			local nextP = pts[i + 1]
			local dy = nextP.Y - p.Y
			local vy = math.sqrt(2 * GRAVITY * (dy + 7))
			local flight = (vy + math.sqrt(math.max(0, vy * vy - 2 * GRAVITY * dy))) / GRAVITY
			local flat = Vector3.new(nextP.X - p.X, 0, nextP.Z - p.Z)
			CollectionService:AddTag(plat, "JumpPad")
			plat:SetAttribute("Power", vy)
			plat:SetAttribute("Dir", flat / flight)
			billboard(plat, "⬆️ SPRUNGFELD", 6, 1.6, 2.5, Color3.fromRGB(255, 209, 102))
		end
	end
	local fp = O + def.finish
	local finish = part({ Size = Vector3.new(12, 1, 12), CFrame = CFrame.new(fp - Vector3.new(0, 0.5, 0)), Color = Color3.fromRGB(255, 205, 60), Material = Enum.Material.Neon })
	if def.finishBuild then def.finishBuild(fp) end
	trophy(fp)
	billboard(finish, "🏆 ZIEL", 6, 2.4, 8, Color3.fromRGB(255, 209, 102))
	table.insert(MapBuilder.minigames.courses, {
		id = def.id, title = def.title, start = startPrompt, startCf = startPad.CFrame, first = first,
		checkpoints = checkpoints, finish = finish, kills = def.killParts or {}, reward = def.reward,
		points = pts, jumps = def.jumps, finishPos = def.finish, size = def.size, firstTop = O + pts[1],
	})
end

-- freie Sprungfelder (Trampoline) zum Spaß
local function trampoline(O, x, z, power, color)
	part({ Shape = Enum.PartType.Cylinder, Size = Vector3.new(1.4, 9, 9), CFrame = CFrame.new(O + Vector3.new(x, 0.7, z)) * CFrame.Angles(0, 0, math.rad(90)), Color = Color3.fromRGB(40, 40, 50), Material = Enum.Material.Metal })
	local pad = part({ Shape = Enum.PartType.Cylinder, Size = Vector3.new(0.4, 7.6, 7.6), CFrame = CFrame.new(O + Vector3.new(x, 1.5, z)) * CFrame.Angles(0, 0, math.rad(90)),
		Color = color or Color3.fromRGB(62, 242, 255), Material = Enum.Material.Neon })
	CollectionService:AddTag(pad, "JumpPad")
	pad:SetAttribute("Power", power or 95)
	billboard(pad, "🦘 Trampolin", 6, 1.6, 2.5, WHITE)
end

local function courseReward(index)
	return { cash = 300 + index * 150, scale = true, gems = 3 + index }
end

----------------------------------------------------------------------------
-- 🏖️ MIAMI BEACH: Bojen-Parkour, Steg mit Leuchtturm, Beachvolleyball, Strandhütten
----------------------------------------------------------------------------
local function beachExtras(O, w, rng, index)
	-- Bojen über dem Meer bis zur Schatzinsel
	local water = part({ Name = "KillZone", Size = Vector3.new(150, 2, 130), CFrame = CFrame.new(O + Vector3.new(130, -2.6, 186)), Transparency = 1, CanCollide = false })
	course(O, {
		id = "beach", title = "Bojen-Parkour", emoji = "🌊", hint = "Spring über die Bojen zur Schatzinsel – nicht ins Wasser fallen!",
		start = Vector3.new(85, 0, 110),
		points = linePoints(Vector3.new(85, 0, 116), Vector3.new(170, 0, 226), 18, 7, 0.9, 1.4, 0.12),
		cpEvery = 6,
		build = function(P, i, size, under)
			if under then return end
			local col = (i % 2 == 0) and Color3.fromRGB(230, 50, 50) or Color3.fromRGB(250, 250, 250)
			local b = part({ Shape = Enum.PartType.Cylinder, Size = Vector3.new(4, 5.2, 5.2), CFrame = CFrame.new(P - Vector3.new(0, 2, 0)) * CFrame.Angles(0, 0, math.rad(90)), Color = col })
			part({ Shape = Enum.PartType.Cylinder, Size = Vector3.new(0.6, 5.4, 5.4), CFrame = CFrame.new(P - Vector3.new(0, 1.2, 0)) * CFrame.Angles(0, 0, math.rad(90)), Color = Color3.fromRGB(255, 200, 40) })
			return b
		end,
		finish = Vector3.new(176, 2.5, 236),
		finishBuild = function(fp)
			part({ Shape = Enum.PartType.Cylinder, Size = Vector3.new(4, 24, 24), CFrame = CFrame.new(fp - Vector3.new(0, 3, 0)) * CFrame.Angles(0, 0, math.rad(90)), Color = Color3.fromRGB(230, 205, 150), Material = Enum.Material.Sand })
			palm(O, fp.X - O.X - 8, fp.Z - O.Z - 2, rng)
			-- Schatzkiste
			part({ Size = Vector3.new(4, 2.4, 3), CFrame = CFrame.new(fp + Vector3.new(4, 1.2, 3)), Color = Color3.fromRGB(120, 75, 40), Material = Enum.Material.WoodPlanks })
			part({ Size = Vector3.new(4.2, 0.8, 3.2), CFrame = CFrame.new(fp + Vector3.new(4, 2.6, 3)), Color = Color3.fromRGB(255, 205, 60), Material = Enum.Material.Foil })
		end,
		reward = courseReward(index), killParts = { water },
	})
	-- Holzsteg ins Meer mit Leuchtturm
	for z = 112, 222, 6 do
		part({ Size = Vector3.new(10, 0.6, 6.2), CFrame = CFrame.new(O + Vector3.new(-110, 1.6, z)), Color = Color3.fromRGB(150, 105, 65), Material = Enum.Material.WoodPlanks })
		for _, s in ipairs({ -4.6, 4.6 }) do
			part({ Size = Vector3.new(0.8, 6, 0.8), CFrame = CFrame.new(O + Vector3.new(-110 + s, -1, z)), Color = Color3.fromRGB(110, 75, 45), Material = Enum.Material.Wood })
		end
	end
	local lh = O + Vector3.new(-110, 0, 232)
	part({ Shape = Enum.PartType.Cylinder, Size = Vector3.new(2, 16, 16), CFrame = CFrame.new(lh + Vector3.new(0, 1, 0)) * CFrame.Angles(0, 0, math.rad(90)), Color = Color3.fromRGB(140, 135, 130), Material = Enum.Material.Slate })
	for k = 0, 5 do
		part({ Shape = Enum.PartType.Cylinder, Size = Vector3.new(6, 9 - k * 0.6, 9 - k * 0.6), CFrame = CFrame.new(lh + Vector3.new(0, 5 + k * 6, 0)) * CFrame.Angles(0, 0, math.rad(90)),
			Color = (k % 2 == 0) and Color3.fromRGB(235, 50, 50) or Color3.fromRGB(250, 250, 250) })
	end
	local lamp = part({ Shape = Enum.PartType.Ball, Size = Vector3.new(5, 5, 5), CFrame = CFrame.new(lh + Vector3.new(0, 40, 0)), Color = Color3.fromRGB(255, 240, 160), Material = Enum.Material.Neon })
	local beam = Instance.new("SpotLight")
	beam.Range = 60
	beam.Angle = 40
	beam.Brightness = 3
	beam.Parent = lamp
	-- Beachvolleyball
	local B = Vector3.new(150, 0, -150)
	part({ Size = Vector3.new(30, 0.3, 16), CFrame = CFrame.new(O + B + Vector3.new(0, 0.15, 0)), Color = Color3.fromRGB(240, 220, 170), Material = Enum.Material.Sand })
	for _, s in ipairs({ -8.5, 8.5 }) do part({ Size = Vector3.new(0.5, 8, 0.5), CFrame = CFrame.new(O + B + Vector3.new(0, 4, s)), Color = WHITE }) end
	part({ Size = Vector3.new(0.2, 3, 17), CFrame = CFrame.new(O + B + Vector3.new(0, 6.3, 0)), Color = Color3.fromRGB(30, 30, 30), Transparency = 0.4 })
	part({ Shape = Enum.PartType.Ball, Size = Vector3.new(1.6, 1.6, 1.6), CFrame = CFrame.new(O + B + Vector3.new(-6, 0.8, 3)), Color = Color3.fromRGB(255, 220, 60) })
	-- Strandhütten
	local hutColors = { Color3.fromRGB(255, 120, 160), Color3.fromRGB(90, 200, 255), Color3.fromRGB(255, 210, 80), Color3.fromRGB(120, 230, 150) }
	for k = 0, 3 do
		local H = O + Vector3.new(222, 0, -125 + k * 14)
		part({ Size = Vector3.new(9, 8, 10), CFrame = CFrame.new(H + Vector3.new(0, 4, 0)), Color = hutColors[k + 1], Material = Enum.Material.WoodPlanks })
		part({ Class = "WedgePart", Size = Vector3.new(10, 3, 5.5), CFrame = CFrame.new(H + Vector3.new(0, 9.5, -2.75)), Color = WHITE })
		part({ Class = "WedgePart", Size = Vector3.new(10, 3, 5.5), CFrame = CFrame.new(H + Vector3.new(0, 9.5, 2.75)) * CFrame.Angles(0, math.rad(180), 0), Color = WHITE })
		part({ Size = Vector3.new(0.3, 5, 3), CFrame = CFrame.new(H + Vector3.new(-4.6, 2.5, 0)), Color = Color3.fromRGB(60, 40, 30) })
	end
	-- Sandburg
	local C = O + Vector3.new(-140, 0, -195)
	part({ Size = Vector3.new(14, 3, 14), CFrame = CFrame.new(C + Vector3.new(0, 1.5, 0)), Color = Color3.fromRGB(220, 190, 130), Material = Enum.Material.Sand })
	for _, p in ipairs({ { -6, -6 }, { 6, -6 }, { -6, 6 }, { 6, 6 } }) do
		part({ Shape = Enum.PartType.Cylinder, Size = Vector3.new(8, 3.4, 3.4), CFrame = CFrame.new(C + Vector3.new(p[1], 5, p[2])) * CFrame.Angles(0, 0, math.rad(90)), Color = Color3.fromRGB(220, 190, 130), Material = Enum.Material.Sand })
		part({ Class = "WedgePart", Size = Vector3.new(3, 2.5, 3), CFrame = CFrame.new(C + Vector3.new(p[1], 10.2, p[2])), Color = Color3.fromRGB(210, 175, 115), Material = Enum.Material.Sand })
	end
	part({ Size = Vector3.new(7, 6, 7), CFrame = CFrame.new(C + Vector3.new(0, 6, 0)), Color = Color3.fromRGB(225, 195, 135), Material = Enum.Material.Sand })
	part({ Size = Vector3.new(0.2, 2, 3), CFrame = CFrame.new(C + Vector3.new(0.3, 11, 1.4)), Color = Color3.fromRGB(255, 79, 216) })
	part({ Size = Vector3.new(0.3, 4, 0.3), CFrame = CFrame.new(C + Vector3.new(0, 11, 0)), Color = Color3.fromRGB(110, 75, 45) })
	-- Eisstand
	local E = O + Vector3.new(-120, 0, 40)
	part({ Size = Vector3.new(10, 4, 5), CFrame = CFrame.new(E + Vector3.new(0, 2, 0)), Color = Color3.fromRGB(250, 250, 250) })
	for k = -2, 2 do
		part({ Size = Vector3.new(2, 0.3, 6), CFrame = CFrame.new(E + Vector3.new(k * 2, 8, 0)), Color = (k % 2 == 0) and Color3.fromRGB(255, 120, 170) or WHITE })
	end
	for _, s in ipairs({ -4.5, 4.5 }) do part({ Size = Vector3.new(0.4, 4, 0.4), CFrame = CFrame.new(E + Vector3.new(s, 6, 0)), Color = WHITE }) end
	local cone = part({ Class = "WedgePart", Size = Vector3.new(1.6, 4, 1.6), CFrame = CFrame.new(E + Vector3.new(0, 11, 0)) * CFrame.Angles(math.rad(180), 0, 0), Color = Color3.fromRGB(220, 170, 100) })
	part({ Shape = Enum.PartType.Ball, Size = Vector3.new(2.6, 2.6, 2.6), CFrame = cone.CFrame * CFrame.new(0, -2.6, 0), Color = Color3.fromRGB(255, 160, 200) })
	-- Trampoline am Strand
	trampoline(O, -60, 95, 100)
	trampoline(O, -40, 75, 100, Color3.fromRGB(255, 79, 216))
end

----------------------------------------------------------------------------
-- 🏔️ IRON MOUNTAIN: Gipfel-Kletterei, gefrorener See (rutschig!), Skilift, Iglu
----------------------------------------------------------------------------
local function mountainExtras(O, w, rng, index)
	local C = Vector3.new(140, 0, 140)
	part({ Shape = Enum.PartType.Cylinder, Size = Vector3.new(80, 34, 34), CFrame = CFrame.new(O + C + Vector3.new(0, 40, 0)) * CFrame.Angles(0, 0, math.rad(90)),
		Color = Color3.fromRGB(120, 118, 125), Material = Enum.Material.Slate })
	part({ Shape = Enum.PartType.Cylinder, Size = Vector3.new(3, 35, 35), CFrame = CFrame.new(O + C + Vector3.new(0, 79, 0)) * CFrame.Angles(0, 0, math.rad(90)),
		Color = Color3.fromRGB(245, 248, 255), Material = Enum.Material.Snow })
	course(O, {
		id = "mountain", title = "Gipfel-Kletterei", emoji = "🧗", hint = "Kletter die Felsvorsprünge hoch bis zur Gipfelfahne!",
		start = Vector3.new(140, 0, 108),
		points = spiralPoints(C, 20, 25, 0.42, 0, 3.15),
		cpEvery = 6,
		size = Vector3.new(6, 1, 6), material = Enum.Material.Slate,
		color = function(i) return (i % 2 == 0) and Color3.fromRGB(150, 145, 150) or Color3.fromRGB(235, 240, 250) end,
		finish = C + Vector3.new(math.cos(25 * 0.42) * 8, 81.5, math.sin(25 * 0.42) * 8),
		finishBuild = function(fp)
			part({ Size = Vector3.new(0.6, 14, 0.6), CFrame = CFrame.new(fp + Vector3.new(4, 7, 4)), Color = Color3.fromRGB(80, 80, 85), Material = Enum.Material.Metal })
			part({ Size = Vector3.new(0.2, 4, 6), CFrame = CFrame.new(fp + Vector3.new(4, 12, 7)), Color = Color3.fromRGB(255, 79, 216) })
		end,
		reward = courseReward(index),
	})
	-- Gefrorener See: Eis ist rutschig!
	local A = O + Vector3.new(-90, 0, 190)
	part({ Shape = Enum.PartType.Cylinder, Size = Vector3.new(0.6, 72, 72), CFrame = CFrame.new(A + Vector3.new(0, 0.3, 0)) * CFrame.Angles(0, 0, math.rad(90)),
		Color = Color3.fromRGB(170, 215, 245), Material = Enum.Material.Ice, Transparency = 0.1 })
	local sign = part({ Size = Vector3.new(14, 4, 0.6), CFrame = CFrame.new(A + Vector3.new(0, 7, -40)), Color = Color3.fromRGB(20, 5, 35) })
	surfaceSign(sign, Enum.NormalId.Front, "⛸️ EISBAHN – rutschig!", Color3.fromRGB(20, 5, 35), WHITE)
	surfaceSign(sign, Enum.NormalId.Back, "⛸️ EISBAHN – rutschig!", Color3.fromRGB(20, 5, 35), WHITE)
	for _, s in ipairs({ -6, 6 }) do part({ Size = Vector3.new(0.5, 7, 0.5), CFrame = CFrame.new(A + Vector3.new(s, 3.5, -40)), Color = Color3.fromRGB(110, 75, 45) }) end
	-- Skilift
	for k = 0, 4 do
		local P = O + Vector3.new(110 + k * 28, 0, -205)
		part({ Size = Vector3.new(1.2, 26 + k * 4, 1.2), CFrame = CFrame.new(P + Vector3.new(0, (26 + k * 4) / 2, 0)), Color = Color3.fromRGB(70, 70, 80), Material = Enum.Material.Metal })
		part({ Size = Vector3.new(1, 1, 8), CFrame = CFrame.new(P + Vector3.new(0, 26 + k * 4, 0)), Color = Color3.fromRGB(70, 70, 80), Material = Enum.Material.Metal })
		if k < 4 then
			local a, b = P + Vector3.new(0, 26 + k * 4, 0), P + Vector3.new(28, 30 + k * 4, 0)
			local mid = (a + b) / 2
			part({ Size = Vector3.new(0.3, 0.3, (b - a).Magnitude), CFrame = CFrame.lookAt(mid, b), Color = Color3.fromRGB(30, 30, 30), CanCollide = false })
			part({ Size = Vector3.new(4, 0.6, 2), CFrame = CFrame.new(mid + Vector3.new(0, -4, 0)), Color = Color3.fromRGB(230, 60, 60), CanCollide = false })
			part({ Size = Vector3.new(0.2, 4, 0.2), CFrame = CFrame.new(mid + Vector3.new(0, -2, 0)), Color = Color3.fromRGB(30, 30, 30), CanCollide = false })
		end
	end
	-- Iglu
	local I = O + Vector3.new(-140, 0, -195)
	ellipsoid({ Size = Vector3.new(18, 14, 18), CFrame = CFrame.new(I), Color = Color3.fromRGB(240, 248, 255), Material = Enum.Material.Snow })
	ellipsoid({ Size = Vector3.new(6, 7, 8), CFrame = CFrame.new(I + Vector3.new(0, 0, -8)), Color = Color3.fromRGB(235, 243, 252), Material = Enum.Material.Snow })
	part({ Size = Vector3.new(3.4, 4.5, 0.4), CFrame = CFrame.new(I + Vector3.new(0, 1.6, -11.9)), Color = Color3.fromRGB(30, 40, 60) })
	-- Eisskulpturen
	for k = 0, 3 do
		local h = 6 + k * 3
		part({ Class = "WedgePart", Size = Vector3.new(3, h, 3), CFrame = CFrame.new(O + Vector3.new(200 + (k % 2) * 8, h / 2, -90 + k * 7)) * CFrame.Angles(0, math.rad(k * 50), 0),
			Color = Color3.fromRGB(160, 220, 255), Material = Enum.Material.Ice, Transparency = 0.25 })
	end
	-- dichter Nadelwald am Rand
	for _ = 1, 40 do
		local x, z = freeSpot(rng, 5, 150)
		if x then
			part({ Size = Vector3.new(1.6, 6, 1.6), CFrame = CFrame.new(O + Vector3.new(x, 3, z)), Color = Color3.fromRGB(110, 70, 40), Material = Enum.Material.Wood })
			for t = 0, 2 do
				local s = 9 - t * 2.5
				part({ Class = "WedgePart", Size = Vector3.new(s, 4.5, s / 2), CFrame = CFrame.new(O + Vector3.new(x, 7 + t * 3.2, z - s / 4)), Color = Color3.fromRGB(30, 95, 55), Material = Enum.Material.Grass })
				part({ Class = "WedgePart", Size = Vector3.new(s, 4.5, s / 2), CFrame = CFrame.new(O + Vector3.new(x, 7 + t * 3.2, z + s / 4)) * CFrame.Angles(0, math.rad(180), 0), Color = Color3.fromRGB(30, 95, 55), Material = Enum.Material.Grass })
				part({ Size = Vector3.new(s * 0.7, 0.4, s * 0.7), CFrame = CFrame.new(O + Vector3.new(x, 9.3 + t * 3.2, z)), Color = WHITE, Material = Enum.Material.Snow })
			end
		end
	end
	trampoline(O, -120, 40, 110)
end

----------------------------------------------------------------------------
-- 🗿 MEWING-TEMPEL: Lava-Tempel-Parkour, Pagode, Koi-Teich mit Brücke, Zen-Garten
----------------------------------------------------------------------------
local function templeExtras(O, w, rng, index)
	local lava = part({ Name = "Lava", Size = Vector3.new(92, 1, 92), CFrame = CFrame.new(O + Vector3.new(150, 0.4, 150)), Color = Color3.fromRGB(255, 90, 20), Material = Enum.Material.Neon })
	local glow = Instance.new("PointLight")
	glow.Color = Color3.fromRGB(255, 120, 40)
	glow.Range = 40
	glow.Brightness = 2
	glow.Parent = lava
	local smoke = Instance.new("ParticleEmitter")
	smoke.Color = ColorSequence.new(Color3.fromRGB(255, 160, 60))
	smoke.Rate = 18
	smoke.Lifetime = NumberRange.new(1.5, 2.5)
	smoke.Speed = NumberRange.new(2, 5)
	smoke.Size = NumberSequence.new(0.6)
	smoke.LightEmission = 1
	smoke.EmissionDirection = Enum.NormalId.Top
	smoke.Parent = lava
	for _, r in ipairs({ { 0, -47, 96, 2 }, { 0, 47, 96, 2 }, { -47, 0, 2, 96 }, { 47, 0, 2, 96 } }) do
		part({ Size = Vector3.new(r[3], 2, r[4]), CFrame = CFrame.new(O + Vector3.new(150 + r[1], 1, 150 + r[2])), Color = Color3.fromRGB(90, 85, 80), Material = Enum.Material.Slate })
	end
	-- Stufenpyramide mit Gong als Ziel
	local fin = Vector3.new(200, 20, 200)
	for k = 0, 3 do
		local s = 24 - k * 4.5
		part({ Size = Vector3.new(s, 5, s), CFrame = CFrame.new(O + Vector3.new(200, 2.5 + k * 5, 200)), Color = Color3.fromRGB(190 - k * 10, 170 - k * 10, 130 - k * 8), Material = Enum.Material.Sandstone })
	end
	course(O, {
		id = "temple", title = "Lava-Tempel", emoji = "🔥", hint = "Spring über die Steinsäulen – die Lava schickt dich zurück!",
		start = Vector3.new(98, 0, 98),
		points = linePoints(Vector3.new(108, 0, 108), Vector3.new(190, 0, 190), 24, 6, 0.9, 2.2, 0.68),
		cpEvery = 6,
		build = function(P, i, size, under)
			local top = P.Y
			local col = Color3.fromRGB(150 - (i % 3) * 12, 140 - (i % 3) * 12, 125)
			local p = part({ Size = Vector3.new(size.X, top, size.Z), CFrame = CFrame.new(Vector3.new(P.X, top / 2, P.Z)), Color = col, Material = Enum.Material.Slate })
			if not under then
				part({ Size = Vector3.new(size.X + 0.6, 0.6, size.Z + 0.6), CFrame = CFrame.new(P - Vector3.new(0, 0.3, 0)), Color = Color3.fromRGB(200, 180, 120), Material = Enum.Material.Sandstone })
			end
			return p
		end,
		finish = fin,
		finishBuild = function(fp)
			part({ Size = Vector3.new(0.8, 9, 0.8), CFrame = CFrame.new(fp + Vector3.new(-3.5, 4.5, 4)), Color = Color3.fromRGB(150, 40, 30), Material = Enum.Material.Wood })
			part({ Size = Vector3.new(0.8, 9, 0.8), CFrame = CFrame.new(fp + Vector3.new(3.5, 4.5, 4)), Color = Color3.fromRGB(150, 40, 30), Material = Enum.Material.Wood })
			part({ Size = Vector3.new(8, 0.8, 0.8), CFrame = CFrame.new(fp + Vector3.new(0, 9, 4)), Color = Color3.fromRGB(150, 40, 30), Material = Enum.Material.Wood })
			part({ Shape = Enum.PartType.Cylinder, Size = Vector3.new(0.5, 5.5, 5.5), CFrame = CFrame.new(fp + Vector3.new(0, 5.5, 4)) * CFrame.Angles(0, math.rad(90), 0), Color = Color3.fromRGB(212, 175, 55), Material = Enum.Material.Foil })
		end,
		reward = courseReward(index), killParts = { lava },
	})
	-- Pagode
	local A = O + Vector3.new(-90, 0, 190)
	for k = 0, 4 do
		local s = 16 - k * 2.4
		part({ Size = Vector3.new(s, 6, s), CFrame = CFrame.new(A + Vector3.new(0, 3 + k * 7, 0)), Color = Color3.fromRGB(200, 50, 40), Material = Enum.Material.WoodPlanks })
		part({ Size = Vector3.new(s + 6, 1, s + 6), CFrame = CFrame.new(A + Vector3.new(0, 6.5 + k * 7, 0)), Color = Color3.fromRGB(40, 35, 35), Material = Enum.Material.Slate })
	end
	part({ Size = Vector3.new(0.8, 8, 0.8), CFrame = CFrame.new(A + Vector3.new(0, 42, 0)), Color = Color3.fromRGB(212, 175, 55), Material = Enum.Material.Foil })
	-- Koi-Teich mit roter Bogenbrücke
	local B = O + Vector3.new(150, 0, -150)
	part({ Shape = Enum.PartType.Cylinder, Size = Vector3.new(0.6, 34, 34), CFrame = CFrame.new(B + Vector3.new(0, 0.3, 0)) * CFrame.Angles(0, 0, math.rad(90)),
		Color = Color3.fromRGB(60, 140, 180), Material = Enum.Material.Glass, Transparency = 0.2 })
	for k = -6, 6 do
		local y = 4 - (k * k) / 9
		part({ Size = Vector3.new(6, 0.6, 3), CFrame = CFrame.new(B + Vector3.new(0, y, k * 2.6)) * CFrame.Angles(math.rad(-k * 6), 0, 0), Color = Color3.fromRGB(210, 40, 30), Material = Enum.Material.WoodPlanks })
	end
	for _ = 1, 8 do
		ellipsoid({ Size = Vector3.new(0.9, 0.6, 2), CFrame = CFrame.new(B + Vector3.new(rng:NextNumber(-12, 12), 0.7, rng:NextNumber(-12, 12))) * CFrame.Angles(0, rng:NextNumber(0, 6), 0),
			Color = rng:NextNumber() < 0.5 and Color3.fromRGB(255, 140, 50) or WHITE, CanCollide = false })
	end
	-- Zen-Garten mit geharktem Sand und Steinen
	local Z = O + Vector3.new(-140, 0, -195)
	part({ Size = Vector3.new(30, 0.4, 22), CFrame = CFrame.new(Z + Vector3.new(0, 0.2, 0)), Color = Color3.fromRGB(235, 225, 200), Material = Enum.Material.Sand })
	for k = -4, 4 do part({ Size = Vector3.new(29, 0.1, 0.3), CFrame = CFrame.new(Z + Vector3.new(0, 0.45, k * 2.3)), Color = Color3.fromRGB(210, 200, 175) }) end
	for _, r in ipairs({ { -8, -3, 4 }, { 5, 4, 3 }, { 9, -5, 2.5 } }) do rock(O, Z.X - O.X + r[1], Z.Z - O.Z + r[2], r[3], Color3.fromRGB(90, 90, 95)) end
	-- Riesen-Moai mit Sonnenbrille
	local M = O + Vector3.new(205, 0, -85)
	local cf = CFrame.new(M) * CFrame.Angles(0, math.rad(-90), 0)
	part({ Size = Vector3.new(14, 26, 11), CFrame = cf * CFrame.new(0, 13, 0), Color = Color3.fromRGB(115, 110, 104), Material = Enum.Material.Slate })
	part({ Size = Vector3.new(14.4, 3.5, 12), CFrame = cf * CFrame.new(0, 24.5, -0.5), Color = Color3.fromRGB(100, 95, 90), Material = Enum.Material.Slate })
	part({ Size = Vector3.new(12, 2.4, 0.6), CFrame = cf * CFrame.new(0, 18, -5.8), Color = Color3.fromRGB(15, 15, 20), Reflectance = 0.4 })
	part({ Class = "WedgePart", Size = Vector3.new(3, 6, 3), CFrame = cf * CFrame.new(0, 13, -7) * CFrame.Angles(0, math.rad(180), 0), Color = Color3.fromRGB(110, 105, 100), Material = Enum.Material.Slate })
	-- Gong-Turm
	local G = O + Vector3.new(-120, 0, 40)
	for _, s in ipairs({ -4, 4 }) do part({ Size = Vector3.new(1, 12, 1), CFrame = CFrame.new(G + Vector3.new(s, 6, 0)), Color = Color3.fromRGB(150, 40, 30), Material = Enum.Material.Wood }) end
	part({ Size = Vector3.new(11, 1, 1.6), CFrame = CFrame.new(G + Vector3.new(0, 12, 0)), Color = Color3.fromRGB(40, 35, 35) })
	part({ Shape = Enum.PartType.Cylinder, Size = Vector3.new(0.5, 6, 6), CFrame = CFrame.new(G + Vector3.new(0, 7.5, 0)) * CFrame.Angles(0, math.rad(90), 0), Color = Color3.fromRGB(212, 175, 55), Material = Enum.Material.Foil })
end

----------------------------------------------------------------------------
-- 👔 MAILAND: Dachterrassen-Parkour, Modenschau-Bühne, Riesen-Parfüm, Riesen-High-Heel, Glas-Café
----------------------------------------------------------------------------
local BAG_COLORS = { Color3.fromRGB(255, 120, 200), Color3.fromRGB(250, 250, 250), Color3.fromRGB(30, 30, 35), Color3.fromRGB(212, 175, 55), Color3.fromRGB(150, 110, 255) }

local function fashionExtras(O, w, rng, index)
	course(O, {
		id = "fashion", title = "Shopping-Parkour", emoji = "🛍️", hint = "Spring über die Riesen-Einkaufstüten bis zur VIP-Lounge!",
		start = Vector3.new(95, 0, 95),
		points = linePoints(Vector3.new(102, 0, 102), Vector3.new(170, 0, 170), 22, 4.5, 1.2, 1.8, 1.65, { [11] = 14 }),
		jumps = { [11] = 14 },
		cpEvery = 7,
		build = function(P, i, size, under)
			if under then return end
			local col = BAG_COLORS[(i % #BAG_COLORS) + 1]
			local p = part({ Size = Vector3.new(5, 6, 4), CFrame = CFrame.new(P - Vector3.new(0, 3, 0)), Color = col, Material = Enum.Material.SmoothPlastic })
			part({ Size = Vector3.new(0.3, 1.6, 2.4), CFrame = CFrame.new(P + Vector3.new(0, 0.6, 0)) * CFrame.Angles(0, math.rad(90), 0), Color = col:Lerp(Color3.new(0, 0, 0), 0.4), CanCollide = false })
			return p
		end,
		finish = Vector3.new(178, 54, 178),
		finishBuild = function(fp)
			for _, s in ipairs({ -4, 4 }) do
				part({ Size = Vector3.new(6, 1.5, 2.5), CFrame = CFrame.new(fp + Vector3.new(s, 0.75, 5)), Color = Color3.fromRGB(255, 120, 200), Material = Enum.Material.Fabric })
			end
			part({ Size = Vector3.new(14, 0.4, 14), CFrame = CFrame.new(fp - Vector3.new(0, 1.2, 0)), Color = w.accent, Material = Enum.Material.Neon })
		end,
		reward = courseReward(index),
	})
	-- Modenschau-Bühne mit LED-Wand und Scheinwerfern
	local A = O + Vector3.new(-90, 0, 190)
	part({ Size = Vector3.new(36, 3, 16), CFrame = CFrame.new(A + Vector3.new(0, 1.5, 0)), Color = Color3.fromRGB(25, 25, 30), Material = Enum.Material.SmoothPlastic })
	local screen = part({ Size = Vector3.new(32, 16, 1), CFrame = CFrame.new(A + Vector3.new(0, 11, 7.5)), Color = Color3.fromRGB(20, 5, 35) })
	surfaceSign(screen, Enum.NormalId.Front, "✨ GLOW FASHION WEEK ✨", Color3.fromRGB(255, 79, 216), WHITE)
	for k = -2, 2 do
		local spot = part({ Shape = Enum.PartType.Ball, Size = Vector3.new(2, 2, 2), CFrame = CFrame.new(A + Vector3.new(k * 7, 20, 2)), Color = WHITE, Material = Enum.Material.Neon })
		local l = Instance.new("SpotLight")
		l.Face = Enum.NormalId.Bottom
		l.Range = 30
		l.Brightness = 4
		l.Color = BAG_COLORS[(k % #BAG_COLORS) + 1]
		l.Parent = spot
	end
	part({ Size = Vector3.new(36, 1, 1), CFrame = CFrame.new(A + Vector3.new(0, 21, 2)), Color = Color3.fromRGB(40, 40, 45), Material = Enum.Material.Metal })
	-- Riesen-Parfümflasche
	local B = O + Vector3.new(150, 0, -150)
	part({ Size = Vector3.new(12, 16, 7), CFrame = CFrame.new(B + Vector3.new(0, 8, 0)), Color = Color3.fromRGB(255, 170, 220), Material = Enum.Material.Glass, Transparency = 0.25 })
	part({ Size = Vector3.new(4, 3, 4), CFrame = CFrame.new(B + Vector3.new(0, 17.5, 0)), Color = Color3.fromRGB(212, 175, 55), Material = Enum.Material.Foil })
	part({ Shape = Enum.PartType.Ball, Size = Vector3.new(5, 5, 5), CFrame = CFrame.new(B + Vector3.new(0, 21, 0)), Color = Color3.fromRGB(255, 120, 200), Material = Enum.Material.Glass })
	local lbl = part({ Size = Vector3.new(8, 4, 0.2), CFrame = CFrame.new(B + Vector3.new(0, 8, -3.6)), Color = WHITE })
	surfaceSign(lbl, Enum.NormalId.Front, "N°1 GLOW", WHITE, Color3.fromRGB(30, 30, 30))
	-- Riesen-High-Heel
	local C = O + Vector3.new(-140, 0, -195)
	local red = Color3.fromRGB(220, 20, 50)
	part({ Size = Vector3.new(5, 1.6, 16), CFrame = CFrame.new(C + Vector3.new(0, 0.8, 0)), Color = red, Material = Enum.Material.SmoothPlastic, Reflectance = 0.2 })
	part({ Size = Vector3.new(5, 1.4, 10), CFrame = CFrame.new(C + Vector3.new(0, 6, 3)) * CFrame.Angles(math.rad(-35), 0, 0), Color = red, Reflectance = 0.2 })
	part({ Size = Vector3.new(1.4, 11, 1.4), CFrame = CFrame.new(C + Vector3.new(0, 5.5, 7.4)), Color = Color3.fromRGB(30, 30, 30) })
	part({ Size = Vector3.new(5.4, 3, 3), CFrame = CFrame.new(C + Vector3.new(0, 2, -6)), Color = red, Reflectance = 0.2 })
	-- Glas-Café
	local D = O + Vector3.new(205, 0, -85)
	part({ Size = Vector3.new(22, 0.6, 18), CFrame = CFrame.new(D + Vector3.new(0, 0.3, 0)), Color = Color3.fromRGB(240, 240, 240), Material = Enum.Material.Marble })
	part({ Size = Vector3.new(22, 10, 0.4), CFrame = CFrame.new(D + Vector3.new(0, 5.5, 9)), Color = Color3.fromRGB(180, 220, 240), Material = Enum.Material.Glass, Transparency = 0.5 })
	part({ Size = Vector3.new(0.4, 10, 18), CFrame = CFrame.new(D + Vector3.new(11, 5.5, 0)), Color = Color3.fromRGB(180, 220, 240), Material = Enum.Material.Glass, Transparency = 0.5 })
	part({ Size = Vector3.new(23, 0.6, 19), CFrame = CFrame.new(D + Vector3.new(0, 10.8, 0)), Color = Color3.fromRGB(30, 30, 35) })
	for _, p in ipairs({ { -5, -3 }, { 3, -3 }, { -5, 4 }, { 3, 4 } }) do
		part({ Shape = Enum.PartType.Cylinder, Size = Vector3.new(0.3, 3, 3), CFrame = CFrame.new(D + Vector3.new(p[1], 3, p[2])) * CFrame.Angles(0, 0, math.rad(90)), Color = WHITE })
		part({ Size = Vector3.new(0.3, 3, 0.3), CFrame = CFrame.new(D + Vector3.new(p[1], 1.5, p[2])), Color = Color3.fromRGB(30, 30, 30) })
	end
	surfaceSign(part({ Size = Vector3.new(12, 2.5, 0.3), CFrame = CFrame.new(D + Vector3.new(0, 12.5, -9)), Color = Color3.fromRGB(20, 5, 35) }), Enum.NormalId.Front, "☕ CAFÉ MILANO", Color3.fromRGB(20, 5, 35), WHITE)
	-- Blumenbögen-Allee
	for k = 0, 3 do
		local P = O + Vector3.new(-120, 0, 20 + k * 12)
		for t = 0, 8 do
			local a = math.rad(t * 22.5)
			part({ Shape = Enum.PartType.Ball, Size = Vector3.new(2, 2, 2), CFrame = CFrame.new(P + Vector3.new(math.cos(a) * 6, math.sin(a) * 8 + 0.5, 0)),
				Color = FLOWER_COLORS[((t + k) % #FLOWER_COLORS) + 1], Material = Enum.Material.Fabric })
		end
	end
	trampoline(O, 30, 120, 110, w.accent)
end

----------------------------------------------------------------------------
-- 🎬 HOLLYWOOD: Stunt-Parkour, Western-Filmset, Riesen-Filmklappe, Kamerakran, Foodtrucks, Suchscheinwerfer
----------------------------------------------------------------------------
local function hollywoodExtras(O, w, rng, index)
	course(O, {
		id = "hollywood", title = "Stunt-Parkour", emoji = "🎬", hint = "Kisten, Gerüste, Sprungfelder – ein echter Filmstunt bis zum Hubschrauber!",
		start = Vector3.new(95, 0, 95),
		points = linePoints(Vector3.new(102, 0, 102), Vector3.new(178, 0, 178), 24, 5, 1.0, 1.6, 1.1, { [8] = 12, [16] = 12 }),
		jumps = { [8] = 12, [16] = 12 },
		cpEvery = 6,
		build = function(P, i, size, under)
			local top = P.Y
			if top < 14 then
				local p = part({ Size = Vector3.new(size.X + 1, top, size.Z + 1), CFrame = CFrame.new(Vector3.new(P.X, top / 2, P.Z)), Color = Color3.fromRGB(160, 115, 70), Material = Enum.Material.WoodPlanks })
				return under and nil or p
			end
			for _, o in ipairs({ { -2.5, -2.5 }, { 2.5, -2.5 }, { -2.5, 2.5 }, { 2.5, 2.5 } }) do
				part({ Size = Vector3.new(0.4, top, 0.4), CFrame = CFrame.new(Vector3.new(P.X + o[1], top / 2, P.Z + o[2])), Color = Color3.fromRGB(170, 170, 180), Material = Enum.Material.Metal })
			end
			if under then return nil end
			return part({ Size = Vector3.new(6, 1, 6), CFrame = CFrame.new(P - Vector3.new(0, 0.5, 0)), Color = Color3.fromRGB(200, 160, 90), Material = Enum.Material.WoodPlanks })
		end,
		finish = Vector3.new(186, 53, 186),
		finishBuild = function(fp)
			part({ Size = Vector3.new(16, 0.4, 16), CFrame = CFrame.new(fp - Vector3.new(0, 1.2, 0)), Color = Color3.fromRGB(50, 50, 55) })
			for _, o in ipairs({ { -6, -6 }, { 6, -6 }, { -6, 6 }, { 6, 6 } }) do
				part({ Size = Vector3.new(0.8, fp.Y - 1.4, 0.8), CFrame = CFrame.new(Vector3.new(fp.X + o[1], (fp.Y - 1.4) / 2, fp.Z + o[2])), Color = Color3.fromRGB(170, 170, 180), Material = Enum.Material.Metal })
			end
			-- Hubschrauber
			local H = fp + Vector3.new(0, 0, -3)
			ellipsoid({ Size = Vector3.new(5, 4, 8), CFrame = CFrame.new(H + Vector3.new(-3, 2.4, 0)), Color = Color3.fromRGB(30, 30, 35), CanCollide = false })
			part({ Size = Vector3.new(1, 1, 7), CFrame = CFrame.new(H + Vector3.new(-3, 2.8, 7)), Color = Color3.fromRGB(30, 30, 35), CanCollide = false })
			part({ Size = Vector3.new(14, 0.2, 0.8), CFrame = CFrame.new(H + Vector3.new(-3, 4.8, 0)) * CFrame.Angles(0, math.rad(30), 0), Color = Color3.fromRGB(60, 60, 65), CanCollide = false })
		end,
		reward = courseReward(index),
	})
	-- Western-Filmset
	local A = O + Vector3.new(-90, 0, 190)
	local names = { "SALOON", "SHERIFF", "BANK" }
	for k = -1, 1 do
		local P = A + Vector3.new(k * 16, 0, 0)
		part({ Size = Vector3.new(15, 14, 1), CFrame = CFrame.new(P + Vector3.new(0, 7, 0)), Color = Color3.fromRGB(150 + k * 15, 100, 60), Material = Enum.Material.WoodPlanks })
		part({ Size = Vector3.new(15, 0.6, 5), CFrame = CFrame.new(P + Vector3.new(0, 8, -2.5)), Color = Color3.fromRGB(110, 75, 45), Material = Enum.Material.WoodPlanks })
		for _, s in ipairs({ -7, 7 }) do part({ Size = Vector3.new(0.5, 8, 0.5), CFrame = CFrame.new(P + Vector3.new(s, 4, -4.8)), Color = Color3.fromRGB(110, 75, 45) }) end
		part({ Size = Vector3.new(4, 6, 0.3), CFrame = CFrame.new(P + Vector3.new(0, 3, -0.6)), Color = Color3.fromRGB(70, 45, 30) })
		surfaceSign(part({ Size = Vector3.new(10, 2.5, 0.3), CFrame = CFrame.new(P + Vector3.new(0, 11.5, -0.7)), Color = Color3.fromRGB(240, 220, 180) }), Enum.NormalId.Front, names[k + 2], Color3.fromRGB(240, 220, 180), Color3.fromRGB(60, 30, 20))
		-- Stützen hinten (es ist nur Kulisse!)
		part({ Size = Vector3.new(0.4, 14, 0.4), CFrame = CFrame.new(P + Vector3.new(0, 6, 4)) * CFrame.Angles(math.rad(-30), 0, 0), Color = Color3.fromRGB(110, 75, 45) })
	end
	-- Riesen-Filmklappe
	local B = O + Vector3.new(150, 0, -150)
	part({ Size = Vector3.new(16, 12, 1.5), CFrame = CFrame.new(B + Vector3.new(0, 6, 0)), Color = Color3.fromRGB(25, 25, 25) })
	surfaceSign(part({ Size = Vector3.new(14, 8, 0.2), CFrame = CFrame.new(B + Vector3.new(0, 5.5, -0.85)), Color = Color3.fromRGB(25, 25, 25) }), Enum.NormalId.Front, "GLOW-UP\nSZENE 1 · TAKE 3000", Color3.fromRGB(25, 25, 25), WHITE)
	for k = 0, 7 do
		part({ Size = Vector3.new(2, 2.2, 1.5), CFrame = CFrame.new(B + Vector3.new(-7 + k * 2, 13.8, 0)) * CFrame.Angles(0, 0, math.rad(8)), Color = (k % 2 == 0) and WHITE or Color3.fromRGB(25, 25, 25) })
	end
	-- Kamerakran
	local C = O + Vector3.new(-140, 0, -195)
	part({ Size = Vector3.new(6, 1.5, 6), CFrame = CFrame.new(C + Vector3.new(0, 0.75, 0)), Color = Color3.fromRGB(40, 40, 45), Material = Enum.Material.Metal })
	part({ Size = Vector3.new(1.4, 10, 1.4), CFrame = CFrame.new(C + Vector3.new(0, 6, 0)), Color = Color3.fromRGB(60, 60, 65), Material = Enum.Material.Metal })
	part({ Size = Vector3.new(1, 1, 22), CFrame = CFrame.new(C + Vector3.new(0, 13, -6)) * CFrame.Angles(math.rad(-15), 0, 0), Color = Color3.fromRGB(60, 60, 65), Material = Enum.Material.Metal })
	part({ Size = Vector3.new(3, 2.4, 4), CFrame = CFrame.new(C + Vector3.new(0, 16.5, -16.5)), Color = Color3.fromRGB(25, 25, 25) })
	part({ Shape = Enum.PartType.Cylinder, Size = Vector3.new(1.6, 1.8, 1.8), CFrame = CFrame.new(C + Vector3.new(0, 16.5, -19)) * CFrame.Angles(0, math.rad(90), 0), Color = Color3.fromRGB(80, 80, 90) })
	-- Foodtrucks
	local truckColors = { Color3.fromRGB(255, 200, 40), Color3.fromRGB(80, 190, 255) }
	local truckNames = { "🌮 TACOS", "🥤 PROTEIN-SHAKES" }
	for k = 1, 2 do
		local P = O + Vector3.new(205, 0, -100 + k * 18)
		part({ Size = Vector3.new(8, 7, 14), CFrame = CFrame.new(P + Vector3.new(0, 4.5, 0)), Color = truckColors[k] })
		for _, o in ipairs({ { -4, -4 }, { 4, -4 }, { -4, 4 }, { 4, 4 } }) do
			part({ Shape = Enum.PartType.Cylinder, Size = Vector3.new(1, 2.2, 2.2), CFrame = CFrame.new(P + Vector3.new(o[1], 1.1, o[2])), Color = Color3.fromRGB(25, 25, 25) })
		end
		surfaceSign(part({ Size = Vector3.new(0.3, 2.5, 10), CFrame = CFrame.new(P + Vector3.new(-4.2, 7, 0)), Color = Color3.fromRGB(20, 5, 35) }), Enum.NormalId.Left, truckNames[k], Color3.fromRGB(20, 5, 35), WHITE)
	end
	-- Premieren-Suchscheinwerfer
	for k = 0, 2 do
		local P = O + Vector3.new(-130 + k * 12, 0, 40)
		part({ Shape = Enum.PartType.Cylinder, Size = Vector3.new(3, 4, 4), CFrame = CFrame.new(P + Vector3.new(0, 2, 0)) * CFrame.Angles(0, 0, math.rad(70 + k * 20)), Color = Color3.fromRGB(60, 60, 65), Material = Enum.Material.Metal })
		part({ Size = Vector3.new(2.5, 120, 2.5), CFrame = CFrame.new(P + Vector3.new(0, 2, 0)) * CFrame.Angles(0, 0, math.rad(-20 + k * 20)) * CFrame.new(0, 60, 0),
			Color = Color3.fromRGB(255, 250, 220), Material = Enum.Material.Neon, Transparency = 0.82, CanCollide = false, CastShadow = false, CanQuery = false })
	end
	-- Riesen-Popcorn
	local Pp = O + Vector3.new(-160, 0, 0)
	for k = 0, 7 do
		part({ Size = Vector3.new(1.6, 10, 1.6), CFrame = CFrame.new(Pp + Vector3.new(math.cos(k * 0.785) * 4, 5, math.sin(k * 0.785) * 4)), Color = (k % 2 == 0) and Color3.fromRGB(220, 30, 40) or WHITE })
	end
	for _ = 1, 14 do
		part({ Shape = Enum.PartType.Ball, Size = Vector3.new(2.2, 2.2, 2.2), CFrame = CFrame.new(Pp + Vector3.new(rng:NextNumber(-3.5, 3.5), rng:NextNumber(10, 12.5), rng:NextNumber(-3.5, 3.5))), Color = Color3.fromRGB(255, 245, 200) })
	end
end

----------------------------------------------------------------------------
-- 🌇 DUBAI: Wolkenkratzer-Lauf mit Sprungfeld-Aufzug, Riesenrad, Infinity-Pool, Hubschrauber, Supercar-Showroom
----------------------------------------------------------------------------
local function dubaiExtras(O, w, rng, index)
	local T = Vector3.new(135, 0, 135)
	part({ Size = Vector3.new(26, 112, 26), CFrame = CFrame.new(O + T + Vector3.new(0, 56, 0)), Color = Color3.fromRGB(120, 170, 210), Material = Enum.Material.Glass, Reflectance = 0.15 })
	for f = 1, 10 do
		part({ Size = Vector3.new(27, 1, 27), CFrame = CFrame.new(O + T + Vector3.new(0, f * 11, 0)), Color = Color3.fromRGB(212, 175, 55), Material = Enum.Material.Foil })
	end
	course(O, {
		id = "dubai", title = "Wolkenkratzer-Lauf", emoji = "🏙️", hint = "Lauf die Stahlträger rund um den Turm hoch bis zum Helipad!",
		start = Vector3.new(135, 0, 102),
		points = spiralPoints(T, 21, 28, 0.4, 0, 3.0, { [10] = 14, [20] = 14 }),
		jumps = { [10] = 14, [20] = 14 },
		cpEvery = 5,
		size = Vector3.new(6, 1, 4), material = Enum.Material.Metal,
		color = function() return Color3.fromRGB(190, 190, 200) end,
		finish = T + Vector3.new(math.cos(28 * 0.4) * 8, 113.5, math.sin(28 * 0.4) * 8),
		finishBuild = function(fp)
			part({ Shape = Enum.PartType.Cylinder, Size = Vector3.new(0.3, 20, 20), CFrame = CFrame.new(fp - Vector3.new(0, 0.85, 0)) * CFrame.Angles(0, 0, math.rad(90)), Color = Color3.fromRGB(50, 50, 55) })
			surfaceSign(part({ Size = Vector3.new(8, 0.1, 8), CFrame = CFrame.new(fp - Vector3.new(0, 0.95, 0)), Transparency = 1, CanCollide = false }), Enum.NormalId.Top, "H", nil, WHITE)
		end,
		reward = courseReward(index),
	})
	-- Riesenrad „Dubai Eye“
	local A = O + Vector3.new(-90, 0, 200)
	local R = 30
	for _, side in ipairs({ -2, 2 }) do
		part({ Size = Vector3.new(1.4, R + 6, 1.4), CFrame = CFrame.new(A + Vector3.new(side * 2, (R + 6) / 2, 0)) * CFrame.Angles(0, 0, math.rad(side * 6)), Color = WHITE, Material = Enum.Material.Metal })
	end
	local hub = A + Vector3.new(0, R + 6, 0)
	for k = 0, 15 do
		local a = k / 16 * math.pi * 2
		local p = hub + Vector3.new(math.cos(a) * R, math.sin(a) * R, 0)
		part({ Size = Vector3.new(0.4, 0.4, R), CFrame = CFrame.lookAt((hub + p) / 2, p), Color = Color3.fromRGB(230, 230, 240), CanCollide = false })
		local nextP = hub + Vector3.new(math.cos(a + math.pi / 8) * R, math.sin(a + math.pi / 8) * R, 0)
		part({ Size = Vector3.new(0.8, 0.8, (nextP - p).Magnitude), CFrame = CFrame.lookAt((p + nextP) / 2, nextP), Color = Color3.fromRGB(62, 242, 255), Material = Enum.Material.Neon, CanCollide = false })
		ellipsoid({ Size = Vector3.new(3, 3, 3.6), CFrame = CFrame.new(p + Vector3.new(0, -1.8, 0)), Color = Color3.fromRGB(200, 230, 255), Material = Enum.Material.Glass, Transparency = 0.2, CanCollide = false })
	end
	-- Infinity-Pool mit Liegen
	local B = O + Vector3.new(150, 0, -150)
	part({ Size = Vector3.new(34, 2, 20), CFrame = CFrame.new(B + Vector3.new(0, 1, 0)), Color = Color3.fromRGB(240, 240, 240), Material = Enum.Material.Marble })
	part({ Size = Vector3.new(31, 0.4, 17), CFrame = CFrame.new(B + Vector3.new(0, 2.05, 0)), Color = Color3.fromRGB(40, 190, 230), Material = Enum.Material.Glass, Transparency = 0.15 })
	for k = -2, 2 do
		local P = B + Vector3.new(k * 6, 0, -14)
		part({ Size = Vector3.new(2.5, 0.6, 6), CFrame = CFrame.new(P + Vector3.new(0, 1, 0)), Color = WHITE })
		part({ Size = Vector3.new(2.5, 0.6, 2.5), CFrame = CFrame.new(P + Vector3.new(0, 1.8, 2.4)) * CFrame.Angles(math.rad(-40), 0, 0), Color = WHITE })
	end
	-- Helikopter auf Landeplatz
	local C = O + Vector3.new(-140, 0, -195)
	part({ Shape = Enum.PartType.Cylinder, Size = Vector3.new(1, 24, 24), CFrame = CFrame.new(C + Vector3.new(0, 0.5, 0)) * CFrame.Angles(0, 0, math.rad(90)), Color = Color3.fromRGB(50, 50, 55) })
	ellipsoid({ Size = Vector3.new(7, 6, 12), CFrame = CFrame.new(C + Vector3.new(0, 4.5, 0)), Color = Color3.fromRGB(212, 175, 55), Material = Enum.Material.Foil })
	part({ Size = Vector3.new(1.4, 1.4, 10), CFrame = CFrame.new(C + Vector3.new(0, 5, 10)), Color = Color3.fromRGB(212, 175, 55), Material = Enum.Material.Foil })
	part({ Size = Vector3.new(22, 0.3, 1.2), CFrame = CFrame.new(C + Vector3.new(0, 8, 0)) * CFrame.Angles(0, math.rad(25), 0), Color = Color3.fromRGB(40, 40, 45) })
	for _, s in ipairs({ -3, 3 }) do part({ Size = Vector3.new(0.5, 0.5, 11), CFrame = CFrame.new(C + Vector3.new(s, 1.5, 0)), Color = Color3.fromRGB(40, 40, 45) }) end
	-- Luxus-Mall-Torbogen
	local D = O + Vector3.new(205, 0, -85)
	for _, s in ipairs({ -10, 10 }) do part({ Size = Vector3.new(4, 24, 4), CFrame = CFrame.new(D + Vector3.new(0, 12, s)), Color = Color3.fromRGB(240, 230, 210), Material = Enum.Material.Marble }) end
	part({ Size = Vector3.new(5, 5, 26), CFrame = CFrame.new(D + Vector3.new(0, 26, 0)), Color = Color3.fromRGB(212, 175, 55), Material = Enum.Material.Foil })
	surfaceSign(part({ Size = Vector3.new(0.3, 4, 20), CFrame = CFrame.new(D + Vector3.new(-2.7, 26, 0)), Color = Color3.fromRGB(20, 5, 35) }), Enum.NormalId.Left, "💎 GLOW MALL", Color3.fromRGB(20, 5, 35), Color3.fromRGB(255, 209, 102))
	-- Supercar-Showroom
	local E = O + Vector3.new(-120, 0, 40)
	for k = -1, 1 do
		local P = E + Vector3.new(k * 14, 0, 0)
		part({ Shape = Enum.PartType.Cylinder, Size = Vector3.new(1, 13, 13), CFrame = CFrame.new(P + Vector3.new(0, 0.5, 0)) * CFrame.Angles(0, 0, math.rad(90)), Color = Color3.fromRGB(30, 30, 35), Material = Enum.Material.Marble })
		car(O, P.X - O.X, P.Z - O.Z, math.rad(30 + k * 40), ({ Color3.fromRGB(212, 175, 55), Color3.fromRGB(250, 250, 250), Color3.fromRGB(220, 20, 50) })[k + 2], true)
	end
	trampoline(O, 60, 120, 110, Color3.fromRGB(255, 209, 102))
end

----------------------------------------------------------------------------
-- 🌌 AURA-GALAXIE: Planeten-Hüpfen mit Sprungfeldern, Mondbasis, Satellitenschüssel, Schwarzes Loch, Alien-Statue
----------------------------------------------------------------------------
local PLANET_COLORS = { Color3.fromRGB(255, 120, 200), Color3.fromRGB(90, 200, 255), Color3.fromRGB(255, 200, 80), Color3.fromRGB(150, 255, 160), Color3.fromRGB(200, 120, 255) }

local function galaxyExtras(O, w, rng, index)
	course(O, {
		id = "galaxy", title = "Planeten-Hüpfen", emoji = "🪐", hint = "Hüpf von Planet zu Planet – die pinken Felder schießen dich hoch!",
		start = Vector3.new(95, 0, 95),
		points = linePoints(Vector3.new(104, 0, 104), Vector3.new(180, 0, 180), 20, 7, 0.8, 3, 1.6, { [6] = 15, [13] = 15 }),
		jumps = { [6] = 15, [13] = 15 },
		cpEvery = 7,
		build = function(P, i, size, under)
			if under then return end
			local d = 9
			local planet = part({ Shape = Enum.PartType.Ball, Size = Vector3.new(d, d, d), CFrame = CFrame.new(P - Vector3.new(0, d / 2, 0)),
				Color = PLANET_COLORS[(i % #PLANET_COLORS) + 1], Material = Enum.Material.SmoothPlastic })
			-- flache Landefläche oben, damit man nicht abrutscht
			part({ Shape = Enum.PartType.Cylinder, Size = Vector3.new(0.4, 6, 6), CFrame = CFrame.new(P - Vector3.new(0, 0.2, 0)) * CFrame.Angles(0, 0, math.rad(90)),
				Color = PLANET_COLORS[(i % #PLANET_COLORS) + 1]:Lerp(WHITE, 0.3), Material = Enum.Material.SmoothPlastic })
			if i % 4 == 0 then
				part({ Shape = Enum.PartType.Cylinder, Size = Vector3.new(0.3, d * 1.7, d * 1.7), CFrame = CFrame.new(P - Vector3.new(0, d / 2, 0)) * CFrame.Angles(math.rad(15), 0, math.rad(90)),
					Color = WHITE, Material = Enum.Material.Neon, Transparency = 0.5, CanCollide = false })
			end
			return planet
		end,
		finish = Vector3.new(188, 66, 188),
		finishBuild = function(fp)
			-- UFO
			ellipsoid({ Size = Vector3.new(22, 4, 22), CFrame = CFrame.new(fp - Vector3.new(0, 2.6, 0)), Color = Color3.fromRGB(180, 185, 200), Material = Enum.Material.Metal })
			ellipsoid({ Size = Vector3.new(9, 6, 9), CFrame = CFrame.new(fp + Vector3.new(0, 1, 6)), Color = Color3.fromRGB(120, 255, 180), Material = Enum.Material.Glass, Transparency = 0.3, CanCollide = false })
			for k = 0, 7 do
				local a = k / 8 * math.pi * 2
				part({ Shape = Enum.PartType.Ball, Size = Vector3.new(1.2, 1.2, 1.2), CFrame = CFrame.new(fp + Vector3.new(math.cos(a) * 10, -2.6, math.sin(a) * 10)), Color = Color3.fromRGB(255, 209, 102), Material = Enum.Material.Neon })
			end
		end,
		reward = courseReward(index),
	})
	-- Mondbasis
	local A = O + Vector3.new(-90, 0, 190)
	for _, d in ipairs({ { 0, 0, 20 }, { 16, 6, 12 }, { -14, 8, 10 } }) do
		ellipsoid({ Size = Vector3.new(d[3], d[3] * 0.9, d[3]), CFrame = CFrame.new(A + Vector3.new(d[1], 0, d[2])), Color = Color3.fromRGB(200, 230, 255), Material = Enum.Material.Glass, Transparency = 0.35 })
	end
	part({ Size = Vector3.new(16, 3, 3), CFrame = CFrame.new(A + Vector3.new(8, 1.5, 3)), Color = Color3.fromRGB(200, 200, 210), Material = Enum.Material.Metal })
	part({ Size = Vector3.new(14, 3, 3), CFrame = CFrame.new(A + Vector3.new(-7, 1.5, 4)), Color = Color3.fromRGB(200, 200, 210), Material = Enum.Material.Metal })
	-- Satellitenschüssel
	local B = O + Vector3.new(150, 0, -150)
	part({ Size = Vector3.new(2, 12, 2), CFrame = CFrame.new(B + Vector3.new(0, 6, 0)), Color = Color3.fromRGB(180, 180, 190), Material = Enum.Material.Metal })
	ellipsoid({ Size = Vector3.new(20, 3, 20), CFrame = CFrame.new(B + Vector3.new(0, 14, 0)) * CFrame.Angles(math.rad(35), 0, 0), Color = Color3.fromRGB(230, 230, 240), Material = Enum.Material.Metal })
	part({ Size = Vector3.new(0.5, 7, 0.5), CFrame = CFrame.new(B + Vector3.new(0, 16.5, -2)) * CFrame.Angles(math.rad(35), 0, 0), Color = Color3.fromRGB(80, 80, 90) })
	part({ Shape = Enum.PartType.Ball, Size = Vector3.new(1.4, 1.4, 1.4), CFrame = CFrame.new(B + Vector3.new(0, 19.4, 0)), Color = Color3.fromRGB(255, 80, 80), Material = Enum.Material.Neon })
	-- Schwarzes Loch (Deko)
	local C = O + Vector3.new(-140, 22, -195)
	part({ Shape = Enum.PartType.Ball, Size = Vector3.new(14, 14, 14), CFrame = CFrame.new(C), Color = Color3.new(0, 0, 0), CanCollide = false })
	for k = 1, 3 do
		part({ Shape = Enum.PartType.Cylinder, Size = Vector3.new(0.4, 18 + k * 7, 18 + k * 7), CFrame = CFrame.new(C) * CFrame.Angles(math.rad(70), 0, math.rad(90)),
			Color = ({ Color3.fromRGB(255, 160, 60), Color3.fromRGB(255, 80, 200), Color3.fromRGB(150, 90, 255) })[k], Material = Enum.Material.Neon, Transparency = 0.3 + k * 0.15, CanCollide = false })
	end
	-- Raumstation-Module
	local D = O + Vector3.new(205, 0, -85)
	for k = 0, 2 do
		part({ Shape = Enum.PartType.Cylinder, Size = Vector3.new(12, 6, 6), CFrame = CFrame.new(D + Vector3.new(0, 4, -12 + k * 12)) * CFrame.Angles(0, math.rad(90), 0), Color = Color3.fromRGB(225, 225, 235), Material = Enum.Material.Metal })
	end
	for _, s in ipairs({ -1, 1 }) do
		part({ Size = Vector3.new(14, 0.3, 6), CFrame = CFrame.new(D + Vector3.new(s * 10, 4, 0)), Color = Color3.fromRGB(40, 70, 160), Material = Enum.Material.Glass })
	end
	-- Alien-Statue (macht natürlich Mewing)
	local E = O + Vector3.new(-120, 0, 40)
	local alien = Color3.fromRGB(120, 230, 140)
	part({ Size = Vector3.new(6, 2, 6), CFrame = CFrame.new(E + Vector3.new(0, 1, 0)), Color = Color3.fromRGB(60, 50, 80), Material = Enum.Material.Marble })
	ellipsoid({ Size = Vector3.new(3, 6, 2.4), CFrame = CFrame.new(E + Vector3.new(0, 5.5, 0)), Color = alien })
	ellipsoid({ Size = Vector3.new(5, 6, 5), CFrame = CFrame.new(E + Vector3.new(0, 11, 0)), Color = alien })
	for _, s in ipairs({ -1.1, 1.1 }) do
		ellipsoid({ Size = Vector3.new(1.4, 2, 0.6), CFrame = CFrame.new(E + Vector3.new(s, 11.4, -2.3)) * CFrame.Angles(0, 0, math.rad(s * 20)), Color = Color3.new(0, 0, 0), Reflectance = 0.5 })
	end
	trampoline(O, 60, 120, 120, Color3.fromRGB(200, 120, 255))
end

local WORLD_EXTRAS = { beach = beachExtras, mountain = mountainExtras, temple = templeExtras, fashion = fashionExtras,
	hollywood = hollywoodExtras, dubai = dubaiExtras, galaxy = galaxyExtras }

-- Bereiche je Welt, an denen keine zufällige Deko stehen darf (Parkour & Wahrzeichen)
local LANDMARK_SPOTS = { { -90, 190, 30 }, { 150, -150, 22 }, { -140, -195, 20 }, { 205, -85, 18 }, { -120, 40, 22 }, { -160, 0, 8 } }
local WORLD_RESERVED = {
	beach = { { 130, 175, 70 }, { 60, 120, 8 } },
	mountain = { { 140, 140, 45 }, { 170, -205, 14 }, { 115, -205, 12 }, { 225, -205, 12 } },
	temple = { { 150, 150, 70 } },
	fashion = { { 138, 138, 58 }, { 30, 120, 8 } },
	hollywood = { { 140, 140, 60 } },
	dubai = { { 135, 135, 50 }, { -90, 200, 40 }, { 60, 120, 8 } },
	galaxy = { { 140, 140, 62 }, { 60, 120, 8 } },
}

local function buildWorld(index, mapFolder)
	local w = Config.Worlds[index]
	local O = Vector3.new((index - 1) * Config.WORLD_SPACING, 0, 0)
	local rng = Random.new(index * 7919)
	currentFolder = Instance.new("Folder")
	currentFolder.Name = index .. "_" .. w.id
	currentFolder.Parent = mapFolder

	-- Boden & unsichtbare Wände
	local ground = part({ Name = "Ground", Size = Vector3.new(S, 4, S), CFrame = CFrame.new(O + Vector3.new(0, -2, 0)), Color = w.ground, Material = GROUND_MATERIAL[w.theme] })
	if TERRAIN_GROUND[w.theme] then
		local ok = pcall(function()
			workspace.Terrain:FillBlock(CFrame.new(O + Vector3.new(0, -2, 0)), Vector3.new(S, 4, S), TERRAIN_GROUND[w.theme])
		end)
		if ok then
			ground.Transparency = 1     -- das Gelände ersetzt die Bodenplatte
			ground.CanCollide = false
			ground.CanQuery = false     -- Fans & Sammel-Items stehen auf dem echten Gelände (nicht übers Meer)
		end
	end
	for _, side in ipairs({ { HALF, 0, 2, S }, { -HALF, 0, 2, S }, { 0, HALF, S, 2 }, { 0, -HALF, S, 2 } }) do
		part({ Name = "Wall", Size = Vector3.new(side[3], 120, side[4]), CFrame = CFrame.new(O + Vector3.new(side[1], 60, side[2])), Transparency = 1 })
	end

	-- Spawn-Platz
	part({ Shape = Enum.PartType.Cylinder, Size = Vector3.new(0.4, 40, 40), CFrame = CFrame.new(O + Vector3.new(0, 0.2, 0)) * CFrame.Angles(0, 0, math.rad(90)),
		Color = w.accent, Material = Enum.Material.SmoothPlastic, Transparency = 0.25 })
	if index == 1 then
		local spawn = Instance.new("SpawnLocation")
		spawn.Name = "Spawn"
		spawn.Anchored = true
		spawn.Size = Vector3.new(10, 1, 10)
		spawn.CFrame = CFrame.new(O + Vector3.new(0, 0.5, 22))
		spawn.Transparency = 1
		spawn.CanCollide = false
		spawn.Duration = 0
		spawn.Neutral = true
		spawn.Parent = currentFolder
	end
	local nameAnchor = part({ Size = Vector3.new(1, 1, 1), CFrame = CFrame.new(O + Vector3.new(0, 26, -30)), Transparency = 1, CanCollide = false })
	billboard(nameAnchor, w.emoji .. " " .. string.upper(w.name) .. "\n<font size='20' color='#ffd166'>Aura x" .. Util.format(w.mult) .. "</font>", 40, 10, 0, WHITE)

	-- Sperrflächen für Parkour & Wahrzeichen dieser Welt
	currentReserved = {}
	currentMaxZ = (w.theme == "beach") and 118 or nil
	for _, r in ipairs(WORLD_RESERVED[w.theme] or {}) do table.insert(currentReserved, r) end
	if WORLD_EXTRAS[w.theme] then
		for _, r in ipairs(LANDMARK_SPOTS) do table.insert(currentReserved, r) end
	end

	-- Deko
	local theme = THEMES[w.theme]
	if theme then theme(O, w, rng) end
	decorate(O, w, rng)

	-- Pet-Stationen: 5 Geschenkboxen, von günstig bis göttlich
	for st, station in ipairs(Config.EggStations) do
		local egg = Config.Eggs[Config.eggIndex(index, st)]
		local ep = O + Vector3.new(40 + (st - 1) * 26, 0, -45 - math.abs(st - 3) * 6)
		part({ Shape = Enum.PartType.Cylinder, Size = Vector3.new(2, 13, 13), CFrame = CFrame.new(ep + Vector3.new(0, 1, 0)) * CFrame.Angles(0, 0, math.rad(90)),
			Color = Color3.fromRGB(40, 20, 60), Material = Enum.Material.SmoothPlastic })
		part({ Shape = Enum.PartType.Cylinder, Size = Vector3.new(0.3, 13.6, 13.6), CFrame = CFrame.new(ep + Vector3.new(0, 2.05, 0)) * CFrame.Angles(0, 0, math.rad(90)),
			Color = station.color, Material = Enum.Material.Neon, Transparency = 0.3 })
		local s = 4.5 + st * 0.5
		local box = part({ Name = "Geschenkbox", Size = Vector3.new(s, s, s), CFrame = CFrame.new(ep + Vector3.new(0, 2 + s / 2 + 0.5, 0)) * CFrame.Angles(0, math.rad(20), 0),
			Color = station.color, Material = st >= 4 and Enum.Material.Glass or Enum.Material.SmoothPlastic, Reflectance = st >= 3 and 0.2 or 0 })
		part({ Size = Vector3.new(s + 0.2, s + 0.2, 0.9), CFrame = box.CFrame, Color = Color3.fromRGB(255, 255, 255), Material = Enum.Material.Neon })
		part({ Size = Vector3.new(0.9, s + 0.2, s + 0.2), CFrame = box.CFrame, Color = Color3.fromRGB(255, 255, 255), Material = Enum.Material.Neon })
		part({ Shape = Enum.PartType.Ball, Size = Vector3.new(1.6, 1.6, 1.6), CFrame = box.CFrame * CFrame.new(0, s / 2 + 0.5, 0), Color = Color3.fromRGB(255, 255, 255), Material = Enum.Material.Neon })
		local light = Instance.new("PointLight")
		light.Color = station.color
		light.Range = 14
		light.Parent = box
		-- beste Chance auf dem Schild
		local bestName, bestChance, total = nil, 0, 0
		for _, e in ipairs(egg.pets) do total = total + e.weight end
		local bestOrder = 0
		for rarityId, w in pairs(station.weights) do
			local r = Config.Rarities[rarityId]
			if r.order > bestOrder then bestOrder, bestName, bestChance = r.order, r.name, w end
		end
		billboard(box, station.emoji .. " " .. station.name .. "\n<font color='#ffd166'>" .. Util.format(egg.cost) .. " Aura</font>\n<font size='14'>bis " .. bestName .. ": "
			.. Util.format(bestChance / total * 100) .. " %</font>", 11, 4.6, s / 2 + 3.5, WHITE)
		table.insert(MapBuilder.eggPrompts, { prompt = prompt(box, "Öffnen", station.name, 0.25), egg = egg, count = 1 })
		table.insert(MapBuilder.eggPrompts, { prompt = prompt(box, "3x öffnen", "Rebirth-Shop: 3er-Öffnen", 0.25, Enum.KeyCode.F), egg = egg, count = 3 })
		table.insert(MapBuilder.eggPrompts, { prompt = prompt(box, "Inhalt ansehen", station.name, 0, Enum.KeyCode.R), egg = egg, info = true })
	end
	local plazaSign = part({ Size = Vector3.new(30, 5, 1), CFrame = CFrame.new(O + Vector3.new(92, 14, -78)), Color = Color3.fromRGB(20, 5, 35) })
	surfaceSign(plazaSign, Enum.NormalId.Back, "🐾 PET-STATIONEN", Color3.fromRGB(20, 5, 35), WHITE)
	part({ Size = Vector3.new(1, 13, 1), CFrame = CFrame.new(O + Vector3.new(78, 6.5, -78)), Color = Color3.fromRGB(60, 60, 70) })
	part({ Size = Vector3.new(1, 13, 1), CFrame = CFrame.new(O + Vector3.new(106, 6.5, -78)), Color = Color3.fromRGB(60, 60, 70) })

	-- Rivale & Boss
	local rival = Config.Rivals[index]
	table.insert(MapBuilder.npcs, { prompt = makeNPC(rival, O + Vector3.new(-55, 0, -40), false), def = rival, world = index, isBoss = false })
	-- schwächere Rivalen zum Üben
	for k, extra in ipairs(Config.ExtraRivals) do
		local name = extra.prefix .. " " .. Config.RivalNames[((index * 3 + k) % #Config.RivalNames) + 1]
		local def = {
			name = name, level = math.max(1, math.floor(rival.level * extra.strength)), rebirths = math.floor(rival.rebirths * extra.strength),
			shirt = rival.shirt:Lerp(Color3.fromRGB(80, 80, 90), 0.4), pants = rival.pants, skin = rival.skin,
		}
		table.insert(MapBuilder.npcs, { prompt = makeNPC(def, O + Vector3.new(-85 - k * 25, 0, -25 - k * 18), false), def = def, world = index, isBoss = false })
	end
	local boss = Config.Bosses[index]
	part({ Shape = Enum.PartType.Cylinder, Size = Vector3.new(4, 30, 30), CFrame = CFrame.new(O + Vector3.new(0, 2, -160)) * CFrame.Angles(0, 0, math.rad(90)),
		Color = boss.final and Color3.fromRGB(212, 175, 55) or Color3.fromRGB(60, 20, 40), Material = boss.final and Enum.Material.Foil or Enum.Material.Slate })
	table.insert(MapBuilder.npcs, { prompt = makeNPC(boss, O + Vector3.new(0, 4, -160), true), def = boss, world = index, isBoss = true })

	-- Portale zur nächsten / vorherigen Welt
	local function portal(x, target, arrow)
		local tw = Config.Worlds[target]
		local P = O + Vector3.new(x, 0, 0)
		part({ Size = Vector3.new(4, 24, 4), CFrame = CFrame.new(P + Vector3.new(0, 12, -11)), Color = Color3.fromRGB(40, 20, 60) })
		part({ Size = Vector3.new(4, 24, 4), CFrame = CFrame.new(P + Vector3.new(0, 12, 11)), Color = Color3.fromRGB(40, 20, 60) })
		part({ Size = Vector3.new(4, 4, 26), CFrame = CFrame.new(P + Vector3.new(0, 26, 0)), Color = Color3.fromRGB(40, 20, 60) })
		local gate = part({ Name = "Portal", Size = Vector3.new(1, 22, 18), CFrame = CFrame.new(P + Vector3.new(0, 12, 0)), Color = tw.accent, Material = Enum.Material.Neon, Transparency = 0.35, CanCollide = false })
		local info = arrow .. " " .. tw.emoji .. " " .. tw.name .. "\n<font size='18' color='#ffd166'>Aura x" .. Util.format(tw.mult)
		if target > index and tw.cost > 0 then
			info = info .. " · " .. Util.format(tw.cost) .. " Aura"
			if tw.rebirths > 0 then info = info .. " · ♻️ " .. tw.rebirths end
		end
		billboard(gate, info .. "</font>", 16, 5, 15, WHITE)
		table.insert(MapBuilder.portals, { prompt = prompt(gate, "Reisen", tw.name, 0.5), target = target })
	end
	if index < #Config.Worlds then portal(200, index + 1, "➡️") end
	if index > 1 then portal(-200, index - 1, "⬅️") end

	-- Minispiele & Event-Platz
	if index == 1 then
		eventPlaza(O)
		obbyCourse(O)
		gymStation(O)
	elseif index == 3 then
		gymStation(O)
	elseif index == 5 then
		raceTrack(O)
	end
	-- Parkour & Wahrzeichen der Welt
	if WORLD_EXTRAS[w.theme] then
		WORLD_EXTRAS[w.theme](O, w, rng, index)
	end

	-- Nur in Glow City: Ranglisten-Tafel & Info-Tafel
	if index == 1 then
		local board = part({ Name = "Rangliste", Size = Vector3.new(40, 26, 1), CFrame = CFrame.new(O + Vector3.new(0, 15, 100)), Color = Color3.fromRGB(20, 5, 35) })
		part({ Size = Vector3.new(2, 15, 2), CFrame = CFrame.new(O + Vector3.new(-15, 1, 100)), Color = Color3.fromRGB(60, 60, 70) })
		part({ Size = Vector3.new(2, 15, 2), CFrame = CFrame.new(O + Vector3.new(15, 1, 100)), Color = Color3.fromRGB(60, 60, 70) })
		local sg = Instance.new("SurfaceGui")
		sg.Face = Enum.NormalId.Front
		sg.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
		sg.PixelsPerStud = 25
		sg.LightInfluence = 0
		sg.Parent = board
		local header = Instance.new("TextLabel")
		header.Size = UDim2.new(1, 0, 0.16, 0)
		header.BackgroundColor3 = Color3.fromRGB(255, 79, 216)
		header.TextScaled = true
		header.Font = Enum.Font.FredokaOne
		header.TextColor3 = WHITE
		header.Text = "🏆 GLOBALE TOP 10 – GLOW-POWER"
		header.Parent = sg
		for r = 1, 10 do
			local row = Instance.new("TextLabel")
			row.Size = UDim2.new(0.96, 0, 0.078, 0)
			row.Position = UDim2.new(0.02, 0, 0.17 + (r - 1) * 0.082, 0)
			row.BackgroundTransparency = r % 2 == 0 and 1 or 0.85
			row.BackgroundColor3 = WHITE
			row.TextScaled = true
			row.RichText = true
			row.Font = Enum.Font.GothamBold
			row.TextColor3 = WHITE
			row.TextXAlignment = Enum.TextXAlignment.Left
			row.Text = r .. ". …"
			row.Parent = sg
			MapBuilder.boardRows[r] = row
		end

		local infoBoard = part({ Size = Vector3.new(22, 16, 0.6), CFrame = CFrame.new(O + Vector3.new(-45, 9, 60)) * CFrame.Angles(0, math.rad(-37), 0), Color = Color3.fromRGB(20, 5, 35) })
		local _, infoLabel = surfaceSign(infoBoard, Enum.NormalId.Front,
			"<b>📖 SO GEHT'S</b>\n🪞 Daily Routine klicken = Aura\n💪 Upgrades kaufen = mehr Aura & Glow\n🎁 Geschenkboxen = Pets mit Boosts\n⚔️ Rivalen & Bosse = Mog Battles\n🌍 Portale = neue Welten\n♻️ Rebirth = dauerhafter Bonus",
			Color3.fromRGB(20, 5, 35), WHITE)
		infoLabel.Font = Enum.Font.GothamBold
	end
end

function MapBuilder.build()
	local mapFolder = workspace:FindFirstChild("Map")
	if mapFolder then mapFolder:Destroy() end
	mapFolder = Instance.new("Folder")
	mapFolder.Name = "Map"
	mapFolder.Parent = workspace

	npcFolder = Instance.new("Folder")
	npcFolder.Name = "NPCs"
	npcFolder.Parent = workspace

	local pets = workspace:FindFirstChild("Pets") or Instance.new("Folder")
	pets.Name = "Pets"
	pets.Parent = workspace

	-- realistischere Beleuchtung (falls in Studio nicht schon eingestellt)
	local Lighting = game:GetService("Lighting")
	pcall(function() Lighting.Technology = Enum.Technology.Future end)
	pcall(function()
		Lighting.GlobalShadows = true
		Lighting.EnvironmentDiffuseScale = 1
		Lighting.EnvironmentSpecularScale = 1
		Lighting.Brightness = 2.5
		workspace.Terrain.Decoration = false   -- Grashalme verdecken sonst kleine Deko (wirkte "im Boden")
		workspace.Terrain.WaterWaveSize = 0.25
		workspace.Terrain.WaterTransparency = 0.6
		workspace.Terrain.WaterColor = Color3.fromRGB(20, 150, 190)
		workspace.Terrain:SetMaterialColor(Enum.Material.Grass, Color3.fromRGB(95, 150, 70))
		workspace.Terrain:SetMaterialColor(Enum.Material.Sand, Color3.fromRGB(230, 205, 150))
	end)

	for i = 1, #Config.Worlds do
		local ok, err = pcall(buildWorld, i, mapFolder)
		if not ok then
			warn("[Looksmaxxer] Fehler beim Bauen von Welt " .. i .. ":", err)
		end
	end
end

return MapBuilder
