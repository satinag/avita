-- GlobalMarketplaceStore.lua (ModuleScript)
-- Handles global marketplace listings across all servers
-- PLACE THIS IN BOTH FARM AND TOWN ServerScriptService

local DataStoreService = game:GetService("DataStoreService")
local HttpService = game:GetService("HttpService")

local MarketplaceStore = DataStoreService:GetDataStore("GlobalMarketplace_v1.0.0")
local LISTING_PREFIX = "Listing_"
local MAX_LISTING_AGE = 7 * 24 * 60 * 60 -- 7 days in seconds

local GlobalMarketplaceStore = {}

-- ============================================
-- ADD LISTING
-- ============================================
function GlobalMarketplaceStore.AddListing(listingData)
	local listingId = HttpService:GenerateGUID(false)
	local key = LISTING_PREFIX .. listingId

	-- Add timestamp
	listingData.ListedAt = os.time()
	listingData.ListingId = listingId

	local success, err = pcall(function()
		MarketplaceStore:SetAsync(key, listingData)
	end)

	if success then
		print("✅ Listed: " .. listingData.ItemName .. " x" .. listingData.Quantity)
		return true, listingId
	else
		warn("❌ Failed to list: " .. tostring(err))
		return false, nil
	end
end

-- ============================================
-- GET ALL LISTINGS
-- ============================================
function GlobalMarketplaceStore.GetAllListings(category, sortBy)
	local listings = {}
	local currentTime = os.time()

	local success, pages = pcall(function()
		return MarketplaceStore:ListKeysAsync(LISTING_PREFIX, 100)
	end)

	if not success then
		warn("❌ Failed to fetch listings")
		return {}
	end

	repeat
		local pageData = pages:GetCurrentPage()

		for _, keyInfo in ipairs(pageData) do
			local success, data = pcall(function()
				return MarketplaceStore:GetAsync(keyInfo.KeyName)
			end)

			if success and data then
				-- Check if listing expired
				local age = currentTime - (data.ListedAt or 0)
				if age < MAX_LISTING_AGE then
					-- Filter by category
					if not category or category == "All" or data.Category == category then
						table.insert(listings, data)
					end
				else
					-- Remove expired listing
					pcall(function()
						MarketplaceStore:RemoveAsync(keyInfo.KeyName)
					end)
					print("🗑️ Removed expired listing: " .. keyInfo.KeyName)
				end
			end
		end

		if not pages.IsFinished then
			pages:AdvanceToNextPageAsync()
		end
	until pages.IsFinished

	-- Sort listings
	if sortBy == "PriceLow" then
		table.sort(listings, function(a, b) return a.PricePerUnit < b.PricePerUnit end)
	elseif sortBy == "PriceHigh" then
		table.sort(listings, function(a, b) return a.PricePerUnit > b.PricePerUnit end)
	elseif sortBy == "Newest" then
		table.sort(listings, function(a, b) return (a.ListedAt or 0) > (b.ListedAt or 0) end)
	end

	print("📦 Loaded " .. #listings .. " listings")
	return listings
end

-- ============================================
-- REMOVE LISTING
-- ============================================
function GlobalMarketplaceStore.RemoveListing(listingId)
	local key = LISTING_PREFIX .. listingId

	local success, err = pcall(function()
		MarketplaceStore:RemoveAsync(key)
	end)

	if success then
		print("✅ Removed listing: " .. listingId)
		return true
	else
		warn("❌ Failed to remove listing: " .. tostring(err))
		return false
	end
end

-- ============================================
-- PURCHASE LISTING
-- ============================================
function GlobalMarketplaceStore.PurchaseListing(buyer, listingId)
	local key = LISTING_PREFIX .. listingId

	-- Use UpdateAsync for atomicity (prevents double-purchase)
	local success, result = pcall(function()
		return MarketplaceStore:UpdateAsync(key, function(oldData)
			if not oldData then
				return nil -- Already purchased/removed
			end

			-- Mark as sold
			oldData.Buyer = buyer.Name
			oldData.BuyerId = buyer.UserId
			oldData.SoldAt = os.time()

			-- Return updated data (will be immediately removed after processing)
			return nil -- Remove from store after purchase
		end)
	end)

	return success
end

print("✅ GlobalMarketplaceStore loaded")
return GlobalMarketplaceStore
