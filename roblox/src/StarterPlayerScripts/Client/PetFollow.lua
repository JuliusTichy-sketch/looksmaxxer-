--[[
	PETFOLLOW – bewegt alle Pets (von allen Spielern) flüssig hinter ihren Besitzern her.
	Läuft auf jedem Gerät selbst, damit es ruckelfrei aussieht.
	Pets laufen leicht hüpfend, schauen in Laufrichtung, Regenbogen-Pets wechseln die Farbe.
]]

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local PetFollow = {}
local t = 0
local FAR = 220   -- weiter entfernte Pets werden nicht bewegt (spart Leistung)

function PetFollow.init()
	RunService.RenderStepped:Connect(function(dt)
		t = t + dt
		local folder = workspace:FindFirstChild("Pets")
		local cam = workspace.CurrentCamera
		if not folder or not cam then return end
		local camPos = cam.CFrame.Position
		for _, ownerFolder in ipairs(folder:GetChildren()) do
			local owner = Players:GetPlayerByUserId(tonumber(ownerFolder.Name) or 0)
			local char = owner and owner.Character
			local hrp = char and char:FindFirstChild("HumanoidRootPart")
			if hrp and (hrp.Position - camPos).Magnitude < FAR then
				local pets = ownerFolder:GetChildren()
				local n = #pets
				local moving = hrp.AssemblyLinearVelocity.Magnitude > 1
				for _, model in ipairs(pets) do
					local root = model:IsA("Model") and model.PrimaryPart
					if root then
						local slot = model:GetAttribute("Slot") or 1
						-- im Halbkreis hinter dem Spieler
						local angle = 0
						if n > 1 then
							angle = math.rad(-75 + (slot - 1) * (150 / (n - 1)))
						end
						local hop = moving and math.abs(math.sin(t * 9 + slot)) * 0.8 or math.sin(t * 2 + slot) * 0.25
						local target = hrp.CFrame * CFrame.new(math.sin(angle) * 6.5, -1.4 + hop, 4.5 + math.cos(angle) * 2)
						local current = root.CFrame
						local pos = current.Position:Lerp(target.Position, math.clamp(dt * 7, 0, 1))
						local look = hrp.CFrame.LookVector
						root.CFrame = CFrame.lookAt(pos, pos + Vector3.new(look.X, 0, look.Z))
						-- Regenbogen-Pets wechseln die Farbe
						if model:GetAttribute("Tier") == 3 then
							local color = Color3.fromHSV((t * 0.25 + slot * 0.1) % 1, 0.65, 1)
							for _, p in ipairs(model:GetDescendants()) do
								if p:IsA("BasePart") and p:GetAttribute("Main") then
									p.Color = color
								end
							end
						end
					end
				end
			end
		end
	end)
end

return PetFollow
