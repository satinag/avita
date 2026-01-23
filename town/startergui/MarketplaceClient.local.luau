-- MarketplaceClient.local.lua (LocalScript)
-- Universal marketplace UI for all Town buildings
-- Location: StarterGui.MarketplaceClient (Town place)

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

-- Remote Events
local OpenMarketplaceEvent = ReplicatedStorage:WaitForChild("OpenMarketplaceEvent")
local RefreshMarketplaceEvent = ReplicatedStorage:WaitForChild("RefreshMarketplaceEvent")
local PurchaseItemEvent = ReplicatedStorage:WaitForChild("PurchaseItemEvent")
local ListItemEvent = ReplicatedStorage:WaitForChild("ListItemEvent")

-- Wait for modules
local TownBuildingConfig = require(ReplicatedStorage:WaitForChild("TownBuildingConfig", 10))
if not TownBuildingConfig then
	warn("❌ TownBuildingConfig not found")
	return
end

-- Detect mobile
local function isMobile()
	return UserInputService.TouchEnabled and not UserInputService.KeyboardEnabled
end

-- ============================================
-- CREATE GUI STRUCTURE
-- ============================================
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "MarketplaceGUI"
screenGui.ResetOnSpawn = false
screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
screenGui.Parent = playerGui

-- Main frame (hidden by default)
local mainFrame = Instance.new("Frame")
mainFrame.Name = "MainFrame"
mainFrame.Size = isMobile() and UDim2.new(0.95, 0, 0.85, 0) or UDim2.new(0.7, 0, 0.75, 0)
mainFrame.Position = isMobile() and UDim2.new(0.025, 0, 0.075, 0) or UDim2.new(0.15, 0, 0.125, 0)
mainFrame.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
mainFrame.BorderSizePixel = 0
mainFrame.Visible = false
mainFrame.ZIndex = 10
mainFrame.Parent = screenGui

local mainCorner = Instance.new("UICorner")
mainCorner.CornerRadius = UDim.new(0, 12)
mainCorner.Parent = mainFrame

-- Top bar
local topBar = Instance.new("Frame")
topBar.Name = "TopBar"
topBar.Size = UDim2.new(1, 0, 0, isMobile() and 60 or 50)
topBar.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
topBar.BorderSizePixel = 0
topBar.ZIndex = 11
topBar.Parent = mainFrame

local topCorner = Instance.new("UICorner")
topCorner.CornerRadius = UDim.new(0, 12)
topCorner.Parent = topBar

-- Title
local titleLabel = Instance.new("TextLabel")
titleLabel.Name = "TitleLabel"
titleLabel.Size = UDim2.new(0.6, 0, 0, isMobile() and 40 or 35)
titleLabel.Position = UDim2.new(0, 15, 0, 0)
titleLabel.BackgroundTransparency = 1
titleLabel.Text = "🏪 Marketplace"
titleLabel.TextColor3 = Color3.new(1, 1, 1)
titleLabel.TextSize = isMobile() and 20 or 24
titleLabel.Font = Enum.Font.GothamBold
titleLabel.TextXAlignment = Enum.TextXAlignment.Left
titleLabel.ZIndex = 12
titleLabel.Parent = topBar

-- Close button
local closeButton = Instance.new("TextButton")
closeButton.Name = "CloseButton"
closeButton.Size = UDim2.new(0, isMobile() and 50 or 40, 0, isMobile() and 50 or 40)
closeButton.Position = UDim2.new(1, isMobile() and -55 or -45, 0, 5)
closeButton.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
closeButton.Text = "✖"
closeButton.TextColor3 = Color3.new(1, 1, 1)
closeButton.TextSize = isMobile() and 22 or 20
closeButton.Font = Enum.Font.GothamBold
closeButton.ZIndex = 12
closeButton.Parent = topBar

local closeCorner = Instance.new("UICorner")
closeCorner.CornerRadius = UDim.new(0, 8)
closeCorner.Parent = closeButton

-- Tabs (Buy/Sell)
local tabFrame = Instance.new("Frame")
tabFrame.Size = UDim2.new(1, -20, 0, isMobile() and 50 or 40)
tabFrame.Position = UDim2.new(0, 10, 0, isMobile() and 65 or 55)
tabFrame.BackgroundTransparency = 1
tabFrame.ZIndex = 11
tabFrame.Parent = mainFrame

local buyTab = Instance.new("TextButton")
buyTab.Name = "BuyTab"
buyTab.Size = UDim2.new(0.48, 0, 1, 0)
buyTab.Position = UDim2.new(0, 0, 0, 0)
buyTab.BackgroundColor3 = Color3.fromRGB(70, 130, 70)
buyTab.Text = "🛒 Buy"
buyTab.TextColor3 = Color3.new(1, 1, 1)
buyTab.TextSize = isMobile() and 18 or 16
buyTab.Font = Enum.Font.GothamBold
buyTab.ZIndex = 12
buyTab.Parent = tabFrame

local buyCorner = Instance.new("UICorner")
buyCorner.CornerRadius = UDim.new(0, 8)
buyCorner.Parent = buyTab

