-- MarketplaceClient.lua (StarterPlayerScripts - LocalScript)
-- Handles marketplace GUI: browse, buy, sell

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

-- Remote Events
local ListItemEvent = ReplicatedStorage:WaitForChild("ListItemEvent")
local BuyItemEvent = ReplicatedStorage:WaitForChild("BuyItemEvent")
local CancelListingEvent = ReplicatedStorage:WaitForChild("CancelListingEvent")
local RefreshMarketEvent = ReplicatedStorage:WaitForChild("RefreshMarketEvent")
local MarketplaceResponseEvent = ReplicatedStorage:WaitForChild("MarketplaceResponseEvent")

print("🏪 MarketplaceClient loaded!")

-- ============================================
-- GUI CONFIGURATION (Mobile-Responsive)
-- ============================================

local GUI_CONFIG = {
	-- Responsive sizing
	IsMobile = UserInputService.TouchEnabled and not UserInputService.KeyboardEnabled,

	-- Colors
	BackgroundColor = Color3.fromRGB(40, 40, 40),
	HeaderColor = Color3.fromRGB(60, 60, 60),
	ButtonColor = Color3.fromRGB(80, 120, 255),
	BuyButtonColor = Color3.fromRGB(80, 200, 80),
	SellButtonColor = Color3.fromRGB(255, 150, 50),
	CancelButtonColor = Color3.fromRGB(200, 80, 80),

	-- Text
	TextColor = Color3.fromRGB(255, 255, 255),

	-- Sizing (responsive)
	FrameWidth = UserInputService.TouchEnabled and 0.95 or 0.7,
	FrameHeight = UserInputService.TouchEnabled and 0.85 or 0.75,
	ButtonHeight = UserInputService.TouchEnabled and 60 or 50,
}

-- ============================================
-- STATE MANAGEMENT
-- ============================================

local MarketplaceState = {
	CurrentTab = "Browse",
	CurrentCategory = "All",
	CurrentSort = "Newest",
	Listings = {},
	MyListings = {}
}

-- ============================================
-- HELPER FUNCTIONS
-- ============================================

local function formatNumber(num)
	local formatted = tostring(math.floor(num))
	return formatted:reverse():gsub("(%d%d%d)", "%1,"):reverse():gsub("^,", "")
end

local function formatCash(amount)
	return "$" .. formatNumber(amount)
end

local function getItemEmoji(itemName)
	local emojis = {
		Wheat = "🌾", Corn = "🌽", Carrot = "🥕", Potato = "🥔",
		Tomato = "🍅", Pumpkin = "🎃", Strawberry = "🍓", Watermelon = "🍉",
		Eggs = "🥚", Milk = "🥛", Meat = "🥩", Wool = "🧶", Honey = "🍯",
		Salmon = "🐟", Tuna = "🐟", Bass = "🐠", Catfish = "🐡",
		Chicken = "🐔", Cow = "🐄", Pig = "🐷", Sheep = "🐑"
	}
	return emojis[itemName] or "📦"
end

local function getTimeSince(timestamp)
	local elapsed = os.time() - timestamp
	local days = math.floor(elapsed / 86400)
	local hours = math.floor((elapsed % 86400) / 3600)
	local minutes = math.floor((elapsed % 3600) / 60)

	if days > 0 then
		return days .. "d ago"
	elseif hours > 0 then
		return hours .. "h ago"
	else
		return minutes .. "m ago"
	end
end


-- ============================================
-- CARD CREATION FUNCTIONS (Define BEFORE tabs)
-- ============================================

