local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local DataStoreService = game:GetService("DataStoreService")
local RunService = game:GetService("RunService")

local TutorialArrowConfig = require(ReplicatedStorage:WaitForChild("TutorialArrowConfig"))
local TutorialDataStore = DataStoreService:GetDataStore("TutorialProgress_v3.7")
--local TutorialDataStore = DataStoreService:GetDataStore("TutorialProgress_v1.1")

-- ✅ Only create if it doesn't exist (prevent duplicates)
local showTutorialEvent = ReplicatedStorage:FindFirstChild("ShowTutorialEvent")
if not showTutorialEvent then
	showTutorialEvent = Instance.new("RemoteEvent")
	showTutorialEvent.Name = "ShowTutorialEvent"
	showTutorialEvent.Parent = ReplicatedStorage
	print("📚 Created ShowTutorialEvent")
else
	print("📚 Using existing ShowTutorialEvent")
end

local tutorialDismissedEvent = ReplicatedStorage:FindFirstChild("TutorialDismissedEvent")
if not tutorialDismissedEvent then
	tutorialDismissedEvent = Instance.new("RemoteEvent")
	tutorialDismissedEvent.Name = "TutorialDismissedEvent"
	tutorialDismissedEvent.Parent = ReplicatedStorage
	print("📚 Created TutorialDismissedEvent")
else
	print("📚 Using existing TutorialDismissedEvent")
end

print("📚 Tutorial Manager loaded")

-- ============================================
-- TUTORIAL DATA
-- ============================================

local TUTORIAL_DATA = {
	Welcome = {
		Title = "🌾 Welcome to Your Farm! ",
		Message = "Follow the yellow arrow to the Seed Shop.\nBuy seeds to start farming! ",
		Duration = 8
	},
	PlantingTutorial = {
		Title = "🌱 Time to Plant!",
		Message = "Follow the arrow to your plot.\nClaim it, then plant your seeds!",
		Duration = 6
	},
	FirstHarvest = {
		Title = "🎉 Ready to Harvest!",
		Message = "Your crop is ready!  Click it to harvest.\nThen follow the arrow to the Barn to sell!",
		Duration = 6
	},
	BarnVisit = {
		Title = "💰 Processing Barn",
		Message = "Here you can sell crops for cash or convert them to seeds.\nSelling gives the most profit!",
		Duration = nil
	},
	Zone1Unlock = {
		Title = "🎊 New Area Unlocked!",
		Message = "You've earned 1000 cash!\nExpansion Zone 1 is now open with 4 more plots!",
		Duration = 6
	},
	Zone2Unlock = {
		Title = "🌟 Expansion Zone 2 Unlocked!",
		Message = "You've earned $5,000!\nZone 2 is now open with even more space!",
		Duration = 6
	},
	Zone3Unlock = {
		Title = "🏆 Expansion Zone 3 Unlocked! ",
		Message = "You've earned $15,000!\nYou're becoming a farming tycoon!",
		Duration = 6
	},
	PoultryUnlock = {
		Title = "🐔 Poultry Farm Unlocked!",
		Message = "You've earned $25,000!\nRaise chickens and collect eggs for profit!",
		Duration = 7
	},
	BeehiveUnlock = {
		Title = "🐝 First Beehive Purchased!",
		Message = "Follow the arrow to your hive!\n🍯 Collect honey every hour for profit.\n\n💡 Buy more hives for greater income!",
		Duration = 8
	},
	FirstHiveCollection = {
		Title = "🍯 First Honey Collection!",
		Message = "Great! Beehives produce honey every hour.\n\nCollect from each hive manually, or upgrade to passive income in the Barn!",
		Duration = 7
	}
}

-- ============================================
-- HELPER FUNCTIONS
-- ============================================

local function loadPlayerProgress(userId)
	local success, data = pcall(function()
		return TutorialDataStore:GetAsync(userId ..  "-progress")
	end)

	if success and data then
		return data
	else
		return {
			CurrentStep = TutorialArrowConfig.Steps[1].Name,
			CompletedSteps = {},
			ShownMessages = {}
		}
	end
end

local function savePlayerProgress(userId, progressData)
	pcall(function()
		TutorialDataStore:SetAsync(userId .. "-progress", progressData)
	end)
end

