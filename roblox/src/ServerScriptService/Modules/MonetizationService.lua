--[[
	MONETIZATIONSERVICE – Robux-Einnahmen
	• Gamepasses (einmal kaufen, für immer): VIP, Doppelte Aura, Glückspilz, +3 Pet-Plätze, 3er-Öffnen, Turbo-Laufen
	• Entwicklerprodukte (mehrfach kaufbar): Gems-Pakete, Starter-Paket, Aura-Paket

	Die IDs trägst du in Config.GamePasses / Config.DevProducts ein (siehe ANLEITUNG.md).
	Wichtig: Für Robux gibt es hier KEINE Zufallsbelohnungen (Roblox-Regeln für "paid random items").
]]

local Players = game:GetService("Players")
local MarketplaceService = game:GetService("MarketplaceService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config"))
local DataService = require(script.Parent.DataService)
local GameService = require(script.Parent.GameService)
local RewardService = require(script.Parent.RewardService)
local PetService = require(script.Parent.PetService)

local MonetizationService = {}

local passByKey, passById, productById = {}, {}, {}
for _, gp in ipairs(Config.GamePasses) do
	passByKey[gp.key] = gp
	if gp.id > 0 then passById[gp.id] = gp end
end
for _, dp in ipairs(Config.DevProducts) do
	if dp.id > 0 then productById[dp.id] = dp end
end

local function passGranted(player, data, gp)
	data.passes[gp.key] = true
	GameService.refreshCharacter(player)
	PetService.rebuildModels(player)
	GameService.sendFull(player)
end

-- Beim Betreten: Gamepasses prüfen
table.insert(GameService.joinHooks, function(player, data)
	for _, gp in ipairs(Config.GamePasses) do
		if gp.id > 0 and not data.passes[gp.key] then
			local ok, owns = pcall(function()
				return MarketplaceService:UserOwnsGamePassAsync(player.UserId, gp.id)
			end)
			if ok and owns then
				data.passes[gp.key] = true
			end
		end
	end
	GameService.sendFull(player)
end)

MarketplaceService.PromptGamePassPurchaseFinished:Connect(function(player, passId, purchased)
	local gp = passById[passId]
	local data = DataService.get(player)
	if purchased and gp and data then
		passGranted(player, data, gp)
		GameService.notify(player, gp.emoji .. " " .. gp.name .. " freigeschaltet!", "Danke für deine Unterstützung! 💖", "title")
		DataService.save(player)
	end
end)

-- Entwicklerprodukte: wird von Roblox aufgerufen, bis wir "Granted" zurückgeben
MarketplaceService.ProcessReceipt = function(info)
	local player = Players:GetPlayerByUserId(info.PlayerId)
	if not player then
		return Enum.ProductPurchaseDecision.NotProcessedYet
	end
	local data = DataService.get(player)
	if not data then
		return Enum.ProductPurchaseDecision.NotProcessedYet
	end
	-- Schon gutgeschrieben? (Roblox kann denselben Kauf mehrmals melden)
	-- Erst "Granted" melden, wenn der Stand wirklich gespeichert ist – sonst versucht Roblox es später nochmal.
	if data.purchases[info.PurchaseId] then
		if DataService.save(player) then
			return Enum.ProductPurchaseDecision.PurchaseGranted
		end
		return Enum.ProductPurchaseDecision.NotProcessedYet
	end
	local product = productById[info.ProductId]
	if not product then
		warn("[Looksmaxxer] Unbekanntes Produkt:", info.ProductId)
		return Enum.ProductPurchaseDecision.NotProcessedYet
	end
	-- Liste der Käufe klein halten: nur Einträge älter als 30 Tage entfernen
	local count = 0
	for _ in pairs(data.purchases) do count = count + 1 end
	if count > 300 then
		local cutoff = os.time() - 30 * 86400
		for id, t in pairs(data.purchases) do
			if type(t) ~= "number" or t < cutoff then data.purchases[id] = nil end
		end
	end

	local reward = product.reward
	if product.once and data.starterPack then
		-- Einmal-Paket doppelt gekauft (z. B. auf zwei Geräten): stattdessen nur die Gems
		reward = { gems = product.reward.gems or 0 }
	end
	if product.once then data.starterPack = true end
	local text = RewardService.give(player, data, reward)
	data.purchases[info.PurchaseId] = os.time()
	GameService.notify(player, product.emoji .. " " .. product.name .. " erhalten!", text .. " · Danke! 💖", "title")
	GameService.sendFull(player)
	if DataService.save(player) then
		return Enum.ProductPurchaseDecision.PurchaseGranted
	end
	return Enum.ProductPurchaseDecision.NotProcessedYet
end

return MonetizationService
