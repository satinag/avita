-- DataStoreModule.lua (ServerScriptService - ModuleScript)
-- Handles all player data saving/loading

-- Global marketplace data (cross-server)
local GlobalMarketplaceData = {
	Listings = {}
}


local DataStoreService = game:GetService("DataStoreService")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local PlayerDataStore = DataStoreService:GetDataStore("PlayerDatav18.0.MARKETPLACE") -- NEW VERSION

local DataStoreModule = {}
DataStoreModule.PlayerData = {} -- Store active player data in memory
DataStoreModule.SessionLocks = {} -- Track session locks

-- ============================================
-- DEFAULT DATA TEMPLATE (COMPLETE)
-- ============================================

local DEFAULT_DATA = {
	Cash = 100,
	TotalEarned = 0,
	HouseLevel = 1,
	ActiveHouseLevel = 1,
	ReservedServerCode = nil,

	-- Seeds
	Seeds = {
		Wheat = 0, Corn = 0, Carrot = 0, Potato = 0,
		Tomato = 0, Pumpkin = 0, Strawberry = 0, Watermelon = 0
	},

	-- Crops
	Crops = {
		Wheat = 0, Corn = 0, Carrot = 0, Potato = 0,
		Tomato = 0, Pumpkin = 0, Strawberry = 0, Watermelon = 0
	},

	-- ✅ ADD: Animals (IntValue system - used by CashSystem)
	Animals = {
		Chicken = 0,
		Cow = 0,
		Pig = 0,
		Sheep = 0
	},

	-- ✅ ADD: Products (IntValue system - used by CashSystem)
	Products = {
		Eggs = 0,
		Milk = 0,
		Meat = 0,
		Wool = 0,
		Honey = 0,
		Wax = 0
	},

	-- ✅ ADD: Fish (IntValue system - used by CashSystem)
	Fish = {
		Salmon = 0,
		Tuna = 0,
		Bass = 0,
		Catfish = 0
	},

	-- Poultry (BoolValue system - legacy/backward compatibility)
	Poultry = {
		Chicken = false,
		Cow = false,
		Pig = false,
		Sheep = false
	},

	-- ProductInventory (same as Products - legacy name)
	ProductInventory = {
		Eggs = 0, Milk = 0, Meat = 0, Wool = 0, Honey = 0
	},

	-- FishInventory (same as Fish - legacy name)
	FishInventory = {
		Salmon = 0, Tuna = 0, Bass = 0, Catfish = 0
	},

	MarketplaceListings = {},

	-- Tools
	Tools = {
		ImprovedShovel = false,
		WateringCan = false,
		UpgradedWateringCan = false,
		UpgradedShovel = false,
		FishingRod = false
	},

	-- Tutorials
	Tutorials = {
		Welcome = false,
		FirstHarvest = false,
		BarnVisit = false,
		Zone1Unlock = false
	},

	HasVisitedBarn = false,
	LastHarvestHint = 0,
	HiveLastCollect_Honey = 0,
	HiveLastCollect_Wax = 0,
	
	-- Daily Reward
	DailyReward = {
		LastClaimDate = "",
		Streak = 0
	},

	-- Plots (16 total)
	Plots = {
		Plot1 = {Owner = nil, CurrentSeed = nil, PlantTime = nil},
		Plot2 = {Owner = nil, CurrentSeed = nil, PlantTime = nil},
		Plot3 = {Owner = nil, CurrentSeed = nil, PlantTime = nil},
		Plot4 = {Owner = nil, CurrentSeed = nil, PlantTime = nil},
		Plot5 = {Owner = nil, CurrentSeed = nil, PlantTime = nil},
		Plot6 = {Owner = nil, CurrentSeed = nil, PlantTime = nil},
		Plot7 = {Owner = nil, CurrentSeed = nil, PlantTime = nil},
		Plot8 = {Owner = nil, CurrentSeed = nil, PlantTime = nil},
		Plot9 = {Owner = nil, CurrentSeed = nil, PlantTime = nil},
		Plot10 = {Owner = nil, CurrentSeed = nil, PlantTime = nil},
		Plot11 = {Owner = nil, CurrentSeed = nil, PlantTime = nil},
		Plot12 = {Owner = nil, CurrentSeed = nil, PlantTime = nil},
		Plot13 = {Owner = nil, CurrentSeed = nil, PlantTime = nil},
		Plot14 = {Owner = nil, CurrentSeed = nil, PlantTime = nil},
		Plot15 = {Owner = nil, CurrentSeed = nil, PlantTime = nil},
		Plot16 = {Owner = nil, CurrentSeed = nil, PlantTime = nil}
	},

	-- Daily Quests
	DailyQuests = {
		LastResetDay = "",
		ActiveQuests = {},
		Progress = {}
	},

	PoultryCooldowns = {},
	HiveCooldowns = {},
	FishingCooldown = 0,

	PassiveIncome = {
		Chicken = false,
		Cow = false,
		Pig = false,
		Sheep = false
	},

	-- Beehives
	Beehives = {
		Count = 0,
		LastCollect = {},
		Passive = {}
	},

	SeedsUnlocked = 0,

	-- Day/Night System
	GameTime = 660,
	DayCount = 1,
	Season = "Spring",
	LastSaveTime = 0,
	LastLogout = 0,

	-- Farm Stats
	FarmStats = {
		-- Overview
		DaysPlayed = 0,
		PrestigeLevel = 0,
		TotalCashEarned = 0,
		TotalCashSpent = 0,

		-- Crops
		TotalCropsHarvested = 0,
		CropHarvestCounts = {
			Wheat = 0, Corn = 0, Carrot = 0, Potato = 0,
			Tomato = 0, Pumpkin = 0, Strawberry = 0, Watermelon = 0
		},
		TotalCropsSold = 0,
		LargestSingleHarvest = 0,

		-- Animals
		TotalAnimalsOwned = 0,
		TotalEggsCollected = 0,
		TotalMilkCollected = 0,
		TotalMeatCollected = 0,
		TotalWoolCollected = 0,
		TotalHoneyCollected = 0,

		-- Economy
		MoneySpentOnPlots = 0,
		MoneySpentOnTools = 0,
		MoneySpentOnSeeds = 0,
		MoneySpentOnAnimals = 0,

		-- Achievements
		Achievements = {
			FarmOwner = false,
			MasterFarmer = false,
			Wealthy = false,
			AnimalLover = false,
			BeeKeeper = false
		}
	}
}

