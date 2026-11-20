--[[
	LEADERBOARDSERVICE – globale Rangliste (Top 500) über ALLE Server.
	Gespeichert wird die "Glow-Power" jedes Spielers in einem OrderedDataStore.
	Alle 2 Minuten: eigene Werte hochladen, Top 500 neu laden.
]]

local DataStoreService = game:GetService("DataStoreService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserService = game:GetService("UserService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config"))
local Logic = require(Shared:WaitForChild("Logic"))
local Util = require(Shared:WaitForChild("Util"))
local Remotes = require(script.Parent.Remotes)
local DataService = require(script.Parent.DataService)

local LeaderboardService = {}
local store = nil
pcall(function()
	store = DataStoreService:GetOrderedDataStore(Config.LEADERBOARD_KEY)
end)

local cache = {}          -- { { rank, userId, name, value } }
local lastRefresh = 0
local nameCache = {}
local boardRows = {}

local function uploadAll()
	if not store then return end
	for _, player in ipairs(Players:GetPlayers()) do
		local data = DataService.get(player)
		if data and DataService.isSaving(player) then
			local value = Logic.glowPower(data)
			if value > 0 then
				pcall(function()
					store:SetAsync(tostring(player.UserId), value)
				end)
			end
		end
	end
end

local function resolveNames(ids)
	local missing = {}
	for _, id in ipairs(ids) do
		if not nameCache[id] then table.insert(missing, id) end
	end
	-- in Paketen von 100 nachschlagen
	for i = 1, #missing, 100 do
		local chunk = {}
		for j = i, math.min(i + 99, #missing) do table.insert(chunk, missing[j]) end
		local ok, infos = pcall(function()
			return UserService:GetUserInfosByUserIdsAsync(chunk)
		end)
		if ok and infos then
			for _, info in ipairs(infos) do
				nameCache[info.Id] = info.DisplayName or info.Username
			end
		end
	end
end

local function refresh()
	if not store then return end
	local ok, pages = pcall(function()
		return store:GetSortedAsync(false, 100)
	end)
	if not ok or not pages then return end
	local list = {}
	while true do
		for _, entry in ipairs(pages:GetCurrentPage()) do
			table.insert(list, { userId = tonumber(entry.key), value = entry.value })
			if #list >= Config.LEADERBOARD_SIZE then break end
		end
		if #list >= Config.LEADERBOARD_SIZE or pages.IsFinished then break end
		local okNext = pcall(function() pages:AdvanceToNextPageAsync() end)
		if not okNext then break end
	end
	local ids = {}
	for _, e in ipairs(list) do table.insert(ids, e.userId) end
	resolveNames(ids)
	for i, e in ipairs(list) do
		e.rank = i
		e.name = nameCache[e.userId] or ("Spieler " .. tostring(e.userId))
	end
	cache = list
	lastRefresh = os.time()

	-- Tafel in Glow City aktualisieren
	for r = 1, 10 do
		local row = boardRows[r]
		if row then
			local e = cache[r]
			local medal = ({ "🥇", "🥈", "🥉" })[r] or (r .. ".")
			row.Text = e and ("  " .. medal .. "  " .. e.name .. "  <font color='#ffd166'>" .. Util.format(e.value) .. "</font>") or ("  " .. r .. ". –")
		end
	end
end

Remotes.GetLeaderboard.OnServerInvoke = function(player)
	return { list = cache, updated = lastRefresh, available = store ~= nil }
end

function LeaderboardService.init(rows)
	boardRows = rows or {}
	task.spawn(function()
		task.wait(10)
		while true do
			uploadAll()
			refresh()
			task.wait(120)
		end
	end)
end

return LeaderboardService
