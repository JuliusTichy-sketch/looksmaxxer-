--[[
	REWARDSERVICE – tägliche Belohnungen (7-Tage-Serie), Promo-Codes und Tränke.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config"))
local Logic = require(Shared:WaitForChild("Logic"))
local Util = require(Shared:WaitForChild("Util"))
local Remotes = require(script.Parent.Remotes)
local DataService = require(script.Parent.DataService)
local GameService = require(script.Parent.GameService)
local PetService = require(script.Parent.PetService)

local RewardService = {}
local DAY = 20 * 3600         -- nach 20 Stunden gibt es die nächste Belohnung
local STREAK_RESET = 48 * 3600

local function addPotion(data, id)
	local p = Logic.potionById[id]
	if not p then return end
	local now = os.time()
	data.potions[id] = math.max(now, data.potions[id] or 0) + p.duration
end

-- Belohnung gutschreiben, gibt einen Beschreibungstext zurück
local function give(player, data, reward)
	local parts = {}
	if reward.cash then
		-- scale = mit Lohn-Bonus (Glow & Rebirths) verrechnen, damit es auch später noch lohnt
		local cash = math.floor(reward.cash * (reward.scale and Logic.jobPayMult(data) or 1))
		data.cash = data.cash + cash
		table.insert(parts, "💵 " .. Util.format(cash) .. " Geld")
	end
	if reward.gems then
		data.gems = data.gems + reward.gems
		table.insert(parts, "💎 " .. Util.format(reward.gems) .. " Gems")
	end
	if reward.spins then
		data.wheel.spins = data.wheel.spins + reward.spins
		table.insert(parts, "🎡 " .. reward.spins .. "x Glücksrad")
	end
	if reward.auraSeconds then
		local aps = math.max(Logic.aps(data, GameService.currentWorld(player), os.time()), 5)
		local gain = aps * reward.auraSeconds
		GameService.addAura(data, gain)
		table.insert(parts, "✨ " .. Util.format(gain) .. " Aura")
	end
	if reward.potion then
		addPotion(data, reward.potion)
		local p = Logic.potionById[reward.potion]
		table.insert(parts, p.emoji .. " " .. p.name)
	end
	if reward.freeEgg then
		-- Box der besten freigeschalteten Welt
		local best = 1
		for i = 1, #Config.Worlds do
			if Logic.worldUnlocked(data, i) then best = i end
		end
		local station = (type(reward.freeEgg) == "number") and reward.freeEgg or 2   -- Standard: Silber-Box
		task.delay(1, function()
			if player.Parent then PetService.hatch(player, Config.eggIndex(best, station), 1, true) end
		end)
		table.insert(parts, Config.EggStations[station].emoji .. " gratis " .. Config.EggStations[station].name)
	end
	return table.concat(parts, " · ")
end
RewardService.give = give
RewardService.addPotion = addPotion

Remotes.ClaimDaily.OnServerEvent:Connect(function(player)
	local data = DataService.get(player)
	if not data then return end
	local now = os.time()
	local since = now - data.daily.last
	if since < DAY then
		GameService.notify(player, "⏳ Noch nicht", "Nächste Belohnung in " .. Util.formatTime(DAY - since) .. ".", "")
		return
	end
	if since > STREAK_RESET then
		data.daily.streak = 0
	end
	data.daily.streak = (data.daily.streak % #Config.Daily) + 1
	data.daily.last = now
	local text = give(player, data, Config.Daily[data.daily.streak])
	GameService.notify(player, "📅 Tag " .. data.daily.streak .. " von 7!", text, "good")
	GameService.sendFull(player)
end)

Remotes.RedeemCode.OnServerEvent:Connect(function(player, code)
	local data = DataService.get(player)
	if not data or type(code) ~= "string" then return end
	code = string.upper((string.gsub(code, "%s", "")))
	local reward = Config.Codes[code]
	if not reward then
		GameService.notify(player, "❌ Ungültiger Code", "Diesen Code gibt es nicht (mehr).", "bad")
		return
	end
	if data.codes[code] then
		GameService.notify(player, "✅ Schon eingelöst", "Diesen Code hast du bereits benutzt.", "")
		return
	end
	data.codes[code] = true
	local text = give(player, data, reward)
	GameService.notify(player, "🎟️ " .. reward.text, text, "good")
	GameService.sendFull(player)
end)

Remotes.BuyPotion.OnServerEvent:Connect(function(player, id, withGems)
	local data = DataService.get(player)
	local p = Logic.potionById[id]
	if not data or not p or p.hidden then return end
	if withGems and p.gems then
		if data.gems < p.gems then
			GameService.notify(player, "💎 Zu wenig Gems", p.name .. " kostet " .. p.gems .. " Gems.", "bad")
			return
		end
		data.gems = data.gems - p.gems
		addPotion(data, id)
		GameService.notify(player, p.emoji .. " " .. p.name, p.desc, "good")
		GameService.sendFull(player)
		return
	end
	if data.cash < p.price then
		GameService.notify(player, "💸 Zu wenig Geld", p.name .. " kostet " .. Util.format(p.price) .. " Geld.", "bad")
		return
	end
	data.cash = data.cash - p.price
	addPotion(data, id)
	GameService.notify(player, p.emoji .. " " .. p.name, p.desc, "good")
	GameService.sendFull(player)
end)

----------------------------------------------------------------------------
-- 🎡 GLÜCKSRAD
----------------------------------------------------------------------------
Remotes.SpinWheel.OnServerEvent:Connect(function(player)
	local data = DataService.get(player)
	if not data then return end
	local now = os.time()
	if data.wheel.spins > 0 then
		data.wheel.spins = data.wheel.spins - 1
	elseif now - data.wheel.last >= Config.WHEEL_COOLDOWN then
		data.wheel.last = now
	else
		GameService.notify(player, "🎡 Noch nicht", "Nächste Gratis-Drehung in " .. Util.formatTime(Config.WHEEL_COOLDOWN - (now - data.wheel.last)) .. ".", "")
		return
	end
	local total = 0
	for _, seg in ipairs(Config.Wheel) do total = total + seg.weight end
	local x = Random.new():NextNumber() * total
	local index = #Config.Wheel
	for i, seg in ipairs(Config.Wheel) do
		x = x - seg.weight
		if x <= 0 then index = i break end
	end
	local seg = Config.Wheel[index]
	-- Gewinn sofort gutschreiben (geht auch beim Verlassen nicht verloren), Anzeige erst nach der Dreh-Animation
	local text = give(player, data, seg.reward)
	Remotes.WheelResult:FireClient(player, index)
	task.delay(4, function()
		if not player.Parent then return end
		GameService.notify(player, "🎡 Gewonnen: " .. seg.label, text, "good")
		GameService.sendFull(player)
	end)
end)

----------------------------------------------------------------------------
-- 🎁 SPIELZEIT-GESCHENKE (pro Spielsitzung)
----------------------------------------------------------------------------
-- Spielzeit zählt pro Tag (UTC) und wird gespeichert: Neu-Beitreten setzt die Geschenke NICHT zurück.
local lastTick = {}   -- [player] = os.time() der letzten Zählung
local function today() return os.date("!%Y-%m-%d") end

local function syncPlaytime(player, data)
	local pt = data.playtime
	local now = os.time()
	if pt.day ~= today() then
		pt.day = today()
		pt.seconds = 0
		pt.claimed = {}
	end
	pt.seconds = pt.seconds + math.max(0, now - (lastTick[player] or now))
	lastTick[player] = now
	-- Anzeige im Glücksrad-Menü: "JoinTime" so setzen, dass jetzt - JoinTime = heutige Spielzeit
	player:SetAttribute("JoinTime", now - pt.seconds)
	for gi = 1, #Config.PlaytimeGifts do
		player:SetAttribute("Gift" .. gi, pt.claimed[tostring(gi)] == true or nil)
	end
end

table.insert(GameService.joinHooks, function(player, data)
	lastTick[player] = os.time()
	syncPlaytime(player, data)
end)
task.spawn(function()
	while true do
		task.wait(30)
		for _, player in ipairs(game:GetService("Players"):GetPlayers()) do
			local data = DataService.get(player)
			if data and lastTick[player] then syncPlaytime(player, data) end
		end
	end
end)
Remotes.ClaimPlaytime.OnServerEvent:Connect(function(player, i)
	local data = DataService.get(player)
	local idx = tonumber(i)
	local gift = idx and Config.PlaytimeGifts[idx]
	if not data or not gift or not lastTick[player] then return end
	syncPlaytime(player, data)
	local key = tostring(idx)
	if data.playtime.claimed[key] then return end
	if data.playtime.seconds < gift.minutes * 60 then
		GameService.notify(player, "⏳ Noch nicht", "Dieses Geschenk gibt es nach " .. gift.minutes .. " Minuten Spielzeit (heute).", "")
		return
	end
	data.playtime.claimed[key] = true
	player:SetAttribute("Gift" .. key, true)
	local text = give(player, data, gift.reward)
	GameService.notify(player, "🎁 Spielzeit-Geschenk!", text, "good")
	GameService.sendFull(player)
end)
game:GetService("Players").PlayerRemoving:Connect(function(player)
	local data = DataService.get(player)
	if data and lastTick[player] then syncPlaytime(player, data) end
	lastTick[player] = nil
end)


return RewardService