local sellTab = Instance.new("TextButton")
sellTab.Name = "SellTab"
sellTab.Size = UDim2.new(0.48, 0, 1, 0)
sellTab.Position = UDim2.new(0.52, 0, 0, 0)
sellTab.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
sellTab.Text = "💰 Sell"
sellTab.TextColor3 = Color3.new(1, 1, 1)
sellTab.TextSize = isMobile() and 18 or 16
sellTab.Font = Enum.Font.GothamBold
sellTab.ZIndex = 12
sellTab.Parent = tabFrame

local sellCorner = Instance.new("UICorner")
sellCorner.CornerRadius = UDim.new(0, 8)
sellCorner.Parent = sellTab

-- Sort dropdown
local sortFrame = Instance.new("Frame")
sortFrame.Size = UDim2.new(1, -20, 0, isMobile() and 40 or 35)
sortFrame.Position = UDim2.new(0, 10, 0, isMobile() and 125 or 105)
sortFrame.BackgroundTransparency = 1
sortFrame.ZIndex = 11
sortFrame.Parent = mainFrame

local sortLabel = Instance.new("TextLabel")
sortLabel.Size = UDim2.new(0, isMobile() and 80 or 70, 1, 0)
sortLabel.BackgroundTransparency = 1
sortLabel.Text = "Sort by:"
sortLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
sortLabel.TextSize = isMobile() and 15 or 14
sortLabel.Font = Enum.Font.Gotham
sortLabel.TextXAlignment = Enum.TextXAlignment.Left
sortLabel.ZIndex = 12
sortLabel.Parent = sortFrame

local sortDropdown = Instance.new("TextButton")
sortDropdown.Name = "SortDropdown"
sortDropdown.Size = UDim2.new(0, isMobile() and 180 or 150, 1, 0)
sortDropdown.Position = UDim2.new(0, isMobile() and 90 or 80, 0, 0)
sortDropdown.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
sortDropdown.Text = "Newest First ▼"
sortDropdown.TextColor3 = Color3.new(1, 1, 1)
sortDropdown.TextSize = isMobile() and 14 or 13
sortDropdown.Font = Enum.Font.Gotham
sortDropdown.ZIndex = 12
sortDropdown.Parent = sortFrame

local sortCorner = Instance.new("UICorner")
sortCorner.CornerRadius = UDim.new(0, 6)
sortCorner.Parent = sortDropdown

-- Refresh button
local refreshButton = Instance.new("TextButton")
refreshButton.Size = UDim2.new(0, isMobile() and 100 or 80, 1, 0)
refreshButton.Position = UDim2.new(1, isMobile() and -100 or -80, 0, 0)
refreshButton.BackgroundColor3 = Color3.fromRGB(70, 130, 180)
refreshButton.Text = "🔄"
refreshButton.TextSize = isMobile() and 20 or 18
refreshButton.Font = Enum.Font.GothamBold
refreshButton.ZIndex = 12
refreshButton.Parent = sortFrame

local refreshCorner = Instance.new("UICorner")
refreshCorner.CornerRadius = UDim.new(0, 6)
refreshCorner.Parent = refreshButton

-- Content scroll frame
local contentScroll = Instance.new("ScrollingFrame")
contentScroll.Name = "ContentScroll"
contentScroll.Size = UDim2.new(1, -20, 1, isMobile() and -175 or -155)
contentScroll.Position = UDim2.new(0, 10, 0, isMobile() and 175 or 155)
contentScroll.BackgroundColor3 = Color3.fromRGB(45, 45, 45)
contentScroll.BorderSizePixel = 0
contentScroll.ScrollBarThickness = 8
contentScroll.ZIndex = 11
contentScroll.Parent = mainFrame

local contentCorner = Instance.new("UICorner")
contentCorner.CornerRadius = UDim.new(0, 8)
contentCorner.Parent = contentScroll

-- ============================================
-- MARKETPLACE CLIENT LOGIC
-- ============================================
-- State variables
local currentBuilding = nil
local currentTab = "Buy"
local currentSort = "Newest"
local currentListings = {}

