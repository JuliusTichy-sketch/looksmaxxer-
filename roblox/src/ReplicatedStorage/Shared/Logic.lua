--[[
	LOGIC – alle Spielformeln an einem Ort (Server & Client)
	Der Server rechnet damit wirklich, der Client nur zum Anzeigen.
]]

local Config = require(script.Parent:WaitForChild("Config"))

local Logic = {}

-- Schnelle Nachschlage-Tabellen
Logic.upgradeById = {}
for _, u in ipairs(Config.Upgrades) do
	Logic.upgradeById[u.id] = u
end
Logic.petById = {}
for _, p in ipairs(Config.Pets) do
	Logic.petById[p.id] = p
end
Logic.potionById = {}
for _, p in ipairs(Config.Potions) do
	Logic.potionById[p.id] = p
end
Logic.perkById = {}
for _, p in ipairs(Config.RebirthShop) do
	Logic.perkById[p.id] = p
end

----------------------------------------------------------------------------
-- Upgrades
----------------------------------------------------------------------------
function Logic.level(data, id)
	return (data.levels and data.levels[id]) or 0
end

function Logic.costAt(u, level)
	return math.floor(u.base * Config.COST_GROWTH ^ level + 0.5)
end

-- Wie viele Stufen kaufen wir (amount = Zahl oder "max") und was kostet das?
function Logic.bulk(u, level, amount, money)
	local remaining = Config.MAX_LEVEL - level
	if remaining <= 0 then
		return 0, 0
	end
	if amount == "max" then
		local count, cost = 0, 0
		while count < remaining do
			local nextCost = Logic.costAt(u, level + count)
			if cost + nextCost > money then
				break
			end
			cost = cost + nextCost
			count = count + 1
		end
		if count == 0 then
			return 1, Logic.costAt(u, level)
		end
		return count, cost
	end
	local count = math.min(amount, remaining)
	local cost = 0
	for i = 0, count - 1 do
		cost = cost + Logic.costAt(u, level + i)
	end
	return count, cost
end

-- Summe über alle Upgrades
local function sumLevels(levels, field)
	local total = 0
	for _, u in ipairs(Config.Upgrades) do
		total = total + ((levels and levels[u.id]) or 0) * u[field]
	end
	return total
end

function Logic.baseGlow(levels) return sumLevels(levels, "glow") end
function Logic.baseAps(levels) return sumLevels(levels, "aps") end
function Logic.clickBonus(levels) return sumLevels(levels, "click") end

-- Summe der Stufen einer Kategorie (z. B. Fitness für breitere Schultern)
function Logic.catLevels(levels, cat)
	local total = 0
	for _, u in ipairs(Config.Upgrades) do
		if u.cat == cat then
			total = total + ((levels and levels[u.id]) or 0)
		end
	end
	return total
end

-- Punkte in einer Kategorie für Mog Battles
function Logic.catScore(levels, cat, rebirths)
	local total = 0
	for _, u in ipairs(Config.Upgrades) do
		if u.cat == cat then
			total = total + ((levels and levels[u.id]) or 0) * u.glow
		end
	end
	return total * (1 + (rebirths or 0) * 0.2)
end

-- Titel-Index zum Glow-Score
function Logic.titleIndex(glow)
	local idx = 1
	for i, t in ipairs(Config.Titles) do
		if glow >= t.glow then
			idx = i
		end
	end
	return idx
end

----------------------------------------------------------------------------
-- Rebirth & Perks
----------------------------------------------------------------------------
function Logic.rebirthCost(r)
	return Config.Rebirth.baseCost * Config.Rebirth.growth ^ r
end
function Logic.rebirthMult(r)
	return 1 + r * Config.Rebirth.multPer
end
function Logic.rebirthPointsFor(newRebirthCount)
	return 1 + math.floor(newRebirthCount / 5)
end
function Logic.perkLevel(data, id)
	return (data.perks and data.perks[id]) or 0
end
function Logic.perkCost(perk, level)
	return perk.baseCost + perk.costStep * level
end

----------------------------------------------------------------------------
-- Pets
----------------------------------------------------------------------------
function Logic.petBoost(pet)
	local def = Logic.petById[pet.id]
	if not def then return 0 end
	local tier = Config.PetTiers[pet.tier or 1] or Config.PetTiers[1]
	return def.boost * tier.mult
end

function Logic.petMult(data)
	local total = 0
	for _, pet in ipairs(data.pets or {}) do
		if pet.eq then
			total = total + Logic.petBoost(pet)
		end
	end
	return 1 + total
end

function Logic.petSlots(data)
	return Config.BASE_PET_SLOTS + Logic.perkLevel(data, "petslot") + (Logic.hasPass(data, "petslots") and 3 or 0)
end

function Logic.equippedCount(data)
	local n = 0
	for _, pet in ipairs(data.pets or {}) do
		if pet.eq then n = n + 1 end
	end
	return n
