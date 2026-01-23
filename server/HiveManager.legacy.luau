-- ServerScriptService.HiveManager
-- Dedicated Hive Barn GUI (similar to PoultryBarn but for hives only)

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local ProductConfig = require(ReplicatedStorage:WaitForChild("ProductConfig"))

print("🐝 Hive Manager loaded!")

-- Create RemoteEvents
local GetHiveDataFunction = ReplicatedStorage:FindFirstChild("GetHiveData")
if not GetHiveDataFunction then
	GetHiveDataFunction = Instance.new("RemoteFunction")
	GetHiveDataFunction.Name = "GetHiveData"
	GetHiveDataFunction.Parent = ReplicatedStorage
	print("✅ Created GetHiveData RemoteFunction")
end

local HiveActionEvent = ReplicatedStorage:FindFirstChild("HiveActionEvent")
if not HiveActionEvent then
	HiveActionEvent = Instance.new("RemoteEvent")
	HiveActionEvent.Name = "HiveActionEvent"
	HiveActionEvent.Parent = ReplicatedStorage
	print("✅ Created HiveActionEvent")
end

local OpenHiveBarnEvent = ReplicatedStorage:FindFirstChild("OpenHiveBarnEvent")
if not OpenHiveBarnEvent then
	OpenHiveBarnEvent = Instance.new("RemoteEvent")
	OpenHiveBarnEvent.Name = "OpenHiveBarnEvent"
	OpenHiveBarnEvent.Parent = ReplicatedStorage
	print("✅ Created OpenHiveBarnEvent")
end

local OpenHiveBarnServer = ReplicatedStorage:FindFirstChild("OpenHiveBarnServer")
if not OpenHiveBarnServer then
	OpenHiveBarnServer = Instance.new("RemoteEvent")
	OpenHiveBarnServer.Name = "OpenHiveBarnServer"
	OpenHiveBarnServer.Parent = ReplicatedStorage
	print("✅ Created OpenHiveBarnServer RemoteEvent")
end

-- Constants
local HIVE_CONFIG = {
	{Rate = 30, PassivePrice = 4000},
	{Rate = 45, PassivePrice = 6000},
	{Rate = 65, PassivePrice = 8500},
	{Rate = 90, PassivePrice = 12000},
	{Rate = 120, PassivePrice = 18000},
	{Rate = 160, PassivePrice = 25000},
	{Rate = 210, PassivePrice = 35000},
	{Rate = 280, PassivePrice = 50000}
}

-- Helper Functions
local function isMobile()
	return UserInputService.TouchEnabled and not UserInputService.KeyboardEnabled
end

local function getOwnedHivesCount(player)
	local beehiveCount = player:FindFirstChild("BeehiveCount")
	return beehiveCount and beehiveCount.Value or 0
end

local function getHiveFolder()
	return workspace:FindFirstChild("AnimalZone") and workspace.AnimalZone:FindFirstChild("Hives")
end

local function getHiveModel(hiveNum)
	local hiveFolder = getHiveFolder()
	if not hiveFolder then return nil end

	local hive = hiveFolder:FindFirstChild("Hive" .. hiveNum)
	if not hive then return nil end

	local nestedHive = hive:FindFirstChild("Hive")
	if nestedHive and nestedHive:IsA("Model") then
		return nestedHive
	end
	return hive
end

-- Collection Functions
local function collectHoney(player, hiveNum)
	if not _G.CollectHoneyProduct then
		warn("ProductManager not loaded!")
		return false, "System not ready"
	end

	local success, result, icon = _G.CollectHoneyProduct(player, hiveNum)

	if success then
		-- ✅ ADD THIS: Complete tutorial level 12 on first hive collection
		if hiveNum == 1 then
			if _G.CompleteTutorialLevel then
				local currentLevel = player:FindFirstChild("CurrentArrowLevel")
				if currentLevel and currentLevel.Value == 12 then
					print("🎯 Completing tutorial level 12 - First hive collection")
					_G.CompleteTutorialLevel(player, 12)
				end
			end
		end

		local showTutorialEvent = ReplicatedStorage:WaitForChild("ShowTutorialEvent")
		showTutorialEvent:FireClient(player, "HoneyCollected", {
			Title = "Honey Collected!",
			Message = icon .. " You collected " .. result .. " Honey from Hive #" .. hiveNum .. "!",
			Duration = 3
		})
		return true, result
	else
		if type(result) == "number" then
			return false, "Wait " .. math.floor(result / 60) .. "m " .. (result % 60) .. "s"
		else
			return false, result
		end
	end
