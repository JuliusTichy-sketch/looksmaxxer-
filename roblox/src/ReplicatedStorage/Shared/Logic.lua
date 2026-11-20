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
	return Config.BASE_PET_SLOTS + Logic.perkLevel(data, "petslot")
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
	return (1 + Logic.perkLevel(data, "luck") * 0.1) * Logic.potionFactor(data, "luck", now)
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

return Logic
