-- ProductHubClient.lua (StarterPlayerScripts - LocalScript)
-- Handles Animal Product Hub GUI (formerly PoultryShop)

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

-- Remote Events
local SellProductEvent = ReplicatedStorage:WaitForChild("SellProductEvent")
local ConvertProductEvent = ReplicatedStorage:WaitForChild("ConvertProductEvent")
local ListItemEvent = ReplicatedStorage:WaitForChild("ListItemEvent")

print("🐔 ProductHubClient loaded!")

-- ============================================
-- GUI CONFIGURATION
-- ============================================

local GUI_CONFIG = {
	IsMobile = UserInputService.TouchEnabled and not UserInputService.KeyboardEnabled,

	BackgroundColor = Color3.fromRGB(40, 40, 40),
	HeaderColor = Color3.fromRGB(60, 60, 60),
	SellButtonColor = Color3.fromRGB(80, 200, 80),
	ConvertButtonColor = Color3.fromRGB(100, 150, 255),
	ListButtonColor = Color3.fromRGB(255, 150, 50),

	TextColor = Color3.fromRGB(255, 255, 255),
}

-- Product quick-sell prices (from ProductConfig)
local QUICK_SELL_PRICES = {
	Eggs = 15, Milk = 60, Meat = 40, Wool = 50
}

-- Product emojis
local PRODUCT_EMOJIS = {
	Eggs = "🥚", Milk = "🥛", Meat = "🥩", Wool = "🧶"
}

