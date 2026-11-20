--[[
	MENUS – alle Menüfenster:
	💪 Upgrades · 🐾 Pets · 🌍 Welten · ♻️ Rebirth · 🏆 Rangliste · 🎁 Belohnungen · ⚙️ Einstellungen
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
local Sounds = require(script.Parent:WaitForChild("Sounds"))
local Effects = require(script.Parent:WaitForChild("Effects"))
local CameraController = require(script.Parent:WaitForChild("CameraController"))
local UserInputService = game:GetService("UserInputService")

local Menus = {}
local window, titleLabel, content
local current = nil        -- Name des offenen Menüs
local refreshFn = nil      -- Aktualisierungsfunktion des offenen Menüs
local C = UI.C

local function snap() return State.snap end
local function data() return State.snap and State.snap.data end

----------------------------------------------------------------------------
-- Fenster
----------------------------------------------------------------------------
function Menus.init(gui)
	window = UI.panel(gui, { Name = "Window", AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.new(0.5, 0, 0.52, 0),
		Size = UDim2.new(0.62, 0, 0.74, 0), Color = C.bg, Transparency = 0.03 })
	window.Visible = false
	window.Active = true   -- Ziehen über dem Menü dreht nicht die Kamera
	UI.new("UISizeConstraint", { MinSize = Vector2.new(330, 300), MaxSize = Vector2.new(880, 620), Parent = window })
	UI.stroke(window, C.pink, 2, 0.2)
	local header = UI.panel(window, { Size = UDim2.new(1, 0, 0, 48), Color = C.panel })
	UI.gradient(header, C.pink, C.purple, 0)
	titleLabel = UI.text(header, "", { Size = UDim2.new(1, -60, 1, -8), Position = UDim2.new(0, 14, 0, 4), XAlign = Enum.TextXAlignment.Left, MaxText = 26 })
	UI.button(header, "✕", C.dark, function() Menus.close() end, { Size = UDim2.new(0, 38, 0, 38), Position = UDim2.new(1, -44, 0, 5), MaxText = 22 })
	content = UI.new("Frame", { Name = "Content", BackgroundTransparency = 1, Position = UDim2.new(0, 10, 0, 56),
		Size = UDim2.new(1, -20, 1, -64), Parent = window })

	State.onChange(function(kind)
		if refreshFn and window.Visible then
			refreshFn(kind)
		end
	end)
end

local BUILDERS = {}
local TITLES = {
	upgrades = "💪 Upgrades", pets = "🐾 Pets", worlds = "🌍 Welten", rebirth = "♻️ Rebirth",
	leaderboard = "🏆 Globale Rangliste", rewards = "🎁 Belohnungen", settings = "⚙️ Einstellungen",
}

function Menus.open(name)
	if not BUILDERS[name] or not State.snap then return end
	UI.clear(content)
	for _, c in ipairs(content:GetChildren()) do c:Destroy() end
	current = name
	titleLabel.Text = TITLES[name]
	window.Visible = true
	refreshFn = BUILDERS[name](content)
	if refreshFn then refreshFn("full") end
end

function Menus.close()
	window.Visible = false
	current = nil
	refreshFn = nil
end

function Menus.toggle(name)
	if current == name and window.Visible then
		Menus.close()
	else
		Menus.open(name)
	end
end

----------------------------------------------------------------------------
-- 💪 UPGRADES
----------------------------------------------------------------------------
local upgradeTab = "skin"
local buyAmount = 1

BUILDERS.upgrades = function(root)
	local tabs = UI.scroll(root, { Size = UDim2.new(1, 0, 0, 40), Horizontal = true })
	UI.list(tabs, true, 6)
	local amountRow = UI.new("Frame", { BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 34), Position = UDim2.new(0, 0, 0, 46), Parent = root })
	UI.list(amountRow, true, 6, Enum.HorizontalAlignment.Right)
	local list = UI.scroll(root, { Size = UDim2.new(1, 0, 1, -86), Position = UDim2.new(0, 0, 0, 86) })
	UI.list(list, false, 6)
	UI.padding(list, 2)

	local rows = {}
	local tabButtons = {}
	local amountButtons = {}

	local function buildRows()
		UI.clear(list)
		rows = {}
		local order = 0
		for _, u in ipairs(Config.Upgrades) do
			if u.cat == upgradeTab then
				order = order + 1
				local row = UI.panel(list, { Size = UDim2.new(1, -10, 0, 76), Color = C.panel2, LayoutOrder = order })
				UI.text(row, u.emoji, { Size = UDim2.new(0, 56, 1, 0), MaxText = 40 })
				local name = UI.text(row, "", { Size = UDim2.new(1, -200, 0.38, 0), Position = UDim2.new(0, 60, 0.04, 0), XAlign = Enum.TextXAlignment.Left, MaxText = 20 })
				local desc = UI.text(row, u.desc, { Size = UDim2.new(1, -200, 0.3, 0), Position = UDim2.new(0, 60, 0.4, 0), XAlign = Enum.TextXAlignment.Left,
					Font = Enum.Font.Gotham, Color = C.muted, MaxText = 14 })
				local parts = {}
				if u.aps > 0 then table.insert(parts, "+" .. Util.format(u.aps) .. " Aura/s") end
				if u.click > 0 then table.insert(parts, "+" .. Util.format(u.click) .. " pro Klick") end
				table.insert(parts, "+" .. u.glow .. " Glow")
				UI.text(row, table.concat(parts, " · ") .. " je Stufe", { Size = UDim2.new(1, -200, 0.26, 0), Position = UDim2.new(0, 60, 0.7, 0),
					XAlign = Enum.TextXAlignment.Left, Font = Enum.Font.GothamBold, Color = C.green, MaxText = 13 })
				local btn = UI.button(row, "", C.gold, function()
					Remotes.BuyUpgrade:FireServer(u.id, buyAmount)
					Sounds.play("Buy")
				end, { AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -8, 0.5, 0), Size = UDim2.new(0, 128, 0, 54), TextColor = C.dark, MaxText = 18 })
				rows[u.id] = { name = name, btn = btn, u = u, desc = desc }
			end
		end
	end

	local function update()
		local d = data()
		for id, r in pairs(rows) do
			local level = Logic.level(d, id)
			r.name.Text = r.u.name .. "  <font color='" .. UI.hex(C.cyan) .. "' size='14'>Stufe " .. level .. "/" .. Config.MAX_LEVEL .. "</font>"
			if level >= Config.MAX_LEVEL then
				r.btn.Text = "✅ MAX"
				r.btn.BackgroundColor3 = C.grey
				r.btn.TextColor3 = C.text
			else
				local count, cost = Logic.bulk(r.u, level, buyAmount, d.aura)
				local affordable = cost <= d.aura
				r.btn.Text = Util.format(cost) .. " ✨\n<font size='12'>" .. (count > 1 and (count .. " Stufen") or "kaufen") .. "</font>"
				r.btn.BackgroundColor3 = affordable and C.gold or C.grey
				r.btn.TextColor3 = affordable and C.dark or C.muted
			end
		end
		for id, b in pairs(tabButtons) do
			b.BackgroundColor3 = (id == upgradeTab) and C.pink or C.panel2
		end
		for amt, b in pairs(amountButtons) do
			b.BackgroundColor3 = (tostring(buyAmount) == amt) and C.cyan or C.panel2
			b.TextColor3 = (tostring(buyAmount) == amt) and C.dark or C.text
		end
	end

	for i, cat in ipairs(Config.Categories) do
		tabButtons[cat.id] = UI.button(tabs, cat.emoji .. " " .. cat.name, C.panel2, function()
			upgradeTab = cat.id
			buildRows()
			update()
		end, { Size = UDim2.new(0, 150, 1, -6), LayoutOrder = i, MaxText = 16 })
	end
	UI.text(amountRow, "Menge:", { Size = UDim2.new(0, 70, 1, 0), LayoutOrder = 0, MaxText = 16, Color = C.muted })
	for i, amt in ipairs({ "1", "10", "max" }) do
		amountButtons[amt] = UI.button(amountRow, amt == "max" and "Max" or ("x" .. amt), C.panel2, function()
			buyAmount = (amt == "max") and "max" or tonumber(amt)
			update()
		end, { Size = UDim2.new(0, 64, 1, 0), LayoutOrder = i, MaxText = 16 })
	end

	buildRows()
	return function()
		update()
	end
