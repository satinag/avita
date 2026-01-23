-- ProductManager.lua (ServerScriptService - Script)
-- Handles product collection, selling, and conversion

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

-- Load dependencies
local ProductConfig = require(ReplicatedStorage:WaitForChild("ProductConfig"))
local DataStoreModule = require(ServerScriptService:WaitForChild("DataStoreModule"))

-- Load SoundManager safely
local SoundManager
pcall(function()
	SoundManager = require(ReplicatedStorage:WaitForChild("SoundManager", 2))
end)

print("📦 ProductManager loaded!")

-- ============================================
-- REMOTE EVENTS (Create if don't exist)
-- ============================================

local function getOrCreateEvent(name)
	local event = ReplicatedStorage:FindFirstChild(name)
	if not event then
		event = Instance.new("RemoteEvent")
		event.Name = name
		event.Parent = ReplicatedStorage
		print("✅ Created RemoteEvent: " .. name)
	end
	return event
end

local SellProductEvent = getOrCreateEvent("SellProductEvent")
local ConvertProductEvent = getOrCreateEvent("ConvertProductEvent")

-- ============================================
-- COLLECTION FUNCTIONS (Called by PoultryBarn/HiveManager)
-- ============================================

-- Collect product from animal
function _G.CollectAnimalProduct(player, animalName)
	local currentTime = os.time()
	local lastCollect = player:GetAttribute("AnimalLastCollect_" .. animalName) or 0
	local animalData = ProductConfig.GetAnimalData(animalName)

	if not animalData then
		return false, "Invalid animal"
	end

	-- Get animal count
	local animalInventory = player:FindFirstChild("AnimalInventory")
	local animalValue = animalInventory and animalInventory:FindFirstChild(animalName)
	local animalCount = animalValue and animalValue.Value or 0

	if animalCount == 0 then
		return false, "No " .. animalName .. " owned"
	end

	local productionTime = animalData.ProductionTime or 60
	local timeElapsed = currentTime - lastCollect

	-- Check if at least 1 production cycle completed
	if timeElapsed < productionTime then
		local remaining = productionTime - timeElapsed
		return false, remaining, animalData.Icon
	end

	-- Calculate how many products accumulated (based on animal count + time)
	-- Each animal produces 1 product per productionTime
	local cyclesCompleted = math.floor(timeElapsed / productionTime)
	local totalProducts = math.min(cyclesCompleted * animalCount, animalCount * 10)  -- Cap at 10 cycles per animal

	if totalProducts == 0 then
		return false, "Not ready yet"
	end

	-- Give products
	local productType = animalData.ProductType
	local productInventory = player:FindFirstChild("ProductInventory")
	local productValue = productInventory and productInventory:FindFirstChild(productType)

	if productValue then
		productValue.Value = productValue.Value + totalProducts

		-- Reset cooldown to current time (or keep partial progress)
		-- Option 1: Reset to now (wastes partial progress)
		-- player:SetAttribute("AnimalLastCollect_" .. animalName, currentTime)

		-- Option 2: Keep partial progress (recommended)
		local partialProgress = timeElapsed % productionTime
		player:SetAttribute("AnimalLastCollect_" .. animalName, currentTime - partialProgress)

		print("✅ " .. player.Name .. " collected " .. totalProducts .. "x " .. productType .. " from " .. animalCount .. "x " .. animalName)

		return true, totalProducts, animalData.Icon
	end

	return false, "Product inventory error"
end

-- Collect Honey from ALL hives at once (like PoultryBarn)
function _G.CollectHoneyProduct(player)
	local beehiveCount = player:FindFirstChild("BeehiveCount")
	if not beehiveCount or beehiveCount.Value == 0 then
		return false, "locked", "You don't own any beehives!"
	end

	local currentTime = os.time()
	local lastCollect = player:GetAttribute("HiveLastCollect_Honey") or 0
	local productionTime = 300 -- 5 minutes

	local timeElapsed = currentTime - lastCollect

	if timeElapsed < productionTime then
		local remaining = productionTime - timeElapsed
		return false, remaining, "🍯"
	end

	-- Calculate total honey (2 per hive, scaled by hive count)
	local totalHives = beehiveCount.Value
	local honeyAmount = totalHives * 2

	-- Add honey to inventory
	local productInventory = player:FindFirstChild("ProductInventory")
	local honeyValue = productInventory and productInventory:FindFirstChild("Honey")

	if honeyValue then
		honeyValue.Value = honeyValue.Value + honeyAmount
		player:SetAttribute("HiveLastCollect_Honey", currentTime)

		-- Track stats
		if _G.TrackStat then
			_G.TrackStat(player, "TotalHoneyCollected", honeyAmount)
		end

		print("🍯 " .. player.Name .. " collected " .. honeyAmount .. " honey from " .. totalHives .. " hives")

		-- ✅ ADD THIS: Complete tutorial level 12 on first honey collection
		if _G.CompleteTutorialLevel then
			local currentLevel = player:FindFirstChild("CurrentArrowLevel")
			if currentLevel and currentLevel.Value == 12 then
				print("🎯 Completing tutorial level 12 - First honey collected")
				_G.CompleteTutorialLevel(player, 12)
			end
		end

		return true, honeyAmount, "🍯"
	end

	return false, "Inventory error"
end


-- Collect Wax from ALL hives at once (like PoultryBarn)
function _G.CollectWaxProduct(player)
	local beehiveCount = player:FindFirstChild("BeehiveCount")
	if not beehiveCount or beehiveCount.Value == 0 then
		return false, "locked", "You don't own any beehives!"
	end

	local currentTime = os.time()
	local lastCollect = player:GetAttribute("HiveLastCollect_Wax") or 0
	local productionTime = 600 -- 10 minutes

	local timeElapsed = currentTime - lastCollect

	if timeElapsed < productionTime then
		local remaining = productionTime - timeElapsed
		return false, remaining, "🕯️"
	end

	-- Calculate total wax (1 per hive, scaled by hive count)
	local totalHives = beehiveCount.Value
	local waxAmount = totalHives * 1

	-- Add wax to inventory
	local productInventory = player:FindFirstChild("ProductInventory")
	local waxValue = productInventory and productInventory:FindFirstChild("Wax")

	if waxValue then
		waxValue.Value = waxValue.Value + waxAmount
		player:SetAttribute("HiveLastCollect_Wax", currentTime)

		-- Track stats
		if _G.TrackStat then
			_G.TrackStat(player, "TotalWaxCollected", waxAmount)
		end

		print("🕯️ " .. player.Name .. " collected " .. waxAmount .. " wax from " .. totalHives .. " hives")
		return true, waxAmount, "🕯️"
	end

	return false, "Inventory error"
end

-- ============================================
-- SELL PRODUCT (Quick Sell at PoultryShop)
-- ============================================

function _G.SellProduct(player, productName, quantity)
	local productInfo = ProductConfig.GetProductData(productName) or ProductConfig.GetFishData(productName)
	if not productInfo then
		return false, 0, "Unknown product"
	end

	-- Find inventory (products or fish)
	local productInventory = player:FindFirstChild("ProductInventory")
	local fishInventory = player:FindFirstChild("FishInventory")

	local inventory = productInventory or fishInventory
	if not inventory then
		return false, 0, "No inventory"
	end

	local productValue = inventory:FindFirstChild(productName)
	if not productValue then
		return false, 0, "Product not found"
	end

	-- Check if player has enough
	if productValue.Value < quantity then
		return false, 0, "Need " .. quantity .. " " .. productName
	end

	-- Calculate earnings
	local pricePerUnit = productInfo.QuickSellPrice
	local earnings = quantity * pricePerUnit

	-- Give cash
	local cash = player.leaderstats and player.leaderstats:FindFirstChild("Cash")
	local totalEarned = player:FindFirstChild("TotalEarned")

	if cash then
		cash.Value = cash.Value + earnings
	end

	if totalEarned then
		totalEarned.Value = totalEarned.Value + earnings
	end

	-- Remove products
	productValue.Value = productValue.Value - quantity

	-- Track stats
	if _G.TrackStat then
		_G.TrackStat(player, "TotalCashEarned", earnings)
		_G.TrackStat(player, "Total" .. productName .. "Sold", quantity)
	end

	print("💰 " .. player.Name .. " sold " .. quantity .. " " .. productName .. " for $" .. earnings)

	return true, earnings, "Sold " .. quantity .. " " .. productName
end

-- Handle client sell request
SellProductEvent.OnServerEvent:Connect(function(player, productName, quantity)
	local success, earnings, message = _G.SellProduct(player, productName, quantity)

	if success then
		-- Play sound
		if SoundManager then
			pcall(function()
				SoundManager:PlaySoundForPlayer(player, "CoinSound")
			end)
		end

		-- Notify client
		SellProductEvent:FireClient(player, "success", earnings, message)
	else
		-- Notify error
		SellProductEvent:FireClient(player, "error", 0, message)
	end
end)

-- ============================================
-- CONVERT PRODUCT (Product → Seeds)
-- ============================================

function _G.ConvertProduct(player, productName)
	local recipe = ProductConfig.GetConversionRecipe(productName)
	if not recipe then
		return false, "No conversion recipe"
	end

	-- Find inventory
	local productInventory = player:FindFirstChild("ProductInventory")
	local fishInventory = player:FindFirstChild("FishInventory")

	local inventory = productInventory or fishInventory
	if not inventory then
		return false, "No inventory"
	end

	local productValue = inventory:FindFirstChild(productName)
	if not productValue then
		return false, "Product not found"
	end

	-- Check if player has enough
	if productValue.Value < recipe.Input then
		return false, "Need " .. recipe.Input .. " " .. productName
	end

	-- Get seed inventory
	local seedInventory = player:FindFirstChild("SeedInventory")
	if not seedInventory then
		return false, "No seed inventory"
	end

	-- Add seeds
	local seedsGained = {}
	for seedName, amount in pairs(recipe.Output) do
		local seedValue = seedInventory:FindFirstChild(seedName)
		if seedValue then
			seedValue.Value = seedValue.Value + amount
			table.insert(seedsGained, amount .. " " .. seedName)
		end
	end

	-- Remove products
	productValue.Value = productValue.Value - recipe.Input

	print("🌱 " .. player.Name .. " converted " .. recipe.Input .. " " .. productName .. " → " .. table.concat(seedsGained, ", ") .. " seeds")

	return true, table.concat(seedsGained, " + ")
end

-- Handle client convert request
ConvertProductEvent.OnServerEvent:Connect(function(player, productName)
	local success, seedsGained = _G.ConvertProduct(player, productName)

	if success then
		-- Play sound
		if SoundManager then
			pcall(function()
				SoundManager:PlaySoundForPlayer(player, "PurchaseSound")
			end)
		end

		-- Notify client
		ConvertProductEvent:FireClient(player, "success", seedsGained)
	else
		-- Notify error
		ConvertProductEvent:FireClient(player, "error", seedsGained)
	end
end)

-- ============================================
-- PASSIVE INCOME LOOP (Accumulate Products)
-- ============================================

task.spawn(function()
	while true do
		task.wait(60) -- Check every minute

		for _, player in ipairs(Players:GetPlayers()) do
			local productInventory = player:FindFirstChild("ProductInventory")
			local animalInventory = player:FindFirstChild("AnimalInventory")

			if productInventory and animalInventory then
				-- Animal products
				for _, animalName in ipairs({"Chicken", "Cow", "Pig", "Sheep"}) do
					-- Only if passive enabled
					if player:GetAttribute("Passive_" .. animalName) then
						local animalValue = animalInventory:FindFirstChild(animalName)
						if animalValue and animalValue.Value > 0 then
							local productMap = {
								Chicken = "Eggs",
								Cow = "Milk",
								Pig = "Meat",
								Sheep = "Wool"
							}

							local productName = productMap[animalName]
							local productValue = productInventory:FindFirstChild(productName)

							if productValue then
								-- Accumulate 1 product per animal per minute
								local amount = animalValue.Value
								productValue.Value = productValue.Value + amount

								print("🔄 PASSIVE: " .. player.Name .. " gained " .. amount .. " " .. productName .. " from " .. animalValue.Value .. " " .. animalName)
							end
						end
					end
				end
			end

			-- Beehive passive honey
			local beehiveCount = player:FindFirstChild("BeehiveCount")
			if productInventory and beehiveCount then
				for i = 1, beehiveCount.Value do
					if player:GetAttribute("Passive_Hive" .. i) then
						local honeyValue = productInventory:FindFirstChild("Honey")
						if honeyValue then
							-- Accumulate 2 honey per hive per minute
							honeyValue.Value = honeyValue.Value + 2
							print("🔄 PASSIVE: " .. player.Name .. " gained 2 Honey from Hive " .. i)
						end
					end
				end
			end
		end
	end
end)

print("✅ ProductManager ready - Passive income loop started")
