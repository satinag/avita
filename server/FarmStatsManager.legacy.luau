-- ServerScriptService/FarmStatsManager
-- Tracks all farm statistics and handles achievements

local Players = game:GetService("Players")
local ServerScriptService = game:GetService("ServerScriptService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local DataStoreModule = require(ServerScriptService:WaitForChild("DataStoreModule"))
local FarmStatsConfig = require(ReplicatedStorage:WaitForChild("FarmStatsConfig"))

print("📊 Farm Stats Manager loaded!")

-- Create RemoteFunction for client queries
local getFarmStatsFunction = Instance.new("RemoteFunction")
getFarmStatsFunction.Name = "GetFarmStatsFunction"
getFarmStatsFunction.Parent = ReplicatedStorage

-- Create RemoteEvent for achievement notifications
local achievementUnlockedEvent = Instance.new("RemoteEvent")
achievementUnlockedEvent.Name = "AchievementUnlockedEvent"
achievementUnlockedEvent.Parent = ReplicatedStorage

-- ============================================
-- STAT TRACKING FUNCTIONS
-- ============================================

local function getPlayerStats(player)
	local data = DataStoreModule.PlayerData[player.UserId]
	if not data or not data.FarmStats then return nil end

	return data.FarmStats
end

function _G.TrackStat(player, statKey, amount)
	local data = DataStoreModule.PlayerData[player.UserId]
	if not data or not data.FarmStats then return end

	-- Increment stat
	if type(data.FarmStats[statKey]) == "number" then
		data.FarmStats[statKey] = data.FarmStats[statKey] + (amount or 1)
		print("📊 " .. player.Name .. " - " .. statKey .. ": " .. data.FarmStats[statKey])
	end

	-- Check achievements after stat update
	task.spawn(function()
		checkAchievements(player)
	end)
end

function _G.TrackCropHarvest(player, cropName, amount)
	local data = DataStoreModule.PlayerData[player.UserId]
	if not data or not data.FarmStats then return end

	-- Track total
	data.FarmStats.TotalCropsHarvested = data.FarmStats.TotalCropsHarvested + amount

	-- Track per crop
	if not data.FarmStats.CropHarvestCounts[cropName] then
		data.FarmStats.CropHarvestCounts[cropName] = 0
	end
	data.FarmStats.CropHarvestCounts[cropName] = data.FarmStats.CropHarvestCounts[cropName] + amount

	-- Track largest single harvest
	if amount > data.FarmStats.LargestSingleHarvest then
		data.FarmStats.LargestSingleHarvest = amount
	end

	print("🌾 " .. player.Name .. " harvested " .. amount .. " " .. cropName .. " (Total: " .. data.FarmStats.TotalCropsHarvested .. ")")

	task.spawn(function()
		checkAchievements(player)
	end)
end

-- ============================================
-- ACHIEVEMENT CHECKING
-- ============================================

function checkAchievements(player)
	local data = DataStoreModule.PlayerData[player.UserId]
	if not data or not data.FarmStats then return end

	for _, achievement in ipairs(FarmStatsConfig.ACHIEVEMENTS) do
		-- Skip if already unlocked
		if data.FarmStats.Achievements[achievement.ID] then continue end

		local unlocked = false

		-- Check requirement
		if achievement.StatKey == "AnimalsOwned" then
			-- Count owned animals
			local count = 0
			local poultryOwned = player:FindFirstChild("PoultryOwned")
			if poultryOwned then
				for _, animal in ipairs(poultryOwned:GetChildren()) do
					if animal:IsA("BoolValue") and animal.Value then
						count = count + 1
					end
				end
			end
			unlocked = (count >= achievement.Requirement)

		elseif achievement.StatKey == "BeehivesOwned" then
			local beehiveCount = player:FindFirstChild("BeehiveCount")
			unlocked = (beehiveCount and beehiveCount.Value >= achievement.Requirement)

		elseif achievement.StatKey == "PlotsOwned" then
			-- Count owned plots
			local count = 0
			local ownedPlots = player:FindFirstChild("OwnedPlots")
			if ownedPlots then
				for _, plotValue in ipairs(ownedPlots:GetChildren()) do
					if plotValue:IsA("StringValue") and plotValue.Value == player.Name then
						count = count + 1
					end
				end
			end
			unlocked = (count >= achievement.Requirement)

		else
			-- Standard stat check
			local statValue = data.FarmStats[achievement.StatKey] or 0
			unlocked = (statValue >= achievement.Requirement)
		end

		-- Unlock achievement
		if unlocked then
			data.FarmStats.Achievements[achievement.ID] = true
			print("🏆 " .. player.Name .. " unlocked: " .. achievement.Name)

			-- Notify client
			achievementUnlockedEvent:FireClient(player, achievement)
		end
	end
end

-- ============================================
-- CLIENT QUERIES
-- ============================================

getFarmStatsFunction.OnServerInvoke = function(player)
	local stats = getPlayerStats(player)
	if not stats then return nil end

	-- Calculate additional stats on the fly
	local response = {
		-- Overview
		DaysPlayed = stats.DaysPlayed,
		PrestigeLevel = stats.PrestigeLevel,
		TotalCashEarned = stats.TotalCashEarned,
		TotalCashSpent = stats.TotalCashSpent,
		CurrentCash = player.leaderstats and player.leaderstats.Cash and player.leaderstats.Cash.Value or 0,

		-- Crops
		TotalCropsHarvested = stats.TotalCropsHarvested,
		CropHarvestCounts = stats.CropHarvestCounts,
		TotalCropsSold = stats.TotalCropsSold,
		LargestSingleHarvest = stats.LargestSingleHarvest,

		-- Animals
		TotalAnimalsOwned = stats.TotalAnimalsOwned,
		TotalEggsCollected = stats.TotalEggsCollected,
		TotalMilkCollected = stats.TotalMilkCollected,
		TotalMeatCollected = stats.TotalMeatCollected,
		TotalWoolCollected = stats.TotalWoolCollected,
		TotalHoneyCollected = stats.TotalHoneyCollected,

		-- Economy
		MoneySpentOnPlots = stats.MoneySpentOnPlots,
		MoneySpentOnTools = stats.MoneySpentOnTools,
		MoneySpentOnSeeds = stats.MoneySpentOnSeeds,
		MoneySpentOnAnimals = stats.MoneySpentOnAnimals,
		NetProfit = stats.TotalCashEarned - stats.TotalCashSpent,

		-- Achievements
		Achievements = stats.Achievements,
	}

	-- Find favorite crop (most harvested)
	local favoriteCrop = "None"
	local maxCount = 0
	for cropName, count in pairs(stats.CropHarvestCounts) do
		if count > maxCount then
			maxCount = count
			favoriteCrop = cropName
		end
	end
	response.FavoriteCrop = favoriteCrop

	return response
end

-- ============================================
-- INITIALIZATION
-- ============================================

Players.PlayerAdded:Connect(function(player)
	-- Wait for data to load
	task.wait(2)

	-- Initial achievement check
	checkAchievements(player)
end)

print("📊 Farm Stats Manager ready!")
