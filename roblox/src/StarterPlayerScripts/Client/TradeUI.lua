--[[
	TRADEUI – das Handelsfenster.
	Links: dein Angebot + deine Pets (antippen = hinzufügen/entfernen) + Geld.
	Rechts: was der andere anbietet.
	Unten: Bereit → Bestätigen (beide müssen zustimmen) oder Abbrechen.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config"))
local Logic = require(Shared:WaitForChild("Logic"))
local Util = require(Shared:WaitForChild("Util"))
local Remotes = ReplicatedStorage:WaitForChild("Remotes")
local UI = require(script.Parent:WaitForChild("UI"))
local State = require(script.Parent:WaitForChild("State"))
local Effects = require(script.Parent:WaitForChild("Effects"))

local TradeUI = {}
local C = UI.C
local gui
local window = nil
local current = nil      -- letzter Stand vom Server

local function petCell(parent, pet, order, onClick, highlight)
	local def = Logic.petById[pet.id]
	if not def then return end
	local rarity = Config.Rarities[def.rarity]
	local tier = Config.PetTiers[pet.tier or 1]
	local cell = UI.new("TextButton", { Text = "", AutoButtonColor = onClick ~= nil, BackgroundColor3 = rarity.color:Lerp(Color3.new(0, 0, 0), 0.6),
		LayoutOrder = order, Parent = parent })
	UI.corner(cell, 8)
	UI.stroke(cell, highlight and C.gold or (tier.color or rarity.color), highlight and 3 or 1.5, 0)
	UI.text(cell, def.emoji, { Size = UDim2.new(1, 0, 0.6, 0), MaxText = 30 })
	UI.text(cell, Util.formatPercent(Logic.petBoost(pet)), { Size = UDim2.new(1, -2, 0.36, 0), Position = UDim2.new(0, 1, 0.62, 0), Color = C.green, MaxText = 11 })
	if onClick then cell.Activated:Connect(onClick) end
	return cell
end

local function grid(parent, props)
	local s = UI.scroll(parent, props)
	UI.new("UIGridLayout", { CellSize = UDim2.new(0, 58, 0, 64), CellPadding = UDim2.new(0, 5, 0, 5), SortOrder = Enum.SortOrder.LayoutOrder, Parent = s })
	return s
end

local function totalBoost(pets)
	local t = 0
	for _, p in ipairs(pets) do t = t + Logic.petBoost(p) end
	return t
end

local function sendOffer(petUids, cash)
	Remotes.TradeOffer:FireServer(petUids, cash)
end

local function render()
	if not current then return end
	if not window then
		window = UI.panel(gui, { AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.new(0.5, 0, 0.53, 0), Size = UDim2.new(0.7, 0, 0.78, 0), Color = C.bg })
		window.Active = true
		UI.new("UISizeConstraint", { MinSize = Vector2.new(340, 340), MaxSize = Vector2.new(900, 600), Parent = window })
		UI.stroke(window, C.cyan, 3, 0)
		UI.padding(window, 10)
	end
	for _, c in ipairs(window:GetChildren()) do
		if c:IsA("GuiObject") then c:Destroy() end
	end
	local s = current
	local myPetsSelected = {}
	for _, p in ipairs(s.mine.pets) do myPetsSelected[p.uid] = true end

	UI.text(window, "<b>🤝 Handel mit " .. s.otherName .. "</b>", { Size = UDim2.new(1, 0, 0.07, 0), MaxText = 24 })
	UI.text(window, "⚠️ Prüfe genau, was du bekommst! Jede Änderung setzt Bereit & Bestätigen zurück.", { Size = UDim2.new(1, 0, 0.045, 0),
		Position = UDim2.new(0, 0, 0.07, 0), Color = C.gold, Font = Enum.Font.GothamBold, MaxText = 13 })

	-- Linke Seite: dein Angebot
	local left = UI.panel(window, { Size = UDim2.new(0.49, 0, 0.36, 0), Position = UDim2.new(0, 0, 0.12, 0), Color = C.panel })
	UI.padding(left, 6)
	UI.text(left, "Dein Angebot " .. (s.myReady and "✅" or "") .. "  <font color='" .. UI.hex(C.green) .. "'>" .. Util.formatPercent(totalBoost(s.mine.pets)) .. "</font>",
		{ Size = UDim2.new(1, 0, 0.18, 0), XAlign = Enum.TextXAlignment.Left, MaxText = 16 })
	local myOffer = grid(left, { Size = UDim2.new(1, 0, 0.58, 0), Position = UDim2.new(0, 0, 0.2, 0) })
	for i, p in ipairs(s.mine.pets) do
		petCell(myOffer, p, i, function()
			local list = {}
			for _, q in ipairs(s.mine.pets) do
				if q.uid ~= p.uid then table.insert(list, q.uid) end
			end
			sendOffer(list, s.mine.cash)
		end, true)
	end
	UI.text(left, "💵", { Size = UDim2.new(0, 26, 0.2, 0), Position = UDim2.new(0, 0, 0.8, 0), MaxText = 18 })
	local cashBox = UI.new("TextBox", { Size = UDim2.new(1, -30, 0.2, 0), Position = UDim2.new(0, 28, 0.8, 0), BackgroundColor3 = C.dark, TextColor3 = C.text,
		Text = tostring(s.mine.cash), PlaceholderText = "Geld anbieten", ClearTextOnFocus = false, TextScaled = true, Font = Enum.Font.GothamBold, Parent = left })
	UI.corner(cashBox, 6)
	cashBox.FocusLost:Connect(function()
		local value = math.max(0, math.floor(tonumber(cashBox.Text) or 0))
		if value == s.mine.cash then
			cashBox.Text = tostring(s.mine.cash)
			return
		end
		local list = {}
		for _, q in ipairs(s.mine.pets) do table.insert(list, q.uid) end
		sendOffer(list, value)
	end)

	-- Rechte Seite: Angebot des anderen
	local right = UI.panel(window, { Size = UDim2.new(0.49, 0, 0.36, 0), Position = UDim2.new(0.51, 0, 0.12, 0), Color = C.panel })
	UI.padding(right, 6)
	UI.text(right, s.otherName .. " bietet " .. (s.theirReady and "✅" or "") .. "  <font color='" .. UI.hex(C.green) .. "'>" .. Util.formatPercent(totalBoost(s.theirs.pets)) .. "</font>",
		{ Size = UDim2.new(1, 0, 0.18, 0), XAlign = Enum.TextXAlignment.Left, MaxText = 16 })
	local theirOffer = grid(right, { Size = UDim2.new(1, 0, 0.58, 0), Position = UDim2.new(0, 0, 0.2, 0) })
	for i, p in ipairs(s.theirs.pets) do
		petCell(theirOffer, p, i, nil, false)
	end
	UI.text(right, "💵 " .. Util.format(s.theirs.cash) .. " Geld", { Size = UDim2.new(1, 0, 0.2, 0), Position = UDim2.new(0, 0, 0.8, 0), Color = C.money,
		XAlign = Enum.TextXAlignment.Left, MaxText = 16 })

	-- Deine Pets zum Auswählen
	UI.text(window, "Deine Pets – antippen zum Anbieten (max. " .. Config.TRADE_MAX_PETS .. "):", { Size = UDim2.new(1, 0, 0.045, 0), Position = UDim2.new(0, 0, 0.49, 0),
		XAlign = Enum.TextXAlignment.Left, Font = Enum.Font.GothamBold, Color = C.muted, MaxText = 14 })
	local inv = grid(window, { Size = UDim2.new(1, 0, 0.3, 0), Position = UDim2.new(0, 0, 0.54, 0) })
	local d = State.snap and State.snap.data
	if d then
		local sorted = Util.copy(d.pets)
		table.sort(sorted, function(a, b) return Logic.petBoost(a) > Logic.petBoost(b) end)
		for i, p in ipairs(sorted) do
			if not myPetsSelected[p.uid] then
				petCell(inv, p, i, function()
					if #s.mine.pets >= Config.TRADE_MAX_PETS then return end
					local list = {}
					for _, q in ipairs(s.mine.pets) do table.insert(list, q.uid) end
					table.insert(list, p.uid)
					sendOffer(list, s.mine.cash)
				end, false)
			end
		end
	end

	-- Knöpfe
	local bothReady = s.myReady and s.theirReady
	UI.button(window, s.myReady and "❎ Doch nicht bereit" or "✅ Bereit", s.myReady and C.grey or C.green, function()
		Remotes.TradeReady:FireServer(not s.myReady)
	end, { Size = UDim2.new(0.32, 0, 0.1, 0), Position = UDim2.new(0, 0, 0.88, 0), TextColor = C.dark, MaxText = 18 })
	local confirmText = s.myConfirm and "⏳ Warte auf " .. s.otherName or (bothReady and "🤝 Bestätigen" or "Beide müssen bereit sein")
	UI.button(window, confirmText, (bothReady and not s.myConfirm) and C.gold or C.grey, function()
		if bothReady and not s.myConfirm then Remotes.TradeConfirm:FireServer() end
	end, { Size = UDim2.new(0.34, 0, 0.1, 0), Position = UDim2.new(0.33, 0, 0.88, 0), TextColor = C.dark, MaxText = 16 })
	UI.button(window, "❌ Abbrechen", C.red, function()
		Remotes.TradeCancel:FireServer()
	end, { Size = UDim2.new(0.32, 0, 0.1, 0), Position = UDim2.new(0.68, 0, 0.88, 0), MaxText = 18 })
end

function TradeUI.init(mainGui)
	gui = mainGui
	Remotes:WaitForChild("TradeRequest").OnClientEvent:Connect(function(name, userId)
		Effects.requestPopup("🤝 <b>" .. name .. "</b> möchte mit dir handeln!", C.cyan, function(ok)
			Remotes.TradeRespond:FireServer(ok, userId)
		end)
	end)
	Remotes:WaitForChild("TradeUpdate").OnClientEvent:Connect(function(state)
		current = state
		render()
	end)
	Remotes:WaitForChild("TradeClosed").OnClientEvent:Connect(function(reason)
		current = nil
		if window then
			window:Destroy()
			window = nil
		end
		if reason ~= "done" then
			Effects.toast("🤝 Handel beendet", reason or "", "")
		end
	end)
	-- eigenes Inventar ändert sich → Fenster neu zeichnen
	State.onChange(function(kind)
		if kind == "full" and current then render() end
	end)
end

return TradeUI