local function showTutorialMessage(player, messageName)
	print("🟢 [SERVER] showTutorialMessage called for: " .. player.Name .. " | Message: " .. messageName)

	local progressData = player:GetAttribute("TutorialProgress")
	if not progressData then 
		warn("🔴 [SERVER] No TutorialProgress attribute for " .. player.Name)
		return 
	end

	local decoded = game:GetService("HttpService"):JSONDecode(progressData)

	-- Skip if already shown
	if decoded.ShownMessages[messageName] then 
		print("🟡 [SERVER] Message already shown: " .. messageName)
		return 
	end

	local data = TUTORIAL_DATA[messageName]
	if data then
		print("🟢 [SERVER] Firing ShowTutorialEvent to " .. player.Name .. " | Message: " .. messageName)
		-- ✅ NO DELAY - ReplicatedFirst always ready
		showTutorialEvent:FireClient(player, messageName, data)
		print("📚 Showed " .. messageName .. " to " .. player.Name)

		-- Mark as shown
		decoded.ShownMessages[messageName] = true
		local encoded = game:GetService("HttpService"):JSONEncode(decoded)
		player:SetAttribute("TutorialProgress", encoded)
		savePlayerProgress(player.UserId, decoded)
	else
		warn("🔴 [SERVER] No tutorial data found for: " .. messageName)
	end
end

-- ✅ Make it globally accessible for ZoneUnlockManager
_G.ShowTutorialMessage = showTutorialMessage

local function markStepComplete(player, stepName)
	local progressData = player:GetAttribute("TutorialProgress")
	if not progressData then return end

	local decoded = game:GetService("HttpService"):JSONDecode(progressData)

	-- Already completed this step
	if decoded.CurrentStep ~= stepName then return end

	table.insert(decoded.CompletedSteps, stepName)

	local nextStep = TutorialArrowConfig:GetNextStep(stepName)

	if nextStep then
		if nextStep.Name == "Paused" then
			decoded.CurrentStep = "Paused"
			print("⏸️ " .. player.Name .. " completed: " .. stepName .. " → Tutorial paused")
		else
			decoded.CurrentStep = nextStep.Name
			print("✓ " .. player.Name .. " completed: " .. stepName .. " → Next: " .. nextStep.DisplayName)

			-- ✅ REPLACE THIS SECTION (around line 145)
			if nextStep.TutorialMessage then
				task.spawn(function()
					task.wait(0.5)
					showTutorialMessage(player, nextStep.TutorialMessage)
				end)
			end
		end
	else
		decoded.CurrentStep = "Completed"
		print("🎉 " .. player.Name .. " completed ALL tutorial steps!")
	end

	local encoded = game:GetService("HttpService"):JSONEncode(decoded)
	player:SetAttribute("TutorialProgress", encoded)
	savePlayerProgress(player.UserId, decoded)

	local currentStepValue = player:FindFirstChild("CurrentArrowStep")
	if currentStepValue then
		currentStepValue. Value = decoded.CurrentStep
	end
end

-- ============================================
-- TUTORIAL MONITORING
-- ============================================

local activeMonitors = {}

local function stopMonitoring(userId)
	if activeMonitors[userId] then
		for _, connection in ipairs(activeMonitors[userId]) do
			if connection.Connected then
				connection:Disconnect()
			end
		end
		activeMonitors[userId] = {}
	end
end

local function monitorPlayerProgress(player, character)
	local humanoidRootPart = character:WaitForChild("HumanoidRootPart")
	local progressData = game:GetService("HttpService"):JSONDecode(player:GetAttribute("TutorialProgress"))

	if progressData.CurrentStep == "Completed" or progressData.CurrentStep == "Paused" then
		return
	end

	local currentStep = TutorialArrowConfig:GetStep(progressData.CurrentStep)
	if not currentStep then return end

	if currentStep.TriggerType == "Manual" then
		print("⏸ Step '" .. currentStep.Name .. "' requires manual trigger")
		return
	end

	local targetPart = TutorialArrowConfig:GetTargetPart(currentStep.Target, currentStep. TargetType)
	if not targetPart then return end

	print("📍 Monitoring location step: " .. currentStep.DisplayName)

	local connection
	connection = RunService.Heartbeat:Connect(function()
		if not humanoidRootPart or not humanoidRootPart.Parent or not player. Parent then
			connection:Disconnect()
			return
		end

		local distance = (humanoidRootPart.Position - targetPart.Position).Magnitude

		if distance <= currentStep.Distance then
			markStepComplete(player, currentStep.Name)
			connection:Disconnect()

			task.wait(0.5)
			monitorPlayerProgress(player, character)
		end
	end)

	if not activeMonitors[player.UserId] then
		activeMonitors[player.UserId] = {}
	end
	table.insert(activeMonitors[player.UserId], connection)
end

-- ============================================
-- PUBLIC FUNCTIONS
-- ============================================

function _G.CompleteTutorialStep(player, stepName)
	if not player or not player.Parent then return false end

	local progressData = player:GetAttribute("TutorialProgress")
	if not progressData then return false end

	local decoded = game:GetService("HttpService"):JSONDecode(progressData)

	if decoded.CurrentStep ~= stepName then
		if decoded.CurrentStep ~= "Completed" then
			warn("Cannot complete step '" .. stepName ..  "' - current step is: " .. decoded.CurrentStep)
		end
		return false
	end

	local stepConfig = TutorialArrowConfig:GetStep(stepName)
	if not stepConfig or stepConfig.TriggerType ~= "Manual" then
		return false
	end

	markStepComplete(player, stepName)

	local character = player. Character
	if character then
		task.wait(0.5)
		monitorPlayerProgress(player, character)
	end

	return true
