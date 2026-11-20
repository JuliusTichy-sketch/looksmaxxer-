--[[
	TRADESERVICE – Pets & Geld zwischen Spielern tauschen.

	Sicherheit gegen Betrug:
	  1) Handel startet nur, wenn beide zustimmen
	  2) Beide müssen "Bereit" drücken, danach beide "Bestätigen"
	  3) Jede Änderung am Angebot setzt Bereit & Bestätigen zurück
	  4) Der Server prüft vor dem Tausch alles noch einmal (Besitz, Geld, Platz)
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config"))
local Logic = require(Shared:WaitForChild("Logic"))
local Util = require(Shared:WaitForChild("Util"))
local Remotes = require(script.Parent.Remotes)
local DataService = require(script.Parent.DataService)
local GameService = require(script.Parent.GameService)
local PetService = require(script.Parent.PetService)

local TradeService = {}
local requests = {}   -- [Ziel] = { from, t }
local active = {}     -- [Spieler] = trade
local lastRequest = {}

local function findPet(data, uid)
	for i, pet in ipairs(data.pets) do
		if pet.uid == uid then return pet, i end
	end
	return nil
end

local function otherOf(trade, player)
	return trade.a == player and trade.b or trade.a
end

local function offerInfo(trade, owner)
	local data = DataService.get(owner)
	local o = trade.offer[owner]
	local pets = {}
	if data then
		for _, uid in ipairs(o.pets) do
			local pet = findPet(data, uid)
			if pet then table.insert(pets, { uid = pet.uid, id = pet.id, tier = pet.tier }) end
		end
	end
	return { pets = pets, cash = o.cash }
end

local function send(trade)
	for _, viewer in ipairs({ trade.a, trade.b }) do
		local other = otherOf(trade, viewer)
		Remotes.TradeUpdate:FireClient(viewer, {
			otherName = other.DisplayName,
			mine = offerInfo(trade, viewer), theirs = offerInfo(trade, other),
			myReady = trade.ready[viewer] == true, theirReady = trade.ready[other] == true,
			myConfirm = trade.confirmed[viewer] == true, theirConfirm = trade.confirmed[other] == true,
		})
	end
end

local function close(trade, reason)
	for _, p in ipairs({ trade.a, trade.b }) do
		if active[p] == trade then active[p] = nil end
		if p.Parent then Remotes.TradeClosed:FireClient(p, reason) end
	end
end

local function resetAgreement(trade)
	trade.ready = {}
	trade.confirmed = {}
end

----------------------------------------------------------------------------
-- Anfrage
----------------------------------------------------------------------------
function TradeService.request(from, target)
	if from == target or active[from] or active[target] then
		GameService.notify(from, "🤝 Geht gerade nicht", "Einer von euch handelt schon.", "bad")
		return
	end
	local last = lastRequest[from]
	if last and os.clock() - last < Config.TRADE_COOLDOWN then
		GameService.notify(from, "⏳ Kurz warten", "Du kannst gleich wieder eine Handelsanfrage schicken.", "")
		return
	end
	lastRequest[from] = os.clock()
	requests[target] = { from = from, t = os.clock() }
	Remotes.TradeRequest:FireClient(target, from.DisplayName, from.UserId)
	GameService.notify(from, "🤝 Anfrage gesendet", target.DisplayName .. " muss noch annehmen …", "")
end

Remotes.TradeRespond.OnServerEvent:Connect(function(target, accept, fromUserId)
	local req = requests[target]
	requests[target] = nil
	if not req or not req.from.Parent or req.from.UserId ~= fromUserId or os.clock() - req.t > 20 then return end
	local from = req.from
	if not accept then
		GameService.notify(from, "🙅 Abgelehnt", target.DisplayName .. " will gerade nicht handeln.", "")
		return
	end
	if active[from] or active[target] then return end
	local trade = { a = from, b = target, offer = {}, ready = {}, confirmed = {}, done = false }
	trade.offer[from] = { pets = {}, cash = 0 }
	trade.offer[target] = { pets = {}, cash = 0 }
	active[from] = trade
	active[target] = trade
	send(trade)
end)

----------------------------------------------------------------------------
-- Angebot ändern, Bereit, Bestätigen, Abbrechen
----------------------------------------------------------------------------
Remotes.TradeOffer.OnServerEvent:Connect(function(player, petUids, cash)
	local trade = active[player]
	local data = DataService.get(player)
	if not trade or not data or trade.done then return end
	local list, seen = {}, {}
	if type(petUids) == "table" then
		for _, uid in ipairs(petUids) do
			uid = tonumber(uid)
			if uid and not seen[uid] and findPet(data, uid) and #list < Config.TRADE_MAX_PETS then
				seen[uid] = true
				table.insert(list, uid)
			end
		end
	end
	cash = math.clamp(math.floor(tonumber(cash) or 0), 0, math.floor(data.cash))
	trade.offer[player] = { pets = list, cash = cash }
	resetAgreement(trade)   -- jede Änderung: alle müssen neu zustimmen
	send(trade)
end)

