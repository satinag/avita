-- TownTutorialManager.lua (COMPLETE - FIXED VERSION)
-- Manages tutorial system with player progress tracking
-- Location: ServerScriptService (Town place)

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local DataStoreService = game:GetService("DataStoreService")

local TutorialDataStore = DataStoreService:GetDataStore("TownTutorials_v1")
local TownTutorialConfig = require(ReplicatedStorage:WaitForChild("TownTutorialConfig"))

-- Track which tutorials each player has seen
local playerTutorialProgress = {}

-- ============================================
-- CREATE REMOTE EVENTS
-- ============================================
local ShowTutorialEvent = Instance.new("RemoteEvent")
ShowTutorialEvent.Name = "ShowTutorialEvent"
ShowTutorialEvent.Parent = ReplicatedStorage

local TutorialSeenEvent = Instance.new("RemoteEvent")
TutorialSeenEvent.Name = "TutorialSeenEvent"
TutorialSeenEvent.Parent = ReplicatedStorage

-- ============================================
-- UTILITY FUNCTIONS
-- ============================================
local function loadTutorialProgress(player)
	local key = "Player_" .. player.UserId
	local success, data = pcall(function()
		return TutorialDataStore:GetAsync(key)
	end)

	if success and data then
		playerTutorialProgress[player.UserId] = data
		print("✅ Loaded tutorial progress for " .. player.Name)
	else
		playerTutorialProgress[player.UserId] = {}
		print("🆕 New player tutorial progress: " .. player.Name)
	end
end

local function saveTutorialProgress(player)
	local key = "Player_" .. player.UserId
	local data = playerTutorialProgress[player.UserId]
	if not data then return end

	pcall(function()
		TutorialDataStore:SetAsync(key, data)
	end)
end

local function hasSeenTutorial(player, tutorialId)
	local progress = playerTutorialProgress[player.UserId]
	return progress and progress[tutorialId] == true
end

local function markTutorialSeen(player, tutorialId)
	local progress = playerTutorialProgress[player.UserId]
	if progress then
		progress[tutorialId] = true
		saveTutorialProgress(player)
		print("📖 " .. player.Name .. " saw: " .. tutorialId)
	end
end

-- ============================================
-- SHOW TUTORIAL
-- ============================================
local function showTutorial(player, tutorialId)
	local tutorial = TownTutorialConfig.GetTutorial(tutorialId)
	if not tutorial then
		warn("❌ Tutorial not found: " .. tostring(tutorialId))
		return
	end

	if tutorial.ShowOnce and hasSeenTutorial(player, tutorialId) then
		return
	end

	ShowTutorialEvent:FireClient(player, tutorialId, {
		Title = tutorial.Title,
		Message = tutorial.Message,
		Duration = tutorial.Duration
	})

	-- Mark seen
	markTutorialSeen(player, tutorialId)
end

-- ============================================
-- SIMPLIFIED TARGET FINDER (No PrimaryPart needed)
-- ============================================
local function findInstanceByPath(pathString)
	local parts = {}
	local pos = 1
	while pos <= #pathString do
		local nextDot = pathString:find("%.", pos)
		if not nextDot then
			table.insert(parts, pathString:sub(pos))
			break
		end
		table.insert(parts, pathString:sub(pos, nextDot - 1))
		pos = nextDot + 1
	end

	local current = game
	for _, partName in ipairs(parts) do
		local name, indexStr = partName:match("(.+)%((%d+)%)$")
		if name and indexStr then
			local index = tonumber(indexStr)
			local children = current:GetChildren()
			if index and index <= #children then
				current = children[index]
			else
				return nil
			end
		else
			current = current:WaitForChild(partName, 5)
			if not current then return nil end
		end
	end
	return current
end

local function findTutorialTarget(targetObject)
	-- SHOP NAMES: Find ProximityPrompt parent anywhere under Town.ShopName
	if targetObject:match("^[A-Za-z]+$") then
		local town = workspace:FindFirstChild("Town")
		if town then
			local shop = town:FindFirstChild(targetObject, true)  -- Recursive!
			if shop then
				-- Return FIRST ProximityPrompt's parent (Door, Handle, etc.)
				for _, prompt in ipairs(shop:GetDescendants()) do
					if prompt:IsA("ProximityPrompt") then
						return prompt.Parent
					end
				end
			end
		end
		return nil
	end

	-- FULL PATHS: Workspace.FarmPortal
	return findInstanceByPath(targetObject)
end

-- ============================================
-- SETUP PROXIMITY TUTORIALS
-- ============================================
local function setupProximityTutorials()
	local proximityTutorials = TownTutorialConfig.GetProximityTutorials()
	print("🔍 Setting up " .. #proximityTutorials .. " proximity tutorials...")

	for _, tutorial in ipairs(proximityTutorials) do
		local target = findTutorialTarget(tutorial.TargetObject)

		if target then
			local prompt = target:FindFirstChildOfClass("ProximityPrompt", true)

			if prompt then
				prompt.PromptShown:Connect(function(player)
					task.wait(0.5)
					showTutorial(player, tutorial.ID)
				end)

				print("✅ " .. tutorial.ID .. " → " .. target:GetFullName())
			else
				warn("⚠️ No ProximityPrompt under: " .. target:GetFullName())
			end
		else
			warn("⚠️ Target FAILED: " .. tutorial.TargetObject)
		end
	end
end

-- ============================================
-- PLAYER EVENTS
-- ============================================
Players.PlayerAdded:Connect(function(player)
	loadTutorialProgress(player)

	player.CharacterAdded:Connect(function()
		task.wait(2)
		showTutorial(player, "Welcome")
	end)
end)

Players.PlayerRemoving:Connect(function(player)
	saveTutorialProgress(player)
	playerTutorialProgress[player.UserId] = nil
end)

TutorialSeenEvent.OnServerEvent:Connect(function(player, tutorialId)
	showTutorial(player, tutorialId)
end)

-- ============================================
-- INITIALIZE
-- ============================================
task.wait(3)
setupProximityTutorials()
print("✅ TownTutorialManager LOADED")

-- ============================================
-- TIMER TUTORIALS (ReturnReminder, etc.)
-- ============================================
spawn(function()
	local timerTutorials = TownTutorialConfig.GetTutorialsByTrigger("Timer")
	for _, tutorial in ipairs(timerTutorials) do
		task.wait(tutorial.TriggerAfter or 60)
		for _, player in ipairs(Players:GetPlayers()) do
			showTutorial(player, tutorial.ID)
		end
	end
end)