-- Create individual listing card (for Browse tab)
local function createListingCard(parent, listing, index)
	local card = Instance.new("Frame")
	card.Name = "Listing_" .. index
	card.Size = UDim2.new(1, -10, 0, GUI_CONFIG.IsMobile and 120 or 100)
	card.BackgroundColor3 = GUI_CONFIG.HeaderColor
	card.BorderSizePixel = 0
	card.LayoutOrder = index
	card.Parent = parent

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 8)
	corner.Parent = card

	-- Item Info
	local itemLabel = Instance.new("TextLabel")
	itemLabel.Size = UDim2.new(0.6, 0, 0.4, 0)
	itemLabel.Position = UDim2.new(0.02, 0, 0.05, 0)
	itemLabel.BackgroundTransparency = 1
	itemLabel.Text = getItemEmoji(listing.ItemName) .. " " .. listing.ItemName .. " x" .. listing.Quantity
	itemLabel.TextColor3 = GUI_CONFIG.TextColor
	itemLabel.TextScaled = true
	itemLabel.Font = Enum.Font.GothamBold
	itemLabel.TextXAlignment = Enum.TextXAlignment.Left
	itemLabel.Parent = card

	-- Price Info
	local priceLabel = Instance.new("TextLabel")
	priceLabel.Size = UDim2.new(0.6, 0, 0.3, 0)
	priceLabel.Position = UDim2.new(0.02, 0, 0.45, 0)
	priceLabel.BackgroundTransparency = 1
	priceLabel.Text = formatCash(listing.TotalPrice) .. " total (" .. formatCash(listing.PricePerUnit) .. " each)"
	priceLabel.TextColor3 = Color3.fromRGB(100, 255, 100)
	priceLabel.TextScaled = true
	priceLabel.Font = Enum.Font.Gotham
	priceLabel.TextXAlignment = Enum.TextXAlignment.Left
	priceLabel.Parent = card

	-- Seller Info
	local sellerLabel = Instance.new("TextLabel")
	sellerLabel.Size = UDim2.new(0.6, 0, 0.25, 0)
	sellerLabel.Position = UDim2.new(0.02, 0, 0.75, 0)
	sellerLabel.BackgroundTransparency = 1
	sellerLabel.Text = "👤 " .. listing.SellerName .. " • " .. getTimeSince(listing.ListedAt)
	sellerLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
	sellerLabel.TextScaled = true
	sellerLabel.Font = Enum.Font.Gotham
	sellerLabel.TextXAlignment = Enum.TextXAlignment.Left
	sellerLabel.Parent = card

	-- Buy Button
	local buyButton = Instance.new("TextButton")
	buyButton.Size = UDim2.new(0.35, -10, 0.7, 0)
	buyButton.Position = UDim2.new(0.63, 0, 0.15, 0)
	buyButton.BackgroundColor3 = GUI_CONFIG.BuyButtonColor
	buyButton.Text = "Buy for " .. formatCash(listing.TotalPrice)
	buyButton.TextColor3 = GUI_CONFIG.TextColor
	buyButton.TextScaled = true
	buyButton.Font = Enum.Font.GothamBold
	buyButton.Parent = card

	local btnCorner = Instance.new("UICorner")
	btnCorner.CornerRadius = UDim.new(0, 6)
	btnCorner.Parent = buyButton

	buyButton.MouseButton1Click:Connect(function()
		buyButton.Text = "Purchasing..."
		buyButton.BackgroundColor3 = GUI_CONFIG.HeaderColor
		BuyItemEvent:FireServer(listing.ListingId)
	end)
end


-- Create "My Listing" card (for My Listings tab)
local function createMyListingCard(parent, listing, index)
	local card = Instance.new("Frame")
	card.Name = "MyListing_" .. index
	card.Size = UDim2.new(1, -10, 0, GUI_CONFIG.IsMobile and 120 or 100)
	card.BackgroundColor3 = GUI_CONFIG.HeaderColor
	card.BorderSizePixel = 0
	card.LayoutOrder = index
	card.Parent = parent

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 8)
	corner.Parent = card

	-- Item Info
	local itemLabel = Instance.new("TextLabel")
	itemLabel.Size = UDim2.new(0.6, 0, 0.4, 0)
	itemLabel.Position = UDim2.new(0.02, 0, 0.05, 0)
	itemLabel.BackgroundTransparency = 1
	itemLabel.Text = getItemEmoji(listing.ItemName) .. " " .. listing.ItemName .. " x" .. listing.Quantity
	itemLabel.TextColor3 = GUI_CONFIG.TextColor
	itemLabel.TextScaled = true
	itemLabel.Font = Enum.Font.GothamBold
	itemLabel.TextXAlignment = Enum.TextXAlignment.Left
	itemLabel.Parent = card

	-- Price Info
	local priceLabel = Instance.new("TextLabel")
	priceLabel.Size = UDim2.new(0.6, 0, 0.3, 0)
	priceLabel.Position = UDim2.new(0.02, 0, 0.45, 0)
	priceLabel.BackgroundTransparency = 1
	priceLabel.Text = "💰 " .. formatCash(listing.TotalPrice) .. " total (" .. formatCash(listing.PricePerUnit) .. " each)"
	priceLabel.TextColor3 = Color3.fromRGB(100, 255, 100)
	priceLabel.TextScaled = true
	priceLabel.Font = Enum.Font.Gotham
	priceLabel.TextXAlignment = Enum.TextXAlignment.Left
	priceLabel.Parent = card

	-- Listed Time
	local timeLabel = Instance.new("TextLabel")
	timeLabel.Size = UDim2.new(0.6, 0, 0.25, 0)
	timeLabel.Position = UDim2.new(0.02, 0, 0.75, 0)
	timeLabel.BackgroundTransparency = 1
	timeLabel.Text = "📅 Listed: " .. getTimeSince(listing.ListedAt)
	timeLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
	timeLabel.TextScaled = true
	timeLabel.Font = Enum.Font.Gotham
	timeLabel.TextXAlignment = Enum.TextXAlignment.Left
	timeLabel.Parent = card

	-- Cancel Button
	local cancelButton = Instance.new("TextButton")
	cancelButton.Size = UDim2.new(0.35, -10, 0.7, 0)
	cancelButton.Position = UDim2.new(0.63, 0, 0.15, 0)
	cancelButton.BackgroundColor3 = GUI_CONFIG.CancelButtonColor
	cancelButton.Text = "❌ Cancel Listing"
	cancelButton.TextColor3 = GUI_CONFIG.TextColor
	cancelButton.TextScaled = true
	cancelButton.Font = Enum.Font.GothamBold
	cancelButton.Parent = card

	local btnCorner = Instance.new("UICorner")
	btnCorner.CornerRadius = UDim.new(0, 6)
	btnCorner.Parent = cancelButton

	cancelButton.MouseButton1Click:Connect(function()
		cancelButton.Text = "Canceling..."
		cancelButton.BackgroundColor3 = GUI_CONFIG.HeaderColor
		CancelListingEvent:FireServer(listing.ListingId)
	end)
