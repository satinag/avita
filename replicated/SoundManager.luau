-- SoundManager: Handles playing sounds (with safety checks)
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local SoundManager = {}

-- Play sound at a specific location (3D spatial sound)
function SoundManager:PlaySoundAtLocation(soundName, position)
	local success, err = pcall(function()
		local soundsFolder = ReplicatedStorage:FindFirstChild("Sounds")
		if not soundsFolder then return end

		local soundTemplate = soundsFolder:FindFirstChild(soundName)
		if not soundTemplate then return end

		local soundPart = Instance.new("Part")
		soundPart.Transparency = 1
		soundPart.CanCollide = false
		soundPart.Anchored = true
		soundPart.Size = Vector3.new(1, 1, 1)
		soundPart.Position = position
		soundPart.Parent = workspace

		local sound = soundTemplate:Clone()
		sound.Parent = soundPart
		sound:Play()

		game:GetService("Debris"):AddItem(soundPart, sound.TimeLength + 0.5)
	end)

	if not success then
		warn("Sound error:", err)
	end
end

-- Play sound for a specific player (2D UI sound)
function SoundManager:PlaySoundForPlayer(player, soundName)
	local success, err = pcall(function()
		local soundsFolder = ReplicatedStorage:FindFirstChild("Sounds")
		if not soundsFolder then return end

		local soundTemplate = soundsFolder:FindFirstChild(soundName)
		if not soundTemplate then return end

		local sound = soundTemplate:Clone()
		sound.Parent = player:WaitForChild("PlayerGui")
		sound:Play()

		game:GetService("Debris"):AddItem(sound, sound.TimeLength + 0.5)
	end)

	if not success then
		warn("Sound error:", err)
	end
end

print("🔊 Sound Manager loaded!")

return SoundManager