-- ============================================
-- PURCHASE CONFIRMATION DIALOG
-- ============================================
local function showPurchaseConfirmation(listing)
	-- Create overlay
	local overlay = Instance.new("Frame")
	overlay.Name = "PurchaseOverlay"
	overlay.Size = UDim2.new(1, 0, 1, 0)
	overlay.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
	overlay.BackgroundTransparency = 0.5
	overlay.BorderSizePixel = 0
	overlay.ZIndex = 50
	overlay.Parent = screenGui

	-- Confirmation dialog
	local dialog = Instance.new("Frame")
	dialog.Size = isMobile() and UDim2.new(0.85, 0, 0, 250) or UDim2.new(0.4, 0, 0, 220)
	dialog.Position = isMobile() and UDim2.new(0.075, 0, 0.3, 0) or UDim2.new(0.3, 0, 0.35, 0)
	dialog.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
	dialog.BorderSizePixel = 0
	dialog.ZIndex = 51
	dialog.Parent = overlay

	local dialogCorner = Instance.new("UICorner")
	dialogCorner.CornerRadius = UDim.new(0, 12)
	dialogCorner.Parent = dialog

	-- Title
	local title = Instance.new("TextLabel")
	title.Size = UDim2.new(1, 0, 0, 40)
	title.BackgroundTransparency = 1
	title.Text = "Confirm Purchase"
	title.TextColor3 = Color3.new(1, 1, 1)
	title.TextSize = isMobile() and 20 or 22
	title.Font = Enum.Font.GothamBold
	title.ZIndex = 52
	title.Parent = dialog

	-- Item details
	local details = Instance.new("TextLabel")
	details.Size = UDim2.new(1, -20, 0, 80)
	details.Position = UDim2.new(0, 10, 0, 50)
	details.BackgroundTransparency = 1
	details.Text = string.format(
		"Item: %s\nQuantity: %d\nPrice per unit: $%d\nTotal: $%d",
		listing.ItemName,
		listing.Quantity,
		listing.PricePerUnit,
		listing.Quantity * listing.PricePerUnit
	)
	details.TextColor3 = Color3.fromRGB(220, 220, 220)
	details.TextSize = isMobile() and 14 or 15
	details.Font = Enum.Font.Gotham
	details.TextWrapped = true
	details.TextXAlignment = Enum.TextXAlignment.Left
	details.TextYAlignment = Enum.TextYAlignment.Top
	details.ZIndex = 52
	details.Parent = dialog

	-- Warning
	local warning = Instance.new("TextLabel")
	warning.Size = UDim2.new(1, -20, 0, 35)
	warning.Position = UDim2.new(0, 10, 0, 135)
	warning.BackgroundTransparency = 1
	warning.Text = "⚠️ Items will be sent to your Farm inventory"
	warning.TextColor3 = Color3.fromRGB(255, 200, 100)
	warning.TextSize = isMobile() and 12 or 13
	warning.Font = Enum.Font.Gotham
	warning.TextWrapped = true
	warning.ZIndex = 52
	warning.Parent = dialog

	-- Confirm button
	local confirmBtn = Instance.new("TextButton")
	confirmBtn.Size = UDim2.new(0.45, 0, 0, 40)
	confirmBtn.Position = UDim2.new(0.05, 0, 1, -50)
	confirmBtn.BackgroundColor3 = Color3.fromRGB(70, 150, 70)
	confirmBtn.Text = "Confirm"
	confirmBtn.TextColor3 = Color3.new(1, 1, 1)
	confirmBtn.TextSize = isMobile() and 16 or 18
	confirmBtn.Font = Enum.Font.GothamBold
	confirmBtn.ZIndex = 52
	confirmBtn.Parent = dialog

	local confirmCorner = Instance.new("UICorner")
	confirmCorner.CornerRadius = UDim.new(0, 8)
	confirmCorner.Parent = confirmBtn

	-- Cancel button
	local cancelBtn = Instance.new("TextButton")
	cancelBtn.Size = UDim2.new(0.45, 0, 0, 40)
	cancelBtn.Position = UDim2.new(0.5, 0, 1, -50)
	cancelBtn.BackgroundColor3 = Color3.fromRGB(150, 50, 50)
	cancelBtn.Text = "Cancel"
	cancelBtn.TextColor3 = Color3.new(1, 1, 1)
	cancelBtn.TextSize = isMobile() and 16 or 18
	cancelBtn.Font = Enum.Font.GothamBold
	cancelBtn.ZIndex = 52
	cancelBtn.Parent = dialog

	local cancelCorner = Instance.new("UICorner")
	cancelCorner.CornerRadius = UDim.new(0, 8)
	cancelCorner.Parent = cancelBtn

	-- Confirm action
	confirmBtn.MouseButton1Click:Connect(function()
		-- Send purchase request
		local PurchaseItemEvent = ReplicatedStorage:WaitForChild("PurchaseItemEvent")
		PurchaseItemEvent:FireServer(listing.ListingId, currentBuilding)

		overlay:Destroy()
	end)

	-- Cancel action
	cancelBtn.MouseButton1Click:Connect(function()
		overlay:Destroy()
	end)
end

