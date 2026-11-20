--[[
	==========================================================================
	CONFIG – alle Spieldaten von Looksmaxxer 3000 (Roblox-Version)
	Hier kannst du Preise, Texte, Welten, Pets usw. ganz einfach ändern.
	Diese Datei wird von Server UND Client benutzt.
	==========================================================================
]]

local Config = {}

-- Allgemeine Einstellungen
Config.MAX_LEVEL = 50               -- höchste Stufe pro Upgrade
Config.COST_GROWTH = 1.3            -- jede Stufe ist 30 % teurer
Config.SAVE_KEY = "LooksmaxxerData_v1"        -- Name des Speichers (DataStore)
Config.LEADERBOARD_KEY = "GlowPower_v1"       -- Name der globalen Rangliste
Config.LEADERBOARD_SIZE = 500                 -- so viele Plätze zeigt die Rangliste
Config.WORLD_SPACING = 1500                   -- Abstand der Welten auf der Karte (Studs)
Config.WORLD_SIZE = 500                       -- Größe einer Welt (Studs)
Config.OFFLINE_HOURS = 8                      -- maximaler Offline-Verdienst (Stunden)
Config.OFFLINE_RATE = 0.3                     -- offline gibt es 30 % der Aura/s

----------------------------------------------------------------------------
-- UPGRADE-KATEGORIEN
----------------------------------------------------------------------------
Config.Categories = {
	{ id = "skin",    name = "Skincare",           emoji = "🧴" },
	{ id = "hair",    name = "Haare",              emoji = "💇" },
	{ id = "fit",     name = "Fitness",            emoji = "💪" },
	{ id = "sleep",   name = "Schlaf & Ernährung", emoji = "😴" },
	{ id = "posture", name = "Haltung & Mewing",   emoji = "🗿" },
	{ id = "style",   name = "Style",              emoji = "👔" },
	{ id = "teeth",   name = "Zähne",              emoji = "🦷" },
	{ id = "conf",    name = "Selbstbewusstsein",  emoji = "😎" },
}

-- Name der Kategorie im Mog Battle
Config.BattleNames = {
	skin = "Hautbild", hair = "Frisur", fit = "Physique", sleep = "Ausgeschlafenheit",
	posture = "Kieferlinie", style = "Drip", teeth = "Lächeln", conf = "Ausstrahlung",
}