end


local function collectWax(player, hiveNum)
	if not _G.CollectWaxProduct then
		warn("ProductManager not loaded!")
		return false, "System not ready"
	end

	local success, result, icon = _G.CollectWaxProduct(player, hiveNum)

	if success then
		local showTutorialEvent = ReplicatedStorage:WaitForChild("ShowTutorialEvent")
		showTutorialEvent:FireClient(player, "WaxCollected", {
			Title = "Wax Collected!",
			Message = icon .. " You collected " .. result .. " Wax from Hive #" .. hiveNum .. "!",
			Duration = 3
		})
		return true, result
	else
		if type(result) == "number" then
			return false, "Wait " .. math.floor(result / 60) .. "m " .. (result % 60) .. "s"
		else
			return false, result
		end
	end
end

-- Get owned products (Honey + Wax only)
local function getOwnedHiveProducts(player)
	local productInventory = player:FindFirstChild("ProductInventory")
	if not productInventory then return {} end

	local owned = {}
	for _, productName in ipairs({"Honey", "Wax"}) do
		local productValue = productInventory:FindFirstChild(productName)
		if productValue and productValue.Value > 0 then
			local productData = ProductConfig.GetProductData(productName)
			table.insert(owned, {
				Name = productName,
				Count = productValue.Value,
				Price = productData and productData.SellPrice or 0,
				Icon = productData and productData.Icon or ""
			})
		end
	end

	return owned
end

-- Sell product
local function sellProduct(player, productName)
	local productInventory = player:FindFirstChild("ProductInventory")
	local productValue = productInventory and productInventory:FindFirstChild(productName)

	if not productValue or productValue.Value == 0 then
		return false, 0, "No " .. productName .. " to sell"
	end

	local cash = player.leaderstats:FindFirstChild("Cash")
	if not cash then
		return false, 0, "No cash value found"
	end

	local amountSold = productValue.Value
	local pricePerProduct = ProductConfig.GetProductSellPrice(productName)
	local earnings = amountSold * pricePerProduct

	cash.Value = cash.Value + earnings
	productValue.Value = 0

	print("💰 " .. player.Name .. " sold " .. amountSold .. "x " .. productName .. " for $" .. earnings)

	if _G.TrackStat then
		_G.TrackStat(player, "TotalCashEarned", earnings)
	end

	return true, earnings, "Sold " .. amountSold .. " " .. productName
end

