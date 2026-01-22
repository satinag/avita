-- SoundManager: Handles playing sounds at locations
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local SoundManager = {}

-- Play sound at a specific location (3D spatial sound)
function SoundManager:PlaySoundAtLocation(soundName, position)
	local soundsFolder = ReplicatedStorage:FindFirstChild("Sounds")
	if not soundsFolder then
		warn("Sounds folder not found in ReplicatedStorage")
		return
	end

	local soundTemplate = soundsFolder:FindFirstChild(soundName)
	if not soundTemplate then
		warn("Sound not found: " .. soundName)
		return
	end

	-- Create a temporary part to hold the sound
	local soundPart = Instance.new("Part")
	soundPart.Transparency = 1
	soundPart.CanCollide = false
	soundPart.Anchored = true
	soundPart.Size = Vector3.new(1, 1, 1)
	soundPart.Position = position
	soundPart.Parent = workspace

	-- Clone and play the sound
	local sound = soundTemplate:Clone()
	sound.Parent = soundPart
	sound:Play()

	-- Destroy after sound finishes
	game:GetService("Debris"):AddItem(soundPart, sound.TimeLength + 0.5)
end

-- Play sound for a specific player (2D UI sound)
function SoundManager:PlaySoundForPlayer(player, soundName)
	local soundsFolder = ReplicatedStorage:FindFirstChild("Sounds")
	if not soundsFolder then return end

	local soundTemplate = soundsFolder:FindFirstChild(soundName)
	if not soundTemplate then return end

	-- Clone sound to player's PlayerGui
	local sound = soundTemplate:Clone()
	sound.Parent = player:WaitForChild("PlayerGui")
	sound:Play()

	game:GetService("Debris"):AddItem(sound, sound.TimeLength + 0.5)
end

print("🔊 Sound Manager loaded!")

return SoundManager