----------------------------------------------------------------------------
-- UPGRADES
-- base  = Startpreis (Aura)
-- aps   = Aura pro Sekunde je Stufe
-- click = extra Aura pro Klick je Stufe
-- glow  = Glow-Score je Stufe
----------------------------------------------------------------------------
Config.Upgrades = {
	-- Skincare
	{ id = "reinigung",    cat = "skin", emoji = "🧼", name = "Gesichtsreinigung",     base = 15,      aps = 0.2,  click = 0, glow = 1,  desc = "Wasser ins Gesicht. Revolutionär." },
	{ id = "feuchtigkeit", cat = "skin", emoji = "💧", name = "Feuchtigkeitscreme",    base = 120,     aps = 1.2,  click = 0, glow = 2,  desc = "Deine Haut sagt endlich Danke statt Hilfe." },
	{ id = "sonnencreme",  cat = "skin", emoji = "☀️", name = "Sonnencreme LSF 50",    base = 900,     aps = 6,    click = 0, glow = 4,  desc = "Auch im Winter. Auch drinnen. Sicher ist sicher." },
	{ id = "retinol",      cat = "skin", emoji = "🧪", name = "Retinol",               base = 7000,    aps = 30,   click = 0, glow = 8,  desc = "Klingt wie ein Endgegner, ist aber ein Serum." },
	{ id = "goldmaske",    cat = "skin", emoji = "✨", name = "Goldene Gesichtsmaske", base = 60000,   aps = 150,  click = 0, glow = 15, desc = "24 Karat im Gesicht. Dein Spiegel braucht eine Sonnenbrille." },
	-- Haare
	{ id = "friseur",      cat = "hair", emoji = "✂️", name = "Friseurbesuch",         base = 50,      aps = 0.5,  click = 0, glow = 1,  desc = "Nur die Spitzen – und er hält sich dran." },
	{ id = "styling",      cat = "hair", emoji = "🫙", name = "Styling-Produkte",      base = 600,     aps = 4,    click = 0, glow = 3,  desc = "Wachs, Gel, Paste, Clay. Du kennst den Unterschied." },
	{ id = "signature",    cat = "hair", emoji = "👑", name = "Signature-Haarschnitt", base = 12000,   aps = 50,   click = 0, glow = 10, desc = "So ikonisch, er hat eigene Follower." },
	{ id = "haarkur",      cat = "hair", emoji = "🌸", name = "Seiden-Haarkur",        base = 90000,   aps = 300,  click = 0, glow = 18, desc = "Deine Haare glänzen heller als deine Zukunft." },
	{ id = "promifriseur", cat = "hair", emoji = "💈", name = "Promi-Friseur",         base = 600000,  aps = 1500, click = 0, glow = 30, desc = "Hat schon Gigachad Sven geschnitten." },
	-- Fitness
	{ id = "liegestuetze", cat = "fit", emoji = "🤸", name = "Liegestütze",            base = 30,      aps = 0.3,  click = 0.5, glow = 1, desc = "Drei Stück. Am Stück. Fast." },
	{ id = "gym",          cat = "fit", emoji = "🏋️", name = "Gym-Abo",                base = 2500,    aps = 15,   click = 0, glow = 5,  desc = "Diesmal gehst du auch hin. Versprochen." },
	{ id = "trainer",      cat = "fit", emoji = "📣", name = "Personal Trainer",       base = 40000,   aps = 150,  click = 0, glow = 15, desc = "Schreit dich motivierend an. Du zahlst dafür." },
	{ id = "proteinplan",  cat = "fit", emoji = "🥛", name = "Protein-Plan",           base = 250000,  aps = 900,  click = 0, glow = 25, desc = "Hähnchen, Reis, Brokkoli. Für immer." },
	{ id = "wettkampf",    cat = "fit", emoji = "🏆", name = "Wettkampf-Vorbereitung", base = 2000000, aps = 6000, click = 0, glow = 45, desc = "Du posierst jetzt auch beim Zähneputzen." },
	-- Schlaf & Ernährung
	{ id = "schlaf",       cat = "sleep", emoji = "🛌", name = "8 Stunden Schlaf",     base = 80,      aps = 0.8,  click = 0, glow = 1,  desc = "Augenringe kündigen fristlos." },
	{ id = "wasser",       cat = "sleep", emoji = "🚰", name = "Wasser trinken",       base = 400,     aps = 3,    click = 0, glow = 2,  desc = "Ein Liter Wasser statt drei Energy-Drinks. Wild." },
	{ id = "kochen",       cat = "sleep", emoji = "🥗", name = "Gesund kochen",        base = 5000,    aps = 25,   click = 0, glow = 6,  desc = "Brokkoli ist jetzt dein Freund." },
	{ id = "mealprep",     cat = "sleep", emoji = "🍱", name = "Meal-Prep-Profi",      base = 80000,   aps = 260,  click = 0, glow = 14, desc = "21 Dosen im Kühlschrank. Alle beschriftet." },
	{ id = "schlaftracker", cat = "sleep", emoji = "⌚", name = "Schlaf-Tracking",     base = 900000,  aps = 2500, click = 0, glow = 32, desc = "Deine Uhr lobt dich jeden Morgen." },
	-- Haltung & Mewing
	{ id = "haltung",      cat = "posture", emoji = "🧍", name = "Gerade Haltung",     base = 200,     aps = 1.5,  click = 0, glow = 2,  desc = "Schultern zurück, Brust raus, Handy runter." },
	{ id = "mewing",       cat = "posture", emoji = "👅", name = "Mewing",             base = 1500,    aps = 8,    click = 0, glow = 4,  desc = "Zunge an den Gaumen. Für immer." },
	{ id = "yoga",         cat = "posture", emoji = "🧘", name = "Haltungs-Yoga",      base = 30000,   aps = 120,  click = 0, glow = 12, desc = "Der herabschauende Gigachad." },
	{ id = "meisterklasse", cat = "posture", emoji = "🗿", name = "Mewing-Meisterklasse", base = 100000, aps = 400, click = 0, glow = 25, desc = "Dein Kiefer kann jetzt Glas schneiden." },
	{ id = "moaimeditation", cat = "posture", emoji = "🌋", name = "Moai-Meditation",  base = 3000000, aps = 9000, click = 0, glow = 55, desc = "Du hast 3 Tage nicht geblinzelt." },
	-- Style
	{ id = "basics",       cat = "style", emoji = "👕", name = "Saubere Basics",       base = 100,     aps = 1,    click = 0, glow = 1,  desc = "Ein T-Shirt ohne Ketchup-Fleck. Ein Anfang." },
	{ id = "kleidung",     cat = "style", emoji = "🧥", name = "Passende Kleidung",    base = 3000,    aps = 18,   click = 0, glow = 5,  desc = "Klamotten in deiner Größe statt wird schon passen." },
	{ id = "parfum",       cat = "style", emoji = "🌺", name = "Parfum",               base = 20000,   aps = 90,   click = 0, glow = 10, desc = "Zwei Sprüher. Nicht zwölf. ZWEI." },
	{ id = "accessoires",  cat = "style", emoji = "⌚", name = "Accessoires",          base = 80000,   aps = 300,  click = 0, glow = 20, desc = "Uhr, Kette, Sonnenbrille im Haar." },
	{ id = "designer",     cat = "style", emoji = "👔", name = "Designer-Garderobe",   base = 1500000, aps = 4500, click = 0, glow = 40, desc = "Dein Kleiderschrank hat einen eigenen Türsteher." },
	-- Zähne
	{ id = "zahnseide",    cat = "teeth", emoji = "🧵", name = "Zahnseide",            base = 60,      aps = 0.4,  click = 0, glow = 1,  desc = "Dein Zahnarzt weint vor Freude." },
	{ id = "bleaching",    cat = "teeth", emoji = "💎", name = "Bleaching",            base = 8000,    aps = 40,   click = 0, glow = 7,  desc = "Weißer als dein Kontostand danach." },
	{ id = "zahnspange",   cat = "teeth", emoji = "😬", name = "Zahnspange",           base = 50000,   aps = 200,  click = 0, glow = 15, desc = "Kurz peinlich, dann perfekt." },
	{ id = "zahnreinigung", cat = "teeth", emoji = "🪥", name = "Profi-Zahnreinigung", base = 400000,  aps = 1200, click = 0, glow = 22, desc = "Es quietscht. Vor Sauberkeit." },
	{ id = "hollywoodsmile", cat = "teeth", emoji = "😁", name = "Hollywood-Lächeln",  base = 4000000, aps = 11000, click = 0, glow = 60, desc = "Wenn du lächelst, geht irgendwo ein Licht an." },
	-- Selbstbewusstsein (stärkt vor allem Klicks)
	{ id = "augenkontakt", cat = "conf", emoji = "👀", name = "Augenkontakt",          base = 25,      aps = 0,    click = 1,   glow = 1,  desc = "Drei Sekunden halten. Nicht starren." },
	{ id = "smalltalk",    cat = "conf", emoji = "💬", name = "Smalltalk",             base = 1000,    aps = 5,    click = 5,   glow = 3,  desc = "Du kannst jetzt übers Wetter reden. Fließend." },
	{ id = "laecheln",     cat = "conf", emoji = "🙂", name = "Lächeln",               base = 15000,   aps = 60,   click = 25,  glow = 8,  desc = "Mit den Augen lächeln. Smizing." },
	{ id = "rhetorik",     cat = "conf", emoji = "🎤", name = "Rhetorik-Kurs",         base = 200000,  aps = 500,  click = 120, glow = 20, desc = "Du sagst jetzt Synergie und meinst es ernst." },
	{ id = "buehne",       cat = "conf", emoji = "🎭", name = "Bühnen-Präsenz",        base = 2500000, aps = 7000, click = 900, glow = 50, desc = "Wenn du einen Raum betrittst, dreht sich das Licht zu dir." },
}

