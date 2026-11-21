--[[
	EFFECTS – alles, was kurz aufpoppt:
	Nachrichten (Toasts), große Banner, fliegende Zahlen,
	Box-Öffnen-Animation, Mog-Battle-Ansicht, Herausforderungen, Bestätigungen.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local Players = game:GetService("Players")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config"))
local Logic = require(Shared:WaitForChild("Logic"))
local Util = require(Shared:WaitForChild("Util"))
local UI = require(script.Parent:WaitForChild("UI"))
local Sounds = require(script.Parent:WaitForChild("Sounds"))
local PetView = require(script.Parent:WaitForChild("PetView"))

local Effects = {}
local gui, overlayGui, toastHolder

local function tween(inst, t, props, style)
	local tw = TweenService:Create(inst, TweenInfo.new(t, style or Enum.EasingStyle.Quad, Enum.EasingDirection.Out), props)
	tw:Play()
	return tw
end

function Effects.init(mainGui)
	gui = mainGui
	overlayGui = UI.new("ScreenGui", {
		Name = "LooksmaxxerOverlay", ResetOnSpawn = false, DisplayOrder = 20,
		ZIndexBehavior = Enum.ZIndexBehavior.Sibling, Parent = Players.LocalPlayer:WaitForChild("PlayerGui"),
	})
	toastHolder = UI.new("Frame", {
		Name = "Toasts", BackgroundTransparency = 1, AnchorPoint = Vector2.new(1, 0),
		Position = UDim2.new(1, -10, 0, 80), Size = UDim2.new(0.28, 0, 0.6, 0), Parent = overlayGui,
	})
	UI.new("UISizeConstraint", { MinSize = Vector2.new(220, 100), MaxSize = Vector2.new(380, 600), Parent = toastHolder })
	UI.list(toastHolder, false, 6, Enum.HorizontalAlignment.Right)
end

----------------------------------------------------------------------------
-- Kleine Nachricht oben rechts
----------------------------------------------------------------------------
local KIND_COLORS = {
	good = UI.C.green, bad = UI.C.red, global = UI.C.gold, title = UI.C.pink, world = UI.C.cyan,
}
function Effects.toast(title, text, kind)
	if not toastHolder then return end
	local color = KIND_COLORS[kind] or UI.C.purple
	local f = UI.panel(toastHolder, { Size = UDim2.new(1, 0, 0, 66), Color = UI.C.dark, Transparency = 0.08 })
	UI.stroke(f, color, 2, 0)
	UI.padding(f, 8)
	UI.text(f, "<b>" .. title .. "</b>", { Size = UDim2.new(1, 0, 0.45, 0), Color = color, XAlign = Enum.TextXAlignment.Left, MaxText = 18 })
	UI.text(f, text or "", { Size = UDim2.new(1, 0, 0.55, 0), Position = UDim2.new(0, 0, 0.45, 0), Font = Enum.Font.GothamBold,
		XAlign = Enum.TextXAlignment.Left, MaxText = 14 })
	if kind == "bad" then Sounds.play("Error") else Sounds.play("Notify") end
	-- höchstens 4 gleichzeitig
	local frames = {}
	for _, c in ipairs(toastHolder:GetChildren()) do
		if c:IsA("Frame") then table.insert(frames, c) end
	end
	if #frames > 4 then frames[1]:Destroy() end
	task.delay(4.5, function()
		if f.Parent then
			tween(f, 0.4, { BackgroundTransparency = 1 })
			task.wait(0.4)
			f:Destroy()
		end
	end)
end

----------------------------------------------------------------------------
-- Großes Banner (neuer Titel, Rebirth, Welt, Beauty Sleep)
----------------------------------------------------------------------------
function Effects.banner(title, text, color)
	local f = UI.panel(overlayGui, { AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.new(0.5, 0, 0.12, 0),
		Size = UDim2.new(0.5, 0, 0.16, 0), Color = color or UI.C.pink })
	UI.new("UISizeConstraint", { MinSize = Vector2.new(300, 90), MaxSize = Vector2.new(700, 140), Parent = f })
	UI.gradient(f, color or UI.C.pink, UI.C.purple, 0)
	UI.stroke(f, UI.C.gold, 3, 0)
	UI.padding(f, 10)
	UI.text(f, "<b>" .. title .. "</b>", { Size = UDim2.new(1, 0, 0.55, 0), MaxText = 34 })
	UI.text(f, text or "", { Size = UDim2.new(1, 0, 0.45, 0), Position = UDim2.new(0, 0, 0.55, 0), Font = Enum.Font.GothamBold, MaxText = 18 })
	local scale = UI.new("UIScale", { Scale = 0.4, Parent = f })
	tween(scale, 0.35, { Scale = 1 }, Enum.EasingStyle.Back)
	Sounds.play("TitleUp")
	task.delay(4, function()
		tween(scale, 0.25, { Scale = 0 })
		task.wait(0.3)
		f:Destroy()
	end)
end

----------------------------------------------------------------------------
-- Fliegende "+X" Zahl
----------------------------------------------------------------------------
function Effects.floatText(text, position, color)
	local l = UI.text(overlayGui, text, { Size = UDim2.new(0, 160, 0, 40), Position = position,
		AnchorPoint = Vector2.new(0.5, 0.5), Color = color or UI.C.gold, MaxText = 30 })
	l.TextStrokeTransparency = 0.3
	tween(l, 0.9, { Position = position - UDim2.new(0, 0, 0, 90), TextTransparency = 1, TextStrokeTransparency = 1 })
	task.delay(1, function() l:Destroy() end)
end

----------------------------------------------------------------------------
-- Dunkler Hintergrund für große Fenster
----------------------------------------------------------------------------
local function overlay()
	local o = UI.new("TextButton", {
		Name = "Overlay", Size = UDim2.new(1, 0, 1, 0), BackgroundColor3 = Color3.new(0, 0, 0),
		BackgroundTransparency = 0.35, Text = "", AutoButtonColor = false, Parent = overlayGui,
	})
	return o
end

----------------------------------------------------------------------------
-- Geschenkbox öffnen
----------------------------------------------------------------------------
function Effects.hatch(results)
	local o = overlay()
	local box = UI.text(o, "🎁", { AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.new(0.5, 0, 0.45, 0), Size = UDim2.new(0, 220, 0, 220), MaxText = 200 })
	Sounds.play("Hatch")
	-- Wackeln
	for i = 1, 8 do
		tween(box, 0.09, { Rotation = (i % 2 == 0) and 18 or -18 })
		task.wait(0.1)
	end
	tween(box, 0.2, { Rotation = 0, Size = UDim2.new(0, 320, 0, 320), TextTransparency = 1 })
	task.wait(0.2)
	box:Destroy()

	local row = UI.new("Frame", { BackgroundTransparency = 1, AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.new(0.5, 0, 0.45, 0),
		Size = UDim2.new(0.9, 0, 0.42, 0), Parent = o })
	UI.list(row, true, 14, Enum.HorizontalAlignment.Center, Enum.VerticalAlignment.Center)
	local best = 1
	for _, r in ipairs(results) do
		local def = Logic.petById[r.id]
		local rarity = Config.Rarities[def.rarity]
		if rarity.order > best then best = rarity.order end
		local card = UI.panel(row, { Size = UDim2.new(0, 170, 0, 220), Color = rarity.color:Lerp(Color3.new(0, 0, 0), 0.55) })
		UI.stroke(card, rarity.color, 4, 0)
		UI.padding(card, 8)
		PetView.make(card, def.id, 1, true, { Size = UDim2.new(1, 0, 0.5, 0) })
		UI.text(card, def.name, { Size = UDim2.new(1, 0, 0.18, 0), Position = UDim2.new(0, 0, 0.52, 0), MaxText = 20 })
		UI.text(card, rarity.name, { Size = UDim2.new(1, 0, 0.14, 0), Position = UDim2.new(0, 0, 0.7, 0), Color = rarity.color, MaxText = 18 })
		UI.text(card, Util.formatPercent(def.boost) .. " Aura", { Size = UDim2.new(1, 0, 0.13, 0), Position = UDim2.new(0, 0, 0.85, 0),
			Color = UI.C.green, Font = Enum.Font.GothamBold, MaxText = 15 })
		if r.new then
			local badge = UI.panel(card, { Size = UDim2.new(0, 56, 0, 24), Position = UDim2.new(1, -40, 0, -16), Color = UI.C.red, Radius = 8 })
			UI.text(badge, "NEU!", { MaxText = 16 })
		end
		local s = UI.new("UIScale", { Scale = 0.2, Parent = card })
		tween(s, 0.35, { Scale = 1 }, Enum.EasingStyle.Back)
	end
	if best >= 5 then Sounds.play("HatchRare") end
	UI.text(o, "Tippen zum Schließen", { AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.new(0.5, 0, 0.72, 0), Size = UDim2.new(0.5, 0, 0.05, 0),
		Color = UI.C.muted, MaxText = 18 })
	local closed = false
	local function close()
		if closed then return end
		closed = true
		o:Destroy()
	end
	o.Activated:Connect(close)
	task.delay(best >= 5 and 6 or 3.5, close)
end

----------------------------------------------------------------------------
-- Mog Battle anzeigen
----------------------------------------------------------------------------
function Effects.battle(res)
	local o = overlay()
	local p = UI.panel(o, { AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.new(0.5, 0, 0.5, 0), Size = UDim2.new(0.5, 0, 0.78, 0), Color = UI.C.bg })
	UI.new("UISizeConstraint", { MinSize = Vector2.new(320, 380), MaxSize = Vector2.new(620, 640), Parent = p })
	UI.stroke(p, res.final and UI.C.gold or UI.C.pink, 3, 0)
	UI.padding(p, 14)
	local title = res.final and "💀 ENDBOSS LEON 💀" or (res.isBoss and "👑 BOSS-BATTLE 👑" or "⚔️ MOG BATTLE ⚔️")
	UI.text(p, "<b>" .. title .. "</b>", { Size = UDim2.new(1, 0, 0.09, 0), Color = res.final and UI.C.gold or UI.C.text, MaxText = 32 })
	local y = 0.09
	if res.taunt then
		UI.text(p, "<i>„" .. res.taunt .. "“</i>", { Size = UDim2.new(1, 0, 0.05, 0), Position = UDim2.new(0, 0, y, 0), Color = UI.C.muted,
			Font = Enum.Font.GothamBold, MaxText = 16 })
		y = y + 0.05
	end
	UI.text(p, "<font color='" .. UI.hex(UI.C.gold) .. "'>DU</font>   VS   <font color='" .. UI.hex(UI.C.cyan) .. "'>" .. res.opponent .. "</font>",
		{ Size = UDim2.new(1, 0, 0.08, 0), Position = UDim2.new(0, 0, y, 0), MaxText = 26 })
	y = y + 0.1
	local rounds = UI.new("Frame", { BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0.45, 0), Position = UDim2.new(0, 0, y, 0), Parent = p })
	UI.list(rounds, false, 5)
	local verdict = UI.text(p, "", { Size = UDim2.new(1, 0, 0.08, 0), Position = UDim2.new(0, 0, 0.7, 0), MaxText = 30 })
	local info = UI.text(p, "", { Size = UDim2.new(1, 0, 0.1, 0), Position = UDim2.new(0, 0, 0.78, 0), Font = Enum.Font.GothamBold, MaxText = 16 })
	Sounds.play("BattleStart")

	local catByName = {}
	for _, c in ipairs(Config.Categories) do catByName[c.id] = c end
	for i, r in ipairs(res.rounds) do
		task.wait(res.isBoss and 0.9 or 0.7)
		if not p.Parent then return end
		local win = r.a > r.b
		local row = UI.panel(rounds, { Size = UDim2.new(1, 0, 0.18, 0), Color = UI.C.panel2, LayoutOrder = i, Radius = 10 })
		UI.text(row, (win and "✅ " or "") .. Util.format(r.a), { Size = UDim2.new(0.25, 0, 1, 0), Color = win and UI.C.green or UI.C.red, MaxText = 20 })
		local c = catByName[r.cat]
		UI.text(row, "Runde " .. i .. " · " .. c.emoji .. " " .. Config.BattleNames[r.cat], { Size = UDim2.new(0.5, 0, 1, 0), Position = UDim2.new(0.25, 0, 0, 0),
			Color = UI.C.muted, MaxText = 16 })
		UI.text(row, Util.format(r.b) .. (win and "" or " ✅"), { Size = UDim2.new(0.25, 0, 1, 0), Position = UDim2.new(0.75, 0, 0, 0),
			Color = win and UI.C.red or UI.C.green, MaxText = 20 })
	end
	task.wait(0.6)
	if not p.Parent then return end
	if res.won then
		verdict.Text = "🏆 DU MOGGST! (" .. res.wins .. ":" .. (5 - res.wins) .. ")"
		verdict.TextColor3 = UI.C.green
		Sounds.play("BattleWin")
	else
		verdict.Text = "💀 GEMOGGT! (" .. res.wins .. ":" .. (5 - res.wins) .. ")"
		verdict.TextColor3 = UI.C.red
		Sounds.play("BattleLose")
	end
	local rewardText = ""
	if res.reward and (res.reward.aura > 0 or res.reward.cash > 0) then
		rewardText = "\n<font color='" .. UI.hex(UI.C.gold) .. "'>+" .. Util.format(res.reward.aura) .. " Aura · +" .. Util.format(res.reward.cash) .. " Geld</font>"
		if res.isBoss then rewardText = rewardText .. "\n🎁 Gratis-Box kommt gleich!" end
	end
	info.Text = (res.text or "") .. rewardText
	UI.button(p, res.won and "Ehrenrunde 😎" or "Ab ins Gym 💪", UI.C.pink, function() o:Destroy() end,
		{ AnchorPoint = Vector2.new(0.5, 1), Position = UDim2.new(0.5, 0, 1, 0), Size = UDim2.new(0.6, 0, 0.09, 0) })
end

----------------------------------------------------------------------------
-- Herausforderung von einem anderen Spieler
----------------------------------------------------------------------------
function Effects.battleRequest(name, userId, respond)
	local f = UI.panel(overlayGui, { AnchorPoint = Vector2.new(0.5, 1), Position = UDim2.new(0.5, 0, 0.78, 0), Size = UDim2.new(0.4, 0, 0.14, 0), Color = UI.C.dark })
	UI.new("UISizeConstraint", { MinSize = Vector2.new(300, 90), MaxSize = Vector2.new(520, 120), Parent = f })
	UI.stroke(f, UI.C.orange, 3, 0)
	UI.padding(f, 8)
	UI.text(f, "⚔️ <b>" .. name .. "</b> fordert dich zum Mog Battle heraus!", { Size = UDim2.new(1, 0, 0.5, 0), MaxText = 20 })
	local done = false
	local function answer(ok)
		if done then return end
		done = true
		respond(ok, userId)
		f:Destroy()
	end
	UI.button(f, "✅ Annehmen", UI.C.green, function() answer(true) end, { Size = UDim2.new(0.48, 0, 0.42, 0), Position = UDim2.new(0, 0, 0.56, 0), TextColor = UI.C.dark })
	UI.button(f, "❌ Ablehnen", UI.C.red, function() answer(false) end, { Size = UDim2.new(0.48, 0, 0.42, 0), Position = UDim2.new(0.52, 0, 0.56, 0) })
	task.delay(15, function() answer(false) end)
end

----------------------------------------------------------------------------
-- Ja/Nein-Abfrage
----------------------------------------------------------------------------
function Effects.confirm(title, text, yesLabel, onYes)
	local o = overlay()
	local p = UI.panel(o, { AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.new(0.5, 0, 0.5, 0), Size = UDim2.new(0.4, 0, 0.36, 0), Color = UI.C.bg })
	UI.new("UISizeConstraint", { MinSize = Vector2.new(300, 200), MaxSize = Vector2.new(520, 300), Parent = p })
	UI.stroke(p, UI.C.pink, 2, 0)
	UI.padding(p, 14)
	UI.text(p, "<b>" .. title .. "</b>", { Size = UDim2.new(1, 0, 0.22, 0), MaxText = 26 })
	UI.text(p, text, { Size = UDim2.new(1, 0, 0.45, 0), Position = UDim2.new(0, 0, 0.24, 0), Font = Enum.Font.GothamBold, MaxText = 16 })
	UI.button(p, "Abbrechen", UI.C.grey, function() o:Destroy() end, { Size = UDim2.new(0.48, 0, 0.24, 0), Position = UDim2.new(0, 0, 0.76, 0) })
	UI.button(p, yesLabel or "Ja", UI.C.pink, function()
		o:Destroy()
		onYes()
	end, { Size = UDim2.new(0.48, 0, 0.24, 0), Position = UDim2.new(0.52, 0, 0.76, 0) })
end

----------------------------------------------------------------------------
-- Allgemeine Anfrage (z. B. Handel) mit Annehmen/Ablehnen
----------------------------------------------------------------------------
function Effects.requestPopup(text, color, respond)
	local f = UI.panel(overlayGui, { AnchorPoint = Vector2.new(0.5, 1), Position = UDim2.new(0.5, 0, 0.62, 0), Size = UDim2.new(0.4, 0, 0.14, 0), Color = UI.C.dark })
	UI.new("UISizeConstraint", { MinSize = Vector2.new(300, 90), MaxSize = Vector2.new(520, 120), Parent = f })
	UI.stroke(f, color or UI.C.cyan, 3, 0)
	UI.padding(f, 8)
	UI.text(f, text, { Size = UDim2.new(1, 0, 0.5, 0), MaxText = 20 })
	local done = false
	local function answer(ok)
		if done then return end
		done = true
		respond(ok)
		f:Destroy()
	end
	UI.button(f, "✅ Annehmen", UI.C.green, function() answer(true) end, { Size = UDim2.new(0.48, 0, 0.42, 0), Position = UDim2.new(0, 0, 0.56, 0), TextColor = UI.C.dark })
	UI.button(f, "❌ Ablehnen", UI.C.red, function() answer(false) end, { Size = UDim2.new(0.48, 0, 0.42, 0), Position = UDim2.new(0.52, 0, 0.56, 0) })
	task.delay(15, function() answer(false) end)
end

----------------------------------------------------------------------------
-- Schadenszahl über dem Boss
----------------------------------------------------------------------------
function Effects.damagePopup(amount, crit, position)
	local anchor = Instance.new("Part")
	anchor.Anchored = true
	anchor.CanCollide = false
	anchor.CanQuery = false
	anchor.CanTouch = false
	anchor.Transparency = 1
	anchor.Size = Vector3.new(0.2, 0.2, 0.2)
	anchor.CFrame = CFrame.new(position)
	anchor.Parent = workspace
	local bb = Instance.new("BillboardGui")
	bb.Size = UDim2.new(0, crit and 160 or 110, 0, crit and 50 or 36)
	bb.AlwaysOnTop = true
	bb.LightInfluence = 0
	bb.Parent = anchor
	local l = UI.text(bb, (crit and "💥 " or "") .. Util.format(amount), { Color = crit and UI.C.gold or UI.C.text, MaxText = crit and 40 or 28 })
	l.TextStrokeTransparency = 0.2
	tween(bb, 0.7, { StudsOffset = Vector3.new(0, 4, 0) })
	tween(l, 0.7, { TextTransparency = 1, TextStrokeTransparency = 1 })
	task.delay(0.75, function() anchor:Destroy() end)
end

----------------------------------------------------------------------------
-- Fan begeistern: Auswahl & Ergebnis
----------------------------------------------------------------------------
local fanPanel = nil
function Effects.fanDialog(info, choose)
	if fanPanel then fanPanel:Destroy() end
	local o = overlay()
	fanPanel = o
	local p = UI.panel(o, { AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.new(0.5, 0, 0.5, 0), Size = UDim2.new(0.44, 0, 0.62, 0), Color = UI.C.bg })
	UI.new("UISizeConstraint", { MinSize = Vector2.new(320, 340), MaxSize = Vector2.new(560, 520), Parent = p })
	UI.stroke(p, UI.C.pink, 3, 0)
	UI.padding(p, 14)
	UI.text(p, "<b>⭐ " .. info.name .. " begeistern</b>", { Size = UDim2.new(1, 0, 0.11, 0), MaxText = 28 })
	UI.text(p, info.role .. " · Promi-Level " .. info.fame .. "/10", { Size = UDim2.new(1, 0, 0.07, 0), Position = UDim2.new(0, 0, 0.11, 0), Color = UI.C.muted, Font = Enum.Font.GothamBold, MaxText = 16 })
	UI.text(p, "Deine Chance: ~" .. info.chance .. " %", { Size = UDim2.new(1, 0, 0.08, 0), Position = UDim2.new(0, 0, 0.19, 0), Color = UI.C.gold, MaxText = 22 })
	UI.text(p, "Charisma " .. Util.format(info.charisma) .. " · gebraucht ca. " .. Util.format(info.req), { Size = UDim2.new(1, 0, 0.06, 0), Position = UDim2.new(0, 0, 0.27, 0),
		Color = UI.C.muted, Font = Enum.Font.Gotham, MaxText = 14 })
	local body = UI.new("Frame", { BackgroundTransparency = 1, Position = UDim2.new(0, 0, 0.35, 0), Size = UDim2.new(1, 0, 0.65, 0), Name = "Body", Parent = p })
	UI.list(body, false, 8)
	for i, text in ipairs(info.openers) do
		UI.button(body, text, UI.C.panel2, function()
			UI.clear(body)
			UI.text(body, "…", { Size = UDim2.new(1, 0, 0, 40), MaxText = 30 })
			choose(i)
		end, { Size = UDim2.new(1, 0, 0, 48), LayoutOrder = i, MaxText = 16 })
	end
	UI.button(body, "Lieber doch nicht 🙈", UI.C.grey, function()
		o:Destroy()
		fanPanel = nil
	end, { Size = UDim2.new(1, 0, 0, 40), LayoutOrder = 9, MaxText = 16 })
end

function Effects.fanResult(success, text, extra)
	if not fanPanel then return end
	local body = fanPanel:FindFirstChild("Body", true)
	if not body then return end
	UI.clear(body)
	UI.text(body, success and "⭐ Neuer Fan!" or "😬 Nicht beeindruckt!", { Size = UDim2.new(1, 0, 0, 44), Color = success and UI.C.green or UI.C.red, MaxText = 30, LayoutOrder = 1 })
	UI.text(body, text, { Size = UDim2.new(1, 0, 0, 60), Font = Enum.Font.GothamBold, MaxText = 18, LayoutOrder = 2 })
	if extra and extra ~= "" then
		UI.text(body, extra, { Size = UDim2.new(1, 0, 0, 40), Color = success and UI.C.gold or UI.C.muted, Font = Enum.Font.GothamBold, MaxText = 15, LayoutOrder = 3 })
	end
	local panel = fanPanel
	UI.button(body, success and "Nice! 😎" or "Weiter geht's", UI.C.pink, function()
		panel:Destroy()
		if fanPanel == panel then fanPanel = nil end
	end, { Size = UDim2.new(1, 0, 0, 44), LayoutOrder = 4 })
	if success then Sounds.play("BattleWin") else Sounds.play("BattleLose") end
end

----------------------------------------------------------------------------
-- Job-Minispiel: im richtigen Moment tippen (3 Versuche)
----------------------------------------------------------------------------
function Effects.jobGame(job, onFinish)
	local RunService = game:GetService("RunService")
	local o = overlay()
	local p = UI.panel(o, { AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.new(0.5, 0, 0.5, 0), Size = UDim2.new(0.5, 0, 0.56, 0), Color = UI.C.bg })
	UI.new("UISizeConstraint", { MinSize = Vector2.new(320, 300), MaxSize = Vector2.new(620, 440), Parent = p })
	UI.stroke(p, UI.C.cyan, 3, 0)
	UI.padding(p, 14)
	UI.text(p, "<b>" .. job.emoji .. " " .. job.name .. "</b>", { Size = UDim2.new(1, 0, 0.13, 0), MaxText = 26 })
	UI.text(p, "Tippe auf den Knopf, wenn der weiße Strich im <font color='" .. UI.hex(UI.C.green) .. "'>grünen</font> Bereich ist. Gelbe Mitte = PERFEKT!",
		{ Size = UDim2.new(1, 0, 0.14, 0), Position = UDim2.new(0, 0, 0.13, 0), Font = Enum.Font.GothamBold, Color = UI.C.muted, MaxText = 15 })
	local bar = UI.panel(p, { Size = UDim2.new(1, 0, 0.12, 0), Position = UDim2.new(0, 0, 0.32, 0), Color = UI.C.panel2, Radius = 10 })
	bar.ClipsDescendants = true
	local zoneF = UI.new("Frame", { BackgroundColor3 = UI.C.green, BackgroundTransparency = 0.3, BorderSizePixel = 0, Size = UDim2.new(0, 0, 1, 0), Parent = bar })
	local perfF = UI.new("Frame", { BackgroundColor3 = UI.C.gold, BorderSizePixel = 0, Size = UDim2.new(0, 0, 1, 0), Parent = bar })
	local marker = UI.new("Frame", { BackgroundColor3 = Color3.new(1, 1, 1), BorderSizePixel = 0, AnchorPoint = Vector2.new(0.5, 0), Size = UDim2.new(0, 6, 1, 0), Parent = bar })
	local results = UI.new("Frame", { BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0.12, 0), Position = UDim2.new(0, 0, 0.48, 0), Parent = p })
	UI.list(results, true, 8, Enum.HorizontalAlignment.Center)

	local zone = math.max(0.1, 0.32 - job.diff * 0.035)
	local speed = 0.55 + job.diff * 0.17
	local pos, dir, zoneStart = 0, 1, 0
	local scores = {}
	local function newZone()
		zoneStart = 0.05 + math.random() * (0.9 - zone)
		zoneF.Position = UDim2.new(zoneStart, 0, 0, 0)
		zoneF.Size = UDim2.new(zone, 0, 1, 0)
		perfF.Position = UDim2.new(zoneStart + zone * 0.35, 0, 0, 0)
		perfF.Size = UDim2.new(zone * 0.3, 0, 1, 0)
	end
	newZone()
	local conn = RunService.RenderStepped:Connect(function(dt)
		pos = pos + dir * speed * dt
		if pos > 1 then pos = 1; dir = -1 end
		if pos < 0 then pos = 0; dir = 1 end
		marker.Position = UDim2.new(pos, 0, 0, 0)
	end)
	local btn
	btn = UI.button(p, job.act, UI.C.pink, function()
		if #scores >= 3 then return end
		local score, label
		if pos >= zoneStart + zone * 0.35 and pos <= zoneStart + zone * 0.65 then score, label = 1, "🌟 PERFEKT"
		elseif pos >= zoneStart and pos <= zoneStart + zone then score, label = 0.6, "👍 Gut"
		else score, label = 0.1, "😬 Daneben" end
		table.insert(scores, score)
		local chip = UI.panel(results, { Size = UDim2.new(0.3, 0, 1, 0), Color = UI.C.panel2, Radius = 10 })
		UI.text(chip, label, { MaxText = 18 })
		Sounds.play("Click")
		if #scores < 3 then
			newZone()
			return
		end
		conn:Disconnect()
		btn.Text = "⏳ Wird ausgewertet …"
		onFinish(scores)
		task.delay(1.2, function() o:Destroy() end)
	end, { Size = UDim2.new(1, 0, 0.22, 0), Position = UDim2.new(0, 0, 0.66, 0), MaxText = 30 })
	UI.button(p, "Abbrechen", UI.C.grey, function()
		conn:Disconnect()
		o:Destroy()
	end, { Size = UDim2.new(0.4, 0, 0.08, 0), Position = UDim2.new(0.3, 0, 0.91, 0), MaxText = 14 })
end


return Effects
