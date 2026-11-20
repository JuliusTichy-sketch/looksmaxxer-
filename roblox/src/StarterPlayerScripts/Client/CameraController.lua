--[[
	CAMERACONTROLLER – eigene Kamerasteuerung für alle Geräte

	PC:
	  • Linke ODER rechte Maustaste gedrückt halten + ziehen = Kamera drehen
	  • Mausrad = zoomen
	  • Strg = "Maus-Kamera" an/aus (Kamera folgt der Maus ohne Klicken, wie Shift-Lock)
	Handy/Tablet:
	  • Mit einem Finger wischen = Kamera drehen
	  • Mit zwei Fingern auseinander/zusammen = zoomen
	Die Kamera geht nicht durch Wände (rückt dann näher heran).
	Wischen/Klicken auf Knöpfe, Menüs oder den Joystick dreht die Kamera NICHT.
]]

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local CameraController = {}

local SETTINGS = {
	mouseSensitivity = 0.0045,   -- wie schnell sich die Kamera mit der Maus dreht
	touchSensitivity = 0.008,    -- wie schnell beim Wischen
	minZoom = 6,
	maxZoom = 70,
	startZoom = 22,
	minPitch = math.rad(-75),    -- maximal so weit nach unten schauen
	maxPitch = math.rad(35),     -- maximal so weit nach oben schauen
	focusHeight = 2.5,           -- Kamera schaut etwas über den Kopf
}

local player = Players.LocalPlayer
local yaw, pitch = 0, math.rad(-20)
local zoom, targetZoom = SETTINGS.startZoom, SETTINGS.startZoom
local mouseDragging = false
local mouseLook = false
local touches = {}           -- aktive Kamera-Finger: [InputObject] = letzte Position
local pinchDistance = nil
local listeners = {}

local function clampPitch()
	pitch = math.clamp(pitch, SETTINGS.minPitch, SETTINGS.maxPitch)
end

local function rotate(dx, dy, sensitivity)
	yaw = yaw - dx * sensitivity
	pitch = pitch - dy * sensitivity
	clampPitch()
end

-- Kamera hinter die Figur drehen (z. B. nach dem Spawnen oder Teleport)
function CameraController.snapBehind()
	local char = player.Character
	local hrp = char and char:FindFirstChild("HumanoidRootPart")
	if hrp then
		local look = hrp.CFrame.LookVector
		yaw = math.atan2(-look.X, -look.Z)
	end
end

function CameraController.isMouseLook()
	return mouseLook
end

function CameraController.setMouseLook(on)
	mouseLook = on and UserInputService.MouseEnabled
	for _, fn in ipairs(listeners) do
		pcall(fn, mouseLook)
	end
end

function CameraController.onMouseLookChanged(fn)
	table.insert(listeners, fn)
end

local function countTouches()
	local n = 0
	for _ in pairs(touches) do n = n + 1 end
	return n
end

local function touchList()
	local list = {}
	for input, pos in pairs(touches) do
		table.insert(list, { input = input, pos = pos })
	end
	return list
end