end

-- Create sellable item card (for Sell tab)
local function createSellableItemCard(parent, item, index)
	local card = Instance.new("Frame")
	card.Name = "SellItem_" .. index
	card.Size = UDim2.new(1, -10, 0, GUI_CONFIG.IsMobile and 140 or 120)
	card.BackgroundColor3 = GUI_CONFIG.HeaderColor
	card.BorderSizePixel = 0
	card.LayoutOrder = index
	card.Parent = parent

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 8)
	corner.Parent = card

	-- Item Name
	local nameLabel = Instance.new("TextLabel")
	nameLabel.Size = UDim2.new(0.5, 0, 0.3, 0)
	nameLabel.Position = UDim2.new(0.02, 0, 0.05, 0)
	nameLabel.BackgroundTransparency = 1
	nameLabel.Text = getItemEmoji(item.Name) .. " " .. item.Name .. " (Have: " .. item.Count .. ")"
	nameLabel.TextColor3 = GUI_CONFIG.TextColor
	nameLabel.TextScaled = true
	nameLabel.Font = Enum.Font.GothamBold
	nameLabel.TextXAlignment = Enum.TextXAlignment.Left
	nameLabel.Parent = card

	-- Quantity Input
	local qtyLabel = Instance.new("TextLabel")
	qtyLabel.Size = UDim2.new(0.2, 0, 0.25, 0)
	qtyLabel.Position = UDim2.new(0.02, 0, 0.4, 0)
	qtyLabel.BackgroundTransparency = 1
	qtyLabel.Text = "Quantity:"
	qtyLabel.TextColor3 = GUI_CONFIG.TextColor
	qtyLabel.TextScaled = true
	qtyLabel.Font = Enum.Font.Gotham
	qtyLabel.TextXAlignment = Enum.TextXAlignment.Left
	qtyLabel.Parent = card

	local qtyInput = Instance.new("TextBox")
	qtyInput.Size = UDim2.new(0.15, 0, 0.25, 0)
	qtyInput.Position = UDim2.new(0.23, 0, 0.4, 0)
	qtyInput.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
	qtyInput.Text = tostring(math.min(item.Count, 10))
	qtyInput.TextColor3 = GUI_CONFIG.TextColor
	qtyInput.TextScaled = true
	qtyInput.Font = Enum.Font.Gotham
	qtyInput.ClearTextOnFocus = true
	qtyInput.Parent = card

	local qtyCorner = Instance.new("UICorner")
	qtyCorner.CornerRadius = UDim.new(0, 4)
	qtyCorner.Parent = qtyInput

	-- Price Per Unit Input
	local priceLabel = Instance.new("TextLabel")
	priceLabel.Size = UDim2.new(0.2, 0, 0.25, 0)
	priceLabel.Position = UDim2.new(0.02, 0, 0.7, 0)
	priceLabel.BackgroundTransparency = 1
	priceLabel.Text = "Price Each:"
	priceLabel.TextColor3 = GUI_CONFIG.TextColor
	priceLabel.TextScaled = true
	priceLabel.Font = Enum.Font.Gotham
	priceLabel.TextXAlignment = Enum.TextXAlignment.Left
	priceLabel.Parent = card

	local priceInput = Instance.new("TextBox")
	priceInput.Size = UDim2.new(0.15, 0, 0.25, 0)
	priceInput.Position = UDim2.new(0.23, 0, 0.7, 0)
	priceInput.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
	-- Smart default price based on item category
	local defaultPrice = 50
	if item.Category == "Crops" then
		defaultPrice = 100  -- Crops default to $100
	elseif item.Category == "Products" then
		defaultPrice = 50   -- Products default to $50
	elseif item.Category == "Fish" then
		defaultPrice = 75   -- Fish default to $75
	end

	priceInput.Text = tostring(defaultPrice)
	priceInput.TextColor3 = GUI_CONFIG.TextColor
	priceInput.TextScaled = true
	priceInput.Font = Enum.Font.Gotham
	priceInput.ClearTextOnFocus = true
	priceInput.Parent = card

	local priceCorner = Instance.new("UICorner")
	priceCorner.CornerRadius = UDim.new(0, 4)
	priceCorner.Parent = priceInput

	-- List Button
	local listButton = Instance.new("TextButton")
	listButton.Size = UDim2.new(0.35, -10, 0.6, 0)
	listButton.Position = UDim2.new(0.63, 0, 0.2, 0)
	listButton.BackgroundColor3 = GUI_CONFIG.SellButtonColor
	listButton.Text = "📋 List Item"
	listButton.TextColor3 = GUI_CONFIG.TextColor
	listButton.TextScaled = true
	listButton.Font = Enum.Font.GothamBold
	listButton.Parent = card

	local btnCorner = Instance.new("UICorner")
	btnCorner.CornerRadius = UDim.new(0, 6)
	btnCorner.Parent = listButton

	listButton.MouseButton1Click:Connect(function()
		local quantity = tonumber(qtyInput.Text)
		local pricePerUnit = tonumber(priceInput.Text)

		if not quantity or quantity <= 0 then
			warn("Invalid quantity")
			return
		end

		if not pricePerUnit or pricePerUnit <= 0 then
			warn("Invalid price")
			return
		end

		if quantity > item.Count then
			warn("Not enough items")
			return
		end

		listButton.Text = "Listing..."
		listButton.BackgroundColor3 = GUI_CONFIG.HeaderColor

		ListItemEvent:FireServer(item.Name, quantity, pricePerUnit)
	end)
