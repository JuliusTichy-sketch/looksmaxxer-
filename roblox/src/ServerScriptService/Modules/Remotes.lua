--[[
	REMOTES – die "Leitungen" zwischen Server und Spieler.
	Der Server erstellt sie beim Start in ReplicatedStorage/Remotes.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Remotes = {}

local EVENTS = {
	-- Server -> Spieler
	"Data",           -- Spielstand senden ("full" oder "light")
	"Notify",         -- Nachricht anzeigen (titel, text, art)
	"HatchResult",    -- Ergebnis beim Box-Öffnen
	"BattleResult",   -- Ergebnis eines Mog Battles
	"BattleRequest",  -- jemand fordert dich heraus
	"OpenMenu",       -- Menü öffnen (z. B. Welten am Portal)
	"FanDialog",      -- Fan-Gespräch öffnen
	"FanResult",      -- Ergebnis des Fan-Gesprächs
	"DamagePopup",    -- Schadenszahl im Bosskampf
	"TradeRequest",   -- jemand will mit dir handeln
	"TradeUpdate",    -- aktueller Stand des Handels
	"TradeClosed",    -- Handel beendet
	"WheelResult",    -- Ergebnis des Glücksrads
	"GymStart",       -- Gym-Minispiel starten
	-- Spieler -> Server
	"Click", "BuyUpgrade", "Rebirth", "BuyPerk",
	"EquipPet", "EquipBest", "FusePet", "DeletePet", "HatchEgg",
	"Teleport", "UnlockWorld",
	"BattleRespond",
	"ClaimDaily", "RedeemCode", "BuyPotion", "Setting",
	"ClaimQuest", "ClaimQuestBonus", "ClaimAchievement",
	"StartJob", "FinishJob",
	"FanChoice",
	"BuyWeapon", "UpgradeWeapon", "EquipWeapon",
	"TradeRespond", "TradeOffer", "TradeReady", "TradeConfirm", "TradeCancel",
	"SpinWheel", "ClaimPlaytime",
	"BuyItem", "EquipItem", "ToggleRide",
	"GymFinish",
}

-- Erst alle Leitungen anlegen, dann den Ordner sichtbar machen
local folder = Instance.new("Folder")
folder.Name = "Remotes"

for _, name in ipairs(EVENTS) do
	local ev = Instance.new("RemoteEvent")
	ev.Name = name
	ev.Parent = folder
	Remotes[name] = ev
end

local lb = Instance.new("RemoteFunction")
lb.Name = "GetLeaderboard"
lb.Parent = folder
Remotes.GetLeaderboard = lb

folder.Parent = ReplicatedStorage

return Remotes