end

function _G.ResumeTutorialStep(player, stepName)
	if not player or not player.Parent then return false end

	local progressData = player:GetAttribute("TutorialProgress")
	if not progressData then return false end

	local decoded = game:GetService("HttpService"):JSONDecode(progressData)

	if decoded.CurrentStep ~= "Paused" then
		return false
	end

	for _, completed in ipairs(decoded.CompletedSteps) do
		if completed == stepName then
			return false
		end
	end

	local stepConfig = TutorialArrowConfig:GetStep(stepName)
	if not stepConfig then
		return false
	end

	decoded.CurrentStep = stepName
	local encoded = game:GetService("HttpService"):JSONEncode(decoded)
	player:SetAttribute("TutorialProgress", encoded)
	savePlayerProgress(player.UserId, decoded)

	local currentStepValue = player:FindFirstChild("CurrentArrowStep")
	if currentStepValue then
		currentStepValue.Value = stepName
	end

	print("🔄 Resumed tutorial for " .. player.Name ..  " at step: " .. stepName)

	local character = player.Character
	if character then
		task.wait(0.5)
		monitorPlayerProgress(player, character)
	end

	return true
end

-- ============================================
-- TUTORIAL DISMISSAL
-- ============================================

tutorialDismissedEvent.OnServerEvent:Connect(function(player, tutorialName)
	if not tutorialName or tutorialName == "" then return end

	local progressData = player:GetAttribute("TutorialProgress")
	if not progressData then return end

	local decoded = game:GetService("HttpService"):JSONDecode(progressData)
	decoded.ShownMessages[tutorialName] = true
	local encoded = game:GetService("HttpService"):JSONEncode(decoded)
	player:SetAttribute("TutorialProgress", encoded)
	savePlayerProgress(player. UserId, decoded)

	print("📚 " .. player.Name .. " dismissed " .. tutorialName)
end)

-- ============================================
-- PLAYER MANAGEMENT
-- ============================================

local monitoringPlayers = {}

Players.PlayerAdded:Connect(function(player)
	local progressData = loadPlayerProgress(player.UserId)

	local encoded = game:GetService("HttpService"):JSONEncode(progressData)
	player:SetAttribute("TutorialProgress", encoded)

	local currentStepValue = Instance.new("StringValue")
	currentStepValue.Name = "CurrentArrowStep"
	currentStepValue. Value = progressData.CurrentStep
	currentStepValue.Parent = player

	local function getValidCurrentStep(stepName, completedSteps)
		local stepConfig = TutorialArrowConfig:GetStep(stepName)
		if not stepConfig then return "Paused" end

		for _, completed in ipairs(completedSteps) do
			if completed == stepName then
				local nextStepConfig = TutorialArrowConfig: GetNextStep(stepName)
				if not nextStepConfig then 
					return "Paused" 
				elseif nextStepConfig.Name == "Paused" then
					return "Paused"
				else
					return getValidCurrentStep(nextStepConfig.Name, completedSteps)
				end
			end
		end

		if stepConfig.ResumeCondition then
			return "Paused"
		end

		return stepName
	end

	progressData.CurrentStep = getValidCurrentStep(progressData.CurrentStep, progressData.CompletedSteps)
	currentStepValue.Value = progressData.CurrentStep

	local function onCharacterAdded(character)
		task.wait(1)

		if progressData.CurrentStep ~= "Completed" and not monitoringPlayers[player.UserId] then
			monitoringPlayers[player.UserId] = true

			-- ✅ Try to start arrow monitoring (don't let it break messages)
			local success, err = pcall(function()
				monitorPlayerProgress(player, character)
			end)

			if not success then
				warn("⚠️ Arrow monitoring failed: " .. tostring(err))
			end

			-- ✅ ALWAYS show tutorial message (even if arrows failed above)
			local currentStep = TutorialArrowConfig:GetStep(progressData.CurrentStep)
			if currentStep and currentStep.TutorialMessage then
				task.spawn(function()
					task.wait(1.5)
					showTutorialMessage(player, currentStep.TutorialMessage)
				end)
			end
		end
	end


	player.CharacterAdded:Connect(onCharacterAdded)
	if player.Character then
		onCharacterAdded(player.Character)
	end
end)

Players.PlayerRemoving:Connect(function(player)
	stopMonitoring(player.UserId)
	monitoringPlayers[player.UserId] = nil
end)

print("✅ TutorialManager ready - all systems integrated")