end


-- ============================================
-- BROWSE TAB
-- ============================================

local function createBrowseTab(container)
	-- Filter Bar
	local filterBar = Instance.new("Frame")
	filterBar.Name = "FilterBar"
	filterBar.Size = UDim2.new(1, 0, 0, 60)
	filterBar.BackgroundTransparency = 1
	filterBar.Parent = container

	-- Category Filter
	local categoryLabel = Instance.new("TextLabel")
	categoryLabel.Size = UDim2.new(0.2, -5, 1, 0)
	categoryLabel.Position = UDim2.new(0, 0, 0, 0)
	categoryLabel.BackgroundTransparency = 1
	categoryLabel.Text = "Category:"
	categoryLabel.TextColor3 = GUI_CONFIG.TextColor
	categoryLabel.TextScaled = true
	categoryLabel.Font = Enum.Font.Gotham
	categoryLabel.Parent = filterBar

	local categoryDropdown = Instance.new("TextButton")
	categoryDropdown.Size = UDim2.new(0.3, -5, 0.8, 0)
	categoryDropdown.Position = UDim2.new(0.2, 0, 0.1, 0)
	categoryDropdown.BackgroundColor3 = GUI_CONFIG.HeaderColor
	categoryDropdown.Text = MarketplaceState.CurrentCategory .. " ▼"
	categoryDropdown.TextColor3 = GUI_CONFIG.TextColor
	categoryDropdown.TextScaled = true
	categoryDropdown.Font = Enum.Font.Gotham
	categoryDropdown.Parent = filterBar

	local catCorner = Instance.new("UICorner")
	catCorner.CornerRadius = UDim.new(0, 6)
	catCorner.Parent = categoryDropdown

	-- Sort Filter
	local sortLabel = Instance.new("TextLabel")
	sortLabel.Size = UDim2.new(0.15, -5, 1, 0)
	sortLabel.Position = UDim2.new(0.5, 5, 0, 0)
	sortLabel.BackgroundTransparency = 1
	sortLabel.Text = "Sort:"
	sortLabel.TextColor3 = GUI_CONFIG.TextColor
	sortLabel.TextScaled = true
	sortLabel.Font = Enum.Font.Gotham
	sortLabel.Parent = filterBar

	local sortDropdown = Instance.new("TextButton")
	sortDropdown.Size = UDim2.new(0.35, -10, 0.8, 0)
	sortDropdown.Position = UDim2.new(0.65, 0, 0.1, 0)
	sortDropdown.BackgroundColor3 = GUI_CONFIG.HeaderColor
	sortDropdown.Text = "Newest First ▼"
	sortDropdown.TextColor3 = GUI_CONFIG.TextColor
	sortDropdown.TextScaled = true
	sortDropdown.Font = Enum.Font.Gotham
	sortDropdown.Parent = filterBar

	local sortCorner = Instance.new("UICorner")
	sortCorner.CornerRadius = UDim.new(0, 6)
	sortCorner.Parent = sortDropdown

	-- Scrolling Frame for Listings
	local scrollFrame = Instance.new("ScrollingFrame")
	scrollFrame.Name = "ListingsScroll"
	scrollFrame.Size = UDim2.new(1, 0, 1, -70)
	scrollFrame.Position = UDim2.new(0, 0, 0, 70)
	scrollFrame.BackgroundTransparency = 1
	scrollFrame.BorderSizePixel = 0
	scrollFrame.ScrollBarThickness = 8
	scrollFrame.Parent = container

	local listLayout = Instance.new("UIListLayout")
	listLayout.Padding = UDim.new(0, 10)
	listLayout.SortOrder = Enum.SortOrder.LayoutOrder
	listLayout.Parent = scrollFrame

	-- Request marketplace data
	RefreshMarketEvent:FireServer(MarketplaceState.CurrentCategory, MarketplaceState.CurrentSort)

	-- Wait for response
	local connection
	connection = MarketplaceResponseEvent.OnClientEvent:Connect(function(listings)
		-- Clear old listings
		for _, child in pairs(scrollFrame:GetChildren()) do
			if child:IsA("Frame") then
				child:Destroy()
			end
		end

		MarketplaceState.Listings = listings

		if #listings == 0 then
			local emptyLabel = Instance.new("TextLabel")
			emptyLabel.Size = UDim2.new(1, 0, 0, 100)
			emptyLabel.BackgroundTransparency = 1
			emptyLabel.Text = "📭 No listings available"
			emptyLabel.TextColor3 = GUI_CONFIG.TextColor
			emptyLabel.TextScaled = true
			emptyLabel.Font = Enum.Font.Gotham
			emptyLabel.Parent = scrollFrame
			return
		end

		-- Create listing cards
		for i, listing in ipairs(listings) do
			createListingCard(scrollFrame, listing, i)
		end

		-- Update canvas size
		scrollFrame.CanvasSize = UDim2.new(0, 0, 0, listLayout.AbsoluteContentSize.Y + 10)
	end)
