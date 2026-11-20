--[[
	MAPBUILDER – baut beim Serverstart alle 8 Welten automatisch auf:
	Boden, Deko je nach Thema, Geschenkbox-Stand, Rivale, Boss, Portale,
	Ranglisten-Tafel und Info-Tafel.

	Tipp: Du kannst die Karte später in Studio von Hand verschönern.
	Starte dazu das Spiel (Play), kopiere Workspace > Map, stoppe,
	füge sie ein und lösche dann den Aufruf von MapBuilder in "Main".
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config"))
local Util = require(Shared:WaitForChild("Util"))

local MapBuilder = {}
MapBuilder.eggPrompts = {}    -- { prompt, egg, count }
MapBuilder.npcs = {}          -- { prompt, def, world, isBoss }
MapBuilder.portals = {}       -- { prompt, target }
MapBuilder.boardRows = {}     -- Textzeilen der Ranglisten-Tafel

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
	{ 0, 0, 55 }, { 55, -40, 22 }, { -55, -40, 22 }, { 0, -160, 40 },
	{ 200, 0, 30 }, { -200, 0, 30 }, { 0, 100, 30 }, { -45, 60, 18 }, { 95, -40, 16 },
}
local function isFree(x, z, radius)
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
		local x = rng:NextNumber(-HALF + radius + 5, HALF - radius - 5)
		local z = rng:NextNumber(-HALF + radius + 5, HALF - radius - 5)
		local d = math.sqrt(x * x + z * z)
		if d >= (minDist or 0) and d <= (maxDist or 9999) and isFree(x, z, radius) then
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
	part({ Size = Vector3.new(2, 10, 2) * scale, CFrame = CFrame.new(O + Vector3.new(x, 5 * scale, z)), Color = Color3.fromRGB(122, 78, 45), Material = Enum.Material.Wood })
	part({ Shape = Enum.PartType.Ball, Size = Vector3.new(11, 11, 11) * scale, CFrame = CFrame.new(O + Vector3.new(x, 12 * scale, z)), Color = color or Color3.fromRGB(63, 143, 69), Material = Enum.Material.Grass })
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
	part({ Size = Vector3.new(S, 0.2, 26), CFrame = CFrame.new(O + Vector3.new(0, 0.1, 0)), Color = Color3.fromRGB(60, 58, 74) })
	part({ Size = Vector3.new(26, 0.2, S), CFrame = CFrame.new(O + Vector3.new(0, 0.12, 0)), Color = Color3.fromRGB(60, 58, 74) })
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
	part({ Size = Vector3.new(S, 1, 120), CFrame = CFrame.new(O + Vector3.new(0, 0.35, 190)), Color = Color3.fromRGB(0, 170, 220),
		Material = Enum.Material.Glass, Transparency = 0.35, CanCollide = false })
	part({ Size = Vector3.new(S, 0.3, 8), CFrame = CFrame.new(O + Vector3.new(0, 0.2, 128)), Color = Color3.fromRGB(255, 255, 255), Transparency = 0.3, CanCollide = false })
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
		local r = HALF - 30
		local size = rng:NextNumber(70, 130)
		local x, z = math.cos(a) * r, math.sin(a) * r
		if isFree(x, z, 20) then
			local cf = CFrame.new(O + Vector3.new(x, size / 2, z)) * CFrame.Angles(0, -a + math.rad(90), 0)
			part({ Class = "WedgePart", Size = Vector3.new(size, size, size * 0.6), CFrame = cf, Color = Color3.fromRGB(110, 110, 118), Material = Enum.Material.Slate })
			part({ Class = "WedgePart", Size = Vector3.new(size * 0.4, size * 0.3, size * 0.25), CFrame = cf * CFrame.new(0, size * 0.36, size * 0.17), Color = Color3.fromRGB(245, 248, 255), Material = Enum.Material.Snow })
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
	part({ Size = Vector3.new(14, 60, 2), CFrame = CFrame.new(O + Vector3.new(-120, 30, -215)), Color = Color3.fromRGB(240, 235, 225), Material = Enum.Material.Neon, Transparency = 0.3 })
	part({ Shape = Enum.PartType.Cylinder, Size = Vector3.new(1, 30, 30), CFrame = CFrame.new(O + Vector3.new(-120, 0.4, -200)) * CFrame.Angles(0, 0, math.rad(90)),
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

local GROUND_MATERIAL = {
	city = Enum.Material.SmoothPlastic, beach = Enum.Material.Sand, mountain = Enum.Material.Grass, temple = Enum.Material.Grass,
	fashion = Enum.Material.SmoothPlastic, hollywood = Enum.Material.Sandstone, dubai = Enum.Material.Sand, galaxy = Enum.Material.Slate,
}

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
local function buildWorld(index, mapFolder)
	local w = Config.Worlds[index]
	local O = Vector3.new((index - 1) * Config.WORLD_SPACING, 0, 0)
	local rng = Random.new(index * 7919)
	currentFolder = Instance.new("Folder")
	currentFolder.Name = index .. "_" .. w.id
	currentFolder.Parent = mapFolder

	-- Boden & unsichtbare Wände
	part({ Name = "Ground", Size = Vector3.new(S, 4, S), CFrame = CFrame.new(O + Vector3.new(0, -2, 0)), Color = w.ground, Material = GROUND_MATERIAL[w.theme] })
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

	-- Deko
	local theme = THEMES[w.theme]
	if theme then theme(O, w, rng) end

	-- Geschenkbox-Stand
	local egg = Config.Eggs[index]
	local ep = O + Vector3.new(55, 0, -40)
	part({ Shape = Enum.PartType.Cylinder, Size = Vector3.new(2, 14, 14), CFrame = CFrame.new(ep + Vector3.new(0, 1, 0)) * CFrame.Angles(0, 0, math.rad(90)), Color = Color3.fromRGB(40, 20, 60) })
	local box = part({ Name = "Geschenkbox", Size = Vector3.new(6, 6, 6), CFrame = CFrame.new(ep + Vector3.new(0, 5, 0)) * CFrame.Angles(0, math.rad(20), 0), Color = w.accent })
	part({ Size = Vector3.new(6.2, 6.2, 1), CFrame = box.CFrame, Color = Color3.fromRGB(255, 209, 102), Material = Enum.Material.Neon })
	part({ Size = Vector3.new(1, 6.2, 6.2), CFrame = box.CFrame, Color = Color3.fromRGB(255, 209, 102), Material = Enum.Material.Neon })
	billboard(box, "🎁 " .. egg.name .. "\n<font color='#ffd166'>" .. Util.format(egg.cost) .. " Aura</font>", 12, 4, 6.5, WHITE)
	table.insert(MapBuilder.eggPrompts, { prompt = prompt(box, "Öffnen", egg.name, 0.25), egg = egg, count = 1 })
	table.insert(MapBuilder.eggPrompts, { prompt = prompt(box, "3x öffnen", "Rebirth-Shop: 3er-Öffnen", 0.25, Enum.KeyCode.F), egg = egg, count = 3 })

	-- Tafel mit den Chancen der Box
	local total = 0
	for _, e in ipairs(egg.pets) do total = total + e.weight end
	local lines = { "<b>Inhalt der " .. egg.name .. "</b>" }
	for _, e in ipairs(egg.pets) do
		local def
		for _, p in ipairs(Config.Pets) do
			if p.id == e.id then def = p end
		end
		local r = Config.Rarities[def.rarity]
		local hex = string.format("#%02x%02x%02x", math.floor(r.color.R * 255 + 0.5), math.floor(r.color.G * 255 + 0.5), math.floor(r.color.B * 255 + 0.5))
		table.insert(lines, def.emoji .. " " .. def.name .. "  <font color='" .. hex .. "'>" .. Util.format(e.weight / total * 100) .. " %</font>")
	end
	local chanceBoard = part({ Size = Vector3.new(14, 16, 0.6), CFrame = CFrame.new(O + Vector3.new(95, 9, -40)) * CFrame.Angles(0, math.rad(115), 0), Color = Color3.fromRGB(20, 5, 35) })
	local _, chanceLabel = surfaceSign(chanceBoard, Enum.NormalId.Front, table.concat(lines, "\n"), Color3.fromRGB(20, 5, 35), WHITE)
	chanceLabel.Font = Enum.Font.GothamBold
	part({ Size = Vector3.new(1, 9, 1), CFrame = CFrame.new(O + Vector3.new(95, 0.5, -40)), Color = Color3.fromRGB(60, 60, 70) })

	-- Rivale & Boss
	local rival = Config.Rivals[index]
	table.insert(MapBuilder.npcs, { prompt = makeNPC(rival, O + Vector3.new(-55, 0, -40), false), def = rival, world = index, isBoss = false })
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

	for i = 1, #Config.Worlds do
		local ok, err = pcall(buildWorld, i, mapFolder)
		if not ok then
			warn("[Looksmaxxer] Fehler beim Bauen von Welt " .. i .. ":", err)
		end
	end
end

return MapBuilder
