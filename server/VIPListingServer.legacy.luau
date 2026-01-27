-- VIPListingServer.lua (DELAYED LISTING SYSTEM)
-- Farm VIP Quick-Sell → Creates pending listings (paid in 12 game hours)
-- Location: ServerScriptService (Farm place)

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local DataStoreService = game:GetService("DataStoreService")
local HttpService = game:GetService("HttpService")

local TownBuildingConfig = require(ReplicatedStorage:WaitForChild("TownBuildingConfig"))
local ProductConfig = require(ReplicatedStorage:WaitForChild("ProductConfig"))
local GamePassConfig = require(ReplicatedStorage:WaitForChild("GamePassConfig"))

-- Use GLOBAL scope accessible from both places
local PendingListingsStore = DataStoreService:GetDataStore("GlobalPendingListings", "global")

-- ✅ CHANGED: 12 hours in GAME MINUTES (not seconds)
local PAYMENT_DELAY_MINUTES = 720 -- 12 game hours = 720 game minutes

-- Create RemoteEvents
local VIPQuickSellEvent = ReplicatedStorage:FindFirstChild("VIPQuickSellEvent")
if not VIPQuickSellEvent then
	VIPQuickSellEvent = Instance.new("RemoteEvent")
	VIPQuickSellEvent.Name = "VIPQuickSellEvent"
	VIPQuickSellEvent.Parent = ReplicatedStorage
end

local CheckVIPStatusEvent = ReplicatedStorage:FindFirstChild("CheckVIPStatusEvent")
if not CheckVIPStatusEvent then
	CheckVIPStatusEvent = Instance.new("RemoteFunction")
	CheckVIPStatusEvent.Name = "CheckVIPStatusEvent"
	CheckVIPStatusEvent.Parent = ReplicatedStorage
end

print("🌟 VIPListingServer (Delayed Payment) loading...")

-- ============================================
-- HELPER FUNCTIONS
-- ============================================

local function hasVIP(player)
	local vipPass = GamePassConfig.GetPass("MarketplaceVIP")
	if not vipPass then return false end

	local success, owns = pcall(function()
		return game:GetService("MarketplaceService"):UserOwnsGamePassAsync(player.UserId, vipPass.ID)
	end)

	return success and owns
end

-- ✅ NEW: Format game minutes to readable time
local function formatMinutesToTime(minutes)
	local hours = math.floor(minutes / 60)
	local mins = minutes % 60
	local period = hours >= 12 and "PM" or "AM"
	if hours > 12 then hours = hours - 12 end
	if hours == 0 then hours = 12 end
	return string.format("%d:%02d %s", hours, mins, period)
end

-- ✅ CHANGED: Returns game time in MINUTES
local function getPlayerGameTime(player)
	if _G.getCurrentTime then
		return _G.getCurrentTime(player) -- Returns MINUTES (e.g., 660 = 11:00 AM)
	end
	return 0
end

local function getBuildingForItem(itemName, category)
	for _, building in ipairs(TownBuildingConfig.BUILDINGS) do
		if TownBuildingConfig.IsItemAccepted(building.ID, itemName, category) then
			return building
		end
	end
	return nil
end

-- ============================================
-- CHECK VIP STATUS
-- ============================================
CheckVIPStatusEvent.OnServerInvoke = function(player)
	return hasVIP(player)
end

