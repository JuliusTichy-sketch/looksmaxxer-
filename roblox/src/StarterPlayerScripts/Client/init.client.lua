--[[
	CLIENT – startet die Oberfläche auf dem Gerät des Spielers
	und empfängt alle Nachrichten vom Server.
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local player = Players.LocalPlayer
local Remotes = ReplicatedStorage:WaitForChild("Remotes")

local UI = require(script:WaitForChild("UI"))
local State = require(script:WaitForChild("State"))
local Sounds = require(script:WaitForChild("Sounds"))
local Effects = require(script:WaitForChild("Effects"))
local Menus = require(script:WaitForChild("Menus"))
local Hud = require(script:WaitForChild("Hud"))
local PetFollow = require(script:WaitForChild("PetFollow"))
local WorldFx = require(script:WaitForChild("WorldFx"))

-- Haupt-Oberfläche
local gui = UI.new("ScreenGui", {
	Name = "LooksmaxxerUI", ResetOnSpawn = false, ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
	Parent = player:WaitForChild("PlayerGui"),
})

Effects.init(gui)
Menus.init(gui)
Hud.init(gui)
PetFollow.init()
WorldFx.init()

-- Spielstand vom Server
local firstData = true
Remotes:WaitForChild("Data").OnClientEvent:Connect(function(kind, payload)
	if kind == "full" then
		State.setFull(payload)
		if firstData then
			firstData = false
			Sounds.setSfx(payload.data.settings.sfx ~= false)
			Sounds.setMusic(payload.data.settings.music ~= false)
		end
	else
		State.setLight(payload)
	end
end)

-- Nachrichten
Remotes:WaitForChild("Notify").OnClientEvent:Connect(function(title, text, kind)
	if kind == "title" then
		Effects.banner(title, text, UI.C.pink)
	elseif kind == "rebirth" then
		Effects.banner(title, text, UI.C.green)
	elseif kind == "offline" then
		Effects.banner(title, text, UI.C.purple)
	else
		Effects.toast(title, text, kind)
	end
end)

Remotes:WaitForChild("HatchResult").OnClientEvent:Connect(function(results)
	Effects.hatch(results)
end)

Remotes:WaitForChild("BattleResult").OnClientEvent:Connect(function(res)
	Menus.close()
	Effects.battle(res)
end)

Remotes:WaitForChild("BattleRequest").OnClientEvent:Connect(function(name, userId)
	Effects.battleRequest(name, userId, function(accept, uid)
		Remotes.BattleRespond:FireServer(accept, uid)
	end)
end)

Remotes:WaitForChild("OpenMenu").OnClientEvent:Connect(function(name)
	Menus.open(name)
end)

-- Begrüßung
task.delay(2, function()
	Effects.toast("✨ Willkommen bei Looksmaxxer 3000!", "Klicke auf Daily Routine, kauf Upgrades und öffne die 🎁 Geschenkbox!", "title")
end)
