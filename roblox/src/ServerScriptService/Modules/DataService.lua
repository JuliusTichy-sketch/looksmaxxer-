--[[
	DATASERVICE – lädt und speichert den Spielstand jedes Spielers (DataStore).

	Wichtig: Damit das Speichern in Roblox Studio funktioniert, muss das Spiel
	veröffentlicht sein und unter Game Settings > Security
	"Enable Studio Access to API Services" eingeschaltet sein.
]]

local DataStoreService = game:GetService("DataStoreService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config"))

local DataService = {}

local store = nil
local okStore, errStore = pcall(function()
	store = DataStoreService:GetDataStore(Config.SAVE_KEY)
end)
if not okStore then
	warn("[Looksmaxxer] DataStore nicht verfügbar – es wird NICHT gespeichert:", errStore)
end

local profiles = {}   -- [player] = Spielstand
local loadedOk = {}   -- [player] = true, wenn erfolgreich geladen (nur dann speichern!)

-- So sieht ein neuer Spielstand aus
local function defaultData()
	return {
		version = 1,
		aura = 0, totalAura = 0, cash = 0, clicks = 0,
		levels = {},                 -- [upgradeId] = Stufe
		rebirths = 0, rebirthPoints = 0,
		perks = {},                  -- [perkId] = Stufe
		worlds = { ["1"] = true },   -- freigeschaltete Welten
		pets = {},                   -- Liste: { uid, id, tier, eq }
		nextPetId = 1,
		index = {},                  -- Sammelbuch: [petId] = true
		eggsOpened = 0, pity = 0,
		mogWins = 0, mogLosses = 0, bossWins = 0,
		bestTitle = 1,
		daily = { last = 0, streak = 0 },
		codes = {},                  -- eingelöste Codes
		potions = {},                -- [potionId] = Ende (os.time)
		settings = { music = true, sfx = true },
		lastOnline = 0,
		stats = {},                  -- Zähler für Aufträge & Erfolge
		quests = { day = 0, list = {}, bonus = false },
		achievements = {},           -- [erfolgId] = abgeholte Stufen
		jobCd = {},                  -- [jobId] = Ende der Pause (os.time)
		weapons = { zahnbuerste = 1 }, -- [waffeId] = Stufe
		weapon = "zahnbuerste",      -- ausgerüstete Waffe
		gems = 0,                    -- Premium-Währung (Robux-Shop, Glücksrad, Events)
		passes = {},                 -- gekaufte Gamepasses
		purchases = {},              -- verarbeitete Robux-Käufe (gegen doppeltes Gutschreiben)
		starterPack = false,
		eventTokens = {},            -- [eventId] = Anzahl Event-Münzen
		wheel = { last = 0, spins = 0 },
		vehicles = {},               -- [fahrzeugId] = true
		vehicle = "",                -- ausgewähltes Fahrzeug
		cosmetics = { owned = {}, aura = "", trail = "", hat = "" },
		records = { obbyLast = 0, raceBest = 0, gymLast = 0, courses = {} },
		playtime = { day = "", seconds = 0, claimed = {} },   -- Spielzeit-Geschenke pro Tag
	}
end
DataService.defaultData = defaultData

-- Fehlende Felder ergänzen (wenn das Spiel neue Funktionen bekommt)
local function reconcile(data)
	local def = defaultData()
	for k, v in pairs(def) do
		if data[k] == nil then
			data[k] = v
		elseif type(v) == "table" and type(data[k]) == "table" then
			for k2, v2 in pairs(v) do
				if data[k][k2] == nil then
					data[k][k2] = v2
				end
			end
		end
	end
	return data
end

function DataService.load(player)
	local data = nil
	local key = "u_" .. player.UserId
	if store then
		for attempt = 1, 3 do
			local ok, result = pcall(function()
				return store:GetAsync(key)
			end)
			if ok then
				data = result
				loadedOk[player] = true
				break
			end
			warn("[Looksmaxxer] Laden fehlgeschlagen (Versuch " .. attempt .. "):", result)
			task.wait(2)
		end
	end
	if type(data) ~= "table" then
		data = defaultData()
	end
	profiles[player] = reconcile(data)
	return profiles[player], loadedOk[player] == true
end

function DataService.get(player)
	return profiles[player]
end

function DataService.isSaving(player)
	return store ~= nil and loadedOk[player] == true
end

-- gibt true zurück, wenn der Stand sicher gespeichert ist (ohne DataStore, z. B. in Studio: true)
function DataService.save(player)
	local data = profiles[player]
	if not data then return false end
	if not store then return true end
	if not loadedOk[player] then return false end
	data.lastOnline = os.time()
	local ok, err = pcall(function()
		store:UpdateAsync("u_" .. player.UserId, function()
			return data
		end)
	end)
	if not ok then
		warn("[Looksmaxxer] Speichern fehlgeschlagen:", err)
	end
	return ok
end

function DataService.release(player)
	DataService.save(player)
	profiles[player] = nil
	loadedOk[player] = nil
end

function DataService.all()
	return profiles
end

-- Automatisch alle 2 Minuten speichern
task.spawn(function()
	while true do
		task.wait(120)
		for player in pairs(profiles) do
			task.spawn(DataService.save, player)
		end
	end
end)

-- Beim Herunterfahren des Servers alles speichern
game:BindToClose(function()
	local pending = 0
	for player in pairs(profiles) do
		pending = pending + 1
		task.spawn(function()
			DataService.save(player)
			pending = pending - 1
		end)
	end
	local start = os.clock()
	while pending > 0 and os.clock() - start < 25 do
		task.wait(0.2)
	end
end)

return DataService