----------------------------------------------------------------------------
-- TITEL (ab welchem Glow-Score)
----------------------------------------------------------------------------
Config.Titles = {
	{ glow = 0,     title = "NPC",                           text = "Du bist ein Hintergrund-Charakter. Noch." },
	{ glow = 10,    title = "Statist mit Sprechrolle",       text = "Jemand hat Hallo zu dir gesagt. Absichtlich!" },
	{ glow = 40,    title = "Hat sich mal gekämmt",          text = "Deine Mutter ist stolz auf dich." },
	{ glow = 100,   title = "Gym-Anfänger mit Ambitionen",   text = "Du postest jetzt Spiegel-Selfies aus der Umkleide." },
	{ glow = 200,   title = "Side Character",                text = "Du hast jetzt eine eigene Nebenhandlung." },
	{ glow = 400,   title = "Main Character",                text = "Die Kamera folgt jetzt DIR." },
	{ glow = 800,   title = "Sigma im Praktikum",            text = "Du trinkst Kaffee schwarz und schaust nachdenklich aus dem Fenster." },
	{ glow = 1500,  title = "Model-Scout schaut zweimal",    text = "Er hat sich umgedreht. Zweimal." },
	{ glow = 2500,  title = "Chad",                          text = "Türen öffnen sich für dich. Auch die ohne Sensor." },
	{ glow = 4000,  title = "Gigachad",                      text = "Dein Kinn hat eine eigene Postleitzahl." },
	{ glow = 6500,  title = "Gigachad Ultra HD",             text = "Kameras schalten auf 4K, wenn du vorbeiläufst." },
	{ glow = 10000, title = "Kosmisches Glow-Wesen",         text = "Die Sonne benutzt DICH als Lichtquelle." },
	{ glow = 15000, title = "Mewing-Gottheit",               text = "Moai-Statuen verneigen sich vor dir." },
	{ glow = 22000, title = "Legende der Kieferlinie",       text = "Geologen untersuchen deinen Kiefer." },
	{ glow = 29000, title = "Das Universum ist neidisch",    text = "Mehr geht nicht. Wirklich nicht." },
}

----------------------------------------------------------------------------
-- WELTEN
-- mult     = Aura-Multiplikator, solange du in dieser Welt bist
-- cost     = Preis zum Freischalten (Aura)
-- rebirths = nötige Rebirths
-- theme    = welche Deko die Karte bekommt
----------------------------------------------------------------------------
Config.Worlds = {
	{ id = "glowcity",  name = "Glow City",          emoji = "🏙️", mult = 1,     cost = 0,     rebirths = 0,  theme = "city",
	  ground = Color3.fromRGB(205, 198, 215), accent = Color3.fromRGB(255, 79, 216),
	  light = { ClockTime = 14, Ambient = Color3.fromRGB(120, 110, 140), Fog = Color3.fromRGB(200, 190, 225), FogEnd = 1400 } },
	{ id = "miami",     name = "Miami Beach",        emoji = "🏖️", mult = 2,     cost = 5e4,  rebirths = 1,  theme = "beach",
	  ground = Color3.fromRGB(238, 214, 160), accent = Color3.fromRGB(0, 200, 220),
	  light = { ClockTime = 13, Ambient = Color3.fromRGB(160, 140, 110), Fog = Color3.fromRGB(255, 232, 200), FogEnd = 1400 } },
	{ id = "mountain",  name = "Iron Mountain",      emoji = "🏔️", mult = 3.5,    cost = 5e7,   rebirths = 2,  theme = "mountain",
	  ground = Color3.fromRGB(110, 140, 100), accent = Color3.fromRGB(180, 220, 255),
	  light = { ClockTime = 10, Ambient = Color3.fromRGB(130, 140, 160), Fog = Color3.fromRGB(220, 230, 245), FogEnd = 900 } },
	{ id = "tempel",    name = "Mewing-Tempel",      emoji = "🗿", mult = 5,    cost = 5e9,   rebirths = 4,  theme = "temple",
	  ground = Color3.fromRGB(120, 160, 90), accent = Color3.fromRGB(255, 160, 60),
	  light = { ClockTime = 17.6, Ambient = Color3.fromRGB(160, 110, 90), Fog = Color3.fromRGB(255, 180, 140), FogEnd = 1100 } },
	{ id = "mailand",   name = "Mailand Fashion District", emoji = "👔", mult = 7, cost = 3e11, rebirths = 6, theme = "fashion",
	  ground = Color3.fromRGB(60, 55, 70), accent = Color3.fromRGB(255, 120, 200),
	  light = { ClockTime = 19.5, Ambient = Color3.fromRGB(120, 100, 140), Fog = Color3.fromRGB(90, 70, 110), FogEnd = 1200 } },
	{ id = "hollywood", name = "Hollywood Hills",    emoji = "🎬", mult = 10,  cost = 1e13,  rebirths = 8,  theme = "hollywood",
	  ground = Color3.fromRGB(190, 160, 110), accent = Color3.fromRGB(255, 50, 60),
	  light = { ClockTime = 18, Ambient = Color3.fromRGB(170, 120, 100), Fog = Color3.fromRGB(255, 160, 120), FogEnd = 1400 } },
	{ id = "dubai",     name = "Dubai Skyline",      emoji = "🌇", mult = 14,  cost = 3e14,  rebirths = 10,  theme = "dubai",
	  ground = Color3.fromRGB(230, 200, 140), accent = Color3.fromRGB(212, 175, 55),
	  light = { ClockTime = 12, Ambient = Color3.fromRGB(180, 160, 120), Fog = Color3.fromRGB(255, 220, 160), FogEnd = 1600 } },
	{ id = "galaxie",   name = "Aura-Galaxie",       emoji = "🌌", mult = 20, cost = 5e15,  rebirths = 13, theme = "galaxy",
	  ground = Color3.fromRGB(35, 20, 60), accent = Color3.fromRGB(160, 90, 255),
	  light = { ClockTime = 0, Ambient = Color3.fromRGB(110, 80, 170), Fog = Color3.fromRGB(40, 10, 70), FogEnd = 1000 } },
}

----------------------------------------------------------------------------
-- REBIRTH
----------------------------------------------------------------------------
Config.Rebirth = {
	baseCost = 1000000,  -- erster Rebirth kostet 1 Mio. Aura
	growth = 4,          -- jeder weitere ist 4x so teuer
	multPer = 0.5,       -- jeder Rebirth = +50 % auf alle Aura
}

