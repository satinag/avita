-- TownShopClient.lua (Town Place - LocalScript)
-- Handles Town shop UI with delayed listings (no cooldowns)
-- Location: StarterPlayerScripts (Town place)

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

-- Wait for modules and events
local TownBuildingConfig = require(ReplicatedStorage:WaitForChild("TownBuildingConfig"))
local ProductConfig = require(ReplicatedStorage:WaitForChild("ProductConfig"))

local OpenTownShopEvent = ReplicatedStorage:WaitForChild("OpenTownShopEvent")
local SellToTownShopEvent = ReplicatedStorage:WaitForChild("SellToTownShopEvent")

print("✅ TownShopClient loaded!")

-- GUI Config
local GUICONFIG = {
	IsMobile = UserInputService.TouchEnabled and not UserInputService.KeyboardEnabled,
	BackgroundColor = Color3.fromRGB(40, 40, 40),
	HeaderColor = Color3.fromRGB(60, 60, 60),
	SellButtonColor = Color3.fromRGB(80, 200, 80),
	LockedColor = Color3.fromRGB(100, 100, 100),
	TextColor = Color3.fromRGB(255, 255, 255),
}

-- State
local currentBuilding = nil
local currentGui = nil

-- Helpers
local function formatNumber(num)
	local formatted = tostring(math.floor(num))
	return formatted:reverse():gsub("(%d%d%d)", "%1,"):reverse():gsub("^,", "")
end

local function formatCash(amount)
	return "$" .. formatNumber(amount)
end

local function getPlayerInventory()
	local inventory = {}

	-- Crops
	local cropInventory = player:FindFirstChild("CropInventory")
	if cropInventory then
		for _, cropValue in pairs(cropInventory:GetChildren()) do
			if cropValue:IsA("IntValue") and cropValue.Value > 0 then
				table.insert(inventory, {
					Name = cropValue.Name,
					Count = cropValue.Value,
					Category = "Crops"
				})
			end
		end
	end

	-- Products
	local productInventory = player:FindFirstChild("ProductInventory")
	if productInventory then
		for _, productValue in pairs(productInventory:GetChildren()) do
			if productValue:IsA("IntValue") and productValue.Value > 0 then
				table.insert(inventory, {
					Name = productValue.Name,
					Count = productValue.Value,
					Category = "Products"
				})
			end
		end
	end

	-- Fish
	local fishInventory = player:FindFirstChild("FishInventory")
	if fishInventory then
		for _, fishValue in pairs(fishInventory:GetChildren()) do
			if fishValue:IsA("IntValue") and fishValue.Value > 0 then
				table.insert(inventory, {
					Name = fishValue.Name,
					Count = fishValue.Value,
					Category = "Fish"
				})
			end
		end
	end

	return inventory
end

-- Get current game time (for countdown display)
local function getCurrentGameTime()
	-- ✅ PRIORITY 1: Try player-specific time
	if _G.getCurrentTime and player then
		local currentTime = _G.getCurrentTime(player)
		if currentTime and currentTime > 0 then
			print("✅ Using _G.getCurrentTime(player):", currentTime)
			return currentTime
		end
	end

	-- ✅ PRIORITY 2: Try global time
	if _G.getCurrentTime then
		local currentTime = _G.getCurrentTime()
		if currentTime and currentTime > 0 then
			print("✅ Using _G.getCurrentTime():", currentTime)
			return currentTime
		end
	end

	-- ✅ PRIORITY 3: Server fallback
	local GetCurrentTimeEvent = ReplicatedStorage:FindFirstChild("GetCurrentTimeEvent")
	if GetCurrentTimeEvent then
		local success, time = pcall(function()
			return GetCurrentTimeEvent:InvokeServer()
		end)
		if success and time and time > 0 then
			print("✅ Using server time:", time)
			return time
		end
	end

	print("⚠️ All time methods failed, using 0")
	return 0
end




