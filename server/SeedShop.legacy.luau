-- ServerScriptService/SeedShop
-- Handles Seed Shop GUI and PURCHASES ONLY
local ProductConfig = require(game:GetService("ReplicatedStorage"):WaitForChild("ProductConfig"))

local SoundManager
pcall(function() SoundManager = require(game:GetService("ReplicatedStorage"):WaitForChild("SoundManager", 2)) end)

local UserInputService = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

print("🌱 Seed Shop loaded!")

-- ❌ DELETE THESE 3 LINES (lines 13-15)
-- local cropData = ProductConfig.GetCropData(seedName)
-- local cost = cropData.SeedCost
-- local quantity = cropData.SeedQuantity

local SEED_ORDER = {"Wheat", "Corn", "Carrot", "Potato", "Tomato", "Pumpkin", "Strawberry", "Watermelon"}

-- ============================================
-- HELPERS
-- ============================================

local function isMobile()
	return UserInputService.TouchEnabled and not UserInputService.KeyboardEnabled
end

-- ============================================
-- BUSINESS LOGIC - PURCHASE ONLY
-- ============================================

local function buySeed(player, seedName)
	-- ✅ Get data from ProductConfig
	local data = ProductConfig.GetCropData(seedName)
	if not data then
		return false, "Invalid seed"
	end

	local totalEarned = player:FindFirstChild("TotalEarned")

	if not totalEarned or totalEarned.Value < data.UnlockRequirement then
		return false, "locked"
	end

	local cash = player.leaderstats:FindFirstChild("Cash")
	local seedInventory = player:FindFirstChild("SeedInventory")

	if not cash or cash.Value < data.SeedCost then
		return false, "poor"
	end

	if seedInventory then
		local seedValue = seedInventory:FindFirstChild(seedName)
		if seedValue then
			cash.Value = cash.Value - data.SeedCost

			-- Track stat
			_G.TrackStat(player, "TotalCashSpent", data.SeedCost)
			_G.TrackStat(player, "MoneySpentOnSeeds", data.SeedCost)

			seedValue.Value = seedValue.Value + data.SeedQuantity
			print("🌱 " .. player.Name .. " bought " .. seedName .. " seeds")

			-- 🎯 Tutorial: Complete "BuySeeds" step on first seed purchase
			if _G.CompleteTutorialLevel then
				_G.CompleteTutorialLevel(player, 2)
			end

			-- 🏆 INCREMENT TIER on first purchase of this seed
			local seedsUnlocked = player:FindFirstChild("SeedsUnlocked")
			if seedsUnlocked and seedValue.Value == data.SeedQuantity then  -- Was 0, now has seeds = new unlock
				seedsUnlocked.Value = seedsUnlocked.Value + 1
				print("🏆 " .. player.Name .. " unlocked Tier " .. seedsUnlocked.Value .. " (" .. seedName .. ")")
			end

			-- Auto-select seed after purchase
			task.wait(0.1)
			local inventory = player:FindFirstChild("SeedInventory")
			local availableSeeds = {}
			for _, seedVal in pairs(inventory:GetChildren()) do
				if seedVal:IsA("IntValue") and seedVal.Value > 0 then
					table.insert(availableSeeds, seedVal.Name)
				end
			end

			if #availableSeeds == 1 then
				player:SetAttribute("SelectedSeed", availableSeeds[1])
				print(player.Name .. " auto-selected " .. availableSeeds[1])
			else
				player:SetAttribute("SelectedSeed", seedName)
				print(player.Name .. " auto-selected purchased seed: " .. seedName)
			end

			if SoundManager then 
				pcall(function() SoundManager:PlaySoundForPlayer(player, "PurchaseSound") end) 
			end

			return true
		end
	end

	return false, "error"
end

-- ============================================
-- GUI CREATION
-- ============================================