-- ============================================
-- LISTING DIALOG (Town - Non-VIP)
-- ============================================
local function showListingDialog(building)
	-- Create overlay
	local overlay = Instance.new("Frame")
	overlay.Name = "ListingOverlay"
	overlay.Size = UDim2.new(1, 0, 1, 0)
	overlay.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
	overlay.BackgroundTransparency = 0.5
	overlay.BorderSizePixel = 0
	overlay.ZIndex = 50
	overlay.Parent = screenGui

	-- Dialog
	local dialog = Instance.new("Frame")
	dialog.Size = isMobile() and UDim2.new(0.9, 0, 0, 350) or UDim2.new(0.5, 0, 0, 320)
	dialog.Position = isMobile() and UDim2.new(0.05, 0, 0.25, 0) or UDim2.new(0.25, 0, 0.3, 0)
	dialog.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
	dialog.BorderSizePixel = 0
	dialog.ZIndex = 51
	dialog.Parent = overlay

	local dialogCorner = Instance.new("UICorner")
	dialogCorner.CornerRadius = UDim.new(0, 12)
	dialogCorner.Parent = dialog

	-- Title
	local title = Instance.new("TextLabel")
	title.Size = UDim2.new(1, 0, 0, 40)
	title.BackgroundTransparency = 1
	title.Text = building.Icon .. " List Item - " .. building.Name
	title.TextColor3 = Color3.new(1, 1, 1)
	title.TextSize = isMobile() and 18 or 20
	title.Font = Enum.Font.GothamBold
	title.ZIndex = 52
	title.Parent = dialog

	-- Category dropdown (simplified - just show allowed categories)
	local categoryLabel = Instance.new("TextLabel")
	categoryLabel.Size = UDim2.new(0, isMobile() and 100 or 90, 0, 25)
	categoryLabel.Position = UDim2.new(0, 15, 0, 55)
	categoryLabel.BackgroundTransparency = 1
	categoryLabel.Text = "Category:"
	categoryLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
	categoryLabel.TextSize = isMobile() and 14 or 15
	categoryLabel.Font = Enum.Font.Gotham
	categoryLabel.TextXAlignment = Enum.TextXAlignment.Left
	categoryLabel.ZIndex = 52
	categoryLabel.Parent = dialog

	local categoryInput = Instance.new("TextBox")
	categoryInput.Size = UDim2.new(1, isMobile() and -130 or -120, 0, 30)
	categoryInput.Position = UDim2.new(0, isMobile() and 115 or 105, 0, 52)
	categoryInput.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
	categoryInput.Text = building.AllowedCategories[1] or "Crops"
	categoryInput.TextColor3 = Color3.new(1, 1, 1)
	categoryInput.TextSize = isMobile() and 14 or 15
	categoryInput.Font = Enum.Font.Gotham
	categoryInput.PlaceholderText = "e.g., Crops, Products"
	categoryInput.ZIndex = 52
	categoryInput.Parent = dialog

	local catCorner = Instance.new("UICorner")
	catCorner.CornerRadius = UDim.new(0, 6)
	catCorner.Parent = categoryInput

	-- Item name
	local itemLabel = Instance.new("TextLabel")
	itemLabel.Size = UDim2.new(0, isMobile() and 100 or 90, 0, 25)
	itemLabel.Position = UDim2.new(0, 15, 0, 100)
	itemLabel.BackgroundTransparency = 1
	itemLabel.Text = "Item Name:"
	itemLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
	itemLabel.TextSize = isMobile() and 14 or 15
	itemLabel.Font = Enum.Font.Gotham
	itemLabel.TextXAlignment = Enum.TextXAlignment.Left
	itemLabel.ZIndex = 52
	itemLabel.Parent = dialog

	local itemInput = Instance.new("TextBox")
	itemInput.Size = UDim2.new(1, isMobile() and -130 or -120, 0, 30)
	itemInput.Position = UDim2.new(0, isMobile() and 115 or 105, 0, 97)
	itemInput.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
	itemInput.Text = ""
	itemInput.TextColor3 = Color3.new(1, 1, 1)
	itemInput.TextSize = isMobile() and 14 or 15
	itemInput.Font = Enum.Font.Gotham
	itemInput.PlaceholderText = "e.g., Wheat, Eggs"
	itemInput.ZIndex = 52
	itemInput.Parent = dialog

	local itemCorner = Instance.new("UICorner")
	itemCorner.CornerRadius = UDim.new(0, 6)
	itemCorner.Parent = itemInput

	-- Quantity
	local qtyLabel = Instance.new("TextLabel")
	qtyLabel.Size = UDim2.new(0, isMobile() and 100 or 90, 0, 25)
	qtyLabel.Position = UDim2.new(0, 15, 0, 145)
	qtyLabel.BackgroundTransparency = 1
	qtyLabel.Text = "Quantity:"
	qtyLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
	qtyLabel.TextSize = isMobile() and 14 or 15
	qtyLabel.Font = Enum.Font.Gotham
	qtyLabel.TextXAlignment = Enum.TextXAlignment.Left
	qtyLabel.ZIndex = 52
	qtyLabel.Parent = dialog

	local qtyInput = Instance.new("TextBox")
	qtyInput.Size = UDim2.new(1, isMobile() and -130 or -120, 0, 30)
	qtyInput.Position = UDim2.new(0, isMobile() and 115 or 105, 0, 142)
	qtyInput.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
	qtyInput.Text = "1"
	qtyInput.TextColor3 = Color3.new(1, 1, 1)
	qtyInput.TextSize = isMobile() and 14 or 15
	qtyInput.Font = Enum.Font.Gotham
	qtyInput.PlaceholderText = "Enter quantity"
	qtyInput.ZIndex = 52
	qtyInput.Parent = dialog

	local qtyCorner = Instance.new("UICorner")
	qtyCorner.CornerRadius = UDim.new(0, 6)
	qtyCorner.Parent = qtyInput

	-- Price per unit
	local priceLabel = Instance.new("TextLabel")
	priceLabel.Size = UDim2.new(0, isMobile() and 100 or 90, 0, 25)
	priceLabel.Position = UDim2.new(0, 15, 0, 190)
	priceLabel.BackgroundTransparency = 1
	priceLabel.Text = "Price Each:"
	priceLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
	priceLabel.TextSize = isMobile() and 14 or 15
	priceLabel.Font = Enum.Font.Gotham
	priceLabel.TextXAlignment = Enum.TextXAlignment.Left
	priceLabel.ZIndex = 52
	priceLabel.Parent = dialog

	local priceInput = Instance.new("TextBox")
	priceInput.Size = UDim2.new(1, isMobile() and -130 or -120, 0, 30)
	priceInput.Position = UDim2.new(0, isMobile() and 115 or 105, 0, 187)
	priceInput.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
	priceInput.Text = "50"
	priceInput.TextColor3 = Color3.new(1, 1, 1)
	priceInput.TextSize = isMobile() and 14 or 15
	priceInput.Font = Enum.Font.Gotham
	priceInput.PlaceholderText = "Price per unit"
	priceInput.ZIndex = 52
	priceInput.Parent = dialog

	local priceCorner = Instance.new("UICorner")
	priceCorner.CornerRadius = UDim.new(0, 6)
	priceCorner.Parent = priceInput

	-- Total preview
	local totalPreview = Instance.new("TextLabel")
	totalPreview.Size = UDim2.new(1, -30, 0, 25)
	totalPreview.Position = UDim2.new(0, 15, 0, 235)
	totalPreview.BackgroundTransparency = 1
	totalPreview.Text = "Total: $0"
	totalPreview.TextColor3 = Color3.fromRGB(100, 200, 100)
	totalPreview.TextSize = isMobile() and 16 or 17
	totalPreview.Font = Enum.Font.GothamBold
	totalPreview.TextXAlignment = Enum.TextXAlignment.Left
	totalPreview.ZIndex = 52
	totalPreview.Parent = dialog

	-- Update total on input
	local function updateTotal()
		local qty = tonumber(qtyInput.Text) or 0
		local price = tonumber(priceInput.Text) or 0
		totalPreview.Text = "Total: $" .. (qty * price)
	end

	qtyInput:GetPropertyChangedSignal("Text"):Connect(updateTotal)
	priceInput:GetPropertyChangedSignal("Text"):Connect(updateTotal)

	-- List button
	local listBtn = Instance.new("TextButton")
	listBtn.Size = UDim2.new(0.45, 0, 0, 45)
	listBtn.Position = UDim2.new(0.05, 0, 1, -55)
	listBtn.BackgroundColor3 = Color3.fromRGB(70, 150, 70)
	listBtn.Text = "List Item"
	listBtn.TextColor3 = Color3.new(1, 1, 1)
	listBtn.TextSize = isMobile() and 16 or 18
	listBtn.Font = Enum.Font.GothamBold
	listBtn.ZIndex = 52
	listBtn.Parent = dialog

	local listBtnCorner = Instance.new("UICorner")
	listBtnCorner.CornerRadius = UDim.new(0, 8)
	listBtnCorner.Parent = listBtn

	-- Cancel button
	local cancelBtn = Instance.new("TextButton")
	cancelBtn.Size = UDim2.new(0.45, 0, 0, 45)
	cancelBtn.Position = UDim2.new(0.5, 0, 1, -55)
	cancelBtn.BackgroundColor3 = Color3.fromRGB(150, 50, 50)
	cancelBtn.Text = "Cancel"
	cancelBtn.TextColor3 = Color3.new(1, 1, 1)
	cancelBtn.TextSize = isMobile() and 16 or 18
	cancelBtn.Font = Enum.Font.GothamBold
	cancelBtn.ZIndex = 52
	cancelBtn.Parent = dialog

	local cancelBtnCorner = Instance.new("UICorner")
	cancelBtnCorner.CornerRadius = UDim.new(0, 8)
	cancelBtnCorner.Parent = cancelBtn

	-- List action
	listBtn.MouseButton1Click:Connect(function()
		local category = categoryInput.Text
		local itemName = itemInput.Text
		local qty = tonumber(qtyInput.Text)
		local price = tonumber(priceInput.Text)

		if not itemName or itemName == "" then
			warn("Item name required")
			return
		end

		if not qty or qty <= 0 then
			warn("Invalid quantity")
			return
		end

		if not price or price <= 0 then
			warn("Invalid price")
			return
		end

		-- Send to server
		local ListItemEvent = ReplicatedStorage:WaitForChild("ListItemEvent")
		ListItemEvent:FireServer(itemName, qty, price, category, currentBuilding)

		overlay:Destroy()
	end)

	-- Cancel action
	cancelBtn.MouseButton1Click:Connect(function()
		overlay:Destroy()
	end)
