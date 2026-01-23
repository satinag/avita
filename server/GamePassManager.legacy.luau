-- GamePassManager.lua (Script)
-- Handles GamePass ownership checks and auto-sell processing
-- Location: ServerScriptService (Farm place)

local MarketplaceService = game:GetService("MarketplaceService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local GamePassConfig = require(ReplicatedStorage:WaitForChild("GamePassConfig"))
local DataStoreModule = require(script.Parent:WaitForChild("DataStoreModule"))

local GamePassManager = {}

-- Cache player GamePass ownership (reduces API calls)
local playerPassCache = {} -- {[userId] = {MarketplaceVIP = true, AutoSellGuarantee = false}}

-- ============================================
-- CHECK GAMEPASS OWNERSHIP
-- ============================================
function GamePassManager.HasPass(player, passName)
	local passData = GamePassConfig.GetPass(passName)
	if not passData then
		warn("❌ Invalid GamePass name: " .. tostring(passName))
		return false
	end

	-- Check cache first
	if playerPassCache[player.UserId] and playerPassCache[player.UserId][passName] ~= nil then
		return playerPassCache[player.UserId][passName]
	end

	-- Check with MarketplaceService
	local success, hasPass = pcall(function()
		return MarketplaceService:UserOwnsGamePassAsync(player.UserId, passData.ID)
	end)

	if success then
		-- Cache result
		playerPassCache[player.UserId] = playerPassCache[player.UserId] or {}
		playerPassCache[player.UserId][passName] = hasPass

		return hasPass
	else
		warn("⚠️ Failed to check GamePass for " .. player.Name)
		return false
	end
end

-- ============================================
-- PROMPT GAMEPASS PURCHASE
-- ============================================
function GamePassManager.PromptPurchase(player, passName)
	local passData = GamePassConfig.GetPass(passName)
	if not passData then return end

	local success = pcall(function()
		MarketplaceService:PromptGamePassPurchase(player, passData.ID)
	end)

	if not success then
		warn("⚠️ Failed to prompt GamePass purchase for " .. player.Name)
	end
end

-- ============================================
-- HANDLE GAMEPASS PURCHASES (Live)
-- ============================================
MarketplaceService.PromptGamePassPurchaseFinished:Connect(function(player, passId, wasPurchased)
	if not wasPurchased then return end

	-- Find which pass was purchased
	local passName = GamePassConfig.GetPassNameByID(passId)
	if not passName then return end

	-- Update cache
	playerPassCache[player.UserId] = playerPassCache[player.UserId] or {}
	playerPassCache[player.UserId][passName] = true

	-- Notify player
	local passData = GamePassConfig.GetPass(passName)
	print("✅ " .. player.Name .. " purchased: " .. passData.Name)

	-- Fire client event for UI update
	local GamePassPurchasedEvent = ReplicatedStorage:FindFirstChild("GamePassPurchasedEvent")
	if GamePassPurchasedEvent then
		GamePassPurchasedEvent:FireClient(player, passName)
	end

	-- Show thank you message
	local ShowTutorialEvent = ReplicatedStorage:FindFirstChild("ShowTutorialEvent")
	if ShowTutorialEvent then
		ShowTutorialEvent:FireClient(player, "GamePassPurchased", {
			Title = "Thank You! " .. passData.Icon,
			Message = "You now own " .. passData.Name .. "! Check your new abilities.",
			Duration = 5
		})
	end
end)

-- ============================================
-- AUTO-SELL PROCESSING (Background Loop)
-- ============================================
local function processAutoSellListings()
	local GlobalMarketplaceStore = require(script.Parent:WaitForChild("GlobalMarketplaceStore"))

	-- Get all listings
	local allListings = GlobalMarketplaceStore.GetAllListings()
	local currentTime = os.time()

	for _, listing in ipairs(allListings) do
		-- Check if listing is 1 game day old (24 real-world hours)
		local age = currentTime - (listing.ListedAt or 0)
		local ONE_DAY = 24 * 60 * 60 -- 24 hours in seconds

		if age >= ONE_DAY then
			-- Check if seller has Auto-Sell GamePass
			local seller = Players:FindFirstChild(listing.SellerName)

			-- If seller offline, try to load from cache or skip
			local hasAutoSell = false
			if seller then
				hasAutoSell = GamePassManager.HasPass(seller, "AutoSellGuarantee")
			else
				-- Check if we cached this player's pass status
				if playerPassCache[listing.SellerId] and playerPassCache[listing.SellerId].AutoSellGuarantee then
					hasAutoSell = true
				end
			end

			if hasAutoSell then
				-- Auto-sell the listing
				local totalPrice = listing.Quantity * listing.PricePerUnit

				-- Add money to seller (even if offline)
				local data = DataStoreModule.PlayerData[listing.SellerId]
				if data then
					-- Seller is online
					data.Cash = data.Cash + totalPrice
					data.TotalEarned = data.TotalEarned + totalPrice

					-- Update live values
					if seller then
						local cash = seller:FindFirstChild("leaderstats") and seller.leaderstats:FindFirstChild("Cash")
						local totalEarned = seller:FindFirstChild("TotalEarned")

						if cash then cash.Value = cash.Value + totalPrice end
						if totalEarned then totalEarned.Value = totalEarned.Value + totalPrice end

						-- Notify seller
						local ShowTutorialEvent = ReplicatedStorage:FindFirstChild("ShowTutorialEvent")
						if ShowTutorialEvent then
							ShowTutorialEvent:FireClient(seller, "AutoSold", {
								Title = "Auto-Sell Success! 💰",
								Message = "Your " .. listing.ItemName .. " x" .. listing.Quantity .. " sold for $" .. totalPrice .. "!",
								Duration = 5
							})
						end
					end

					print("💰 Auto-sold: " .. listing.ItemName .. " x" .. listing.Quantity .. " for $" .. totalPrice)
				else
					-- Seller is offline - load their data and save
					local offlineData = DataStoreModule:LoadData({UserId = listing.SellerId, Name = listing.SellerName})
					if offlineData then
						offlineData.Cash = offlineData.Cash + totalPrice
						offlineData.TotalEarned = offlineData.TotalEarned + totalPrice

						-- Save immediately
						local key = "Player_" .. listing.SellerId
						local PlayerDataStore = game:GetService("DataStoreService"):GetDataStore("PlayerData_v18.0.1")
						pcall(function()
							PlayerDataStore:SetAsync(key, offlineData)
						end)

						print("💰 Auto-sold (offline): " .. listing.SellerName .. " - $" .. totalPrice)
					end
				end

				-- Remove listing from marketplace
				GlobalMarketplaceStore.RemoveListing(listing.ListingId)
			else
				-- No GamePass - remove expired listing (7 days handled in GlobalMarketplaceStore)
				print("⏰ Old listing (no auto-sell): " .. listing.ItemName)
			end
		end
	end
end

-- Run auto-sell check every 10 minutes
task.spawn(function()
	while true do
		task.wait(600) -- 10 minutes

		local success, err = pcall(processAutoSellListings)
		if not success then
			warn("⚠️ Auto-sell processing error: " .. tostring(err))
		end
	end
end)

-- ============================================
-- REMOTE FUNCTIONS FOR CLIENT
-- ============================================

-- Check if player owns a specific pass
local CheckGamePassFunction = Instance.new("RemoteFunction")
CheckGamePassFunction.Name = "CheckGamePassFunction"
CheckGamePassFunction.Parent = ReplicatedStorage

CheckGamePassFunction.OnServerInvoke = function(player, passName)
	return GamePassManager.HasPass(player, passName)
end

-- Prompt GamePass purchase
local PromptGamePassEvent = Instance.new("RemoteEvent")
PromptGamePassEvent.Name = "PromptGamePassEvent"
PromptGamePassEvent.Parent = ReplicatedStorage

PromptGamePassEvent.OnServerEvent:Connect(function(player, passName)
	GamePassManager.PromptPurchase(player, passName)
end)

-- Create event for purchase notifications
local GamePassPurchasedEvent = Instance.new("RemoteEvent")
GamePassPurchasedEvent.Name = "GamePassPurchasedEvent"
GamePassPurchasedEvent.Parent = ReplicatedStorage

-- ============================================
-- PLAYER INITIALIZATION
-- ============================================
Players.PlayerAdded:Connect(function(player)
	-- Pre-cache GamePass ownership on join
	task.spawn(function()
		task.wait(2) -- Wait for player to fully load

		for passName, _ in pairs(GamePassConfig.PASSES) do
			GamePassManager.HasPass(player, passName)
		end

		print("✅ GamePass cache loaded for " .. player.Name)
	end)
end)

-- Clear cache on leave
Players.PlayerRemoving:Connect(function(player)
	playerPassCache[player.UserId] = nil
end)

print("✅ GamePassManager loaded - Auto-sell running every 10 minutes")
return GamePassManager