Remotes.TradeReady.OnServerEvent:Connect(function(player, ready)
	local trade = active[player]
	if not trade or trade.done then return end
	trade.ready[player] = ready == true
	trade.confirmed = {}
	send(trade)
end)

local function execute(trade)
	local A, B = trade.a, trade.b
	local da, db = DataService.get(A), DataService.get(B)
	if not da or not db then close(trade, "Ein Spieler ist weg."); return end
	local oa, ob = trade.offer[A], trade.offer[B]
	-- alles noch einmal prüfen
	for _, pair in ipairs({ { da, oa }, { db, ob } }) do
		for _, uid in ipairs(pair[2].pets) do
			if not findPet(pair[1], uid) then close(trade, "Ein Pet ist nicht mehr da – Handel abgebrochen."); return end
		end
		if pair[1].cash < pair[2].cash then close(trade, "Nicht genug Geld – Handel abgebrochen."); return end
	end
	if #da.pets - #oa.pets + #ob.pets > Config.MAX_PET_INVENTORY or #db.pets - #ob.pets + #oa.pets > Config.MAX_PET_INVENTORY then
		close(trade, "Ein Inventar wäre zu voll (max. " .. Config.MAX_PET_INVENTORY .. " Pets).")
		return
	end
	trade.done = true
	local function move(fromData, toData, uids)
		for _, uid in ipairs(uids) do
			local pet, i = findPet(fromData, uid)
			table.remove(fromData.pets, i)
			table.insert(toData.pets, { uid = toData.nextPetId, id = pet.id, tier = pet.tier, eq = false })
			toData.nextPetId = toData.nextPetId + 1
			toData.index[pet.id] = true
		end
	end
	move(da, db, oa.pets)
	move(db, da, ob.pets)
	da.cash = da.cash - oa.cash + ob.cash
	db.cash = db.cash - ob.cash + oa.cash
	for _, p in ipairs({ A, B }) do
		GameService.track(p, "trades", 1)
		PetService.rebuildModels(p)
		GameService.sendFull(p)
		DataService.save(p)   -- Handel sofort speichern
	end
	GameService.notify(A, "🤝 Handel abgeschlossen!", "Mit " .. B.DisplayName .. ".", "good")
	GameService.notify(B, "🤝 Handel abgeschlossen!", "Mit " .. A.DisplayName .. ".", "good")
	close(trade, "done")
end

Remotes.TradeConfirm.OnServerEvent:Connect(function(player)
	local trade = active[player]
	if not trade or trade.done then return end
	local other = otherOf(trade, player)
	if not (trade.ready[player] and trade.ready[other]) then return end
	trade.confirmed[player] = true
	if trade.confirmed[other] then
		execute(trade)
	else
		send(trade)
	end
end)

Remotes.TradeCancel.OnServerEvent:Connect(function(player)
	local trade = active[player]
	if trade and not trade.done then
		close(trade, player.DisplayName .. " hat den Handel abgebrochen.")
	end
end)

----------------------------------------------------------------------------
-- "Handeln"-Knopf an jedem Spieler (Taste F)
----------------------------------------------------------------------------
local function addPrompt(player, char)
	local hrp = char:WaitForChild("HumanoidRootPart", 10)
	if not hrp then return end
	local old = hrp:FindFirstChild("TradePrompt")
	if old then old:Destroy() end
	local pr = Instance.new("ProximityPrompt")
	pr.Name = "TradePrompt"
	pr.ActionText = "Handeln"
	pr.ObjectText = player.DisplayName
	pr.KeyboardKeyCode = Enum.KeyCode.F
	pr.HoldDuration = 0.5
	pr.MaxActivationDistance = 12
	pr.RequiresLineOfSight = false
	pr.UIOffset = Vector2.new(0, 70)
	pr.Parent = hrp
	pr.Triggered:Connect(function(from)
		if from ~= player then TradeService.request(from, player) end
	end)
end
table.insert(GameService.characterHooks, addPrompt)

Players.PlayerRemoving:Connect(function(player)
	local trade = active[player]
	if trade and not trade.done then
		close(trade, player.DisplayName .. " hat das Spiel verlassen.")
	end
	requests[player] = nil
	lastRequest[player] = nil
end)

return TradeService
