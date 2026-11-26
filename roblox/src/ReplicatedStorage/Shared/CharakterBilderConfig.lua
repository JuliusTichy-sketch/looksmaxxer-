--[[
	CHARAKTER-BILDER – Vorher/Nachher-Bild des Charakters im 💪 Upgrades-Menü.

	██████████████████████████████████████████████████████████████████████
	██  HIER DIE BILD-IDs EINTRAGEN                                     ██
	██  So bekommst du die ID: Studio → Asset Manager (oder Toolbox →   ██
	██  "Meine Bilder") → Rechtsklick aufs Bild → "Copy Asset ID".      ██
	██  Dann zwischen die Anführungszeichen einfügen, z. B.:            ██
	██      VORHER = "rbxassetid://1234567890",                          ██
	██████████████████████████████████████████████████████████████████████
]]

local CharakterBilderConfig = {

	-- 🧟 Charakter_Vorher.png  (alle Attribute auf Minimum)
	VORHER = "rbxassetid://130585970837388",   -- Charakter_Vorher (hochgeladen am 26.11.2026)

	-- 😎 Charakter_Nachher.png (alle Attribute komplett gemaxxt)
	NACHHER = "rbxassetid://124633394210800",  -- Charakter_Nachher (hochgeladen am 26.11.2026)

	-- Optional für später: Zwischenbilder. "ab" = Fortschritt von 0 bis 1 (0.5 = 50 %).
	-- Das Spiel blendet dann immer zwischen den zwei passenden Bildern über.
	ZWISCHEN = {
		-- { ab = 0.5, id = "rbxassetid://..." },
	},

	----------------------------------------------------------------------------
	-- Einstellungen (normalerweise nicht ändern)
	----------------------------------------------------------------------------
	-- Diese 7 Kategorien zählen für den Glow-Up (Selbstbewusstsein "conf" absichtlich nicht)
	ATTRIBUTE = { "skin", "hair", "fit", "sleep", "posture", "style", "teeth" },

	-- Kurve: 1 = genau linear. Kleiner als 1 = frühe Upgrades sind schon deutlicher sichtbar.
	-- 0.5 bedeutet: 10 % Fortschritt → ca. 32 % sichtbar, 50 % → ca. 71 %. 0 % und 100 % bleiben exakt.
	KURVE = 0.5,

	SEITENVERHAELTNIS = 876 / 1080,   -- Breite ÷ Höhe der Bilder (0.811)
	UEBERGANG_SEKUNDEN = 0.6,         -- Dauer der weichen Überblendung
}

return CharakterBilderConfig