-- Rebirth-Shop (bezahlt mit Rebirth-Punkten)
Config.RebirthShop = {
	{ id = "petslot",   emoji = "🐾", name = "+1 Pet-Platz",         desc = "Ein Pet mehr gleichzeitig ausrüsten.",       max = 5,  baseCost = 1, costStep = 1 },
	{ id = "luck",      emoji = "🍀", name = "Glück +10 %",          desc = "Seltenere Pets aus Geschenkboxen.",          max = 10, baseCost = 1, costStep = 1 },
	{ id = "speed",     emoji = "👟", name = "Schneller laufen",     desc = "+2 Laufgeschwindigkeit pro Stufe.",          max = 5,  baseCost = 1, costStep = 0 },
	{ id = "autoclick", emoji = "🤖", name = "Auto-Routine",         desc = "Macht automatisch 2 Daily Routines pro Sekunde.", max = 1, baseCost = 3, costStep = 0 },
	{ id = "triple",    emoji = "🎁", name = "3er-Öffnen",           desc = "Öffne 3 Geschenkboxen auf einmal.",          max = 1,  baseCost = 4, costStep = 0 },
	{ id = "offline",   emoji = "😴", name = "Längerer Beauty Sleep", desc = "+2 Stunden Offline-Verdienst pro Stufe.",   max = 4,  baseCost = 2, costStep = 1 },
}

----------------------------------------------------------------------------
-- PETS & GESCHENKBOXEN
----------------------------------------------------------------------------
-- Seltenheiten: weight = Chance (relativ), mult = Stärke-Faktor
Config.Rarities = {
	common    = { order = 1, name = "Gewöhnlich",   color = Color3.fromRGB(200, 200, 210), weight = 55,  mult = 1 },
	uncommon  = { order = 2, name = "Ungewöhnlich", color = Color3.fromRGB(78, 240, 120),  weight = 27,  mult = 2 },
	rare      = { order = 3, name = "Selten",       color = Color3.fromRGB(70, 150, 255),  weight = 12,  mult = 4 },
	epic      = { order = 4, name = "Episch",       color = Color3.fromRGB(170, 90, 255),  weight = 5,   mult = 9 },
	legendary = { order = 5, name = "Legendär",     color = Color3.fromRGB(255, 200, 40),  weight = 0.9, mult = 25 },
	mythic    = { order = 6, name = "Mythisch",     color = Color3.fromRGB(255, 60, 90),   weight = 0.1, mult = 80 },
	secret    = { order = 7, name = "GEHEIM",       color = Color3.fromRGB(255, 255, 255), weight = 0,   mult = 300 },
}

-- Stufen durch Fusionieren (5 gleiche = 1 bessere)
Config.PetTiers = {
	{ name = "Normal",     mult = 1,  color = nil },
	{ name = "Gold",       mult = 3,  color = Color3.fromRGB(255, 205, 60) },
	{ name = "Regenbogen", mult = 10, color = Color3.fromRGB(255, 120, 220) },
	{ name = "Diamant",    mult = 30, color = Color3.fromRGB(150, 240, 255) },
}
Config.FUSE_COUNT = 5
Config.BASE_PET_SLOTS = 3
Config.MAX_PET_INVENTORY = 60
Config.PITY = 150                 -- spätestens nach so vielen Boxen ohne Legendär kommt eins
Config.PET_BASE_BOOST = 0.05      -- Gewöhnliches Pet in Welt 1 = +5 % Aura
Config.PET_WORLD_GROWTH = 1.5     -- jede Welt: Pets 1,5x stärker

-- Pets pro Welt: { Name, Emoji, Seltenheit }
local PET_DATA = {
	{ -- 1 Glow City
		{ "Gym-Hamster", "🐹", "common" }, { "Skincare-Katze", "🐱", "common" }, { "Mewing-Mops", "🐶", "uncommon" },
		{ "Protein-Pinguin", "🐧", "rare" }, { "Sigma-Wolf", "🐺", "epic" }, { "Golden Retriever Chad", "🐕", "legendary" },
		{ "Mini-Moai", "🗿", "mythic" },
	},
	{ -- 2 Miami Beach
		{ "Pinch-Krabbe", "🦀", "common" }, { "Strand-Möwe", "🐦", "common" }, { "Flex-Delfin", "🐬", "uncommon" },
		{ "Glow-Mingo", "🦩", "rare" }, { "Jaw-Hai", "🦈", "epic" }, { "Bronze-Schildkröte", "🐢", "legendary" },
		{ "Sonnengott-Krake", "🐙", "mythic" },
	},
	{ -- 3 Iron Mountain
		{ "Hantel-Hase", "🐰", "common" }, { "Bergziege", "🐐", "common" }, { "Eiweiß-Eule", "🦉", "uncommon" },
		{ "Eisbär-Bro", "🐻", "rare" }, { "Titan-Gorilla", "🦍", "epic" }, { "Gains-Drache", "🐉", "legendary" },
		{ "Ur-Mammut", "🐘", "mythic" },
	},
	{ -- 4 Mewing-Tempel
		{ "Meditations-Frosch", "🐸", "common" }, { "Tempel-Affe", "🐒", "common" }, { "Jade-Schlange", "🐍", "uncommon" },
		{ "Zen-Kranich", "🦢", "rare" }, { "Mönch-Panda", "🐼", "epic" }, { "Kiefer-Tiger", "🐯", "legendary" },
		{ "Ur-Moai-Geist", "👻", "mythic" },
	},
	{ -- 5 Mailand
		{ "Laufsteg-Pudel", "🐩", "common" }, { "Designer-Maus", "🐭", "common" }, { "Pfau Paolo", "🦚", "uncommon" },
		{ "Drip-Zebra", "🦓", "rare" }, { "Fashion-Fuchs", "🦊", "epic" }, { "Couture-Schwan", "🦢", "legendary" },
		{ "Il-Drippo-Einhorn", "🦄", "mythic" },
	},
	{ -- 6 Hollywood
		{ "Paparazzi-Papagei", "🦜", "common" }, { "Popcorn-Waschbär", "🦝", "common" }, { "Oscar-Otter", "🦦", "uncommon" },
		{ "Stunt-Känguru", "🦘", "rare" }, { "Red-Carpet-Löwe", "🦁", "epic" }, { "Blockbuster-Bär", "🐻", "legendary" },
		{ "Walk-of-Fame-Phönix", "🔥", "mythic" },
	},
	{ -- 7 Dubai
		{ "Gold-Kamel", "🐫", "common" }, { "Wüsten-Skorpion", "🦂", "common" }, { "Falke Faisal", "🦅", "uncommon" },
		{ "Luxus-Leopard", "🐆", "rare" }, { "Yacht-Wal", "🐋", "epic" }, { "Diamant-Drache", "🐲", "legendary" },
		{ "Scheich-Phönix", "✨", "mythic" },
	},
	{ -- 8 Aura-Galaxie
		{ "Mond-Hamster", "🌙", "common" }, { "Sternen-Katze", "⭐", "common" }, { "Komet-Hund", "💫", "uncommon" },
		{ "Alien-Bro", "👽", "rare" }, { "Nebula-Wal", "🌌", "epic" }, { "Schwarzes-Loch-Mops", "⚫", "legendary" },
		{ "Aura-Gott", "🌈", "mythic" },
	},
}

