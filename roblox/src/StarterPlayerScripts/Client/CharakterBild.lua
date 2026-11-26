--[[
	CHARAKTERBILD – zeigt das Vorher/Nachher-Bild des Charakters (im 💪 Upgrades-Menü)
	und feiert einmal, wenn alle 7 Attribute gemaxxt sind.

	Die Bild-IDs stehen in ReplicatedStorage › Shared › CharakterBilderConfig.
	Die Attributwerte (Upgrade-Stufen) kommen vom Server (State.snap.data.levels).
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Logic = require(Shared:WaitForChild("Logic"))
local Bilder = require(Shared:WaitForChild("CharakterBilderConfig"))
local UI = require(script.Parent:WaitForChild("UI"))
local State = require(script.Parent:WaitForChild("State"))
local Sounds = require(script.Parent:WaitForChild("Sounds"))

local CharakterBild = {}
local C = UI.C
local BG = Color3.fromRGB(222, 222, 226)   -- passt zum hellgrauen Bildhintergrund

-- Fortschritt 0..1 aus dem Spielstand
function CharakterBild.progress(data)
	return Logic.glowUpProgress(data and data.levels, Bilder.ATTRIBUTE)
end

-- Bildstufen: Vorher (0) → Zwischenbilder → Nachher (1); leere IDs werden übersprungen
local function stages()
	local list = {}
	if Bilder.VORHER ~= "" then table.insert(list, { ab = 0, id = Bilder.VORHER }) end
	for _, z in ipairs(Bilder.ZWISCHEN or {}) do
		if z.id and z.id ~= "" and type(z.ab) == "number" and z.ab > 0 and z.ab < 1 then
			table.insert(list, { ab = z.ab, id = z.id })
		end
	end
	if Bilder.NACHHER ~= "" then table.insert(list, { ab = 1, id = Bilder.NACHHER }) end
	table.sort(list, function(a, b) return a.ab < b.ab end)
	return list
end

-- welches Bild unten, welches oben und wie sichtbar das obere ist (0..1)
local function blend(p)
	local list = stages()
	if #list == 0 then return nil end
	if #list == 1 then return list[1].id, nil, 0 end
	local k = 1
	for i = 1, #list - 1 do
		if p >= list[i].ab then k = i end
	end
	local a, b = list[k], list[k + 1]
	local t = math.clamp((p - a.ab) / math.max(b.ab - a.ab, 0.0001), 0, 1)
	local v = t ^ (Bilder.KURVE or 1)
	return a.id, b.id, v
end

local function imageLabel(parent, z)
	local img = UI.new("ImageLabel", {
		Name = "Bild", BackgroundTransparency = 1, Size = UDim2.new(1, 0, 1, 0),
		ScaleType = Enum.ScaleType.Fit, ImageTransparency = 1, ZIndex = z, Parent = parent,
	})
	UI.new("UIAspectRatioConstraint", { AspectRatio = Bilder.SEITENVERHAELTNIS, Parent = img })
	UI.corner(img, 10)
	return img
end

-- Baut die Anzeige in "parent" (füllt die Breite, Höhe ergibt sich aus 0.811).
-- Rückgabe: { holder = Frame, set = function(progress, sofort) }
function CharakterBild.create(parent)
	local holder = UI.panel(parent, { Name = "CharakterBild", Size = UDim2.new(1, 0, 1, -30), Color = BG, Radius = 10, LayoutOrder = 1 })
	UI.new("UIAspectRatioConstraint", { AspectRatio = Bilder.SEITENVERHAELTNIS, AspectType = Enum.AspectType.FitWithinMaxSize,
		DominantAxis = Enum.DominantAxis.Height, Parent = holder })
	UI.stroke(holder, C.pink, 2, 0.3)
	local bottom = imageLabel(holder, 2)
	local top = imageLabel(holder, 3)
	local missing = UI.text(holder, "🖼️ Bilder fehlen noch\n<font size='12'>IDs in CharakterBilderConfig eintragen</font>",
		{ Color = Color3.fromRGB(80, 70, 100), MaxText = 16, ZIndex = 4 })

	local info = UI.new("Frame", { BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 26), LayoutOrder = 2, Parent = parent })
	local barBg = UI.panel(info, { Size = UDim2.new(1, 0, 0, 6), Position = UDim2.new(0, 0, 1, -6), Color = C.dark, Radius = 3 })
	local bar = UI.panel(barBg, { Size = UDim2.new(0, 0, 1, 0), Color = C.pink, Radius = 3 })
	UI.gradient(bar, C.pink, C.gold, 0)
	local label = UI.text(info, "", { Size = UDim2.new(1, 0, 1, -8), Color = C.gold, MaxText = 16 })
	-- Text & Balken genau so breit wie das Bild
	holder:GetPropertyChangedSignal("AbsoluteSize"):Connect(function()
		info.Size = UDim2.new(0, holder.AbsoluteSize.X, 0, 26)
	end)

	local last = nil
	local currentTween = nil
	local function set(p, instant)
		p = math.clamp(p or 0, 0, 1)
		label.Text = p >= 1 and "👑 FULLY LOOKSMAXXED!" or ("✨ Glow-Up: " .. math.floor(p * 100) .. " %")
		bar.Size = UDim2.new(p, 0, 1, 0)
		if last ~= nil and math.abs(last - p) < 0.00001 and not instant then return end
		last = p
		local lowId, highId, v = blend(p)
		missing.Visible = lowId == nil
		if not lowId then
			bottom.ImageTransparency, top.ImageTransparency = 1, 1
			return
		end
		bottom.ImageTransparency = 0
		local segmentChanged = bottom.Image ~= lowId or top.Image ~= (highId or "")
		bottom.Image = lowId
		top.Image = highId or ""
		local target = highId and (1 - v) or 1
		if currentTween then currentTween:Cancel() end
		if instant or segmentChanged then
			top.ImageTransparency = target
		else
			currentTween = TweenService:Create(top, TweenInfo.new(Bilder.UEBERGANG_SEKUNDEN or 0.6, Enum.EasingStyle.Sine, Enum.EasingDirection.Out),
				{ ImageTransparency = target })
			currentTween:Play()
		end
	end
	return { holder = holder, set = set }
end

----------------------------------------------------------------------------
-- 👑 Feier, wenn alles gemaxxt ist
----------------------------------------------------------------------------
local CONFETTI = { C.pink, C.gold, C.cyan, C.green, C.purple, Color3.new(1, 1, 1) }

function CharakterBild.celebrate()
	local gui = UI.new("ScreenGui", { Name = "FullyLooksmaxxed", ResetOnSpawn = false, IgnoreGuiInset = true, DisplayOrder = 30,
		ZIndexBehavior = Enum.ZIndexBehavior.Sibling, Parent = Players.LocalPlayer:WaitForChild("PlayerGui") })
	local bg = UI.new("TextButton", { Text = "", AutoButtonColor = false, BackgroundColor3 = Color3.new(0, 0, 0), BackgroundTransparency = 1,
		Size = UDim2.new(1, 0, 1, 0), Parent = gui })
	TweenService:Create(bg, TweenInfo.new(0.4), { BackgroundTransparency = 0.35 }):Play()

	-- sich drehende Lichtstrahlen
	local rays = UI.new("Frame", { BackgroundTransparency = 1, AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.new(0.5, 0, 0.45, 0),
		Size = UDim2.new(0, 10, 0, 10), Parent = bg })
	for k = 0, 11 do
		local ray = UI.new("Frame", { BackgroundColor3 = C.gold, BorderSizePixel = 0, AnchorPoint = Vector2.new(0.5, 1), Position = UDim2.new(0.5, 0, 0.5, 0),
			Size = UDim2.new(0, 26, 0, 900), Rotation = k * 30, BackgroundTransparency = 0.75, Parent = rays })
		UI.new("UIGradient", { Transparency = NumberSequence.new(0, 1), Rotation = 90, Parent = ray })
	end
	TweenService:Create(rays, TweenInfo.new(8, Enum.EasingStyle.Linear), { Rotation = 180 }):Play()

	-- das Nachher-Bild groß in der Mitte
	local card = UI.new("Frame", { BackgroundColor3 = BG, AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.new(0.5, 0, 0.45, 0),
		Size = UDim2.new(0, 0, 0.55, 0), Parent = bg })
	UI.new("UIAspectRatioConstraint", { AspectRatio = Bilder.SEITENVERHAELTNIS, AspectType = Enum.AspectType.FitWithinMaxSize,
		DominantAxis = Enum.DominantAxis.Height, Parent = card })
	UI.corner(card, 16)
	UI.stroke(card, C.gold, 4, 0)
	if Bilder.NACHHER ~= "" then
		local img = imageLabel(card, 2)
		img.Image = Bilder.NACHHER
		img.ImageTransparency = 0
	else
		UI.text(card, "😎", { MaxText = 100 })
	end
	card.Size = UDim2.new(0.55, 0, 0.55, 0)
	local cardScale = UI.new("UIScale", { Scale = 0.2, Parent = card })
	TweenService:Create(cardScale, TweenInfo.new(0.6, Enum.EasingStyle.Back, Enum.EasingDirection.Out), { Scale = 1 }):Play()

	local title = UI.text(bg, "<b>FULLY LOOKSMAXXED!</b>", { AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.new(0.5, 0, 0.75, 0),
		Size = UDim2.new(0.9, 0, 0.11, 0), Color = C.gold, MaxText = 70 })
	title.TextStrokeTransparency = 0
	title.TextStrokeColor3 = Color3.fromRGB(80, 20, 90)
	local sub = UI.text(bg, "Alle 7 Attribute gemaxxt – absolute Gigachad-Energie 🗿👑", { AnchorPoint = Vector2.new(0.5, 0),
		Position = UDim2.new(0.5, 0, 0.86, 0), Size = UDim2.new(0.8, 0, 0.05, 0), Font = Enum.Font.GothamBold, MaxText = 22 })
	sub.TextStrokeTransparency = 0.3
	local titleScale = UI.new("UIScale", { Scale = 0, Parent = title })
	task.delay(0.35, function()
		TweenService:Create(titleScale, TweenInfo.new(0.5, Enum.EasingStyle.Back, Enum.EasingDirection.Out), { Scale = 1 }):Play()
	end)

	-- Konfetti
	for i = 1, 70 do
		local c = UI.new("Frame", { BackgroundColor3 = CONFETTI[(i % #CONFETTI) + 1], BorderSizePixel = 0, AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.new(math.random(), 0, -0.05, 0), Size = UDim2.new(0, math.random(6, 12), 0, math.random(10, 18)),
			Rotation = math.random(0, 360), Parent = bg })
		TweenService:Create(c, TweenInfo.new(math.random(25, 45) / 10, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
			Position = UDim2.new(c.Position.X.Scale + (math.random() - 0.5) * 0.3, 0, 1.08, 0), Rotation = c.Rotation + math.random(-540, 540),
		}):Play()
	end

	Sounds.play("Rebirth")
	task.delay(0.5, function() Sounds.play("TitleUp") end)

	local closed = false
	local function close()
		if closed then return end
		closed = true
		TweenService:Create(cardScale, TweenInfo.new(0.25), { Scale = 0 }):Play()
		TweenService:Create(titleScale, TweenInfo.new(0.25), { Scale = 0 }):Play()
		TweenService:Create(bg, TweenInfo.new(0.3), { BackgroundTransparency = 1 }):Play()
		task.delay(0.35, function() gui:Destroy() end)
	end
	-- antippen schließt (erst nach kurzer Zeit, damit man es nicht aus Versehen wegklickt)
	task.delay(1.2, function() bg.Activated:Connect(close) end)
	task.delay(7, close)
end

-- Wächter: feiert genau dann, wenn der Fortschritt von unter 100 % auf 100 % springt.
-- (Der erste Stand nach dem Beitreten zählt nur als Ausgangswert → keine Feier beim Neubeitritt.)
function CharakterBild.init()
	local before = nil
	State.onChange(function(kind)
		if kind ~= "full" or not State.snap then return end
		local p = CharakterBild.progress(State.snap.data)
		if before ~= nil and before < 1 and p >= 1 then
			CharakterBild.celebrate()
		end
		before = p
	end)
	-- Bilder vorladen, damit beim ersten Öffnen nichts aufploppt
	task.spawn(function()
		local ids = {}
		for _, s in ipairs(stages()) do
			local img = Instance.new("ImageLabel")
			img.Image = s.id
			table.insert(ids, img)
		end
		if #ids > 0 then
			pcall(function() game:GetService("ContentProvider"):PreloadAsync(ids) end)
		end
	end)
end

return CharakterBild