local function createSeedShopGUI(player, refreshCallback)
	local existingGui = player.PlayerGui:FindFirstChild("SeedShopGui")
	if existingGui then existingGui:Destroy() end

	local gui = Instance.new("ScreenGui")
	gui.Name = "SeedShopGui"
	gui.ResetOnSpawn = false
	gui.IgnoreGuiInset = true

	local camera = workspace.CurrentCamera
	local viewportSize = camera.ViewportSize
	local isNarrowScreen = viewportSize.X < 900
	local mobile = isNarrowScreen

	local frameWidth = isNarrowScreen and 0.98 or 0.55
	local frameHeight = isNarrowScreen and 0.90 or 0.80

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
	title.Name = "Title"
	title.Size = UDim2.new(1, 0, 0, mobile and 60 or 50)
	title.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
	title.Text = "🌱 Seed Shop"
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
	closeButton.Size = UDim2.new(0, 40, 0, 40)
	closeButton.Position = UDim2.new(1, -45, 0, 5)
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

	local titleHeight = mobile and 60 or 50

	-- Container for grid layout
	local scrollFrame = Instance.new("ScrollingFrame")
	scrollFrame.Name = "ScrollFrame"
	scrollFrame.Size = UDim2.new(1, -20, 1, -(titleHeight + 20))
	scrollFrame.Position = UDim2.new(0, 10, 0, titleHeight + 10)
	scrollFrame.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
	scrollFrame.BorderSizePixel = 0
	scrollFrame.ScrollBarThickness = mobile and 12 or 8
	scrollFrame.Parent = frame

	local scrollCorner = Instance.new("UICorner")
	scrollCorner.CornerRadius = UDim.new(0, 8)
	scrollCorner.Parent = scrollFrame

	-- Container for rows
	local container = Instance.new("Frame")
	container.Name = "Container"
	container.Size = UDim2.new(1, 0, 0, 0)
	container.BackgroundTransparency = 1
	container.Parent = scrollFrame

	-- UIListLayout for rows
	local listLayout = Instance.new("UIListLayout")
	listLayout.FillDirection = Enum.FillDirection.Vertical
	listLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
	listLayout.VerticalAlignment = Enum.VerticalAlignment.Top
	listLayout.SortOrder = Enum.SortOrder.LayoutOrder
	listLayout.Padding = UDim.new(0, 8)
	listLayout.Parent = container

	-- Create rows (2 buttons per row)
	local buttons = {}
	local numRows = math.ceil(#SEED_ORDER / 2)
	local rowHeight = mobile and 100 or 90

	for row = 0, numRows - 1 do
		local rowFrame = Instance.new("Frame")
		rowFrame.Name = "Row" .. (row + 1)
		rowFrame.Size = UDim2.new(1, 0, 0, rowHeight)
		rowFrame.BackgroundTransparency = 1
		rowFrame.LayoutOrder = row
		rowFrame.Parent = container

		-- Create 2 buttons in this row
		for col = 0, 1 do
			local index = (row * 2) + col + 1
			if index <= #SEED_ORDER then
				local seedName = SEED_ORDER[index]
				-- ✅ Get data from ProductConfig
				local data = ProductConfig.GetCropData(seedName)

				local button = Instance.new("TextButton")
				button.Name = seedName .. "Button"
				button.Size = UDim2.new(0.48, 0, 1, 0)
				button.Position = UDim2.new(col * 0.51, 0, 0, 0)
				button.BackgroundColor3 = Color3.fromRGB(100, 100, 100)
				button.Text = ""
				button.BorderSizePixel = 0
				button.Parent = rowFrame

				local corner = Instance.new("UICorner")
				corner.CornerRadius = UDim.new(0, 8)
				corner.Parent = button

				-- Text label
				local textLabel = Instance.new("TextLabel")
				textLabel.Size = UDim2.new(1, 0, 1, 0)
				textLabel.BackgroundTransparency = 1
				textLabel.TextColor3 = Color3.fromRGB(150, 150, 150)
				textLabel.Font = Enum.Font.Gotham
				textLabel.TextScaled = true
				textLabel.TextWrapped = true
				textLabel.Text = seedName .. "\n🔒 Locked"
				textLabel.TextYAlignment = Enum.TextYAlignment.Center
				textLabel.Parent = button

				local textPadding = Instance.new("UIPadding")
				textPadding.PaddingLeft = UDim.new(0.05, 0)
				textPadding.PaddingRight = UDim.new(0.05, 0)
				textPadding.PaddingTop = UDim.new(0.1, 0)
				textPadding.PaddingBottom = UDim.new(0.1, 0)
				textPadding.Parent = textLabel

				buttons[seedName] = {Button = button, Label = textLabel}

				button.MouseButton1Click:Connect(function()
					local success = buySeed(player, seedName)
					if success then
						refreshCallback()
					end
				end)
			end
		end
	end

	-- ============================================
	-- UPDATE BUTTON DISPLAY
	-- ============================================

	local function updateButtons()
		local totalEarned = player:FindFirstChild("TotalEarned")
		local seedInventory = player:FindFirstChild("SeedInventory")

		if totalEarned and seedInventory then
			for seedName, buttonData in pairs(buttons) do
				-- ✅ Get data from ProductConfig
				local data = ProductConfig.GetCropData(seedName)
				local button = buttonData.Button
				local label = buttonData.Label
				local seedValue = seedInventory:FindFirstChild(seedName)
				local owned = seedValue and seedValue.Value or 0
				local unlocked = totalEarned.Value >= data.UnlockRequirement

				if unlocked then
					button.BackgroundColor3 = Color3.fromRGB(100, 200, 100)
					label.TextColor3 = Color3.fromRGB(0, 0, 0)
					label.Text = data.Emoji .. " " .. seedName .. "\n🌱 " .. owned .. " | 💰 " .. data.SeedCost
				else
					button.BackgroundColor3 = Color3.fromRGB(100, 100, 100)
					label.TextColor3 = Color3.fromRGB(150, 150, 150)
					label.Text = data.Emoji .. " " .. seedName .. "\n🔒 " .. data.UnlockRequirement
				end
			end
		end
	end

	-- Initial update
	updateButtons()

	-- Listen for changes
	task.spawn(function()
		local totalEarned = player:FindFirstChild("TotalEarned")
		if totalEarned then
			totalEarned.Changed:Connect(updateButtons)
		end

		local seedInventory = player:FindFirstChild("SeedInventory")
		if seedInventory then
			for _, seed in pairs(seedInventory:GetChildren()) do
				seed.Changed:Connect(updateButtons)
			end
			seedInventory.ChildAdded:Connect(function(child)
				child.Changed:Connect(updateButtons)
			end)
		end
	end)

	-- Calculate canvas size based on number of rows
	local canvasHeight = (numRows * rowHeight) + ((numRows - 1) * 8) + 16  -- rows + padding + margin
	scrollFrame.CanvasSize = UDim2.new(0, 0, 0, canvasHeight)

	gui.Parent = player.PlayerGui
end

-- ============================================
-- PUBLIC FUNCTION
-- ============================================

_G.openSeedShop = function(player)
	print(player.Name .. " opened seed shop")
	local function refresh()
		createSeedShopGUI(player, refresh)
	end
	createSeedShopGUI(player, refresh)
end
