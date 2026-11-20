--[[
	PETFOLLOW – bewegt alle Pets (von allen Spielern) flüssig hinter ihren Besitzern her.
	Läuft auf jedem Gerät selbst, damit es ruckelfrei aussieht.
]]

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local PetFollow = {}
local t = 0

function PetFollow.init()
	RunService.RenderStepped:Connect(function(dt)
		t = t + dt
		local folder = workspace:FindFirstChild("Pets")
		if not folder then return end
		for _, ownerFolder in ipairs(folder:GetChildren()) do
			local owner = Players:GetPlayerByUserId(tonumber(ownerFolder.Name) or 0)
			local char = owner and owner.Character
			local hrp = char and char:FindFirstChild("HumanoidRootPart")
			if hrp then
				local pets = ownerFolder:GetChildren()
				local n = #pets
				for _, p in ipairs(pets) do
					if p:IsA("BasePart") then
						local slot = p:GetAttribute("Slot") or 1
						-- Pets im Halbkreis hinter dem Spieler
						local angle = 0
						if n > 1 then
							angle = math.rad(-70 + (slot - 1) * (140 / (n - 1)))
						end
						local bob = math.sin(t * 3 + slot) * 0.4
						local target = hrp.CFrame * CFrame.new(math.sin(angle) * 6, -1 + bob, 4 + math.cos(angle) * 2)
						p.CFrame = p.CFrame:Lerp(target, math.clamp(dt * 7, 0, 1))
						-- Regenbogen-Pets wechseln die Farbe
						if p:GetAttribute("Tier") == 3 then
							p.Color = Color3.fromHSV((t * 0.25 + slot * 0.1) % 1, 0.65, 1)
						end
					end
				end
			end
		end
	end)
end

return PetFollow