-- Get player's listings for this building
local function getPlayerListings(buildingId)
	local GetPlayerListingsEvent = ReplicatedStorage:FindFirstChild("GetPlayerListingsEvent")
	if not GetPlayerListingsEvent then 
		warn("❌ GetPlayerListingsEvent not found")
		return {} 
	end

	local success, listings = pcall(function()
		return GetPlayerListingsEvent:InvokeServer(buildingId)
	end)

	if not success then
		warn("❌ Failed to get listings:", listings)
		return {}
	end

	return listings or {}
end

-- Format time remaining for countdown
local function formatTimeRemaining(seconds)
	if seconds <= 0 then
		return "Ready!"
	end

	local hours = math.floor(seconds / 3600)
	local minutes = math.floor((seconds % 3600) / 60)
	local secs = math.floor(seconds % 60)

	if hours > 0 then
		return string.format("%dh %dm", hours, minutes)
	elseif minutes > 0 then
		return string.format("%dm %ds", minutes, secs)
	else
		return string.format("%ds", secs)
	end
end

-- Update listing countdown timers
local function updateListingCountdowns(listingsFrame)
	while listingsFrame and listingsFrame.Parent do
		for _, itemFrame in pairs(listingsFrame:GetChildren()) do
			if itemFrame:IsA("Frame") and itemFrame:FindFirstChild("CountdownLabel") then
				local countdownLabel = itemFrame.CountdownLabel
				local payoutTime = itemFrame:GetAttribute("PayoutTime")

				if payoutTime then
					local currentTime = getCurrentGameTime()
					local timeRemaining = payoutTime - currentTime

					if timeRemaining > 0 then
						countdownLabel.Text = "⏳ " .. formatTimeRemaining(timeRemaining)
						countdownLabel.TextColor3 = Color3.fromRGB(255, 200, 100)
					else
						countdownLabel.Text = "✅ Ready to collect!"
						countdownLabel.TextColor3 = Color3.fromRGB(100, 255, 100)
					end
				end
			end
		end
		task.wait(1)
	end
end


