-- VIPListingServer.lua (Script)
-- Handles VIP quick-listing from Farm place
-- Location: ServerScriptService (Farm place)

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local GamePassConfig = require(ReplicatedStorage:WaitForChild("GamePassConfig"))
local GamePassManager = require(script.Parent:WaitForChild("GamePassManager"))
local GlobalMarketplaceStore = require(script.Parent:WaitForChild("GlobalMarketplaceStore"))
local ProductConfig = require(ReplicatedStorage:WaitForChild("ProductConfig"))

-- ============================================
-- CREATE REMOTE EVENTS
-- ============================================
local VIPListItemEvent = Instance.new("RemoteEvent")
VIPListItemEvent.Name = "VIPListItemEvent"
VIPListItemEvent.Parent = ReplicatedStorage

local CheckVIPFunction = Instance.new("RemoteFunction")
CheckVIPFunction.Name = "CheckVIPFunction"
CheckVIPFunction.Parent = ReplicatedStorage

-- ============================================
-- CHECK VIP STATUS
-- ============================================
CheckVIPFunction.OnServerInvoke = function(player)
	return GamePassManager.HasPass(player, "MarketplaceVIP")
end

-- ============================================
-- VIP LISTING HANDLER
-- ============================================
VIPListItemEvent.OnServerEvent:Connect(function(player, itemName, quantity, pricePerUnit, category)
	print("📦 VIP List request: " .. player.Name .. " - " .. itemName .. " x" .. quantity)

	-- Verify VIP status
	if not GamePassManager.HasPass(player, "MarketplaceVIP") then
		VIPListItemEvent:FireClient(player, "failed", "Marketplace VIP GamePass required!")
		print("❌ " .. player.Name .. " tried to VIP list without GamePass")
		return
	end

	-- Validate inputs
	if not itemName or quantity <= 0 or pricePerUnit <= 0 then
		VIPListItemEvent:FireClient(player, "failed", "Invalid listing data")
		return
	end

	-- Check if player actually has the items
	local inventory = nil
	local itemValue = nil

	-- Determine which inventory to check
	if category == "Crops" then
		inventory = player:FindFirstChild("CropInventory")
	elseif category == "Products" then
		inventory = player:FindFirstChild("ProductInventory")
	elseif category == "Fish" then
		inventory = player:FindFirstChild("FishInventory")
	elseif category == "Animals" then
		inventory = player:FindFirstChild("AnimalInventory")
	end

	if not inventory then
		VIPListItemEvent:FireClient(player, "failed", "Inventory not found")
		return
	end

	itemValue = inventory:FindFirstChild(itemName)
	if not itemValue or itemValue.Value < quantity then
		VIPListItemEvent:FireClient(player, "failed", "You don't have enough " .. itemName)
		return
	end

	-- Create listing data
	local listingData = {
		SellerName = player.Name,
		SellerId = player.UserId,
		ItemName = itemName,
		Quantity = quantity,
		PricePerUnit = pricePerUnit,
		Category = category,
		ListedAt = os.time(),
		IsVIPListing = true -- Flag for priority placement
	}

	-- Add to global marketplace
	local success, listingId = GlobalMarketplaceStore.AddListing(listingData)

	if success then
		-- Deduct items from inventory
		itemValue.Value = itemValue.Value - quantity

		print("✅ VIP Listed: " .. itemName .. " x" .. quantity .. " for $" .. pricePerUnit .. " each")

		-- Track marketplace listing quest
		local DailyQuestManager = require(script.Parent:WaitForChild("DailyQuestManager"))
		if DailyQuestManager then
			DailyQuestManager:UpdateMarketplaceListing(player, 1)
			print("📝 Tracked marketplace listing for quests")
		end


		VIPListItemEvent:FireClient(player, "success", "Listed successfully! ID: " .. listingId)

		-- Show confirmation
		local ShowTutorialEvent = ReplicatedStorage:FindFirstChild("ShowTutorialEvent")
		if ShowTutorialEvent then
			ShowTutorialEvent:FireClient(player, "VIPListed", {
				Title = "Listed on Marketplace! 🛍️",
				Message = itemName .. " x" .. quantity .. " listed for $" .. (quantity * pricePerUnit) .. " total",
				Duration = 4
			})
		end
	else
		VIPListItemEvent:FireClient(player, "failed", "Marketplace error - try again")
	end
end)

print("✅ VIP Listing Server ready")