local EGG_NAMES = { "Glow-City-Box", "Strand-Box", "Gym-Box", "Tempel-Box", "Couture-Box", "Blockbuster-Box", "Gold-Box", "Galaxie-Box" }
local EGG_COSTS = { 150, 2500, 1.5e6, 1.5e8, 1e10, 3e11, 1e13, 1.5e14 }

-- Pets und Boxen werden hier automatisch aus den Listen oben erzeugt
Config.Pets = {}
Config.Eggs = {}
for w, list in ipairs(PET_DATA) do
	local egg = { index = w, world = w, name = EGG_NAMES[w], cost = EGG_COSTS[w], pets = {} }
	local counts = {}
	for _, p in ipairs(list) do
		counts[p[3]] = (counts[p[3]] or 0) + 1
	end
	local base = Config.PET_BASE_BOOST * Config.PET_WORLD_GROWTH ^ (w - 1)
	for i, p in ipairs(list) do
		local rarity = Config.Rarities[p[3]]
		local pet = {
			id = "w" .. w .. "_" .. i, name = p[1], emoji = p[2], rarity = p[3], world = w,
			boost = base * rarity.mult,
		}
		table.insert(Config.Pets, pet)
		table.insert(egg.pets, { id = pet.id, weight = rarity.weight / counts[p[3]] })
	end
	table.insert(Config.Eggs, egg)
end
-- Das geheime Pet gibt es nur, wenn man Endboss Leon besiegt
Config.SECRET_PET = "secret_goldfisch"
table.insert(Config.Pets, {
	id = Config.SECRET_PET, name = "Leons Goldfisch", emoji = "🐠", rarity = "secret", world = 8,
	boost = Config.PET_BASE_BOOST * Config.PET_WORLD_GROWTH ^ 7 * Config.Rarities.secret.mult,
})
Config.SECRET_CHANCE = 0.05   -- 5 % Chance bei einem Sieg gegen Leon

----------------------------------------------------------------------------
-- MOG-BATTLE-GEGNER: ein Rivale und ein Boss pro Welt
-- level = Stufe aller Upgrades, rebirths = Rebirths
----------------------------------------------------------------------------
Config.Rivals = {
	{ name = "Gym-Bro Dennis",    level = 1,  rebirths = 0,  shirt = Color3.fromRGB(230, 57, 70),  pants = Color3.fromRGB(40, 50, 80),  skin = Color3.fromRGB(224, 172, 105) },
	{ name = "Influencer Luca",   level = 8, rebirths = 0,  shirt = Color3.fromRGB(30, 30, 30),   pants = Color3.fromRGB(60, 60, 80),  skin = Color3.fromRGB(255, 224, 196) },
	{ name = "Hantel-Horst",      level = 25, rebirths = 5,  shirt = Color3.fromRGB(90, 90, 150),  pants = Color3.fromRGB(30, 30, 40),  skin = Color3.fromRGB(198, 134, 66) },
	{ name = "Mewing-Meister Kai", level = 35, rebirths = 7, shirt = Color3.fromRGB(240, 240, 240), pants = Color3.fromRGB(80, 60, 40), skin = Color3.fromRGB(141, 85, 36) },
	{ name = "Model Marco",       level = 42, rebirths = 10,  shirt = Color3.fromRGB(255, 120, 200), pants = Color3.fromRGB(20, 20, 20), skin = Color3.fromRGB(241, 194, 125) },
	{ name = "Stuntman Steve",    level = 46, rebirths = 13,  shirt = Color3.fromRGB(200, 120, 40), pants = Color3.fromRGB(60, 40, 30),  skin = Color3.fromRGB(224, 172, 105) },
	{ name = "Yacht-Yannick",     level = 48, rebirths = 15, shirt = Color3.fromRGB(255, 255, 255), pants = Color3.fromRGB(30, 60, 120), skin = Color3.fromRGB(255, 224, 196) },
	{ name = "Astro-Ali",         level = 49, rebirths = 16, shirt = Color3.fromRGB(200, 200, 220), pants = Color3.fromRGB(200, 200, 220), skin = Color3.fromRGB(141, 85, 36) },
}
Config.Bosses = {
	{ name = "Gigachad Sven",        level = 4, rebirths = 0,  shirt = Color3.fromRGB(29, 53, 87),   pants = Color3.fromRGB(29, 53, 87),   skin = Color3.fromRGB(241, 194, 125), scale = 1.25 },
	{ name = "Bronzer Brad",         level = 15, rebirths = 1,  shirt = Color3.fromRGB(255, 80, 60),  pants = Color3.fromRGB(255, 200, 0),  skin = Color3.fromRGB(198, 134, 66),  scale = 1.3 },
	{ name = "Der Hantel-Yeti",      level = 30, rebirths = 7,  shirt = Color3.fromRGB(240, 240, 255), pants = Color3.fromRGB(240, 240, 255), skin = Color3.fromRGB(230, 235, 255), scale = 1.45 },
	{ name = "Der Ur-Moai",          level = 40, rebirths = 9,  shirt = Color3.fromRGB(120, 120, 120), pants = Color3.fromRGB(100, 100, 100), skin = Color3.fromRGB(140, 140, 140), scale = 1.5 },
	{ name = "Il Drippo",            level = 45, rebirths = 12,  shirt = Color3.fromRGB(180, 40, 160), pants = Color3.fromRGB(20, 20, 20),  skin = Color3.fromRGB(255, 224, 196), scale = 1.3 },
	{ name = "Der Casting-Direktor", level = 48, rebirths = 14, shirt = Color3.fromRGB(20, 20, 20),   pants = Color3.fromRGB(20, 20, 20),   skin = Color3.fromRGB(224, 172, 105), scale = 1.3 },
	{ name = "Scheich Glowmed",      level = 50, rebirths = 16, shirt = Color3.fromRGB(255, 255, 255), pants = Color3.fromRGB(255, 255, 255), skin = Color3.fromRGB(198, 134, 66), scale = 1.35 },
	{ name = "LEON",                 level = 50, rebirths = 20, shirt = Color3.fromRGB(201, 162, 39), pants = Color3.fromRGB(201, 162, 39), skin = Color3.fromRGB(241, 194, 125), scale = 1.6, final = true },
}
Config.RIVAL_COOLDOWN = 30   -- Sekunden
Config.BOSS_COOLDOWN = 120
Config.PVP_COOLDOWN = 20

