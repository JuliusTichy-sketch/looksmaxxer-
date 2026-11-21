--[[
	PETSERVICE – Geschenkboxen öffnen, Pets ausrüsten, fusionieren, löschen.
	Die Pet-Figuren in der Welt werden hier erstellt; bewegt werden sie
	auf jedem Gerät vom Client-Skript "PetFollow".
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local MessagingService = game:GetService("MessagingService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config"))
local Logic = require(Shared:WaitForChild("Logic"))
local Util = require(Shared:WaitForChild("Util"))
local Remotes = require(script.Parent.Remotes)
local DataService = require(script.Parent.DataService)
local GameService = require(script.Parent.GameService)
local PetModels = require(Shared:WaitForChild("PetModels"))

local PetService = {}
local rng = Random.new()
local ANNOUNCE_TOPIC = "LooksmaxxerAnnounce"

----------------------------------------------------------------------------
-- Pet-Figuren in der Welt
----------------------------------------------------------------------------
local function petsFolder()
	local f = workspace:FindFirstChild("Pets")
	if not f then
		f = Instance.new("Folder")
		f.Name = "Pets"
		f.Parent = workspace
	end
	return f
end

function PetService.rebuildModels(player)
	local data = DataService.get(player)
	if not data then return end
	local folder = petsFolder():FindFirstChild(tostring(player.UserId))
	if not folder then
		folder = Instance.new("Folder")
		folder.Name = tostring(player.UserId)
		folder.Parent = petsFolder()
	end
	folder:ClearAllChildren()
	local char = player.Character
	local hrp = char and char:FindFirstChild("HumanoidRootPart")
	local slot = 0
	for _, pet in ipairs(data.pets) do
		if pet.eq then
			slot = slot + 1
			local def = Logic.petById[pet.id]
			if def then
				local model = PetModels.build(def, pet.tier or 1, true)
				model:SetAttribute("Owner", player.UserId)
				model:SetAttribute("Slot", slot)
				model:SetAttribute("Tier", pet.tier or 1)
				if hrp then
					model:PivotTo(hrp.CFrame * CFrame.new(slot * 2, 0, 4))
				end
				model.Parent = folder
			end
		end
	end
end

----------------------------------------------------------------------------
-- Pets im Spielstand
----------------------------------------------------------------------------
local function findPet(data, uid)
	for i, pet in ipairs(data.pets) do
		if pet.uid == uid then
			return pet, i
		end
	end
	return nil
end

local function addPet(data, id, tier)
	local pet = { uid = data.nextPetId, id = id, tier = tier or 1, eq = false }
	data.nextPetId = data.nextPetId + 1
	table.insert(data.pets, pet)
	local isNew = not data.index[id]
	data.index[id] = true
	-- automatisch ausrüsten, wenn noch ein Platz frei ist
	if Logic.equippedCount(data) < Logic.petSlots(data) then
		pet.eq = true
	end
	return pet, isNew
end

local function equipBest(data)
	for _, pet in ipairs(data.pets) do
		pet.eq = false
	end
	local sorted = Util.copy(data.pets)
	table.sort(sorted, function(a, b)
		return Logic.petBoost(a) > Logic.petBoost(b)
	end)
	for i = 1, math.min(Logic.petSlots(data), #sorted) do
		sorted[i].eq = true
	end
end

local function changed(player)
	PetService.rebuildModels(player)
	GameService.sendFull(player)
end

----------------------------------------------------------------------------
-- Weltweite Ansagen bei seltenen Funden
----------------------------------------------------------------------------
local function announceLocal(text)
	for _, p in ipairs(Players:GetPlayers()) do
		GameService.notify(p, "📢 Seltener Fund!", text, "global")
	end
end

function PetService.announce(text)
	local ok = pcall(function()
		MessagingService:PublishAsync(ANNOUNCE_TOPIC, text)
	end)
	if not ok then
		announceLocal(text)
	end
end

task.spawn(function()
	local ok = pcall(function()
		MessagingService:SubscribeAsync(ANNOUNCE_TOPIC, function(message)
			if type(message.Data) == "string" then
				announceLocal(message.Data)
			end
		end)
	end)
	if not ok then
		warn("[Looksmaxxer] MessagingService nicht verfügbar (in Studio normal).")
	end
end)

----------------------------------------------------------------------------
-- Box öffnen
----------------------------------------------------------------------------
local function roll(egg, luck, forceLegendary)
	local entries, total = {}, 0
	for _, e in ipairs(egg.pets) do
		local def = Logic.petById[e.id]
		local r = Config.Rarities[def.rarity]
		local w = e.weight
		if r.order >= 3 then
			w = w * luck
		end
		if forceLegendary and r.order < 5 then
			w = 0
		end
		if w > 0 then
			total = total + w
			table.insert(entries, { id = e.id, w = w })
		end
	end
	local x = rng:NextNumber() * total
	for _, e in ipairs(entries) do
		x = x - e.w
		if x <= 0 then
			return e.id
		end
	end
	return entries[#entries].id
end

-- free = true: kostenlos (Belohnung)
function PetService.hatch(player, eggIndex, count, free)
	local data = DataService.get(player)
	local egg = Config.Eggs[eggIndex]
	if not data or not egg then return end
	count = (count == 3) and 3 or 1
	if count == 3 and Logic.perkLevel(data, "triple") < 1 then
		GameService.notify(player, "🎁 3er-Öffnen gesperrt", "Kaufe 3er-Öffnen im Rebirth-Shop.", "bad")
		return
	end
	if not Logic.worldUnlocked(data, egg.world) then
		GameService.notify(player, "🔒 Gesperrt", "Diese Welt ist noch nicht freigeschaltet.", "bad")
		return
	end
	if #data.pets + count > Config.MAX_PET_INVENTORY then
		GameService.notify(player, "🎒 Inventar voll", "Lösche oder fusioniere Pets (max. " .. Config.MAX_PET_INVENTORY .. ").", "bad")
		return
	end
	local cost = egg.cost * count
	if not free then
		if data.aura < cost then
			GameService.notify(player, "💸 Zu wenig Aura", egg.name .. " kostet " .. Util.format(cost) .. " Aura.", "bad")
			return
		end
		data.aura = data.aura - cost
	end

	local luck = Logic.luck(data, os.time())
	local results = {}
	for _ = 1, count do
		data.eggsOpened = data.eggsOpened + 1
		data.pity = data.pity + 1
		local id = roll(egg, luck, data.pity >= Config.PITY)
		local def = Logic.petById[id]
		local rarity = Config.Rarities[def.rarity]
		if rarity.order >= 5 then
			data.pity = 0
			PetService.announce(player.DisplayName .. " hat ein " .. rarity.name .. "es Pet gezogen: " .. def.emoji .. " " .. def.name .. "!")
		end
		local pet, isNew = addPet(data, id, 1)
		table.insert(results, { id = id, uid = pet.uid, new = isNew })
	end
	Remotes.HatchResult:FireClient(player, results)
	changed(player)
end

-- Ein bestimmtes Pet schenken (z. B. Leons Goldfisch)
function PetService.givePet(player, id)
	local data = DataService.get(player)
	if not data or not Logic.petById[id] then return end
	local pet, isNew = addPet(data, id, 1)
	Remotes.HatchResult:FireClient(player, { { id = id, uid = pet.uid, new = isNew } })
	changed(player)
end

----------------------------------------------------------------------------
-- Remotes
----------------------------------------------------------------------------
Remotes.HatchEgg.OnServerEvent:Connect(function(player, eggIndex, count)
	PetService.hatch(player, tonumber(eggIndex), tonumber(count), false)
end)

Remotes.EquipPet.OnServerEvent:Connect(function(player, uid, equip)
	local data = DataService.get(player)
	if not data then return end
	local pet = findPet(data, uid)
	if not pet then return end
	if equip and not pet.eq then
		if Logic.equippedCount(data) >= Logic.petSlots(data) then
			GameService.notify(player, "🐾 Alle Plätze voll", "Lege zuerst ein anderes Pet ab (Plätze: " .. Logic.petSlots(data) .. ").", "bad")
			return
		end
		pet.eq = true
	elseif not equip then
		pet.eq = false
	end
	changed(player)
end)

Remotes.EquipBest.OnServerEvent:Connect(function(player)
	local data = DataService.get(player)
	if not data then return end
	equipBest(data)
	changed(player)
end)

Remotes.FusePet.OnServerEvent:Connect(function(player, uid)
	local data = DataService.get(player)
	if not data then return end
	local pet = findPet(data, uid)
	if not pet then return end
	if pet.tier >= #Config.PetTiers then
		GameService.notify(player, "💎 Maximum", "Dieses Pet ist schon Diamant.", "")
		return
	end
	-- 5 gleiche Pets (gleiche Art & Stufe) sammeln, das gewählte zuerst
	local group = { pet }
	for _, other in ipairs(data.pets) do
		if #group >= Config.FUSE_COUNT then break end
		if other ~= pet and other.id == pet.id and other.tier == pet.tier and not other.eq then
			table.insert(group, other)
		end
	end
	for _, other in ipairs(data.pets) do
		if #group >= Config.FUSE_COUNT then break end
		if other ~= pet and other.id == pet.id and other.tier == pet.tier and other.eq then
			local already = false
			for _, g in ipairs(group) do
				if g == other then already = true end
			end
			if not already then table.insert(group, other) end
		end
	end
	if #group < Config.FUSE_COUNT then
		GameService.notify(player, "🔮 Zu wenige", "Du brauchst " .. Config.FUSE_COUNT .. " gleiche Pets derselben Stufe.", "bad")
		return
	end
	local wasEquipped = false
	for _, g in ipairs(group) do
		if g.eq then wasEquipped = true end
		local _, i = findPet(data, g.uid)
		if i then table.remove(data.pets, i) end
	end
	local newTier = pet.tier + 1
	local newPet = { uid = data.nextPetId, id = pet.id, tier = newTier, eq = wasEquipped }
	data.nextPetId = data.nextPetId + 1
	table.insert(data.pets, newPet)
	local def = Logic.petById[pet.id]
	GameService.notify(player, "🔮 Fusioniert!", def.emoji .. " " .. def.name .. " ist jetzt " .. Config.PetTiers[newTier].name .. "!", "good")
	changed(player)
end)

Remotes.DeletePet.OnServerEvent:Connect(function(player, uid)
	local data = DataService.get(player)
	if not data then return end
	local _, i = findPet(data, uid)
	if i then
		table.remove(data.pets, i)
		changed(player)
	end
end)

-- Pets erscheinen, wenn der Charakter erscheint
table.insert(GameService.characterHooks, function(player)
	task.wait(1)
	PetService.rebuildModels(player)
end)

Players.PlayerRemoving:Connect(function(player)
	local f = petsFolder():FindFirstChild(tostring(player.UserId))
	if f then f:Destroy() end
end)

return PetService