-- ============================================
-- VIP QUICK-SELL (Creates Pending Listings)
-- ============================================
VIPQuickSellEvent.OnServerEvent:Connect(function(player, items)
	print("🌟 VIP Quick-Sell (Delayed):", player.Name)

	if not hasVIP(player) then
		warn(player.Name .. " tried Quick-Sell without VIP")
		return
	end

	local leaderstats = player:FindFirstChild("leaderstats")
	local cash = leaderstats and leaderstats:FindFirstChild("Cash")
	if not cash then
		warn("No cash leaderstat for", player.Name)
		return
	end

	-- ✅ CHANGED: Get game time in MINUTES
	local currentGameTime = getPlayerGameTime(player)
	local payoutGameTime = currentGameTime + PAYMENT_DELAY_MINUTES

	print("⏰ VIP Listing created:")
	print("   Current game time:", currentGameTime, "minutes (" .. formatMinutesToTime(currentGameTime) .. ")")
	print("   Payout game time:", payoutGameTime, "minutes (" .. formatMinutesToTime(payoutGameTime) .. ")")
	print("   Delay:", PAYMENT_DELAY_MINUTES / 60, "game hours")

	local totalPending = 0
	local listingsCreated = {}

	for itemName, quantity in pairs(items) do
		if quantity <= 0 then continue end

		-- Determine category + inventory
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
			warn("Quick-Sell: item not found:", itemName)
			continue
		end

		local valueObj = inventory:FindFirstChild(itemName)
		if not valueObj or valueObj.Value <= 0 then
			warn("Quick-Sell: no stock of", itemName)
			continue
		end

		local sellQty = math.min(quantity, valueObj.Value)

		-- Find Town building
		local building = getBuildingForItem(itemName, category)
		if not building then
			warn("Quick-Sell: no Town building accepts", itemName)
			continue
		end

		-- ✅ PERFECT PRICE LOOKUP FOR YOUR CONFIG
		local basePrice = 0

		-- 1️⃣ PRODUCTS (Eggs, Milk, Meat, Wool, Honey, Wax)
		if ProductConfig.PRODUCTS and ProductConfig.PRODUCTS[itemName] then
			basePrice = ProductConfig.PRODUCTS[itemName].SellPrice or 0
			print("✅ PRODUCTS:", itemName, "→", basePrice)

			-- 2️⃣ CROPS (Potato, Corn, Wheat)
		elseif ProductConfig.CROPS and ProductConfig.CROPS[itemName] then
			basePrice = ProductConfig.CROPS[itemName].SellPrice or 0
			print("✅ CROPS:", itemName, "→", basePrice)

			-- 3️⃣ FISH (Salmon, Tuna)
		elseif ProductConfig.FISH and ProductConfig.FISH[itemName] then
			basePrice = ProductConfig.FISH[itemName].SellPrice or 0
			print("✅ FISH:", itemName, "→", basePrice)

		else
			warn("❌ No price for:", itemName)
			continue
		end

		if basePrice <= 0 then
			warn("❌ Zero price for:", itemName)
			continue
		end

		local townUnitPrice = math.floor(basePrice * (building.PriceMultiplier or 1.2))
		local earnings = townUnitPrice * sellQty

		print("💰", itemName, "@", townUnitPrice, "x", sellQty, "=", earnings)


		-- Deduct stock IMMEDIATELY
		valueObj.Value = valueObj.Value - sellQty

		-- ✅ CHANGED: Create listing with GAME TIME (minutes)
		local listingId = HttpService:GenerateGUID(false)
		local listing = {
			ListingId = listingId,
			PlayerUserId = player.UserId,
			PlayerName = player.Name,
			BuildingId = building.ID,
			ItemName = itemName,
			Category = category,
			Quantity = sellQty,
			PricePerUnit = townUnitPrice,
			TotalEarnings = earnings,
			CreatedAt = currentGameTime,      -- ✅ Game minutes
			PayoutTime = payoutGameTime,      -- ✅ Game minutes
			Status = "Pending" -- "Pending", "Paid", "Cancelled"
		}

		-- Save to DataStore
		pcall(function()
			PendingListingsStore:SetAsync("Listing_" .. listingId, listing)
		end)

		totalPending = totalPending + earnings
		table.insert(listingsCreated, {
			Name = itemName,
			Quantity = sellQty,
			Price = townUnitPrice,
			Total = earnings,
			Building = building.Name
		})

		-- Tutorial: also count Quick-Sell as first barn sale (Level 6)
		if _G.CompleteTutorialLevel then
			local currentLevel = player:FindFirstChild("CurrentArrowLevel")
			if currentLevel and currentLevel.Value == 6 then
				print("🎯 Completing tutorial level 6 via Quick-Sell")
				_G.CompleteTutorialLevel(player, 6)
			end
		end


		print("  ✅ Created listing:", sellQty, itemName, "@", building.Name, "for $" .. earnings)
	end

	if totalPending <= 0 then
		print("Quick-Sell: nothing listed for", player.Name)
		return
	end

	print("✅ VIP Quick-Sell complete:", player.Name, "pending $" .. totalPending)

	-- Send confirmation to client
	local ShowTutorialEvent = ReplicatedStorage:FindFirstChild("ShowTutorialEvent")
	if ShowTutorialEvent then
		local hoursText = "12 game hours"
		local msg = "Listed " .. #listingsCreated .. " items for $" .. totalPending .. "\n\n💰 Payment in " .. hoursText
		ShowTutorialEvent:FireClient(player, "VIPQuickSellSuccess", {
			Title = "🌟 Listed for Sale",
			Message = msg,
			Duration = 5
		})
	end
end)

