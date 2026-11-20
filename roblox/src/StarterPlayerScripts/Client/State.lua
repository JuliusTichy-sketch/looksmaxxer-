--[[
	STATE – speichert auf dem Gerät den letzten Spielstand vom Server
	und informiert alle Menüs, wenn sich etwas ändert.
]]

local State = {}
State.snap = nil        -- letzter Stand vom Server (siehe GameService.snapshot)
State.listeners = {}

function State.onChange(fn)
	table.insert(State.listeners, fn)
end

local function fire(kind)
	for _, fn in ipairs(State.listeners) do
		local ok, err = pcall(fn, kind)
		if not ok then
			warn("[Looksmaxxer UI]", err)
		end
	end
end

function State.setFull(snap)
	State.snap = snap
	fire("full")
end

function State.setLight(l)
	local s = State.snap
	if not s then return end
	s.data.aura = l.aura
	s.data.cash = l.cash
	s.data.totalAura = l.totalAura
	s.aps = l.aps
	s.click = l.click
	s.mult = l.mult
	s.world = l.world
	s.serverTime = l.serverTime
	fire("light")
end

-- nur lokal (z. B. Klick sofort anzeigen, bevor der Server antwortet)
function State.bump()
	fire("light")
end

return State