end

-- ============================================
-- LISTING CARD CREATION
-- ============================================
local function createListingCard(listing, yOffset)
	local card = Instance.new("Frame")
	card.Name = "ListingCard_" .. listing.ListingId
	card.Size = isMobile() and UDim2.new(1, -10, 0, 110) or UDim2.new(1, -10, 0, 90)
	card.Position = UDim2.new(0, 5, 0, yOffset)
	card.BackgroundColor3 = listing.IsVIPListing and Color3.fromRGB(60, 60, 80) or Color3.fromRGB(50, 50, 50)
	card.BorderSizePixel = 0
	card.ZIndex = 12
	card.Parent = contentScroll

	local cardCorner = Instance.new("UICorner")
	cardCorner.CornerRadius = UDim.new(0, 8)
	cardCorner.Parent = card

	-- VIP badge (if applicable)
	if listing.IsVIPListing then
		local vipBadge = Instance.new("TextLabel")
		vipBadge.Size = UDim2.new(0, 45, 0, 20)
		vipBadge.Position = UDim2.new(0, 5, 0, 5)
		vipBadge.BackgroundColor3 = Color3.fromRGB(255, 215, 0)
		vipBadge.Text = "VIP"
		vipBadge.TextColor3 = Color3.fromRGB(0, 0, 0)
		vipBadge.TextSize = 10
		vipBadge.Font = Enum.Font.GothamBold
		vipBadge.ZIndex = 13
		vipBadge.Parent = card

		local vipCorner = Instance.new("UICorner")
		vipCorner.CornerRadius = UDim.new(0, 4)
		vipCorner.Parent = vipBadge
	end

	-- Item name
	local itemName = Instance.new("TextLabel")
	itemName.Size = isMobile() and UDim2.new(0.55, 0, 0, 25) or UDim2.new(0.6, 0, 0, 25)
	itemName.Position = UDim2.new(0, 10, 0, listing.IsVIPListing and 30 or 10)
	itemName.BackgroundTransparency = 1
	itemName.Text = listing.ItemName
	itemName.TextColor3 = Color3.fromRGB(220, 220, 220)
	itemName.TextSize = isMobile() and 16 or 18
	itemName.Font = Enum.Font.GothamBold
	itemName.TextXAlignment = Enum.TextXAlignment.Left
	itemName.ZIndex = 13
	itemName.Parent = card

	-- Quantity
	local quantity = Instance.new("TextLabel")
	quantity.Size = UDim2.new(0, isMobile() and 80 or 100, 0, 20)
	quantity.Position = UDim2.new(0, 10, 0, listing.IsVIPListing and 55 or 35)
	quantity.BackgroundTransparency = 1
	quantity.Text = "Qty: " .. listing.Quantity
	quantity.TextColor3 = Color3.fromRGB(150, 200, 150)
	quantity.TextSize = isMobile() and 13 or 14
	quantity.Font = Enum.Font.Gotham
	quantity.TextXAlignment = Enum.TextXAlignment.Left
	quantity.ZIndex = 13
	quantity.Parent = card

	-- Price per unit
	local pricePerUnit = Instance.new("TextLabel")
	pricePerUnit.Size = UDim2.new(0, isMobile() and 100 or 120, 0, 20)
	pricePerUnit.Position = UDim2.new(0, 10, 0, listing.IsVIPListing and 75 or 55)
	pricePerUnit.BackgroundTransparency = 1
	pricePerUnit.Text = "$" .. listing.PricePerUnit .. " each"
	pricePerUnit.TextColor3 = Color3.fromRGB(200, 200, 100)
	pricePerUnit.TextSize = isMobile() and 12 or 13
	pricePerUnit.Font = Enum.Font.Gotham
	pricePerUnit.TextXAlignment = Enum.TextXAlignment.Left
	pricePerUnit.ZIndex = 13
	pricePerUnit.Parent = card

	-- Total price
	local totalPrice = listing.Quantity * listing.PricePerUnit
	local totalLabel = Instance.new("TextLabel")
	totalLabel.Size = isMobile() and UDim2.new(0.4, 0, 0, 30) or UDim2.new(0.35, 0, 0, 30)
	totalLabel.Position = isMobile() and UDim2.new(0.55, 0, 0, 10) or UDim2.new(0.6, 0, 0, 10)
	totalLabel.BackgroundTransparency = 1
	totalLabel.Text = "Total: $" .. totalPrice
	totalLabel.TextColor3 = Color3.new(1, 1, 1)
	totalLabel.TextSize = isMobile() and 16 or 18
	totalLabel.Font = Enum.Font.GothamBold
	totalLabel.TextXAlignment = Enum.TextXAlignment.Right
	totalLabel.ZIndex = 13
	totalLabel.Parent = card

	-- Seller name
	local seller = Instance.new("TextLabel")
	seller.Size = isMobile() and UDim2.new(0.4, 0, 0, 18) or UDim2.new(0.35, 0, 0, 18)
	seller.Position = isMobile() and UDim2.new(0.55, 0, 0, 45) or UDim2.new(0.6, 0, 0, 40)
	seller.BackgroundTransparency = 1
	seller.Text = "Seller: " .. listing.SellerName
	seller.TextColor3 = Color3.fromRGB(150, 150, 150)
	seller.TextSize = isMobile() and 11 or 12
	seller.Font = Enum.Font.Gotham
	seller.TextXAlignment = Enum.TextXAlignment.Right
	seller.ZIndex = 13
	seller.Parent = card

	-- Buy button
	local buyButton = Instance.new("TextButton")
	buyButton.Size = isMobile() and UDim2.new(0.35, 0, 0, 35) or UDim2.new(0.3, 0, 0, 30)
	buyButton.Position = isMobile() and UDim2.new(0.6, 0, 1, -40) or UDim2.new(0.65, 0, 1, -35)
	buyButton.BackgroundColor3 = Color3.fromRGB(70, 150, 70)
	buyButton.Text = "Buy Now"
	buyButton.TextColor3 = Color3.new(1, 1, 1)
	buyButton.TextSize = isMobile() and 14 or 15
	buyButton.Font = Enum.Font.GothamBold
	buyButton.ZIndex = 13
	buyButton.Parent = card

	local buyCorner = Instance.new("UICorner")
	buyCorner.CornerRadius = UDim.new(0, 6)
	buyCorner.Parent = buyButton

	-- Buy button action
	buyButton.MouseButton1Click:Connect(function()
		-- Show confirmation dialog
		showPurchaseConfirmation(listing)
	end)

	return card