-- Conversion descriptions
local CONVERSIONS = {
	Eggs = "10 Eggs → 5 Wheat + 3 Corn Seeds",
	Milk = "5 Milk → 3 Carrot + 2 Potato Seeds",
	Meat = "3 Meat → 2 Tomato + 1 Pumpkin Seed",
	Wool = "5 Wool → 3 Strawberry + 1 Watermelon Seed"
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

-- ============================================
-- GET PLAYER PRODUCTS
-- ============================================

local function getPlayerProducts()
	local products = {}

	-- Animal products ONLY (exclude Honey and Wax - those are for beehives)
	local productInventory = player:FindFirstChild("ProductInventory")
	if productInventory then
		for _, productValue in pairs(productInventory:GetChildren()) do
			if productValue:IsA("IntValue") and productValue.Value > 0 
				and productValue.Name ~= "Honey" 
				and productValue.Name ~= "Wax" then
				table.insert(products, {
					Name = productValue.Name,
					Count = productValue.Value,
					Type = "Product"
				})
			end
		end
	end

	return products
end

-- ============================================
-- CREATE MAIN GUI
-- ============================================

local function createMainFrame()
	local screenGui = Instance.new("ScreenGui")
	screenGui.Name = "ProductHubGui"
	screenGui.ResetOnSpawn = false
	screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling

	local mainFrame = Instance.new("Frame")
	mainFrame.Name = "MainFrame"
	mainFrame.Size = UDim2.new(GUI_CONFIG.IsMobile and 0.95 or 0.6, 0, GUI_CONFIG.IsMobile and 0.85 or 0.7, 0)
	mainFrame.Position = UDim2.new(0.5, 0, 0.5, 0)
	mainFrame.AnchorPoint = Vector2.new(0.5, 0.5)
	mainFrame.BackgroundColor3 = GUI_CONFIG.BackgroundColor
	mainFrame.BorderSizePixel = 0
	mainFrame.Visible = false
	mainFrame.Parent = screenGui

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

	local title = Instance.new("TextLabel")
	title.Size = UDim2.new(0.8, 0, 1, 0)
	title.Position = UDim2.new(0.05, 0, 0, 0)
	title.BackgroundTransparency = 1
	title.Text = "🐔 Animal Products Hub"
	title.TextColor3 = GUI_CONFIG.TextColor
	title.TextScaled = true
	title.Font = Enum.Font.GothamBold
	title.TextXAlignment = Enum.TextXAlignment.Left
	title.Parent = header

	-- Close Button
	local closeButton = Instance.new("TextButton")
	closeButton.Size = UDim2.new(0, 50, 0, 50)
	closeButton.Position = UDim2.new(1, -55, 0, 5)
	closeButton.BackgroundColor3 = Color3.fromRGB(200, 80, 80)
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

	-- Content Container
	local contentContainer = Instance.new("ScrollingFrame")
	contentContainer.Name = "ContentContainer"
	contentContainer.Size = UDim2.new(1, -20, 1, -80)
	contentContainer.Position = UDim2.new(0, 10, 0, 70)
	contentContainer.BackgroundTransparency = 1
	contentContainer.BorderSizePixel = 0
	contentContainer.ScrollBarThickness = 8
	contentContainer.Parent = mainFrame

	local listLayout = Instance.new("UIListLayout")
	listLayout.Padding = UDim.new(0, 15)
	listLayout.SortOrder = Enum.SortOrder.LayoutOrder
	listLayout.Parent = contentContainer

	screenGui.Parent = playerGui

	return screenGui, mainFrame, contentContainer, listLayout
end

-- ============================================
-- CREATE PRODUCT CARD
-- ============================================

local function createProductCard(parent, product, index)
	local card = Instance.new("Frame")
	card.Name = "Product_" .. product.Name
	card.Size = UDim2.new(1, -10, 0, GUI_CONFIG.IsMobile and 180 or 150)
	card.BackgroundColor3 = GUI_CONFIG.HeaderColor
	card.BorderSizePixel = 0
	card.LayoutOrder = index
	card.Parent = parent

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 10)
	corner.Parent = card

	-- Product Info
	local emoji = PRODUCT_EMOJIS[product.Name] or "📦"
	local price = QUICK_SELL_PRICES[product.Name] or 10

	local nameLabel = Instance.new("TextLabel")
	nameLabel.Size = UDim2.new(1, -20, 0, 30)
	nameLabel.Position = UDim2.new(0, 10, 0, 10)
	nameLabel.BackgroundTransparency = 1
	nameLabel.Text = emoji .. " " .. product.Name .. " x" .. product.Count
	nameLabel.TextColor3 = GUI_CONFIG.TextColor
	nameLabel.TextScaled = true
	nameLabel.Font = Enum.Font.GothamBold
	nameLabel.TextXAlignment = Enum.TextXAlignment.Left
	nameLabel.Parent = card

	-- Quick Sell Info
	local sellInfo = Instance.new("TextLabel")
	sellInfo.Size = UDim2.new(1, -20, 0, 20)
	sellInfo.Position = UDim2.new(0, 10, 0, 45)
	sellInfo.BackgroundTransparency = 1
	sellInfo.Text = "Quick Sell: " .. formatCash(price) .. " each"
	sellInfo.TextColor3 = Color3.fromRGB(100, 255, 100)
	sellInfo.TextScaled = true
	sellInfo.Font = Enum.Font.Gotham
	sellInfo.TextXAlignment = Enum.TextXAlignment.Left
	sellInfo.Parent = card

	-- Conversion Info
	local conversionInfo = Instance.new("TextLabel")
	conversionInfo.Size = UDim2.new(1, -20, 0, 20)
	conversionInfo.Position = UDim2.new(0, 10, 0, 70)
	conversionInfo.BackgroundTransparency = 1
	conversionInfo.Text = "🌱 " .. (CONVERSIONS[product.Name] or "No conversion")
	conversionInfo.TextColor3 = Color3.fromRGB(200, 200, 200)
	conversionInfo.TextScaled = true
	conversionInfo.Font = Enum.Font.Gotham
	conversionInfo.TextXAlignment = Enum.TextXAlignment.Left
	conversionInfo.Parent = card

	-- Button Container
	local buttonContainer = Instance.new("Frame")
	buttonContainer.Size = UDim2.new(1, -20, 0, 50)
	buttonContainer.Position = UDim2.new(0, 10, 1, -60)
	buttonContainer.BackgroundTransparency = 1
	buttonContainer.Parent = card

	-- 1. SELL BUTTON
	local sellButton = Instance.new("TextButton")
	sellButton.Size = UDim2.new(0.3, -5, 1, 0)
	sellButton.Position = UDim2.new(0, 0, 0, 0)
	sellButton.BackgroundColor3 = GUI_CONFIG.SellButtonColor
	sellButton.Text = "💰 Sell All\n" .. formatCash(price * product.Count)
	sellButton.TextColor3 = GUI_CONFIG.TextColor
	sellButton.TextScaled = true
	sellButton.Font = Enum.Font.GothamBold
	sellButton.Parent = buttonContainer

	local sellCorner = Instance.new("UICorner")
	sellCorner.CornerRadius = UDim.new(0, 6)
	sellCorner.Parent = sellButton

	sellButton.MouseButton1Click:Connect(function()
		sellButton.Text = "Selling..."
		SellProductEvent:FireServer(product.Name, product.Count)
	end)

	-- 2. CONVERT BUTTON
	local convertButton = Instance.new("TextButton")
	convertButton.Size = UDim2.new(0.3, -5, 1, 0)
	convertButton.Position = UDim2.new(0.35, 0, 0, 0)
	convertButton.BackgroundColor3 = GUI_CONFIG.ConvertButtonColor
	convertButton.Text = "🌱 Convert"
	convertButton.TextColor3 = GUI_CONFIG.TextColor
	convertButton.TextScaled = true
	convertButton.Font = Enum.Font.GothamBold
	convertButton.Parent = buttonContainer

	local convertCorner = Instance.new("UICorner")
	convertCorner.CornerRadius = UDim.new(0, 6)
	convertCorner.Parent = convertButton

	convertButton.MouseButton1Click:Connect(function()
		convertButton.Text = "Converting..."
		ConvertProductEvent:FireServer(product.Name)
	end)

	-- 3. LIST ON MARKETPLACE BUTTON
	local listButton = Instance.new("TextButton")
	listButton.Size = UDim2.new(0.3, -5, 1, 0)
	listButton.Position = UDim2.new(0.7, 0, 0, 0)
	listButton.BackgroundColor3 = GUI_CONFIG.ListButtonColor
	listButton.Text = "🏪 List on\nMarket"
	listButton.TextColor3 = GUI_CONFIG.TextColor
	listButton.TextScaled = true
	listButton.Font = Enum.Font.GothamBold
	listButton.Parent = buttonContainer

	local listCorner = Instance.new("UICorner")
	listCorner.CornerRadius = UDim.new(0, 6)
	listCorner.Parent = listButton

	-- List button (for Products like Eggs, Milk)
	listButton.MouseButton1Click:Connect(function()
		-- Check VIP status first
		local ReplicatedStorage = game:GetService("ReplicatedStorage")
		local CheckVIPFunction = ReplicatedStorage:WaitForChild("CheckVIPFunction", 5)

		if not CheckVIPFunction then
			warn("❌ CheckVIPFunction not found")
			return
		end

		local hasVIP = CheckVIPFunction:InvokeServer()

		if hasVIP then
			-- VIP USER: Show quick-list UI
			openVIPListingUI(productName) -- You'll create this function below
		else
			-- NON-VIP: Show prompt to buy GamePass or go to Town
			local ShowTutorialEvent = ReplicatedStorage:FindFirstChild("ShowTutorialEvent")
			if ShowTutorialEvent then
				ShowTutorialEvent:FireServer("NeedMarketplaceVIP", {
					Title = "Marketplace VIP Required 🛍️",
					Message = "Get VIP GamePass to list from anywhere, or walk to the Town Portal to list for free!",
					Duration = 6
				})
			end

			-- Option: Show GamePass purchase prompt
			local PromptGamePassEvent = ReplicatedStorage:FindFirstChild("PromptGamePassEvent")
			if PromptGamePassEvent then
				-- Wait 2 seconds, then show purchase prompt
				task.wait(2)
				PromptGamePassEvent:FireServer("MarketplaceVIP")
			end
		end
	end)

	-- ============================================
	-- VIP LISTING UI FUNCTION
	-- ============================================
	local function openVIPListingUI(productName)
		-- Create simple listing dialog
		local listingFrame = Instance.new("Frame")
		listingFrame.Name = "VIPListingFrame"
		listingFrame.Size = UDim2.new(0.5, 0, 0.4, 0)
		listingFrame.Position = UDim2.new(0.25, 0, 0.3, 0)
		listingFrame.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
		listingFrame.BorderSizePixel = 0
		listingFrame.ZIndex = 20
		listingFrame.Parent = screenGui

		local corner = Instance.new("UICorner")
		corner.CornerRadius = UDim.new(0, 12)
		corner.Parent = listingFrame

		-- Title
		local title = Instance.new("TextLabel")
		title.Size = UDim2.new(1, 0, 0, 40)
		title.BackgroundTransparency = 1
		title.Text = "🛍️ VIP Quick List - " .. productName
		title.TextColor3 = Color3.new(1, 1, 1)
		title.TextSize = 20
		title.Font = Enum.Font.GothamBold
		title.ZIndex = 21
		title.Parent = listingFrame

		-- Quantity input
		local qtyLabel = Instance.new("TextLabel")
		qtyLabel.Size = UDim2.new(0.3, 0, 0, 30)
		qtyLabel.Position = UDim2.new(0.05, 0, 0.25, 0)
		qtyLabel.BackgroundTransparency = 1
		qtyLabel.Text = "Quantity:"
		qtyLabel.TextColor3 = Color3.new(1, 1, 1)
		qtyLabel.TextSize = 16
		qtyLabel.Font = Enum.Font.Gotham
		qtyLabel.TextXAlignment = Enum.TextXAlignment.Left
		qtyLabel.ZIndex = 21
		qtyLabel.Parent = listingFrame

		local qtyInput = Instance.new("TextBox")
		qtyInput.Size = UDim2.new(0.6, 0, 0, 30)
		qtyInput.Position = UDim2.new(0.35, 0, 0.25, 0)
		qtyInput.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
		qtyInput.Text = "1"
		qtyInput.TextColor3 = Color3.new(1, 1, 1)
		qtyInput.TextSize = 18
		qtyInput.Font = Enum.Font.Gotham
		qtyInput.PlaceholderText = "Enter quantity"
		qtyInput.ZIndex = 21
		qtyInput.Parent = listingFrame

		local qtyCorner = Instance.new("UICorner")
		qtyCorner.CornerRadius = UDim.new(0, 6)
		qtyCorner.Parent = qtyInput

		-- Price per unit input
		local priceLabel = Instance.new("TextLabel")
		priceLabel.Size = UDim2.new(0.3, 0, 0, 30)
		priceLabel.Position = UDim2.new(0.05, 0, 0.45, 0)
		priceLabel.BackgroundTransparency = 1
		priceLabel.Text = "Price Each:"
		priceLabel.TextColor3 = Color3.new(1, 1, 1)
		priceLabel.TextSize = 16
		priceLabel.Font = Enum.Font.Gotham
		priceLabel.TextXAlignment = Enum.TextXAlignment.Left
		priceLabel.ZIndex = 21
		priceLabel.Parent = listingFrame

		local priceInput = Instance.new("TextBox")
		priceInput.Size = UDim2.new(0.6, 0, 0, 30)
		priceInput.Position = UDim2.new(0.35, 0, 0.45, 0)
		priceInput.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
		priceInput.Text = "50"
		priceInput.TextColor3 = Color3.new(1, 1, 1)
		priceInput.TextSize = 18
		priceInput.Font = Enum.Font.Gotham
		priceInput.PlaceholderText = "Enter price"
		priceInput.ZIndex = 21
		priceInput.Parent = listingFrame

		local priceCorner = Instance.new("UICorner")
		priceCorner.CornerRadius = UDim.new(0, 6)
		priceCorner.Parent = priceInput

		-- List button
		local listBtn = Instance.new("TextButton")
		listBtn.Size = UDim2.new(0.4, 0, 0, 40)
		listBtn.Position = UDim2.new(0.05, 0, 0.75, 0)
		listBtn.BackgroundColor3 = Color3.fromRGB(70, 150, 70)
		listBtn.Text = "List Item"
		listBtn.TextColor3 = Color3.new(1, 1, 1)
		listBtn.TextSize = 18
		listBtn.Font = Enum.Font.GothamBold
		listBtn.ZIndex = 21
		listBtn.Parent = listingFrame

		local listCorner = Instance.new("UICorner")
		listCorner.CornerRadius = UDim.new(0, 8)
		listCorner.Parent = listBtn

		-- Cancel button
		local cancelBtn = Instance.new("TextButton")
		cancelBtn.Size = UDim2.new(0.4, 0, 0, 40)
		cancelBtn.Position = UDim2.new(0.55, 0, 0.75, 0)
		cancelBtn.BackgroundColor3 = Color3.fromRGB(150, 50, 50)
		cancelBtn.Text = "Cancel"
		cancelBtn.TextColor3 = Color3.new(1, 1, 1)
		cancelBtn.TextSize = 18
		cancelBtn.Font = Enum.Font.GothamBold
		cancelBtn.ZIndex = 21
		cancelBtn.Parent = listingFrame

		local cancelCorner = Instance.new("UICorner")
		cancelCorner.CornerRadius = UDim.new(0, 8)
		cancelCorner.Parent = cancelBtn

		-- List button action
		listBtn.MouseButton1Click:Connect(function()
			local qty = tonumber(qtyInput.Text)
			local price = tonumber(priceInput.Text)

			if not qty or qty <= 0 then
				warn("Invalid quantity")
				return
			end

			if not price or price <= 0 then
				warn("Invalid price")
				return
			end

			-- Send to server
			local VIPListItemEvent = game:GetService("ReplicatedStorage"):WaitForChild("VIPListItemEvent")
			VIPListItemEvent:FireServer(productName, qty, price, "Products")

			listingFrame:Destroy()
		end)

		-- Cancel button action
		cancelBtn.MouseButton1Click:Connect(function()
			listingFrame:Destroy()
		end)
	end
