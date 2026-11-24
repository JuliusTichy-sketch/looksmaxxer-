--[[
	FANSERVICE – in jeder Welt laufen Leute herum, die du als Fans gewinnen kannst.
	• Promi-Level 1–10: je höher, desto mehr Charisma brauchst du
	• Du wählst einen von 3 Sprüchen/Aktionen (manche helfen, manche nicht 😄)
	• Erfolg: Aura + Geld, Zähler "fans" steigt (für Aufträge & Erfolge)
	Die Figuren laufen nur herum, wenn jemand in ihrer Welt ist (spart Leistung).
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config"))
local Logic = require(Shared:WaitForChild("Logic"))
local Util = require(Shared:WaitForChild("Util"))
local Remotes = require(script.Parent.Remotes)
local DataService = require(script.Parent.DataService)
local GameService = require(script.Parent.GameService)

local FanService = {}
local rng = Random.new()
local fans = {}          -- alle Fans
local cooldowns = {}     -- [player] = { [fanId] = os.clock() bis wann gesperrt }
local pending = {}       -- [player] = { fan, openers, t }

local WALK_ANIM = "rbxassetid://507777826"   -- Standard-Laufanimation (R15)

local SKIN = { Color3.fromRGB(255, 224, 196), Color3.fromRGB(241, 194, 125), Color3.fromRGB(224, 172, 105),
	Color3.fromRGB(198, 134, 66), Color3.fromRGB(141, 85, 36), Color3.fromRGB(92, 58, 30) }
local CLOTHES = { Color3.fromRGB(230, 57, 70), Color3.fromRGB(255, 143, 171), Color3.fromRGB(155, 92, 255), Color3.fromRGB(58, 134, 255),
	Color3.fromRGB(42, 157, 143), Color3.fromRGB(255, 183, 3), Color3.fromRGB(240, 240, 240), Color3.fromRGB(34, 34, 34) }

-- freier Platz auf dem Boden (nicht in Gebäuden)
local function groundSpot(origin)
	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	local npcs = workspace:FindFirstChild("NPCs")
	params.FilterDescendantsInstances = npcs and { npcs } or {}
	for _ = 1, 40 do
		local x = rng:NextNumber(-170, 170)
		local z = rng:NextNumber(-170, 170)
		if math.sqrt(x * x + z * z) > 35 then
			local from = origin + Vector3.new(x, 300, z)
			local hit = workspace:Raycast(from, Vector3.new(0, -400, 0), params)
			if hit and (hit.Instance.Name == "Ground" or hit.Instance:IsA("Terrain")) and hit.Material ~= Enum.Material.Water and hit.Position.Y < 4 then
				return hit.Position
			end
		end
	end
	return origin + Vector3.new(rng:NextNumber(-30, 30), 0, 40)
end

local function makeFan(world, index)
	local origin = GameService.worldOrigin(world)
	local fame = rng:NextInteger(1, 10)
	local name = Config.FanNames[rng:NextInteger(1, #Config.FanNames)]
	local role = Config.FanRoles[fame]
	local skin = SKIN[rng:NextInteger(1, #SKIN)]
	local model
	local ok = pcall(function()
		local desc = Instance.new("HumanoidDescription")
		desc.HeadColor = skin
		desc.LeftArmColor = skin
		desc.RightArmColor = skin
		desc.TorsoColor = CLOTHES[rng:NextInteger(1, #CLOTHES)]
		local pants = CLOTHES[rng:NextInteger(1, #CLOTHES)]
		desc.LeftLegColor = pants
		desc.RightLegColor = pants
		desc.HeightScale = rng:NextNumber(0.9, 1.05)
		model = Players:CreateHumanoidModelFromDescription(desc, Enum.HumanoidRigType.R15)
	end)
	if not ok or not model then return nil end
	model.Name = "Fan_" .. name
	local hum = model:FindFirstChildOfClass("Humanoid")
	local hrp = model:FindFirstChild("HumanoidRootPart")
	if not hum or not hrp then return nil end
	hum.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None
	hum.WalkSpeed = 7
	local home = groundSpot(origin)
	model:PivotTo(CFrame.new(home + Vector3.new(0, 3, 0)))
	model.Parent = workspace:FindFirstChild("NPCs") or workspace
	pcall(function() hrp:SetNetworkOwner(nil) end)

	-- Namensschild
	local head = model:FindFirstChild("Head")
	local bb = Instance.new("BillboardGui")
	bb.Size = UDim2.new(6, 0, 1.6, 0)
	bb.StudsOffset = Vector3.new(0, 2.4, 0)
	bb.MaxDistance = 80
	bb.LightInfluence = 0
	bb.Parent = head
	local label = Instance.new("TextLabel")
	label.Size = UDim2.new(1, 0, 1, 0)
	label.BackgroundTransparency = 1
	label.TextScaled = true
	label.RichText = true
	label.Font = Enum.Font.FredokaOne
	label.TextColor3 = Color3.new(1, 1, 1)
	label.TextStrokeTransparency = 0.3
	label.Text = "<font color='#ff9ad5'>⭐ " .. name .. " · " .. fame .. "/10</font>\n<font size='12'>" .. role .. "</font>"
	label.Parent = bb

	local prompt = Instance.new("ProximityPrompt")
	prompt.ActionText = "Begeistern"
	prompt.ObjectText = name .. " (Promi " .. fame .. "/10)"
	prompt.HoldDuration = 0.25
	prompt.MaxActivationDistance = 10
	prompt.RequiresLineOfSight = false
	prompt.Parent = hrp

	-- Laufanimation
	pcall(function()
		local animator = hum:FindFirstChildOfClass("Animator") or Instance.new("Animator")
		animator.Parent = hum
		local anim = Instance.new("Animation")
		anim.AnimationId = WALK_ANIM
		local track = animator:LoadAnimation(anim)
		hum.Running:Connect(function(speed)
			if speed > 0.5 then
				if not track.IsPlaying then track:Play() end
			elseif track.IsPlaying then
				track:Stop()
			end
		end)
	end)

	local fan = { id = world .. "_" .. index, world = world, fame = fame, name = name, role = role,
		model = model, hum = hum, hrp = hrp, home = home, head = head }
	prompt.Triggered:Connect(function(player)
		FanService.talk(player, fan)
	end)
	return fan
end

-- Kurzes Herz über dem Kopf
local function heart(fan, text)
	if not fan.head then return end
	local bb = Instance.new("BillboardGui")
	bb.Size = UDim2.new(3, 0, 1.5, 0)
	bb.StudsOffset = Vector3.new(0, 4.2, 0)
	bb.LightInfluence = 0
	bb.Parent = fan.head
	local l = Instance.new("TextLabel")
	l.Size = UDim2.new(1, 0, 1, 0)
	l.BackgroundTransparency = 1
	l.TextScaled = true
	l.Text = text
	l.Parent = bb
	task.delay(3, function() bb:Destroy() end)
end

function FanService.talk(player, fan)
	local data = DataService.get(player)
	if not data or not Logic.worldUnlocked(data, fan.world) then return end
	cooldowns[player] = cooldowns[player] or {}
	local blockedUntil = cooldowns[player][fan.id]
	if blockedUntil and blockedUntil > os.clock() then
		GameService.notify(player, "🙄 Gerade nicht", fan.name .. " braucht noch " .. math.ceil(blockedUntil - os.clock()) .. " s Pause von dir.", "")
		return
	end
	-- 3 zufällige Sprüche
	local pool = Util.copy(Config.FanOpeners)
	Util.shuffle(pool, rng)
	local openers = { pool[1], pool[2], pool[3] }
	pending[player] = { fan = fan, openers = openers, t = os.clock() }
	local texts = {}
	for i, o in ipairs(openers) do texts[i] = o.text end
	Remotes.FanDialog:FireClient(player, {
		name = fan.name, role = fan.role, fame = fan.fame,
		chance = math.floor(Logic.fanChance(data, fan.world, fan.fame, 0) * 100 + 0.5),
		charisma = Logic.charisma(data), req = Logic.fanReq(fan.world, fan.fame),
		openers = texts,
	})
end

Remotes.FanChoice.OnServerEvent:Connect(function(player, index)
	local p = pending[player]
	pending[player] = nil
	local data = DataService.get(player)
	if not p or not data or os.clock() - p.t > 60 then return end
	local op = p.openers[tonumber(index) or 0]
	if not op then return end
	local fan = p.fan
	local mod = op.mod or 0
	if op.kind == "conf" then
		mod = Logic.catLevels(data.levels, "conf") >= 30 and 0.15 or -0.1
	elseif op.kind == "glow" then
		mod = Logic.charisma(data) >= Logic.fanReq(fan.world, fan.fame) * 1.5 and 0.15 or -0.15
	elseif op.kind == "rand" then
		mod = rng:NextNumber(-0.25, 0.2)
	end
	local chance = Logic.fanChance(data, fan.world, fan.fame, mod)
	cooldowns[player] = cooldowns[player] or {}
	if rng:NextNumber() < chance then
		local aps = math.max(Logic.aps(data, GameService.currentWorld(player), os.time()), 5)
		local aura = aps * 10 * fan.fame
		local cash = math.floor(5 * fan.fame * fan.world * fan.world * Logic.cashMult(data))
		GameService.addAura(data, aura)
		data.cash = data.cash + cash
		GameService.track(player, "fans", 1)
		cooldowns[player][fan.id] = os.clock() + Config.FAN_REPEAT
		heart(fan, "💚")
		Remotes.FanResult:FireClient(player, true, Config.FanYes[rng:NextInteger(1, #Config.FanYes)],
			"+" .. Util.format(aura) .. " Aura · +" .. Util.format(cash) .. " Geld")
	else
		cooldowns[player][fan.id] = os.clock() + Config.FAN_FAIL_COOLDOWN
		heart(fan, "😒")
		local tip = chance < 0.35 and "Tipp: Mehr Glow, Selbstbewusstsein-Upgrades und Rebirths erhöhen dein Charisma." or ""
		Remotes.FanResult:FireClient(player, false, string.format(Config.FanNo[rng:NextInteger(1, #Config.FanNo)], fan.name), tip)
	end
	GameService.sendFull(player)
end)

-- Fans laufen in ihrer Nähe herum, wenn Spieler in der Welt sind
local function worldHasPlayers(world)
	for _, plr in ipairs(Players:GetPlayers()) do
		if (plr:GetAttribute("World") or 1) == world then return true end
	end
	return false
end

function FanService.init()
	for w = 1, #Config.Worlds do
		for i = 1, Config.FANS_PER_WORLD do
			local fan = makeFan(w, i)
			if fan then table.insert(fans, fan) end
		end
	end
	task.spawn(function()
		while true do
			task.wait(4)
			local active = {}
			for w = 1, #Config.Worlds do active[w] = worldHasPlayers(w) end
			for _, fan in ipairs(fans) do
				if fan.model.Parent then
					if active[fan.world] then
						-- Welt ist besucht: Fan bewegt sich
						if fan.hrp.Anchored then fan.hrp.Anchored = false end
						if rng:NextNumber() < 0.5 then
							local target = fan.home + Vector3.new(rng:NextNumber(-35, 35), 0, rng:NextNumber(-35, 35))
							fan.hum:MoveTo(target)
						end
					elseif not fan.hrp.Anchored then
						-- niemand da: Fan "einfrieren" (spart Server-Leistung)
						fan.hrp.Anchored = true
					end
				end
			end
		end
	end)
end

Players.PlayerRemoving:Connect(function(player)
	cooldowns[player] = nil
	pending[player] = nil
end)

return FanService
