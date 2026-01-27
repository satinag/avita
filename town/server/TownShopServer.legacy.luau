-- TownShopServer.lua (WITH LISTING MANAGEMENT)
-- Handles Town shop selling + viewing/canceling player's listings
-- Location: ServerScriptService (Town place)

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local DataStoreService = game:GetService("DataStoreService")
local HttpService = game:GetService("HttpService")

-- ============================================
-- TIME REMOTE EVENT (for TownShopClient fallback)
-- ============================================
local GetCurrentTimeEvent = ReplicatedStorage:FindFirstChild("GetCurrentTimeEvent")
if not GetCurrentTimeEvent then
	GetCurrentTimeEvent = Instance.new("RemoteFunction")
	GetCurrentTimeEvent.Name = "GetCurrentTimeEvent"
	GetCurrentTimeEvent.Parent = ReplicatedStorage
end

GetCurrentTimeEvent.OnServerInvoke = function(player)
	-- Get game time from any player
	local anyPlayer = game.Players:GetPlayers()[1]
	if anyPlayer and _G.getCurrentTime then
		return _G.getCurrentTime(anyPlayer)
	end
	return 0
end

local TownBuildingConfig = require(ReplicatedStorage:WaitForChild("TownBuildingConfig"))
local ProductConfig = require(ReplicatedStorage:WaitForChild("ProductConfig"))

-- Use SAME global DataStore
local PendingListingsStore = DataStoreService:GetDataStore("GlobalPendingListings", "global")

local PAYMENT_DELAY = 12 * 60 -- 12 game hours

-- Create RemoteEvents
local OpenTownShopEvent = ReplicatedStorage:FindFirstChild("OpenTownShopEvent")
if not OpenTownShopEvent then
	OpenTownShopEvent = Instance.new("RemoteEvent")
	OpenTownShopEvent.Name = "OpenTownShopEvent"
	OpenTownShopEvent.Parent = ReplicatedStorage
end

local SellToTownShopEvent = ReplicatedStorage:FindFirstChild("SellToTownShopEvent")
if not SellToTownShopEvent then
	SellToTownShopEvent = Instance.new("RemoteEvent")
	SellToTownShopEvent.Name = "SellToTownShopEvent"
	SellToTownShopEvent.Parent = ReplicatedStorage
end

local GetPlayerListingsEvent = ReplicatedStorage:FindFirstChild("GetPlayerListingsEvent")
if not GetPlayerListingsEvent then
	GetPlayerListingsEvent = Instance.new("RemoteFunction")
	GetPlayerListingsEvent.Name = "GetPlayerListingsEvent"
	GetPlayerListingsEvent.Parent = ReplicatedStorage
end

local CancelListingEvent = ReplicatedStorage:FindFirstChild("CancelListingEvent")
if not CancelListingEvent then
	CancelListingEvent = Instance.new("RemoteEvent")
	CancelListingEvent.Name = "CancelListingEvent"
	CancelListingEvent.Parent = ReplicatedStorage
end

print("🏪 TownShopServer loading...")

-- ============================================
-- HELPER FUNCTIONS
-- ============================================

local function getPlayerGameTime(player)
	if _G.getCurrentTime then
		return _G.getCurrentTime(player)
	end
	return 0
end

-- Get player's listings for a specific building
GetPlayerListingsEvent.OnServerInvoke = function(player, buildingId)
	local listings = {}

	local success, pages = pcall(function()
		return PendingListingsStore:ListKeysAsync("Listing_", 100)
	end)

	if not success then return listings end

	repeat
		local pageData = pages:GetCurrentPage()

		for _, keyInfo in ipairs(pageData) do
			local listingSuccess, listing = pcall(function()
				return PendingListingsStore:GetAsync(keyInfo.KeyName)
			end)

			if listingSuccess and listing 
				and listing.PlayerUserId == player.UserId 
				and listing.BuildingId == buildingId
				and listing.Status == "Pending" then

				table.insert(listings, listing)
			end
		end

		if not pages.IsFinished then
			pages:AdvanceToNextPageAsync()
		end
	until pages.IsFinished

	return listings
end