Config.BossTaunts = {
	"Du bist nicht mal auf meinem Radar.",
	"Ich mewe seit 2009.",
	"Mein Spiegelbild fragt MICH nach Autogrammen.",
	"Komm wieder, wenn du ein Kinn hast.",
}

Config.MogWin = {
	"%s wurde komplett gemoggt und überlegt jetzt, sich einen Bart wachsen zu lassen.",
	"%s schaut ab heute Skincare-Tutorials. Wegen dir.",
	"Totaler Mog! Die Zuschauer klatschen.",
	"%s hat kurz in den Spiegel geschaut und still gg gesagt.",
}
Config.MogLose = {
	"Du wurdest gemoggt. Ab ins Gym.",
	"%s hat dich mit einem einzigen Seitenprofil besiegt.",
	"Autsch. Selbst dein Spiegelbild schaut weg.",
}

----------------------------------------------------------------------------
-- TRÄNKE (kosten Geld)
----------------------------------------------------------------------------
Config.Potions = {
	{ id = "aura2",  emoji = "🧪", name = "Aura-Trank",  desc = "Doppelte Aura für 10 Minuten.",                 price = 300, duration = 600, aura = 2 },
	{ id = "luck2",  emoji = "🍀", name = "Glücks-Trank", desc = "Doppeltes Glück beim Öffnen für 10 Minuten.",  price = 500, duration = 600, luck = 2 },
	{ id = "click3", emoji = "🥤", name = "Klick-Shake", desc = "Dreifacher Klick-Wert für 5 Minuten.",          price = 150, duration = 300, click = 3 },
}

----------------------------------------------------------------------------
-- TÄGLICHE BELOHNUNGEN (7-Tage-Serie)
-- auraSeconds = so viele Sekunden deiner Aura/s als Bonus
----------------------------------------------------------------------------
Config.Daily = {
	{ cash = 50,   auraSeconds = 60 },
	{ cash = 100,  auraSeconds = 120 },
	{ cash = 150,  potion = "aura2" },
	{ cash = 250,  auraSeconds = 300 },
	{ cash = 400,  potion = "luck2" },
	{ cash = 600,  auraSeconds = 600 },
	{ cash = 1000, potion = "aura2", freeEgg = true },
}

----------------------------------------------------------------------------
-- PROMO-CODES (Groß-/Kleinschreibung egal, jeder Code nur einmal)
----------------------------------------------------------------------------
Config.Codes = {
	MEWING2026 = { text = "Mewing-Starterpaket", cash = 500, auraSeconds = 120 },
	GIGACHAD   = { text = "Glücks-Trank",       potion = "luck2" },
	GLOWUP     = { text = "Aura-Trank",         potion = "aura2" },
	LEON       = { text = "Leons Taschengeld",  cash = 2000 },
}

----------------------------------------------------------------------------
-- SOUNDS
-- Trage hier Sound-IDs aus der Roblox-Bibliothek ein (siehe ANLEITUNG.md),
-- z. B. "rbxassetid://123456789". Leer = kein Sound.
----------------------------------------------------------------------------
Config.Sounds = {
	Click       = "rbxasset://sounds/electronicpingshort.wav",
	Buy         = "",   -- Suchbegriff: "cash register" / "ka-ching"
	TitleUp     = "",   -- "phonk cowbell" / "level up"
	BattleStart = "",   -- "vine boom" / "bass boom"
	BattleWin   = "",   -- "phonk drop" / "victory"
	BattleLose  = "",   -- "sad trombone" / "fail"
	Hatch       = "",   -- "drum roll"
	HatchRare   = "",   -- "anime wow" / "choir"
	Rebirth     = "",   -- "power up"
	Error       = "",   -- "error" / "bruh"
	Notify      = "",   -- "notification" / "pop"
}
-- Hintergrundmusik pro Welt (1–8). Leer = keine Musik.
Config.Music = { "", "", "", "", "", "", "", "" }

-- Farben der Glitzer-Aura um den Spieler (wechselt mit jedem Rebirth)
Config.AuraColors = {
	Color3.fromRGB(255, 79, 216), Color3.fromRGB(62, 242, 255), Color3.fromRGB(255, 209, 102),
	Color3.fromRGB(78, 240, 160), Color3.fromRGB(255, 140, 66), Color3.fromRGB(179, 136, 255),
}

----------------------------------------------------------------------------
-- 📋 TÄGLICHE AUFTRÄGE
-- stat = welcher Zähler zählt (siehe Logic.statValue)
----------------------------------------------------------------------------
Config.QuestPool = {
	{ id = "clicks",   stat = "clicks",      goal = 300, text = "Mache %d Daily Routines" },
	{ id = "upgrades", stat = "upgrades",    goal = 25,  text = "Kaufe %d Upgrade-Stufen" },
	{ id = "eggs",     stat = "eggs",        goal = 10,  text = "Öffne %d Geschenkboxen" },
	{ id = "mog",      stat = "mogWins",     goal = 3,   text = "Gewinne %d Mog Battles" },
	{ id = "fans",     stat = "fans",        goal = 5,   text = "Gewinne %d neue Fans" },
	{ id = "jobs",     stat = "jobs",        goal = 3,   text = "Erledige %d Jobs" },
	{ id = "bosshits", stat = "bossHits",    goal = 40,  text = "Triff Bosse %d-mal mit deiner Waffe" },
	{ id = "play",     stat = "playMinutes", goal = 20,  text = "Spiele %d Minuten" },
}
Config.QUESTS_PER_DAY = 3
Config.QuestReward = { cash = 300, auraSeconds = 180 }
Config.QuestBonus = { cash = 1000, freeEgg = true }   -- wenn alle Aufträge des Tages geschafft sind

