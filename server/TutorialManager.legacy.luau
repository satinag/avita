-- ServerScriptService/TutorialManager
-- UPDATED to work with TutorialLevelConfig system
-- Complete file - replace entire content

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local DataStoreService = game:GetService("DataStoreService")
local RunService = game:GetService("RunService")
local HttpService = game:GetService("HttpService")

local TutorialLevelConfig = require(ReplicatedStorage:WaitForChild("TutorialLevelConfig"))
--local TutorialDataStore = DataStoreService:GetDataStore("TutorialProgress_v3.18.3.1")
local TutorialDataStore = DataStoreService:GetDataStore("TutorialProgress_v18.0.2") --PUBLISH VERSION

-- Create RemoteEvents
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
-- TUTORIAL DATA (Popup Messages)
-- ============================================
local TUTORIAL_DATA = {
	Welcome = {
		Title = "🌾 Welcome to Your Farm!",
		Message = "Follow the yellow arrow to the Seed Shop.\nBuy seeds to start farming!",
		Duration = 8
	},
	PlantingTutorial = {
		Title = "🌱 Time to Plant!",
		Message = "Follow the arrow to your plot.\nClaim it, then plant your seeds!",
		Duration = 6
	},
	FirstHarvest = {
		Title = "🎉 Ready to Harvest!",
		Message = "Your crop is ready! Click it to harvest.\nThen follow the arrow to the Barn to sell!",
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
		Title = "🏆 Expansion Zone 3 Unlocked!",
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
	},
	HouseUpgrade = {
		Title = "Upgrade Your House!",
		Message = "Earn enough money and you can always go the Postal Box for upgrading your house",
		Duration = 7
	},
	FishingRodUnlock = {
		Title = "🎣 Fishing Unlocked!",
		Message = "You can now fish at the pond!\nCatch fish and sell them for profit!",
		Duration = 7
	}

}

-- ============================================
-- HELPER FUNCTIONS
-- ============================================