-- Create Shop GUI (WITH LISTINGS)
local function createShopGUI(buildingId)
	print("🏪 Creating shop GUI for:", buildingId)

	-- Clean up existing GUI
	if currentGui then
		currentGui:Destroy()
		currentGui = nil
	end

	if cooldownUpdateConnection then
		cooldownUpdateConnection:Disconnect()
		cooldownUpdateConnection = nil
	end

	local building = TownBuildingConfig.GetBuilding(buildingId)
	if not building then
		warn("❌ Invalid building: " .. tostring(buildingId))
		return
	end

	currentBuilding = building

	-- Get player's listings for this building
	local playerListings = getPlayerListings(buildingId)

	-- Create ScreenGui
	local screenGui = Instance.new("ScreenGui")
	screenGui.Name = "TownShopGui"
	screenGui.ResetOnSpawn = false
	screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	currentGui = screenGui

	-- Main Frame
	local mainFrame = Instance.new("Frame")
	mainFrame.Name = "MainFrame"
	mainFrame.Size = UDim2.new(GUICONFIG.IsMobile and 0.95 or 0.7, 0, GUICONFIG.IsMobile and 0.9 or 0.8, 0)
	mainFrame.Position = UDim2.new(0.5, 0, 0.5, 0)
	mainFrame.AnchorPoint = Vector2.new(0.5, 0.5)
	mainFrame.BackgroundColor3 = GUICONFIG.BackgroundColor
	mainFrame.BorderSizePixel = 0
	mainFrame.Parent = screenGui

	local mainCorner = Instance.new("UICorner")
	mainCorner.CornerRadius = UDim.new(0, 12)
	mainCorner.Parent = mainFrame

	-- Header
	local header = Instance.new("Frame")
	header.Name = "Header"
	header.Size = UDim2.new(1, 0, 0, 60)
	header.BackgroundColor3 = building.Color or GUICONFIG.HeaderColor
	header.BorderSizePixel = 0
	header.Parent = mainFrame

	local headerCorner = Instance.new("UICorner")
	headerCorner.CornerRadius = UDim.new(0, 12)
	headerCorner.Parent = header

	-- Title
	local title = Instance.new("TextLabel")
	title.Size = UDim2.new(0.8, 0, 1, 0)
	title.Position = UDim2.new(0.05, 0, 0, 0)
	title.BackgroundTransparency = 1
	title.Text = (building.Icon or "") .. " " .. building.Name
	title.TextColor3 = GUICONFIG.TextColor
	title.TextScaled = true
	title.Font = Enum.Font.GothamBold
	title.TextXAlignment = Enum.TextXAlignment.Left
	title.Parent = header

	local titlePadding = Instance.new("UIPadding")
	titlePadding.PaddingLeft = UDim.new(0, 10)
	titlePadding.Parent = title

	-- Close Button
	local closeButton = Instance.new("TextButton")
	closeButton.Size = UDim2.new(0, 50, 0, 50)
	closeButton.Position = UDim2.new(1, -55, 0, 5)
	closeButton.BackgroundColor3 = Color3.fromRGB(200, 80, 80)
	closeButton.Text = "✕"
	closeButton.TextColor3 = GUICONFIG.TextColor
	closeButton.TextScaled = true
	closeButton.Font = Enum.Font.GothamBold
	closeButton.Parent = header

	local closeCorner = Instance.new("UICorner")
	closeCorner.CornerRadius = UDim.new(1, 0)
	closeCorner.Parent = closeButton

	closeButton.MouseButton1Click:Connect(function()
		screenGui:Destroy()
		currentGui = nil
	end)

	-- Description
	local description = Instance.new("TextLabel")
	description.Size = UDim2.new(1, -20, 0, 25)
	description.Position = UDim2.new(0, 10, 0, 70)
	description.BackgroundTransparency = 1
	description.Text = building.Description or ""
	description.TextColor3 = Color3.fromRGB(200, 200, 200)
	description.TextScaled = true
	description.Font = Enum.Font.Gotham
	description.Parent = mainFrame

	-- ============================================
	-- YOUR LISTINGS SECTION
	-- ============================================
	if #playerListings > 0 then
		local listingsFrame = Instance.new("Frame")
		listingsFrame.Name = "ListingsFrame"
		listingsFrame.Size = UDim2.new(1, -40, 0, 140)  -- ✅ Taller for real-time label
		listingsFrame.Position = UDim2.new(0, 20, 0, 105)
		listingsFrame.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
		listingsFrame.BorderSizePixel = 0
		listingsFrame.Parent = mainFrame

		local listingsCorner = Instance.new("UICorner")
		listingsCorner.CornerRadius = UDim.new(0, 8)
		listingsCorner.Parent = listingsFrame

		local listingsTitle = Instance.new("TextLabel")
		listingsTitle.Size = UDim2.new(1, -10, 0, 25)
		listingsTitle.Position = UDim2.new(0, 5, 0, 5)
		listingsTitle.BackgroundTransparency = 1
		listingsTitle.Text = "📋 Your Pending Listings (" .. #playerListings .. ")"
		listingsTitle.TextColor3 = Color3.fromRGB(255, 200, 100)
		listingsTitle.TextScaled = true
		listingsTitle.Font = Enum.Font.GothamBold
		listingsTitle.TextXAlignment = Enum.TextXAlignment.Left
		listingsTitle.Parent = listingsFrame

		-- ✅ NEW: Real-time explanation
		local realtimeLabel = Instance.new("TextLabel")
		realtimeLabel.Size = UDim2.new(1, -10, 0, 15)
		realtimeLabel.Position = UDim2.new(0, 5, 0, 28)
		realtimeLabel.BackgroundTransparency = 1
		realtimeLabel.Text = "⏰ (Real-Time Countdown)"
		realtimeLabel.TextColor3 = Color3.fromRGB(150, 200, 255)
		realtimeLabel.TextSize = 10
		realtimeLabel.Font = Enum.Font.Gotham
		realtimeLabel.TextXAlignment = Enum.TextXAlignment.Left
		realtimeLabel.Parent = listingsFrame

		local listingsScroll = Instance.new("ScrollingFrame")
		listingsScroll.Name = "ListingsScrollFrame"
		listingsScroll.Size = UDim2.new(1, -10, 0, 95)  -- Adjusted height
		listingsScroll.Position = UDim2.new(0, 5, 0, 45)  -- Moved down
		listingsScroll.BackgroundTransparency = 1
		listingsScroll.BorderSizePixel = 0
		listingsScroll.ScrollBarThickness = 6
		listingsScroll.Parent = listingsFrame

		local listLayout2 = Instance.new("UIListLayout")
		listLayout2.Padding = UDim.new(0, 5)
		listLayout2.FillDirection = Enum.FillDirection.Horizontal
		listLayout2.Parent = listingsScroll

		for _, listing in ipairs(playerListings) do
			if not listing or not listing.PayoutTime or not listing.ItemName then
				warn("❌ Invalid listing data:", listing and listing.ItemName or "unknown")
				continue
			end

			local currentTime = getCurrentGameTime()
			if not currentTime then
				currentTime = 0
				warn("⚠️ getCurrentGameTime() failed, using 0")
			end

			local timeRemaining = listing.PayoutTime - currentTime

			print("📋 Listing:", listing.ItemName, "- PayoutTime:", listing.PayoutTime, "- Current:", currentTime, "- Remaining:", timeRemaining)

			local listingCard = Instance.new("Frame")
			listingCard.Size = UDim2.new(0, 180, 1, -5)
			listingCard.BackgroundColor3 = Color3.fromRGB(70, 70, 70)
			listingCard.BorderSizePixel = 0
			listingCard:SetAttribute("PayoutTime", listing.PayoutTime)
			listingCard.Parent = listingsScroll

			local cardCorner = Instance.new("UICorner")
			cardCorner.CornerRadius = UDim.new(0, 6)
			cardCorner.Parent = listingCard

			local listingText = Instance.new("TextLabel")
			listingText.Size = UDim2.new(1, -10, 0, 35)
			listingText.Position = UDim2.new(0, 5, 0, 5)
			listingText.BackgroundTransparency = 1
			listingText.Text = listing.Quantity .. "x " .. listing.ItemName .. "\n💰 $" .. (listing.TotalEarnings or "0")
			listingText.TextColor3 = GUICONFIG.TextColor
			listingText.TextSize = 12
			listingText.Font = Enum.Font.Gotham
			listingText.TextWrapped = true
			listingText.Parent = listingCard

			local timeLabel = Instance.new("TextLabel")
			timeLabel.Name = "CountdownLabel"
			timeLabel.Size = UDim2.new(1, -10, 0, 15)
			timeLabel.Position = UDim2.new(0, 5, 0, 42)
			timeLabel.BackgroundTransparency = 1
			timeLabel.Text = "⏳ " .. formatTimeRemaining(timeRemaining)
			timeLabel.TextColor3 = Color3.fromRGB(255, 200, 100)
			timeLabel.TextSize = 10
			timeLabel.Font = Enum.Font.Gotham
			timeLabel.Parent = listingCard

			local cancelBtn = Instance.new("TextButton")
			cancelBtn.Size = UDim2.new(1, -10, 0, 18)
			cancelBtn.Position = UDim2.new(0, 5, 1, -23)
			cancelBtn.BackgroundColor3 = Color3.fromRGB(200, 80, 80)
			cancelBtn.Text = "Cancel"
			cancelBtn.TextColor3 = Color3.new(1, 1, 1)
			cancelBtn.TextSize = 12
			cancelBtn.Font = Enum.Font.GothamBold
			cancelBtn.Parent = listingCard

			local cancelCorner = Instance.new("UICorner")
			cancelCorner.CornerRadius = UDim.new(0, 4)
			cancelCorner.Parent = cancelBtn

			cancelBtn.MouseButton1Click:Connect(function()
				cancelBtn.Text = "Canceling..."
				local CancelListingEvent = ReplicatedStorage:FindFirstChild("CancelListingEvent")
				if CancelListingEvent then
					CancelListingEvent:FireServer(listing.ListingId)
					task.wait(0.5)
					createShopGUI(buildingId)
				end
			end)
		end

		listingsScroll.CanvasSize = UDim2.new(0, listLayout2.AbsoluteContentSize.X, 0, 0)

		-- ✅ IMPROVED COUNTDOWN UPDATER (runs every 5 seconds)
		task.spawn(function()
			while listingsFrame.Parent do
				updateListingCountdowns(listingsScroll)
				task.wait(5)  -- Check every 5 seconds (more efficient)
			end
		end)
	else
		-- Empty state
		local emptyLabel = Instance.new("TextLabel")
		emptyLabel.Size = UDim2.new(1, -40, 0, 60)
		emptyLabel.Position = UDim2.new(0, 20, 0, 105)
		emptyLabel.BackgroundTransparency = 1
		emptyLabel.Text = "📋 No pending listings\n\nList items from your Farm to sell here!"
		emptyLabel.TextColor3 = Color3.fromRGB(150, 150, 150)
		emptyLabel.TextScaled = true
		emptyLabel.Font = Enum.Font.Gotham
		emptyLabel.TextXAlignment = Enum.TextXAlignment.Center
		emptyLabel.Parent = mainFrame
	end


	-- ============================================
	-- SELL MORE SECTION
	-- ============================================
	local sellSectionY = #playerListings > 0 and 235 or 105

	local scrollFrame = Instance.new("ScrollingFrame")
	scrollFrame.Name = "InventoryScroll"
	scrollFrame.Size = UDim2.new(1, -40, 1, -(sellSectionY + 90))
	scrollFrame.Position = UDim2.new(0, 20, 0, sellSectionY)
	scrollFrame.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
	scrollFrame.BorderSizePixel = 0
	scrollFrame.ScrollBarThickness = 8
	scrollFrame.Parent = mainFrame

	local scrollCorner = Instance.new("UICorner")
	scrollCorner.CornerRadius = UDim.new(0, 8)
	scrollCorner.Parent = scrollFrame

	local listLayout = Instance.new("UIListLayout")
	listLayout.Padding = UDim.new(0, 10)
	listLayout.SortOrder = Enum.SortOrder.LayoutOrder
	listLayout.Parent = scrollFrame

	-- Get player inventory
	local inventory = getPlayerInventory()

	-- Filter items accepted by this shop
	local acceptedItems = {}
	local totalValue = 0

	for _, item in ipairs(inventory) do
		if TownBuildingConfig.IsItemAccepted(buildingId, item.Name, item.Category) then
			local basePrice = 0
			if ProductConfig.GetSellPrice then
				basePrice = ProductConfig.GetSellPrice(item.Name)
			else
				local data = ProductConfig.GetCropData and ProductConfig.GetCropData(item.Name)
					or ProductConfig.GetProductData and ProductConfig.GetProductData(item.Name)
					or ProductConfig.GetFishData and ProductConfig.GetFishData(item.Name)
				basePrice = data and data.SellPrice or 0
			end

			if basePrice > 0 then
				local townPrice = math.floor(basePrice * building.PriceMultiplier)
				local itemTotal = townPrice * item.Count

				table.insert(acceptedItems, {
					Name = item.Name,
					Count = item.Count,
					Category = item.Category,
					BasePrice = basePrice,
					TownPrice = townPrice,
					Total = itemTotal
				})

				totalValue = totalValue + itemTotal
			end
		end
	end

	if #acceptedItems == 0 then
		-- No items
		local emptyLabel = Instance.new("TextLabel")
		emptyLabel.Size = UDim2.new(1, 0, 0, 100)
		emptyLabel.BackgroundTransparency = 1
		emptyLabel.Text = "No items to sell here!\n\n" .. (building.Description or "")
		emptyLabel.TextColor3 = Color3.fromRGB(150, 150, 150)
		emptyLabel.TextScaled = true
		emptyLabel.Font = Enum.Font.Gotham
		emptyLabel.Parent = scrollFrame
	else
		-- Show items (same as before, keeping your existing code)
		for i, item in ipairs(acceptedItems) do
			local itemCard = Instance.new("Frame")
			itemCard.Size = UDim2.new(1, -10, 0, GUICONFIG.IsMobile and 90 or 80)
			itemCard.BackgroundColor3 = Color3.fromRGB(70, 70, 70)
			itemCard.BorderSizePixel = 0
			itemCard.LayoutOrder = i
			itemCard.Parent = scrollFrame

			local cardCorner = Instance.new("UICorner")
			cardCorner.CornerRadius = UDim.new(0, 8)
			cardCorner.Parent = itemCard

			local emoji = ""
			local data = ProductConfig.GetCropData and ProductConfig.GetCropData(item.Name)
				or ProductConfig.GetProductData and ProductConfig.GetProductData(item.Name)
				or ProductConfig.GetFishData and ProductConfig.GetFishData(item.Name)
			if data and data.Emoji then
				emoji = data.Emoji
			elseif data and data.Icon then
				emoji = data.Icon
			end

			local nameLabel = Instance.new("TextLabel")
			nameLabel.Size = UDim2.new(0.5, 0, 0.35, 0)
			nameLabel.Position = UDim2.new(0.02, 0, 0.1, 0)
			nameLabel.BackgroundTransparency = 1
			nameLabel.Text = emoji .. " " .. item.Name .. " x" .. item.Count
			nameLabel.TextColor3 = GUICONFIG.TextColor
			nameLabel.TextScaled = true
			nameLabel.Font = Enum.Font.GothamBold
			nameLabel.TextXAlignment = Enum.TextXAlignment.Left
			nameLabel.Parent = itemCard

			local priceLabel = Instance.new("TextLabel")
			priceLabel.Size = UDim2.new(0.5, 0, 0.25, 0)
			priceLabel.Position = UDim2.new(0.02, 0, 0.5, 0)
			priceLabel.BackgroundTransparency = 1
			priceLabel.Text = "Farm: " .. formatCash(item.BasePrice) .. "  →  Town: " .. formatCash(item.TownPrice)
			priceLabel.TextColor3 = Color3.fromRGB(100, 255, 100)
			priceLabel.TextScaled = true
			priceLabel.Font = Enum.Font.Gotham
			priceLabel.TextXAlignment = Enum.TextXAlignment.Left
			priceLabel.Parent = itemCard

			local bonusLabel = Instance.new("TextLabel")
			bonusLabel.Size = UDim2.new(0.5, 0, 0.2, 0)
			bonusLabel.Position = UDim2.new(0.02, 0, 0.75, 0)
			bonusLabel.BackgroundTransparency = 1
			bonusLabel.Text = "📈 +" .. math.floor((building.PriceMultiplier - 1) * 100) .. "% Bonus (Paid in 12h)"
			bonusLabel.TextColor3 = Color3.fromRGB(255, 200, 100)
			bonusLabel.TextScaled = true
			bonusLabel.Font = Enum.Font.Gotham
			bonusLabel.TextXAlignment = Enum.TextXAlignment.Left
			bonusLabel.Parent = itemCard

			local totalLabel = Instance.new("TextLabel")
			totalLabel.Size = UDim2.new(0.45, 0, 0.4, 0)
			totalLabel.Position = UDim2.new(0.53, 0, 0.3, 0)
			totalLabel.BackgroundTransparency = 1
			totalLabel.Text = formatCash(item.Total)
			totalLabel.TextColor3 = Color3.fromRGB(100, 255, 100)
			totalLabel.TextScaled = true
			totalLabel.Font = Enum.Font.GothamBold
			totalLabel.TextXAlignment = Enum.TextXAlignment.Right
			totalLabel.Parent = itemCard
		end

		-- Sell All Button
		local sellAllFrame = Instance.new("Frame")
		sellAllFrame.Size = UDim2.new(1, -40, 0, GUICONFIG.IsMobile and 80 or 70)
		sellAllFrame.Position = UDim2.new(0, 20, 1, -(GUICONFIG.IsMobile and 90 or 80))
		sellAllFrame.BackgroundColor3 = GUICONFIG.HeaderColor
		sellAllFrame.BorderSizePixel = 0
		sellAllFrame.Parent = mainFrame

		local sellAllCorner = Instance.new("UICorner")
		sellAllCorner.CornerRadius = UDim.new(0, 10)
		sellAllCorner.Parent = sellAllFrame

		local summaryLabel = Instance.new("TextLabel")
		summaryLabel.Size = UDim2.new(0.6, 0, 0.4, 0)
		summaryLabel.Position = UDim2.new(0.02, 0, 0.1, 0)
		summaryLabel.BackgroundTransparency = 1
		summaryLabel.Text = "💵 Total: " .. formatCash(totalValue) .. " (Paid in 12 hours)"
		summaryLabel.TextColor3 = Color3.fromRGB(100, 255, 100)
		summaryLabel.TextScaled = true
		summaryLabel.Font = Enum.Font.GothamBold
		summaryLabel.TextXAlignment = Enum.TextXAlignment.Left
		summaryLabel.Parent = sellAllFrame

		local sellAllButton = Instance.new("TextButton")
		sellAllButton.Size = UDim2.new(0.35, 0, 0.7, 0)
		sellAllButton.Position = UDim2.new(0.63, 0, 0.15, 0)
		sellAllButton.BackgroundColor3 = GUICONFIG.SellButtonColor
		sellAllButton.Text = "💰 List for Sale"
		sellAllButton.TextColor3 = Color3.fromRGB(0, 0, 0)
		sellAllButton.TextScaled = true
		sellAllButton.Font = Enum.Font.GothamBold
		sellAllButton.Parent = sellAllFrame

		local sellButtonCorner = Instance.new("UICorner")
		sellButtonCorner.CornerRadius = UDim.new(0, 8)
		sellButtonCorner.Parent = sellAllButton

		sellAllButton.MouseButton1Click:Connect(function()
			sellAllButton.Text = "Listing..."
			sellAllButton.BackgroundColor3 = Color3.fromRGB(150, 150, 150)

			local itemsToSell = {}
			for _, item in ipairs(acceptedItems) do
				itemsToSell[item.Name] = item.Count
			end

			SellToTownShopEvent:FireServer(buildingId, itemsToSell)
		end)
	end

	scrollFrame.CanvasSize = UDim2.new(0, 0, 0, listLayout.AbsoluteContentSize.Y + 10)
	screenGui.Parent = playerGui