----------------------------------------------------------------------------
-- 🏅 ERFOLGE (je 4 Stufen)
-- Belohnung pro Stufe: Geld = 150 * 4^(Stufe-1), Aura = 120 s * Stufe
----------------------------------------------------------------------------
Config.Achievements = {
	{ id = "clicks",   stat = "clicks",    emoji = "🪞", name = "Routine-Profi",   text = "Daily Routines",        tiers = { 100, 1000, 10000, 100000 } },
	{ id = "upgrades", stat = "upgrades",  emoji = "💪", name = "Shopaholic",      text = "gekaufte Upgrade-Stufen", tiers = { 25, 250, 1000, 5000 } },
	{ id = "eggs",     stat = "eggs",      emoji = "🎁", name = "Box-Öffner",      text = "geöffnete Boxen",       tiers = { 10, 100, 1000, 5000 } },
	{ id = "mog",      stat = "mogWins",   emoji = "⚔️", name = "Mogger",          text = "gewonnene Mog Battles", tiers = { 5, 50, 250, 1000 } },
	{ id = "boss",     stat = "bossKills", emoji = "👑", name = "Boss-Jäger",      text = "besiegte Bosse (Kampf)", tiers = { 1, 10, 50, 200 } },
	{ id = "rebirth",  stat = "rebirths",  emoji = "♻️", name = "Rebirth-Meister", text = "Rebirths",              tiers = { 1, 5, 10, 15 } },
	{ id = "fans",     stat = "fans",      emoji = "⭐", name = "Fan-Magnet",      text = "gewonnene Fans",        tiers = { 5, 50, 250, 1000 } },
	{ id = "jobs",     stat = "jobs",      emoji = "💼", name = "Arbeitstier",     text = "erledigte Jobs",        tiers = { 5, 50, 250, 1000 } },
	{ id = "trades",   stat = "trades",    emoji = "🤝", name = "Händler",         text = "abgeschlossene Handel", tiers = { 1, 10, 50, 200 } },
	{ id = "worlds",   stat = "worlds",    emoji = "🌍", name = "Weltenbummler",   text = "freigeschaltete Welten", tiers = { 2, 4, 6, 8 } },
	{ id = "index",    stat = "index",     emoji = "📖", name = "Sammler",         text = "Pets im Sammelbuch",    tiers = { 10, 25, 40, 57 } },
}

----------------------------------------------------------------------------
-- 💼 JOBS (Geld verdienen mit Minispiel)
-- req = nötiger Glow-Score, pay = Grundlohn, cd = Pause (s), diff = Schwierigkeit
----------------------------------------------------------------------------
Config.Jobs = {
	{ id = "flyer",     emoji = "📄", name = "Flyer verteilen",              req = 0,     pay = 20,    cd = 30,  diff = 0, act = "Flyer geben!",     desc = "Für einen Döner-Laden. Bezahlung in Cash und Knoblauchsoße." },
	{ id = "barista",   emoji = "☕", name = "Barista im Café Mewing",       req = 100,   pay = 60,    cd = 45,  diff = 1, act = "Milch eingießen!", desc = "Latte Art in Form eines Kieferknochens." },
	{ id = "statist",   emoji = "🎬", name = "Statist im Werbespot",         req = 500,   pay = 200,   cd = 60,  diff = 2, act = "Lächeln!",         desc = "Du läufst im Hintergrund vorbei. Mit Gefühl." },
	{ id = "insta",     emoji = "📸", name = "Instagram-Fotoshooting",       req = 1500,  pay = 700,   cd = 90,  diff = 3, act = "Pose!",            desc = "Und jetzt nachdenklich in die Ferne schauen." },
	{ id = "laufsteg",  emoji = "🕴️", name = "Laufsteg in Mailand",          req = 4000,  pay = 2500,  cd = 120, diff = 4, act = "Schritt!",         desc = "Nicht stolpern. NICHT stolpern." },
	{ id = "parfum",    emoji = "🌸", name = "Gesicht einer Parfum-Kampagne", req = 9000, pay = 8000,  cd = 180, diff = 5, act = "Blick!",           desc = "Du flüsterst einen französischen Namen am Strand." },
	{ id = "hollywood", emoji = "🎥", name = "Hollywood-Hauptrolle",         req = 18000, pay = 30000, cd = 300, diff = 6, act = "Action!",          desc = "Du spielst dich selbst. Oscar-verdächtig." },
}

----------------------------------------------------------------------------
-- ⭐ FANS IN DEN WELTEN
----------------------------------------------------------------------------
Config.FANS_PER_WORLD = 6
Config.FAN_FAIL_COOLDOWN = 45      -- nach einem Fehlversuch (Sekunden)
Config.FAN_REPEAT = 300            -- derselbe Fan erst nach 5 Minuten wieder
-- Grund-Charisma, das Fans in Welt 1–8 erwarten (Promi 5 ≈ x1,2 · Promi 10 = x2)
Config.FanBaseReq = { 150, 400, 2000, 5000, 9000, 12000, 15000, 18000 }
Config.FanNames = { "Lena", "Sophie", "Mia", "Emma", "Hannah", "Lea", "Anna", "Laura", "Selin", "Aylin", "Zoe", "Amira",
	"Paul", "Felix", "Noah", "Elias", "Finn", "Emil", "Luis", "Ben", "Yusuf", "Mats", "Jonas", "Can", "Milan", "Theo" }
