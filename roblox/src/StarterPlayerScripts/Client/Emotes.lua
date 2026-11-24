--[[
	EMOTES – spielt Emotes (Animationen) am eigenen Avatar ab.
	Eigene Animationen sieht jeder andere Spieler automatisch auch.
]]

local Players = game:GetService("Players")

local Emotes = {}
local current = nil

function Emotes.play(def)
	local char = Players.LocalPlayer.Character
	local hum = char and char:FindFirstChildOfClass("Humanoid")
	local animator = hum and hum:FindFirstChildOfClass("Animator")
	if not animator or not def or not def.anim then return end
	if current then current:Stop() end
	local anim = Instance.new("Animation")
	anim.AnimationId = def.anim
	local ok, track = pcall(function() return animator:LoadAnimation(anim) end)
	if ok and track then
		track.Priority = Enum.AnimationPriority.Action
		track:Play()
		current = track
	end
	if def.bubble then
		pcall(function()
			game:GetService("TextChatService"):DisplayBubble(char:FindFirstChild("Head"), def.bubble)
		end)
	end
end

return Emotes