-- GUI Creation with LIVE COUNTDOWN
local function createHiveBarnGUI(player, refreshCallback)
	local existingGui = player.PlayerGui:FindFirstChild("HiveBarnGui")
	if existingGui then existingGui:Destroy() end

	local gui = Instance.new("ScreenGui")
	gui.Name = "HiveBarnGui"
	gui.ResetOnSpawn = false
	gui.IgnoreGuiInset = true

	local camera = workspace.CurrentCamera
	local viewportSize = camera.ViewportSize
	local isNarrowScreen = viewportSize.X < 900
	local mobile = isNarrowScreen

	local frameWidth = isNarrowScreen and 0.98 or 0.55

	-- Calculate dynamic height based on content
	local ownedHives = getOwnedHivesCount(player)
	local rowHeight = mobile and 100 or 85
	local titleHeight = mobile and 60 or 50
	local padding = 80  -- Top + bottom padding
	local headerSpace = 40

	local contentHeight
	if ownedHives > 0 then
		contentHeight = titleHeight + headerSpace + (rowHeight * 2) + 30 + padding  -- 2 rows + spacing
	else
		contentHeight = titleHeight + 100 + padding  -- Empty state
	end

	local screenHeight = viewportSize.Y
	local maxHeight = screenHeight * 0.9
	local frameHeight = math.min(contentHeight, maxHeight) / screenHeight

	local frame = Instance.new("Frame")
	frame.Size = UDim2.new(frameWidth, 0, frameHeight, 0)
	frame.Position = UDim2.new(0.5, 0, 0.5, 0)
	frame.AnchorPoint = Vector2.new(0.5, 0.5)
	frame.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
	frame.BorderSizePixel = 0
	frame.Parent = gui

	local frameCorner = Instance.new("UICorner")
	frameCorner.CornerRadius = UDim.new(0, 12)
	frameCorner.Parent = frame

	-- Title
	local title = Instance.new("TextLabel")
	title.Size = UDim2.new(1, 0, 0, titleHeight)
	title.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
	title.Text = "🐝 Hive Barn"
	title.TextColor3 = Color3.fromRGB(255, 255, 255)
	title.TextScaled = true
	title.Font = Enum.Font.GothamBold
	title.Parent = frame

	local titleCorner = Instance.new("UICorner")
	titleCorner.CornerRadius = UDim.new(0, 12)
	titleCorner.Parent = title

	local titlePadding = Instance.new("UIPadding")
	titlePadding.PaddingLeft = UDim.new(0, 10)
	titlePadding.PaddingRight = UDim.new(0, 10)
	titlePadding.Parent = title

	-- Close button
	local closeButton = Instance.new("TextButton")
	closeButton.Size = UDim2.new(0, 35, 0, 35)
	closeButton.Position = UDim2.new(1, -40, 0, 5)
	closeButton.BackgroundColor3 = Color3.fromRGB(200, 100, 100)
	closeButton.Text = "X"
	closeButton.TextColor3 = Color3.fromRGB(255, 255, 255)
	closeButton.TextScaled = true
	closeButton.Font = Enum.Font.GothamBold
	closeButton.Parent = frame

	local closeCorner = Instance.new("UICorner")
	closeCorner.CornerRadius = UDim.new(1, 0)
	closeCorner.Parent = closeButton

	closeButton.MouseButton1Click:Connect(function()
		gui:Destroy()
	end)

	-- Scrolling frame
	local scrollFrame = Instance.new("ScrollingFrame")
	scrollFrame.Size = UDim2.new(1, -20, 1, -(titleHeight + 20))
	scrollFrame.Position = UDim2.new(0, 10, 0, titleHeight + 10)
	scrollFrame.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
	scrollFrame.BorderSizePixel = 0
	scrollFrame.ScrollBarThickness = mobile and 12 or 8
	scrollFrame.ScrollBarImageTransparency = ownedHives > 0 and 0 or 1  -- Hide scrollbar if no content
	scrollFrame.Parent = frame

	local scrollCorner = Instance.new("UICorner")
	scrollCorner.CornerRadius = UDim.new(0, 8)
	scrollCorner.Parent = scrollFrame

	local yPos = 10

	-- ============================================
	-- DYNAMIC BUTTON MANAGEMENT FUNCTION
	-- ============================================
	local function createSellButton(parentFrame, productName, productValue, buttonWidth, buttonHeight, buttonY, buttonSpacing)
		local existingBtn = parentFrame:FindFirstChild("Sell" .. productName .. "Btn")

		if productValue.Value > 0 then
			if existingBtn then
				-- Update existing button text
				existingBtn.Text = "Sell/List (" .. productValue.Value .. ")"
			else
				-- Create new button
				local sellBtn = Instance.new("TextButton")
				sellBtn.Name = "Sell" .. productName .. "Btn"
				sellBtn.Size = UDim2.new(buttonWidth, 0, 0, buttonHeight)
				sellBtn.Position = UDim2.new(0.38 + (buttonWidth + buttonSpacing) * 2, 0, 0, buttonY)
				sellBtn.BackgroundColor3 = Color3.fromRGB(255, 150, 50)
				sellBtn.Text = "Sell/List (" .. productValue.Value .. ")"
				sellBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
				sellBtn.TextScaled = true
				sellBtn.Font = Enum.Font.GothamBold
				sellBtn.Parent = parentFrame

				local sellCorner = Instance.new("UICorner")
				sellCorner.CornerRadius = UDim.new(0, 6)
				sellCorner.Parent = sellBtn

				sellBtn.MouseButton1Click:Connect(function()
					gui:Destroy()
					OpenHiveBarnEvent:FireClient(player)
				end)
			end
		else
			-- Remove button if inventory is empty
			if existingBtn then
				existingBtn:Destroy()
			end
		end
	end

	if ownedHives > 0 then
		-- Section header
		local hiveHeader = Instance.new("TextLabel")
		hiveHeader.Size = UDim2.new(0.9, 0, 0, 30)
		hiveHeader.Position = UDim2.new(0.05, 0, 0, yPos)
		hiveHeader.BackgroundTransparency = 1
		hiveHeader.Text = "🐝 Beehives (" .. ownedHives .. " owned)"
		hiveHeader.TextColor3 = Color3.fromRGB(255, 220, 100)
		hiveHeader.TextScaled = true
		hiveHeader.Font = Enum.Font.GothamBold
		hiveHeader.TextXAlignment = Enum.TextXAlignment.Left
		hiveHeader.Parent = scrollFrame
		yPos = yPos + 40

		-- ============================================
		-- ROW 1: HONEY
		-- ============================================
		local honeyFrame = Instance.new("Frame")
		honeyFrame.Size = UDim2.new(0.95, 0, 0, rowHeight)
		honeyFrame.Position = UDim2.new(0.025, 0, 0, yPos)
		honeyFrame.BackgroundColor3 = Color3.fromRGB(255, 200, 50)
		honeyFrame.BorderSizePixel = 0
		honeyFrame.Parent = scrollFrame

		local honeyCorner = Instance.new("UICorner")
		honeyCorner.CornerRadius = UDim.new(0, 8)
		honeyCorner.Parent = honeyFrame

		-- Info frame
		local honeyInfoFrame = Instance.new("Frame")
		honeyInfoFrame.Size = UDim2.new(0.35, 0, 1, 0)
		honeyInfoFrame.Position = UDim2.new(0.02, 0, 0, 0)
		honeyInfoFrame.BackgroundTransparency = 1
		honeyInfoFrame.Parent = honeyFrame

		local honeyNameLabel = Instance.new("TextLabel")
		honeyNameLabel.Size = UDim2.new(1, 0, 0.4, 0)
		honeyNameLabel.BackgroundTransparency = 1
		honeyNameLabel.Text = "🍯 Honey"
		honeyNameLabel.TextColor3 = Color3.fromRGB(0, 0, 0)
		honeyNameLabel.TextScaled = true
		honeyNameLabel.Font = Enum.Font.GothamBold
		honeyNameLabel.TextXAlignment = Enum.TextXAlignment.Left
		honeyNameLabel.Parent = honeyInfoFrame

		local honeyStatusLabel = Instance.new("TextLabel")
		honeyStatusLabel.Size = UDim2.new(1, 0, 0.6, 0)
		honeyStatusLabel.Position = UDim2.new(0, 0, 0.4, 0)
		honeyStatusLabel.BackgroundTransparency = 1
		honeyStatusLabel.TextXAlignment = Enum.TextXAlignment.Left
		honeyStatusLabel.TextScaled = true
		honeyStatusLabel.Font = Enum.Font.Gotham
		honeyStatusLabel.Parent = honeyInfoFrame

		-- HONEY COUNTDOWN (Unified - All Hives)
		local function updateHoneyStatus()
			local currentTime = os.time()
			local lastCollect = player:GetAttribute("HiveLastCollect_Honey") or 0
			local productionTime = 300 -- 5 minutes
			local timeElapsed = currentTime - lastCollect

			if timeElapsed >= productionTime then
				honeyStatusLabel.Text = "✅ Ready!"
				honeyStatusLabel.TextColor3 = Color3.fromRGB(0, 180, 0)
			else
				local remaining = productionTime - timeElapsed
				local minutes = math.floor(remaining / 60)
				local seconds = remaining % 60
				honeyStatusLabel.Text = string.format("⏳ %dm %ds", minutes, seconds)
				honeyStatusLabel.TextColor3 = Color3.fromRGB(200, 150, 50)
			end
		end

		-- Initial update
		updateHoneyStatus()

		-- Live countdown loop
		task.spawn(function()
			while gui.Parent do
				task.wait(1)
				if gui.Parent then
					updateHoneyStatus()
				end
			end
		end)

		-- Buttons
		local buttonWidth = mobile and 0.19 or 0.18
		local buttonHeight = mobile and 36 or 34
		local buttonY = mobile and (rowHeight - buttonHeight - 8) or (rowHeight - buttonHeight - 5)
		local buttonSpacing = 0.015

		-- Collect button
		local collectHoneyBtn = Instance.new("TextButton")
		collectHoneyBtn.Size = UDim2.new(buttonWidth, 0, 0, buttonHeight)
		collectHoneyBtn.Position = UDim2.new(0.38, 0, 0, buttonY)
		collectHoneyBtn.BackgroundColor3 = Color3.fromRGB(100, 200, 100)
		collectHoneyBtn.Text = "Collect"
		collectHoneyBtn.TextColor3 = Color3.fromRGB(0, 0, 0)
		collectHoneyBtn.TextScaled = true
		collectHoneyBtn.Font = Enum.Font.GothamBold
		collectHoneyBtn.Parent = honeyFrame

		local collectHoneyCorner = Instance.new("UICorner")
		collectHoneyCorner.CornerRadius = UDim.new(0, 6)
		collectHoneyCorner.Parent = collectHoneyBtn

		-- Collect Honey Button
		collectHoneyBtn.MouseButton1Click:Connect(function()
			local success, result, icon = _G.CollectHoneyProduct(player)

			if success then
				updateHoneyStatus() -- Refresh countdown immediately
			else
				if type(result) == "number" then
					local minutes = math.floor(result / 60)
					local seconds = result % 60
					warn(string.format("Wait %dm %ds", minutes, seconds))
				else
					warn(result)
				end
			end
		end)

		-- Passive button (for next hive without passive)
		local nextPassiveHive = nil
		local nextPassiveCost = 0
		for i = 1, ownedHives do
			if not player:GetAttribute("PassiveHive_" .. i) then
				nextPassiveHive = i
				nextPassiveCost = HIVE_CONFIG[i].PassivePrice
				break
			end
		end

		local passiveBtn = Instance.new("TextButton")
		passiveBtn.Size = UDim2.new(buttonWidth, 0, 0, buttonHeight)
		passiveBtn.Position = UDim2.new(0.38 + buttonWidth + buttonSpacing, 0, 0, buttonY)

		if nextPassiveHive then
			passiveBtn.BackgroundColor3 = Color3.fromRGB(100, 150, 255)
			passiveBtn.Text = "Passive #" .. nextPassiveHive .. " $" .. nextPassiveCost
		else
			passiveBtn.BackgroundColor3 = Color3.fromRGB(100, 200, 100)
			passiveBtn.Text = "✓ All Passive"
		end

		passiveBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
		passiveBtn.TextScaled = true
		passiveBtn.Font = Enum.Font.Gotham
		passiveBtn.Parent = honeyFrame

		local passiveCorner = Instance.new("UICorner")
		passiveCorner.CornerRadius = UDim.new(0, 6)
		passiveCorner.Parent = passiveBtn

		passiveBtn.MouseButton1Click:Connect(function()
			if nextPassiveHive and _G.UpgradeHivePassive then
				local success = _G.UpgradeHivePassive(player, nextPassiveHive)
				if success then refreshCallback() end
			end
		end)

		-- Sell/List button with LIVE monitoring
		local productInventory = player:FindFirstChild("ProductInventory")
		local honeyValue = productInventory and productInventory:FindFirstChild("Honey")

		if honeyValue then
			-- Create initial button
			createSellButton(honeyFrame, "Honey", honeyValue, buttonWidth, buttonHeight, buttonY, buttonSpacing)

			-- Monitor inventory changes
			local honeyConnection = honeyValue.Changed:Connect(function()
				if gui.Parent then
					createSellButton(honeyFrame, "Honey", honeyValue, buttonWidth, buttonHeight, buttonY, buttonSpacing)
				end
			end)

			-- Cleanup connection when GUI is destroyed
			gui.Destroying:Connect(function()
				if honeyConnection then
					honeyConnection:Disconnect()
				end
			end)
		end

		yPos = yPos + rowHeight + 10

		-- ============================================
		-- ROW 2: WAX
		-- ============================================
		local waxFrame = Instance.new("Frame")
		waxFrame.Size = UDim2.new(0.95, 0, 0, rowHeight)
		waxFrame.Position = UDim2.new(0.025, 0, 0, yPos)
		waxFrame.BackgroundColor3 = Color3.fromRGB(220, 200, 150)
		waxFrame.BorderSizePixel = 0
		waxFrame.Parent = scrollFrame

		local waxCorner = Instance.new("UICorner")
		waxCorner.CornerRadius = UDim.new(0, 8)
		waxCorner.Parent = waxFrame

		local waxInfoFrame = Instance.new("Frame")
		waxInfoFrame.Size = UDim2.new(0.35, 0, 1, 0)
		waxInfoFrame.Position = UDim2.new(0.02, 0, 0, 0)
		waxInfoFrame.BackgroundTransparency = 1
		waxInfoFrame.Parent = waxFrame

		local waxNameLabel = Instance.new("TextLabel")
		waxNameLabel.Size = UDim2.new(1, 0, 0.4, 0)
		waxNameLabel.BackgroundTransparency = 1
		waxNameLabel.Text = "🕯️ Wax"
		waxNameLabel.TextColor3 = Color3.fromRGB(0, 0, 0)
		waxNameLabel.TextScaled = true
		waxNameLabel.Font = Enum.Font.GothamBold
		waxNameLabel.TextXAlignment = Enum.TextXAlignment.Left
		waxNameLabel.Parent = waxInfoFrame

		local waxStatusLabel = Instance.new("TextLabel")
		waxStatusLabel.Size = UDim2.new(1, 0, 0.6, 0)
		waxStatusLabel.Position = UDim2.new(0, 0, 0.4, 0)
		waxStatusLabel.BackgroundTransparency = 1
		waxStatusLabel.TextXAlignment = Enum.TextXAlignment.Left
		waxStatusLabel.TextScaled = true
		waxStatusLabel.Font = Enum.Font.Gotham
		waxStatusLabel.Parent = waxInfoFrame

		-- WAX COUNTDOWN (Unified - All Hives)
		local function updateWaxStatus()
			local currentTime = os.time()
			local lastCollect = player:GetAttribute("HiveLastCollect_Wax") or 0
			local productionTime = 600 -- 10 minutes
			local timeElapsed = currentTime - lastCollect

			if timeElapsed >= productionTime then
				waxStatusLabel.Text = "✅ Ready!"
				waxStatusLabel.TextColor3 = Color3.fromRGB(0, 180, 0)
			else
				local remaining = productionTime - timeElapsed
				local minutes = math.floor(remaining / 60)
				local seconds = remaining % 60
				waxStatusLabel.Text = string.format("⏳ %dm %ds", minutes, seconds)
				waxStatusLabel.TextColor3 = Color3.fromRGB(200, 120, 80)
			end
		end

		-- Initial update
		updateWaxStatus()

		-- Live countdown loop
		task.spawn(function()
			while gui.Parent do
				task.wait(1)
				if gui.Parent then
					updateWaxStatus()
				end
			end
		end)

		-- Collect Wax
		local collectWaxBtn = Instance.new("TextButton")
		collectWaxBtn.Size = UDim2.new(buttonWidth, 0, 0, buttonHeight)
		collectWaxBtn.Position = UDim2.new(0.38, 0, 0, buttonY)
		collectWaxBtn.BackgroundColor3 = Color3.fromRGB(100, 200, 100)
		collectWaxBtn.Text = "Collect"
		collectWaxBtn.TextColor3 = Color3.fromRGB(0, 0, 0)
		collectWaxBtn.TextScaled = true
		collectWaxBtn.Font = Enum.Font.GothamBold
		collectWaxBtn.Parent = waxFrame

		local collectWaxCorner = Instance.new("UICorner")
		collectWaxCorner.CornerRadius = UDim.new(0, 6)
		collectWaxCorner.Parent = collectWaxBtn

		-- Collect Wax Button
		collectWaxBtn.MouseButton1Click:Connect(function()
			local success, result, icon = _G.CollectWaxProduct(player)

			if success then
				updateWaxStatus() -- Refresh countdown immediately
			else
				if type(result) == "number" then
					local minutes = math.floor(result / 60)
					local seconds = result % 60
					warn(string.format("Wait %dm %ds", minutes, seconds))
				else
					warn(result)
				end
			end
		end)

		-- Passive button (same next hive logic)
		local passiveWaxBtn = Instance.new("TextButton")
		passiveWaxBtn.Size = UDim2.new(buttonWidth, 0, 0, buttonHeight)
		passiveWaxBtn.Position = UDim2.new(0.38 + buttonWidth + buttonSpacing, 0, 0, buttonY)

		if nextPassiveHive then
			passiveWaxBtn.BackgroundColor3 = Color3.fromRGB(100, 150, 255)
			passiveWaxBtn.Text = "Passive #" .. nextPassiveHive .. " $" .. nextPassiveCost
		else
			passiveWaxBtn.BackgroundColor3 = Color3.fromRGB(100, 200, 100)
			passiveWaxBtn.Text = "✓ All Passive"
		end

		passiveWaxBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
		passiveWaxBtn.TextScaled = true
		passiveWaxBtn.Font = Enum.Font.Gotham
		passiveWaxBtn.Parent = waxFrame

		local passiveWaxCorner = Instance.new("UICorner")
		passiveWaxCorner.CornerRadius = UDim.new(0, 6)
		passiveWaxCorner.Parent = passiveWaxBtn

		passiveWaxBtn.MouseButton1Click:Connect(function()
			if nextPassiveHive and _G.UpgradeHivePassive then
				local success = _G.UpgradeHivePassive(player, nextPassiveHive)
				if success then refreshCallback() end
			end
		end)

		-- Sell/List Wax with LIVE monitoring
		local waxValue = productInventory and productInventory:FindFirstChild("Wax")

		if waxValue then
			-- Create initial button
			createSellButton(waxFrame, "Wax", waxValue, buttonWidth, buttonHeight, buttonY, buttonSpacing)

			-- Monitor inventory changes
			local waxConnection = waxValue.Changed:Connect(function()
				if gui.Parent then
					createSellButton(waxFrame, "Wax", waxValue, buttonWidth, buttonHeight, buttonY, buttonSpacing)
				end
			end)

			-- Cleanup connection when GUI is destroyed
			gui.Destroying:Connect(function()
				if waxConnection then
					waxConnection:Disconnect()
				end
			end)
		end

		yPos = yPos + rowHeight + 10

	else
		-- Empty state
		local noHivesLabel = Instance.new("TextLabel")
		noHivesLabel.Size = UDim2.new(0.9, 0, 0, 80)
		noHivesLabel.Position = UDim2.new(0.05, 0, 0, 20)
		noHivesLabel.BackgroundTransparency = 1
		noHivesLabel.Text = "🐝 No beehives!\nVisit the Poultry Shop to buy."
		noHivesLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
		noHivesLabel.TextScaled = true
		noHivesLabel.Font = Enum.Font.Gotham
		noHivesLabel.Parent = scrollFrame
	end

	scrollFrame.CanvasSize = UDim2.new(0, 0, 0, yPos + 20)
	gui.Parent = player.PlayerGui