local function loadPlayerProgress(userId)
	local success, data = pcall(function()
		return TutorialDataStore:GetAsync(userId .. "-progress")
	end)

	if success and data then
		return data
	else
		-- Return default data with LEVEL-BASED system
		return {
			CurrentLevel = 1,  -- Start at level 1
			CompletedLevels = {},
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
	if not messageName then return end

	print("🟢 [SERVER] showTutorialMessage called for: " .. player.Name .. " | Message: " .. messageName)

	local progressData = player:GetAttribute("TutorialProgress")
	if not progressData then 
		warn("🔴 [SERVER] No TutorialProgress attribute for " .. player.Name)
		return 
	end

	local decoded = HttpService:JSONDecode(progressData)

	-- Skip if already shown
	if decoded.ShownMessages[messageName] then 
		print("🟡 [SERVER] Message already shown: " .. messageName)
		return 
	end

	local data = TUTORIAL_DATA[messageName]
	if data then
		print("🟢 [SERVER] Firing ShowTutorialEvent to " .. player.Name .. " | Message: " .. messageName)
		showTutorialEvent:FireClient(player, messageName, data)
		print("📚 Showed " .. messageName .. " to " .. player.Name)

		-- Mark as shown
		decoded.ShownMessages[messageName] = true
		local encoded = HttpService:JSONEncode(decoded)
		player:SetAttribute("TutorialProgress", encoded)
		savePlayerProgress(player.UserId, decoded)
	else
		warn("🔴 [SERVER] No tutorial data found for: " .. messageName)
	end
end

-- Make globally accessible
_G.ShowTutorialMessage = showTutorialMessage

local function completeTutorialLevel(player, levelNumber)
	local progressData = player:GetAttribute("TutorialProgress")
	if not progressData then return end

	local decoded = HttpService:JSONDecode(progressData)

	-- Check if we're on this level
	if decoded.CurrentLevel ~= levelNumber then 
		print("⚠️ Cannot complete level " .. levelNumber .. " - current level is " .. decoded.CurrentLevel)
		return 
	end

	-- Mark level as completed
	table.insert(decoded.CompletedLevels, levelNumber)

	-- Get next level
	local nextLevelConfig = TutorialLevelConfig:GetNextLevel(levelNumber)

	if nextLevelConfig then
		-- Check if next level is an UnlockTrigger - if so, STOP auto-advancing
		if nextLevelConfig.TriggerType == "UnlockTrigger" then
			decoded.CurrentLevel = 999  -- Pause tutorial progression
			print("⏸️ " .. player.Name .. " completed level " .. levelNumber .. " → Paused (next level requires unlock trigger)")
		else
			decoded.CurrentLevel = levelNumber + 1
			print("✓ " .. player.Name .. " completed level " .. levelNumber .. " → Next: " .. nextLevelConfig.DisplayName)

			-- Show message for next level if it has one
			if nextLevelConfig.MessageToShow then
				task.spawn(function()
					task.wait(0.5)
					showTutorialMessage(player, nextLevelConfig.MessageToShow)
				end)
			end
		end
	else
		-- All tutorials complete
		decoded.CurrentLevel = 999
		print("🎉 " .. player.Name .. " completed ALL tutorials!")
	end


	-- Save progress
	local encoded = HttpService:JSONEncode(decoded)
	player:SetAttribute("TutorialProgress", encoded)
	savePlayerProgress(player.UserId, decoded)

	-- Update arrow level
	local currentLevelValue = player:FindFirstChild("CurrentArrowLevel")
	if currentLevelValue then
		currentLevelValue.Value = decoded.CurrentLevel
	end
end

-- ============================================
-- TUTORIAL MONITORING
-- ============================================

local activeMonitors = {}

local function stopMonitoring(userId)
	if activeMonitors[userId] then
		for _, connection in ipairs(activeMonitors[userId]) do
			if connection and connection.Connected then
				connection:Disconnect()
			end
		end
		activeMonitors[userId] = {}
	end
end

local function monitorPlayerProgress(player, character)
	local humanoidRootPart = character:WaitForChild("HumanoidRootPart", 5)
	if not humanoidRootPart then return end

	local progressData = HttpService:JSONDecode(player:GetAttribute("TutorialProgress"))

	if progressData.CurrentLevel >= 999 then
		print("✅ Tutorial completed, no monitoring needed")
		return
	end

	-- Get current level config
	local currentLevelConfig = TutorialLevelConfig:GetLevel(progressData.CurrentLevel)
	if not currentLevelConfig then 
		warn("⚠️ No config found for level " .. progressData.CurrentLevel)
		return 
	end

	-- Only monitor Location-based triggers
	if currentLevelConfig.TriggerType ~= "Location" then
		print("⏸ Level " .. progressData.CurrentLevel .. " requires manual trigger")
		return
	end

	-- Resolve target
	local targetObject = TutorialLevelConfig:ResolvePathToTarget(currentLevelConfig.TargetPath)
	local targetPart = TutorialLevelConfig:GetRenderablePart(targetObject)

	if not targetPart then 
		warn("⚠️ Could not find target for level " .. progressData.CurrentLevel)
		return 
	end

	print("📍 Monitoring location for level " .. progressData.CurrentLevel .. ": " .. currentLevelConfig.DisplayName)

	local connection
	connection = RunService.Heartbeat:Connect(function()
		if not humanoidRootPart or not humanoidRootPart.Parent or not player.Parent then
			if connection then connection:Disconnect() end
			return
		end

		local distance = (humanoidRootPart.Position - targetPart.Position).Magnitude

		if distance <= currentLevelConfig.Distance then
			completeTutorialLevel(player, progressData.CurrentLevel)
			if connection then connection:Disconnect() end

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

function _G.CompleteTutorialLevel(player, levelNumber)
	if not player or not player.Parent then return false end

	local progressData = player:GetAttribute("TutorialProgress")
	if not progressData then return false end

	local decoded = HttpService:JSONDecode(progressData)

	if decoded.CurrentLevel ~= levelNumber then
		if decoded.CurrentLevel < 999 then
			warn("Cannot complete level " .. levelNumber .. " - current level is: " .. decoded.CurrentLevel)
		end
		return false
	end

	local levelConfig = TutorialLevelConfig:GetLevel(levelNumber)
	if not levelConfig then
		warn("Level " .. levelNumber .. " not found in config")
		return false
	end

	-- ✅ ALLOW BOTH Manual AND UnlockTrigger types to be manually completed
	if levelConfig.TriggerType ~= "Manual" and levelConfig.TriggerType ~= "UnlockTrigger" then
		warn("Level " .. levelNumber .. " cannot be manually completed (type: " .. levelConfig.TriggerType .. ")")
		return false
	end

	completeTutorialLevel(player, levelNumber)

	local character = player.Character
	if character then
		task.wait(0.5)
		monitorPlayerProgress(player, character)
	end

	return true
end


function _G.ActivateTutorialLevel(player, levelNumber)
	if not player or not player.Parent then return false end

	local progressData = player:GetAttribute("TutorialProgress")
	if not progressData then return false end

	local decoded = HttpService:JSONDecode(progressData)

	-- Check if level already completed
	for _, completed in ipairs(decoded.CompletedLevels) do
		if completed == levelNumber then
			return false
		end
	end

	local levelConfig = TutorialLevelConfig:GetLevel(levelNumber)
	if not levelConfig or levelConfig.TriggerType ~= "UnlockTrigger" then
		warn("Level " .. levelNumber .. " is not an unlock trigger level")
		return false
	end

	-- Activate this level
	decoded.CurrentLevel = levelNumber
	local encoded = HttpService:JSONEncode(decoded)
	player:SetAttribute("TutorialProgress", encoded)
	savePlayerProgress(player.UserId, decoded)

	local currentLevelValue = player:FindFirstChild("CurrentArrowLevel")
	if currentLevelValue then
		currentLevelValue.Value = levelNumber
	end

	print("🔄 Activated tutorial level " .. levelNumber .. " for " .. player.Name)

	-- Show message if exists
	if levelConfig.MessageToShow then
		task.spawn(function()
			task.wait(0.5)
			showTutorialMessage(player, levelConfig.MessageToShow)
		end)
	end

	-- Start monitoring
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

	local decoded = HttpService:JSONDecode(progressData)
	decoded.ShownMessages[tutorialName] = true
	local encoded = HttpService:JSONEncode(decoded)
	player:SetAttribute("TutorialProgress", encoded)
	savePlayerProgress(player.UserId, decoded)

	print("📚 " .. player.Name .. " dismissed " .. tutorialName)
end)

-- ============================================
-- PLAYER MANAGEMENT
-- ============================================

local monitoringPlayers = {}

Players.PlayerAdded:Connect(function(player)
	local progressData = loadPlayerProgress(player.UserId)

	local encoded = HttpService:JSONEncode(progressData)
	player:SetAttribute("TutorialProgress", encoded)

	-- Create CurrentArrowLevel IntValue (used by client)
	local currentLevelValue = Instance.new("IntValue")
	currentLevelValue.Name = "CurrentArrowLevel"
	currentLevelValue.Value = progressData.CurrentLevel
	currentLevelValue.Parent = player

	print("📚 " .. player.Name .. " loaded at tutorial level: " .. progressData.CurrentLevel)

	local function onCharacterAdded(character)
		task.wait(1)

		if progressData.CurrentLevel < 999 and not monitoringPlayers[player.UserId] then
			monitoringPlayers[player.UserId] = true

			-- Start monitoring with error handling
			local success, err = pcall(function()
				monitorPlayerProgress(player, character)
			end)

			if not success then
				warn("⚠️ Arrow monitoring failed: " .. tostring(err))
			end

			-- Show tutorial message
			local currentLevelConfig = TutorialLevelConfig:GetLevel(progressData.CurrentLevel)
			if currentLevelConfig and currentLevelConfig.MessageToShow then
				task.spawn(function()
					task.wait(1.5)
					showTutorialMessage(player, currentLevelConfig.MessageToShow)
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

print("✅ TutorialManager ready - Level-based system active")
