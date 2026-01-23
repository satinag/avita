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
			print("Sell button clicked for " .. product.Name)
			sellButton.Text = "Selling..."
			HiveActionEvent:FireServer("Sell", product.Name)

			task.delay(0.5, function()
				if gui.Parent then
					gui:Destroy()
				end
				if cameFromHiveBarn then
					cameFromHiveBarn = false
					task.wait(0.2)
					_G.openHiveBarn(player)
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
