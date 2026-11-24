--[[
	EVENTSERVICE – saisonale Events (Winter, Halloween, Sommer) laufen automatisch nach Kalender.
	Während eines Events liegen in allen Welten Sammelobjekte (z. B. ❄️ Schneeflocken).
	Mit den Event-Münzen öffnet man die Event-Box in Glow City (exklusive Pets!).
	Außerdem: Samstag & Sonntag automatisch doppelte Aura & doppeltes Glück (siehe Logic).
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config"))
local Logic = require(Shared:WaitForChild("Logic"))
local DataService = require(script.Parent.DataService)
local GameService = require(script.Parent.GameService)

local EventService = {}
local rng = Random.new()
local items = {}        -- [world] = Liste der Sammelobjekte
local folder = nil

local function groundSpot(origin)
	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	params.FilterDescendantsInstances = { folder }
	for _ = 1, 30 do
		local x, z = rng:NextNumber(-200, 200), rng:NextNumber(-200, 200)
		local hit = workspace:Raycast(origin + Vector3.new(x, 300, z), Vector3.new(0, -400, 0), params)
		if hit and (hit.Instance.Name == "Ground" or hit.Instance:IsA("Terrain")) and hit.Position.Y < 4 then
			return hit.Position
		end
	end
	return nil
end

local function spawnItem(ev, world)
	local pos = groundSpot(GameService.worldOrigin(world))
	if not pos then return end
	local p = Instance.new("Part")
	p.Name = "EventItem"
	p.Shape = Enum.PartType.Ball
	p.Size = Vector3.new(2.6, 2.6, 2.6)
	p.Color = ev.color
	p.Material = Enum.Material.Neon
	p.Transparency = 0.2
	p.Anchored = true
	p.CanCollide = false
	p.CFrame = CFrame.new(pos + Vector3.new(0, 2.5, 0))
	local bb = Instance.new("BillboardGui")
	bb.Size = UDim2.new(3, 0, 3, 0)
	bb.StudsOffset = Vector3.new(0, 2.2, 0)
	bb.MaxDistance = 90
	bb.LightInfluence = 0
	bb.Parent = p
	local l = Instance.new("TextLabel")
	l.Size = UDim2.new(1, 0, 1, 0)
	l.BackgroundTransparency = 1
	l.TextScaled = true
	l.Text = ev.tokenEmoji
	l.Parent = bb
	local light = Instance.new("PointLight")
	light.Color = ev.color
	light.Range = 10
	light.Parent = p
	local taken = false
	p.Touched:Connect(function(hit)
		if taken then return end
		local player = Players:GetPlayerFromCharacter(hit.Parent)
		local data = player and DataService.get(player)
		if not data then return end
		taken = true
		local amount = 1 + (Logic.isWeekend(os.time()) and 1 or 0)
		data.eventTokens[ev.id] = Logic.eventTokens(data, ev.id) + amount
		local aps = math.max(Logic.aps(data, GameService.currentWorld(player), os.time()), 5)
		GameService.addAura(data, aps * 5)
		GameService.notify(player, ev.tokenEmoji .. " +" .. amount .. " " .. ev.token, "Du hast jetzt " .. Logic.eventTokens(data, ev.id) .. ". Event-Box in Glow City!", "")
		GameService.sendFull(player)
		p:Destroy()
	end)
	p.Parent = folder
	table.insert(items[world], p)
end

function EventService.init()
	folder = Instance.new("Folder")
	folder.Name = "EventItems"
	folder.Parent = workspace
	for w = 1, #Config.Worlds do items[w] = {} end
	task.spawn(function()
		while true do
			local ev = Logic.activeEvent(os.time())
			for w = 1, #Config.Worlds do
				-- verschwundene (eingesammelte) Objekte aus der Liste entfernen
				local alive = {}
				for _, p in ipairs(items[w]) do
					if p.Parent then
						if ev then table.insert(alive, p) else p:Destroy() end
					end
				end
				items[w] = alive
				if ev and #alive < Config.EVENT_ITEMS_PER_WORLD then
					spawnItem(ev, w)
				end
			end
			task.wait(8)
		end
	end)
end

return EventService