end

-- ============================================
-- MY LISTINGS TAB (Complete Implementation)
-- ============================================

local function createMyListingsTab(container)
	-- Instruction Label
	local instructionLabel = Instance.new("TextLabel")
	instructionLabel.Size = UDim2.new(1, 0, 0, 40)
	instructionLabel.BackgroundTransparency = 1
	instructionLabel.Text = "📋 Your Active Marketplace Listings (Max 5)"
	instructionLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
	instructionLabel.TextScaled = true
	instructionLabel.Font = Enum.Font.Gotham
	instructionLabel.Parent = container

	-- Scrolling Frame
	local scrollFrame = Instance.new("ScrollingFrame")
	scrollFrame.Name = "MyListingsScroll"
	scrollFrame.Size = UDim2.new(1, 0, 1, -50)
	scrollFrame.Position = UDim2.new(0, 0, 0, 50)
	scrollFrame.BackgroundTransparency = 1
	scrollFrame.BorderSizePixel = 0
	scrollFrame.ScrollBarThickness = 8
	scrollFrame.Parent = container

	local listLayout = Instance.new("UIListLayout")
	listLayout.Padding = UDim.new(0, 10)
	listLayout.SortOrder = Enum.SortOrder.LayoutOrder
	listLayout.Parent = scrollFrame

	-- Request marketplace data
	RefreshMarketEvent:FireServer("All", "Newest")

	-- Wait for response
	local connection
	connection = MarketplaceResponseEvent.OnClientEvent:Connect(function(listings)
		-- Clear old listings
		for _, child in pairs(scrollFrame:GetChildren()) do
			if child:IsA("Frame") then
				child:Destroy()
			end
		end

		-- Filter to only player's listings
		local myListings = {}
		for _, listing in ipairs(listings) do
			if listing.SellerId == player.UserId then
				table.insert(myListings, listing)
			end
		end

		if #myListings == 0 then
			local emptyLabel = Instance.new("TextLabel")
			emptyLabel.Size = UDim2.new(1, 0, 0, 100)
			emptyLabel.BackgroundTransparency = 1
			emptyLabel.Text = "📭 No active listings\n\nGo to 'Sell Items' tab to create your first listing!"
			emptyLabel.TextColor3 = GUI_CONFIG.TextColor
			emptyLabel.TextScaled = true
			emptyLabel.Font = Enum.Font.Gotham
			emptyLabel.Parent = scrollFrame
			return
		end

		-- Create listing cards
		for i, listing in ipairs(myListings) do
			createMyListingCard(scrollFrame, listing, i)
		end

		-- Update canvas size
		scrollFrame.CanvasSize = UDim2.new(0, 0, 0, listLayout.AbsoluteContentSize.Y + 10)
	end)