end

----------------------------------------------------------------------------
-- Tränke
----------------------------------------------------------------------------
function Logic.potionActive(data, id, now)
	local untilTime = data.potions and data.potions[id]
	return untilTime and untilTime > now
end

function Logic.potionFactor(data, field, now)
	local f = 1
	for _, p in ipairs(Config.Potions) do
		if p[field] and Logic.potionActive(data, p.id, now) then
			f = f * p[field]
		end
	end
	return f
end

function Logic.luck(data, now)
	return (1 + Logic.perkLevel(data, "luck") * 0.1 + Logic.hatBoost(data, "luck")) * Logic.potionFactor(data, "luck", now)
		* (Logic.hasPass(data, "lucky") and 2 or 1) * (Logic.isWeekend(now) and Config.WEEKEND_BOOST.luck or 1)
end

----------------------------------------------------------------------------
-- Gesamtwerte
----------------------------------------------------------------------------
function Logic.worldMult(index)
	local w = Config.Worlds[index] or Config.Worlds[1]
	return w.mult
end

-- Multiplikator auf alle Aura
function Logic.multiplier(data, worldIndex, now)
	return Logic.worldMult(worldIndex) * Logic.rebirthMult(data.rebirths or 0) * Logic.petMult(data)
		* Logic.potionFactor(data, "aura", now)
		* (Logic.hasPass(data, "vip") and 1.25 or 1) * (Logic.hasPass(data, "x2aura") and 2 or 1)
		* (1 + Logic.hatBoost(data, "aura")) * (Logic.isWeekend(now) and Config.WEEKEND_BOOST.aura or 1)
end

function Logic.aps(data, worldIndex, now)
	return Logic.baseAps(data.levels) * Logic.multiplier(data, worldIndex, now)
end

function Logic.clickValue(data, worldIndex, now)
	local base = 1 + Logic.clickBonus(data.levels) + Logic.baseAps(data.levels) * 0.05
	return base * Logic.multiplier(data, worldIndex, now) * Logic.potionFactor(data, "click", now)
end

-- Glow-Power = Wert für die globale Rangliste
function Logic.glowPower(data)
	return math.floor(Logic.baseGlow(data.levels) * (1 + (data.rebirths or 0) * 0.25) * Logic.petMult(data))
end

function Logic.worldUnlocked(data, index)
	return index == 1 or (data.worlds and data.worlds[tostring(index)] == true)
end

----------------------------------------------------------------------------
-- Zähler für Aufträge & Erfolge
----------------------------------------------------------------------------
function Logic.statValue(data, stat)
	if stat == "clicks" then return data.clicks or 0 end
	if stat == "eggs" then return data.eggsOpened or 0 end
	if stat == "mogWins" then return data.mogWins or 0 end
	if stat == "rebirths" then return data.rebirths or 0 end
	if stat == "worlds" then
		local n = 0
		for i = 1, #Config.Worlds do
			if Logic.worldUnlocked(data, i) then n = n + 1 end
		end
		return n
	end
	if stat == "index" then
		local n = 0
		for _ in pairs(data.index or {}) do n = n + 1 end
		return n
	end
	return (data.stats and data.stats[stat]) or 0
end

-- Fortschritt eines Tagesauftrags
function Logic.questProgress(data, q)
	return math.max(0, Logic.statValue(data, q.stat) - (q.start or 0))
end

function Logic.achievementReward(tier)
	return { cash = 150 * 4 ^ (tier - 1), auraSeconds = 120 * tier }
end

----------------------------------------------------------------------------
-- Fans: Charisma & Chance
----------------------------------------------------------------------------
function Logic.charisma(data)
	return Logic.baseGlow(data.levels) + Logic.catLevels(data.levels, "conf") * 10 + (data.rebirths or 0) * 100
end