-- ============================================
-- HELPER FUNCTIONS
-- ============================================

-- Deep copy table to avoid reference issues
local function deepCopy(original)
	local copy = {}
	for key, value in pairs(original) do
		if type(value) == "table" then
			copy[key] = deepCopy(value)
		else
			copy[key] = value
		end
	end
	return copy
end

-- Retry wrapper for DataStore calls
local function retryDataStoreCall(func, maxRetries)
	maxRetries = maxRetries or 3
	local attempt = 0
	local success, result

	repeat
		attempt = attempt + 1
		success, result = pcall(func)

		if not success then
			warn("DataStore call failed (attempt " .. attempt .. "/" .. maxRetries .. "): " .. tostring(result))
			if attempt < maxRetries then
				task.wait(1 * attempt) -- Exponential backoff
			end
		end
	until success or attempt >= maxRetries

	return success, result
end

-- ============================================
-- LOAD DATA
-- ============================================

function DataStoreModule:LoadData(player)
	local userId = player.UserId
	local key = "Player_" .. userId

	print("Loading data for " .. player.Name .. " (UserID: " .. userId .. ")")

	local success, data = retryDataStoreCall(function()
		return PlayerDataStore:GetAsync(key)
	end)

	if not success then
		warn("Failed to load data for " .. player.Name .. ". Using default data.")
		player:SetAttribute("HouseLevel", 1)
		return deepCopy(DEFAULT_DATA)
	end

	if data then
		-- Restore reserved server code
		if data.ReservedServerCode then
			player:SetAttribute("ReservedServerCode", data.ReservedServerCode)
		end

		-- Restore house levels
		if data.HouseLevel then
			player:SetAttribute("HouseLevel", data.HouseLevel)
			print("Loaded House Level " .. data.HouseLevel .. " for " .. player.Name)
		end

		if data.ActiveHouseLevel then
			player:SetAttribute("ActiveHouseLevel", data.ActiveHouseLevel)
		end

		-- **Check session lock**
		local currentJobId = game.JobId
		if data.SessionLock and data.SessionLock ~= "" and data.SessionLock ~= currentJobId then
			warn(player.Name .. " is in another server (Session Lock active). Kicking player.")
			player:Kick("Your data is open in another server. Please try again in 1 minute.")
			return nil
		end

		-- **Apply session lock**
		data.SessionLock = currentJobId
		self.SessionLocks[userId] = true

		-- **Merge with default data** (in case new fields were added)
		for key, value in pairs(DEFAULT_DATA) do
			if data[key] == nil then
				data[key] = (type(value) == "table") and deepCopy(value) or value
			elseif type(value) == "table" then
				for subKey, subValue in pairs(value) do
					if data[key][subKey] == nil then
						data[key][subKey] = (type(subValue) == "table") and deepCopy(subValue) or subValue
					end
				end
			end
		end

		print("Data loaded for " .. player.Name)
		return data
	else
		print("New player detected: " .. player.Name .. ". Creating default data.")
		player:SetAttribute("HouseLevel", 1)
		return deepCopy(DEFAULT_DATA)
	end
