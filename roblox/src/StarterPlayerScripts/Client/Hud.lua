--[[
	HUD – die ständige Anzeige:
	oben die Werte, links die Menü-Knöpfe, unten der Daily-Routine-Knopf
	mit Titel und Fortschritt zum nächsten Titel.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config"))
local Logic = require(Shared:WaitForChild("Logic"))
local Util = require(Shared:WaitForChild("Util"))
local Remotes = ReplicatedStorage:WaitForChild("Remotes")
local UI = require(script.Parent:WaitForChild("UI"))
local State = require(script.Parent:WaitForChild("State"))
local Sounds = require(script.Parent:WaitForChild("Sounds"))
local Effects = require(script.Parent:WaitForChild("Effects"))
local Menus = require(script.Parent:WaitForChild("Menus"))

local Hud = {}
local C = UI.C
local chips = {}
local titleLabel, nextLabel, progressBar, routineSub, routineBtn, rewardsDot
local wheelDot, eventBtn, rideBtn, raceLabel

local UIS = game:GetService("UserInputService")
-- Handy/Tablet ohne Tastatur: kompaktere Oberfläche, damit man mehr vom Spiel sieht
local touch = UIS.TouchEnabled and not UIS.KeyboardEnabled

local function chip(parent, key, caption, color, order)
	local f = UI.panel(parent, { Size = UDim2.new(0.155, 0, 1, 0), Color = C.dark, Transparency = touch and 0.3 or 0.15, LayoutOrder = order, Radius = touch and 10 or 14 })
	UI.stroke(f, color, touch and 1.5 or 2, 0.3)
	UI.text(f, caption, { Size = UDim2.new(1, 0, 0.34, 0), Position = UDim2.new(0, 0, 0.04, 0), Color = C.muted, Font = Enum.Font.GothamBold, MaxText = touch and 9 or 12 })
	chips[key] = UI.text(f, "0", { Size = UDim2.new(1, -8, 0.58, 0), Position = UDim2.new(0, 4, 0.38, 0), Color = color, MaxText = touch and 17 or 24 })
end

function Hud.init(gui)
	-- Werte oben
	local top = UI.new("Frame", { Name = "TopBar", BackgroundTransparency = 1, AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.new(0.5, 0, 0, 6),
		Size = UDim2.new(0.66, 0, 0.08, 0), Parent = gui })
	if touch then
		-- ganz nach oben in die Roblox-Leiste, rechts neben die Roblox-Knöpfe
		-- (Höhe der Leiste wird vom Gerät abgefragt, damit nichts abgeschnitten wird)
		local inset = 58
		pcall(function() inset = game:GetService("GuiService"):GetGuiInset().Y end)
		if inset >= 48 then
			local h = math.min(40, inset - 12)
			top.Position = UDim2.new(0.63, 0, 0, -inset + (inset - h) / 2)
			top.Size = UDim2.new(0.56, 0, 0, h)
			UI.new("UISizeConstraint", { MinSize = Vector2.new(280, h), MaxSize = Vector2.new(560, h), Parent = top })
		else
			-- schmale Leiste: direkt darunter, aber klein
			top.Position = UDim2.new(0.5, 0, 0, 2)
			top.Size = UDim2.new(0.56, 0, 0, 34)
			UI.new("UISizeConstraint", { MinSize = Vector2.new(280, 30), MaxSize = Vector2.new(560, 34), Parent = top })
		end
	else
		UI.new("UISizeConstraint", { MinSize = Vector2.new(320, 44), MaxSize = Vector2.new(900, 62), Parent = top })
	end
	UI.list(top, true, touch and 4 or 6, Enum.HorizontalAlignment.Center)
	chip(top, "aura", "✨ AURA", C.gold, 1)
	chip(top, "aps", "⚡ PRO SEK.", C.green, 2)
	chip(top, "cash", "💵 GELD", C.money, 3)
	chip(top, "glow", "💖 GLOW", C.pink, 4)
	chip(top, "reb", "♻️ REBIRTHS", C.cyan, 5)
	chip(top, "gems", "💎 GEMS", C.cyan, 6)

	-- Menü-Knöpfe links
	local side = UI.new("Frame", { Name = "Side", BackgroundTransparency = 1, AnchorPoint = Vector2.new(0, 0.5), Position = UDim2.new(0, 8, 0.5, 0),
		Size = UDim2.new(0.07, 0, 0.84, 0), Parent = gui })
	UI.new("UISizeConstraint", { MinSize = Vector2.new(44, 300), MaxSize = Vector2.new(74, 780), Parent = side })
	UI.list(side, false, 6, Enum.HorizontalAlignment.Center, Enum.VerticalAlignment.Center)
	-- Handy/Tablet: Knöpfe kompakt oben anordnen, damit der Lauf-Joystick unten links frei bleibt
	local function compact(frame, anchorRight)
		local layout = frame:FindFirstChildOfClass("UIListLayout")
		if layout then layout:Destroy() end
		local constraint = frame:FindFirstChildOfClass("UISizeConstraint")
		if constraint then constraint:Destroy() end
		frame.AnchorPoint = Vector2.new(anchorRight and 1 or 0, 0)
		frame.Position = anchorRight and UDim2.new(1, -4, 0, 4) or UDim2.new(0, 4, 0, 4)
		frame.Size = UDim2.new(0, 80, 0.75, 0)
		UI.new("UIGridLayout", { CellSize = UDim2.new(0, 37, 0, 37), CellPadding = UDim2.new(0, 3, 0, 3),
			HorizontalAlignment = anchorRight and Enum.HorizontalAlignment.Right or Enum.HorizontalAlignment.Left,
			SortOrder = Enum.SortOrder.LayoutOrder, Parent = frame })
	end
	if touch then compact(side, false) end
	local buttons = {
		{ "upgrades", "💪", "Upgrades", C.pink }, { "pets", "🐾", "Pets", C.purple }, { "weapons", "⚔️", "Waffen", C.red },
		{ "worlds", "🌍", "Welten", C.cyan }, { "quests", "📋", "Aufträge", C.orange }, { "jobs", "💼", "Jobs", C.money },
		{ "rebirth", "♻️", "Rebirth", C.green }, { "leaderboard", "🏆", "Rangliste", C.gold }, { "rewards", "🎁", "Belohnung", C.pink },
		{ "settings", "⚙️", "Optionen", C.grey },
	}
	for i, b in ipairs(buttons) do
		local btn = UI.new("TextButton", { Text = "", AutoButtonColor = true, BackgroundColor3 = b[4], Size = UDim2.new(1, 0, 1 / 10, -6),
			LayoutOrder = i, Parent = side })
		UI.new("UIAspectRatioConstraint", { AspectRatio = 1, Parent = btn })
		UI.corner(btn, 14)
		UI.stroke(btn, Color3.new(1, 1, 1), 2, 0.6)
		UI.text(btn, b[2], { Size = UDim2.new(1, 0, 0.62, 0), MaxText = touch and 20 or 34 })
		UI.text(btn, b[3], { Size = UDim2.new(1, -4, 0.3, 0), Position = UDim2.new(0, 2, 0.66, 0), MaxText = touch and 8 or 12 })
		btn.Activated:Connect(function()
			Menus.toggle(b[1])
		end)
		if b[1] == "rewards" then
			rewardsDot = UI.panel(btn, { Size = UDim2.new(0, 16, 0, 16), Position = UDim2.new(1, -12, 0, -4), Color = C.red, Radius = 8 })
			rewardsDot.Visible = false
		end
	end

	-- Knöpfe rechts: Shop, Glücksrad, Event, Ausrüstung, Emotes, Fahrzeug
	local right = UI.new("Frame", { Name = "Right", BackgroundTransparency = 1, AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -8, 0.45, 0),
		Size = UDim2.new(0.07, 0, 0.56, 0), Parent = gui })
	UI.new("UISizeConstraint", { MinSize = Vector2.new(44, 220), MaxSize = Vector2.new(74, 520), Parent = right })
	UI.list(right, false, 6, Enum.HorizontalAlignment.Center, Enum.VerticalAlignment.Center)
	if touch then compact(right, true) end
	local rightButtons = {
		{ "shop", "💎", "Shop", C.cyan }, { "wheel", "🎡", "Glücksrad", C.gold }, { "event", "🎉", "Events", C.orange },
		{ "style", "✨", "Style", C.purple }, { "emote", "🕺", "Emotes", C.pink }, { "ride", "🛹", "Fahren (V)", C.green },
	}
	for i, b in ipairs(rightButtons) do
		local btn = UI.new("TextButton", { Text = "", AutoButtonColor = true, BackgroundColor3 = b[4], Size = UDim2.new(1, 0, 1 / 6, -6),
			LayoutOrder = i, Parent = right })
		UI.new("UIAspectRatioConstraint", { AspectRatio = 1, Parent = btn })
		UI.corner(btn, 14)
		UI.stroke(btn, Color3.new(1, 1, 1), 2, 0.6)
		UI.text(btn, b[2], { Size = UDim2.new(1, 0, 0.62, 0), MaxText = touch and 20 or 34 })
		UI.text(btn, b[3], { Size = UDim2.new(1, -4, 0.3, 0), Position = UDim2.new(0, 2, 0.66, 0), MaxText = touch and 8 or 12 })
		btn.Activated:Connect(function()
			if b[1] == "emote" then
				Menus.open("style", "emote")
			elseif b[1] == "ride" then
				Hud.toggleRide()
			else
				Menus.toggle(b[1])
			end
		end)
		if b[1] == "wheel" then
			wheelDot = UI.panel(btn, { Size = UDim2.new(0, 16, 0, 16), Position = UDim2.new(1, -12, 0, -4), Color = C.red, Radius = 8 })
			wheelDot.Visible = false
		elseif b[1] == "event" then
			eventBtn = btn
		elseif b[1] == "ride" then
			rideBtn = btn
		end
	end
	game:GetService("UserInputService").InputBegan:Connect(function(input, processed)
		if not processed and input.KeyCode == Enum.KeyCode.V then
			Hud.toggleRide()
		end
	end)

	-- Stoppuhr fürs Laufrennen
	raceLabel = UI.text(gui, "", { AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.new(0.5, 0, 0.21, 0), Size = UDim2.new(0, 260, 0, 46),
		Color = C.gold, MaxText = 36 })
	raceLabel.TextStrokeTransparency = 0.2
	raceLabel.Visible = false
	game:GetService("RunService").Heartbeat:Connect(function()
		local start = game:GetService("Players").LocalPlayer:GetAttribute("RaceStart")
		if start then
			raceLabel.Visible = true
			raceLabel.Text = "⏱️ " .. string.format("%.2f", workspace:GetServerTimeNow() - start) .. " s"
		else
			raceLabel.Visible = false
		end
	end)

	-- Unten: Titel, Fortschritt, Daily Routine
	local bottom = UI.new("Frame", { Name = "Bottom", BackgroundTransparency = 1, AnchorPoint = Vector2.new(0.5, 1), Position = UDim2.new(0.5, 0, 1, -10),
		Size = UDim2.new(0.3, 0, 0.22, 0), Parent = gui })
	if touch then
		bottom.Size = UDim2.new(0.26, 0, 0.24, 0)
		bottom.Position = UDim2.new(0.5, 0, 1, -6)
		UI.new("UISizeConstraint", { MinSize = Vector2.new(190, 92), MaxSize = Vector2.new(300, 124), Parent = bottom })
	else
		UI.new("UISizeConstraint", { MinSize = Vector2.new(240, 130), MaxSize = Vector2.new(420, 190), Parent = bottom })
	end
	-- Solange ein Menü (z. B. Upgrades) offen ist, verschwindet die Daily Routine, damit man mehr sieht
	Menus.onVisibility(function(open)
		bottom.Visible = not open
	end)
	if touch then
		-- liegt eine Waffe im Rucksack, zeigt Roblox unten die Werkzeugleiste → Knopf etwas höher
		local plr = game:GetService("Players").LocalPlayer
		local function fitAboveHotbar()
			local bp = plr:FindFirstChildOfClass("Backpack")
			local char = plr.Character
			local hasTool = (bp and #bp:GetChildren() > 0) or (char and char:FindFirstChildOfClass("Tool") ~= nil)
			bottom.Position = UDim2.new(0.5, 0, 1, hasTool and -62 or -6)
		end
		task.spawn(function()
			while true do
				fitAboveHotbar()
				task.wait(1)
			end
		end)
	end
	titleLabel = UI.text(bottom, "NPC", { Size = UDim2.new(1, 0, 0.18, 0), Color = C.pink, MaxText = 24 })
	titleLabel.TextStrokeTransparency = 0.4
	local barBg = UI.panel(bottom, { Size = UDim2.new(1, 0, 0.07, 0), Position = UDim2.new(0, 0, 0.2, 0), Color = C.dark, Radius = 6 })
	progressBar = UI.panel(barBg, { Size = UDim2.new(0, 0, 1, 0), Color = C.pink, Radius = 6 })
	UI.gradient(progressBar, C.pink, C.gold, 0)
	nextLabel = UI.text(bottom, "", { Size = UDim2.new(1, 0, 0.12, 0), Position = UDim2.new(0, 0, 0.28, 0), Color = C.muted, Font = Enum.Font.GothamBold, MaxText = 14 })
	nextLabel.TextStrokeTransparency = 0.5

	routineBtn = UI.new("TextButton", { Name = "Routine", Text = "", AutoButtonColor = true, BackgroundColor3 = C.pink,
		Size = UDim2.new(1, 0, 0.56, 0), Position = UDim2.new(0, 0, 0.44, 0), Parent = bottom })
	UI.corner(routineBtn, 18)
	UI.gradient(routineBtn, C.pink, C.cyan, 0)
	UI.stroke(routineBtn, Color3.new(1, 1, 1), 3, 0.3)
	local scale = UI.new("UIScale", { Parent = routineBtn })
	UI.text(routineBtn, "🪞 DAILY ROUTINE", { Size = UDim2.new(1, 0, 0.58, 0), Position = UDim2.new(0, 0, 0.06, 0), MaxText = 34 })
	routineSub = UI.text(routineBtn, "+1 Aura", { Size = UDim2.new(1, 0, 0.32, 0), Position = UDim2.new(0, 0, 0.62, 0), Font = Enum.Font.GothamBold, MaxText = 18 })

	routineBtn.Activated:Connect(function()
		local s = State.snap
		if not s then return end
		Remotes.Click:FireServer()
		s.data.aura = s.data.aura + s.click      -- sofort anzeigen
		State.bump()
		local pos = routineBtn.AbsolutePosition
		local size = routineBtn.AbsoluteSize
		Effects.floatText("+" .. Util.format(s.click), UDim2.new(0, pos.X + size.X * (0.3 + math.random() * 0.4), 0, pos.Y), C.gold)
		scale.Scale = 0.93
		TweenService:Create(scale, TweenInfo.new(0.15, Enum.EasingStyle.Back), { Scale = 1 }):Play()
	end)

	-- Lebensbalken: Selbstbewusstsein & Boss
	local bars = UI.new("Frame", { Name = "Bars", BackgroundTransparency = 1, AnchorPoint = Vector2.new(0.5, 0), Position = touch and UDim2.new(0.5, 0, 0, 4) or UDim2.new(0.5, 0, 0.11, 6),
		Size = UDim2.new(0.42, 0, 0.09, 0), Parent = gui })
	UI.new("UISizeConstraint", { MinSize = Vector2.new(260, 56), MaxSize = Vector2.new(560, 80), Parent = bars })
	local bossBg = UI.panel(bars, { Size = UDim2.new(1, 0, 0.5, -2), Color = C.dark, Radius = 8 })
	local bossFill = UI.panel(bossBg, { Size = UDim2.new(1, 0, 1, 0), Color = C.red, Radius = 8 })
	local bossText = UI.text(bossBg, "", { MaxText = 16 })
	bossText.TextStrokeTransparency = 0.3
	local confBg = UI.panel(bars, { Size = UDim2.new(0.7, 0, 0.42, 0), Position = UDim2.new(0.15, 0, 0.56, 0), Color = C.dark, Radius = 8 })
	local confFill = UI.panel(confBg, { Size = UDim2.new(1, 0, 1, 0), Color = C.green, Radius = 8 })
	local confText = UI.text(confBg, "", { MaxText = 14 })
	confText.TextStrokeTransparency = 0.3
	bossBg.Visible = false
	confBg.Visible = false

	local Players = game:GetService("Players")
	local player = Players.LocalPlayer
	task.spawn(function()
		while true do
			task.wait(0.15)
			local char = player.Character
			local hrp = char and char:FindFirstChild("HumanoidRootPart")
			local nearest, nd = nil, 90
			local npcs = workspace:FindFirstChild("NPCs")
			if hrp and npcs then
				for _, m in ipairs(npcs:GetChildren()) do
					local maxHp = m:GetAttribute("MaxHP")
					local root = maxHp and m:FindFirstChild("HumanoidRootPart")
					if root then
						local d = (root.Position - hrp.Position).Magnitude
						if d < nd then nearest, nd = m, d end
					end
				end
			end
			if nearest then
				local hp, maxHp = nearest:GetAttribute("HP") or 0, nearest:GetAttribute("MaxHP") or 1
				bossBg.Visible = true
				bossFill.Size = UDim2.new(math.clamp(hp / maxHp, 0, 1), 0, 1, 0)
				bossText.Text = "👑 " .. nearest.Name .. "  ❤️ " .. Util.format(math.max(0, hp)) .. " / " .. Util.format(maxHp)
			else
				bossBg.Visible = false
			end
			local conf, maxConf = player:GetAttribute("Conf"), player:GetAttribute("MaxConf")
			if conf and maxConf and (nearest or conf < maxConf) then
				confBg.Visible = true
				local r = math.clamp(conf / maxConf, 0, 1)
				confFill.Size = UDim2.new(r, 0, 1, 0)
				confFill.BackgroundColor3 = r > 0.5 and C.green or (r > 0.25 and C.gold or C.red)
				confText.Text = "😎 Selbstbewusstsein " .. Util.format(conf) .. " / " .. Util.format(maxConf)
			else
				confBg.Visible = false
			end
		end
	end)

	State.onChange(Hud.update)
end

function Hud.toggleRide()
	local s = State.snap
	if not s then return end
	if s.data.vehicle == "" then
		Effects.toast("🛹 Kein Fahrzeug", "Kauf dir im Menü ✨ Style → Fahrzeuge ein Skateboard, Auto oder Hoverboard!", "")
		Menus.open("style", "vehicle")
		return
	end
	Remotes.ToggleRide:FireServer()
end

function Hud.update()
	local s = State.snap
	if not s then return end
	local d = s.data
	chips.aura.Text = Util.format(d.aura)
	chips.aps.Text = Util.format(s.aps)
	chips.cash.Text = Util.format(d.cash)
	chips.glow.Text = Util.format(s.glow)
	chips.reb.Text = tostring(d.rebirths)
	chips.gems.Text = Util.format(d.gems)
	if wheelDot then
		wheelDot.Visible = d.wheel.spins > 0 or os.time() - d.wheel.last >= Config.WHEEL_COOLDOWN
	end
	if eventBtn then
		local now = os.time()
		eventBtn.BackgroundColor3 = (Logic.activeEvent(now) or Logic.isWeekend(now)) and C.orange or C.grey
	end
	if rideBtn then
		local riding = game:GetService("Players").LocalPlayer:GetAttribute("Riding") == true
		rideBtn.BackgroundColor3 = riding and C.gold or C.green
	end
	routineSub.Text = "+" .. Util.format(s.click) .. " Aura pro Klick"

	local idx = Logic.titleIndex(s.glow)
	titleLabel.Text = "🏷️ " .. Config.Titles[idx].title
	local nextT = Config.Titles[idx + 1]
	if nextT then
		local prev = Config.Titles[idx].glow
		progressBar.Size = UDim2.new(math.clamp((s.glow - prev) / (nextT.glow - prev), 0, 1), 0, 1, 0)
		nextLabel.Text = "Nächster Titel: " .. nextT.title .. " (" .. Util.format(s.glow) .. "/" .. Util.format(nextT.glow) .. " Glow)"
	else
		progressBar.Size = UDim2.new(1, 0, 1, 0)
		nextLabel.Text = "Höchster Titel erreicht!"
	end
	if rewardsDot then
		rewardsDot.Visible = Menus.dailyReady()
	end
end

return Hud
