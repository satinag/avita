-- FishProductClient.lua (StarterPlayerScripts - LocalScript)
-- Handles Fish Product Hub (Sell/List fish inventory)

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")
local cameFromFishingZone = false

print("🎣 FishProductClient LOADING...")

-- Wait for RemoteEvents
local GetFishDataFunction = ReplicatedStorage:WaitForChild("GetFishData")
local FishActionEvent = ReplicatedStorage:WaitForChild("FishActionEvent")
local OpenFishHubEvent = ReplicatedStorage:WaitForChild("OpenFishHubEvent")

print("🎣 FishProductClient loaded!")

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

-- Create Fish Product Hub GUI
local function createFishProductHubGUI()
	local ownedFish = GetFishDataFunction:InvokeServer()

	if #ownedFish == 0 then
		warn("No fish in inventory!")
		if cameFromFishingZone then
			cameFromFishingZone = false
			task.wait(0.2)
			_G.openFishingZone(player)
		end
		return
	end

	local existing = playerGui:FindFirstChild("FishProductHubGui")
	if existing then existing:Destroy() end

	local gui = Instance.new("ScreenGui")
	gui.Name = "FishProductHubGui"
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
	title.Text = "🎣 Fish Inventory"
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
		if cameFromFishingZone then
			cameFromFishingZone = false
			task.wait(0.2)
			_G.openFishingZone(player)
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

	-- Create fish cards
	for i, fish in ipairs(ownedFish) do
		local fishCard = Instance.new("Frame")
		fishCard.Size = UDim2.new(1, -10, 0, GUICONFIG.IsMobile and 100 or 90)
		fishCard.BackgroundColor3 = Color3.fromRGB(80, 80, 80)
		fishCard.BorderSizePixel = 0
		fishCard.LayoutOrder = i
		fishCard.Parent = scrollFrame

		local cardCorner = Instance.new("UICorner")
		cardCorner.CornerRadius = UDim.new(0, 8)
		cardCorner.Parent = fishCard

		local fishLabel = Instance.new("TextLabel")
		fishLabel.Size = UDim2.new(0.35, 0, 0.4, 0)
		fishLabel.Position = UDim2.new(0.02, 0, 0.1, 0)
		fishLabel.BackgroundTransparency = 1
		fishLabel.Text = fish.Icon .. " " .. fish.Name .. " x" .. fish.Count
		fishLabel.TextColor3 = GUICONFIG.TextColor
		fishLabel.TextScaled = true
		fishLabel.Font = Enum.Font.GothamBold
		fishLabel.TextXAlignment = Enum.TextXAlignment.Left
		fishLabel.Parent = fishCard

		local priceLabel = Instance.new("TextLabel")
		priceLabel.Size = UDim2.new(0.35, 0, 0.3, 0)
		priceLabel.Position = UDim2.new(0.02, 0, 0.55, 0)
		priceLabel.BackgroundTransparency = 1
		priceLabel.Text = "$" .. fish.Price .. " each"
		priceLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
		priceLabel.TextScaled = true
		priceLabel.Font = Enum.Font.Gotham
		priceLabel.TextXAlignment = Enum.TextXAlignment.Left
		priceLabel.Parent = fishCard

		-- Sell Button
		local sellButton = Instance.new("TextButton")
		sellButton.Size = UDim2.new(0.28, 0, 0.7, 0)
		sellButton.Position = UDim2.new(0.39, 0, 0.15, 0)
		sellButton.BackgroundColor3 = GUICONFIG.SellButtonColor
		sellButton.Text = "Sell $" .. (fish.Count * fish.Price)
		sellButton.TextColor3 = Color3.fromRGB(0, 0, 0)
		sellButton.TextScaled = true
		sellButton.Font = Enum.Font.GothamBold
		sellButton.Parent = fishCard

		local sellCorner = Instance.new("UICorner")
		sellCorner.CornerRadius = UDim.new(0, 6)
		sellCorner.Parent = sellButton

		sellButton.MouseButton1Click:Connect(function()
			print("Sell button clicked for " .. fish.Name)
			sellButton.Text = "Selling..."
			FishActionEvent:FireServer("Sell", fish.Name)

			task.delay(0.5, function()
				if gui.Parent then
					gui:Destroy()
				end
				if cameFromFishingZone then
					cameFromFishingZone = false
					task.wait(0.2)
					_G.openFishingZone(player)
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
		listButton.Parent = fishCard

		local listCorner = Instance.new("UICorner")
		listCorner.CornerRadius = UDim.new(0, 6)
		listCorner.Parent = listButton

		listButton.MouseButton1Click:Connect(function()
			print("List button clicked for " .. fish.Name)
			gui:Destroy()

			local maxWait = 50
			local waited = 0
			while not _G.OpenMarketplace and waited < maxWait do
				task.wait(0.1)
				waited = waited + 1
			end

			if _G.OpenMarketplace then
				_G.OpenMarketplace("Sell Items")
			end
		end)
	end

	scrollFrame.CanvasSize = UDim2.new(0, 0, 0, listLayout.AbsoluteContentSize.Y + 10)
	gui.Parent = playerGui
end

-- Event listener
OpenFishHubEvent.OnClientEvent:Connect(function()
	print("FishProductClient: Received OpenFishHubEvent!")
	cameFromFishingZone = true
	createFishProductHubGUI()
end)

FishActionEvent.OnClientEvent:Connect(function(action, success, message)
	print("Fish action result:", action, success, message)
	if success then
		local gui = playerGui:FindFirstChild("FishProductHubGui")
		if gui then
			gui:Destroy()
		end
	end
end)

-- Global function to reopen Fishing Zone
_G.openFishingZone = function(plr)
	local FishingZoneEvent = ReplicatedStorage:FindFirstChild("OpenFishingZoneServer")
	if not FishingZoneEvent then
		FishingZoneEvent = Instance.new("RemoteEvent")
		FishingZoneEvent.Name = "OpenFishingZoneServer"
		FishingZoneEvent.Parent = ReplicatedStorage
	end
	FishingZoneEvent:FireServer()
end

print("🎣 FishProductClient ready!")
