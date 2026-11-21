--[[
	BATTLESERVICE – Mog Battles
	• gegen andere Spieler (Anfrage → Annehmen/Ablehnen)
	• gegen den Rivalen und den Boss jeder Welt
	• gegen Endboss LEON (mit Chance auf das geheime Pet)

	Ablauf: 5 zufällige Kategorien, in jeder werden die Punkte verglichen
	(mit ±25 % Glück). Wer 3 Runden gewinnt, moggt.
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

local BattleService = {}
local rng = Random.new()
local cooldowns = {}   -- [player] = { [key] = Zeitpunkt }
local pending = {}     -- [Herausgeforderter] = { from = Spieler, t = Zeit }

local function onCooldown(player, key, seconds)
	cooldowns[player] = cooldowns[player] or {}
	local last = cooldowns[player][key]
	local now = os.clock()
	if last and now - last < seconds then
		return math.ceil(seconds - (now - last))
	end
	return nil
end
local function setCooldown(player, key)
	cooldowns[player] = cooldowns[player] or {}
	cooldowns[player][key] = os.clock()
end

-- Kämpfer-Daten
local function playerFighter(player)
	local data = DataService.get(player)
	if not data then return nil end
	return { name = player.DisplayName, levels = data.levels, rebirths = data.rebirths }
end

local function npcFighter(def)
	local levels = {}
	for _, u in ipairs(Config.Upgrades) do
		levels[u.id] = def.level
	end
	return { name = def.name, levels = levels, rebirths = def.rebirths }
end

-- Den Kampf ausrechnen
function BattleService.simulate(A, B)
	local cats = Util.shuffle(Util.copy(Config.Categories), rng)
	local rounds, wins = {}, 0
	for i = 1, 5 do
		local c = cats[i]
		local a = Logic.catScore(A.levels, c.id, A.rebirths) * rng:NextNumber(0.75, 1.25) + rng:NextNumber(0, 4)
		local b = Logic.catScore(B.levels, c.id, B.rebirths) * rng:NextNumber(0.75, 1.25) + rng:NextNumber(0, 4)
		if a > b then wins = wins + 1 end
		table.insert(rounds, { cat = c.id, a = a, b = b })
	end
	return rounds, wins, wins >= 3
end

-- Runden aus Sicht des Gegners umdrehen
local function flip(rounds)
	local out = {}
	for i, r in ipairs(rounds) do
		out[i] = { cat = r.cat, a = r.b, b = r.a }
	end
	return out
end

----------------------------------------------------------------------------
-- Kampf gegen NPCs (Rivalen & Bosse)
----------------------------------------------------------------------------
function BattleService.fightNPC(player, entry)
	local data = DataService.get(player)
	if not data then return end
	local def, world, isBoss = entry.def, entry.world, entry.isBoss
	if not Logic.worldUnlocked(data, world) then return end
	local key = (isBoss and "boss" or "rival") .. world .. def.name
	local wait = onCooldown(player, key, isBoss and Config.BOSS_COOLDOWN or Config.RIVAL_COOLDOWN)
	if wait then
		GameService.notify(player, "⏳ Verschnaufpause", def.name .. " erholt sich noch " .. wait .. " s.", "")
		return
	end
	setCooldown(player, key)

	local me = playerFighter(player)
	local rounds, wins, won = BattleService.simulate(me, npcFighter(def))
	local now = os.time()
	local aps = math.max(Logic.aps(data, GameService.currentWorld(player), now), 1)
	local reward = { aura = 0, cash = 0 }
	local special = nil
	local text

	if won then
		data.mogWins = data.mogWins + 1
		if isBoss then
			data.bossWins = data.bossWins + 1
			reward.aura = math.max(500, aps * 300)
			reward.cash = def.final and 100000 or 200 * world * world
			text = def.final and "Die ganze Stadt rastet aus. Leon setzt wortlos seine Sonnenbrille auf und geht."
				or string.format(Config.MogWin[rng:NextInteger(1, #Config.MogWin)], def.name)
		else
			reward.aura = math.max(100, aps * 60)
			reward.cash = 25 * world * world
			text = string.format(Config.MogWin[rng:NextInteger(1, #Config.MogWin)], def.name)
		end
		GameService.addAura(data, reward.aura)
		data.cash = data.cash + reward.cash
	else
		data.mogLosses = data.mogLosses + 1
		text = def.final and "Leon hat dich nicht mal angeschaut – und trotzdem gewonnen."
			or string.format(Config.MogLose[rng:NextInteger(1, #Config.MogLose)], def.name)
	end

	Remotes.BattleResult:FireClient(player, {
		opponent = def.name, isBoss = isBoss, final = def.final == true,
		taunt = isBoss and Config.BossTaunts[rng:NextInteger(1, #Config.BossTaunts)] or nil,
		rounds = rounds, wins = wins, won = won, reward = reward, text = text,
	})

	-- Belohnungen für Boss-Siege: eine kostenlose Box der Welt (+ Chance auf Leons Goldfisch)
	if won and isBoss then
		task.delay(6, function()
			if not player.Parent then return end
			if def.final and rng:NextNumber() < Config.SECRET_CHANCE then
				PetService.givePet(player, Config.SECRET_PET)
				PetService.announce(player.DisplayName .. " hat LEON besiegt und das GEHEIME Pet 🐠 Leons Goldfisch erbeutet!")
			else
				PetService.hatch(player, Config.eggIndex(world, 2), 1, true)   -- gratis Silber-Box
			end
		end)
	end
	GameService.sendFull(player)
end

----------------------------------------------------------------------------
-- Spieler gegen Spieler
----------------------------------------------------------------------------
local function addPrompt(player, char)
	local hrp = char:WaitForChild("HumanoidRootPart", 10)
	if not hrp then return end
	local old = hrp:FindFirstChild("MogPrompt")
	if old then old:Destroy() end
	local pr = Instance.new("ProximityPrompt")
	pr.Name = "MogPrompt"
	pr.ActionText = "Mog Battle"
	pr.ObjectText = player.DisplayName
	pr.HoldDuration = 0.5
	pr.MaxActivationDistance = 12
	pr.RequiresLineOfSight = false
	pr.Parent = hrp
	pr.Triggered:Connect(function(challenger)
		if challenger == player then return end
		BattleService.challenge(challenger, player)
	end)
end

function BattleService.challenge(challenger, target)
	if not DataService.get(challenger) or not DataService.get(target) then return end
	local wait = onCooldown(challenger, "pvp" .. target.UserId, Config.PVP_COOLDOWN)
	if wait then
		GameService.notify(challenger, "⏳ Kurz warten", "Du kannst " .. target.DisplayName .. " in " .. wait .. " s wieder herausfordern.", "")
		return
	end
	setCooldown(challenger, "pvp" .. target.UserId)
	pending[target] = { from = challenger, t = os.clock() }
	Remotes.BattleRequest:FireClient(target, challenger.DisplayName, challenger.UserId)
	GameService.notify(challenger, "⚔️ Herausforderung gesendet", target.DisplayName .. " muss noch annehmen …", "")
end

Remotes.BattleRespond.OnServerEvent:Connect(function(target, accept, fromUserId)
	local req = pending[target]
	pending[target] = nil
	if not req or not req.from.Parent or req.from.UserId ~= fromUserId then return end
	if os.clock() - req.t > 20 then return end
	local challenger = req.from
	if not accept then
		GameService.notify(challenger, "🙅 Abgelehnt", target.DisplayName .. " hat sich nicht getraut.", "bad")
		return
	end
	local A, B = playerFighter(challenger), playerFighter(target)
	if not A or not B then return end
	local rounds, wins, won = BattleService.simulate(A, B)
	local winner = won and challenger or target
	local loser = won and target or challenger
	local wd, ld = DataService.get(winner), DataService.get(loser)
	local reward = { aura = math.max(100, Logic.aps(wd, GameService.currentWorld(winner), os.time()) * 60), cash = 50 }
	GameService.addAura(wd, reward.aura)
	wd.cash = wd.cash + reward.cash
	wd.mogWins = wd.mogWins + 1
	ld.mogLosses = ld.mogLosses + 1

	Remotes.BattleResult:FireClient(challenger, {
		opponent = target.DisplayName, rounds = rounds, wins = wins, won = won,
		reward = won and reward or { aura = 0, cash = 0 },
		text = won and string.format(Config.MogWin[1], target.DisplayName) or string.format(Config.MogLose[2], target.DisplayName),
	})
	Remotes.BattleResult:FireClient(target, {
		opponent = challenger.DisplayName, rounds = flip(rounds), wins = 5 - wins, won = not won,
		reward = (not won) and reward or { aura = 0, cash = 0 },
		text = (not won) and string.format(Config.MogWin[1], challenger.DisplayName) or string.format(Config.MogLose[2], challenger.DisplayName),
	})
	if wins == 5 or wins == 0 then
		PetService.announce(winner.DisplayName .. " hat " .. loser.DisplayName .. " mit 5:0 komplett gemoggt! 💀")
	end
	GameService.sendFull(challenger)
	GameService.sendFull(target)
end)

----------------------------------------------------------------------------
-- Start
----------------------------------------------------------------------------
function BattleService.init(npcEntries)
	for _, entry in ipairs(npcEntries) do
		entry.prompt.Triggered:Connect(function(player)
			BattleService.fightNPC(player, entry)
		end)
	end
	table.insert(GameService.characterHooks, addPrompt)
end

Players.PlayerRemoving:Connect(function(player)
	cooldowns[player] = nil
	pending[player] = nil
end)

return BattleService
