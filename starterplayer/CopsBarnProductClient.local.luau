local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

print("🌾 BarnClient LOADING...")

-- Wait for remote events/functions
local GetCropDataFunction = ReplicatedStorage:WaitForChild("GetCropData")
local BarnActionEvent = ReplicatedStorage:WaitForChild("BarnActionEvent")
local OpenBarnEvent = ReplicatedStorage:WaitForChild("OpenBarnEvent")

print("🌾 BarnClient loaded! All RemoteEvents found")


-- ============================================
-- GUI CONFIG (RESPONSIVE)
-- ============================================

local GUI_CONFIG = {
	IsMobile = UserInputService.TouchEnabled and not UserInputService.KeyboardEnabled,
	BackgroundColor = Color3.fromRGB(40, 40, 40),
	HeaderColor = Color3.fromRGB(60, 60, 60),
	SellButtonColor = Color3.fromRGB(100, 200, 100),
	ConvertButtonColor = Color3.fromRGB(100, 150, 200),
	ListButtonColor = Color3.fromRGB(255, 150, 50),
	TextColor = Color3.fromRGB(255, 255, 255),

	-- Responsive sizing
	FrameWidth = UserInputService.TouchEnabled and 0.95 or 0.6,
	FrameHeight = UserInputService.TouchEnabled and 0.85 or 0.7,
}

-- ============================================
-- CREATE BARN GUI
-- ============================================