function CameraController.init()
	----------------------------------------------------------------
	-- Eingaben
	----------------------------------------------------------------
	UserInputService.InputBegan:Connect(function(input, gameProcessed)
		local t = input.UserInputType
		if (t == Enum.UserInputType.MouseButton1 or t == Enum.UserInputType.MouseButton2) and not gameProcessed then
			mouseDragging = true
		elseif t == Enum.UserInputType.Touch and not gameProcessed then
			touches[input] = input.Position
			pinchDistance = nil
		elseif t == Enum.UserInputType.Keyboard and not gameProcessed then
			if input.KeyCode == Enum.KeyCode.LeftControl or input.KeyCode == Enum.KeyCode.RightControl then
				CameraController.setMouseLook(not mouseLook)
			end
		end
	end)

	UserInputService.InputEnded:Connect(function(input)
		local t = input.UserInputType
		if t == Enum.UserInputType.MouseButton1 or t == Enum.UserInputType.MouseButton2 then
			if not UserInputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton1)
				and not UserInputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton2) then
				mouseDragging = false
			end
		elseif t == Enum.UserInputType.Touch then
			touches[input] = nil
			pinchDistance = nil
		end
	end)

	UserInputService.InputChanged:Connect(function(input, gameProcessed)
		local t = input.UserInputType
		if t == Enum.UserInputType.MouseMovement then
			if mouseDragging or mouseLook then
				rotate(input.Delta.X, input.Delta.Y, SETTINGS.mouseSensitivity)
			end
		elseif t == Enum.UserInputType.MouseWheel and not gameProcessed then
			targetZoom = math.clamp(targetZoom - input.Position.Z * 4, SETTINGS.minZoom, SETTINGS.maxZoom)
		elseif t == Enum.UserInputType.Touch and touches[input] then
			local n = countTouches()
			if n == 1 then
				local delta = input.Position - touches[input]
				rotate(delta.X, delta.Y, SETTINGS.touchSensitivity)
			elseif n >= 2 then
				-- Zwei Finger: Zoomen
				touches[input] = input.Position
				local list = touchList()
				local dist = (list[1].pos - list[2].pos).Magnitude
				if pinchDistance then
					targetZoom = math.clamp(targetZoom - (dist - pinchDistance) * 0.08, SETTINGS.minZoom, SETTINGS.maxZoom)
				end
				pinchDistance = dist
			end
			touches[input] = input.Position
		end
	end)

	-- Falls das Fenster den Fokus verliert: Ziehen beenden
	UserInputService.WindowFocusReleased:Connect(function()
		mouseDragging = false
		touches = {}
	end)

	player.CharacterAdded:Connect(function(char)
		char:WaitForChild("HumanoidRootPart", 10)
		task.wait()
		CameraController.snapBehind()
	end)
	if player.Character then
		CameraController.snapBehind()
	end

	----------------------------------------------------------------
	-- Jedes Bild: Kamera positionieren
	----------------------------------------------------------------
	local rayParams = RaycastParams.new()
	rayParams.FilterType = Enum.RaycastFilterType.Exclude
	rayParams.IgnoreWater = true

	RunService:BindToRenderStep("LooksmaxxerCamera", Enum.RenderPriority.Camera.Value + 1, function(dt)
		local cam = workspace.CurrentCamera
		local char = player.Character
		local hrp = char and char:FindFirstChild("HumanoidRootPart")
		if not cam or not hrp then return end
		cam.CameraType = Enum.CameraType.Scriptable

		-- Mauszeiger: beim Ziehen festhalten, bei Maus-Kamera in die Mitte sperren
		if mouseLook then
			UserInputService.MouseBehavior = Enum.MouseBehavior.LockCenter
			UserInputService.MouseIconEnabled = false
		elseif mouseDragging then
			UserInputService.MouseBehavior = Enum.MouseBehavior.LockCurrentPosition
			UserInputService.MouseIconEnabled = true
		else
			UserInputService.MouseBehavior = Enum.MouseBehavior.Default
			UserInputService.MouseIconEnabled = true
		end

		zoom = zoom + (targetZoom - zoom) * math.clamp(dt * 10, 0, 1)
		local focus = hrp.Position + Vector3.new(0, SETTINGS.focusHeight, 0)
		local rotation = CFrame.Angles(0, yaw, 0) * CFrame.Angles(pitch, 0, 0)
		local desired = focus + rotation:VectorToWorldSpace(Vector3.new(0, 0, zoom))

		-- Nicht durch Wände schauen
		local ignore = { char }
		local pets = workspace:FindFirstChild("Pets")
		if pets then table.insert(ignore, pets) end
		rayParams.FilterDescendantsInstances = ignore
		local dir = desired - focus
		local hit = workspace:Raycast(focus, dir, rayParams)
		local camPos = desired
		if hit and hit.Instance and hit.Instance.CanCollide and hit.Instance.Transparency < 0.9 then
			camPos = hit.Position - dir.Unit * 0.6
		end

		cam.CFrame = CFrame.lookAt(camPos, focus)
		cam.Focus = CFrame.new(focus)

		-- Bei Maus-Kamera schaut die Figur in Blickrichtung (wie Shift-Lock)
		local hum = char:FindFirstChildOfClass("Humanoid")
		if hum then
			hum.AutoRotate = not mouseLook
			if mouseLook then
				hrp.CFrame = CFrame.new(hrp.Position) * CFrame.Angles(0, yaw, 0)
			end
		end
	end)
end

return CameraController
