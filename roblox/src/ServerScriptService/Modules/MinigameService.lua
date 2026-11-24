--[[
	MINIGAMESERVICE – Minispiele auf der Karte
	🧗 Dach-Parkour (Glow City): Springe von Plattform zu Plattform bis ganz nach oben. Mit Checkpoints.
	🏁 Laufsteg-Rennen (Mailand): So schnell wie möglich vom Start zum Ziel. Bestzeit wird gespeichert.
	💪 Gym-Training (Glow City & Iron Mountain): Rhythmus-Minispiel → Gym-Pump (+50 % Aura für 3 Minuten).
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
local RewardService = require(script.Parent.RewardService)

local MinigameService = {}
local raceStart = {}     -- [player] = os.clock()
local gymStart = {}      -- [player] = os.clock()
local touchDebounce = {} -- [player .. part] = Zeit

local function playerFromHit(hit)
	local char = hit and hit.Parent
	local player = char and Players:GetPlayerFromCharacter(char)
	if not player then
		-- Teil eines Fahrzeugs/Huts? Eine Ebene höher suchen
		char = char and char.Parent
		player = char and Players:GetPlayerFromCharacter(char)
	end
	return player
end

local function debounce(player, key, seconds)
	local k = player.UserId .. key
	local now = os.clock()
	if touchDebounce[k] and now - touchDebounce[k] < seconds then return false end
	touchDebounce[k] = now
	return true
end

local function teleportTo(player, cf)
	local char = player.Character
	if char then char:PivotTo(cf) end
end

----------------------------------------------------------------------------
-- 🧗 Dach-Parkour
----------------------------------------------------------------------------
local function initObby(obby)
	obby.start.Triggered:Connect(function(player)
		local cp = player:GetAttribute("ObbyCheckpoint") or 0
		local target = (cp > 0 and obby.checkpoints[cp]) or obby.first
		teleportTo(player, target.CFrame * CFrame.new(0, 4, 0))
		GameService.notify(player, "🧗 Dach-Parkour", cp > 0 and ("Weiter ab Checkpoint " .. cp .. "!") or "Spring nach oben bis zum goldenen Pokal!", "")
	end)
	for i, cpPart in ipairs(obby.checkpoints) do
		cpPart.Touched:Connect(function(hit)
			local player = playerFromHit(hit)
			if player and (player:GetAttribute("ObbyCheckpoint") or 0) < i then
				player:SetAttribute("ObbyCheckpoint", i)
				GameService.notify(player, "🚩 Checkpoint " .. i, "Falls du fällst: am Start-Knopf geht's hier weiter.", "")
			end
		end)
	end
	obby.finish.Touched:Connect(function(hit)
		local player = playerFromHit(hit)
		local data = player and DataService.get(player)
		if not data or not debounce(player, "obbyFinish", 5) then return end
		player:SetAttribute("ObbyCheckpoint", 0)
		local now = os.time()
		if now - data.records.obbyLast < Config.OBBY_COOLDOWN then
			GameService.notify(player, "🏆 Geschafft!", "Nächste Belohnung in " .. Util.formatTime(Config.OBBY_COOLDOWN - (now - data.records.obbyLast)) .. ".", "good")
		else
			data.records.obbyLast = now
			GameService.track(player, "obby", 1)
			local text = RewardService.give(player, data, Config.ObbyReward)
			GameService.notify(player, "🏆 DACH-PARKOUR GESCHAFFT!", text, "title")
			GameService.sendFull(player)
		end
		task.delay(2, function()
			if player.Parent then teleportTo(player, obby.start.Parent.CFrame * CFrame.new(0, 4, 6)) end
		end)
	end)
end

----------------------------------------------------------------------------
-- 🧗 Parkour-Strecken in den Welten 2–8 (Bojen, Gipfel, Lava-Tempel, Shopping, Stunt, Wolkenkratzer, Planeten)
----------------------------------------------------------------------------
local function initCourse(c)
	local attr = "CP_" .. c.id
	local function backToCheckpoint(player)
		local cp = player:GetAttribute(attr) or 0
		local target = (cp > 0 and c.checkpoints[cp]) or c.first
		if target then teleportTo(player, target.CFrame * CFrame.new(0, 4, 0)) end
	end
	c.start.Triggered:Connect(function(player)
		local cp = player:GetAttribute(attr) or 0
		backToCheckpoint(player)
		GameService.notify(player, "🧗 " .. c.title, cp > 0 and ("Weiter ab Checkpoint " .. cp .. "!") or "Los geht's – ab zum goldenen Pokal!", "")
	end)
	for i, cpPart in ipairs(c.checkpoints) do
		cpPart.Touched:Connect(function(hit)
			local player = playerFromHit(hit)
			if player and (player:GetAttribute(attr) or 0) < i then
				player:SetAttribute(attr, i)
				GameService.notify(player, "🚩 Checkpoint " .. i, "Wenn du fällst, geht's hier weiter.", "")
			end
		end)
	end
	-- Lava / Wasser: zurück zum letzten Checkpoint
	for _, kill in ipairs(c.kills) do
		kill.Touched:Connect(function(hit)
			local player = playerFromHit(hit)
			if player and debounce(player, "kill" .. c.id, 1.2) then
				backToCheckpoint(player)
			end
		end)
	end
	c.finish.Touched:Connect(function(hit)
		local player = playerFromHit(hit)
		local data = player and DataService.get(player)
		if not data or not debounce(player, "finish" .. c.id, 5) then return end
		player:SetAttribute(attr, 0)
		local now = os.time()
		local last = data.records.courses[c.id] or 0
		if now - last < Config.OBBY_COOLDOWN then
			GameService.notify(player, "🏆 Geschafft!", "Nächste Belohnung hier in " .. Util.formatTime(Config.OBBY_COOLDOWN - (now - last)) .. ".", "good")
		else
			data.records.courses[c.id] = now
			GameService.track(player, "obby", 1)
			local text = RewardService.give(player, data, c.reward)
			GameService.notify(player, "🏆 " .. c.title .. " geschafft!", text, "title")
			GameService.sendFull(player)
		end
		task.delay(2.5, function()
			if player.Parent then teleportTo(player, c.startCf * CFrame.new(0, 4, -6)) end
		end)
	end)
end

----------------------------------------------------------------------------
-- 🏁 Laufsteg-Rennen
----------------------------------------------------------------------------
local function initRace(race)
	race.start.Touched:Connect(function(hit)
		local player = playerFromHit(hit)
		if not player or not debounce(player, "raceStart", 2) then return end
		raceStart[player] = os.clock()
		player:SetAttribute("RaceStart", workspace:GetServerTimeNow())
	end)
	race.finish.Touched:Connect(function(hit)
		local player = playerFromHit(hit)
		local data = player and DataService.get(player)
		local started = player and raceStart[player]
		if not data or not started then return end
		raceStart[player] = nil
		player:SetAttribute("RaceStart", nil)
		local t = os.clock() - started
		if t < 3 then return end   -- zu schnell = unmöglich
		local factor = math.clamp(Config.RACE_TARGET / t, 0.3, 2)
		local cash = math.floor(Config.RaceReward.cash * Logic.jobPayMult(data) * factor * Logic.cashMult(data))
		data.cash = data.cash + cash
		local best = data.records.raceBest
		local newBest = best == 0 or t < best
		if newBest then data.records.raceBest = t end
		GameService.track(player, "race", 1)
		GameService.notify(player, "🏁 Ziel! " .. string.format("%.2f", t) .. " s" .. (newBest and " – NEUE BESTZEIT!" or ""),
			"+" .. Util.format(cash) .. " Geld · Bestzeit: " .. string.format("%.2f", data.records.raceBest) .. " s", newBest and "title" or "good")
		GameService.sendFull(player)
	end)
end

----------------------------------------------------------------------------
-- 💪 Gym-Training
----------------------------------------------------------------------------
local function initGym(prompt)
	prompt.Triggered:Connect(function(player)
		local data = DataService.get(player)
		if not data then return end
		local wait = Config.GYM_COOLDOWN - (os.time() - data.records.gymLast)
		if wait > 0 then
			GameService.notify(player, "😮‍💨 Pause", "Deine Muskeln brauchen noch " .. wait .. " s.", "")
			return
		end
		gymStart[player] = os.clock()
		Remotes.GymStart:FireClient(player)
	end)
end

Remotes.GymFinish.OnServerEvent:Connect(function(player, hits)
	local data = DataService.get(player)
	local started = gymStart[player]
	gymStart[player] = nil
	if not data or not started then return end
	local elapsed = os.clock() - started
	if elapsed < 3 or elapsed > 90 then return end
	hits = math.clamp(math.floor(tonumber(hits) or 0), 0, 8)
	data.records.gymLast = os.time()
	GameService.track(player, "gym", 1)
	if hits >= 4 then
		RewardService.addPotion(data, "pump")
		local cash = math.floor(40 * hits * Logic.jobPayMult(data) * Logic.cashMult(data))
		data.cash = data.cash + cash
		GameService.notify(player, "💪 GYM-PUMP! (" .. hits .. "/8)", "+50 % Aura für 3 Minuten · +" .. Util.format(cash) .. " Geld", "title")
	else
		GameService.notify(player, "😅 Zu wenig Wiederholungen (" .. hits .. "/8)", "Mindestens 4 Treffer für den Gym-Pump. Gleich nochmal!", "bad")
	end
	GameService.sendFull(player)
end)

function MinigameService.init(info)
	if info.obby then initObby(info.obby) end
	if info.race then initRace(info.race) end
	for _, prompt in ipairs(info.gyms or {}) do initGym(prompt) end
	for _, c in ipairs(info.courses or {}) do initCourse(c) end
end

Players.PlayerRemoving:Connect(function(player)
	raceStart[player] = nil
	gymStart[player] = nil
end)

return MinigameService