end

----------------------------------------------------------------------------
-- 🐾 PETS
----------------------------------------------------------------------------
local selectedPet = nil

BUILDERS.pets = function(root)
	local info = UI.text(root, "", { Size = UDim2.new(0.7, 0, 0, 30), XAlign = Enum.TextXAlignment.Left, Font = Enum.Font.GothamBold, MaxText = 16 })
	UI.button(root, "⭐ Beste ausrüsten", C.pink, function()
		Remotes.EquipBest:FireServer()
	end, { AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, 0, 0, 0), Size = UDim2.new(0.28, 0, 0, 32), MaxText = 16 })
	local grid = UI.scroll(root, { Size = UDim2.new(0.6, -6, 1, -42), Position = UDim2.new(0, 0, 0, 42) })
	UI.new("UIGridLayout", { CellSize = UDim2.new(0, 86, 0, 104), CellPadding = UDim2.new(0, 6, 0, 6), SortOrder = Enum.SortOrder.LayoutOrder, Parent = grid })
	local detail = UI.panel(root, { Size = UDim2.new(0.4, -6, 1, -42), Position = UDim2.new(0.6, 6, 0, 42), Color = C.panel })
	UI.padding(detail, 10)

	local function showDetail()
		UI.clear(detail)
		local d = data()
		local pet = nil
		for _, p in ipairs(d.pets) do
			if p.uid == selectedPet then pet = p end
		end
		if not pet then
			UI.text(detail, "👈 Wähle ein Pet aus.\n\nPets folgen dir und geben dir Aura-Boosts. Öffne Geschenkboxen in jeder Welt, um neue zu finden!",
				{ Font = Enum.Font.GothamBold, Color = C.muted, MaxText = 16 })
			return
		end
		local def = Logic.petById[pet.id]
		local rarity = Config.Rarities[def.rarity]
		local tier = Config.PetTiers[pet.tier]
		UI.text(detail, def.emoji, { Size = UDim2.new(1, 0, 0.26, 0), MaxText = 80 })
		UI.text(detail, def.name, { Size = UDim2.new(1, 0, 0.09, 0), Position = UDim2.new(0, 0, 0.27, 0), MaxText = 22 })
		UI.text(detail, rarity.name .. (pet.tier > 1 and (" · " .. tier.name) or ""), { Size = UDim2.new(1, 0, 0.07, 0), Position = UDim2.new(0, 0, 0.36, 0),
			Color = tier.color or rarity.color, MaxText = 18 })
		UI.text(detail, Util.formatPercent(Logic.petBoost(pet)) .. " Aura", { Size = UDim2.new(1, 0, 0.07, 0), Position = UDim2.new(0, 0, 0.43, 0),
			Color = C.green, MaxText = 20 })
		local same = 0
		for _, p in ipairs(d.pets) do
			if p.id == pet.id and p.tier == pet.tier then same = same + 1 end
		end
		UI.button(detail, pet.eq and "Ablegen" or "Ausrüsten", pet.eq and C.grey or C.green, function()
			Remotes.EquipPet:FireServer(pet.uid, not pet.eq)
		end, { Size = UDim2.new(1, 0, 0.12, 0), Position = UDim2.new(0, 0, 0.53, 0), TextColor = pet.eq and C.text or C.dark })
		if pet.tier < #Config.PetTiers then
			local nextTier = Config.PetTiers[pet.tier + 1]
			UI.button(detail, "🔮 Fusionieren (" .. same .. "/" .. Config.FUSE_COUNT .. ") → " .. nextTier.name, same >= Config.FUSE_COUNT and C.purple or C.grey, function()
				Remotes.FusePet:FireServer(pet.uid)
			end, { Size = UDim2.new(1, 0, 0.12, 0), Position = UDim2.new(0, 0, 0.67, 0), MaxText = 16 })
		end
		UI.button(detail, "🗑️ Löschen", C.red, function()
			Effects.confirm("Pet löschen?", def.emoji .. " " .. def.name .. " wirklich löschen? Das kann man nicht rückgängig machen.", "Löschen", function()
				Remotes.DeletePet:FireServer(pet.uid)
				selectedPet = nil
			end)
		end, { Size = UDim2.new(1, 0, 0.12, 0), Position = UDim2.new(0, 0, 0.81, 0) })
	end

	local function build()
		local s, d = snap(), data()
		local indexCount = 0
		for _ in pairs(d.index) do indexCount = indexCount + 1 end
		info.Text = "🐾 Ausgerüstet " .. Logic.equippedCount(d) .. "/" .. s.petSlots .. "  ·  🎒 " .. #d.pets .. "/" .. Config.MAX_PET_INVENTORY
			.. "  ·  Boost " .. Util.formatMult(s.petMult) .. "  ·  📖 " .. indexCount .. "/" .. #Config.Pets
		UI.clear(grid)
		local sorted = Util.copy(d.pets)
		table.sort(sorted, function(a, b)
			if a.eq ~= b.eq then return a.eq end
			return Logic.petBoost(a) > Logic.petBoost(b)
		end)
		for i, pet in ipairs(sorted) do
			local def = Logic.petById[pet.id]
			if def then
				local rarity = Config.Rarities[def.rarity]
				local tier = Config.PetTiers[pet.tier]
				local cell = UI.new("TextButton", { Text = "", AutoButtonColor = true, BackgroundColor3 = rarity.color:Lerp(Color3.new(0, 0, 0), 0.6),
					LayoutOrder = i, Parent = grid })
				UI.corner(cell, 10)
				UI.stroke(cell, tier.color or rarity.color, pet.uid == selectedPet and 4 or 2, 0)
				UI.text(cell, def.emoji, { Size = UDim2.new(1, 0, 0.55, 0), MaxText = 44 })
				UI.text(cell, Util.formatPercent(Logic.petBoost(pet)), { Size = UDim2.new(1, -4, 0.2, 0), Position = UDim2.new(0, 2, 0.56, 0), Color = C.green, MaxText = 13 })
				UI.text(cell, pet.tier > 1 and tier.name or rarity.name, { Size = UDim2.new(1, -4, 0.18, 0), Position = UDim2.new(0, 2, 0.78, 0),
					Color = tier.color or rarity.color, Font = Enum.Font.GothamBold, MaxText = 11 })
				if pet.eq then
					UI.text(cell, "✅", { Size = UDim2.new(0, 22, 0, 22), Position = UDim2.new(1, -24, 0, 2), MaxText = 18 })
				end
				cell.Activated:Connect(function()
					selectedPet = pet.uid
					build()
				end)
			end
		end
		if #sorted == 0 then
			UI.text(grid, "Noch keine Pets.\nGeh zur 🎁 Geschenkbox!", { Color = C.muted, MaxText = 16 })
		end
		showDetail()
	end

	return function(kind)
		if kind == "full" then build() end
	end