end

-- ============================================
-- SAVE DATA
-- ============================================

function DataStoreModule:SaveData(player)
	local userId = player.UserId
	local key = "Player_" .. userId
	local data = self.PlayerData[userId]

	if not data then
		warn("No data to save for " .. player.Name)
		return false
	end

	print("Saving data for " .. player.Name)

	-- **Save reserved server code** (preserve it if it exists)
	if not data.ReservedServerCode then
		local serverCode = player:GetAttribute("ReservedServerCode")
		if serverCode then
			data.ReservedServerCode = serverCode
			print("Saved new ReservedServerCode for " .. player.Name)
		end
	end

	-- **Collect current data from player instance**
	local leaderstats = player:FindFirstChild("leaderstats")
	if leaderstats then
		local cash = leaderstats:FindFirstChild("Cash")
		if cash then
			data.Cash = cash.Value
		end
	end

	local totalEarned = player:FindFirstChild("TotalEarned")
	if totalEarned then
		data.TotalEarned = totalEarned.Value
	end

	-- Save house level
	data.HouseLevel = player:GetAttribute("HouseLevel") or 1
	data.ActiveHouseLevel = player:GetAttribute("ActiveHouseLevel") or data.HouseLevel

	-- ✅ NEW: Save Animals (IntValue inventory)
	data.Animals = data.Animals or {Chicken = 0, Cow = 0, Pig = 0, Sheep = 0}
	local animalInventory = player:FindFirstChild("AnimalInventory")
	if animalInventory then
		for _, animalValue in ipairs(animalInventory:GetChildren()) do
			if animalValue:IsA("IntValue") then
				data.Animals[animalValue.Name] = animalValue.Value
				print("💾 Saving " .. animalValue.Name .. ": " .. animalValue.Value)
			end
		end
	end

	-- Save Products (Eggs, Milk, etc.)
	data.Products = data.Products or {Eggs = 0, Milk = 0, Meat = 0, Wool = 0, Honey = 0}
	local productInventory = player:FindFirstChild("ProductInventory")
	if productInventory then
		for _, productValue in ipairs(productInventory:GetChildren()) do
			if productValue:IsA("IntValue") then
				data.Products[productValue.Name] = productValue.Value
			end
		end
	end

	-- Save Fish
	data.Fish = data.Fish or {Salmon = 0, Tuna = 0, Bass = 0, Catfish = 0}
	local fishInventory = player:FindFirstChild("FishInventory")
	if fishInventory then
		for _, fishValue in ipairs(fishInventory:GetChildren()) do
			if fishValue:IsA("IntValue") then
				data.Fish[fishValue.Name] = fishValue.Value
			end
		end
	end


	-- **Seeds**
	local seedInventory = player:FindFirstChild("SeedInventory")
	if seedInventory then
		for seedName, _ in pairs(data.Seeds) do
			local seedValue = seedInventory:FindFirstChild(seedName)
			if seedValue then
				data.Seeds[seedName] = seedValue.Value
			end
		end
	end

	-- **Crops**
	local cropInventory = player:FindFirstChild("CropInventory")
	if cropInventory then
		for cropName, _ in pairs(data.Crops) do
			local cropValue = cropInventory:FindFirstChild(cropName)
			if cropValue then
				data.Crops[cropName] = cropValue.Value
			end
		end
	end

	-- **NEW: Product Inventory** (Eggs, Milk, etc.)
	local productInventory = player:FindFirstChild("ProductInventory")
	if productInventory then
		data.ProductInventory = data.ProductInventory or {}
		for _, product in ipairs({"Eggs", "Milk", "Meat", "Wool", "Honey"}) do
			local productValue = productInventory:FindFirstChild(product)
			if productValue then
				data.ProductInventory[product] = productValue.Value
			end
		end
	end

	-- **NEW: Fish Inventory**
	local fishInventory = player:FindFirstChild("FishInventory")
	if fishInventory then
		data.FishInventory = data.FishInventory or {}
		for _, fish in ipairs({"Salmon", "Tuna", "Bass", "Catfish"}) do
			local fishValue = fishInventory:FindFirstChild(fish)
			if fishValue then
				data.FishInventory[fish] = fishValue.Value
			end
		end
	end

	-- Tools (FIXED - NO SPACES)
	local toolsOwned = player:FindFirstChild("ToolsOwned")
	if toolsOwned then
		local improvedShovel = toolsOwned:FindFirstChild("ImprovedShovel")  -- ✅ No space
		if improvedShovel then
			data.Tools.ImprovedShovel = improvedShovel.Value
		end

		local wateringCan = toolsOwned:FindFirstChild("WateringCan")  -- ✅ No space
		if wateringCan then
			data.Tools.WateringCan = wateringCan.Value
		end

		local fishingRod = toolsOwned:FindFirstChild("FishingRod")
		if fishingRod then
			data.Tools.FishingRod = fishingRod.Value
		end

		local upgradedWateringCan = toolsOwned:FindFirstChild("UpgradedWateringCan")
		if upgradedWateringCan then
			data.Tools.UpgradedWateringCan = upgradedWateringCan.Value
		end

		local upgradedShovel = toolsOwned:FindFirstChild("UpgradedShovel")
		if upgradedShovel then
			data.Tools.UpgradedShovel = upgradedShovel.Value
		end
	end



	-- **POULTRY** (Updated for Sheep)
	local poultryOwned = player:FindFirstChild("PoultryOwned")
	if poultryOwned and not data.Poultry then
		data.Poultry = {}
	end

	if poultryOwned then
		for _, animalName in ipairs({"Chicken", "Cow", "Pig", "Sheep"}) do
			local animal = poultryOwned:FindFirstChild(animalName)
			if animal then
				data.Poultry[animalName] = animal.Value
			end
		end
	end
	

	-- **BEEHIVES** (separate from Poultry)
	data.Beehives = data.Beehives or {Count = 0, LastCollect = {}, Passive = {}}
	local beehiveCount = player:FindFirstChild("BeehiveCount")
	if beehiveCount then
		data.Beehives.Count = beehiveCount.Value
		print("Saving " .. beehiveCount.Value .. " beehives for " .. player.Name)

		-- Save individual hive cooldowns
		for i = 1, beehiveCount.Value do
			local lastCollect = player:GetAttribute("HiveLastCollect_" .. i)
			if lastCollect then
				data.Beehives.LastCollect[i] = lastCollect
			end

			-- Save passive status
			local passive = player:GetAttribute("PassiveHive_" .. i)
			if passive then
				data.Beehives.Passive[i] = true
			end
		end
	end

	-- **Passive income flags** (animals only, not beehives)
	data.PassiveIncome = data.PassiveIncome or {}
	if poultryOwned then
		for _, poultry in ipairs(poultryOwned:GetChildren()) do
			if poultry:IsA("BoolValue") then -- Only animals (not BeehiveCount IntValue)
				local passiveFlag = player:GetAttribute("Passive_" .. poultry.Name)
				if passiveFlag ~= nil then
					data.PassiveIncome[poultry.Name] = passiveFlag
				end
			end
		end
	end
	
	data.AutoCollect = data.AutoCollect or {}
	for _, animalName in ipairs({"Chicken", "Cow", "Pig", "Sheep"}) do
		local autoFlag = player:GetAttribute("AutoCollect_" .. animalName)
		if autoFlag then
			data.AutoCollect[animalName] = true
		end
	end

	-- **Poultry cooldowns** (animals only) save from AnimalInventory
	data.PoultryCooldowns = data.PoultryCooldowns or {}
	local animalInventory = player:FindFirstChild("AnimalInventory")
	if animalInventory then
		for _, animalValue in ipairs(animalInventory:GetChildren()) do
			if animalValue:IsA("IntValue") and animalValue.Value > 0 then
				local lastCollect = player:GetAttribute("AnimalLastCollect_" .. animalValue.Name)
				if lastCollect then
					data.PoultryCooldowns[animalValue.Name] = lastCollect
					print("💾 Saving cooldown for " .. animalValue.Name .. ": " .. lastCollect)
				end
			end
		end
	end

	-- ✅ Save unified hive cooldowns (NO LOOP - just save once)
	local honeyTime = player:GetAttribute("HiveLastCollect_Honey")
	if honeyTime then
		data.HiveLastCollect_Honey = honeyTime
	end

	local waxTime = player:GetAttribute("HiveLastCollect_Wax")
	if waxTime then
		data.HiveLastCollect_Wax = waxTime
	end

	-- **NEW: Save SeedsUnlocked counter**
	local seedsUnlocked = player:FindFirstChild("SeedsUnlocked")
	if seedsUnlocked then
		data.SeedsUnlocked = seedsUnlocked.Value
	end

	-- **Tutorials**
	local tutorialProgress = player:FindFirstChild("TutorialProgress")
	if tutorialProgress then
		for tutName, _ in pairs(data.Tutorials) do
			local tutValue = tutorialProgress:FindFirstChild(tutName)
			if tutValue then
				data.Tutorials[tutName] = tutValue.Value
			end
		end
	end

	-- **Misc**
	local hasVisitedBarn = player:FindFirstChild("HasVisitedBarn")
	if hasVisitedBarn then
		data.HasVisitedBarn = hasVisitedBarn.Value
	end

	local lastHarvestHint = player:FindFirstChild("LastHarvestHint")
	if lastHarvestHint then
		data.LastHarvestHint = lastHarvestHint.Value
	end

	-- **Plots** (from player's OwnedPlots folder)
	print("Checking plots to save for " .. player.Name .. "...")
	local ownedPlots = player:FindFirstChild("OwnedPlots")
	if ownedPlots then
		for plotName, _ in pairs(data.Plots) do
			local ownerValue = ownedPlots:FindFirstChild(plotName)
			local seedValue = ownedPlots:FindFirstChild(plotName .. "_Seed")

			if ownerValue then
				local owner = ownerValue.Value
				local currentSeed = seedValue and seedValue.Value or ""
				local plantTimeValue = ownedPlots:FindFirstChild(plotName .. "_PlantTime")
				local plantTime = plantTimeValue and plantTimeValue.Value or 0

				data.Plots[plotName].Owner = (owner and owner ~= "") and owner or nil
				data.Plots[plotName].CurrentSeed = (currentSeed and currentSeed ~= "") and currentSeed or nil
				data.Plots[plotName].PlantTime = (plantTime > 0) and plantTime or nil

				if owner then
					print(plotName .. " - Owner: " .. owner .. ", Seed: " .. tostring(currentSeed and currentSeed or "none"))
				end
			end
		end
	else
		warn("OwnedPlots folder not found for " .. player.Name)
	end

	-- **SAVE DAY/NIGHT DATA + TIMESTAMP**
	if _G.playerGameTime and _G.playerGameTime[player.UserId] then
		data.GameTime = _G.playerGameTime[player.UserId]
	end

	if _G.playerDayCount and _G.playerDayCount[player.UserId] then
		data.DayCount = _G.playerDayCount[player.UserId]
	end

	if _G.playerSeason and _G.playerSeason[player.UserId] then
		data.Season = _G.playerSeason[player.UserId]
	end

	data.LastSaveTime = os.time() -- Always save timestamp


	-- **Save to DataStore**
	local success, errorMessage = retryDataStoreCall(function()
		PlayerDataStore:SetAsync(key, data)
	end)

	if success then
		print("Data saved for " .. player.Name)
		return true
	else
		warn("Failed to save data for " .. player.Name .. ": " .. tostring(errorMessage))
		return false
	end
end

-- ============================================
-- RELEASE SESSION LOCK
-- ============================================

function DataStoreModule:ReleaseLock(player)
	local userId = player.UserId
	local key = "Player_" .. userId
	local data = self.PlayerData[userId]

	if data and self.SessionLocks[userId] then
		data.SessionLock = nil
		self.SessionLocks[userId] = nil

		retryDataStoreCall(function()
			PlayerDataStore:UpdateAsync(key, function(oldData)
				if oldData then
					oldData.SessionLock = nil
					return oldData
				end
				return nil
			end)
		end)

		print("Session lock released for " .. player.Name)
	end
end

-- ============================================
-- MARKETPLACE LISTING FUNCTIONS
-- ============================================
-- Save marketplace listings to DataStore
function DataStoreModule.SaveMarketplaceListings(listings)
	-- Update global reference
	GlobalMarketplaceData.Listings = listings
	print("💾 Saved " .. #listings .. " marketplace listings")

	-- Debug: verify it was saved
	print("✅ GlobalMarketplaceData now has " .. #GlobalMarketplaceData.Listings .. " listings")
end


-- Get marketplace listings from DataStore
function DataStoreModule.GetMarketplaceListings()
	-- Return a COPY so modifications don't break the reference
	local listings = {}
	for i, listing in ipairs(GlobalMarketplaceData.Listings or {}) do
		table.insert(listings, listing)
	end
	print("📖 Loaded " .. #listings .. " marketplace listings")
	return listings
end



function DataStoreModule:AcquireListingLock(listingId)
	-- Simple lock mechanism
	if self.ListingLocks and self.ListingLocks[listingId] then
		return false
	end

	self.ListingLocks = self.ListingLocks or {}
	self.ListingLocks[listingId] = true
	return true
end

function DataStoreModule:ReleaseListingLock(listingId)
	if self.ListingLocks then
		self.ListingLocks[listingId] = nil
	end
end




return DataStoreModule
