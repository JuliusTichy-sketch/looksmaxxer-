--[[
	UTIL – kleine Hilfsfunktionen (Server & Client)
]]

local Util = {}

local SUFFIXES = { "", " Tsd.", " Mio.", " Mrd.", " Bio.", " Brd.", " Trill.", " Trd.", " Quadr.", " Quadrd.",
	" Quint.", " Quintd.", " Sext.", " Sextd.", " Sept.", " Septd.", " Okt.", " Oktd.", " Non.", " Nond.", " Dez." }

-- 12345 -> "12.345"
local function withDots(n)
	local s = tostring(math.floor(n))
	local out = string.reverse((string.gsub(string.reverse(s), "(%d%d%d)", "%1.")))
	if string.sub(out, 1, 1) == "." then
		out = string.sub(out, 2)
	end
	return out
end

-- "12,50" -> "12,5" ; "3,00" -> "3"
local function trimDecimals(s)
	if string.find(s, ",", 1, true) then
		s = string.gsub(s, "0+$", "")
		s = string.gsub(s, ",$", "")
	end
	return s
end

-- Große Zahlen hübsch formatieren (deutsche Schreibweise)
function Util.format(n)
	n = tonumber(n) or 0
	if n ~= n then return "0" end
	if n == math.huge then return "∞" end
	if n < 0 then return "-" .. Util.format(-n) end
	if n < 10 then
		return trimDecimals((string.gsub(string.format("%.1f", n), "%.", ",")))
	end
	if n < 100000 then
		return withDots(n)
	end
	local i = 1
	while n >= 1000 and i < #SUFFIXES do
		n = n / 1000
		i = i + 1
	end
	local s
	if n < 100 then
		s = string.format("%.2f", n)
	else
		s = string.format("%.1f", n)
	end
	s = string.gsub(s, "%.", ",")
	return trimDecimals(s) .. SUFFIXES[i]
end

-- Sekunden -> "1 Std. 5 Min." / "45 s"
function Util.formatTime(sec)
	sec = math.max(0, math.floor(sec))
	if sec < 60 then return sec .. " s" end
	local m = math.floor(sec / 60)
	if m < 60 then return m .. " Min. " .. (sec % 60) .. " s" end
	local h = math.floor(m / 60)
	return h .. " Std. " .. (m % 60) .. " Min."
end

-- Multiplikator schön: 2.5 -> "x2,5"
function Util.formatMult(n)
	return "x" .. Util.format(n)
end

-- Prozent: 0.25 -> "+25 %"
function Util.formatPercent(n)
	return "+" .. Util.format(n * 100) .. " %"
end

-- flache Kopie einer Liste
function Util.copy(list)
	local out = {}
	for i, v in ipairs(list) do
		out[i] = v
	end
	return out
end

-- Liste zufällig mischen
function Util.shuffle(list, rng)
	for i = #list, 2, -1 do
		local j = rng and rng:NextInteger(1, i) or math.random(1, i)
		list[i], list[j] = list[j], list[i]
	end
	return list
end

return Util
