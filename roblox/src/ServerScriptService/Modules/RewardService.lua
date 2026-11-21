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
		data.cash = data.cash + reward.cash
		table.insert(parts, "💵 " .. Util.format(reward.cash) .. " Geld")
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
		task.delay(1, function()
			if player.Parent then PetService.hatch(player, Config.eggIndex(best, 2), 1, true) end   -- gratis Silber-Box
		end)
		table.insert(parts, "🎁 gratis Geschenkbox")
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

Remotes.BuyPotion.OnServerEvent:Connect(function(player, id)
	local data = DataService.get(player)
	local p = Logic.potionById[id]
	if not data or not p then return end
	if data.cash < p.price then
		GameService.notify(player, "💸 Zu wenig Geld", p.name .. " kostet " .. Util.format(p.price) .. " Geld.", "bad")
		return
	end
	data.cash = data.cash - p.price
	addPotion(data, id)
	GameService.notify(player, p.emoji .. " " .. p.name, p.desc, "good")
	GameService.sendFull(player)
end)

return RewardService