-- Wie viel Charisma ein Fan mit Promi-Level 1–10 in Welt w braucht
function Logic.fanReq(world, fame)
	local base = Config.FanBaseReq[world] or Config.FanBaseReq[#Config.FanBaseReq]
	return math.floor(base * (0.4 + fame * 0.16))
end

function Logic.fanChance(data, world, fame, mod)
	local req = Logic.fanReq(world, fame)
	return math.clamp(0.5 + 0.45 * (Logic.charisma(data) - req) / req + (mod or 0), 0.03, 0.97)
end

----------------------------------------------------------------------------
-- Jobs
----------------------------------------------------------------------------
function Logic.jobPayMult(data)
	return (1 + Logic.baseGlow(data.levels) / 2000) * (1 + (data.rebirths or 0) * 0.1)
end
function Logic.jobPay(data, job)
	return math.floor(job.pay * Logic.jobPayMult(data))
end

----------------------------------------------------------------------------
-- Waffen & Kampf
----------------------------------------------------------------------------
Logic.weaponById = {}
for _, w in ipairs(Config.Weapons) do
	Logic.weaponById[w.id] = w
end

function Logic.weaponLevel(data, id)
	return (data.weapons and data.weapons[id]) or 0
end

-- Schaden eines Schlags (ohne Krit)
function Logic.weaponDamage(data, id)
	local w = Logic.weaponById[id]
	if not w then return 0 end
	local level = math.max(1, Logic.weaponLevel(data, id))
	return w.damage * (1 + (level - 1) * Config.WEAPON_LEVEL_BONUS)
		* (1 + Logic.baseGlow(data.levels) / 500) * (1 + (data.rebirths or 0) * 0.3)
end

function Logic.weaponUpgradeCost(id, level)
	local w = Logic.weaponById[id]
	local base = (w and w.price > 0) and w.price or 1e7
	return math.floor(math.max(200, base) * 0.5 * 1.6 ^ level)
end

-- Selbstbewusstsein = Lebensbalken im Bosskampf
function Logic.maxConfidence(data)
	return math.floor(100 + Logic.baseGlow(data.levels) / 50)
end


----------------------------------------------------------------------------
-- Gamepasses, Hüte, Wochenende, Events, Laufen
----------------------------------------------------------------------------
function Logic.hasPass(data, key)
	return data.passes ~= nil and data.passes[key] == true
end

Logic.hatById, Logic.auraById, Logic.trailById, Logic.emoteById, Logic.vehicleById = {}, {}, {}, {}, {}
for _, h in ipairs(Config.Hats) do Logic.hatById[h.id] = h end
for _, a in ipairs(Config.Auras) do Logic.auraById[a.id] = a end
for _, t in ipairs(Config.Trails) do Logic.trailById[t.id] = t end
for _, e in ipairs(Config.Emotes) do Logic.emoteById[e.id] = e end
for _, v in ipairs(Config.Vehicles) do Logic.vehicleById[v.id] = v end

-- Bonus des aufgesetzten Hutes (field = "aura", "cash", "luck" oder "speed")
function Logic.hatBoost(data, field)
	local hatId = data.cosmetics and data.cosmetics.hat
	local hat = hatId and Logic.hatById[hatId]
	return (hat and hat.boost[field]) or 0
end

-- Geld-Multiplikator (VIP & Hut)
function Logic.cashMult(data)
	return (Logic.hasPass(data, "vip") and 1.25 or 1) * (1 + Logic.hatBoost(data, "cash"))
end

-- Samstag oder Sonntag (UTC)?
function Logic.isWeekend(now)
	if not now or now <= 0 then return false end
	local t = os.date("!*t", now)
	return t.wday == 1 or t.wday == 7
end

-- Welches Event läuft gerade? (nil = keins)
function Logic.activeEvent(now)
	if Config.EVENT_OVERRIDE and Config.EVENT_OVERRIDE ~= "" then
		for _, ev in ipairs(Config.Events) do
			if ev.id == Config.EVENT_OVERRIDE then return ev end
		end
	end
	if not now or now <= 0 then return nil end
	local t = os.date("!*t", now)
	local today = t.month * 100 + t.day
	for _, ev in ipairs(Config.Events) do
		local from = ev.from[1] * 100 + ev.from[2]
		local to = ev.to[1] * 100 + ev.to[2]
		if from <= to then
			if today >= from and today <= to then return ev end
		elseif today >= from or today <= to then   -- über den Jahreswechsel
			return ev
		end
	end
	return nil
end

function Logic.eventTokens(data, eventId)
	return (data.eventTokens and data.eventTokens[eventId]) or 0
end

-- Laufgeschwindigkeit (Perk, Gamepass, Hut, Fahrzeug)
function Logic.walkSpeed(data, riding)
	local speed = 16 + 2 * Logic.perkLevel(data, "speed") + (Logic.hasPass(data, "speed") and 8 or 0) + Logic.hatBoost(data, "speed")
	if riding then
		local v = Logic.vehicleById[data.vehicle or ""]
		if v then speed = speed + v.speed end
	end
	return speed
end

-- Besitzt der Spieler einen Gegenstand? (kind: "aura", "trail", "hat", "emote", "vehicle")
function Logic.ownsItem(data, kind, id)
	if kind == "vehicle" then return data.vehicles ~= nil and data.vehicles[id] == true end
	if kind == "emote" then
		local e = Logic.emoteById[id]
		if e and e.price == 0 then return true end
	end
	return data.cosmetics ~= nil and data.cosmetics.owned ~= nil and data.cosmetics.owned[id] == true
end

function Logic.itemDef(kind, id)
	if kind == "aura" then return Logic.auraById[id] end
	if kind == "trail" then return Logic.trailById[id] end
	if kind == "hat" then return Logic.hatById[id] end
	if kind == "emote" then return Logic.emoteById[id] end
	if kind == "vehicle" then return Logic.vehicleById[id] end
	return nil
end


return Logic
