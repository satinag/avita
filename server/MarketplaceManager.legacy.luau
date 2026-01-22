-- MarketplaceManager.lua (ServerScriptService - Script)
-- Handles global marketplace: listing, buying, canceling

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local HttpService = game:GetService("HttpService")

-- Load dependencies
local MarketplaceConfig = require(ServerScriptService:WaitForChild("MarketplaceConfig"))
local DataStoreModule = require(ServerScriptService:WaitForChild("DataStoreModule"))

-- Load SoundManager safely
local SoundManager
pcall(function()
	SoundManager = require(ReplicatedStorage:WaitForChild("SoundManager", 2))
end)

print("🏪 MarketplaceManager loaded!")

-- ============================================
-- REMOTE EVENTS
-- ============================================

local ListItemEvent = ReplicatedStorage:WaitForChild("ListItemEvent")
local BuyItemEvent = ReplicatedStorage:WaitForChild("BuyItemEvent")
local CancelListingEvent = ReplicatedStorage:WaitForChild("CancelListingEvent")
local RefreshMarketEvent = ReplicatedStorage:WaitForChild("RefreshMarketEvent")
local MarketplaceResponseEvent = ReplicatedStorage:WaitForChild("MarketplaceResponseEvent")

-- ============================================
-- IN-MEMORY MARKETPLACE CACHE
-- ============================================

local MarketplaceCache = {}
local CacheLastUpdated = 0
local CACHE_DURATION = 5 -- Refresh cache every 5 seconds

-- ============================================
-- HELPER FUNCTIONS
-- ============================================

local function generateListingId()
	return HttpService:GenerateGUID(false)
end

local function isListingExpired(listing)
	local currentTime = os.time()
	local expirationTime = listing.ListedAt + (MarketplaceConfig.SETTINGS.LISTING_DURATION_DAYS * 86400)
	return currentTime >= expirationTime
end

local function removeExpiredListings(listings)
	local cleaned = {}
	for _, listing in ipairs(listings) do
		if not isListingExpired(listing) then
			table.insert(cleaned, listing)
		else
			print("🗑️ Removed expired listing: " .. listing.ItemName .. " from " .. listing.SellerName)
		end
	end
	return cleaned
end

local function getMarketplaceListings(forceRefresh)
	local currentTime = os.time()

	-- Use cache if fresh
	if not forceRefresh and (currentTime - CacheLastUpdated) < CACHE_DURATION then
		return MarketplaceCache
	end

	-- Load from DataStore
	local listings = DataStoreModule.GetMarketplaceListings()

	-- Remove expired listings
	listings = removeExpiredListings(listings)

	-- Update cache
	MarketplaceCache = listings
	CacheLastUpdated = currentTime

	-- DON'T SAVE HERE - only save when creating/canceling listings
	-- DataStoreModule.SaveMarketplaceListings(listings)  ← REMOVE THIS LINE

	return listings
end

-- ============================================
-- LIST ITEM ON MARKETPLACE
-- ============================================

