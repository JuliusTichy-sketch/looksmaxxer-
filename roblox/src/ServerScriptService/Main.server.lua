--[[
	MAIN – startet das Spiel auf dem Server.
	Reihenfolge: Remotes → Karte bauen → Systeme starten → Spieler laden.
]]

local Players = game:GetService("Players")

local Modules = script.Parent:WaitForChild("Modules")
local Remotes = require(Modules.Remotes)
local DataService = require(Modules.DataService)
local MapBuilder = require(Modules.MapBuilder)
local GameService = require(Modules.GameService)
local PetService = require(Modules.PetService)
local BattleService = require(Modules.BattleService)
local LeaderboardService = require(Modules.LeaderboardService)
require(Modules.RewardService)
require(Modules.QuestService)
require(Modules.JobService)
require(Modules.TradeService)
local FanService = require(Modules.FanService)
local CombatService = require(Modules.CombatService)

-- 1) Karte mit allen 8 Welten bauen
MapBuilder.build()

-- 2) Geschenkbox-Stände verbinden
for _, entry in ipairs(MapBuilder.eggPrompts) do
	entry.prompt.Triggered:Connect(function(player)
		PetService.hatch(player, entry.egg.index, entry.count, false)
	end)
end

-- 3) Portale verbinden: freigeschaltet → reisen, sonst Welten-Menü öffnen
for _, entry in ipairs(MapBuilder.portals) do
	entry.prompt.Triggered:Connect(function(player)
		local data = DataService.get(player)
		if not data then return end
		local Logic = require(game:GetService("ReplicatedStorage").Shared.Logic)
		if Logic.worldUnlocked(data, entry.target) then
			GameService.teleport(player, entry.target)
		else
			Remotes.OpenMenu:FireClient(player, "worlds")
		end
	end)
end

-- 4) Mog Battles, Bosskämpfe, Fans & Rangliste starten
BattleService.init(MapBuilder.npcs)
CombatService.init(MapBuilder.npcs)
task.spawn(FanService.init)   -- im Hintergrund (das Erstellen der Figuren dauert kurz)
LeaderboardService.init(MapBuilder.boardRows)

-- 5) Spieler
Players.PlayerAdded:Connect(GameService.playerAdded)
for _, player in ipairs(Players:GetPlayers()) do
	task.spawn(GameService.playerAdded, player)
end
Players.PlayerRemoving:Connect(function(player)
	DataService.release(player)
end)

-- 6) Jede Sekunde Aura verteilen
GameService.start()

print("[Looksmaxxer 3000] Server gestartet – viel Spaß beim Glow-Up! ✨")