local function createBarnGUI()
	-- Request crop data from server
	local ownedCrops = GetCropDataFunction:InvokeServer()

	if #ownedCrops == 0 then
		warn("No crops in inventory!")
		return
	end

	-- Close existing barn GUI
	local existing = playerGui:FindFirstChild("BarnGui")
	if existing then existing:Destroy() end

	local gui = Instance.new("ScreenGui")
	gui.Name = "BarnGui"
	gui.ResetOnSpawn = false

	-- Main Frame (Responsive)
	local mainFrame = Instance.new("Frame")
	mainFrame.Name = "MainFrame"
	mainFrame.Size = UDim2.new(GUI_CONFIG.FrameWidth, 0, GUI_CONFIG.FrameHeight, 0)
	mainFrame.Position = UDim2.new(0.5, 0, 0.5, 0)
	mainFrame.AnchorPoint = Vector2.new(0.5, 0.5)
	mainFrame.BackgroundColor3 = GUI_CONFIG.BackgroundColor
	mainFrame.BorderSizePixel = 0
	mainFrame.Parent = gui

	local mainCorner = Instance.new("UICorner")
	mainCorner.CornerRadius = UDim.new(0, 12)
	mainCorner.Parent = mainFrame

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
	title.Size = UDim2.new(0.8, 0, 1, 0)
	title.Position = UDim2.new(0.05, 0, 0, 0)
	title.BackgroundTransparency = 1
	title.Text = "🏠 Barn - Manage Crops"
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
		gui:Destroy()
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

	-- Create crop cards
	for i, crop in ipairs(ownedCrops) do
		local cropCard = Instance.new("Frame")
		cropCard.Size = UDim2.new(1, -10, 0, GUI_CONFIG.IsMobile and 100 or 90)
		cropCard.BackgroundColor3 = Color3.fromRGB(80, 80, 80)
		cropCard.BorderSizePixel = 0
		cropCard.LayoutOrder = i
		cropCard.Parent = scrollFrame

		local cardCorner = Instance.new("UICorner")
		cardCorner.CornerRadius = UDim.new(0, 8)
		cardCorner.Parent = cropCard

		-- Crop Info
		local cropLabel = Instance.new("TextLabel")
		cropLabel.Size = UDim2.new(0.35, 0, 0.4, 0)
		cropLabel.Position = UDim2.new(0.02, 0, 0.1, 0)
		cropLabel.BackgroundTransparency = 1
		cropLabel.Text = crop.Emoji .. " " .. crop.Name .. " x" .. crop.Count
		cropLabel.TextColor3 = GUI_CONFIG.TextColor
		cropLabel.TextScaled = true
		cropLabel.Font = Enum.Font.GothamBold
		cropLabel.TextXAlignment = Enum.TextXAlignment.Left
		cropLabel.Parent = cropCard

		-- Price Label
		local priceLabel = Instance.new("TextLabel")
		priceLabel.Size = UDim2.new(0.35, 0, 0.3, 0)
		priceLabel.Position = UDim2.new(0.02, 0, 0.55, 0)
		priceLabel.BackgroundTransparency = 1
		priceLabel.Text = "💰 $" .. crop.Price .. " each"
		priceLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
		priceLabel.TextScaled = true
		priceLabel.Font = Enum.Font.Gotham
		priceLabel.TextXAlignment = Enum.TextXAlignment.Left
		priceLabel.Parent = cropCard

		-- === HORIZONTAL BUTTONS ===

		-- Sell Button
		local sellButton = Instance.new("TextButton")
		sellButton.Size = UDim2.new(0.19, 0, 0.7, 0)
		sellButton.Position = UDim2.new(0.39, 0, 0.15, 0)
		sellButton.BackgroundColor3 = GUI_CONFIG.SellButtonColor
		sellButton.Text = "💰 Sell\n$" .. (crop.Count * crop.Price)
		sellButton.TextColor3 = Color3.fromRGB(0, 0, 0)
		sellButton.TextScaled = true
		sellButton.Font = Enum.Font.GothamBold
		sellButton.Parent = cropCard

		local sellCorner = Instance.new("UICorner")
		sellCorner.CornerRadius = UDim.new(0, 6)
		sellCorner.Parent = sellButton

		-- Convert Button
		local convertButton = Instance.new("TextButton")
		convertButton.Size = UDim2.new(0.19, 0, 0.7, 0)
		convertButton.Position = UDim2.new(0.59, 0, 0.15, 0)
		convertButton.BackgroundColor3 = GUI_CONFIG.ConvertButtonColor
		convertButton.Text = "🌱 Convert\n" .. (crop.Count * 5) .. " seeds"
		convertButton.TextColor3 = GUI_CONFIG.TextColor
		convertButton.TextScaled = true
		convertButton.Font = Enum.Font.GothamBold
		convertButton.Parent = cropCard

		local convertCorner = Instance.new("UICorner")
		convertCorner.CornerRadius = UDim.new(0, 6)
		convertCorner.Parent = convertButton

		-- List on Marketplace Button
		local listButton = Instance.new("TextButton")
		listButton.Size = UDim2.new(0.19, 0, 0.7, 0)
		listButton.Position = UDim2.new(0.79, 0, 0.15, 0)
		listButton.BackgroundColor3 = GUI_CONFIG.ListButtonColor
		listButton.Text = "🏪 List"
		listButton.TextColor3 = GUI_CONFIG.TextColor
		listButton.TextScaled = true
		listButton.Font = Enum.Font.GothamBold
		listButton.Parent = cropCard

		local listCorner = Instance.new("UICorner")
		listCorner.CornerRadius = UDim.new(0, 6)
		listCorner.Parent = listButton

		-- === BUTTON ACTIONS ===

		sellButton.MouseButton1Click:Connect(function()
			print("🔵 Sell button clicked for " .. crop.Name)
			sellButton.Text = "Selling..."
			BarnActionEvent:FireServer("Sell", crop.Name)

			-- Auto-close GUI after 2 seconds (assume success)
			task.delay(2, function()
				if gui.Parent then
					gui:Destroy()
				end
			end)
		end)

		convertButton.MouseButton1Click:Connect(function()
			print("🔵 Convert button clicked for " .. crop.Name)
			convertButton.Text = "Converting..."
			BarnActionEvent:FireServer("Convert", crop.Name)

			-- Auto-close GUI after 2 seconds (assume success)
			task.delay(2, function()
				if gui.Parent then
					gui:Destroy()
				end
			end)
		end)

		listButton.MouseButton1Click:Connect(function()
			print("🔵 List button clicked for " .. crop.Name)
			gui:Destroy()

			-- Wait for marketplace to be ready (max 5 seconds)
			local maxWait = 50
			local waited = 0
			while not _G.OpenMarketplace and waited < maxWait do
				task.wait(0.1)
				waited = waited + 1
			end

			if _G.OpenMarketplace then
				print("✅ Opening marketplace")
				_G.OpenMarketplace()
			else
				warn("❌ Marketplace failed to load after 5 seconds")
			end
		end) 
	end  


	-- Update canvas size
	scrollFrame.CanvasSize = UDim2.new(0, 0, 0, listLayout.AbsoluteContentSize.Y + 10)

	gui.Parent = playerGui

	-- Auto-close after 30 seconds
	task.delay(30, function()
		if gui.Parent then gui:Destroy() end
	end)
end

-- ============================================
-- EVENT LISTENERS
-- ============================================

-- Listen for barn open request
OpenBarnEvent.OnClientEvent:Connect(function()
	print("🌾 BarnClient: Received OpenBarnEvent!")
	createBarnGUI()
end)

-- Listen for action results
BarnActionEvent.OnClientEvent:Connect(function(action, success, message)
	print("📊 Barn action result:", action, success, message)

	if success then
		-- Close GUI and show success
		local gui = playerGui:FindFirstChild("BarnGui")
		if gui then gui:Destroy() end
	end
end)

-- Listen for marketplace open request (connect to existing marketplace client)
local MarketplaceOpenEvent = ReplicatedStorage:FindFirstChild("OpenMarketplaceEvent")
if not MarketplaceOpenEvent then
	MarketplaceOpenEvent = Instance.new("RemoteEvent")
	MarketplaceOpenEvent.Name = "OpenMarketplaceEvent"
	MarketplaceOpenEvent.Parent = ReplicatedStorage

	MarketplaceOpenEvent.OnClientEvent:Connect(function()
		if _G.OpenMarketplace then
			_G.OpenMarketplace()
		end
	end)
end

print("✅ BarnClient ready!")
