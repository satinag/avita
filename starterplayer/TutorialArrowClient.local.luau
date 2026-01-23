-- StarterPlayer/StarterPlayerScripts/TutorialArrowClient
-- Updated to use TutorialIndicatorHandlers module

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local player = Players.LocalPlayer
local TutorialLevelConfig = require(ReplicatedStorage:WaitForChild("TutorialLevelConfig"))
local IndicatorHandlers = require(script.Parent:WaitForChild("TutorialIndicatorHandlers"))

local function updateArrow(level)
	if level >= 999 or level == 0 then
		IndicatorHandlers:HideIndicator()
		if level >= 999 then
			print("✅ Tutorial Complete! No more indicators.")
		else
			print("⏸️ Tutorial Paused - waiting for unlock")
		end
		return
	end

	local levelConfig = TutorialLevelConfig:GetLevel(level)
	if not levelConfig then
		warn("Could not find level config for: " .. level)
		IndicatorHandlers:HideIndicator()
		return
	end

	IndicatorHandlers:ShowIndicator(levelConfig)
	print("📍 Tutorial Level " .. level .. ": " .. levelConfig.DisplayName)
end

local currentLevelValue = player:WaitForChild("CurrentArrowLevel", 10)
if not currentLevelValue then
	warn("CurrentArrowLevel not found on player")
	return
end

task.wait(1)
updateArrow(currentLevelValue.Value)

currentLevelValue.Changed:Connect(function(newLevel)
	task.wait(0.5)
	updateArrow(newLevel)
end)

player.CharacterAdded:Connect(function(character)
	IndicatorHandlers:HideIndicator()
	task.wait(1)
	updateArrow(currentLevelValue.Value)
end)

player.CharacterRemoving:Connect(function()
	IndicatorHandlers:HideIndicator()
end)

print("🎯 TutorialArrowClient loaded successfully")