end


-- Listen for server sell response
SellToTownShopEvent.OnClientEvent:Connect(function(status, data)
	if status == "success" then
		-- Close GUI
		if currentGui then
			currentGui:Destroy()
			currentGui = nil
		end

		if cooldownUpdateConnection then
			cooldownUpdateConnection:Disconnect()
			cooldownUpdateConnection = nil
		end

		-- Show success notification
		local ShowTutorialEvent = ReplicatedStorage:FindFirstChild("ShowTutorialEvent")
		if ShowTutorialEvent then
			local message = "Sold " .. #data.ItemsSold .. " items for " .. formatCash(data.TotalEarned) .. "!\n\n⏰ Next sale: " .. TownBuildingConfig.FormatCooldown(TownBuildingConfig.SELL_COOLDOWN)

			ShowTutorialEvent:FireServer("TownSellSuccess", {
				Title = "✅ Sold!",
				Message = message,
				Duration = 5
			})
		end

		print("✅ Town sale successful: $" .. data.TotalEarned)
	else
		-- Show error
		warn("❌ Town sale failed: " .. tostring(data))

		local ShowTutorialEvent = ReplicatedStorage:FindFirstChild("ShowTutorialEvent")
		if ShowTutorialEvent then
			ShowTutorialEvent:FireServer("TownSellFailed", {
				Title = "❌ Sale Failed",
				Message = tostring(data),
				Duration = 4
			})
		end

		-- Refresh GUI
		if currentBuilding then
			task.wait(0.5)
			createShopGUI(currentBuilding.ID)
		end
	end
end)

-- ============================================
-- LISTEN FOR PROXIMITY PROMPT (SINGLE LISTENER)
-- ============================================
OpenTownShopEvent.OnClientEvent:Connect(function(buildingID)
	print("📱 Received OpenTownShopEvent:", buildingID)

	-- Close existing GUI
	if currentGui then
		currentGui:Destroy()
		currentGui = nil
	end

	if cooldownUpdateConnection then
		cooldownUpdateConnection:Disconnect()
		cooldownUpdateConnection = nil
	end

	-- Open shop GUI
	createShopGUI(buildingID)
end)

print("✅ TownShopClient ready and listening for proximity prompts!")
