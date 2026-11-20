--[[
	JOBSERVICE – Geld verdienen mit Jobs.
	Ablauf: Spieler startet Job → Minispiel läuft auf dem Gerät →
	Ergebnis (3 Versuche) wird geschickt → Server prüft und zahlt.
	Je höher Glow-Score & Rebirths, desto mehr Lohn.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config"))
local Logic = require(Shared:WaitForChild("Logic"))
local Util = require(Shared:WaitForChild("Util"))
local Remotes = require(script.Parent.Remotes)
local DataService = require(script.Parent.DataService)
local GameService = require(script.Parent.GameService)

local JobService = {}
local running = {}   -- [player] = { id, start }

local jobById = {}
for _, j in ipairs(Config.Jobs) do
	jobById[j.id] = j
end

Remotes.StartJob.OnServerEvent:Connect(function(player, id)
	local data = DataService.get(player)
	local job = jobById[id]
	if not data or not job then return end
	if Logic.baseGlow(data.levels) < job.req then
		GameService.notify(player, "🔒 Gesperrt", job.name .. " gibt es ab " .. Util.format(job.req) .. " Glow.", "bad")
		return
	end
	local untilTime = data.jobCd[id] or 0
	if untilTime > os.time() then
		GameService.notify(player, "⏳ Pause", "Noch " .. Util.formatTime(untilTime - os.time()) .. " Pause.", "")
		return
	end
	running[player] = { id = id, start = os.clock() }
end)

Remotes.FinishJob.OnServerEvent:Connect(function(player, id, scores)
	local data = DataService.get(player)
	local run = running[player]
	running[player] = nil
	local job = jobById[id]
	if not data or not job or not run or run.id ~= id then return end
	local elapsed = os.clock() - run.start
	if elapsed < 1.5 or elapsed > 120 or type(scores) ~= "table" then return end

	-- 3 Versuche: 1 = perfekt, 0.6 = gut, 0.1 = daneben
	local total, perfect = 0, 0
	for i = 1, 3 do
		local s = tonumber(scores[i]) or 0.1
		if s >= 1 then s = 1; perfect = perfect + 1 elseif s >= 0.6 then s = 0.6 else s = 0.1 end
		total = total + s
	end
	local perf = total / 3
	if perfect == 3 then perf = perf * 1.25 end
	local earned = math.max(1, math.floor(Logic.jobPay(data, job) * perf))
	data.cash = data.cash + earned
	data.jobCd[id] = os.time() + job.cd
	GameService.track(player, "jobs", 1)
	local quip = perf >= 1.1 and "Der Kunde ist begeistert und will dich wieder buchen! 🤩"
		or (perf >= 0.6 and "Solide Arbeit. Der Chef nickt anerkennend." or "Naja … bezahlt wurdest du trotzdem. Irgendwie.")
	GameService.notify(player, job.emoji .. " Zahltag: +" .. Util.format(earned) .. " Geld", quip, "good")
	GameService.sendFull(player)
end)

Players.PlayerRemoving:Connect(function(player)
	running[player] = nil
end)

return JobService