function _G.ListItemOnMarketplace(player, itemName, quantity, pricePerUnit)
	-- Convert to numbers (client might send strings)
	quantity = tonumber(quantity)
	pricePerUnit = tonumber(pricePerUnit)

	-- Validate inputs
	if not itemName or not quantity or not pricePerUnit then
		return false, "Invalid input"
	end

	if quantity <= 0 then
		return false, "Quantity must be positive"
	end

	-- Validate price
	local priceValid, priceError = MarketplaceConfig.ValidatePrice(itemName, pricePerUnit)  -- ✅ CORRECT ORDER
	if not priceValid then
		return false, priceError
	end

	-- Get inventory folder
	local inventoryFolderName = MarketplaceConfig.GetInventoryFolder(itemName)
	if not inventoryFolderName then
		return false, "Unknown item category"
	end

	local inventory = player:FindFirstChild(inventoryFolderName)
	print("📦 Looking for folder:", inventoryFolderName, "Found:", inventory)

	if not inventory then
		return false, "Inventory not found: " .. inventoryFolderName
	end

	local itemValue = inventory:FindFirstChild(itemName)
	print("📦 Looking for item:", itemName, "Found:", itemValue, "Value:", itemValue and itemValue.Value or "nil")

	if not itemValue or itemValue.Value < quantity then
		return false, "Not enough " .. itemName .. " (have: " .. (itemValue and itemValue.Value or 0) .. ")"
	end


	-- Check max listings
	local listings = getMarketplaceListings(true)
	print("📊 AFTER LOAD: listings table has " .. #listings .. " items")

	local playerListings = 0
	for _, listing in ipairs(listings) do
		if listing.SellerId == player.UserId then
			playerListings = playerListings + 1
		end
	end

	if playerListings >= MarketplaceConfig.SETTINGS.MAX_LISTINGS_PER_PLAYER then
		return false, "Maximum " .. MarketplaceConfig.SETTINGS.MAX_LISTINGS_PER_PLAYER .. " listings reached"
	end

	-- Calculate fees
	local totalPrice = quantity * pricePerUnit
	local listingFee = MarketplaceConfig.CalculateListingFee(totalPrice)

	-- Check if player can afford fee
	local cash = player.leaderstats and player.leaderstats:FindFirstChild("Cash")
	if not cash or cash.Value < listingFee then
		return false, "Not enough cash for listing fee ($" .. listingFee .. ")"
	end

	-- Deduct listing fee
	cash.Value = cash.Value - listingFee

	-- Remove items from inventory
	itemValue.Value = itemValue.Value - quantity

	-- Create listing
	local listing = {
		ListingId = generateListingId(),
		SellerId = player.UserId,
		SellerName = player.Name,
		ItemName = itemName,
		Quantity = quantity,
		PricePerUnit = pricePerUnit,
		TotalPrice = totalPrice,
		ListedAt = os.time(),
		Category = MarketplaceConfig.GetCategoryForItem(itemName)
	}

	-- Add to marketplace
	table.insert(listings, listing)
	print("📊 BEFORE SAVE: listings table has " .. #listings .. " items")
	DataStoreModule.SaveMarketplaceListings(listings)


	-- Update cache
	MarketplaceCache = listings
	CacheLastUpdated = os.time()

	-- Update player's marketplace data
	local playerData = DataStoreModule.PlayerData[player.UserId]
	if playerData then
		-- Initialize Marketplace table if it doesn't exist
		if not playerData.Marketplace then
			playerData.Marketplace = {
				ActiveListings = {},
				SoldItems = 0,
				TotalEarnings = 0
			}
		end
		table.insert(playerData.Marketplace.ActiveListings, listing.ListingId)
	end


	print("📋 " .. player.Name .. " listed " .. quantity .. "x " .. itemName .. " for $" .. pricePerUnit .. " each (fee: $" .. listingFee .. ")")

	return true, listing, listingFee
end

-- Handle client list request
ListItemEvent.OnServerEvent:Connect(function(player, itemName, quantity, pricePerUnit)
	local success, result, fee = _G.ListItemOnMarketplace(player, itemName, quantity, pricePerUnit)

	if success then
		-- Play sound
		if SoundManager then
			pcall(function()
				SoundManager:PlaySoundForPlayer(player, "PurchaseSound")
			end)
		end

		-- Notify success
		ListItemEvent:FireClient(player, "success", result, fee)
	else
		-- Notify error
		ListItemEvent:FireClient(player, "error", result)
	end
end)

-- ============================================
-- BUY ITEM FROM MARKETPLACE
-- ============================================

function _G.BuyItemFromMarketplace(player, listingId)
	-- Acquire listing lock to prevent double-purchase
	if not DataStoreModule:AcquireListingLock(listingId) then
		return false, "Item is being purchased by another player"
	end

	-- Get fresh listings
	local listings = getMarketplaceListings(true)

	-- Find listing
	local listingIndex = nil
	local listing = nil

	for i, l in ipairs(listings) do
		if l.ListingId == listingId then
			listingIndex = i
			listing = l
			break
		end
	end

	if not listing then
		DataStoreModule:ReleaseListingLock(listingId)
		return false, "Listing not found"
	end

	-- Check if player is buying their own listing
	if listing.SellerId == player.UserId then
		DataStoreModule:ReleaseListingLock(listingId)
		return false, "Cannot buy your own listing"
	end

	-- Check if player has enough cash
	local cash = player.leaderstats and player.leaderstats:FindFirstChild("Cash")
	if not cash or cash.Value < listing.TotalPrice then
		DataStoreModule:ReleaseListingLock(listingId)
		return false, "Not enough cash (need $" .. listing.TotalPrice .. ")"
	end

	-- Deduct cash from buyer
	cash.Value = cash.Value - listing.TotalPrice

	-- Add item to buyer's inventory
	local inventoryFolderName = MarketplaceConfig.GetInventoryFolder(listing.ItemName)
	local inventory = player:FindFirstChild(inventoryFolderName)

	if not inventory then
		-- Refund buyer
		cash.Value = cash.Value + listing.TotalPrice
		DataStoreModule:ReleaseListingLock(listingId)
		return false, "Inventory error"
	end

	local itemValue = inventory:FindFirstChild(listing.ItemName)
	if not itemValue then
		-- Refund buyer
		cash.Value = cash.Value + listing.TotalPrice
		DataStoreModule:ReleaseListingLock(listingId)
		return false, "Item type not found"
	end

	-- Add items to buyer
	itemValue.Value = itemValue.Value + listing.Quantity

	-- Give cash to seller (even if offline)
	local sellerData = DataStoreModule.PlayerData[listing.SellerId]
	if sellerData then
		sellerData.Cash = sellerData.Cash + listing.TotalPrice
		print("💰 Seller " .. listing.SellerName .. " earned $" .. listing.TotalPrice .. " (online)")
	else
		-- Seller offline - load their data and update
		pcall(function()
			local PlayerDataStore = game:GetService("DataStoreService"):GetDataStore("PlayerData_v5")
			local sellerSavedData = PlayerDataStore:GetAsync("Player_" .. listing.SellerId)
			if sellerSavedData then
				sellerSavedData.Cash = (sellerSavedData.Cash or 0) + listing.TotalPrice
				PlayerDataStore:SetAsync("Player_" .. listing.SellerId, sellerSavedData)
				print("💰 Seller " .. listing.SellerName .. " earned $" .. listing.TotalPrice .. " (offline)")
			end
		end)
	end

	-- Remove listing
	table.remove(listings, listingIndex)
	DataStoreModule:SaveMarketplaceListings(listings)

	-- Update cache
	MarketplaceCache = listings
	CacheLastUpdated = os.time()

	-- Release lock
	DataStoreModule:ReleaseListingLock(listingId)

	-- Update stats
	if _G.TrackStat then
		_G.TrackStat(player, "TotalMarketplacePurchases", 1)
	end

	print("✅ " .. player.Name .. " bought " .. listing.Quantity .. "x " .. listing.ItemName .. " for $" .. listing.TotalPrice)

	return true, listing
end

-- Handle client buy request
BuyItemEvent.OnServerEvent:Connect(function(player, listingId)
	local success, result = _G.BuyItemFromMarketplace(player, listingId)

	if success then
		-- Play sound
		if SoundManager then
			pcall(function()
				SoundManager:PlaySoundForPlayer(player, "CoinSound")
			end)
		end

		-- Notify success
		BuyItemEvent:FireClient(player, "success", result)
	else
		-- Notify error
		BuyItemEvent:FireClient(player, "error", result)
	end
end)

-- ============================================
-- CANCEL LISTING
-- ============================================

function _G.CancelMarketplaceListing(player, listingId)
	print("🔍 Attempting to cancel listing: " .. listingId)

	-- Get listings
	local listings = getMarketplaceListings(true)
	print("📊 Total listings in marketplace: " .. #listings)

	-- DEBUG: Print all listing IDs
	for i, l in ipairs(listings) do
		print("  - Listing " .. i .. ": " .. l.ListingId .. " (Seller: " .. l.SellerName .. ")")
	end

	-- Find listing
	local listingIndex = nil
	local listing = nil
	for i, l in ipairs(listings) do
		if l.ListingId == listingId then
			listingIndex = i
			listing = l
			break
		end
	end

	if not listing then
		warn("❌ Listing " .. listingId .. " not found in marketplace!")
		return false, "Listing not found"
	end

	print("✅ Found listing: " .. listing.ItemName)

	-- Check ownership
	if listing.SellerId ~= player.UserId then
		return false, "Not your listing"
	end

	-- Return items to player
	local inventoryFolderName = MarketplaceConfig.GetInventoryFolder(listing.ItemName)
	local inventory = player:FindFirstChild(inventoryFolderName)
	if inventory then
		local itemValue = inventory:FindFirstChild(listing.ItemName)
		if itemValue then
			itemValue.Value = itemValue.Value + listing.Quantity
		end
	end

	-- Remove listing
	table.remove(listings, listingIndex)
	DataStoreModule.SaveMarketplaceListings(listings)

	-- Update cache
	MarketplaceCache = listings
	CacheLastUpdated = os.time()

	print("🗑️ " .. player.Name .. " cancelled listing: " .. listing.Quantity .. "x " .. listing.ItemName)
	return true, listing
end


-- Handle client cancel request
CancelListingEvent.OnServerEvent:Connect(function(player, listingId)
	local success, result = _G.CancelMarketplaceListing(player, listingId)

	if success then
		CancelListingEvent:FireClient(player, "success", result)
	else
		CancelListingEvent:FireClient(player, "error", result)
	end
end)

-- ============================================
-- REFRESH MARKETPLACE DATA
-- ============================================

RefreshMarketEvent.OnServerEvent:Connect(function(player, category, sortBy)
	local listings = getMarketplaceListings(false) -- Use cache

	-- Filter by category
	if category and category ~= "All" then
		local filtered = {}
		for _, listing in ipairs(listings) do
			if listing.Category == category then
				table.insert(filtered, listing)
			end
		end
		listings = filtered
	end

	-- Sort listings
	if sortBy == "PriceLowHigh" then
		table.sort(listings, function(a, b)
			return a.PricePerUnit < b.PricePerUnit
		end)
	elseif sortBy == "PriceHighLow" then
		table.sort(listings, function(a, b)
			return a.PricePerUnit > b.PricePerUnit
		end)
	else -- Newest first (default)
		table.sort(listings, function(a, b)
			return a.ListedAt > b.ListedAt
		end)
	end

	-- Send to client
	MarketplaceResponseEvent:FireClient(player, listings)
end)

-- ============================================
-- CLEANUP EXPIRED LISTINGS (Every 5 minutes)
-- ============================================

task.spawn(function()
	while true do
		task.wait(300) -- 5 minutes

		local listings = getMarketplaceListings(true)
		local cleaned = removeExpiredListings(listings)

		if #cleaned < #listings then
			print("🗑️ Cleaned " .. (#listings - #cleaned) .. " expired marketplace listings")
			DataStoreModule:SaveMarketplaceListings(cleaned)
			MarketplaceCache = cleaned
			CacheLastUpdated = os.time()
		end
	end
end)

print("✅ MarketplaceManager ready - Marketplace operational!")
