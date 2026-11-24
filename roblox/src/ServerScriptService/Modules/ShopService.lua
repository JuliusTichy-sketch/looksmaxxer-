--[[
	SHOPSERVICE – Ausrüstung & Fahrzeuge kaufen/ausrüsten (mit Geld oder Gems),
	Fahrzeug aufsteigen/absteigen.
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Logic = require(Shared:WaitForChild("Logic"))
local Util = require(Shared:WaitForChild("Util"))
local Remotes = require(script.Parent.Remotes)
local DataService = require(script.Parent.DataService)
local GameService = require(script.Parent.GameService)

local ShopService = {}
local KINDS = { aura = true, trail = true, hat = true, emote = true, vehicle = true }

local function pay(player, data, def)
	if def.currency == "gems" then
		if data.gems < def.price then
			GameService.notify(player, "💎 Zu wenig Gems", def.name .. " kostet " .. Util.format(def.price) .. " Gems. Gems gibt's im 💎 Shop, am Glücksrad & bei Events.", "bad")
			return false
		end
		data.gems = data.gems - def.price
	else
		if data.cash < def.price then
			GameService.notify(player, "💸 Zu wenig Geld", def.name .. " kostet " .. Util.format(def.price) .. " Geld. Tipp: 💼 Jobs & Bosse!", "bad")
			return false
		end
		data.cash = data.cash - def.price
	end
	return true
end

Remotes.BuyItem.OnServerEvent:Connect(function(player, kind, id)
	local data = DataService.get(player)
	if not data or not KINDS[kind] then return end
	local def = Logic.itemDef(kind, id)
	if not def or Logic.ownsItem(data, kind, id) then return end
	if not pay(player, data, def) then return end
	if kind == "vehicle" then
		data.vehicles[id] = true
		data.vehicle = id
	else
		data.cosmetics.owned[id] = true
		if kind ~= "emote" then data.cosmetics[kind] = id end
	end
	GameService.notify(player, def.emoji .. " " .. def.name .. " gekauft!", kind == "vehicle" and "Drücke V (oder den Knopf) zum Aufsteigen." or "Ausgerüstet!", "good")
	GameService.refreshCharacter(player)
	GameService.sendFull(player)
end)

Remotes.EquipItem.OnServerEvent:Connect(function(player, kind, id)
	local data = DataService.get(player)
	if not data or not KINDS[kind] or kind == "emote" then return end
	id = tostring(id or "")
	if id ~= "" and not Logic.ownsItem(data, kind, id) then return end
	if kind == "vehicle" then
		data.vehicle = id
		if id == "" then player:SetAttribute("Riding", false) end
	else
		-- gleiches Teil nochmal = ablegen
		if data.cosmetics[kind] == id then id = "" end
		data.cosmetics[kind] = id
	end
	GameService.refreshCharacter(player)
	GameService.sendFull(player)
end)

Remotes.ToggleRide.OnServerEvent:Connect(function(player)
	local data = DataService.get(player)
	if not data then return end
	if (data.vehicle or "") == "" or not Logic.ownsItem(data, "vehicle", data.vehicle) then
		GameService.notify(player, "🛹 Kein Fahrzeug", "Kaufe eins im Menü ✨ Ausrüstung → Fahrzeuge.", "")
		return
	end
	player:SetAttribute("Riding", not player:GetAttribute("Riding"))
	GameService.refreshCharacter(player)
end)

-- Nach dem Respawn nicht mehr fahren
table.insert(GameService.characterHooks, function(player)
	player:SetAttribute("Riding", false)
end)

return ShopService