end



-- Global function to open Hive Barn
_G.openHiveBarn = function(player)
	print(player.Name .. " opened Hive Barn")
	local function refresh()
		createHiveBarnGUI(player, refresh)
	end
	createHiveBarnGUI(player, refresh)
end

-- RemoteFunction callback
GetHiveDataFunction.OnServerInvoke = function(player)
	return getOwnedHiveProducts(player)
end

-- RemoteEvent listener
HiveActionEvent.OnServerEvent:Connect(function(player, action, productName)
	print("🐝 HiveActionEvent:", action, productName)

	if action == "Sell" then
		local success, earnings, message = sellProduct(player, productName)
		HiveActionEvent:FireClient(player, "Sell", success, message)
	end
end)

-- Listen for client request to reopen Hive Barn
OpenHiveBarnServer.OnServerEvent:Connect(function(player)
	print("🔄 Client requested to reopen HiveBarn")
	_G.openHiveBarn(player)
end)

-- Update proximity prompts to open Hive Barn
task.spawn(function()
	task.wait(3)
	local hiveFolder = getHiveFolder()
	if hiveFolder then
		for i = 1, 8 do
			local outerHive = hiveFolder:FindFirstChild("Hive" .. i)
			if outerHive then
				local prompt = outerHive:FindFirstChildOfClass("ProximityPrompt", true)
				if prompt then
					prompt.Triggered:Connect(function(playerWhoTriggered)
						print("🐝 " .. playerWhoTriggered.Name .. " triggered Hive" .. i)
						_G.openHiveBarn(playerWhoTriggered)
					end)
					print("✅ Hive" .. i .. " proximity prompt connected")
				end
			end
		end
	end
end)