-- ============================================
-- AUTO-PAYMENT LOOP (Runs every 60 seconds)
-- ============================================
task.spawn(function()
	while true do
		task.wait(60) -- Check every real minute

		print("🔍 Checking for listings ready to pay...")

		local success, pages = pcall(function()
			return PendingListingsStore:ListKeysAsync("Listing_", 100)
		end)

		if not success then
			warn("❌ Failed to fetch pending listings:", pages)
			continue
		end

		local checkedCount = 0
		local paidCount = 0

		repeat
			local pageData = pages:GetCurrentPage()

			for _, keyInfo in ipairs(pageData) do
				local listingSuccess, listing = pcall(function()
					return PendingListingsStore:GetAsync(keyInfo.KeyName)
				end)

				if listingSuccess and listing and listing.Status == "Pending" then
					checkedCount = checkedCount + 1

					-- ✅ FIXED: Get current GAME TIME from first online player
					local players = Players:GetPlayers()
					if #players == 0 then
						print("⚠️ No players online, skipping payment check")
						continue
					end

					local anyPlayer = players[1]
					print("⏰ Using player", anyPlayer.Name, "for time check")

					local currentGameTime = getPlayerGameTime(anyPlayer)
					print("⏰ Current game time:", currentGameTime)

					local timeRemaining = listing.PayoutTime - currentGameTime

					-- Convert to game hours for display
					local hoursRemaining = timeRemaining / 60

					print("⏰", listing.PlayerName, "-", listing.ItemName, "- Game time left:", string.format("%.1f", hoursRemaining), "hours")

					-- ✅ CHANGED: Check if payment time reached (in GAME MINUTES)
					if currentGameTime >= listing.PayoutTime then
						-- PAY THE PLAYER
						local player = Players:GetPlayerByUserId(listing.PlayerUserId)

						if player then
							-- Player online - pay directly
							local cash = player:FindFirstChild("Cash")
							if cash then
								cash.Value = cash.Value + listing.TotalEarnings
								print("💰 Paid listing:", listing.PlayerName, "$" .. listing.TotalEarnings)

								paidCount = paidCount + 1

								-- Notify player
								local ShowTutorialEvent = ReplicatedStorage:FindFirstChild("ShowTutorialEvent")
								if ShowTutorialEvent then
									ShowTutorialEvent:FireClient(player, "ListingPaid", {
										Title = "💰 Payment Received",
										Message = "Sold " .. listing.Quantity .. " " .. listing.ItemName .. " for $" .. listing.TotalEarnings .. "!",
										Duration = 4
									})
								end
							else
								warn("❌ Player", listing.PlayerName, "has no Cash value")
							end
						else
							-- Player offline - save to DataStore
							local DataStoreModule = require(game.ServerScriptService:FindFirstChild("DataStoreModule"))
							if DataStoreModule and DataStoreModule.LoadDataUserId then
								local playerData = DataStoreModule.LoadDataUserId(listing.PlayerUserId, listing.PlayerName)
								if playerData then
									playerData.Cash = (playerData.Cash or 0) + listing.TotalEarnings
									playerData.TotalEarned = (playerData.TotalEarned or 0) + listing.TotalEarnings

									-- Save to DataStore
									local saveSuccess = pcall(function()
										local PlayerDataStore = DataStoreService:GetDataStore("PlayerData_v18.0.2")
										PlayerDataStore:SetAsync("Player_" .. listing.PlayerUserId, playerData)
									end)

									if saveSuccess then
										print("💰 Paid offline listing:", listing.PlayerName, "$" .. listing.TotalEarnings)
										paidCount = paidCount + 1
									else
										warn("❌ Failed to save offline payment for", listing.PlayerName)
									end
								else
									warn("❌ Could not load data for offline player:", listing.PlayerName)
								end
							else
								warn("❌ DataStoreModule not found or LoadDataUserId missing")
							end
						end

						-- Mark as paid
						listing.Status = "Paid"
						listing.PaidAt = currentGameTime -- ✅ Game minutes

						local updateSuccess = pcall(function()
							PendingListingsStore:SetAsync(keyInfo.KeyName, listing)
						end)

						if not updateSuccess then
							warn("❌ Failed to update listing status to Paid")
						end

						-- Delete paid listings after 24 game hours (1440 minutes)
						task.delay(60, function()
							local deleteGameTime = currentGameTime + 1440 -- 24 game hours

							-- Wait until 24 game hours pass
							while true do
								task.wait(60)
								local checkPlayer = next(Players:GetPlayers())
								if checkPlayer and getPlayerGameTime(checkPlayer) >= deleteGameTime then
									break
								end
							end

							pcall(function()
								PendingListingsStore:RemoveAsync(keyInfo.KeyName)
								print("🗑️ Deleted old paid listing:", keyInfo.KeyName)
							end)
						end)
					end
				end
			end

			if not pages.IsFinished then
				pages:AdvanceToNextPageAsync()
			end
		until pages.IsFinished

		if checkedCount > 0 then
			print("✅ Payment check complete:", paidCount, "paid out of", checkedCount, "pending")
		end
	end
end)


print("✅ VIPListingServer (Delayed Payment) ready!")