end

-- ============================================
-- REFRESH LISTINGS DISPLAY
-- ============================================
local function refreshListingsDisplay()
	-- Clear existing cards
	for _, child in ipairs(contentScroll:GetChildren()) do
		if child.Name:match("ListingCard_") then
			child:Destroy()
		end
	end

	-- Show empty state if no listings
	if #currentListings == 0 then
		local emptyLabel = Instance.new("TextLabel")
		emptyLabel.Name = "EmptyLabel"
		emptyLabel.Size = UDim2.new(1, -20, 0, 100)
		emptyLabel.Position = UDim2.new(0, 10, 0, 50)
		emptyLabel.BackgroundTransparency = 1
		emptyLabel.Text = "No listings available\nCheck back later!"
		emptyLabel.TextColor3 = Color3.fromRGB(150, 150, 150)
		emptyLabel.TextSize = isMobile() and 16 or 18
		emptyLabel.Font = Enum.Font.Gotham
		emptyLabel.TextWrapped = true
		emptyLabel.ZIndex = 12
		emptyLabel.Parent = contentScroll

		contentScroll.CanvasSize = UDim2.new(0, 0, 0, 200)
		return
	end

	-- Create listing cards
	local yOffset = 5
	for _, listing in ipairs(currentListings) do
		createListingCard(listing, yOffset)
		yOffset = yOffset + (isMobile() and 115 or 95)
	end

	contentScroll.CanvasSize = UDim2.new(0, 0, 0, yOffset + 10)