end

----------------------------------------------------------------------------
-- 🌍 WELTEN
----------------------------------------------------------------------------
BUILDERS.worlds = function(root)
	local list = UI.scroll(root)
	UI.list(list, false, 6)
	UI.padding(list, 2)
	local rows = {}
	for i, w in ipairs(Config.Worlds) do
		local row = UI.panel(list, { Size = UDim2.new(1, -10, 0, 70), Color = C.panel2, LayoutOrder = i })
		UI.stroke(row, w.accent, 2, 0.3)
		UI.text(row, w.emoji, { Size = UDim2.new(0, 60, 1, 0), MaxText = 40 })
		UI.text(row, "<b>" .. i .. ". " .. w.name .. "</b>  <font color='" .. UI.hex(C.gold) .. "'>Aura x" .. Util.format(w.mult) .. "</font>",
			{ Size = UDim2.new(1, -230, 0.5, 0), Position = UDim2.new(0, 64, 0, 4), XAlign = Enum.TextXAlignment.Left, MaxText = 20 })
		local req = UI.text(row, "", { Size = UDim2.new(1, -230, 0.4, 0), Position = UDim2.new(0, 64, 0.52, 0), XAlign = Enum.TextXAlignment.Left,
			Font = Enum.Font.GothamBold, Color = C.muted, MaxText = 14 })
		local btn = UI.button(row, "", C.cyan, function()
			Remotes.Teleport:FireServer(i)
			Menus.close()
		end, { AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -8, 0.5, 0), Size = UDim2.new(0, 150, 0, 48), MaxText = 16 })
		rows[i] = { req = req, btn = btn, w = w }
	end
	return function()
		local s, d = snap(), data()
		for i, r in ipairs(rows) do
			local w = r.w
			local unlocked = Logic.worldUnlocked(d, i)
			if s.world == i then
				r.req.Text = "📍 Du bist hier"
				r.btn.Text = "📍 Hier"
				r.btn.BackgroundColor3 = C.grey
			elseif unlocked then
				r.req.Text = "✅ Freigeschaltet"
				r.btn.Text = "🌀 Teleport"
				r.btn.BackgroundColor3 = C.cyan
				r.btn.TextColor3 = C.dark
			else
				local parts = { "💸 " .. Util.format(w.cost) .. " Aura" }
				if w.rebirths > 0 then table.insert(parts, "♻️ " .. w.rebirths .. " Rebirths") end
				r.req.Text = table.concat(parts, "  ·  ")
				local canBuy = Logic.worldUnlocked(d, i - 1) and d.aura >= w.cost and d.rebirths >= w.rebirths
				r.btn.Text = canBuy and "🔓 Freischalten" or "🔒 Gesperrt"
				r.btn.BackgroundColor3 = canBuy and C.gold or C.grey
				r.btn.TextColor3 = canBuy and C.dark or C.muted
			end
		end
	end