-- Passive upgrades
function _G.UpgradeHivePassive(player, hiveNum)
	if player:GetAttribute("PassiveHive_" .. hiveNum) then
		return false, "Already passive"
	end

	local beehiveCount = player:FindFirstChild("BeehiveCount")
	if not beehiveCount or hiveNum > beehiveCount.Value then
		return false, "Hive not owned"
	end

	local config = HIVE_CONFIG[hiveNum]
	if not config then
		return false, "Invalid hive"
	end

	local cash = player.leaderstats:FindFirstChild("Cash")
	if not cash or cash.Value < config.PassivePrice then
		return false, "Not enough money"
	end

	cash.Value = cash.Value - config.PassivePrice
	player:SetAttribute("PassiveHive_" .. hiveNum, true)
	print("✅ " .. player.Name .. " enabled passive for Hive " .. hiveNum .. " ($" .. config.PassivePrice .. ")")
	return true
end

-- Visual management (existing code - keep as is)
local function updateHiveVisuals(player)
	local beehiveCount = player:FindFirstChild("BeehiveCount")
	if not beehiveCount then return end

	local ownedCount = beehiveCount.Value

	for i = 1, 8 do
		local hiveModel = getHiveModel(i)
		if hiveModel then
			if i <= ownedCount then
				for _, descendant in pairs(hiveModel:GetDescendants()) do
					if descendant:IsA("BasePart") or descendant:IsA("UnionOperation") or descendant:IsA("MeshPart") then
						if descendant.Name == "Area" then
							descendant.Transparency = 1
						else
							descendant.Transparency = 0
						end
					end
				end
				local prompt = hiveModel:FindFirstChildOfClass("ProximityPrompt", true)
				if prompt then
					prompt.Enabled = true
				end
			else
				for _, descendant in pairs(hiveModel:GetDescendants()) do
					if descendant:IsA("BasePart") or descendant:IsA("UnionOperation") or descendant:IsA("MeshPart") then
						if descendant.Name == "Area" then
							descendant.Transparency = 1
						else
							descendant.Transparency = 0.6
						end
					end
				end
				local prompt = hiveModel:FindFirstChildOfClass("ProximityPrompt", true)
				if prompt then
					prompt.Enabled = false
				end
			end
		end
	end
end

-- Player initialization
Players.PlayerAdded:Connect(function(player)
	task.spawn(function()
		local beehiveCount = player:WaitForChild("BeehiveCount", 30)
		if not beehiveCount then
			warn("BeehiveCount not found for " .. player.Name)
			return
		end

		task.wait(3)
		print("🐝 Initializing hives for " .. player.Name .. " (Owned: " .. beehiveCount.Value .. ")")

		updateHiveVisuals(player)

		beehiveCount.Changed:Connect(function()
			print("🐝 " .. player.Name .. " now owns " .. beehiveCount.Value .. " hives")
			updateHiveVisuals(player)
		end)
	end)
end)

print("🐝 Hive Manager ready!")