end

-- ============================================
-- LOAD LISTINGS FROM SERVER
-- ============================================
local function loadListings()
	if not currentBuilding then return end

	print("🔄 Loading listings for: " .. currentBuilding)

	-- Show loading indicator
	for _, child in ipairs(contentScroll:GetChildren()) do
		if child.Name:match("ListingCard_") or child.Name == "EmptyLabel" then
			child:Destroy()
		end
	end

	local loadingLabel = Instance.new("TextLabel")
	loadingLabel.Name = "LoadingLabel"
	loadingLabel.Size = UDim2.new(1, -20, 0, 50)
	loadingLabel.Position = UDim2.new(0, 10, 0, 50)
	loadingLabel.BackgroundTransparency = 1
	loadingLabel.Text = "Loading..."
	loadingLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
	loadingLabel.TextSize = isMobile() and 16 or 18
	loadingLabel.Font = Enum.Font.Gotham
	loadingLabel.ZIndex = 12
	loadingLabel.Parent = contentScroll

	-- Request from server
	local RefreshMarketplaceEvent = ReplicatedStorage:WaitForChild("RefreshMarketplaceEvent")
	RefreshMarketplaceEvent:FireServer(currentBuilding, currentSort)
end

-- ============================================
-- SELL TAB FUNCTIONALITY
-- ============================================
local function showSellInterface()
	-- Clear content
	for _, child in ipairs(contentScroll:GetChildren()) do
		child:Destroy()
	end

	-- Warning message
	local warningLabel = Instance.new("TextLabel")
	warningLabel.Size = UDim2.new(1, -20, 0, 80)
	warningLabel.Position = UDim2.new(0, 10, 0, 20)
	warningLabel.BackgroundColor3 = Color3.fromRGB(60, 60, 100)
	warningLabel.Text = "⚠️ To list items, you need:\n• VIP GamePass (list from Farm)\n• OR use this building (deducts from Farm inventory)"
	warningLabel.TextColor3 = Color3.fromRGB(220, 220, 255)
	warningLabel.TextSize = isMobile() and 13 or 14
	warningLabel.Font = Enum.Font.Gotham
	warningLabel.TextWrapped = true
	warningLabel.ZIndex = 12
	warningLabel.Parent = contentScroll

	local warningCorner = Instance.new("UICorner")
	warningCorner.CornerRadius = UDim.new(0, 8)
	warningCorner.Parent = warningLabel

	-- Get building info
	local building = TownBuildingConfig.GetBuilding(currentBuilding)
	if not building then return end

	-- Instruction
	local instruction = Instance.new("TextLabel")
	instruction.Size = UDim2.new(1, -20, 0, 60)
	instruction.Position = UDim2.new(0, 10, 0, 110)
	instruction.BackgroundTransparency = 1
	instruction.Text = "This " .. building.Name .. " accepts:\n" .. table.concat(building.AllowedCategories, ", ")
	instruction.TextColor3 = Color3.fromRGB(200, 200, 200)
	instruction.TextSize = isMobile() and 14 or 15
	instruction.Font = Enum.Font.GothamBold
	instruction.TextWrapped = true
	instruction.ZIndex = 12
	instruction.Parent = contentScroll

	-- List new item button
	local listButton = Instance.new("TextButton")
	listButton.Size = isMobile() and UDim2.new(0.9, 0, 0, 50) or UDim2.new(0.6, 0, 0, 45)
	listButton.Position = isMobile() and UDim2.new(0.05, 0, 0, 190) or UDim2.new(0.2, 0, 0, 180)
	listButton.BackgroundColor3 = Color3.fromRGB(70, 150, 70)
	listButton.Text = "📦 List New Item"
	listButton.TextColor3 = Color3.new(1, 1, 1)
	listButton.TextSize = isMobile() and 16 or 18
	listButton.Font = Enum.Font.GothamBold
	listButton.ZIndex = 12
	listButton.Parent = contentScroll

	local listCorner = Instance.new("UICorner")
	listCorner.CornerRadius = UDim.new(0, 8)
	listCorner.Parent = listButton

	-- List button action
	listButton.MouseButton1Click:Connect(function()
		showListingDialog(building)
	end)

	contentScroll.CanvasSize = UDim2.new(0, 0, 0, 300)
