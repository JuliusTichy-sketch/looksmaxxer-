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

local function chip(parent, key, caption, color, order)
	local f = UI.panel(parent, { Size = UDim2.new(0.19, 0, 1, 0), Color = C.dark, Transparency = 0.15, LayoutOrder = order })
	UI.stroke(f, color, 2, 0.3)
	UI.text(f, caption, { Size = UDim2.new(1, 0, 0.34, 0), Position = UDim2.new(0, 0, 0.04, 0), Color = C.muted, Font = Enum.Font.GothamBold, MaxText = 12 })
	chips[key] = UI.text(f, "0", { Size = UDim2.new(1, -8, 0.58, 0), Position = UDim2.new(0, 4, 0.38, 0), Color = color, MaxText = 24 })
end

function Hud.init(gui)
	-- Werte oben
	local top = UI.new("Frame", { Name = "TopBar", BackgroundTransparency = 1, AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.new(0.5, 0, 0, 6),
		Size = UDim2.new(0.66, 0, 0.08, 0), Parent = gui })
	UI.new("UISizeConstraint", { MinSize = Vector2.new(320, 44), MaxSize = Vector2.new(900, 62), Parent = top })
	UI.list(top, true, 6, Enum.HorizontalAlignment.Center)
	chip(top, "aura", "✨ AURA", C.gold, 1)
	chip(top, "aps", "⚡ PRO SEK.", C.green, 2)
	chip(top, "cash", "💵 GELD", C.money, 3)
	chip(top, "glow", "💖 GLOW", C.pink, 4)
	chip(top, "reb", "♻️ REBIRTHS", C.cyan, 5)

	-- Menü-Knöpfe links
	local side = UI.new("Frame", { Name = "Side", BackgroundTransparency = 1, AnchorPoint = Vector2.new(0, 0.5), Position = UDim2.new(0, 8, 0.5, 0),
		Size = UDim2.new(0.075, 0, 0.7, 0), Parent = gui })
	UI.new("UISizeConstraint", { MinSize = Vector2.new(50, 300), MaxSize = Vector2.new(82, 640), Parent = side })
	UI.list(side, false, 6, Enum.HorizontalAlignment.Center, Enum.VerticalAlignment.Center)
	local buttons = {
		{ "upgrades", "💪", "Upgrades", C.pink }, { "pets", "🐾", "Pets", C.purple }, { "worlds", "🌍", "Welten", C.cyan },
		{ "rebirth", "♻️", "Rebirth", C.green }, { "leaderboard", "🏆", "Rangliste", C.gold }, { "rewards", "🎁", "Belohnung", C.orange },
		{ "settings", "⚙️", "Optionen", C.grey },
	}
	for i, b in ipairs(buttons) do
		local btn = UI.new("TextButton", { Text = "", AutoButtonColor = true, BackgroundColor3 = b[4], Size = UDim2.new(1, 0, 1 / 7, -6),
			LayoutOrder = i, Parent = side })
		UI.new("UIAspectRatioConstraint", { AspectRatio = 1, Parent = btn })
		UI.corner(btn, 14)
		UI.stroke(btn, Color3.new(1, 1, 1), 2, 0.6)
		UI.text(btn, b[2], { Size = UDim2.new(1, 0, 0.62, 0), MaxText = 34 })
		UI.text(btn, b[3], { Size = UDim2.new(1, -4, 0.3, 0), Position = UDim2.new(0, 2, 0.66, 0), MaxText = 12 })
		btn.Activated:Connect(function()
			Menus.toggle(b[1])
		end)
		if b[1] == "rewards" then
			rewardsDot = UI.panel(btn, { Size = UDim2.new(0, 16, 0, 16), Position = UDim2.new(1, -12, 0, -4), Color = C.red, Radius = 8 })
			rewardsDot.Visible = false
		end
	end

	-- Unten: Titel, Fortschritt, Daily Routine
	local bottom = UI.new("Frame", { Name = "Bottom", BackgroundTransparency = 1, AnchorPoint = Vector2.new(0.5, 1), Position = UDim2.new(0.5, 0, 1, -10),
		Size = UDim2.new(0.3, 0, 0.22, 0), Parent = gui })
	UI.new("UISizeConstraint", { MinSize = Vector2.new(240, 130), MaxSize = Vector2.new(420, 190), Parent = bottom })
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
		Sounds.play("Click")
		local pos = routineBtn.AbsolutePosition
		local size = routineBtn.AbsoluteSize
		Effects.floatText("+" .. Util.format(s.click), UDim2.new(0, pos.X + size.X * (0.3 + math.random() * 0.4), 0, pos.Y), C.gold)
		scale.Scale = 0.93
		TweenService:Create(scale, TweenInfo.new(0.15, Enum.EasingStyle.Back), { Scale = 1 }):Play()
	end)

	State.onChange(Hud.update)
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
