-- CashSystem: Creates player data structure and integrates with DataStore
local Players = game:GetService("Players")
local ServerScriptService = game:GetService("ServerScriptService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
-- Load DataStore module
local DataStoreModule = require(ServerScriptService:WaitForChild("DataStoreModule"))

-- Auto-save interval (3 minutes)
local AUTO_SAVE_INTERVAL = 180

-- Seed data (needed for offline growth calculation) - UPDATED WITH NEW SEEDS
local SEEDS = {
	Wheat = {GrowTime = 10, Model = "WheatModel", MatureModel = "WheatMature"},
	Corn = {GrowTime = 20, Model = "CornModel", MatureModel = "CornMature"},
	Carrot = {GrowTime = 30, Model = "CarrotModel", MatureModel = "CarrotMature"},
	Potato = {GrowTime = 40, Model = "PotatoModel", MatureModel = "PotatoMature"},
	Tomato = {GrowTime = 50, Model = "TomatoModel", MatureModel = "TomatoMature"},
	Pumpkin = {GrowTime = 60, Model = "PumpkinModel", MatureModel = "PumpkinMature"},
	Strawberry = {GrowTime = 70, Model = "StrawberryModel", MatureModel = "StrawberryMature"},
	Watermelon = {GrowTime = 80, Model = "WatermelonModel", MatureModel = "WatermelonMature"}
}

-- Create player data structure from loaded data
local function setupPlayerData(player, data)
	-- Create leaderstats folder
	local leaderstats = Instance.new("Folder")
	leaderstats.Name = "leaderstats"
	leaderstats.Parent = player

	-- Create Cash value
	local cash = Instance.new("IntValue")
	cash.Name = "Cash"
	cash.Value = data.Cash
	cash.Parent = leaderstats

	-- Track total earned (for unlocks)
	local totalEarned = Instance.new("IntValue")
	totalEarned.Name = "TotalEarned"
	totalEarned.Value = data.TotalEarned
	totalEarned.Parent = player

	-- Seed inventory folder
	local seedInventory = Instance.new("Folder")
	seedInventory.Name = "SeedInventory"
	seedInventory.Parent = player

	for seedName, count in pairs(data.Seeds) do
		local seedValue = Instance.new("IntValue")
		seedValue.Name = seedName
		seedValue.Value = count
		seedValue.Parent = seedInventory
	end

	-- Crop inventory folder
	local cropInventory = Instance.new("Folder")
	cropInventory.Name = "CropInventory"
	cropInventory.Parent = player

	for cropName, count in pairs(data.Crops) do
		local cropValue = Instance.new("IntValue")
		cropValue.Name = cropName
		cropValue.Value = count
		cropValue.Parent = cropInventory
	end

	-- Tutorial tracking
	local hasVisitedBarn = Instance.new("BoolValue")
	hasVisitedBarn.Name = "HasVisitedBarn"
	hasVisitedBarn.Value = data.HasVisitedBarn
	hasVisitedBarn.Parent = player

	local lastHarvestHint = Instance.new("NumberValue")
	lastHarvestHint.Name = "LastHarvestHint"
	lastHarvestHint.Value = data.LastHarvestHint
	lastHarvestHint.Parent = player


	-- Tool ownership tracking
	local toolsOwned = Instance.new("Folder")
	toolsOwned.Name = "ToolsOwned"
	toolsOwned.Parent = player

	-- ✅ NEW (NO SPACES - MATCH PRODUCTCONFIG):
	local improvedShovel = Instance.new("BoolValue")
	improvedShovel.Name = "ImprovedShovel"  -- ✅ No space
	improvedShovel.Value = data.Tools.ImprovedShovel
	improvedShovel.Parent = toolsOwned

	local wateringCan = Instance.new("BoolValue")
	wateringCan.Name = "WateringCan"  -- ✅ No space
	wateringCan.Value = data.Tools.WateringCan
	wateringCan.Parent = toolsOwned

	local fishingRod = Instance.new("BoolValue")
	fishingRod.Name = "FishingRod"  -- ✅ Already correct
	fishingRod.Value = data.Tools.FishingRod or false
	fishingRod.Parent = toolsOwned

	
	-- ============================================
	-- ANIMAL INVENTORY (replaces PoultryOwned)
	-- ============================================
	-- ✅ Animals inventory folder (IntValue - for marketplace)
	local animalInventory = Instance.new("Folder")
	animalInventory.Name = "AnimalInventory"
	animalInventory.Parent = player

	for animalName, count in pairs(data.Animals or {}) do
		local animalValue = Instance.new("IntValue")
		animalValue.Name = animalName
		animalValue.Value = count
		animalValue.Parent = animalInventory
	end

	-- ✅ Products inventory folder (IntValue - for marketplace)
	local productInventory = Instance.new("Folder")
	productInventory.Name = "ProductInventory"
	productInventory.Parent = player

	for productName, count in pairs(data.Products or {}) do
		local productValue = Instance.new("IntValue")
		productValue.Name = productName
		productValue.Value = count
		productValue.Parent = productInventory
	end

	-- ✅ Fish inventory folder (IntValue - for marketplace)
	local fishInventory = Instance.new("Folder")
	fishInventory.Name = "FishInventory"
	fishInventory.Parent = player

	for fishName, count in pairs(data.Fish or {}) do
		local fishValue = Instance.new("IntValue")
		fishValue.Name = fishName
		fishValue.Value = count
		fishValue.Parent = fishInventory
	end

	-- Restore passive income flags
	if data.PassiveIncome then
		for animalName, enabled in pairs(data.PassiveIncome) do
			player:SetAttribute("Passive_" .. animalName, enabled)
		end
	end

	-- Restore animal cooldowns
	if data.PoultryCooldowns then
		for animalName, timestamp in pairs(data.PoultryCooldowns) do
			player:SetAttribute("AnimalLastCollect_" .. animalName, timestamp)
		end
	end

	-- Restore fishing cooldown (NEW)
	if data.FishingCooldown then
		player:SetAttribute("LastFishTime", data.FishingCooldown)
	end

	-- Beehive tracking
	local beehiveCount = Instance.new("IntValue")
	beehiveCount.Name = "BeehiveCount"
	beehiveCount.Value = data.Beehives and data.Beehives.Count or 0
	beehiveCount.Parent = player

	print("🐝 " .. player.Name .. " loaded with " .. beehiveCount.Value .. " beehives")

	-- ✅ Restore unified hive cooldowns (NO LOOP - just restore once)
	if data.HiveLastCollect_Honey then
		player:SetAttribute("HiveLastCollect_Honey", data.HiveLastCollect_Honey)
	else
		player:SetAttribute("HiveLastCollect_Honey", 0)
	end

	if data.HiveLastCollect_Wax then
		player:SetAttribute("HiveLastCollect_Wax", data.HiveLastCollect_Wax)
	else
		player:SetAttribute("HiveLastCollect_Wax", 0)
	end


	print("🐝 " .. player.Name .. " loaded with " .. beehiveCount.Value .. " beehives")


	-- NEW: Create upgraded tool BoolValues
	local upgradedWateringCan = Instance.new("BoolValue")
	upgradedWateringCan.Name = "UpgradedWateringCan"
	upgradedWateringCan.Value = data.Tools.UpgradedWateringCan
	upgradedWateringCan.Parent = toolsOwned

	local upgradedShovel = Instance.new("BoolValue")
	upgradedShovel.Name = "UpgradedShovel"
	upgradedShovel.Value = data.Tools.UpgradedShovel
	upgradedShovel.Parent = toolsOwned

	-- Tutorial progress folder
	local tutorialProgress = Instance.new("Folder")
	tutorialProgress.Name = "TutorialProgress"
	tutorialProgress.Parent = player

	for tutName, seen in pairs(data.Tutorials) do
		local tutValue = Instance.new("BoolValue")
		tutValue.Name = tutName
		tutValue.Value = seen
		tutValue.Parent = tutorialProgress
	end

	-- 🎯 NEW: SeedsUnlocked progression counter
	local seedsUnlocked = Instance.new("IntValue")
	seedsUnlocked.Name = "SeedsUnlocked"
	seedsUnlocked.Value = data.SeedsUnlocked or 0
	seedsUnlocked.Parent = player

	-- Plot ownership tracking folder
	local ownedPlots = Instance.new("Folder")
	ownedPlots.Name = "OwnedPlots"
	ownedPlots.Parent = player

	-- Create StringValues for each plot
	for plotName, plotData in pairs(data.Plots) do
		local plotValue = Instance.new("StringValue")
		plotValue.Name = plotName
		plotValue.Value = plotData.Owner or ""
		plotValue.Parent = ownedPlots

		-- Also store the current seed
		local seedValue = Instance.new("StringValue")
		seedValue.Name = plotName .. "_Seed"
		seedValue.Value = plotData.CurrentSeed or ""
		seedValue.Parent = ownedPlots

		-- Store plant timestamp
		local plantTime = Instance.new("NumberValue")
		plantTime.Name = plotName .. "_PlantTime"
		plantTime.Value = plotData.PlantTime or 0
		plantTime.Parent = ownedPlots
	end

	-- Restore plot ownership (with proper delay and error checking)
	task.spawn(function()
		-- Wait longer to ensure plots are fully loaded
		task.wait(3)
		print("🔧 Starting plot restoration for " .. player.Name)

		for plotName, plotData in pairs(data.Plots) do
			-- Only restore if this player owns the plot
			if plotData.Owner == player.Name then
				local plot = nil

				-- Check StartingZone first (Plot1-4)
				local startingZone = workspace:FindFirstChild("StartingZone")
				if startingZone then
					plot = startingZone:FindFirstChild(plotName)
				end

				-- If not found, check ExpansionZone1 (Plot5-8)
				if not plot then
					local zone = workspace:FindFirstChild("ExpansionZone1")
					if zone then
						plot = zone:FindFirstChild(plotName)
					end
				end

				-- If still not found, check ExpansionZone2 (Plot9-12)
				if not plot then
					local zone2 = workspace:FindFirstChild("ExpansionZone2")
					if zone2 then
						plot = zone2:FindFirstChild(plotName)
					end
				end
				
				-- If still not found, check ExpansionZone3 (Plot13-16)
				if not plot then
					local zone3 = workspace:FindFirstChild("ExpansionZone3")
					if zone3 then
						plot = zone3:FindFirstChild(plotName)
					end
				end

				if plot then
					-- Set ownership attributes
					plot:SetAttribute("Owner", plotData.Owner)
					plot:SetAttribute("CurrentSeed", plotData.CurrentSeed)
					plot:SetAttribute("PlantTime", plotData.PlantTime or 0)

					-- Update prompt text
					local prompt = plot:FindFirstChild("ProximityPrompt")
					if prompt then
						if plotData.CurrentSeed and plotData.PlantTime and plotData.PlantTime > 0 then
							-- Calculate if crop should be ready
							local currentTime = os.time()
							local timeElapsed = currentTime - plotData.PlantTime

							local seedInfo = SEEDS[plotData.CurrentSeed]
							if seedInfo then
								local growTime = seedInfo.GrowTime

								-- Check if player owns Watering Can
								if wateringCan.Value then
									growTime = growTime * 0.8
								end

								if timeElapsed >= growTime then
									-- Crop is ready to harvest!
									plot:SetAttribute("CanHarvest", true)
									plot:SetAttribute("IsGrowing", false)
									prompt.ActionText = "Harvest " .. plotData.CurrentSeed

									-- Spawn mature crop model
									local matureModel = ReplicatedStorage:FindFirstChild(seedInfo.MatureModel)
									if matureModel then
										local matureCrop = matureModel:Clone()
										matureCrop.Name = "Crop"
										matureCrop.Parent = plot

										local landPart = plot:FindFirstChild("Land")
										if landPart then
											local exactGroundY = landPart.Position.Y + (landPart.Size.Y / 2)
											local targetPos = Vector3.new(landPart.Position.X, exactGroundY + 2, landPart.Position.Z)

											if matureCrop:IsA("Model") then
												if not matureCrop.PrimaryPart then
													matureCrop.PrimaryPart = matureCrop:FindFirstChildWhichIsA("BasePart")
												end
												if matureCrop.PrimaryPart then
													matureCrop:SetPrimaryPartCFrame(CFrame.new(targetPos))
												end
												for _, part in pairs(matureCrop:GetDescendants()) do
													if part:IsA("BasePart") then
														part.Anchored = true
														part.CanCollide = false
													end
												end
											else
												matureCrop.CFrame = CFrame.new(targetPos)
												matureCrop.Anchored = true
												matureCrop.CanCollide = false
											end
										end
									end

									print("🌾 " .. plotName .. " grew while offline - ready to harvest!")
								else
									-- Still growing
									local remainingTime = math.ceil(growTime - timeElapsed)
									prompt.ActionText = "Growing... (" .. remainingTime .. "s left)"
									plot:SetAttribute("IsGrowing", true)

									-- Spawn growing crop model
									local growingModel = ReplicatedStorage:FindFirstChild(seedInfo.Model)
									if growingModel then
										local crop = growingModel:Clone()
										crop.Name = "Crop"
										crop.Parent = plot

										local landPart = plot:FindFirstChild("Land")
										if landPart then
											local exactGroundY = landPart.Position.Y + (landPart.Size.Y / 2)
											local targetPos = Vector3.new(landPart.Position.X, exactGroundY + 2, landPart.Position.Z)

											if crop:IsA("Model") then
												if not crop.PrimaryPart then
													crop.PrimaryPart = crop:FindFirstChildWhichIsA("BasePart")
												end
												if crop.PrimaryPart then
													crop:SetPrimaryPartCFrame(CFrame.new(targetPos))
												end
												for _, part in pairs(crop:GetDescendants()) do
													if part:IsA("BasePart") then
														part.Anchored = true
														part.CanCollide = false
													end
												end
											else
												crop.CFrame = CFrame.new(targetPos)
												crop.Anchored = true
												crop.CanCollide = false
											end
										end
									end

									print("🌱 " .. plotName .. " still growing - " .. remainingTime .. "s remaining")
								end
							end
						else
							prompt.ActionText = "Select Seed to Plant"
						end
					end

				else
					warn("⚠️ Could not find " .. plotName .. " in workspace to restore ownership")
				end
			end
		end

		print("🏠 Plot restoration complete for " .. player.Name)
	end)

	print("✅ " .. player.Name .. " joined with " .. data.Cash .. " cash, loaded from DataStore")
end

-- Player joined
Players.PlayerAdded:Connect(function(player)
	-- Load data from DataStore
	local data = DataStoreModule:LoadData(player)

	if not data then
		-- Player was kicked due to session lock
		return
	end

	-- Store data in memory
	DataStoreModule.PlayerData[player.UserId] = data

	-- ✅ ADD THIS RIGHT HERE (before offline calculations)
	if not data.LastLogout then
		-- NEW PLAYER - initialize timestamps to prevent epoch bug
		data.LastSaveTime = os.time()
		data.LastLogout = os.time()
	end

	-- Require DailyQuestManager here
	require(game:GetService("ServerScriptService"):WaitForChild("DailyQuestManager"))

	-- Offline earnings calculation
	local offlineEarnings = 0
	local offlineCrops = 0
	local currentTime = os.time()
	local totalOfflineSeconds = currentTime - (data.LastLogout or currentTime)
	local offlineMinutes = math.floor(totalOfflineSeconds / 60)
	local offlineHours = math.floor(totalOfflineSeconds / 3600)

	-- Poultry passive income (only if passive enabled)
	if data.PassiveIncome then
		for poultryName, enabled in pairs(data.PassiveIncome) do
			if enabled then
				local rates = {Chicken=20/60, Cow=50/60, Pig=35/60}  -- Per minute rates
				offlineEarnings = offlineEarnings + (rates[poultryName] or 0) * offlineMinutes
			end
		end
	end

	-- Round earnings to cents
	offlineEarnings = math.floor(offlineEarnings * 100) / 100
	
	-- Growing crops (count plots with ready-to-harvest crops)
	-- ✅ ACCOUNT FOR DAY/NIGHT MULTIPLIER (average 0.75x = 50% day, 50% night)
	if data.Plots then
		for plotName, plotData in pairs(data.Plots) do
			if plotData.CurrentSeed and plotData.PlantTime then
				local timeElapsed = currentTime - plotData. PlantTime
				local seedInfo = SEEDS[plotData.CurrentSeed]
				if seedInfo then
					-- ✅ ACCOUNT FOR DAY/NIGHT MULTIPLIER (average 0.75x = 50% day at 1x, 50% night at 0.5x)
					local avgGrowthMultiplier = (0.5 * 1) + (0.5 * 0.5)  -- = 0.75x
					local adjustedGrowTime = seedInfo.GrowTime / avgGrowthMultiplier

					if timeElapsed >= adjustedGrowTime then
						offlineCrops = offlineCrops + 1
					end
				end
			end
		end
	end

	-- ADD OFFLINE EARNINGS TO CASH (before setupPlayerData)
	if offlineEarnings > 0 then
		data.Cash = data.Cash + offlineEarnings
		data.TotalEarned = data.TotalEarned + offlineEarnings
		-- Track stat
		_G.TrackStat(player, "TotalCashEarned", offlineEarnings)

		print("💰 Added $" .. offlineEarnings .. " offline earnings to " .. player.Name)
	end

	-- Create player data structure (uses updated data.Cash)
	setupPlayerData(player, data)

	-- Show Welcome popup for returning players (if offline > 1 min)
	if data.LastLogout and totalOfflineSeconds > 60 then
		task.spawn(function()
			task.wait(2)  -- Wait for TutorialManager to load

			local message = "Welcome back to your farm!"
			if offlineEarnings > 0 or offlineCrops > 0 then
				message = ""
				if offlineEarnings > 0 then
					message = message .. "💰 Poultry earned $" .. string.format("%.2f", offlineEarnings) .. "\n"
				end
				if offlineCrops > 0 then
					message = message .. "🌾 " .. offlineCrops .. " crops ready to harvest!\n"
				end
				message = message .. "\n(" .. offlineHours .. "h offline)"
			end

			-- Fire event directly with dynamic message
			local showTutorialEvent = ReplicatedStorage:WaitForChild("ShowTutorialEvent")
			showTutorialEvent:FireClient(player, "OfflineEarnings", {
				Title = "👋 Welcome Back!",
				Message = message,
				Duration = 5
			})
			print("💬 Showed welcome popup to " .. player.Name .. ": " .. message)
		end)
	end


	-- ✅ Poultry passive income loop
	task.spawn(function()
		while player.Parent do
			task.wait(60)  -- Check every minute

			local cash = player.leaderstats:FindFirstChild("Cash")
			local totalEarned = player:FindFirstChild("TotalEarned")

			if cash and totalEarned then
				local poultryOwned = player:FindFirstChild("PoultryOwned")
				if poultryOwned then
					local earnedThisCycle = 0

					for _, poultry in ipairs(poultryOwned:GetChildren()) do
						if poultry:IsA("BoolValue") and poultry.Value then
							-- ONLY if passive enabled for THIS animal
							if player:GetAttribute("Passive_" .. poultry.Name) then
								local rates = {Chicken = 20/60, Cow = 50/60, Pig = 35/60}
								local income = rates[poultry.Name] or 0
								earnedThisCycle = earnedThisCycle + income
							end
						end
					end

					if earnedThisCycle > 0 then
						cash.Value = cash.Value + earnedThisCycle
						totalEarned.Value = totalEarned.Value + earnedThisCycle
						print("🐔 " .. player.Name .. " earned $" .. math.floor(earnedThisCycle * 100) / 100 .. " from poultry")
					end
				end
			end
		end
	end)

	-- Start auto-save loop for this player
	task.spawn(function()
		while player.Parent do
			task.wait(AUTO_SAVE_INTERVAL)
			if player.Parent then
				DataStoreModule:SaveData(player)
			end
		end
	end)
end)



-- Player leaving
Players.PlayerRemoving:Connect(function(player)
	local data = DataStoreModule.PlayerData[player.UserId]
	if data then
		data.LastLogout = os.time()
	end
	DataStoreModule:SaveData(player)
	DataStoreModule:ReleaseLock(player)
	DataStoreModule.PlayerData[player.UserId] = nil
	print("👋 " .. player.Name .. " left. Data saved.")
end)

-- Server shutdown
game:BindToClose(function()
	print("🛑 Server shutting down. Saving all player data...")

	for _, player in pairs(Players:GetPlayers()) do
		DataStoreModule:SaveData(player)
		DataStoreModule:ReleaseLock(player)
	end

	task.wait(3) -- Give time for saves to complete
	print("✅ All data saved. Server can close.")
end)
