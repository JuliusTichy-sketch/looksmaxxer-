--[[
	QUESTSERVICE – tägliche Aufträge (3 pro Tag) und Erfolge (je 4 Stufen).

	Aufträge: Beim ersten Login des Tages werden 3 zufällige Aufträge gewählt.
	Der Fortschritt = Zählerstand jetzt – Zählerstand beim Erstellen.
	Erfolge: zählen über die ganze Spielzeit.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config"))
local Logic = require(Shared:WaitForChild("Logic"))
local Remotes = require(script.Parent.Remotes)
local DataService = require(script.Parent.DataService)
local GameService = require(script.Parent.GameService)
local RewardService = require(script.Parent.RewardService)

local QuestService = {}

local function today()
	return math.floor(os.time() / 86400)
end

-- Neue Aufträge erstellen, wenn ein neuer Tag angefangen hat
function QuestService.ensureQuests(player, data)
	local day = today()
	if data.quests.day == day and #data.quests.list > 0 then
		return
	end
	local rng = Random.new(day * 1000 + (player.UserId % 1000))
	local pool = {}
	for _, q in ipairs(Config.QuestPool) do
		table.insert(pool, q)
	end
	local list = {}
	for _ = 1, math.min(Config.QUESTS_PER_DAY, #pool) do
		local q = table.remove(pool, rng:NextInteger(1, #pool))
		table.insert(list, { id = q.id, stat = q.stat, goal = q.goal, text = string.format(q.text, q.goal),
			start = Logic.statValue(data, q.stat), claimed = false })
	end
	data.quests = { day = day, list = list, bonus = false }
end

Remotes.ClaimQuest.OnServerEvent:Connect(function(player, index)
	local data = DataService.get(player)
	if not data then return end
	QuestService.ensureQuests(player, data)
	local q = data.quests.list[tonumber(index) or 0]
	if not q or q.claimed then return end
	if Logic.questProgress(data, q) < q.goal then
		GameService.notify(player, "📋 Noch nicht geschafft", q.text, "bad")
		return
	end
	q.claimed = true
	local text = RewardService.give(player, data, Config.QuestReward)
	GameService.notify(player, "📋 Auftrag erledigt!", text, "good")
	GameService.sendFull(player)
end)

Remotes.ClaimQuestBonus.OnServerEvent:Connect(function(player)
	local data = DataService.get(player)
	if not data or data.quests.bonus then return end
	for _, q in ipairs(data.quests.list) do
		if not q.claimed then
			GameService.notify(player, "📋 Noch nicht", "Erledige zuerst alle Aufträge von heute.", "bad")
			return
		end
	end
	data.quests.bonus = true
	local text = RewardService.give(player, data, Config.QuestBonus)
	GameService.notify(player, "🏆 Alle Aufträge geschafft!", text, "title")
	GameService.sendFull(player)
end)

Remotes.ClaimAchievement.OnServerEvent:Connect(function(player, id)
	local data = DataService.get(player)
	if not data then return end
	local ach
	for _, a in ipairs(Config.Achievements) do
		if a.id == id then ach = a end
	end
	if not ach then return end
	local claimed = data.achievements[id] or 0
	local nextTier = claimed + 1
	local goal = ach.tiers[nextTier]
	if not goal then return end
	if Logic.statValue(data, ach.stat) < goal then
		GameService.notify(player, "🏅 Noch nicht", ach.name .. ": " .. goal .. " " .. ach.text .. " nötig.", "bad")
		return
	end
	data.achievements[id] = nextTier
	local text = RewardService.give(player, data, Logic.achievementReward(nextTier))
	GameService.notify(player, "🏅 Erfolg: " .. ach.name .. " " .. string.rep("⭐", nextTier), text, "title")
	GameService.sendFull(player)
end)

-- Beim Betreten Aufträge prüfen; zusätzlich jede Minute (falls Mitternacht vorbei ist)
table.insert(GameService.joinHooks, function(player, data)
	QuestService.ensureQuests(player, data)
end)
task.spawn(function()
	while true do
		task.wait(60)
		for player, data in pairs(DataService.all()) do
			if data.quests.day ~= today() then
				QuestService.ensureQuests(player, data)
				GameService.notify(player, "📋 Neue Aufträge!", "Ein neuer Tag – 3 neue Aufträge warten auf dich.", "good")
				GameService.sendFull(player)
			end
		end
	end
end)

return QuestService
