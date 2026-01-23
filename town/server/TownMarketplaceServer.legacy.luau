-- TownMarketplaceServer.lua (Script)
-- Handles marketplace interactions for all Town buildings
-- Location: ServerScriptService (Town place)

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

-- Wait for modules
local GlobalMarketplaceStore = require(script.Parent:WaitForChild("GlobalMarketplaceStore"))
local TownBuildingConfig = require(ReplicatedStorage:WaitForChild("TownBuildingConfig"))

-- ============================================
-- CREATE REMOTE EVENTS
-- ============================================
local OpenMarketplaceEvent = Instance.new("RemoteEvent")
OpenMarketplaceEvent.Name = "OpenMarketplaceEvent"
OpenMarketplaceEvent.Parent = ReplicatedStorage

local RefreshMarketplaceEvent = Instance.new("RemoteEvent")
RefreshMarketplaceEvent.Name = "RefreshMarketplaceEvent"
RefreshMarketplaceEvent.Parent = ReplicatedStorage

local PurchaseItemEvent = Instance.new("RemoteEvent")
PurchaseItemEvent.Name = "PurchaseItemEvent"
PurchaseItemEvent.Parent = ReplicatedStorage

local ListItemEvent = Instance.new("RemoteEvent")
ListItemEvent.Name = "ListItemEvent"
ListItemEvent.Parent = ReplicatedStorage

-- ============================================
-- SAME TARGET FINDER AS TUTORIALS (No PrimaryPart)
-- ============================================
local function findMarketTarget(buildingName)
	-- Find ANY ProximityPrompt under Town.BuildingName → return prompt.Parent
	local town = workspace:FindFirstChild("Town")
	if town then
		local building = town:FindFirstChild(buildingName, true)  -- Recursive!
		if building then
			for _, prompt in ipairs(building:GetDescendants()) do
				if prompt:IsA("ProximityPrompt") then
					return prompt.Parent  -- Door.LeftPart, Handle, etc. ✓
				end
			end
		end
	end
	return nil
end

-- ============================================
-- PROXIMITY PROMPT SETUP (SAME LOGIC)
-- ============================================
local function setupBuildingPrompts()
	local townFolder = workspace:FindFirstChild("Town")
	if not townFolder then
		warn("❌ Town folder not found!")
		return
	end

	print("🔍 Setting up marketplace prompts...")
	for _, building in ipairs(TownBuildingConfig.BUILDINGS) do
		local target = findMarketTarget(building.ID)

		if target then
			local prompt = target:FindFirstChildOfClass("ProximityPrompt", true)

			if prompt then
				prompt.ActionText = "Browse " .. building.Name
				prompt.ObjectText = building.Icon .. " " .. building.Name

				prompt.Triggered:Connect(function(player)
					print("🏪 " .. player.Name .. " opened " .. building.Name)
					OpenMarketplaceEvent:FireClient(player, building.ID)
				end)

				print("✅ Marketplace: " .. building.Name .. " → " .. target:GetFullName())
			else
				warn("⚠️ No ProximityPrompt under: " .. target:GetFullName())
			end
		else
			warn("⚠️ Building target FAILED: " .. building.ID)
		end
	end
end

-- Initialize
task.spawn(function()
	task.wait(2)
	setupBuildingPrompts()
end)


