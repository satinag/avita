-- StarterPlayer/StarterPlayerScripts/TutorialArrowClient

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local player = Players.LocalPlayer
local TutorialArrowConfig = require(ReplicatedStorage:WaitForChild("TutorialArrowConfig"))

local currentBeam = nil
local currentPlayerAttachment = nil

local function removeArrow()
	if currentBeam then
		currentBeam:Destroy()
		currentBeam = nil
	end
	if currentPlayerAttachment then
		currentPlayerAttachment:Destroy()
		currentPlayerAttachment = nil
	end
end

local function createArrow(targetPart)
	removeArrow()  -- Clear any existing arrow
	
	local character = player.Character
	if not character then return end
	
	local humanoidRootPart = character:FindFirstChild("HumanoidRootPart")
	if not humanoidRootPart then return end
	
	-- Find or create attachment on target
	local targetAttachment = targetPart:FindFirstChildOfClass("Attachment")
	if not targetAttachment then
		targetAttachment = Instance.new("Attachment")
		targetAttachment.Name = "ArrowTargetAttachment"
		targetAttachment.Parent = targetPart
	end
	
	-- Create attachment on player
	currentPlayerAttachment = Instance.new("Attachment")
	currentPlayerAttachment.Name = "ArrowPlayerAttachment"
	currentPlayerAttachment.Parent = humanoidRootPart
	
	-- Create beam with configured settings
	currentBeam = Instance.new("Beam")
	currentBeam.Name = "TutorialArrowBeam"
	currentBeam.Parent = workspace.CurrentCamera
	currentBeam.Attachment0 = currentPlayerAttachment
	currentBeam.Attachment1 = targetAttachment
	
	-- Apply settings from config
	local settings = TutorialArrowConfig.ArrowSettings
	currentBeam.Color = ColorSequence.new(settings.Color)
	currentBeam.Width0 = settings.Width0
	currentBeam.Width1 = settings.Width1
	currentBeam.FaceCamera = true
	currentBeam.Transparency = NumberSequence.new(settings.Transparency)
	currentBeam.LightEmission = settings.LightEmission
	currentBeam.Texture = settings.Texture
	currentBeam.TextureSpeed = settings.TextureSpeed
	currentBeam.TextureLength = settings.TextureLength
	
	print("🎯 Arrow created pointing to " .. targetPart.Name)
end

local function updateArrow(stepName)
	-- ✅ Handle Completed and Paused states
	if stepName == "Completed" or stepName == "Paused" then
		removeArrow()
		print("✅ Tutorial " .. stepName .. "! No more arrows.")
		return
	end
	
	-- Get step configuration
	local stepConfig = TutorialArrowConfig:GetStep(stepName)
	if not stepConfig then
		warn("Could not find step config for: " .. stepName)
		removeArrow()
		return
	end
	
	-- Find target part using helper function
	local targetPart = TutorialArrowConfig:GetTargetPart(stepConfig.Target, stepConfig.TargetType)
	if not targetPart then
		warn("Could not find or get valid part for target: " .. stepConfig.Target)
		removeArrow()
		return
	end
	
	-- Create arrow pointing to target
	createArrow(targetPart)
	print("📍 Tutorial Step: " .. stepConfig.DisplayName .. " | Target: " .. targetPart:GetFullName())
end

-- Wait for CurrentArrowStep value from server
local currentStepValue = player:WaitForChild("CurrentArrowStep", 10)
if not currentStepValue then
	warn("CurrentArrowStep not found on player")
	return
end

-- Initial arrow setup
task.wait(1)  -- Wait for character to fully load
updateArrow(currentStepValue.Value)

-- Listen for step changes
currentStepValue.Changed:Connect(function(newStep)
	task.wait(0.5)  -- Small delay for smooth transition
	updateArrow(newStep)
end)

-- Handle character respawn
player.CharacterAdded:Connect(function(character)
	removeArrow()
	task.wait(1)
	updateArrow(currentStepValue.Value)
end)

-- Cleanup
player.CharacterRemoving:Connect(function()
	removeArrow()
end)