end

-- ============================================
-- TAB SWITCHING
-- ============================================
buyTab.MouseButton1Click:Connect(function()
	currentTab = "Buy"
	buyTab.BackgroundColor3 = Color3.fromRGB(70, 130, 70)
	sellTab.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
	loadListings()
end)

sellTab.MouseButton1Click:Connect(function()
	currentTab = "Sell"
	buyTab.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
	sellTab.BackgroundColor3 = Color3.fromRGB(70, 130, 70)
	showSellInterface()
end)

-- ============================================
-- SORT DROPDOWN
-- ============================================
local sortOptions = {"Newest", "PriceLow", "PriceHigh"}
local sortIndex = 1

sortDropdown.MouseButton1Click:Connect(function()
	sortIndex = (sortIndex % #sortOptions) + 1
	currentSort = sortOptions[sortIndex]

	local labels = {
		Newest = "Newest First ▼",
		PriceLow = "Price: Low to High ▼",
		PriceHigh = "Price: High to Low ▼"
	}

	sortDropdown.Text = labels[currentSort]

	if currentTab == "Buy" then
		loadListings()
	end
end)

-- ============================================
-- REFRESH BUTTON
-- ============================================
refreshButton.MouseButton1Click:Connect(function()
	if currentTab == "Buy" then
		loadListings()
	else
		showSellInterface()
	end
end)

-- ============================================
-- CLOSE BUTTON
-- ============================================
closeButton.MouseButton1Click:Connect(function()
	mainFrame.Visible = false
	currentBuilding = nil
end)

-- ============================================
-- REMOTE EVENT LISTENERS
-- ============================================

-- Open marketplace
OpenMarketplaceEvent.OnClientEvent:Connect(function(buildingId)
	currentBuilding = buildingId

	-- Update title
	local building = TownBuildingConfig.GetBuilding(buildingId)
	if building then
		titleLabel.Text = building.Icon .. " " .. building.Name
		topBar.BackgroundColor3 = building.Color
	end

	-- Show UI
	mainFrame.Visible = true
	currentTab = "Buy"
	buyTab.BackgroundColor3 = Color3.fromRGB(70, 130, 70)
	sellTab.BackgroundColor3 = Color3.fromRGB(50, 50, 50)

	-- Load listings
	loadListings()
end)

-- Receive listings
RefreshMarketplaceEvent.OnClientEvent:Connect(function(listings)
	currentListings = listings
	refreshListingsDisplay()
end)

-- Purchase response
PurchaseItemEvent.OnClientEvent:Connect(function(success, message)
	-- Show notification
	local notification = Instance.new("TextLabel")
	notification.Size = isMobile() and UDim2.new(0.8, 0, 0, 60) or UDim2.new(0.4, 0, 0, 50)
	notification.Position = isMobile() and UDim2.new(0.1, 0, 0.45, 0) or UDim2.new(0.3, 0, 0.45, 0)
	notification.BackgroundColor3 = success and Color3.fromRGB(70, 150, 70) or Color3.fromRGB(150, 50, 50)
	notification.Text = message
	notification.TextColor3 = Color3.new(1, 1, 1)
	notification.TextSize = isMobile() and 14 or 16
	notification.Font = Enum.Font.GothamBold
	notification.TextWrapped = true
	notification.ZIndex = 100
	notification.Parent = screenGui

	local notifCorner = Instance.new("UICorner")
	notifCorner.CornerRadius = UDim.new(0, 10)
	notifCorner.Parent = notification

	-- Fade out
	task.delay(3, function()
		notification:Destroy()
		-- Refresh listings if purchase successful
		if success and currentTab == "Buy" then
			loadListings()
		end
	end)
end)

-- Listing response
ListItemEvent.OnClientEvent:Connect(function(success, message)
	-- Show notification
	local notification = Instance.new("TextLabel")
	notification.Size = isMobile() and UDim2.new(0.8, 0, 0, 60) or UDim2.new(0.4, 0, 0, 50)
	notification.Position = isMobile() and UDim2.new(0.1, 0, 0.45, 0) or UDim2.new(0.3, 0, 0.45, 0)
	notification.BackgroundColor3 = success and Color3.fromRGB(70, 150, 70) or Color3.fromRGB(150, 50, 50)
	notification.Text = message
	notification.TextColor3 = Color3.new(1, 1, 1)
	notification.TextSize = isMobile() and 14 or 16
	notification.Font = Enum.Font.GothamBold
	notification.TextWrapped = true
	notification.ZIndex = 100
	notification.Parent = screenGui

	local notifCorner = Instance.new("UICorner")
	notifCorner.CornerRadius = UDim.new(0, 10)
	notifCorner.Parent = notification

	task.delay(3, function()
		notification:Destroy()
	end)
end)

print("✅ Marketplace Client loaded")