--[[
	PETVIEW – zeigt ein Pet als drehbare 3D-Vorschau in Menüs (ViewportFrame).
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local PetModels = require(Shared:WaitForChild("PetModels"))
local Logic = require(Shared:WaitForChild("Logic"))

local PetView = {}
local spinning = {}   -- Modelle, die sich langsam drehen

RunService.RenderStepped:Connect(function(dt)
	for model, data in pairs(spinning) do
		if not model.Parent then
			spinning[model] = nil
		else
			data.angle = data.angle + dt * 0.8
			model:PivotTo(CFrame.Angles(0, data.angle, 0))
		end
	end
end)

-- parent: GUI-Element; petId: z. B. "w1_3"; tier: 1–4; spin: drehen?
function PetView.make(parent, petId, tier, spin, props)
	props = props or {}
	local def = Logic.petById[petId]
	local vp = Instance.new("ViewportFrame")
	vp.Name = "PetView"
	vp.BackgroundTransparency = 1
	vp.Size = props.Size or UDim2.new(1, 0, 1, 0)
	vp.Position = props.Position or UDim2.new(0, 0, 0, 0)
	vp.Ambient = Color3.fromRGB(190, 190, 200)
	vp.LightColor = Color3.fromRGB(255, 250, 240)
	vp.LightDirection = Vector3.new(-1, -1.2, -0.6)
	vp.ZIndex = props.ZIndex or 1
	vp.Parent = parent
	if not def then return vp end

	local model = PetModels.build(def, tier or 1, false)
	model.Parent = vp
	local cam = Instance.new("Camera")
	cam.FieldOfView = 40
	local size = model:GetExtentsSize()
	local dist = math.max(size.X, size.Y, size.Z) * 1.9 + 1
	cam.CFrame = CFrame.lookAt(Vector3.new(dist * 0.45, dist * 0.3, -dist), Vector3.new(0, 0, 0))
	cam.Parent = vp
	vp.CurrentCamera = cam
	if spin then
		spinning[model] = { angle = 0 }
	end
	return vp
end

return PetView