Config.FanRoles = { "Schüler", "Azubi", "Skater", "Gamer", "Barista", "Fitness-Fan", "Fotograf", "TikTok-Creator", "Model", "Mega-Influencer" }
-- mod = Bonus/Malus auf die Chance. kind: "conf" (gut mit viel Selbstbewusstsein), "glow" (gut mit viel Glow), "rand" (Glückssache)
Config.FanOpeners = {
	{ text = "„Hi! Selfie zusammen?“ 🤳", mod = 0.10 },
	{ text = "„Willst du ein Autogramm?“ ✍️", kind = "glow", mod = 0.15 },
	{ text = "*Mewing-Pose machen und wissend nicken* 🗿", kind = "rand", mod = 0 },
	{ text = "„Coole Jacke! Wo hast du die her?“", mod = 0.08 },
	{ text = "*Augenkontakt halten und freundlich lächeln* 🙂", kind = "conf", mod = 0.15 },
	{ text = "„Ich hab heute 3 Liter Wasser getrunken.“", mod = -0.08 },
	{ text = "„Soll ich dir einen Skincare-Tipp geben?“ 🧴", mod = 0.06 },
	{ text = "*Nervös winken und schnell weitergehen* 👋", mod = -0.3 },
	{ text = "„Übrigens: Mein Kiefer ist gemewt.“", mod = -0.15 },
	{ text = "„Meine Skincare-Routine hat 14 Schritte. Willst du alle hören?“", mod = -0.12 },
}
Config.FanYes = {
	"„Krass, du hast ja richtig Aura! Ich folge dir!“ 📲",
	"„Darf ich ein Selfie mit dir posten?“ 🤳",
	"„Wie machst du das mit den Haaren?! Ich bin jetzt Fan.“ ⭐",
	"„Okay, du bist der Main Character. Ich abonniere dich.“ 🔔",
}
Config.FanNo = {
	"%s schaut demonstrativ aufs Handy. Das Handy ist aus.",
	"„Sorry … kenn ich dich?“ – Autsch.",
	"%s sagt „Nein danke“ – so freundlich, dass es doppelt wehtut.",
	"%s hat dich nicht mal bemerkt. Mehr Aura nötig.",
}

----------------------------------------------------------------------------
-- ⚔️ WAFFEN (für Echtzeit-Bosskämpfe)
-- damage = Grundschaden, cooldown = Sekunden zwischen Schlägen, range = Reichweite,
-- crit = Chance auf kritischen Treffer (x2,5), price = Geld (0 = nicht kaufbar)
----------------------------------------------------------------------------
Config.Weapons = {
	{ id = "zahnbuerste", emoji = "🪥", name = "Zahnbürsten-Dolch",  rarity = "common",    damage = 10,    cooldown = 0.45, range = 9,  crit = 0.05, price = 0,       desc = "Schnelle, schwache Stiche. Jeder fängt so an." },
	{ id = "foehn",       emoji = "💨", name = "Föhn-Blaster",       rarity = "common",    damage = 22,    cooldown = 0.7,  range = 16, crit = 0.05, price = 600,     desc = "Heißluft aus sicherer Entfernung." },
	{ id = "lasso",       emoji = "🧵", name = "Zahnseide-Lasso",    rarity = "rare",      damage = 60,    cooldown = 0.8,  range = 20, crit = 0.08, price = 4000,    desc = "Reinigt Zahnzwischenräume UND Bosse." },
	{ id = "haarspray",   emoji = "🧴", name = "Haarspray-Nebel",    rarity = "rare",      damage = 110,   cooldown = 0.9,  range = 14, crit = 0.1,  price = 15000,   desc = "Extra starker Halt. Extra starker Schaden." },
	{ id = "katana",      emoji = "🔥", name = "Glätteisen-Katana",  rarity = "epic",      damage = 320,   cooldown = 0.6,  range = 10, crit = 0.15, price = 60000,   desc = "230 Grad. Zischt bei jedem Treffer." },
	{ id = "hammer",      emoji = "🏋️", name = "Hantel-Hammer",      rarity = "epic",      damage = 900,   cooldown = 1.4,  range = 10, crit = 0.1,  price = 250000,  desc = "Langsam, aber BONK." },
	{ id = "spiegel",     emoji = "🪞", name = "Spiegel-Schild",     rarity = "epic",      damage = 500,   cooldown = 0.9,  range = 10, crit = 0.1,  price = 400000,  shield = 0.5, desc = "Halbiert den Schaden von Boss-Angriffen." },
	{ id = "paparazzi",   emoji = "📸", name = "Paparazzi-Blitz",    rarity = "legendary", damage = 2500,  cooldown = 1.0,  range = 24, crit = 0.15, price = 2000000, desc = "Blendet Bosse mit 1000 Blitzen." },
	{ id = "kiefer",      emoji = "🗿", name = "Kiefer-Kanone",      rarity = "legendary", damage = 6000,  cooldown = 1.2,  range = 30, crit = 0.12, price = 8000000, desc = "Schießt Moai-Köpfe. Ja, wirklich." },
	{ id = "faust",       emoji = "👊", name = "Gigachad-Faust",     rarity = "mythic",    damage = 18000, cooldown = 0.8,  range = 11, crit = 0.2,  price = 0, drop = 0.03, desc = "Nur als Beute von Bossen ab Welt 4 (3 %)." },
	{ id = "laser",       emoji = "🌈", name = "Aura-Laser",         rarity = "mythic",    damage = 50000, cooldown = 0.5,  range = 35, crit = 0.25, price = 0, drop = 0.02, desc = "Nur als Beute von LEON (2 %)." },
}
Config.STARTER_WEAPON = "zahnbuerste"
Config.WEAPON_MAX_LEVEL = 10
Config.WEAPON_LEVEL_BONUS = 0.25      -- +25 % Schaden pro Stufe

-- Lebenspunkte der Bosse im Echtzeit-Kampf (Welt 1–8)
Config.BossHP = { 2000, 25000, 3e5, 3e6, 1.5e7, 5e7, 4e8, 5e9 }
Config.BOSS_RESPAWN = 45              -- Sekunden bis der Boss wieder erscheint
Config.BOSS_ATTACK_EVERY = 5          -- Sekunden zwischen Boss-Angriffen
Config.BOSS_HIT_PERCENT = 0.35        -- ein Treffer kostet 35 % deines Selbstbewusstseins

----------------------------------------------------------------------------
-- 🤝 HANDEL
----------------------------------------------------------------------------
Config.TRADE_MAX_PETS = 8
Config.TRADE_COOLDOWN = 15

return Config
