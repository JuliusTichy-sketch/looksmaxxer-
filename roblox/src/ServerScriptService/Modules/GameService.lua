--[[
	GAMESERVICE – das Herzstück auf dem Server:
	Klicks, Upgrades, Aura pro Sekunde, Rebirth, Welten, Titel,
	Namensschild & Aussehen des Avatars, Offline-Verdienst.
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config"))
local Logic = require(Shared:WaitForChild("Logic"))
local Util = require(Shared:WaitForChild("Util"))
local Remotes = require(script.Parent.Remotes)
local DataService = require(script.Parent.DataService)

local GameService = {}
GameService.characterHooks = {}   -- andere Module können sich hier für "Charakter erschienen" eintragen

----------------------------------------------------------------------------
-- Hilfsfunktionen
----------------------------------------------------------------------------
function GameService.worldOrigin(index)
	return Vector3.new((index - 1) * Config.WORLD_SPACING, 0, 0)
end

function GameService.worldIndexAt(x)
	local i = math.floor((x + Config.WORLD_SPACING / 2) / Config.WORLD_SPACING) + 1
	return math.clamp(i, 1, #Config.Worlds)
end

function GameService.currentWorld(player)
	return player:GetAttribute("World") or 1
end

function GameService.notify(player, title, text, kind)
	Remotes.Notify:FireClient(player, title, text, kind or "")
end

function GameService.addAura(data, amount)
	data.aura = data.aura + amount
	data.totalAura = data.totalAura + amount
end

-- Alles, was der Spieler zum Anzeigen braucht
function GameService.snapshot(player, data)
	local now = os.time()
	local w = GameService.currentWorld(player)
	return {
		data = data,
		world = w,
		aps = Logic.aps(data, w, now),
		click = Logic.clickValue(data, w, now),
		glow = Logic.baseGlow(data.levels),
		glowPower = Logic.glowPower(data),
		mult = Logic.multiplier(data, w, now),
		petMult = Logic.petMult(data),
		petSlots = Logic.petSlots(data),
		luck = Logic.luck(data, now),
		rebirthCost = Logic.rebirthCost(data.rebirths),
		serverTime = now,
		saving = DataService.isSaving(player),
	}
end

function GameService.sendFull(player)
	local data = DataService.get(player)
	if data then
		Remotes.Data:FireClient(player, "full", GameService.snapshot(player, data))
	end
end

function GameService.sendLight(player)
	local data = DataService.get(player)
	if not data then return end
	local now = os.time()
	local w = GameService.currentWorld(player)
	Remotes.Data:FireClient(player, "light", {
		aura = data.aura, cash = data.cash, totalAura = data.totalAura,
		aps = Logic.aps(data, w, now), click = Logic.clickValue(data, w, now),
		mult = Logic.multiplier(data, w, now), world = w, serverTime = now,
	})
end

----------------------------------------------------------------------------
-- Leaderstats (Spielerliste oben rechts)
----------------------------------------------------------------------------
local function setupLeaderstats(player, data)
	local ls = Instance.new("Folder")
	ls.Name = "leaderstats"
	local glow = Instance.new("IntValue")
	glow.Name = "✨ Glow"
	glow.Parent = ls
	local reb = Instance.new("IntValue")
	reb.Name = "♻️ Rebirths"
	reb.Parent = ls
	ls.Parent = player
end

local function updateLeaderstats(player, data)
	local ls = player:FindFirstChild("leaderstats")
	if not ls then return end
	local glow = ls:FindFirstChild("✨ Glow")
	local reb = ls:FindFirstChild("♻️ Rebirths")
	if glow then glow.Value = math.floor(Logic.baseGlow(data.levels)) end
	if reb then reb.Value = data.rebirths end
end

----------------------------------------------------------------------------
-- Aussehen: Namensschild, Glitzer-Aura, breitere Schultern
----------------------------------------------------------------------------
local function makeLabel(parent, name, posY, height, color, bold)
	local l = Instance.new("TextLabel")
	l.Name = name
	l.BackgroundTransparency = 1
	l.Size = UDim2.new(1, 0, height, 0)
	l.Position = UDim2.new(0, 0, posY, 0)
	l.TextScaled = true
	l.Font = bold and Enum.Font.FredokaOne or Enum.Font.GothamBold
	l.TextColor3 = color
	l.TextStrokeTransparency = 0.4
	l.Text = ""
	l.Parent = parent
	return l
end

local function ensureNametag(head)
	local tag = head:FindFirstChild("Nametag")
	if tag then return tag end
	tag = Instance.new("BillboardGui")
	tag.Name = "Nametag"
	tag.Size = UDim2.new(7, 0, 2.2, 0)
	tag.StudsOffset = Vector3.new(0, 2.8, 0)
	tag.MaxDistance = 120
	tag.AlwaysOnTop = false
	tag.Parent = head
	makeLabel(tag, "TitleLabel", 0, 0.32, Color3.fromRGB(255, 120, 220), false)
	makeLabel(tag, "NameLabel", 0.32, 0.4, Color3.new(1, 1, 1), true)
	makeLabel(tag, "InfoLabel", 0.72, 0.28, Color3.fromRGB(255, 209, 102), false)
	return tag
end

function GameService.refreshCharacter(player)
	local data = DataService.get(player)
	local char = player.Character
	if not data or not char then return end
	local hum = char:FindFirstChildOfClass("Humanoid")
	local head = char:FindFirstChild("Head")
	local hrp = char:FindFirstChild("HumanoidRootPart")
	if not hum or not head or not hrp then return end

	local glow = Logic.baseGlow(data.levels)
	hum.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None
	hum.WalkSpeed = 16 + 2 * Logic.perkLevel(data, "speed")

	-- Namensschild mit Titel
	local tag = ensureNametag(head)
	tag.TitleLabel.Text = Config.Titles[Logic.titleIndex(glow)].title
	tag.NameLabel.Text = player.DisplayName
	tag.InfoLabel.Text = "✨ " .. Util.format(glow) .. " Glow  ·  ♻️ " .. data.rebirths

	-- Breitere Schultern durch Fitness (funktioniert nur mit R15-Avataren)
	local fit = Logic.catLevels(data.levels, "fit")
	local width = 1 + math.min(0.45, fit / 250)
	pcall(function()
		local ws = hum:FindFirstChild("BodyWidthScale")
		local ds = hum:FindFirstChild("BodyDepthScale")
		if ws then ws.Value = width end
		if ds then ds.Value = 1 + (width - 1) * 0.7 end
	end)

	-- Glitzer-Aura (stärker mit Glow, Farbe wechselt mit Rebirths)
	local aura = hrp:FindFirstChild("GlowAura")
	if not aura then
		aura = Instance.new("ParticleEmitter")
		aura.Name = "GlowAura"
		aura.LightEmission = 1
		aura.Lifetime = NumberRange.new(0.8, 1.6)
		aura.Speed = NumberRange.new(1, 3)
		aura.SpreadAngle = Vector2.new(180, 180)
		aura.Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.5), NumberSequenceKeypoint.new(1, 0) })
		aura.Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.1), NumberSequenceKeypoint.new(1, 1) })
		aura.Parent = hrp
	end
	local colorIndex = (data.rebirths % #Config.AuraColors) + 1
	aura.Color = ColorSequence.new(Config.AuraColors[colorIndex])
	aura.Rate = math.clamp(glow / 80, 0, 45)
	aura.Enabled = glow >= 40
end

-- Nach Änderungen an den Upgrades: Titel prüfen, alles aktualisieren
function GameService.afterLevelsChanged(player, data)
	local glow = Logic.baseGlow(data.levels)
	local idx = Logic.titleIndex(glow)
	if idx > data.bestTitle then
		data.bestTitle = idx
		local t = Config.Titles[idx]
		GameService.notify(player, "🏆 Neuer Titel: " .. t.title .. "!", t.text, "title")
	end
	updateLeaderstats(player, data)
	GameService.refreshCharacter(player)
	GameService.sendFull(player)
end

----------------------------------------------------------------------------
-- Welten & Teleport
----------------------------------------------------------------------------
function GameService.teleport(player, index)
	local char = player.Character
	if not char then return end
	local origin = GameService.worldOrigin(index)
	char:PivotTo(CFrame.new(origin + Vector3.new(0, 5, 22)))
	player:SetAttribute("World", index)
	local w = Config.Worlds[index]
	GameService.notify(player, w.emoji .. " " .. w.name, "Aura-Multiplikator dieser Welt: x" .. Util.format(w.mult), "world")
	GameService.sendFull(player)
end

-- Welt freischalten (Aura bezahlen) oder hinreisen
function GameService.tryWorld(player, index)
	local data = DataService.get(player)
	local w = Config.Worlds[index]
	if not data or not w then return end
	if Logic.worldUnlocked(data, index) then
		GameService.teleport(player, index)
		return
	end
	if not Logic.worldUnlocked(data, index - 1) then
		GameService.notify(player, "🔒 Gesperrt", "Schalte zuerst " .. Config.Worlds[index - 1].name .. " frei.", "bad")
		return
	end
	if data.rebirths < w.rebirths then
		GameService.notify(player, "🔒 Mehr Rebirths nötig", w.name .. " braucht " .. w.rebirths .. " Rebirths.", "bad")
		return
	end
	if data.aura < w.cost then
		GameService.notify(player, "💸 Zu wenig Aura", w.name .. " kostet " .. Util.format(w.cost) .. " Aura.", "bad")
		return
	end
	data.aura = data.aura - w.cost
	data.worlds[tostring(index)] = true
	GameService.notify(player, "🌍 Neue Welt freigeschaltet!", w.emoji .. " " .. w.name .. " – x" .. Util.format(w.mult) .. " Aura!", "title")
	GameService.teleport(player, index)
end

----------------------------------------------------------------------------
-- Spieler betritt / verlässt das Spiel
----------------------------------------------------------------------------
local function onCharacterAdded(player, char)
	local hum = char:WaitForChild("Humanoid", 10)
	char:WaitForChild("HumanoidRootPart", 10)
	char:WaitForChild("Head", 10)
	if not hum then return end
	player:SetAttribute("World", 1)
	GameService.refreshCharacter(player)
	for _, hook in ipairs(GameService.characterHooks) do
		task.spawn(hook, player, char)
	end
end

local function offlineEarnings(player, data)
	if data.lastOnline <= 0 then return end
	local hours = Config.OFFLINE_HOURS + 2 * Logic.perkLevel(data, "offline")
	local secs = math.min(hours * 3600, os.time() - data.lastOnline)
	local aps = Logic.aps(data, 1, os.time())
	if secs < 60 or aps <= 0 then return end
	local gain = aps * secs * Config.OFFLINE_RATE
	GameService.addAura(data, gain)
	GameService.notify(player, "😴 Beauty Sleep",
		"Du warst " .. Util.formatTime(secs) .. " weg und hast im Schlaf " .. Util.format(gain) .. " Aura gesammelt!", "offline")
end

function GameService.playerAdded(player)
	local data, saving = DataService.load(player)
	if not player.Parent then return end   -- schon wieder weg
	setupLeaderstats(player, data)
	updateLeaderstats(player, data)
	player:SetAttribute("World", 1)
	player:SetAttribute("Loaded", true)

	player.CharacterAdded:Connect(function(char)
		onCharacterAdded(player, char)
	end)
	player.CharacterAppearanceLoaded:Connect(function()
		task.wait(0.5)
		GameService.refreshCharacter(player)
	end)
	if player.Character then
		task.spawn(onCharacterAdded, player, player.Character)
	end

	GameService.sendFull(player)
	task.delay(3, function()
		if not player.Parent then return end
		if not saving then
			GameService.notify(player, "⚠️ Speichern aus",
				"Der Spielstand kann gerade nicht gespeichert werden (in Studio: API-Zugriff aktivieren).", "bad")
		end
		offlineEarnings(player, data)
		GameService.sendFull(player)
	end)
end

----------------------------------------------------------------------------
-- Remotes: Klicks, Upgrades, Rebirth, Perks, Welten
----------------------------------------------------------------------------
local clickWindow = {}   -- Schutz gegen Auto-Klicker-Programme

Remotes.Click.OnServerEvent:Connect(function(player)
	local data = DataService.get(player)
	if not data then return end
	local now = os.clock()
	local w = clickWindow[player]
	if not w or now - w.start >= 1 then
		w = { start = now, n = 0 }
		clickWindow[player] = w
	end
	w.n = w.n + 1
	if w.n > 15 then return end   -- mehr als 15 Klicks pro Sekunde wird ignoriert
	GameService.addAura(data, Logic.clickValue(data, GameService.currentWorld(player), os.time()))
	data.clicks = data.clicks + 1
end)

Remotes.BuyUpgrade.OnServerEvent:Connect(function(player, id, amount)
	local data = DataService.get(player)
	local u = Logic.upgradeById[id]
	if not data or not u then return end
	if amount ~= "max" then
		amount = math.clamp(math.floor(tonumber(amount) or 1), 1, 100)
	end
	local level = Logic.level(data, id)
	local count, cost = Logic.bulk(u, level, amount, data.aura)
	if count <= 0 then
		GameService.notify(player, "✅ Maximal", u.name .. " ist schon auf der höchsten Stufe.", "")
		return
	end
	if cost > data.aura then
		GameService.notify(player, "💸 Zu wenig Aura", "Dir fehlen noch " .. Util.format(cost - data.aura) .. " Aura.", "bad")
		return
	end
	data.aura = data.aura - cost
	data.levels[id] = level + count
	if data.levels[id] >= Config.MAX_LEVEL then
		GameService.notify(player, u.emoji .. " " .. u.name .. " gemeistert!", "Maximale Stufe erreicht.", "good")
	end
	GameService.afterLevelsChanged(player, data)
end)

Remotes.Rebirth.OnServerEvent:Connect(function(player)
	local data = DataService.get(player)
	if not data then return end
	local cost = Logic.rebirthCost(data.rebirths)
	if data.aura < cost then
		GameService.notify(player, "💸 Noch nicht", "Rebirth kostet " .. Util.format(cost) .. " Aura.", "bad")
		return
	end
	data.aura = 0
	data.levels = {}
	data.rebirths = data.rebirths + 1
	local points = Logic.rebirthPointsFor(data.rebirths)
	data.rebirthPoints = data.rebirthPoints + points
	GameService.notify(player, "♻️ REBIRTH #" .. data.rebirths .. "!",
		"Neuer Multiplikator: x" .. Util.format(Logic.rebirthMult(data.rebirths)) .. " · +" .. points .. " Rebirth-Punkte", "rebirth")
	GameService.afterLevelsChanged(player, data)
end)

Remotes.BuyPerk.OnServerEvent:Connect(function(player, id)
	local data = DataService.get(player)
	local perk = Logic.perkById[id]
	if not data or not perk then return end
	local level = Logic.perkLevel(data, id)
	if level >= perk.max then return end
	local cost = Logic.perkCost(perk, level)
	if data.rebirthPoints < cost then
		GameService.notify(player, "💸 Zu wenig Rebirth-Punkte", "Du brauchst " .. cost .. " Punkte.", "bad")
		return
	end
	data.rebirthPoints = data.rebirthPoints - cost
	data.perks[id] = level + 1
	GameService.notify(player, perk.emoji .. " " .. perk.name, "Gekauft! (Stufe " .. (level + 1) .. ")", "good")
	GameService.refreshCharacter(player)
	GameService.sendFull(player)
end)

Remotes.Teleport.OnServerEvent:Connect(function(player, index)
	index = tonumber(index)
	if index then GameService.tryWorld(player, index) end
end)
Remotes.UnlockWorld.OnServerEvent:Connect(function(player, index)
	index = tonumber(index)
	if index then GameService.tryWorld(player, index) end
end)

Remotes.Setting.OnServerEvent:Connect(function(player, key, value)
	local data = DataService.get(player)
	if not data or (key ~= "music" and key ~= "sfx") then return end
	data.settings[key] = value == true
end)

----------------------------------------------------------------------------
-- Die Schleife: jede Sekunde Aura gutschreiben
----------------------------------------------------------------------------
function GameService.start()
	task.spawn(function()
		while true do
			task.wait(1)
			local now = os.time()
			for _, player in ipairs(Players:GetPlayers()) do
				local data = DataService.get(player)
				local char = player.Character
				local hrp = char and char:FindFirstChild("HumanoidRootPart")
				if data then
					-- In welcher Welt steht der Spieler? (Schutz: nur freigeschaltete Welten zählen)
					if hrp then
						local idx = GameService.worldIndexAt(hrp.Position.X)
						if not Logic.worldUnlocked(data, idx) then
							idx = 1
							GameService.teleport(player, 1)
						end
						player:SetAttribute("World", idx)
					end
					local w = GameService.currentWorld(player)
					GameService.addAura(data, Logic.aps(data, w, now))
					if Logic.perkLevel(data, "autoclick") > 0 then
						GameService.addAura(data, Logic.clickValue(data, w, now) * 2)
					end
					GameService.sendLight(player)
				end
			end
		end
	end)
end

Players.PlayerRemoving:Connect(function(player)
	clickWindow[player] = nil
end)

return GameService