-- Cancel listing
CancelListingEvent.OnServerEvent:Connect(function(player, listingId)
	print("🔄 Cancel listing request:", player.Name, listingId)

	local success, listing = pcall(function()
		return PendingListingsStore:GetAsync("Listing_" .. listingId)
	end)

	if not success or not listing then
		warn("❌ Listing not found:", listingId)
		return
	end

	if listing.PlayerUserId ~= player.UserId then 
		warn("❌ Player doesn't own listing:", player.Name, listingId)
		return
	end

	if listing.Status ~= "Pending" then
		warn("❌ Listing not pending:", listingId, listing.Status)
		return
	end

	-- ✅ Mark as cancelled (will be restored in Farm when player returns)
	listing.Status = "Cancelled"
	listing.CancelledAt = os.time()  -- Track when cancelled

	pcall(function()
		PendingListingsStore:SetAsync("Listing_" .. listingId, listing)
	end)

	print("✅ Listing cancelled:", player.Name, listingId)
	print("   Items will be restored when returning to Farm")

	-- Notify client
	CancelListingEvent:FireClient(player, true, listingId)

	-- ✅ Show notification
	local ShowTutorialEvent = ReplicatedStorage:FindFirstChild("ShowTutorialEvent")
	if ShowTutorialEvent then
		ShowTutorialEvent:FireClient(player, "ListingCancelled", {
			Title = "🔄 Listing Cancelled",
			Message = listing.Quantity .. "x " .. listing.ItemName .. " will return to your Farm inventory",
			Duration = 4
		})
	end
end)



-- Sell to Town shop (creates listing)
SellToTownShopEvent.OnServerEvent:Connect(function(player, buildingId, items)
	print("🏪 Town sell request:", player.Name, buildingId)

	local building = TownBuildingConfig.GetBuilding(buildingId)
	if not building then
		SellToTownShopEvent:FireClient(player, "failed", "Invalid building")
		return
	end

	local currentTime = getPlayerGameTime(player)
	local paymentTime = currentTime + PAYMENT_DELAY

	local totalPending = 0
	local listingsCreated = {}

	for itemName, quantity in pairs(items) do
		if quantity <= 0 then continue end

		-- Find inventory
		local category
		local inventory

		local cropInv = player:FindFirstChild("CropInventory")
		local prodInv = player:FindFirstChild("ProductInventory")
		local fishInv = player:FindFirstChild("FishInventory")

		if cropInv and cropInv:FindFirstChild(itemName) then
			category = "Crops"
			inventory = cropInv
		elseif prodInv and prodInv:FindFirstChild(itemName) then
			category = "Products"
			inventory = prodInv
		elseif fishInv and fishInv:FindFirstChild(itemName) then
			category = "Fish"
			inventory = fishInv
		else
			continue
		end

		local valueObj = inventory:FindFirstChild(itemName)
		if not valueObj or valueObj.Value < quantity then
			SellToTownShopEvent:FireClient(player, "failed", "Not enough " .. itemName)
			return
		end

		-- Check if building accepts
		if not TownBuildingConfig.IsItemAccepted(buildingId, itemName, category) then
			SellToTownShopEvent:FireClient(player, "failed", building.Name .. " doesn't accept " .. itemName)
			return
		end

		-- Get price
		local basePrice = 0
		if ProductConfig.GetSellPrice then
			basePrice = ProductConfig.GetSellPrice(itemName)
		else
			local data = ProductConfig.GetCropData and ProductConfig.GetCropData(itemName)
				or ProductConfig.GetProductData and ProductConfig.GetProductData(itemName)
				or ProductConfig.GetFishData and ProductConfig.GetFishData(itemName)
			basePrice = data and data.SellPrice or 0
		end

		local townUnitPrice = math.floor(basePrice * building.PriceMultiplier)
		local earnings = townUnitPrice * quantity

		-- Deduct inventory
		valueObj.Value = valueObj.Value - quantity

		-- Create listing
		local listingId = HttpService:GenerateGUID(false)
		local listing = {
			ListingId = listingId,
			PlayerUserId = player.UserId,
			PlayerName = player.Name,
			BuildingId = buildingId,
			ItemName = itemName,
			Category = category,
			Quantity = quantity,
			PricePerUnit = townUnitPrice,
			TotalEarnings = earnings,
			CreatedAt = currentTime,
			PaymentAt = paymentTime,
			Status = "Pending"
		}

		pcall(function()
			PendingListingsStore:SetAsync("Listing_" .. listingId, listing)
		end)

		totalPending = totalPending + earnings
		table.insert(listingsCreated, {
			Name = itemName,
			Quantity = quantity,
			Price = townUnitPrice,
			Total = earnings
		})
	end

	if totalPending <= 0 then
		SellToTownShopEvent:FireClient(player, "failed", "Nothing sold")
		return
	end

	print("✅ Town sell complete:", player.Name, "pending $" .. totalPending)

	SellToTownShopEvent:FireClient(player, "success", {
		TotalEarned = totalPending,
		ItemsSold = listingsCreated,
		PaymentDelay = PAYMENT_DELAY
	})
end)

print("✅ TownShopServer ready!")