end

----------------------------------------------------------------------------
-- ♻️ REBIRTH
----------------------------------------------------------------------------
BUILDERS.rebirth = function(root)
	local top = UI.panel(root, { Size = UDim2.new(1, 0, 0.42, 0), Color = C.panel2 })
	UI.padding(top, 10)
	local infoL = UI.text(top, "", { Size = UDim2.new(0.62, 0, 0.62, 0), XAlign = Enum.TextXAlignment.Left, Font = Enum.Font.GothamBold, MaxText = 17 })
	local barBg = UI.panel(top, { Size = UDim2.new(0.62, 0, 0.12, 0), Position = UDim2.new(0, 0, 0.66, 0), Color = C.dark, Radius = 8 })
	local bar = UI.panel(barBg, { Size = UDim2.new(0, 0, 1, 0), Color = C.green, Radius = 8 })
	UI.gradient(bar, C.pink, C.gold, 0)
	UI.text(top, "Aura & Upgrades werden zurückgesetzt. Pets, Welten, Geld und Perks bleiben!", { Size = UDim2.new(0.62, 0, 0.18, 0),
		Position = UDim2.new(0, 0, 0.82, 0), XAlign = Enum.TextXAlignment.Left, Font = Enum.Font.Gotham, Color = C.muted, MaxText = 13 })
	local rbBtn = UI.button(top, "♻️ REBIRTH!", C.gold, function()
		local s = snap()
		Effects.confirm("♻️ Rebirth machen?", "Du startest mit Aura und Upgrades neu, bekommst aber dauerhaft x" .. Util.format(Logic.rebirthMult(s.data.rebirths + 1))
			.. " Aura und " .. Logic.rebirthPointsFor(s.data.rebirths + 1) .. " Rebirth-Punkte.", "Rebirth!", function()
			Remotes.Rebirth:FireServer()
			Sounds.play("Rebirth")
		end)
	end, { AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, 0, 0.5, 0), Size = UDim2.new(0.34, 0, 0.5, 0), TextColor = C.dark, MaxText = 26 })

	local shopTitle = UI.text(root, "", { Size = UDim2.new(1, 0, 0, 30), Position = UDim2.new(0, 0, 0.44, 4), XAlign = Enum.TextXAlignment.Left, MaxText = 20 })
	local list = UI.scroll(root, { Size = UDim2.new(1, 0, 0.56, -40), Position = UDim2.new(0, 0, 0.44, 40) })
	UI.list(list, false, 6)
	UI.padding(list, 2)
	local rows = {}
	for i, perk in ipairs(Config.RebirthShop) do
		local row = UI.panel(list, { Size = UDim2.new(1, -10, 0, 60), Color = C.panel2, LayoutOrder = i })
		UI.text(row, perk.emoji, { Size = UDim2.new(0, 50, 1, 0), MaxText = 32 })
		local name = UI.text(row, "", { Size = UDim2.new(1, -200, 0.5, 0), Position = UDim2.new(0, 54, 0.04, 0), XAlign = Enum.TextXAlignment.Left, MaxText = 18 })
		UI.text(row, perk.desc, { Size = UDim2.new(1, -200, 0.42, 0), Position = UDim2.new(0, 54, 0.54, 0), XAlign = Enum.TextXAlignment.Left,
			Font = Enum.Font.Gotham, Color = C.muted, MaxText = 13 })
		local btn = UI.button(row, "", C.cyan, function()
			Remotes.BuyPerk:FireServer(perk.id)
		end, { AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -8, 0.5, 0), Size = UDim2.new(0, 120, 0, 42), MaxText = 16 })
		rows[perk.id] = { name = name, btn = btn, perk = perk }
	end

	return function()
		local s, d = snap(), data()
		local cost = s.rebirthCost
		infoL.Text = "♻️ Rebirths: <font color='" .. UI.hex(C.cyan) .. "'>" .. d.rebirths .. "</font>\n"
			.. "Multiplikator: x" .. Util.format(Logic.rebirthMult(d.rebirths)) .. " → <font color='" .. UI.hex(C.green) .. "'>x"
			.. Util.format(Logic.rebirthMult(d.rebirths + 1)) .. "</font>\n"
			.. "Kosten: <font color='" .. UI.hex(C.gold) .. "'>" .. Util.format(cost) .. " Aura</font>"
		bar.Size = UDim2.new(math.clamp(d.aura / cost, 0, 1), 0, 1, 0)
		local can = d.aura >= cost
		rbBtn.BackgroundColor3 = can and C.gold or C.grey
		rbBtn.TextColor3 = can and C.dark or C.muted
		shopTitle.Text = "🛒 Rebirth-Shop  ·  <font color='" .. UI.hex(C.cyan) .. "'>" .. d.rebirthPoints .. " Rebirth-Punkte</font>"
		for id, r in pairs(rows) do
			local level = Logic.perkLevel(d, id)
			r.name.Text = r.perk.name .. "  <font size='13' color='" .. UI.hex(C.cyan) .. "'>" .. level .. "/" .. r.perk.max .. "</font>"
			if level >= r.perk.max then
				r.btn.Text = "✅ MAX"
				r.btn.BackgroundColor3 = C.grey
			else
				local pc = Logic.perkCost(r.perk, level)
				r.btn.Text = pc .. " RP"
				r.btn.BackgroundColor3 = d.rebirthPoints >= pc and C.cyan or C.grey
				r.btn.TextColor3 = d.rebirthPoints >= pc and C.dark or C.muted
			end
		end
	end