end

-- ============================================
-- SELL TAB (Complete Implementation)
-- ============================================

local function createSellTab(container)
	-- Instruction Label
	local instructionLabel = Instance.new("TextLabel")
	instructionLabel.Size = UDim2.new(1, 0, 0, 40)
	instructionLabel.BackgroundTransparency = 1
	instructionLabel.Text = "📋 Select an item to list on the marketplace (5% listing fee)"
	instructionLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
	instructionLabel.TextScaled = true
	instructionLabel.Font = Enum.Font.Gotham
	instructionLabel.Parent = container

	-- Scrolling Frame for Player Inventory
	local scrollFrame = Instance.new("ScrollingFrame")
	scrollFrame.Size = UDim2.new(1, 0, 1, -50)
	scrollFrame.Position = UDim2.new(0, 0, 0, 50)
	scrollFrame.BackgroundTransparency = 1
	scrollFrame.BorderSizePixel = 0
	scrollFrame.ScrollBarThickness = 8
	scrollFrame.Parent = container

	local listLayout = Instance.new("UIListLayout")
	listLayout.Padding = UDim.new(0, 10)
	listLayout.SortOrder = Enum.SortOrder.LayoutOrder
	listLayout.Parent = scrollFrame

	-- Get player's sellable items
	local sellableItems = {}

	-- Crops
	local cropInventory = player:FindFirstChild("CropInventory")
	if cropInventory then
		for _, cropValue in pairs(cropInventory:GetChildren()) do
			if cropValue:IsA("IntValue") and cropValue.Value > 0 then
				table.insert(sellableItems, {
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
				table.insert(sellableItems, {
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
				table.insert(sellableItems, {
					Name = fishValue.Name,
					Count = fishValue.Value,
					Category = "Fish"
				})
			end
		end
	end

	if #sellableItems == 0 then
		local emptyLabel = Instance.new("TextLabel")
		emptyLabel.Size = UDim2.new(1, 0, 0, 100)
		emptyLabel.BackgroundTransparency = 1
		emptyLabel.Text = "📭 No items to sell\n\nHarvest crops, collect products, or catch fish first!"
		emptyLabel.TextColor3 = GUI_CONFIG.TextColor
		emptyLabel.TextScaled = true
		emptyLabel.Font = Enum.Font.Gotham
		emptyLabel.Parent = scrollFrame
		return
	end

	-- Create sellable item cards
	for i, item in ipairs(sellableItems) do
		createSellableItemCard(scrollFrame, item, i)
	end

	-- Update canvas size
	scrollFrame.CanvasSize = UDim2.new(0, 0, 0, listLayout.AbsoluteContentSize.Y + 10)
end



-- ============================================
-- CREATE MAIN GUI FRAME
-- ============================================

local function createMainFrame()
	local screenGui = Instance.new("ScreenGui")
	screenGui.Name = "MarketplaceGui"
	screenGui.ResetOnSpawn = false
	screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling

	-- Main Frame (responsive)
	local mainFrame = Instance.new("Frame")
	mainFrame.Name = "MainFrame"
	mainFrame.Size = UDim2.new(GUI_CONFIG.FrameWidth, 0, GUI_CONFIG.FrameHeight, 0)
	mainFrame.Position = UDim2.new(0.5, 0, 0.5, 0)
	mainFrame.AnchorPoint = Vector2.new(0.5, 0.5)
	mainFrame.BackgroundColor3 = GUI_CONFIG.BackgroundColor
	mainFrame.BorderSizePixel = 0
	mainFrame.Visible = false -- Hidden by default
	mainFrame.Parent = screenGui

	-- Corner radius
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 12)
	corner.Parent = mainFrame

	-- Header
	local header = Instance.new("Frame")
	header.Name = "Header"
	header.Size = UDim2.new(1, 0, 0, 60)
	header.BackgroundColor3 = GUI_CONFIG.HeaderColor
	header.BorderSizePixel = 0
	header.Parent = mainFrame

	local headerCorner = Instance.new("UICorner")
	headerCorner.CornerRadius = UDim.new(0, 12)
	headerCorner.Parent = header

	-- Title
	local title = Instance.new("TextLabel")
	title.Name = "Title"
	title.Size = UDim2.new(0.8, 0, 1, 0)
	title.Position = UDim2.new(0.05, 0, 0, 0)
	title.BackgroundTransparency = 1
	title.Text = "🏪 Player Marketplace"
	title.TextColor3 = GUI_CONFIG.TextColor
	title.TextScaled = true
	title.Font = Enum.Font.GothamBold
	title.TextXAlignment = Enum.TextXAlignment.Left
	title.Parent = header

	-- Close Button
	local closeButton = Instance.new("TextButton")
	closeButton.Name = "CloseButton"
	closeButton.Size = UDim2.new(0, 50, 0, 50)
	closeButton.Position = UDim2.new(1, -55, 0, 5)
	closeButton.BackgroundColor3 = GUI_CONFIG.CancelButtonColor
	closeButton.Text = "✕"
	closeButton.TextColor3 = GUI_CONFIG.TextColor
	closeButton.TextScaled = true
	closeButton.Font = Enum.Font.GothamBold
	closeButton.Parent = header

	local closeCorner = Instance.new("UICorner")
	closeCorner.CornerRadius = UDim.new(1, 0)
	closeCorner.Parent = closeButton

	closeButton.MouseButton1Click:Connect(function()
		screenGui:Destroy()
	end)

	-- Tab Container
	local tabContainer = Instance.new("Frame")
	tabContainer.Name = "TabContainer"
	tabContainer.Size = UDim2.new(1, 0, 0, 50)
	tabContainer.Position = UDim2.new(0, 0, 0, 60)
	tabContainer.BackgroundTransparency = 1
	tabContainer.Parent = mainFrame

	-- Content Container
	local contentContainer = Instance.new("Frame")
	contentContainer.Name = "ContentContainer"
	contentContainer.Size = UDim2.new(1, -20, 1, -130)
	contentContainer.Position = UDim2.new(0, 10, 0, 120)
	contentContainer.BackgroundTransparency = 1
	contentContainer.Parent = mainFrame

	screenGui.Parent = playerGui

	return screenGui, mainFrame, tabContainer, contentContainer
end

-- ============================================
-- CREATE TAB BUTTONS
-- ============================================

local function createTabButtons(tabContainer, contentContainer)
	local tabs = {"Browse", "My Listings", "Sell Items"}
	local tabWidth = 1 / #tabs

	for i, tabName in ipairs(tabs) do
		local tabButton = Instance.new("TextButton")
		tabButton.Name = tabName .. "Tab"
		tabButton.Size = UDim2.new(tabWidth, -5, 1, -10)
		tabButton.Position = UDim2.new(tabWidth * (i - 1), 5, 0, 5)
		tabButton.BackgroundColor3 = (tabName == MarketplaceState.CurrentTab) and GUI_CONFIG.ButtonColor or GUI_CONFIG.HeaderColor
		tabButton.Text = tabName
		tabButton.TextColor3 = GUI_CONFIG.TextColor
		tabButton.TextScaled = true
		tabButton.Font = Enum.Font.GothamBold
		tabButton.Parent = tabContainer

		local corner = Instance.new("UICorner")
		corner.CornerRadius = UDim.new(0, 8)
		corner.Parent = tabButton

		tabButton.MouseButton1Click:Connect(function()
			-- Update state
			MarketplaceState.CurrentTab = tabName

			-- Update button colors
			for _, btn in pairs(tabContainer:GetChildren()) do
				if btn:IsA("TextButton") then
					btn.BackgroundColor3 = (btn.Text == tabName) and GUI_CONFIG.ButtonColor or GUI_CONFIG.HeaderColor
				end
			end

			-- Clear content
			for _, child in pairs(contentContainer:GetChildren()) do
				child:Destroy()
			end

			-- Load tab content
			if tabName == "Browse" then
				createBrowseTab(contentContainer)
			elseif tabName == "My Listings" then
				createMyListingsTab(contentContainer)
			elseif tabName == "Sell Items" then
				createSellTab(contentContainer)
			end
		end)
	end
end


-- ============================================
-- OPEN MARKETPLACE
-- ============================================

-- OPEN MARKETPLACE
function _G.OpenMarketplace(initialTab)
	-- Close existing GUI
	local existing = playerGui:FindFirstChild("MarketplaceGui")
	if existing then
		existing:Destroy()
	end

	-- Determine which tab to show
	local tabToShow = initialTab or "Browse"

	-- Update state BEFORE creating GUI
	MarketplaceState.CurrentTab = tabToShow

	-- Create new GUI
	local screenGui, mainFrame, tabContainer, contentContainer = createMainFrame()
	createTabButtons(tabContainer, contentContainer)

	-- Clear any default content that createTabButtons might have added
	for _, child in pairs(contentContainer:GetChildren()) do
		if child:IsA("GuiObject") then
			child:Destroy()
		end
	end

	-- Load the correct tab content
	if tabToShow == "Sell Items" then
		createSellTab(contentContainer)
	elseif tabToShow == "My Listings" then
		createMyListingsTab(contentContainer)
	else
		createBrowseTab(contentContainer)
	end

	-- Show GUI
	mainFrame.Visible = true
	print("Marketplace opened to " .. tabToShow .. " tab")
end




-- ============================================
-- PROXIMITY PROMPT (MarketplaceStand)
-- ============================================

task.spawn(function()
	task.wait(3)

	local startingZone = workspace:FindFirstChild("StartingZone")
	if not startingZone then
		warn("⚠️ StartingZone not found!")
		return
	end

	local marketplaceStand = startingZone:FindFirstChild("MarketplaceStand")
	if not marketplaceStand then
		warn("⚠️ MarketplaceStand not found!")
		return
	end

	-- Search inside Stand for ProximityPrompt
	local stand = marketplaceStand:FindFirstChild("Stand")
	local prompt = stand and stand:FindFirstChild("ProximityPrompt")

	if not prompt then
		warn("⚠️ ProximityPrompt not found in MarketplaceStand > Stand!")
		return
	end

	-- Override prompt to open Marketplace
	prompt.ActionText = "Open Marketplace"
	prompt.Triggered:Connect(function(playerWhoTriggered)
		if playerWhoTriggered == player then
			_G.OpenMarketplace()
		end
	end)

	print("✅ MarketplaceStand ProximityPrompt connected!")
end)


-- ============================================
-- EVENT LISTENERS
-- ============================================

-- Listen for buy response
BuyItemEvent.OnClientEvent:Connect(function(status, data)
	if status == "success" then
		-- Show success notification
		local showTutorialEvent = ReplicatedStorage:FindFirstChild("ShowTutorialEvent")
		if showTutorialEvent then
			showTutorialEvent:FireServer("PurchaseSuccess", {
				Title = "✅ Purchase Complete!",
				Message = "You bought " .. data.Quantity .. "x " .. data.ItemName .. " for " .. formatCash(data.TotalPrice),
				Duration = 3
			})
		end

		-- Refresh marketplace
		RefreshMarketEvent:FireServer(MarketplaceState.CurrentCategory, MarketplaceState.CurrentSort)
	else
		-- Show error
		warn("❌ Purchase failed: " .. data)
	end
end)


-- ============================================
-- ADDITIONAL EVENT LISTENERS
-- ============================================

-- Listen for list response
ListItemEvent.OnClientEvent:Connect(function(status, result, fee)
	if status == "success" then
		-- Show success notification
		local showTutorialEvent = ReplicatedStorage:WaitForChild("ShowTutorialEvent")
		showTutorialEvent:FireServer("ListSuccess", {
			Title = "✅ Listed on Marketplace!",
			Message = "Your item is now for sale! (Fee: " .. formatCash(fee) .. ")",
			Duration = 3
		})

		-- Refresh to "My Listings" tab
		if _G.OpenMarketplace then
			task.wait(0.5)
			_G.OpenMarketplace()
			-- TODO: Auto-switch to "My Listings" tab
		end
	else
		-- Show error
		warn("❌ Listing failed: " .. result)
	end
end)

-- Listen for cancel response
CancelListingEvent.OnClientEvent:Connect(function(status, result)
	if status == "success" then
		-- Show success notification
		local showTutorialEvent = ReplicatedStorage:WaitForChild("ShowTutorialEvent")
		showTutorialEvent:FireServer("CancelSuccess", {
			Title = "✅ Listing Canceled",
			Message = result.Quantity .. "x " .. result.ItemName .. " returned to your inventory",
			Duration = 3
		})

		-- Refresh marketplace
		RefreshMarketEvent:FireServer(MarketplaceState.CurrentCategory, MarketplaceState.CurrentSort)
	else
		warn("❌ Cancel failed: " .. result)
	end
end)

-- Function to open marketplace to sell tab with pre-selected item
function _G.OpenMarketplaceToSell(itemName, itemCount)
	_G.OpenMarketplace()
	-- TODO: Auto-switch to "Sell Items" tab and pre-fill item
end


print("✅ MarketplaceClient ready!")
