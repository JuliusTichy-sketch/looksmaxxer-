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
-- Seltenheiten: weight = Grundchance, mult = Stärke-Faktor
Config.Rarities = {
	common    = { order = 1, name = "Gewöhnlich",   color = Color3.fromRGB(200, 200, 210), mult = 1 },
	uncommon  = { order = 2, name = "Ungewöhnlich", color = Color3.fromRGB(78, 240, 120),  mult = 1.7 },
	rare      = { order = 3, name = "Selten",       color = Color3.fromRGB(70, 150, 255),  mult = 2.8 },
	epic      = { order = 4, name = "Episch",       color = Color3.fromRGB(170, 90, 255),  mult = 4.5 },
	legendary = { order = 5, name = "Legendär",     color = Color3.fromRGB(255, 200, 40),  mult = 8 },
	mythic    = { order = 6, name = "Mythisch",     color = Color3.fromRGB(255, 60, 90),   mult = 14 },
	exotic    = { order = 7, name = "Exotisch",     color = Color3.fromRGB(0, 255, 200),   mult = 25 },
	divine    = { order = 8, name = "Göttlich",     color = Color3.fromRGB(255, 240, 150), mult = 45 },
	secret    = { order = 9, name = "GEHEIM",       color = Color3.fromRGB(255, 255, 255), mult = 80 },
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
Config.MAX_PET_INVENTORY = 75
Config.PITY = 150                 -- spätestens nach so vielen Boxen ohne Legendär (oder besser) kommt eins
Config.PET_BASE_BOOST = 0.03      -- Gewöhnliches Pet in Welt 1 = +3 % Aura
Config.PET_WORLD_GROWTH = 1.5     -- jede Welt: Pets 1,5x stärker

-- 5 Stationen pro Welt: je teurer, desto bessere Chancen
-- costMult = Preis-Faktor, weights = Chancen pro Seltenheit
Config.EggStations = {
	{ name = "Basis-Box",    emoji = "📦", costMult = 1,    color = Color3.fromRGB(205, 127, 50),
	  weights = { common = 55, uncommon = 27, rare = 12, epic = 5, legendary = 0.9, mythic = 0.1 } },
	{ name = "Silber-Box",   emoji = "🥈", costMult = 6,    color = Color3.fromRGB(200, 205, 215),
	  weights = { common = 30, uncommon = 32, rare = 22, epic = 11.5, legendary = 3.5, mythic = 0.9, exotic = 0.1 } },
	{ name = "Gold-Box",     emoji = "🥇", costMult = 40,   color = Color3.fromRGB(255, 205, 60),
	  weights = { common = 10, uncommon = 28, rare = 32, epic = 20, legendary = 7.5, mythic = 2, exotic = 0.45, divine = 0.05 } },
	{ name = "Diamant-Box",  emoji = "💎", costMult = 250,  color = Color3.fromRGB(150, 240, 255),
	  weights = { uncommon = 18, rare = 36, epic = 30, legendary = 11, mythic = 3.8, exotic = 1, divine = 0.2 } },
	{ name = "Göttliche Box", emoji = "🌈", costMult = 1500, color = Color3.fromRGB(255, 120, 240),
	  weights = { rare = 28, epic = 40, legendary = 20, mythic = 8, exotic = 3.2, divine = 0.8 } },
}

local C = Color3.fromRGB
--[[ Pets pro Welt: { Name, Emoji, Seltenheit, Aussehen }
	Aussehen (look): plan = Bauplan der 3D-Figur, c1/c2 = Farben, dazu Extras:
	  quad    = Vierbeiner (ears = round/pointy/long/floppy/big, tail = short/long/fluffy/curl, mane, horn, horns, hump, trunk, stripes, spots, patches, mask)
	  bird    = Vogel (style = penguin/owl/eagle/longleg/crest/peacock/swan/phoenix)
	  sea     = Meerestier (style = fish/dolphin/shark/whale)
	  crab, scorpion, octopus, turtle, snake, frog, dragon, moai, ghost, alien, star, planet, blob
	  glass = durchsichtig glänzend, neon = leuchtend, gold = golden, halo = Heiligenschein, shades = Sonnenbrille
]]
local PET_DATA = {
	{ -- 1 Glow City
		{ "Gym-Hamster", "🐹", "common", { plan = "quad", c1 = C(230, 170, 100), c2 = C(255, 235, 210), ears = "round", tail = "short", size = 0.85 } },
		{ "Skincare-Katze", "🐱", "common", { plan = "quad", c1 = C(240, 240, 240), c2 = C(255, 190, 200), ears = "pointy", tail = "long", cucumber = true } },
		{ "Straßen-Taube", "🐦", "common", { plan = "bird", c1 = C(140, 140, 155), c2 = C(90, 95, 110) } },
		{ "Mewing-Mops", "🐶", "uncommon", { plan = "quad", c1 = C(215, 185, 140), c2 = C(60, 50, 45), ears = "floppy", tail = "curl" } },
		{ "Selfie-Eichhörnchen", "🐿️", "uncommon", { plan = "quad", c1 = C(190, 110, 60), c2 = C(240, 200, 160), ears = "pointy", tail = "fluffy", size = 0.9 } },
		{ "Protein-Pinguin", "🐧", "rare", { plan = "bird", style = "penguin", c1 = C(30, 30, 35), c2 = C(250, 250, 250) } },
		{ "Hipster-Fuchs", "🦊", "rare", { plan = "quad", c1 = C(235, 120, 40), c2 = C(255, 255, 255), ears = "pointy", tail = "fluffy", shades = true } },
		{ "Sigma-Wolf", "🐺", "epic", { plan = "quad", c1 = C(110, 115, 130), c2 = C(220, 220, 230), ears = "pointy", tail = "long" } },
		{ "Neon-Katze", "😺", "epic", { plan = "quad", c1 = C(255, 79, 216), c2 = C(62, 242, 255), ears = "pointy", tail = "long", neon = true } },
		{ "Golden Retriever Chad", "🐕", "legendary", { plan = "quad", c1 = C(230, 180, 80), c2 = C(250, 230, 170), ears = "floppy", tail = "long", shades = true, size = 1.1 } },
		{ "Mini-Moai", "🗿", "mythic", { plan = "moai", c1 = C(130, 125, 120), c2 = C(100, 95, 90) } },
		{ "Kristall-Drache", "🐉", "exotic", { plan = "dragon", c1 = C(120, 220, 255), c2 = C(255, 255, 255), glass = true } },
		{ "Glow-Gott-Löwe", "🦁", "divine", { plan = "quad", c1 = C(255, 215, 90), c2 = C(255, 150, 40), ears = "round", tail = "long", mane = true, neon = true, halo = true, size = 1.15 } },
	},
	{ -- 2 Miami Beach
		{ "Pinch-Krabbe", "🦀", "common", { plan = "crab", c1 = C(230, 70, 50), c2 = C(255, 200, 180) } },
		{ "Strand-Möwe", "🐦", "common", { plan = "bird", c1 = C(250, 250, 250), c2 = C(150, 155, 165) } },
		{ "Sand-Schildkröte", "🐢", "common", { plan = "turtle", c1 = C(120, 170, 90), c2 = C(160, 120, 70) } },
		{ "Flex-Delfin", "🐬", "uncommon", { plan = "sea", style = "dolphin", c1 = C(120, 170, 220), c2 = C(230, 240, 250) } },
		{ "Kokos-Affe", "🐒", "uncommon", { plan = "quad", c1 = C(130, 90, 60), c2 = C(230, 190, 150), ears = "round", tail = "long" } },
		{ "Glow-Mingo", "🦩", "rare", { plan = "bird", style = "longleg", c1 = C(255, 130, 170), c2 = C(255, 200, 220) } },
		{ "Seestern Sam", "⭐", "rare", { plan = "star", c1 = C(255, 150, 80), c2 = C(255, 220, 150) } },
		{ "Jaw-Hai", "🦈", "epic", { plan = "sea", style = "shark", c1 = C(120, 130, 150), c2 = C(240, 240, 245) } },
		{ "Papagei Pablo", "🦜", "epic", { plan = "bird", style = "crest", c1 = C(230, 40, 40), c2 = C(40, 120, 255) } },
		{ "Bronze-Schildkröte", "🐢", "legendary", { plan = "turtle", c1 = C(205, 127, 50), c2 = C(140, 90, 40), gold = true } },
		{ "Sonnengott-Krake", "🐙", "mythic", { plan = "octopus", c1 = C(255, 120, 60), c2 = C(255, 200, 120) } },
		{ "Regenbogen-Wal", "🐋", "exotic", { plan = "sea", style = "whale", c1 = C(90, 140, 255), c2 = C(220, 240, 255), glass = true } },
		{ "Poseidons Delfin", "🔱", "divine", { plan = "sea", style = "dolphin", c1 = C(255, 220, 100), c2 = C(255, 255, 255), neon = true, halo = true } },
	},
	{ -- 3 Iron Mountain
		{ "Hantel-Hase", "🐰", "common", { plan = "quad", c1 = C(240, 240, 240), c2 = C(255, 190, 200), ears = "long", tail = "short", size = 0.85 } },
		{ "Bergziege", "🐐", "common", { plan = "quad", c1 = C(220, 210, 190), c2 = C(120, 100, 80), ears = "floppy", tail = "short", horns = true } },
		{ "Murmeltier", "🦫", "common", { plan = "quad", c1 = C(150, 110, 70), c2 = C(210, 180, 140), ears = "round", tail = "short", size = 0.9 } },
		{ "Eiweiß-Eule", "🦉", "uncommon", { plan = "bird", style = "owl", c1 = C(140, 100, 70), c2 = C(240, 220, 190) } },
		{ "Schnee-Fuchs", "🦊", "uncommon", { plan = "quad", c1 = C(245, 245, 255), c2 = C(200, 210, 230), ears = "pointy", tail = "fluffy" } },
		{ "Eisbär-Bro", "🐻", "rare", { plan = "quad", c1 = C(245, 245, 250), c2 = C(40, 40, 45), ears = "round", tail = "short", size = 1.15 } },
		{ "Adler Arnold", "🦅", "rare", { plan = "bird", style = "eagle", c1 = C(100, 70, 40), c2 = C(255, 255, 255) } },
		{ "Titan-Gorilla", "🦍", "epic", { plan = "quad", c1 = C(55, 55, 60), c2 = C(120, 110, 105), ears = "round", tail = "none", size = 1.25 } },
		{ "Yeti-Baby", "❄️", "epic", { plan = "quad", c1 = C(230, 235, 255), c2 = C(150, 180, 230), ears = "round", tail = "fluffy", mane = true } },
		{ "Gains-Drache", "🐉", "legendary", { plan = "dragon", c1 = C(60, 160, 80), c2 = C(255, 220, 80) } },
		{ "Ur-Mammut", "🦣", "mythic", { plan = "quad", c1 = C(130, 90, 60), c2 = C(245, 240, 225), ears = "big", tail = "short", trunk = true, size = 1.3 } },
		{ "Lawinen-Wolf", "🐺", "exotic", { plan = "quad", c1 = C(200, 230, 255), c2 = C(255, 255, 255), ears = "pointy", tail = "long", glass = true } },
		{ "Berg-Gott-Adler", "🦅", "divine", { plan = "bird", style = "eagle", c1 = C(255, 210, 80), c2 = C(255, 255, 255), neon = true, halo = true } },
	},
	{ -- 4 Mewing-Tempel
		{ "Meditations-Frosch", "🐸", "common", { plan = "frog", c1 = C(100, 200, 80), c2 = C(220, 240, 170) } },
		{ "Tempel-Affe", "🐒", "common", { plan = "quad", c1 = C(160, 110, 70), c2 = C(240, 200, 170), ears = "round", tail = "long" } },
		{ "Koi-Fisch", "🐟", "common", { plan = "sea", style = "fish", c1 = C(255, 140, 60), c2 = C(255, 255, 255) } },
		{ "Jade-Schlange", "🐍", "uncommon", { plan = "snake", c1 = C(60, 180, 120), c2 = C(220, 240, 180) } },
		{ "Glücks-Katze", "😸", "uncommon", { plan = "quad", c1 = C(255, 250, 240), c2 = C(220, 40, 40), ears = "pointy", tail = "short" } },
		{ "Zen-Kranich", "🦢", "rare", { plan = "bird", style = "longleg", c1 = C(250, 250, 250), c2 = C(30, 30, 30) } },
		{ "Tempel-Löwe", "🦁", "rare", { plan = "quad", c1 = C(210, 170, 60), c2 = C(170, 60, 40), ears = "round", tail = "long", mane = true } },
		{ "Mönch-Panda", "🐼", "epic", { plan = "quad", c1 = C(250, 250, 250), c2 = C(25, 25, 25), ears = "round", tail = "short", patches = true, size = 1.15 } },
		{ "Kirschblüten-Hirsch", "🦌", "epic", { plan = "quad", c1 = C(170, 110, 70), c2 = C(255, 180, 210), ears = "pointy", tail = "short", horns = true } },
		{ "Kiefer-Tiger", "🐯", "legendary", { plan = "quad", c1 = C(240, 140, 40), c2 = C(30, 25, 20), ears = "round", tail = "long", stripes = true, size = 1.1 } },
		{ "Ur-Moai-Geist", "👻", "mythic", { plan = "ghost", c1 = C(200, 230, 255), c2 = C(120, 160, 255) } },
		{ "Jade-Drache", "🐲", "exotic", { plan = "dragon", c1 = C(60, 200, 140), c2 = C(220, 255, 230), glass = true } },
		{ "Erleuchteter Moai", "🗿", "divine", { plan = "moai", c1 = C(255, 215, 90), c2 = C(255, 255, 200), neon = true, halo = true } },
	},
	{ -- 5 Mailand
		{ "Laufsteg-Pudel", "🐩", "common", { plan = "quad", c1 = C(250, 250, 250), c2 = C(255, 190, 220), ears = "floppy", tail = "fluffy", mane = true } },
		{ "Designer-Maus", "🐭", "common", { plan = "quad", c1 = C(180, 180, 190), c2 = C(255, 190, 200), ears = "big", tail = "long", size = 0.8 } },
		{ "Tauben-Model", "🐦", "common", { plan = "bird", c1 = C(170, 170, 190), c2 = C(120, 200, 180) } },
		{ "Pfau Paolo", "🦚", "uncommon", { plan = "bird", style = "peacock", c1 = C(40, 120, 200), c2 = C(40, 200, 120) } },
		{ "Seiden-Raupe", "🐛", "uncommon", { plan = "snake", c1 = C(250, 230, 240), c2 = C(255, 150, 200) } },
		{ "Drip-Zebra", "🦓", "rare", { plan = "quad", c1 = C(250, 250, 250), c2 = C(20, 20, 20), ears = "pointy", tail = "long", stripes = true, mane = true } },
		{ "Flamingo Fiorella", "🦩", "rare", { plan = "bird", style = "longleg", c1 = C(255, 140, 190), c2 = C(255, 220, 235), shades = true } },
		{ "Fashion-Fuchs", "🦊", "epic", { plan = "quad", c1 = C(220, 80, 140), c2 = C(255, 255, 255), ears = "pointy", tail = "fluffy", shades = true } },
		{ "Couture-Chamäleon", "🦎", "epic", { plan = "frog", c1 = C(120, 220, 180), c2 = C(255, 120, 200) } },
		{ "Couture-Schwan", "🦢", "legendary", { plan = "bird", style = "swan", c1 = C(250, 250, 250), c2 = C(255, 180, 0) } },
		{ "Il-Drippo-Einhorn", "🦄", "mythic", { plan = "quad", c1 = C(255, 230, 250), c2 = C(200, 120, 255), ears = "pointy", tail = "long", mane = true, horn = true } },
		{ "Diamant-Pfau", "💎", "exotic", { plan = "bird", style = "peacock", c1 = C(180, 240, 255), c2 = C(255, 255, 255), glass = true } },
		{ "Vogue-Phönix", "🔥", "divine", { plan = "bird", style = "phoenix", c1 = C(255, 120, 200), c2 = C(255, 220, 120), neon = true, halo = true } },
	},
	{ -- 6 Hollywood
		{ "Paparazzi-Papagei", "🦜", "common", { plan = "bird", style = "crest", c1 = C(60, 200, 90), c2 = C(255, 220, 60) } },
		{ "Popcorn-Waschbär", "🦝", "common", { plan = "quad", c1 = C(130, 130, 140), c2 = C(40, 40, 45), ears = "round", tail = "fluffy", mask = true } },
		{ "Stunt-Frosch", "🐸", "common", { plan = "frog", c1 = C(60, 140, 60), c2 = C(255, 200, 60) } },
		{ "Oscar-Otter", "🦦", "uncommon", { plan = "quad", c1 = C(120, 85, 60), c2 = C(220, 190, 160), ears = "round", tail = "long" } },
		{ "Kamera-Krabbe", "📷", "uncommon", { plan = "crab", c1 = C(40, 40, 45), c2 = C(200, 200, 210) } },
		{ "Stunt-Känguru", "🦘", "rare", { plan = "quad", c1 = C(200, 140, 90), c2 = C(240, 210, 180), ears = "long", tail = "long" } },
		{ "Starlet-Katze", "🐈", "rare", { plan = "quad", c1 = C(255, 220, 240), c2 = C(255, 120, 180), ears = "pointy", tail = "long", shades = true } },
		{ "Red-Carpet-Löwe", "🦁", "epic", { plan = "quad", c1 = C(220, 170, 80), c2 = C(150, 70, 40), ears = "round", tail = "long", mane = true, size = 1.15 } },
		{ "Spotlight-Eule", "🦉", "epic", { plan = "bird", style = "owl", c1 = C(255, 240, 150), c2 = C(255, 255, 230), neon = true } },
		{ "Blockbuster-Bär", "🐻", "legendary", { plan = "quad", c1 = C(120, 80, 50), c2 = C(200, 160, 120), ears = "round", tail = "short", shades = true, size = 1.25 } },
		{ "Walk-of-Fame-Phönix", "🔥", "mythic", { plan = "bird", style = "phoenix", c1 = C(255, 120, 40), c2 = C(255, 220, 80) } },
		{ "Oscar-Statuen-Hund", "🏆", "exotic", { plan = "quad", c1 = C(255, 205, 60), c2 = C(255, 240, 180), ears = "floppy", tail = "long", gold = true } },
		{ "Hollywood-Drache", "🐉", "divine", { plan = "dragon", c1 = C(255, 60, 60), c2 = C(255, 220, 120), neon = true, halo = true } },
	},
	{ -- 7 Dubai
		{ "Gold-Kamel", "🐫", "common", { plan = "quad", c1 = C(210, 170, 110), c2 = C(240, 210, 160), ears = "round", tail = "short", hump = true } },
		{ "Wüsten-Skorpion", "🦂", "common", { plan = "scorpion", c1 = C(200, 160, 90), c2 = C(120, 90, 50) } },
		{ "Fennek", "🦊", "common", { plan = "quad", c1 = C(240, 200, 150), c2 = C(255, 240, 220), ears = "big", tail = "fluffy", size = 0.85 } },
		{ "Falke Faisal", "🦅", "uncommon", { plan = "bird", style = "eagle", c1 = C(150, 110, 70), c2 = C(240, 230, 210) } },
		{ "Oryx", "🦌", "uncommon", { plan = "quad", c1 = C(240, 235, 225), c2 = C(40, 35, 30), ears = "pointy", tail = "short", horns = true } },
		{ "Luxus-Leopard", "🐆", "rare", { plan = "quad", c1 = C(230, 190, 110), c2 = C(50, 35, 20), ears = "round", tail = "long", spots = true } },
		{ "Perlen-Blob", "🦪", "rare", { plan = "blob", c1 = C(240, 240, 255), c2 = C(255, 220, 240) } },
		{ "Yacht-Wal", "🐋", "epic", { plan = "sea", style = "whale", c1 = C(60, 90, 160), c2 = C(220, 230, 245) } },
		{ "Gold-Gepard", "🐆", "epic", { plan = "quad", c1 = C(255, 210, 80), c2 = C(80, 50, 20), ears = "round", tail = "long", spots = true, gold = true } },
		{ "Diamant-Drache", "🐲", "legendary", { plan = "dragon", c1 = C(180, 230, 255), c2 = C(255, 255, 255), glass = true } },
		{ "Scheich-Phönix", "✨", "mythic", { plan = "bird", style = "phoenix", c1 = C(255, 205, 60), c2 = C(255, 255, 255), gold = true } },
		{ "Platin-Kamel", "🐪", "exotic", { plan = "quad", c1 = C(230, 230, 240), c2 = C(255, 255, 255), ears = "round", tail = "short", hump = true, gold = true } },
		{ "Sultan-Löwe", "👑", "divine", { plan = "quad", c1 = C(255, 215, 90), c2 = C(255, 255, 255), ears = "round", tail = "long", mane = true, neon = true, halo = true, size = 1.2 } },
	},
	{ -- 8 Aura-Galaxie
		{ "Mond-Hamster", "🌙", "common", { plan = "quad", c1 = C(220, 220, 240), c2 = C(180, 180, 210), ears = "round", tail = "short", size = 0.85 } },
		{ "Sternen-Katze", "⭐", "common", { plan = "quad", c1 = C(60, 60, 120), c2 = C(255, 240, 150), ears = "pointy", tail = "long", spots = true } },
		{ "Asteroiden-Blob", "☄️", "common", { plan = "blob", c1 = C(120, 110, 100), c2 = C(255, 150, 80) } },
		{ "Komet-Hund", "💫", "uncommon", { plan = "quad", c1 = C(120, 200, 255), c2 = C(255, 255, 255), ears = "floppy", tail = "long", neon = true } },
		{ "Saturn-Schildkröte", "🪐", "uncommon", { plan = "turtle", c1 = C(220, 190, 120), c2 = C(160, 120, 255) } },
		{ "Alien-Bro", "👽", "rare", { plan = "alien", c1 = C(120, 255, 120), c2 = C(20, 20, 20) } },
		{ "UFO-Katze", "🛸", "rare", { plan = "quad", c1 = C(150, 150, 170), c2 = C(120, 255, 200), ears = "pointy", tail = "long", halo = true } },
		{ "Nebula-Wal", "🌌", "epic", { plan = "sea", style = "whale", c1 = C(160, 90, 255), c2 = C(255, 150, 230), neon = true } },
		{ "Planet-Blob", "🌍", "epic", { plan = "planet", c1 = C(90, 200, 255), c2 = C(120, 230, 120) } },
		{ "Schwarzes-Loch-Mops", "⚫", "legendary", { plan = "quad", c1 = C(25, 20, 35), c2 = C(160, 90, 255), ears = "floppy", tail = "curl", halo = true } },
		{ "Aura-Gott", "🌈", "mythic", { plan = "star", c1 = C(255, 120, 240), c2 = C(120, 240, 255), neon = true } },
		{ "Galaxie-Drache", "🐉", "exotic", { plan = "dragon", c1 = C(120, 60, 255), c2 = C(255, 150, 255), neon = true } },
		{ "Kosmischer Löwe", "🦁", "divine", { plan = "quad", c1 = C(255, 255, 255), c2 = C(200, 160, 255), ears = "round", tail = "long", mane = true, neon = true, halo = true, size = 1.25 } },
	},
}

local WORLD_BOX_NAMES = { "Glow City", "Strand", "Gym", "Tempel", "Couture", "Blockbuster", "Gold", "Galaxie" }
local EGG_COSTS = { 150, 2500, 1.5e6, 1.5e8, 1e10, 3e11, 1e13, 1.5e14 }   -- Preis der Basis-Box je Welt

-- Pets und Boxen werden hier automatisch aus den Listen oben erzeugt
Config.Pets = {}
Config.Eggs = {}
local petsOfWorld = {}
for w, list in ipairs(PET_DATA) do
	petsOfWorld[w] = {}
	local base = Config.PET_BASE_BOOST * Config.PET_WORLD_GROWTH ^ (w - 1)
	for i, p in ipairs(list) do
		local rarity = Config.Rarities[p[3]]
		local pet = { id = "w" .. w .. "_" .. i, name = p[1], emoji = p[2], rarity = p[3], world = w, look = p[4], boost = base * rarity.mult }
		table.insert(Config.Pets, pet)
		table.insert(petsOfWorld[w], pet)
	end
end
for w = 1, #PET_DATA do
	for s, station in ipairs(Config.EggStations) do
		local counts = {}
		for _, pet in ipairs(petsOfWorld[w]) do
			if station.weights[pet.rarity] then
				counts[pet.rarity] = (counts[pet.rarity] or 0) + 1
			end
		end
		local egg = {
			index = (w - 1) * #Config.EggStations + s, world = w, station = s,
			name = WORLD_BOX_NAMES[w] .. " · " .. station.name, emoji = station.emoji,
			cost = EGG_COSTS[w] * station.costMult, pets = {},
		}
		for _, pet in ipairs(petsOfWorld[w]) do
			local wgt = station.weights[pet.rarity]
			if wgt then
				table.insert(egg.pets, { id = pet.id, weight = wgt / counts[pet.rarity] })
			end
		end
		table.insert(Config.Eggs, egg)
	end
end

-- Box-Nummer aus Welt & Station
function Config.eggIndex(world, station)
	return (world - 1) * #Config.EggStations + (station or 1)
end

-- Das geheime Pet gibt es nur, wenn man Endboss Leon besiegt
Config.SECRET_PET = "secret_goldfisch"
table.insert(Config.Pets, {
	id = Config.SECRET_PET, name = "Leons Goldfisch", emoji = "🐠", rarity = "secret", world = 8,
	look = { plan = "sea", style = "fish", c1 = C(255, 200, 40), c2 = C(255, 255, 255), gold = true, halo = true },
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
-- Zusätzliche (schwächere) Rivalen pro Welt: Stärke = Anteil vom Haupt-Rivalen
Config.ExtraRivals = {
	{ prefix = "Azubi", strength = 0.55 },
	{ prefix = "Möchtegern", strength = 0.75 },
}
Config.RivalNames = { "Kevin", "Justin", "Marco", "Tobi", "Can", "Malte", "Ole", "Nico", "Dario", "Yannis", "Jannik", "Luis",
	"Elias", "Mehmet", "Finn", "Leandro" }
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
	{ id = "aura2",  emoji = "🧪", name = "Aura-Trank",  desc = "Doppelte Aura für 10 Minuten.",                 gems = 20, price = 300, duration = 600, aura = 2 },
	{ id = "luck2",  emoji = "🍀", name = "Glücks-Trank", desc = "Doppeltes Glück beim Öffnen für 10 Minuten.",  gems = 30, price = 500, duration = 600, luck = 2 },
	{ id = "click3", emoji = "🥤", name = "Klick-Shake", desc = "Dreifacher Klick-Wert für 5 Minuten.",          price = 150, duration = 300, click = 3 },
	{ id = "pump",   emoji = "💪", name = "Gym-Pump",    desc = "+50 % Aura für 3 Minuten (aus dem Gym-Training).", price = 0, duration = 180, aura = 1.5, hidden = true },
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
	Click       = "",   -- (absichtlich leer: kein Sound bei der Daily Routine)
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
	{ id = "index",    stat = "index",     emoji = "📖", name = "Sammler",         text = "Pets im Sammelbuch",    tiers = { 10, 30, 60, 105 } },
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
Config.FANS_PER_WORLD = 18
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

----------------------------------------------------------------------------
-- 🎉 EVENTS (laufen automatisch nach Kalender, Zeitzone UTC)
-- from/to = { Monat, Tag }. Zum Testen: Config.EVENT_OVERRIDE = "halloween" usw.
----------------------------------------------------------------------------
Config.EVENT_OVERRIDE = ""
Config.EVENT_EGG_COST = 25          -- Event-Box kostet 25 Event-Münzen
Config.EVENT_ITEMS_PER_WORLD = 6    -- so viele Sammelobjekte liegen gleichzeitig in jeder Welt
Config.WEEKEND_BOOST = { aura = 2, luck = 2 }   -- Samstag & Sonntag automatisch

local EC = Color3.fromRGB
Config.Events = {
	{ id = "winter", name = "Winter-Glow", emoji = "❄️", from = { 11, 20 }, to = { 1, 6 }, color = EC(140, 220, 255),
	  token = "Schneeflocken", tokenEmoji = "❄️",
	  boss = { name = "Frost-Chad", level = 30, rebirths = 6, hp = 2e6, shirt = EC(200, 230, 255), pants = EC(80, 120, 200), skin = EC(220, 235, 255), scale = 1.5 },
	  pets = {
		{ "Schneemann-Mops", "⛄", "rare", { plan = "quad", c1 = EC(250, 250, 255), c2 = EC(255, 140, 40), ears = "floppy", tail = "curl" } },
		{ "Rentier-Chad", "🦌", "epic", { plan = "quad", c1 = EC(150, 100, 60), c2 = EC(230, 40, 40), ears = "pointy", tail = "short", horns = true, shades = true } },
		{ "Pinguin-Elf", "🐧", "legendary", { plan = "bird", style = "penguin", c1 = EC(40, 150, 60), c2 = EC(230, 40, 40) } },
		{ "Eis-Yeti", "🧊", "mythic", { plan = "quad", c1 = EC(190, 235, 255), c2 = EC(255, 255, 255), ears = "round", tail = "fluffy", mane = true, glass = true } },
		{ "Weihnachts-Drache", "🎄", "divine", { plan = "dragon", c1 = EC(220, 30, 40), c2 = EC(255, 215, 90), neon = true, halo = true } },
	  } },
	{ id = "halloween", name = "Halloween-Glow", emoji = "🎃", from = { 10, 10 }, to = { 11, 7 }, color = EC(255, 140, 30),
	  token = "Kürbisse", tokenEmoji = "🎃",
	  boss = { name = "Kürbis-König", level = 30, rebirths = 6, hp = 2e6, shirt = EC(255, 130, 20), pants = EC(30, 20, 30), skin = EC(120, 200, 80), scale = 1.5 },
	  pets = {
		{ "Kürbis-Katze", "🎃", "rare", { plan = "quad", c1 = EC(255, 140, 30), c2 = EC(30, 25, 30), ears = "pointy", tail = "long" } },
		{ "Fledermaus-Bro", "🦇", "epic", { plan = "bird", style = "eagle", c1 = EC(40, 30, 50), c2 = EC(150, 60, 200) } },
		{ "Geister-Moai", "👻", "legendary", { plan = "ghost", c1 = EC(230, 240, 255), c2 = EC(120, 255, 150) } },
		{ "Vampir-Wolf", "🧛", "mythic", { plan = "quad", c1 = EC(60, 20, 30), c2 = EC(200, 20, 40), ears = "pointy", tail = "long" } },
		{ "Skelett-Drache", "💀", "divine", { plan = "dragon", c1 = EC(245, 245, 235), c2 = EC(120, 255, 120), glass = true, halo = true } },
	  } },
	{ id = "summer", name = "Sommer-Glow", emoji = "☀️", from = { 7, 1 }, to = { 8, 20 }, color = EC(255, 210, 60),
	  token = "Kokosnüsse", tokenEmoji = "🥥",
	  boss = { name = "Sonnenbrand-Brad", level = 30, rebirths = 6, hp = 2e6, shirt = EC(255, 90, 60), pants = EC(60, 160, 220), skin = EC(255, 150, 120), scale = 1.5 },
	  pets = {
		{ "Kokos-Krabbe", "🦀", "rare", { plan = "crab", c1 = EC(150, 100, 60), c2 = EC(255, 240, 220) } },
		{ "Surf-Delfin", "🏄", "epic", { plan = "sea", style = "dolphin", c1 = EC(60, 200, 230), c2 = EC(255, 255, 255), shades = true } },
		{ "Sonnen-Flamingo", "🦩", "legendary", { plan = "bird", style = "longleg", c1 = EC(255, 200, 60), c2 = EC(255, 120, 160), gold = true } },
		{ "Strand-Gott-Hai", "🦈", "mythic", { plan = "sea", style = "shark", c1 = EC(255, 180, 80), c2 = EC(255, 255, 255) } },
		{ "Sonnen-Phönix", "🌞", "divine", { plan = "bird", style = "phoenix", c1 = EC(255, 200, 40), c2 = EC(255, 90, 40), neon = true, halo = true } },
	  } },
}
-- Event-Pets & Event-Boxen erzeugen (Stärke wie Pets aus Welt 4)
Config.EVENT_WEIGHTS = { rare = 60, epic = 28, legendary = 9, mythic = 2.6, divine = 0.4 }
for _, ev in ipairs(Config.Events) do
	local egg = { index = #Config.Eggs + 1, world = 1, station = 0, event = ev.id, name = ev.name .. "-Box", emoji = ev.emoji,
		cost = Config.EVENT_EGG_COST, pets = {} }
	local counts = {}
	for _, p in ipairs(ev.pets) do counts[p[3]] = (counts[p[3]] or 0) + 1 end
	for i, p in ipairs(ev.pets) do
		local pet = { id = "ev_" .. ev.id .. "_" .. i, name = p[1], emoji = p[2], rarity = p[3], world = 4, event = ev.id, look = p[4],
			boost = Config.PET_BASE_BOOST * Config.PET_WORLD_GROWTH ^ 3 * Config.Rarities[p[3]].mult }
		table.insert(Config.Pets, pet)
		table.insert(egg.pets, { id = pet.id, weight = Config.EVENT_WEIGHTS[p[3]] / counts[p[3]] })
	end
	ev.eggIndex = egg.index
	table.insert(Config.Eggs, egg)
end

----------------------------------------------------------------------------
-- 🎡 GLÜCKSRAD & SPIELZEIT-GESCHENKE
-- Glücksrad: 1x pro Tag gratis (+ Drehungen aus Spielzeit-Geschenken). Kein Robux-Kauf (Roblox-Regeln für Zufall).
----------------------------------------------------------------------------
Config.WHEEL_COOLDOWN = 20 * 3600
Config.Wheel = {
	{ label = "💵 Geld",          weight = 25, color = EC(124, 252, 154), reward = { cash = 500, scale = true } },
	{ label = "💵 Viel Geld",     weight = 12, color = EC(80, 200, 120),  reward = { cash = 2500, scale = true } },
	{ label = "💎 10 Gems",       weight = 15, color = EC(120, 200, 255), reward = { gems = 10 } },
	{ label = "💎 50 Gems",       weight = 4,  color = EC(60, 140, 255),  reward = { gems = 50 } },
	{ label = "🧪 Aura-Trank",    weight = 14, color = EC(255, 120, 220), reward = { potion = "aura2" } },
	{ label = "🍀 Glücks-Trank",  weight = 12, color = EC(120, 230, 120), reward = { potion = "luck2" } },
	{ label = "🥈 Silber-Box",    weight = 12, color = EC(200, 205, 215), reward = { freeEgg = 2 } },
	{ label = "🌈 Göttliche Box", weight = 1,  color = EC(255, 120, 240), reward = { freeEgg = 5 } },
	{ label = "✨ 10 Min. Aura",  weight = 5,  color = EC(255, 209, 102), reward = { auraSeconds = 600 } },
}
Config.PlaytimeGifts = {
	{ minutes = 5,  label = "💵 Geld",           reward = { cash = 300, scale = true } },
	{ minutes = 10, label = "🎡 Glücksrad-Dreh", reward = { spins = 1 } },
	{ minutes = 20, label = "🧪 Aura-Trank",     reward = { potion = "aura2" } },
	{ minutes = 30, label = "💎 15 Gems",        reward = { gems = 15 } },
	{ minutes = 45, label = "🥈 Silber-Box",     reward = { freeEgg = 2 } },
	{ minutes = 60, label = "🎡 2 Drehungen",    reward = { spins = 2 } },
}

----------------------------------------------------------------------------
-- 💎 ROBUX-SHOP
-- Die IDs musst du im Creator Hub anlegen und hier eintragen (siehe ANLEITUNG.md).
-- id = 0 → im Spiel steht "Bald verfügbar".
----------------------------------------------------------------------------
Config.GamePasses = {
	{ key = "vip",      id = 0, emoji = "👑", name = "VIP",               robux = 299, desc = "+25 % Aura & Geld, goldenes VIP-Namensschild." },
	{ key = "x2aura",   id = 0, emoji = "✨", name = "Doppelte Aura",     robux = 399, desc = "Für immer x2 Aura." },
	{ key = "lucky",    id = 0, emoji = "🍀", name = "Glückspilz",        robux = 249, desc = "Für immer x2 Glück beim Box-Öffnen." },
	{ key = "petslots", id = 0, emoji = "🐾", name = "+3 Pet-Plätze",     robux = 299, desc = "3 Pets mehr gleichzeitig ausrüsten." },
	{ key = "triple",   id = 0, emoji = "🎁", name = "3er-Öffnen",        robux = 199, desc = "Öffne 3 Boxen auf einmal – sofort, ohne Rebirth-Shop." },
	{ key = "speed",    id = 0, emoji = "⚡", name = "Turbo-Laufen",      robux = 99,  desc = "+8 Laufgeschwindigkeit für immer." },
}
Config.DevProducts = {
	{ key = "gems100",  id = 0, emoji = "💎", name = "100 Gems",          robux = 49,  reward = { gems = 100 } },
	{ key = "gems550",  id = 0, emoji = "💎", name = "550 Gems",          robux = 199, reward = { gems = 550 } },
	{ key = "gems1200", id = 0, emoji = "💎", name = "1.200 Gems",        robux = 399, reward = { gems = 1200 } },
	{ key = "gems3000", id = 0, emoji = "💎", name = "3.000 Gems",        robux = 899, reward = { gems = 3000 } },
	{ key = "starter",  id = 0, emoji = "🎁", name = "Starter-Paket",     robux = 99,  once = true,
	  reward = { gems = 150, cash = 2000, scale = true, potion = "aura2" }, desc = "Nur einmal kaufbar!" },
	{ key = "aurapack", id = 0, emoji = "✨", name = "Aura-Paket",        robux = 79,  reward = { auraSeconds = 900 }, desc = "Sofort 15 Minuten deiner Aura/s." },
}

----------------------------------------------------------------------------
-- 🛹 FAHRZEUGE (Taste V = aufsteigen/absteigen)
-- currency = "cash" (Geld) oder "gems"
----------------------------------------------------------------------------
Config.Vehicles = {
	{ id = "skateboard", emoji = "🛹", name = "Skateboard",        speed = 8,  jump = 0,  price = 2000,  currency = "cash", plan = "board" },
	{ id = "scooter",    emoji = "🛴", name = "E-Scooter",         speed = 14, jump = 0,  price = 50000, currency = "cash", plan = "scooter" },
	{ id = "sportwagen", emoji = "🏎️", name = "Sportwagen",        speed = 24, jump = 0,  price = 5e6,   currency = "cash", plan = "car" },
	{ id = "hoverboard", emoji = "🛸", name = "Hoverboard",        speed = 30, jump = 20, price = 400,   currency = "gems", plan = "hover" },
	{ id = "goldcar",    emoji = "🚗", name = "Gold-Sportwagen",   speed = 36, jump = 0,  price = 1500,  currency = "gems", plan = "car", gold = true },
}

----------------------------------------------------------------------------
-- ✨ AUSRÜSTUNG: Auren, Spuren, Hüte (mit Boosts), Emotes
----------------------------------------------------------------------------
Config.Auras = {
	{ id = "aura_pink",    emoji = "💖", name = "Pinke Glitzer-Aura", price = 1000,  currency = "cash", style = "sparkle", color = EC(255, 120, 220) },
	{ id = "aura_fire",    emoji = "🔥", name = "Feuer-Aura",         price = 25000, currency = "cash", style = "fire",    color = EC(255, 120, 30) },
	{ id = "aura_ice",     emoji = "❄️", name = "Eis-Aura",           price = 250000, currency = "cash", style = "sparkle", color = EC(140, 220, 255) },
	{ id = "aura_gold",    emoji = "🌟", name = "Gold-Aura",          price = 2.5e6, currency = "cash", style = "sparkle", color = EC(255, 205, 60), strong = true },
	{ id = "aura_dark",    emoji = "🌑", name = "Dunkle Aura",        price = 2.5e7, currency = "cash", style = "smoke",   color = EC(70, 20, 110) },
	{ id = "aura_rainbow", emoji = "🌈", name = "Regenbogen-Aura",    price = 500,   currency = "gems", style = "rainbow", color = EC(255, 255, 255), strong = true },
}
Config.Trails = {
	{ id = "trail_pink",    emoji = "💗", name = "Pinke Spur",       price = 5000,  currency = "cash", c1 = EC(255, 120, 220), c2 = EC(255, 255, 255) },
	{ id = "trail_fire",    emoji = "🔥", name = "Feuer-Spur",       price = 100000, currency = "cash", c1 = EC(255, 220, 60), c2 = EC(255, 60, 20) },
	{ id = "trail_neon",    emoji = "💠", name = "Neon-Spur",        price = 2e6,   currency = "cash", c1 = EC(62, 242, 255), c2 = EC(155, 92, 255) },
	{ id = "trail_rainbow", emoji = "🌈", name = "Regenbogen-Spur",  price = 300,   currency = "gems", rainbow = true },
	{ id = "trail_galaxy",  emoji = "🌌", name = "Galaxie-Spur",     price = 800,   currency = "gems", c1 = EC(120, 60, 255), c2 = EC(20, 10, 40) },
}
-- Hüte geben Boosts: aura/cash/luck = Prozent (0.1 = +10 %), speed = Laufgeschwindigkeit
Config.Hats = {
	{ id = "cap",        emoji = "🧢", name = "Gym-Cap",            price = 3000,   currency = "cash", boost = { aura = 0.05 } },
	{ id = "headphones", emoji = "🎧", name = "Phonk-Kopfhörer",    price = 60000,  currency = "cash", boost = { cash = 0.05, speed = 3 } },
	{ id = "cowboy",     emoji = "🤠", name = "Sheriff-Hut",        price = 800000, currency = "cash", boost = { cash = 0.1 } },
	{ id = "halo",       emoji = "😇", name = "Heiligenschein",     price = 1e7,    currency = "cash", boost = { aura = 0.15 } },
	{ id = "crown",      emoji = "👑", name = "Gigachad-Krone",     price = 2e8,    currency = "cash", boost = { aura = 0.25 } },
	{ id = "viking",     emoji = "🪖", name = "Wikinger-Helm",      price = 600,    currency = "gems", boost = { luck = 0.15 } },
	{ id = "diamond",    emoji = "💎", name = "Diamant-Krone",      price = 1500,   currency = "gems", boost = { aura = 0.3, luck = 0.1 } },
}
-- Emotes (Standard-Roblox-Animationen für R15)
Config.Emotes = {
	{ id = "wave",   emoji = "👋", name = "Winken",       price = 0,     currency = "cash", anim = "rbxassetid://507770239" },
	{ id = "cheer",  emoji = "🙌", name = "Jubeln",       price = 1000,  currency = "cash", anim = "rbxassetid://507770677" },
	{ id = "laugh",  emoji = "😂", name = "Lachen",       price = 5000,  currency = "cash", anim = "rbxassetid://507770818" },
	{ id = "dance",  emoji = "🕺", name = "Tanzen",       price = 25000, currency = "cash", anim = "rbxassetid://507771019" },
	{ id = "mewing", emoji = "🗿", name = "Mewing-Pose",  price = 100,   currency = "gems", anim = "rbxassetid://507770453", bubble = "*mewt intensiv* 🗿" },
}

----------------------------------------------------------------------------
-- 🏃 MINISPIELE
----------------------------------------------------------------------------
Config.OBBY_COOLDOWN = 600            -- Belohnung für den Dach-Parkour höchstens alle 10 Minuten
Config.ObbyReward = { cash = 400, scale = true, gems = 5 }
Config.RACE_TARGET = 14               -- Sekunden für volle Belohnung im Laufsteg-Rennen
Config.RaceReward = { cash = 250 }    -- wird mit Lohn-Bonus und Tempo verrechnet
Config.GYM_COOLDOWN = 45

return Config