end

----------------------------------------------------------------------------
-- 🏆 RANGLISTE
----------------------------------------------------------------------------
BUILDERS.leaderboard = function(root)
	local header = UI.text(root, "Lädt …", { Size = UDim2.new(1, -130, 0, 34), XAlign = Enum.TextXAlignment.Left, Font = Enum.Font.GothamBold, MaxText = 16 })
	local list = UI.scroll(root, { Size = UDim2.new(1, 0, 1, -42), Position = UDim2.new(0, 0, 0, 42) })
	UI.list(list, false, 4)
	UI.padding(list, 2)
	local me = Players.LocalPlayer.UserId

	local function load()
		header.Text = "Lädt …"
		task.spawn(function()
			local ok, result = pcall(function()
				return Remotes:WaitForChild("GetLeaderboard"):InvokeServer()
			end)
			if not list.Parent then return end
			UI.clear(list)
			if not ok or not result or not result.available then
				header.Text = "Rangliste nicht verfügbar (in Studio: API-Zugriff aktivieren)."
				return
			end
			local myRank = nil
			for i, e in ipairs(result.list) do
				if e.userId == me then myRank = e.rank end
				local isMe = e.userId == me
				local row = UI.panel(list, { Size = UDim2.new(1, -10, 0, 34), Color = isMe and C.purple or C.panel2, LayoutOrder = i, Radius = 8 })
				local medal = ({ "🥇", "🥈", "🥉" })[e.rank] or ("#" .. e.rank)
				UI.text(row, medal, { Size = UDim2.new(0, 60, 1, 0), MaxText = 18 })
				UI.text(row, e.name, { Size = UDim2.new(1, -220, 1, 0), Position = UDim2.new(0, 64, 0, 0), XAlign = Enum.TextXAlignment.Left, MaxText = 17 })
				UI.text(row, "✨ " .. Util.format(e.value), { Size = UDim2.new(0, 150, 1, 0), Position = UDim2.new(1, -156, 0, 0),
					XAlign = Enum.TextXAlignment.Right, Color = C.gold, MaxText = 17 })
			end
			local power = snap() and snap().glowPower or 0
			if myRank then
				header.Text = "Dein Platz: <font color='" .. UI.hex(C.gold) .. "'>#" .. myRank .. "</font> · Glow-Power: " .. Util.format(power)
			else
				header.Text = "Du bist (noch) nicht in den Top " .. Config.LEADERBOARD_SIZE .. " · deine Glow-Power: " .. Util.format(power)
			end
			if #result.list == 0 then
				UI.text(list, "Noch keine Einträge. Die Rangliste aktualisiert sich alle 2 Minuten.", { Color = C.muted, MaxText = 16, Size = UDim2.new(1, 0, 0, 60) })
			end
		end)
	end
	UI.button(root, "🔄 Neu laden", C.panel2, load, { AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, 0, 0, 0), Size = UDim2.new(0, 120, 0, 34), MaxText = 15 })
	load()
	return nil
