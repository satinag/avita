-- StarterPlayerScripts.HiveBarnClient
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")
local cameFromHiveBarn = false

print("HiveBarnClient LOADING...")

-- Wait for RemoteEvents
local GetHiveDataFunction = ReplicatedStorage:WaitForChild("GetHiveData")
local HiveActionEvent = ReplicatedStorage:WaitForChild("HiveActionEvent")
local OpenHiveBarnEvent = ReplicatedStorage:WaitForChild("OpenHiveBarnEvent")

print("HiveBarnClient loaded!")

-- GUI Config
local GUICONFIG = {
	IsMobile = UserInputService.TouchEnabled and not UserInputService.KeyboardEnabled,
	BackgroundColor = Color3.fromRGB(40, 40, 40),
	HeaderColor = Color3.fromRGB(60, 60, 60),
	SellButtonColor = Color3.fromRGB(100, 200, 100),
	ListButtonColor = Color3.fromRGB(255, 150, 50),
	TextColor = Color3.fromRGB(255, 255, 255),
	FrameWidth = UserInputService.TouchEnabled and 0.95 or 0.6,
	FrameHeight = UserInputService.TouchEnabled and 0.85 or 0.7
}

-- Create Product Hub GUI (same as PoultryBarn)
local function createProductHubGUI()
	local ownedProducts = GetHiveDataFunction:InvokeServer()

	if #ownedProducts == 0 then
		warn("No hive products in inventory!")
		if cameFromHiveBarn then
			cameFromHiveBarn = false
			task.wait(0.2)
			_G.openHiveBarn(player)
		end
		return
	end

	local existing = playerGui:FindFirstChild("HiveProductHubGui")
	if existing then existing:Destroy() end

	local gui = Instance.new("ScreenGui")
	gui.Name = "HiveProductHubGui"
	gui.ResetOnSpawn = false
	
	-- ============================================
	-- NON-VIP DIALOG FUNCTION (NEW)
	-- ============================================
	local function showNonVIPDialog(itemName)
		local ReplicatedStorage = game:GetService("ReplicatedStorage")
		local MarketplaceService = game:GetService("MarketplaceService")
		local GamePassConfig = require(ReplicatedStorage:WaitForChild("GamePassConfig"))

		-- Store product name for purchase callback
		local productNameForListing = itemName

		-- Create overlay
		local overlay = Instance.new("Frame")
		overlay.Name = "NonVIPOverlay"
		overlay.Size = UDim2.new(1, 0, 1, 0)
		overlay.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
		overlay.BackgroundTransparency = 0.5
		overlay.BorderSizePixel = 0
		overlay.ZIndex = 100
		overlay.Parent = playerGui

		-- Dialog box
		local dialog = Instance.new("Frame")
		dialog.Size = UDim2.new(GUI_CONFIG.IsMobile and 0.9 or 0.5, 0, GUI_CONFIG.IsMobile and 0.45 or 0.35, 0)
		dialog.Position = UDim2.new(0.5, 0, 0.5, 0)
		dialog.AnchorPoint = Vector2.new(0.5, 0.5)
		dialog.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
		dialog.BorderSizePixel = 0
		dialog.ZIndex = 101
		dialog.Parent = overlay

		local dialogCorner = Instance.new("UICorner")
		dialogCorner.CornerRadius = UDim.new(0, 12)
		dialogCorner.Parent = dialog

		-- Title
		local title = Instance.new("TextLabel")
		title.Size = UDim2.new(1, -20, 0, GUI_CONFIG.IsMobile and 40 or 35)
		title.Position = UDim2.new(0, 10, 0, 10)
		title.BackgroundTransparency = 1
		title.Text = "🔒 Marketplace VIP Required"
		title.TextColor3 = Color3.fromRGB(255, 200, 50)
		title.TextScaled = true
		title.Font = Enum.Font.GothamBold
		title.ZIndex = 102
		title.Parent = dialog

		-- Message
		local message = Instance.new("TextLabel")
		message.Size = UDim2.new(1, -30, 0.35, 0)
		message.Position = UDim2.new(0, 15, 0, GUI_CONFIG.IsMobile and 60 or 55)
		message.BackgroundTransparency = 1
		message.Text = "• List items directly from your Farm (VIP only)\n• OR visit Town buildings to list for free"
		message.TextColor3 = Color3.fromRGB(220, 220, 220)
		message.TextSize = GUI_CONFIG.IsMobile and 14 or 16
		message.Font = Enum.Font.Gotham
		message.TextWrapped = true
		message.TextXAlignment = Enum.TextXAlignment.Left
		message.TextYAlignment = Enum.TextYAlignment.Top
		message.ZIndex = 102
		message.Parent = dialog

		-- Buy VIP Button
		local buyButton = Instance.new("TextButton")
		buyButton.Size = UDim2.new(1, -30, 0, GUI_CONFIG.IsMobile and 50 or 45)
		buyButton.Position = UDim2.new(0, 15, 0.6, 0)
		buyButton.BackgroundColor3 = Color3.fromRGB(70, 150, 70)
		buyButton.Text = "💎 Buy VIP GamePass"
		buyButton.TextColor3 = Color3.new(1, 1, 1)
		buyButton.TextSize = GUI_CONFIG.IsMobile and 16 or 18
		buyButton.Font = Enum.Font.GothamBold
		buyButton.ZIndex = 102
		buyButton.Parent = dialog

		local buyCorner = Instance.new("UICorner")
		buyCorner.CornerRadius = UDim.new(0, 8)
		buyCorner.Parent = buyButton

		-- Cancel Button
		local cancelButton = Instance.new("TextButton")
		cancelButton.Size = UDim2.new(1, -30, 0, GUI_CONFIG.IsMobile and 45 or 40)
		cancelButton.Position = UDim2.new(0, 15, 0.8, 0)
		cancelButton.BackgroundColor3 = Color3.fromRGB(150, 50, 50)
		cancelButton.Text = "Cancel"
		cancelButton.TextColor3 = Color3.new(1, 1, 1)
		cancelButton.TextSize = GUI_CONFIG.IsMobile and 14 or 16
		cancelButton.Font = Enum.Font.Gotham
		cancelButton.ZIndex = 102
		cancelButton.Parent = dialog

		local cancelCorner = Instance.new("UICorner")
		cancelCorner.CornerRadius = UDim.new(0, 8)
		cancelCorner.Parent = cancelButton

		-- Buy Button Action
		buyButton.MouseButton1Click:Connect(function()
			local vipPass = GamePassConfig.GetPass("MarketplaceVIP")
			if not vipPass then
				warn("MarketplaceVIP pass not found")
				overlay:Destroy()
				return
			end

			-- Fetch price
			local success, productInfo = pcall(function()
				return MarketplaceService:GetProductInfo(vipPass.ID, Enum.InfoType.GamePass)
			end)

			if success and productInfo then
				buyButton.Text = "💎 " .. productInfo.PriceInRobux .. " Robux"
			end

			-- Prompt purchase
			pcall(function()
				MarketplaceService:PromptGamePassPurchase(player, vipPass.ID)
			end)

			task.wait(1)
			overlay:Destroy()
		end)

		-- Cancel Action
		cancelButton.MouseButton1Click:Connect(function()
			overlay:Destroy()
		end)

		-- Listen for purchase completion
		local connection
		connection = MarketplaceService.PromptGamePassPurchaseFinished:Connect(function(plr, passId, wasPurchased)
			if plr == player and wasPurchased then
				overlay:Destroy()
				-- Auto-open listing UI
				task.wait(0.5)
				openVIPListingUI(productNameForListing)
				connection:Disconnect()
			end
		end)
	end

	-- ============================================
	-- VIP LISTING UI FUNCTION
	-- ============================================
	local function openVIPListingUI(productName, productCount, defaultCategory)
		-- Create dialog
		local listingFrame = Instance.new("Frame")
		listingFrame.Name = "VIPListingFrame"
		listingFrame.Size = UDim2.new(0.5, 0, 0.5, 0)
		listingFrame.Position = UDim2.new(0.25, 0, 0.25, 0)
		listingFrame.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
		listingFrame.BorderSizePixel = 0
		listingFrame.ZIndex = 20
		listingFrame.Parent = gui

		local corner = Instance.new("UICorner")
		corner.CornerRadius = UDim.new(0, 12)
		corner.Parent = listingFrame

		-- Title
		local title = Instance.new("TextLabel")
		title.Size = UDim2.new(1, 0, 0, 40)
		title.BackgroundTransparency = 1
		title.Text = "⭐ VIP Quick List - " .. productName
		title.TextColor3 = Color3.new(1, 1, 1)
		title.TextSize = 20
		title.Font = Enum.Font.GothamBold
		title.ZIndex = 21
		title.Parent = listingFrame

		-- ✨ NEW: Category Dropdown
		local categoryLabel = Instance.new("TextLabel")
		categoryLabel.Size = UDim2.new(0.3, 0, 0, 30)
		categoryLabel.Position = UDim2.new(0.05, 0, 0, 60)
		categoryLabel.BackgroundTransparency = 1
		categoryLabel.Text = "Category:"
		categoryLabel.TextColor3 = Color3.new(1, 1, 1)
		categoryLabel.TextSize = 16
		categoryLabel.Font = Enum.Font.Gotham
		categoryLabel.TextXAlignment = Enum.TextXAlignment.Left
		categoryLabel.ZIndex = 21
		categoryLabel.Parent = listingFrame

		local categoryDropdown = Instance.new("TextButton")
		categoryDropdown.Size = UDim2.new(0.6, 0, 0, 30)
		categoryDropdown.Position = UDim2.new(0.35, 0, 0, 60)
		categoryDropdown.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
		categoryDropdown.Text = defaultCategory or "Crops"
		categoryDropdown.TextColor3 = Color3.new(1, 1, 1)
		categoryDropdown.TextSize = 16
		categoryDropdown.Font = Enum.Font.Gotham
		categoryDropdown.ZIndex = 21
		categoryDropdown.Parent = listingFrame

		local dropCorner = Instance.new("UICorner")
		dropCorner.CornerRadius = UDim.new(0, 6)
		dropCorner.Parent = categoryDropdown

		-- Dropdown menu
		local categories = {"Crops", "Products", "Fish", "Animals"}
		local dropdownOpen = false

		categoryDropdown.MouseButton1Click:Connect(function()
			if dropdownOpen then return end
			dropdownOpen = true

			for i, cat in ipairs(categories) do
				local option = Instance.new("TextButton")
				option.Size = UDim2.new(0.6, 0, 0, 25)
				option.Position = UDim2.new(0.35, 0, 0, 60 + (i * 25))
				option.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
				option.Text = cat
				option.TextColor3 = Color3.new(1, 1, 1)
				option.TextSize = 14
				option.Font = Enum.Font.Gotham
				option.ZIndex = 22
				option.Parent = listingFrame

				option.MouseButton1Click:Connect(function()
					categoryDropdown.Text = cat
					-- Remove options
					for _, child in ipairs(listingFrame:GetChildren()) do
						if child:IsA("TextButton") and child ~= categoryDropdown then
							child:Destroy()
						end
					end
					dropdownOpen = false
				end)
			end
		end)

		-- Quantity input
		local qtyLabel = Instance.new("TextLabel")
		qtyLabel.Size = UDim2.new(0.3, 0, 0, 30)
		qtyLabel.Position = UDim2.new(0.05, 0, 0, 110)
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
		qtyInput.Position = UDim2.new(0.35, 0, 0, 110)
		qtyInput.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
		qtyInput.Text = tostring(productCount or 1)
		qtyInput.TextColor3 = Color3.new(1, 1, 1)
		qtyInput.TextSize = 18
		qtyInput.Font = Enum.Font.Gotham
		qtyInput.PlaceholderText = "Enter quantity"
		qtyInput.ZIndex = 21
		qtyInput.Parent = listingFrame

		local qtyCorner = Instance.new("UICorner")
		qtyCorner.CornerRadius = UDim.new(0, 6)
		qtyCorner.Parent = qtyInput

		-- Price input
		local priceLabel = Instance.new("TextLabel")
		priceLabel.Size = UDim2.new(0.3, 0, 0, 30)
		priceLabel.Position = UDim2.new(0.05, 0, 0, 160)
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
		priceInput.Position = UDim2.new(0.35, 0, 0, 160)
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
		listBtn.Text = "📋 List Item"
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
		cancelBtn.Text = "❌ Cancel"
		cancelBtn.TextColor3 = Color3.new(1, 1, 1)
		cancelBtn.TextSize = 18
		cancelBtn.Font = Enum.Font.GothamBold
		cancelBtn.ZIndex = 21
		cancelBtn.Parent = listingFrame

		local cancelCorner = Instance.new("UICorner")
		cancelCorner.CornerRadius = UDim.new(0, 8)
		cancelCorner.Parent = cancelBtn

		-- Button actions
		listBtn.MouseButton1Click:Connect(function()
			local qty = tonumber(qtyInput.Text)
			local price = tonumber(priceInput.Text)
			local category = categoryDropdown.Text

			if not qty or qty <= 0 then
				warn("Invalid quantity")
				return
			end
			if not price or price <= 0 then
				warn("Invalid price")
				return
			end

			-- Send to server
			local VIPListItemEvent = ReplicatedStorage:WaitForChild("VIPListItemEvent")
			VIPListItemEvent:FireServer(productName, qty, price, category)

			listingFrame:Destroy()
		end)

		cancelBtn.MouseButton1Click:Connect(function()
			listingFrame:Destroy()
		end)
	end

	-- VIP PROMPT DIALOG
	local function showVIPPromptDialog()
		local promptGui = Instance.new("ScreenGui")
		promptGui.Name = "VIPPromptGui"
		promptGui.ResetOnSpawn = false
		promptGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling

		-- Overlay
		local overlay = Instance.new("Frame")
		overlay.Size = UDim2.new(1, 0, 1, 0)
		overlay.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
		overlay.BackgroundTransparency = 0.5
		overlay.BorderSizePixel = 0
		overlay.Parent = promptGui

		-- Dialog
		local dialog = Instance.new("Frame")
		dialog.Size = UDim2.new(GUI_CONFIG.IsMobile and 0.9 or 0.5, 0, GUI_CONFIG.IsMobile and 0.5 or 0.4, 0)
		dialog.Position = UDim2.new(0.5, 0, 0.5, 0)
		dialog.AnchorPoint = Vector2.new(0.5, 0.5)
		dialog.BackgroundColor3 = GUI_CONFIG.BackgroundColor
		dialog.BorderSizePixel = 0
		dialog.Parent = promptGui

		local dialogCorner = Instance.new("UICorner")
		dialogCorner.CornerRadius = UDim.new(0, 12)
		dialogCorner.Parent = dialog

		-- Icon
		local icon = Instance.new("TextLabel")
		icon.Size = UDim2.new(1, 0, 0.3, 0)
		icon.Position = UDim2.new(0, 0, 0.05, 0)
		icon.BackgroundTransparency = 1
		icon.Text = "🌟"
		icon.TextColor3 = Color3.fromRGB(255, 200, 50)
		icon.TextScaled = true
		icon.Font = Enum.Font.GothamBold
		icon.Parent = dialog

		-- Title
		local title = Instance.new("TextLabel")
		title.Size = UDim2.new(1, -40, 0.15, 0)
		title.Position = UDim2.new(0, 20, 0.35, 0)
		title.BackgroundTransparency = 1
		title.Text = "VIP Quick-Sell Required"
		title.TextColor3 = GUI_CONFIG.TextColor
		title.TextScaled = true
		title.Font = Enum.Font.GothamBold
		title.Parent = dialog

		-- Message
		local message = Instance.new("TextLabel")
		message.Size = UDim2.new(1, -40, 0.2, 0)
		message.Position = UDim2.new(0, 20, 0.5, 0)
		message.BackgroundTransparency = 1
		message.Text = "Get VIP to sell at Town prices from your Farm!\n\nOr visit Town shops to sell manually."
		message.TextColor3 = Color3.fromRGB(200, 200, 200)
		message.TextScaled = true
		message.Font = Enum.Font.Gotham
		message.TextWrapped = true
		message.Parent = dialog

		-- Buy VIP Button
		local buyButton = Instance.new("TextButton")
		buyButton.Size = UDim2.new(0.45, 0, 0.15, 0)
		buyButton.Position = UDim2.new(0.05, 0, 0.78, 0)
		buyButton.BackgroundColor3 = Color3.fromRGB(255, 200, 50)
		buyButton.Text = "🌟 Buy VIP"
		buyButton.TextColor3 = Color3.fromRGB(0, 0, 0)
		buyButton.TextScaled = true
		buyButton.Font = Enum.Font.GothamBold
		buyButton.Parent = dialog

		local buyCorner = Instance.new("UICorner")
		buyCorner.CornerRadius = UDim.new(0, 8)
		buyCorner.Parent = buyButton

		buyButton.MouseButton1Click:Connect(function()
			local PromptGamePassEvent = ReplicatedStorage:FindFirstChild("PromptGamePassEvent")
			if PromptGamePassEvent then
				PromptGamePassEvent:FireServer("MarketplaceVIP")
			end
			promptGui:Destroy()
		end)

		-- Go to Town Button
		local townButton = Instance.new("TextButton")
		townButton.Size = UDim2.new(0.45, 0, 0.15, 0)
		townButton.Position = UDim2.new(0.5, 0, 0.78, 0)
		townButton.BackgroundColor3 = Color3.fromRGB(100, 150, 255)
		townButton.Text = "🚪 Go to Town"
		townButton.TextColor3 = GUI_CONFIG.TextColor
		townButton.TextScaled = true
		townButton.Font = Enum.Font.GothamBold
		townButton.Parent = dialog

		local townCorner = Instance.new("UICorner")
		townCorner.CornerRadius = UDim.new(0, 8)
		townCorner.Parent = townButton

		townButton.MouseButton1Click:Connect(function()
			promptGui:Destroy()
			local ShowTutorialEvent = ReplicatedStorage:FindFirstChild("ShowTutorialEvent")
			if ShowTutorialEvent then
				ShowTutorialEvent:FireServer("GoToTown", {
					Title = "Visit Town Shops",
					Message = "Walk to the Town Portal to sell at better prices!",
					Duration = 5
				})
			end
		end)

		promptGui.Parent = playerGui
	end

	local mainFrame = Instance.new("Frame")
	mainFrame.Size = UDim2.new(GUICONFIG.FrameWidth, 0, GUICONFIG.FrameHeight, 0)
	mainFrame.Position = UDim2.new(0.5, 0, 0.5, 0)
	mainFrame.AnchorPoint = Vector2.new(0.5, 0.5)
	mainFrame.BackgroundColor3 = GUICONFIG.BackgroundColor
	mainFrame.BorderSizePixel = 0
	mainFrame.Parent = gui

	local mainCorner = Instance.new("UICorner")
	mainCorner.CornerRadius = UDim.new(0, 12)
	mainCorner.Parent = mainFrame

	-- Header
	local header = Instance.new("Frame")
	header.Size = UDim2.new(1, 0, 0, 60)
	header.BackgroundColor3 = GUICONFIG.HeaderColor
	header.BorderSizePixel = 0
	header.Parent = mainFrame

	local headerCorner = Instance.new("UICorner")
	headerCorner.CornerRadius = UDim.new(0, 12)
	headerCorner.Parent = header

	local title = Instance.new("TextLabel")
	title.Size = UDim2.new(0.8, 0, 1, 0)
	title.Position = UDim2.new(0.05, 0, 0, 0)
	title.BackgroundTransparency = 1
	title.Text = "🐝 Hive Products"
	title.TextColor3 = GUICONFIG.TextColor
	title.TextScaled = true
	title.Font = Enum.Font.GothamBold
	title.TextXAlignment = Enum.TextXAlignment.Left
	title.Parent = header

	-- Close Button
	local closeButton = Instance.new("TextButton")
	closeButton.Size = UDim2.new(0, 50, 0, 50)
	closeButton.Position = UDim2.new(1, -55, 0, 5)
	closeButton.BackgroundColor3 = Color3.fromRGB(200, 80, 80)
	closeButton.Text = "X"
	closeButton.TextColor3 = GUICONFIG.TextColor
	closeButton.TextScaled = true
	closeButton.Font = Enum.Font.GothamBold
	closeButton.Parent = header

	local closeCorner = Instance.new("UICorner")
	closeCorner.CornerRadius = UDim.new(1, 0)
	closeCorner.Parent = closeButton

	closeButton.MouseButton1Click:Connect(function()
		gui:Destroy()
		if cameFromHiveBarn then
			cameFromHiveBarn = false
			task.wait(0.2)
			_G.openHiveBarn(player)
		end
	end)

	-- Scrolling Frame
	local scrollFrame = Instance.new("ScrollingFrame")
	scrollFrame.Size = UDim2.new(1, -20, 1, -80)
	scrollFrame.Position = UDim2.new(0, 10, 0, 70)
	scrollFrame.BackgroundTransparency = 1
	scrollFrame.BorderSizePixel = 0
	scrollFrame.ScrollBarThickness = 8
	scrollFrame.Parent = mainFrame

	local listLayout = Instance.new("UIListLayout")
	listLayout.Padding = UDim.new(0, 10)
	listLayout.SortOrder = Enum.SortOrder.LayoutOrder
	listLayout.Parent = scrollFrame

	-- Create product cards
	for i, product in ipairs(ownedProducts) do
		local productCard = Instance.new("Frame")
		productCard.Size = UDim2.new(1, -10, 0, GUICONFIG.IsMobile and 100 or 90)
		productCard.BackgroundColor3 = Color3.fromRGB(80, 80, 80)
		productCard.BorderSizePixel = 0
		productCard.LayoutOrder = i
		productCard.Parent = scrollFrame

		local cardCorner = Instance.new("UICorner")
		cardCorner.CornerRadius = UDim.new(0, 8)
		cardCorner.Parent = productCard

		local productLabel = Instance.new("TextLabel")
		productLabel.Size = UDim2.new(0.35, 0, 0.4, 0)
		productLabel.Position = UDim2.new(0.02, 0, 0.1, 0)
		productLabel.BackgroundTransparency = 1
		productLabel.Text = product.Icon .. " " .. product.Name .. " x" .. product.Count
		productLabel.TextColor3 = GUICONFIG.TextColor
		productLabel.TextScaled = true
		productLabel.Font = Enum.Font.GothamBold
		productLabel.TextXAlignment = Enum.TextXAlignment.Left
		productLabel.Parent = productCard

		local priceLabel = Instance.new("TextLabel")
		priceLabel.Size = UDim2.new(0.35, 0, 0.3, 0)
		priceLabel.Position = UDim2.new(0.02, 0, 0.55, 0)
		priceLabel.BackgroundTransparency = 1
		priceLabel.Text = "$" .. product.Price .. " each"
		priceLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
		priceLabel.TextScaled = true
		priceLabel.Font = Enum.Font.Gotham
		priceLabel.TextXAlignment = Enum.TextXAlignment.Left
		priceLabel.Parent = productCard

		-- Sell Button
		local sellButton = Instance.new("TextButton")
		sellButton.Size = UDim2.new(0.28, 0, 0.7, 0)
		sellButton.Position = UDim2.new(0.39, 0, 0.15, 0)
		sellButton.BackgroundColor3 = GUICONFIG.SellButtonColor
		sellButton.Text = "Sell $" .. (product.Count * product.Price)
		sellButton.TextColor3 = Color3.fromRGB(0, 0, 0)
		sellButton.TextScaled = true
		sellButton.Font = Enum.Font.GothamBold
		sellButton.Parent = productCard

		local sellCorner = Instance.new("UICorner")
		sellCorner.CornerRadius = UDim.new(0, 6)
		sellCorner.Parent = sellButton

		sellButton.MouseButton1Click:Connect(function()
			print("🐝 Sell button clicked for " .. product.Name)
			sellButton.Text = "Selling..."
			HiveActionEvent:FireServer("Sell", product.Name)

			-- ✅ SMART REFRESH
			task.spawn(function()
				task.wait(1.5)
				local productInventory = player:FindFirstChild("ProductInventory")
				local hasProducts = false

				if productInventory then
					for _, item in pairs(productInventory:GetChildren()) do
						if item:IsA("IntValue") and item.Value > 0 and 
							(item.Name == "Honey" or item.Name == "Wax") then
							hasProducts = true
							break
						end
					end
				end

				local oldGui = playerGui:FindFirstChild("HiveBarnGui")
				if oldGui then oldGui:Destroy() end

				if hasProducts then
					G.OpenProductHub()
				else
					if cameFromHiveBarn then
						cameFromHiveBarn = false
						_G.openHiveBarn(player)
					end
				end
			end)
		end)


		-- List Button
		local listButton = Instance.new("TextButton")
		listButton.Size = UDim2.new(0.28, 0, 0.7, 0)
		listButton.Position = UDim2.new(0.69, 0, 0.15, 0)
		listButton.BackgroundColor3 = GUICONFIG.ListButtonColor
		listButton.Text = "List"
		listButton.TextColor3 = GUICONFIG.TextColor
		listButton.TextScaled = true
		listButton.Font = Enum.Font.GothamBold
		listButton.Parent = productCard

		local listCorner = Instance.new("UICorner")
		listCorner.CornerRadius = UDim.new(0, 6)
		listCorner.Parent = listButton

		-- List button action (VIP Quick-Sell - DELAYED PAYMENT)
		listButton.MouseButton1Click:Connect(function()
			print("🌟 Quick-Sell button clicked for " .. product.Name)

			-- Check VIP status
			local CheckVIPStatusEvent = ReplicatedStorage:FindFirstChild("CheckVIPStatusEvent")
			if not CheckVIPStatusEvent then
				warn("❌ CheckVIPStatusEvent not found")
				return
			end

			local hasVIP = CheckVIPStatusEvent:InvokeServer()

			if not hasVIP then
				showVIPPromptDialog()
				return
			end

			-- VIP user: Create listing
			listButton.Text = "Listing..."
			listButton.BackgroundColor3 = Color3.fromRGB(150, 150, 150)

			local itemsToSell = {}
			itemsToSell[product.Name] = product.Count

			local VIPQuickSellEvent = ReplicatedStorage:WaitForChild("VIPQuickSellEvent")
			VIPQuickSellEvent:FireServer(itemsToSell)

			-- ✅ SINGLE SMART REFRESH + AUTO-CLOSE FOR HIVE BARN
			task.spawn(function()
				task.wait(2.5)  -- Server process + listing time

				-- Check current ProductInventory (Honey/Wax)
				local productInventory = player:FindFirstChild("ProductInventory")
				local hasProducts = false

				if productInventory then
					for _, item in pairs(productInventory:GetChildren()) do
						if item:IsA("IntValue") and item.Value > 0 and (item.Name == "Honey" or item.Name == "Wax") then
							hasProducts = true
							break
						end
					end
				end

				-- Close old GUI
				local oldGui = playerGui:FindFirstChild("HiveBarnGui")  -- ✅ HiveBarn GUI name
				if oldGui then oldGui:Destroy() end

				-- If products left → Refresh GUI
				if hasProducts then
					G.OpenProductHub()  -- ✅ HiveBarn uses global refresh
					print("🐝 HiveBarn REFRESHED - products remaining")
				else
					print("🐝 HiveBarn CLOSED - no products left")
				end
			end)
		end)

	end

	scrollFrame.CanvasSize = UDim2.new(0, 0, 0, listLayout.AbsoluteContentSize.Y + 10)
	gui.Parent = playerGui
end

-- Event listener
OpenHiveBarnEvent.OnClientEvent:Connect(function()
	print("HiveBarnClient: Received OpenHiveBarnEvent!")
	cameFromHiveBarn = true
	createProductHubGUI()
end)

HiveActionEvent.OnClientEvent:Connect(function(action, success, message)
	print("Hive action result:", action, success, message)
	if success then
		local gui = playerGui:FindFirstChild("HiveProductHubGui")
		if gui then
			gui:Destroy()
		end
	end
end)

-- Global function to reopen Hive Barn
_G.openHiveBarn = function(plr)
	local HiveBarnEvent = ReplicatedStorage:FindFirstChild("OpenHiveBarnServer")
	if not HiveBarnEvent then
		HiveBarnEvent = Instance.new("RemoteEvent")
		HiveBarnEvent.Name = "OpenHiveBarnServer"
		HiveBarnEvent.Parent = ReplicatedStorage
	end
	HiveBarnEvent:FireServer()
end

print("HiveBarnClient ready!")
