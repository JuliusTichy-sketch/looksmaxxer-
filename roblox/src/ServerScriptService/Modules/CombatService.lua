--[[
	COMBATSERVICE – Waffen & Echtzeit-Bosskämpfe

	Waffen:
	  • kaufen, verbessern (bis Stufe 10) und ausrüsten mit Geld
	  • die ausgerüstete Waffe liegt als Werkzeug unten im Inventar (Taste 1)
	  • Klicken/Tippen = zuschlagen
	Bosskampf:
	  • jeder Boss hat Lebenspunkte – alle Spieler in der Nähe kämpfen zusammen
	  • der Boss greift an: rote Kreise auf dem Boden = schnell rauslaufen!
	  • dein "Selbstbewusstsein" ist dein Lebensbalken. Bei 0 wirst du zum Spawn geschickt.
	  • Beute für alle, die mitgeholfen haben: Geld, Aura, seltene Boss-Waffen
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Debris = game:GetService("Debris")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config"))
local Logic = require(Shared:WaitForChild("Logic"))
local Util = require(Shared:WaitForChild("Util"))
local Remotes = require(script.Parent.Remotes)
local DataService = require(script.Parent.DataService)
local GameService = require(script.Parent.GameService)
local PetService = require(script.Parent.PetService)

local CombatService = {}
local rng = Random.new()
local bosses = {}
local lastAttack = {}     -- [player] = os.clock()
local lastHurt = {}       -- [player] = os.clock()

local RARITY_COLOR = {}
for id, r in pairs(Config.Rarities) do RARITY_COLOR[id] = r.color end

----------------------------------------------------------------------------
-- Selbstbewusstsein (Lebensbalken)
----------------------------------------------------------------------------
local function setConfidence(player, value)
	local data = DataService.get(player)
	if not data then return end
	local max = Logic.maxConfidence(data)
	player:SetAttribute("MaxConf", max)
	player:SetAttribute("Conf", math.clamp(value, 0, max))
end

local function hurt(player, percent)
	local data = DataService.get(player)
	if not data then return end
	local max = Logic.maxConfidence(data)
	local w = Logic.weaponById[data.weapon]
	if w and w.shield then percent = percent * w.shield end
	local conf = (player:GetAttribute("Conf") or max) - max * percent
	lastHurt[player] = os.clock()
	if conf <= 0 then
		setConfidence(player, max)
		GameService.notify(player, "😵 Gemoggt vom Boss!", "Dein Selbstbewusstsein ist am Boden. Kurz durchatmen am Spawn – dann zurück in den Kampf!", "bad")
		GameService.teleport(player, GameService.currentWorld(player))
	else
		setConfidence(player, conf)
	end
end

----------------------------------------------------------------------------
-- Waffe als Werkzeug ins Inventar legen
----------------------------------------------------------------------------
function CombatService.giveTool(player)
	local data = DataService.get(player)
	local char = player.Character
	local backpack = player:FindFirstChildOfClass("Backpack")
	if not data or not backpack then return end
	for _, container in ipairs({ backpack, char }) do
		if container then
			for _, t in ipairs(container:GetChildren()) do
				if t:IsA("Tool") and t:GetAttribute("LooksWeapon") then t:Destroy() end
			end
		end
	end
	local w = Logic.weaponById[data.weapon] or Logic.weaponById[Config.STARTER_WEAPON]
	local tool = Instance.new("Tool")
	tool.Name = w.emoji .. " " .. w.name
	tool.ToolTip = w.name .. " (Stufe " .. math.max(1, Logic.weaponLevel(data, w.id)) .. ")"
	tool.CanBeDropped = false
	tool.RequiresHandle = true
	tool:SetAttribute("LooksWeapon", true)
	local handle = Instance.new("Part")
	handle.Name = "Handle"
	handle.Size = Vector3.new(0.5, 3.4, 0.5)
	handle.Color = RARITY_COLOR[w.rarity] or Color3.new(1, 1, 1)
	handle.Material = (w.rarity == "legendary" or w.rarity == "mythic") and Enum.Material.Neon or Enum.Material.SmoothPlastic
	handle.CanCollide = false
	handle.Massless = true
	handle.Parent = tool
	local bb = Instance.new("BillboardGui")
	bb.Size = UDim2.new(2, 0, 2, 0)
	bb.StudsOffset = Vector3.new(0, 2, 0)
	bb.LightInfluence = 0
	bb.MaxDistance = 60
	bb.Parent = handle
	local l = Instance.new("TextLabel")
	l.Size = UDim2.new(1, 0, 1, 0)
	l.BackgroundTransparency = 1
	l.TextScaled = true
	l.Text = w.emoji
	l.Parent = bb
	tool.Activated:Connect(function()
		-- Schwung-Animation über das Standard-Animationsskript
		local anim = Instance.new("StringValue")
		anim.Name = "toolanim"
		anim.Value = "Slash"
		anim.Parent = tool
		Debris:AddItem(anim, 0.5)
		CombatService.attack(player)
	end)
	tool.Parent = backpack
end

----------------------------------------------------------------------------
-- Boss-Lebensbalken
----------------------------------------------------------------------------
local function makeHpBar(boss)
	local bb = Instance.new("BillboardGui")
	bb.Name = "HpBar"
	bb.Size = UDim2.new(9, 0, 1.1, 0)
	bb.StudsOffset = Vector3.new(0, 7 * boss.scale, 0)
	bb.MaxDistance = 150
	bb.LightInfluence = 0
	bb.Parent = boss.head
	local bg = Instance.new("Frame")
	bg.Size = UDim2.new(1, 0, 1, 0)
	bg.BackgroundColor3 = Color3.fromRGB(30, 10, 40)
	bg.BorderSizePixel = 0
	bg.Parent = bb
	local fill = Instance.new("Frame")
	fill.Name = "Fill"
	fill.Size = UDim2.new(1, 0, 1, 0)
	fill.BackgroundColor3 = Color3.fromRGB(255, 70, 90)
	fill.BorderSizePixel = 0
	fill.Parent = bg
	local text = Instance.new("TextLabel")
	text.Name = "Text"
	text.Size = UDim2.new(1, 0, 1, 0)
	text.BackgroundTransparency = 1
	text.TextScaled = true
	text.Font = Enum.Font.FredokaOne
	text.TextColor3 = Color3.new(1, 1, 1)
	text.TextStrokeTransparency = 0.3
	text.Parent = bg
	boss.bar = fill
	boss.barText = text
end

local function updateBoss(boss)
	boss.model:SetAttribute("HP", boss.hp)
	boss.model:SetAttribute("MaxHP", boss.maxHp)
	if boss.bar then
		boss.bar.Size = UDim2.new(math.clamp(boss.hp / boss.maxHp, 0, 1), 0, 1, 0)
		boss.barText.Text = "❤️ " .. Util.format(math.max(0, boss.hp)) .. " / " .. Util.format(boss.maxHp)
	end
end

----------------------------------------------------------------------------
-- Angreifen
----------------------------------------------------------------------------
local function hitFlash(position, color)
	local p = Instance.new("Part")
	p.Shape = Enum.PartType.Ball
	p.Size = Vector3.new(2.5, 2.5, 2.5)
	p.Anchored = true
	p.CanCollide = false
	p.CanQuery = false
	p.CanTouch = false
	p.Material = Enum.Material.Neon
	p.Color = color
	p.Transparency = 0.2
	p.CFrame = CFrame.new(position)
	p.Parent = workspace
	Debris:AddItem(p, 0.15)
end

local function defeat(boss)
	boss.dead = true
	local participants = {}
	for player, dmg in pairs(boss.damage) do
		if player.Parent and dmg >= boss.maxHp * 0.03 then
			table.insert(participants, { player = player, share = dmg / boss.maxHp })
		end
	end
	boss.damage = {}
	boss.respawnAt = os.clock() + Config.BOSS_RESPAWN
	boss.model.Parent = nil   -- Boss verschwindet

	for _, p in ipairs(participants) do
		local player = p.player
		local data = DataService.get(player)
		if data then
			local aps = math.max(Logic.aps(data, GameService.currentWorld(player), os.time()), 5)
			local cash = math.floor(150 * boss.world ^ 2.5 * (0.5 + math.min(p.share, 1)) * Logic.cashMult(data))
			local aura = aps * 120
			data.cash = data.cash + cash
			GameService.addAura(data, aura)
			GameService.track(player, "bossKills", 1)
			local text = "+" .. Util.format(cash) .. " Geld · +" .. Util.format(aura) .. " Aura · Dein Anteil: " .. math.floor(p.share * 100) .. " %"
			-- Event-Boss: Event-Münzen
			if boss.def.event then
				local tokens = math.floor(10 + 20 * math.min(p.share, 1))
				data.eventTokens[boss.def.event] = Logic.eventTokens(data, boss.def.event) + tokens
				text = text .. " · +" .. tokens .. " Event-Münzen"
			end
			-- seltene Boss-Waffen
			local drop = nil
			if boss.def.final and rng:NextNumber() < Logic.weaponById.laser.drop and Logic.weaponLevel(data, "laser") == 0 then
				drop = "laser"
			elseif boss.world >= 4 and rng:NextNumber() < Logic.weaponById.faust.drop and Logic.weaponLevel(data, "faust") == 0 then
				drop = "faust"
			end
			if drop then
				data.weapons[drop] = 1
				local w = Logic.weaponById[drop]
				text = text .. "\n🎉 BEUTE: " .. w.emoji .. " " .. w.name .. "!"
				PetService.announce(player.DisplayName .. " hat die Waffe " .. w.emoji .. " " .. w.name .. " erbeutet!")
			end
			GameService.notify(player, "👑 " .. boss.def.name .. " BESIEGT!", text, "title")
			GameService.sendFull(player)
		end
	end
end

function CombatService.attack(player)
	local data = DataService.get(player)
	local char = player.Character
	local hrp = char and char:FindFirstChild("HumanoidRootPart")
	if not data or not hrp then return end
	local w = Logic.weaponById[data.weapon] or Logic.weaponById[Config.STARTER_WEAPON]
	local now = os.clock()
	if lastAttack[player] and now - lastAttack[player] < w.cooldown * 0.9 then return end
	lastAttack[player] = now

	local best, bestDist = nil, math.huge
	for _, boss in ipairs(bosses) do
		if not boss.dead then
			local d = (boss.hrp.Position - hrp.Position).Magnitude - boss.radius
			if d <= w.range and d < bestDist then
				best, bestDist = boss, d
			end
		end
	end
	if not best then return end

	local dmg = Logic.weaponDamage(data, w.id)
	local crit = rng:NextNumber() < w.crit
	if crit then dmg = dmg * 2.5 end
	best.hp = best.hp - dmg
	best.damage[player] = (best.damage[player] or 0) + dmg
	best.lastHit = now
	GameService.track(player, "bossHits", 1)
	local hitPos = best.hrp.Position + Vector3.new(rng:NextNumber(-2, 2), rng:NextNumber(0, 3), rng:NextNumber(-2, 2))
	hitFlash(hitPos, RARITY_COLOR[w.rarity] or Color3.new(1, 1, 1))
	Remotes.DamagePopup:FireClient(player, dmg, crit, hitPos)
	updateBoss(best)
	if best.hp <= 0 then
		defeat(best)
	end
end

----------------------------------------------------------------------------
-- Boss-Angriffe: roter Kreis → nach kurzer Zeit Schaden
----------------------------------------------------------------------------
local function telegraph(position, radius, delay, onHit)
	local ring = Instance.new("Part")
	ring.Shape = Enum.PartType.Cylinder
	ring.Size = Vector3.new(0.3, radius * 2, radius * 2)
	ring.CFrame = CFrame.new(position.X, 0.25, position.Z) * CFrame.Angles(0, 0, math.rad(90))
	ring.Anchored = true
	ring.CanCollide = false
	ring.CanQuery = false
	ring.CanTouch = false
	ring.Material = Enum.Material.Neon
	ring.Color = Color3.fromRGB(255, 40, 60)
	ring.Transparency = 0.6
	ring.Parent = workspace
	task.delay(delay, function()
		ring.Transparency = 0.1
		ring.Color = Color3.fromRGB(255, 240, 200)
		onHit()
		Debris:AddItem(ring, 0.25)
	end)
end

local function nearbyPlayers(boss, range)
	local list = {}
	for _, player in ipairs(Players:GetPlayers()) do
		local char = player.Character
		local hrp = char and char:FindFirstChild("HumanoidRootPart")
		if hrp and (hrp.Position - boss.hrp.Position).Magnitude <= range then
			table.insert(list, { player = player, hrp = hrp })
		end
	end
	return list
end

local function hitArea(center, radius)
	for _, player in ipairs(Players:GetPlayers()) do
		local char = player.Character
		local hrp = char and char:FindFirstChild("HumanoidRootPart")
		if hrp then
			local flat = Vector3.new(hrp.Position.X - center.X, 0, hrp.Position.Z - center.Z)
			if flat.Magnitude <= radius then
				hurt(player, Config.BOSS_HIT_PERCENT)
			end
		end
	end
end

local function bossAttack(boss)
	local near = nearbyPlayers(boss, 70)
	if #near == 0 then return end
	if rng:NextNumber() < 0.5 then
		-- Schockwelle rund um den Boss
		local center = boss.hrp.Position
		local r = 18 + boss.scale * 4
		telegraph(center, r, 1.6, function() hitArea(center, r) end)
	else
		-- "Mog-Blick": gezielter Angriff auf einen Spieler (+ eventuell einen zweiten)
		for k = 1, math.min(#near, boss.world >= 5 and 2 or 1) do
			local target = near[rng:NextInteger(1, #near)]
			local center = target.hrp.Position
			telegraph(center, 9, 1.4, function() hitArea(center, 9) end)
		end
	end
end

----------------------------------------------------------------------------
-- Remotes: Waffen kaufen, verbessern, ausrüsten
----------------------------------------------------------------------------
Remotes.BuyWeapon.OnServerEvent:Connect(function(player, id)
	local data = DataService.get(player)
	local w = Logic.weaponById[id]
	if not data or not w then return end
	if Logic.weaponLevel(data, id) > 0 then return end
	if w.price <= 0 then
		GameService.notify(player, "👑 Nur als Beute", w.desc, "bad")
		return
	end
	if data.cash < w.price then
		GameService.notify(player, "💸 Zu wenig Geld", w.name .. " kostet " .. Util.format(w.price) .. " Geld. Tipp: 💼 Jobs!", "bad")
		return
	end
	data.cash = data.cash - w.price
	data.weapons[id] = 1
	data.weapon = id
	CombatService.giveTool(player)
	GameService.notify(player, w.emoji .. " " .. w.name .. " gekauft!", "Ausgerüstet – ab zum nächsten Boss!", "good")
	GameService.sendFull(player)
end)

Remotes.UpgradeWeapon.OnServerEvent:Connect(function(player, id)
	local data = DataService.get(player)
	local w = Logic.weaponById[id]
	if not data or not w then return end
	local level = Logic.weaponLevel(data, id)
	if level <= 0 or level >= Config.WEAPON_MAX_LEVEL then return end
	local cost = Logic.weaponUpgradeCost(id, level)
	if data.cash < cost then
		GameService.notify(player, "💸 Zu wenig Geld", "Verbessern kostet " .. Util.format(cost) .. " Geld.", "bad")
		return
	end
	data.cash = data.cash - cost
	data.weapons[id] = level + 1
	if data.weapon == id then CombatService.giveTool(player) end
	GameService.notify(player, w.emoji .. " " .. w.name .. " verbessert!", "Jetzt Stufe " .. (level + 1) .. ".", "good")
	GameService.sendFull(player)
end)

Remotes.EquipWeapon.OnServerEvent:Connect(function(player, id)
	local data = DataService.get(player)
	if not data or Logic.weaponLevel(data, id) <= 0 then return end
	data.weapon = id
	CombatService.giveTool(player)
	GameService.sendFull(player)
end)

----------------------------------------------------------------------------
-- Start
----------------------------------------------------------------------------
function CombatService.init(npcEntries)
	for _, entry in ipairs(npcEntries) do
		if entry.isBoss then
			local hrp = entry.prompt.Parent
			local model = hrp and hrp.Parent
			if model and model:IsA("Model") then
				local boss = {
					def = entry.def, world = entry.world, model = model, hrp = hrp, head = model:FindFirstChild("Head") or hrp,
					parent = model.Parent, scale = entry.def.scale or 1, radius = 3 * (entry.def.scale or 1),
					maxHp = entry.def.hp or Config.BossHP[entry.world] or 1000, damage = {}, lastHit = 0, dead = false, nextAttack = 0,
				}
				boss.hp = boss.maxHp
				makeHpBar(boss)
				updateBoss(boss)
				table.insert(bosses, boss)
			end
		end
	end

	-- Charaktere: Waffe geben, Selbstbewusstsein auffüllen
	table.insert(GameService.characterHooks, function(player, char)
		player:WaitForChild("Backpack", 10)
		local data = DataService.get(player)
		if data then
			if Logic.weaponLevel(data, data.weapon) <= 0 then data.weapon = Config.STARTER_WEAPON end
			setConfidence(player, Logic.maxConfidence(data))
		end
		CombatService.giveTool(player)
	end)

	-- Boss-Schleife: Angriffe & Wiederauferstehung
	task.spawn(function()
		while true do
			task.wait(0.5)
			local now = os.clock()
			for _, boss in ipairs(bosses) do
				if boss.dead then
					if now >= boss.respawnAt then
						boss.dead = false
						boss.hp = boss.maxHp
						boss.model.Parent = boss.parent
						updateBoss(boss)
					end
				elseif now - boss.lastHit < 20 and now >= boss.nextAttack then
					boss.nextAttack = now + Config.BOSS_ATTACK_EVERY
					bossAttack(boss)
				elseif now - boss.lastHit > 60 and boss.hp < boss.maxHp then
					-- niemand kämpft mehr: Boss heilt sich
					boss.hp = boss.maxHp
					boss.damage = {}
					updateBoss(boss)
				end
			end
		end
	end)

	-- Selbstbewusstsein regeneriert sich langsam
	task.spawn(function()
		while true do
			task.wait(1)
			for _, player in ipairs(Players:GetPlayers()) do
				local data = DataService.get(player)
				if data then
					local max = Logic.maxConfidence(data)
					local conf = player:GetAttribute("Conf") or max
					if conf < max and os.clock() - (lastHurt[player] or 0) > 5 then
						setConfidence(player, conf + max * 0.08)
					elseif player:GetAttribute("MaxConf") ~= max then
						setConfidence(player, math.min(conf, max))
					end
				end
			end
		end
	end)
end

Players.PlayerRemoving:Connect(function(player)
	lastAttack[player] = nil
	lastHurt[player] = nil
	for _, boss in ipairs(bosses) do
		boss.damage[player] = nil
	end
end)

return CombatService