end

----------------------------------------------------------------------------
-- 🎁 BELOHNUNGEN: tägliche Serie, Codes, Tränke
----------------------------------------------------------------------------
local function rewardText(r)
	local parts = {}
	if r.cash then table.insert(parts, "💵 " .. Util.format(r.cash)) end
	if r.auraSeconds then table.insert(parts, "✨ " .. r.auraSeconds .. "s Aura") end
	if r.potion then table.insert(parts, Logic.potionById[r.potion].emoji .. " Trank") end
	if r.freeEgg then table.insert(parts, "🎁 Box") end
	return table.concat(parts, "\n")
end

function Menus.dailyReady()
	local d = data()
	if not d then return false end
	return os.time() - d.daily.last >= 20 * 3600
end

BUILDERS.rewards = function(root)
	UI.text(root, "📅 Tägliche Belohnung (7-Tage-Serie)", { Size = UDim2.new(1, 0, 0, 26), XAlign = Enum.TextXAlignment.Left, MaxText = 18 })
	local days = UI.new("Frame", { BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 92), Position = UDim2.new(0, 0, 0, 28), Parent = root })
	UI.list(days, true, 6, Enum.HorizontalAlignment.Center)
	local dayCells = {}
	for i, r in ipairs(Config.Daily) do
		local cell = UI.panel(days, { Size = UDim2.new(1 / 7, -6, 1, 0), Color = C.panel2, LayoutOrder = i, Radius = 10 })
		UI.padding(cell, 4)
		UI.text(cell, "Tag " .. i, { Size = UDim2.new(1, 0, 0.28, 0), MaxText = 15 })
		UI.text(cell, rewardText(r), { Size = UDim2.new(1, 0, 0.7, 0), Position = UDim2.new(0, 0, 0.3, 0), Font = Enum.Font.GothamBold, Color = C.muted, MaxText = 12 })
		dayCells[i] = cell
	end
	local claim = UI.button(root, "", C.gold, function()
		Remotes.ClaimDaily:FireServer()
	end, { Size = UDim2.new(1, 0, 0, 40), Position = UDim2.new(0, 0, 0, 126), TextColor = C.dark, MaxText = 18 })

	UI.text(root, "🎟️ Code einlösen", { Size = UDim2.new(0.5, 0, 0, 24), Position = UDim2.new(0, 0, 0, 174), XAlign = Enum.TextXAlignment.Left, MaxText = 17 })
	local box = UI.new("TextBox", { Size = UDim2.new(0.65, -6, 0, 38), Position = UDim2.new(0, 0, 0, 200), BackgroundColor3 = C.dark,
		TextColor3 = C.text, PlaceholderText = "z. B. MEWING2026", PlaceholderColor3 = C.muted, Text = "", ClearTextOnFocus = false,
		Font = Enum.Font.GothamBold, TextScaled = true, Parent = root })
	UI.corner(box, 10)
	UI.padding(box, 6)
	UI.button(root, "Einlösen", C.pink, function()
		Remotes.RedeemCode:FireServer(box.Text)
		box.Text = ""
	end, { Size = UDim2.new(0.35, 0, 0, 38), Position = UDim2.new(0.65, 0, 0, 200), MaxText = 18 })

	UI.text(root, "🧪 Tränke (kosten Geld)", { Size = UDim2.new(0.6, 0, 0, 24), Position = UDim2.new(0, 0, 0, 246), XAlign = Enum.TextXAlignment.Left, MaxText = 17 })
	local list = UI.scroll(root, { Size = UDim2.new(1, 0, 1, -276), Position = UDim2.new(0, 0, 0, 274) })
	UI.list(list, false, 6)
	UI.padding(list, 2)
	local potionRows = {}
	for i, p in ipairs(Config.Potions) do
		local row = UI.panel(list, { Size = UDim2.new(1, -10, 0, 56), Color = C.panel2, LayoutOrder = i })
		UI.text(row, p.emoji, { Size = UDim2.new(0, 46, 1, 0), MaxText = 30 })
		UI.text(row, p.name, { Size = UDim2.new(1, -190, 0.5, 0), Position = UDim2.new(0, 50, 0.04, 0), XAlign = Enum.TextXAlignment.Left, MaxText = 17 })
		local sub = UI.text(row, p.desc, { Size = UDim2.new(1, -190, 0.42, 0), Position = UDim2.new(0, 50, 0.54, 0), XAlign = Enum.TextXAlignment.Left,
			Font = Enum.Font.Gotham, Color = C.muted, MaxText = 13 })
		local btn = UI.button(row, "💵 " .. Util.format(p.price), C.money, function()
			Remotes.BuyPotion:FireServer(p.id)
		end, { AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -8, 0.5, 0), Size = UDim2.new(0, 120, 0, 40), TextColor = C.dark, MaxText = 16 })
		potionRows[p.id] = { sub = sub, btn = btn, p = p }
	end

	return function()
		local d = data()
		local streak = d.daily.streak
		local remaining = d.daily.last + 20 * 3600 - os.time()
		local ready = remaining <= 0
		local nextDay = (ready and os.time() - d.daily.last > 48 * 3600) and 1 or ((streak % #Config.Daily) + 1)
		for i, cell in ipairs(dayCells) do
			cell.BackgroundColor3 = (i == nextDay and ready) and C.pink or ((i <= streak and not (ready and nextDay == 1)) and C.purple or C.panel2)
		end
		claim.Text = ready and ("🎁 Tag " .. nextDay .. " abholen!") or ("⏳ Nächste Belohnung in " .. Util.formatTime(remaining))
		claim.BackgroundColor3 = ready and C.gold or C.grey
		local now = os.time()
		for id, r in pairs(potionRows) do
			local untilTime = d.potions[id]
			if untilTime and untilTime > now then
				r.sub.Text = "<font color='" .. UI.hex(C.green) .. "'>Aktiv: noch " .. Util.formatTime(untilTime - now) .. "</font>"
			else
				r.sub.Text = r.p.desc
			end
			r.btn.BackgroundColor3 = d.cash >= r.p.price and C.money or C.grey
		end
	end
end

----------------------------------------------------------------------------
-- ⚙️ EINSTELLUNGEN
----------------------------------------------------------------------------
BUILDERS.settings = function(root)
	UI.list(root, false, 10)
	local musicBtn, sfxBtn, camBtn
	local function update()
		local d = data()
		if camBtn then
			local on = CameraController.isMouseLook()
			camBtn.Text = "🖱️ Maus-Kamera (Taste Strg): " .. (on and "AN" or "AUS")
			camBtn.BackgroundColor3 = on and C.green or C.grey
		end
		musicBtn.Text = "🎵 Musik: " .. (d.settings.music and "AN" or "AUS")
		musicBtn.BackgroundColor3 = d.settings.music and C.green or C.grey
		sfxBtn.Text = "🔊 Soundeffekte: " .. (d.settings.sfx and "AN" or "AUS")
		sfxBtn.BackgroundColor3 = d.settings.sfx and C.green or C.grey
	end
	musicBtn = UI.button(root, "", C.green, function()
		local d = data()
		d.settings.music = not d.settings.music
		Sounds.setMusic(d.settings.music)
		Remotes.Setting:FireServer("music", d.settings.music)
		update()
	end, { Size = UDim2.new(1, 0, 0, 46), LayoutOrder = 1, TextColor = C.dark })
	sfxBtn = UI.button(root, "", C.green, function()
		local d = data()
		d.settings.sfx = not d.settings.sfx
		Sounds.setSfx(d.settings.sfx)
		Remotes.Setting:FireServer("sfx", d.settings.sfx)
		update()
	end, { Size = UDim2.new(1, 0, 0, 46), LayoutOrder = 2, TextColor = C.dark })
	if UserInputService.MouseEnabled then
		camBtn = UI.button(root, "", C.grey, function()
			CameraController.setMouseLook(not CameraController.isMouseLook())
			update()
		end, { Size = UDim2.new(1, 0, 0, 46), LayoutOrder = 3, TextColor = C.dark })
	end
	UI.text(root, UserInputService.TouchEnabled and not UserInputService.MouseEnabled
		and "📱 Kamera: mit einem Finger wischen = drehen · zwei Finger = zoomen"
		or "🖱️ Kamera: Maustaste gedrückt halten und ziehen = drehen · Mausrad = zoomen · Strg = Maus-Kamera",
		{ Size = UDim2.new(1, 0, 0, 40), LayoutOrder = 4, Font = Enum.Font.GothamBold, Color = C.cyan, MaxText = 15 })
	local s = snap()
	local d = data()
	UI.text(root, (s.saving and "💾 Dein Spielstand wird automatisch gespeichert." or "⚠️ Speichern ist gerade aus.")
		.. "\n\n📊 Klicks: " .. Util.format(d.clicks) .. "  ·  🎁 Boxen geöffnet: " .. Util.format(d.eggsOpened)
		.. "\n⚔️ Mog-Siege: " .. d.mogWins .. "  ·  Niederlagen: " .. d.mogLosses .. "  ·  👑 Boss-Siege: " .. d.bossWins
		.. "\n🌌 Aura insgesamt: " .. Util.format(d.totalAura),
		{ Size = UDim2.new(1, 0, 0, 130), LayoutOrder = 5, Font = Enum.Font.GothamBold, Color = C.muted, MaxText = 16 })
	update()
	return nil
end

return Menus