-- ============================================
-- REFRESH LISTINGS (Filtered by Building)
-- ============================================
RefreshMarketplaceEvent.OnServerEvent:Connect(function(player, buildingId, sortBy)
	print("🔄 Refresh request: " .. buildingId .. " - Sort: " .. tostring(sortBy))

	-- Get all listings
	local allListings = GlobalMarketplaceStore.GetAllListings()

	-- Filter by building rules
	local filteredListings = TownBuildingConfig.FilterListings(buildingId, allListings)

	-- Apply sorting
	if sortBy == "PriceLow" then
		table.sort(filteredListings, function(a, b) return a.PricePerUnit < b.PricePerUnit end)
	elseif sortBy == "PriceHigh" then
		table.sort(filteredListings, function(a, b) return a.PricePerUnit > b.PricePerUnit end)
	elseif sortBy == "Newest" then
		table.sort(filteredListings, function(a, b) return (a.ListedAt or 0) > (b.ListedAt or 0) end)
	end

	print("📦 Sending " .. #filteredListings .. " listings to " .. player.Name)

	-- Send to client
	RefreshMarketplaceEvent:FireClient(player, filteredListings)
end)

-- ============================================
-- PURCHASE ITEM
-- ============================================
PurchaseItemEvent.OnServerEvent:Connect(function(player, listingId, buildingId)
	print("💰 Purchase request: " .. player.Name .. " - Listing: " .. listingId)

	-- Get listing data
	local allListings = GlobalMarketplaceStore.GetAllListings()
	local listing = nil

	for _, l in ipairs(allListings) do
		if l.ListingId == listingId then
			listing = l
			break
		end
	end

	if not listing then
		PurchaseItemEvent:FireClient(player, false, "Listing no longer available")
		return
	end

	-- Prevent self-purchase
	if listing.SellerId == player.UserId then
		PurchaseItemEvent:FireClient(player, false, "You can't buy your own listing!")
		return
	end

	-- Calculate total price
	local totalPrice = listing.Quantity * listing.PricePerUnit

	-- Check if buyer has enough money (cross-server - use DataStore)
	local DataStoreService = game:GetService("DataStoreService")
	local PlayerDataStore = DataStoreService:GetDataStore("PlayerData_v18.0.1")
	local buyerKey = "Player_" .. player.UserId

	local buyerData = nil
	local success, err = pcall(function()
		buyerData = PlayerDataStore:GetAsync(buyerKey)
	end)

	if not success or not buyerData then
		PurchaseItemEvent:FireClient(player, false, "Failed to load your data")
		return
	end

	if buyerData.Cash < totalPrice then
		PurchaseItemEvent:FireClient(player, false, "Not enough cash! Need $" .. totalPrice)
		return
	end

	-- DEDUCT BUYER'S CASH
	buyerData.Cash = buyerData.Cash - totalPrice

	-- ADD ITEM TO BUYER'S INVENTORY
	local categoryFolder = listing.Category -- "Crops", "Products", "Fish", "Animals"

	if categoryFolder == "Crops" then
		buyerData.Crops[listing.ItemName] = (buyerData.Crops[listing.ItemName] or 0) + listing.Quantity
	elseif categoryFolder == "Products" then
		buyerData.Products[listing.ItemName] = (buyerData.Products[listing.ItemName] or 0) + listing.Quantity
	elseif categoryFolder == "Fish" then
		buyerData.Fish[listing.ItemName] = (buyerData.Fish[listing.ItemName] or 0) + listing.Quantity
	elseif categoryFolder == "Animals" then
		buyerData.Animals[listing.ItemName] = (buyerData.Animals[listing.ItemName] or 0) + listing.Quantity
	end

	-- SAVE BUYER DATA
	local saveSuccess = pcall(function()
		PlayerDataStore:SetAsync(buyerKey, buyerData)
	end)

	if not saveSuccess then
		PurchaseItemEvent:FireClient(player, false, "Transaction failed - contact support")
		return
	end

	-- ADD CASH TO SELLER (even if offline)
	local sellerKey = "Player_" .. listing.SellerId
	local sellerData = nil

	pcall(function()
		sellerData = PlayerDataStore:GetAsync(sellerKey)
	end)

	if sellerData then
		sellerData.Cash = sellerData.Cash + totalPrice
		sellerData.TotalEarned = sellerData.TotalEarned + totalPrice

		pcall(function()
			PlayerDataStore:SetAsync(sellerKey, sellerData)
		end)

		print("💵 Seller " .. listing.SellerName .. " received $" .. totalPrice)

		-- Notify seller if online
		local seller = Players:FindFirstChild(listing.SellerName)
		if seller then
			local ShowTutorialEvent = ReplicatedStorage:FindFirstChild("ShowTutorialEvent")
			if ShowTutorialEvent then
				ShowTutorialEvent:FireClient(seller, "ItemSold", {
					Title = "Item Sold! 💰",
					Message = listing.ItemName .. " x" .. listing.Quantity .. " sold for $" .. totalPrice .. "!",
					Duration = 5
				})
			end
		end
	end

	-- REMOVE LISTING FROM MARKETPLACE
	GlobalMarketplaceStore.RemoveListing(listingId)

	-- NOTIFY BUYER
	PurchaseItemEvent:FireClient(player, true, "Purchased successfully! Check your inventory in Farm.")

	print("✅ Purchase complete: " .. listing.ItemName .. " x" .. listing.Quantity .. " for $" .. totalPrice)
	-- Track marketplace purchase quest (cross-server)
	-- This will be tracked when player returns to Farm
	-- For simplicity, we'll track on Farm place login instead
end)

-- ============================================
-- LIST ITEM (Non-VIP users in Town)
-- ============================================
ListItemEvent.OnServerEvent:Connect(function(player, itemName, quantity, pricePerUnit, category, buildingId)
	print("📦 List request: " .. player.Name .. " - " .. itemName .. " x" .. quantity)

	-- Validate building filter
	if not TownBuildingConfig.IsItemAllowed(buildingId, itemName, category) then
		ListItemEvent:FireClient(player, false, "This item cannot be sold at " .. buildingId)
		return
	end

	-- Load player data from Farm place
	local DataStoreService = game:GetService("DataStoreService")
	local PlayerDataStore = DataStoreService:GetDataStore("PlayerData_v18.0.1")
	local key = "Player_" .. player.UserId

	local playerData = nil
	local success, err = pcall(function()
		playerData = PlayerDataStore:GetAsync(key)
	end)

	if not success or not playerData then
		ListItemEvent:FireClient(player, false, "Failed to load your inventory")
		return
	end

	-- Check if player has the item
	local inventory = nil
	if category == "Crops" then
		inventory = playerData.Crops
	elseif category == "Products" then
		inventory = playerData.Products
	elseif category == "Fish" then
		inventory = playerData.Fish
	elseif category == "Animals" then
		inventory = playerData.Animals
	end

	if not inventory or not inventory[itemName] or inventory[itemName] < quantity then
		ListItemEvent:FireClient(player, false, "You don't have enough " .. itemName)
		return
	end

	-- DEDUCT ITEM FROM INVENTORY
	inventory[itemName] = inventory[itemName] - quantity

	-- SAVE PLAYER DATA
	local saveSuccess = pcall(function()
		PlayerDataStore:SetAsync(key, playerData)
	end)

	if not saveSuccess then
		ListItemEvent:FireClient(player, false, "Failed to save - try again")
		return
	end

	-- CREATE LISTING
	local listingData = {
		SellerName = player.Name,
		SellerId = player.UserId,
		ItemName = itemName,
		Quantity = quantity,
		PricePerUnit = pricePerUnit,
		Category = category,
		ListedAt = os.time()
	}

	local listSuccess, listingId = GlobalMarketplaceStore.AddListing(listingData)

	if listSuccess then
		ListItemEvent:FireClient(player, true, "Listed successfully!")
		print("✅ Listed: " .. itemName .. " x" .. quantity .. " at $" .. pricePerUnit .. " each")
		-- Track marketplace listing quest (cross-server)
		-- Note: This tracking happens in Farm place when player returns
		-- For now, we'll use MessagingService for real-time tracking
	else
		-- Refund item
		inventory[itemName] = inventory[itemName] + quantity
		pcall(function()
			PlayerDataStore:SetAsync(key, playerData)
		end)

		ListItemEvent:FireClient(player, false, "Marketplace error - item refunded")
	end
end)

print("✅ TownMarketplaceServer ready")