end

-- ============================================
-- OPEN PRODUCT HUB
-- ============================================ds

function _G.OpenProductHub()
	-- Close existing
	local existing = playerGui:FindFirstChild("ProductHubGui")
	if existing then
		existing:Destroy()
	end

	-- Get products
	local products = getPlayerProducts()

	if #products == 0 then
		-- Show notification
		local showTutorialEvent = ReplicatedStorage:WaitForChild("ShowTutorialEvent")
		showTutorialEvent:FireServer("NoProducts", {
			Title = "📭 No Products",
			Message = "Collect products from your animals first!",
			Duration = 3
		})
		return
	end

	-- Create GUI
	local screenGui, mainFrame, contentContainer, listLayout = createMainFrame()

	-- Create product cards
	for i, product in ipairs(products) do
		createProductCard(contentContainer, product, i)
	end

	-- Update canvas size
	contentContainer.CanvasSize = UDim2.new(0, 0, 0, listLayout.AbsoluteContentSize.Y + 20)

	-- Show GUI
	mainFrame.Visible = true

	print("🐔 Product Hub opened with " .. #products .. " products")
end

-- ============================================
-- EVENT LISTENERS
-- ============================================

-- Sell Product Response
SellProductEvent.OnClientEvent:Connect(function(status, earnings, message)
	if status == "success" then
		-- Refresh GUI
		_G.OpenProductHub()

		-- Show notification
		local showTutorialEvent = ReplicatedStorage:WaitForChild("ShowTutorialEvent")
		showTutorialEvent:FireServer("SellSuccess", {
			Title = "💰 Sold!",
			Message = "You earned " .. formatCash(earnings) .. "!",
			Duration = 3
		})
	else
		warn("❌ Sell failed: " .. message)
	end
end)

-- Convert Product Response
ConvertProductEvent.OnClientEvent:Connect(function(status, seedsGained)
	if status == "success" then
		-- Refresh GUI
		_G.OpenProductHub()

		-- Show notification
		local showTutorialEvent = ReplicatedStorage:WaitForChild("ShowTutorialEvent")
		showTutorialEvent:FireServer("ConvertSuccess", {
			Title = "🌱 Converted!",
			Message = "You received: " .. seedsGained .. " seeds!",
			Duration = 3
		})
	else
		warn("❌ Convert failed: " .. seedsGained)
	end
end)

-- ============================================
-- REMOTE EVENT LISTENER
-- ============================================

local OpenProductHubEvent = ReplicatedStorage:FindFirstChild("OpenProductHubEvent")
if not OpenProductHubEvent then
	OpenProductHubEvent = Instance.new("RemoteEvent")
	OpenProductHubEvent.Name = "OpenProductHubEvent"
	OpenProductHubEvent.Parent = ReplicatedStorage
	print("🔵 Created OpenProductHubEvent in ProductHubClient")
end

OpenProductHubEvent.OnClientEvent:Connect(function()
	print("🔵 Received OpenProductHubEvent!")
	_G.OpenProductHub()
end)

-- ============================================
-- PROXIMITY PROMPT PoultryBarn
-- ============================================

task.spawn(function()
	task.wait(3)

	local animalZone = workspace:FindFirstChild("AnimalZone")
	if not animalZone then
		warn("❌ AnimalZone not found!")
		return
	end

	local poultryBarn = animalZone:FindFirstChild("PoultryBarn")
	if not poultryBarn then
		warn("❌ PoultryBarn not found!")
		return
	end

	-- Search inside Union for ProximityPrompt
	local union = poultryBarn:FindFirstChild("Union")
	local prompt = union and union:FindFirstChild("ProximityPrompt")

	if not prompt then
		warn("❌ ProximityPrompt not found in PoultryBarn Union!")
		return
	end

	-- Override prompt to open Product Hub
	prompt.ActionText = "Manage Products"

	prompt.Triggered:Connect(function(playerWhoTriggered)
		if playerWhoTriggered == player then
			_G.OpenProductHub()
		end
	end)

	print("✅ PoultryBarn ProximityPrompt connected to Product Hub!")
end)

print("✅ ProductHubClient ready!")
