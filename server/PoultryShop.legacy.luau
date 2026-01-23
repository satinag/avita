-- ServerScriptService/PoultryShop
-- Handles Poultry Shop GUI with animals & beehives

local UserInputService = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ProductConfig = require(ReplicatedStorage:WaitForChild("ProductConfig"))

local SoundManager
pcall(function()
	SoundManager = require(game:GetService("ReplicatedStorage"):WaitForChild("SoundManager"), 2)
end)

print("Poultry Shop loaded!")

-- --
-- HELPERS
-- --
local function isMobile()
	return UserInputService.TouchEnabled and not UserInputService.KeyboardEnabled
end

local function getBeehiveCount(player)
	local beehiveCount = player:FindFirstChild("BeehiveCount")
	return beehiveCount and beehiveCount.Value or 0
end

-- --
-- BUSINESS LOGIC
-- --
local function buyAnimal(player, animalName, price)
	-- Check if already owned using AnimalInventory IntValue
	local animalInventory = player:FindFirstChild("AnimalInventory")
	if not animalInventory then
		warn("AnimalInventory not found!")
		return false, "Inventory not found"
	end

	local animalValue = animalInventory:FindFirstChild(animalName)
	if not animalValue then
		warn(animalName .. " IntValue not found in AnimalInventory!")
		return false, "Animal data not found"
	end

	local cash = player.leaderstats:FindFirstChild("Cash")
	if not cash or cash.Value < price then
		return false, "Not enough money"
	end

	-- Process purchase
	cash.Value = cash.Value - price

	-- Track stats
	_G.TrackStat(player, "TotalCashSpent", price)
	_G.TrackStat(player, "MoneySpentOnAnimals", price)
	_G.TrackStat(player, "TotalAnimalsOwned", 1)

	-- Increment animal count
	animalValue.Value = animalValue.Value + 1

	-- Check animal ownership quest
	local DailyQuestManager = require(script.Parent:WaitForChild("DailyQuestManager"))
	if DailyQuestManager then
		task.delay(1, function()
			DailyQuestManager:CheckAnimalOwnership(player)
		end)
	end

	print(player.Name .. " bought " .. animalName .. " New count: " .. animalValue.Value)


	if SoundManager then
		pcall(function()
			SoundManager:PlaySoundForPlayer(player, "PurchaseSound")
		end)
	end

	return true
end

local function buyBeehive(player, price)
	local cash = player.leaderstats:FindFirstChild("Cash")
	if not cash or cash.Value < price then
		return false, "Not enough money"
	end

	local beehiveCount = player:FindFirstChild("BeehiveCount")
	if not beehiveCount then
		return false, "BeehiveCount not found"
	end

	local currentCount = beehiveCount.Value
	if currentCount >= 8 then
		return false, "Max beehives owned"
	end

	-- Process purchase
	cash.Value = cash.Value - price

	-- Track stats
	_G.TrackStat(player, "TotalCashSpent", price)
	_G.TrackStat(player, "MoneySpentOnAnimals", price)

	beehiveCount.Value = currentCount + 1

	-- Track beehive purchase quest
	local DailyQuestManager = require(script.Parent:WaitForChild("DailyQuestManager"))
	if DailyQuestManager then
		task.delay(1, function()
			DailyQuestManager:CheckBeehiveOwnership(player)
		end)
	end


	print(player.Name .. " bought Beehive #" .. (currentCount + 1))

	if SoundManager then
		pcall(function()
			SoundManager:PlaySoundForPlayer(player, "PurchaseSound")
		end)
	end

	-- Call HiveManager to unlock the hive
	if _G.UnlockHive then
		_G.UnlockHive(player, currentCount + 1)
	end

	-- Tutorial: First beehive purchased
	-- Tutorial: First beehive purchased
	if currentCount == 0 then
		task.spawn(function()
			task.wait(0.3)

			-- ✅ Activate level 12 (GoToFirstHive) when buying first beehive
			if _G.ActivateTutorialLevel then
				print("🎯 Activating tutorial level 12 - First beehive bought")
				_G.ActivateTutorialLevel(player, 12)
			end
		end)
	end



	return true
end

-- --
-- GUI CREATION
-- --
local function createShopGUI(player, refreshCallback)
	local existingGui = player.PlayerGui:FindFirstChild("PoultryShopGui")
	if existingGui then
		existingGui:Destroy()
	end

	local gui = Instance.new("ScreenGui")
	gui.Name = "PoultryShopGui"
	gui.ResetOnSpawn = false
	gui.IgnoreGuiInset = true

	local camera = workspace.CurrentCamera
	local viewportSize = camera.ViewportSize
	local isNarrowScreen = viewportSize.X < 900
	local mobile = isNarrowScreen

	local frameWidth = isNarrowScreen and 0.98 or 0.50
	local frameHeight = isNarrowScreen and 0.90 or 0.75

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
	title.Size = UDim2.new(1, 0, 0, mobile and 60 or 50)
	title.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
	title.Text = "🐔 Poultry & Beehive Shop"
	title.TextColor3 = Color3.fromRGB(255, 255, 255)
	title.TextScaled = true
	title.Font = Enum.Font.GothamBold
	title.Parent = frame

	local titleCorner = Instance.new("UICorner")
	titleCorner.CornerRadius = UDim.new(0, 12)
	titleCorner.Parent = title

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

	local titleHeight = mobile and 60 or 50

	-- Scrolling frame
	local scrollFrame = Instance.new("ScrollingFrame")
	scrollFrame.Size = UDim2.new(1, -20, 1, -titleHeight - 20)
	scrollFrame.Position = UDim2.new(0, 10, 0, titleHeight + 10)
	scrollFrame.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
	scrollFrame.BorderSizePixel = 0
	scrollFrame.ScrollBarThickness = mobile and 12 or 8
	scrollFrame.Parent = frame

	local scrollCorner = Instance.new("UICorner")
	scrollCorner.CornerRadius = UDim.new(0, 8)
	scrollCorner.Parent = scrollFrame

	local yPos = 10
	local baseContentHeight = mobile and 80 or 70
	local buttonHeight = mobile and 40 or 34
	local padding = mobile and 12 or 10
	local rowHeight = baseContentHeight + buttonHeight + padding

	-- Render animals from ProductConfig
	for animalName, animalData in pairs(ProductConfig.ANIMALS) do
		local animalInventory = player:FindFirstChild("AnimalInventory")
		local animalValue = animalInventory and animalInventory:FindFirstChild(animalName)
		local ownedCount = animalValue and animalValue.Value or 0

		local itemFrame = Instance.new("Frame")
		itemFrame.Size = UDim2.new(0.95, 0, 0, rowHeight)
		itemFrame.Position = UDim2.new(0.025, 0, 0, yPos)
		itemFrame.BackgroundColor3 = ownedCount > 0 and Color3.fromRGB(50, 100, 50) or Color3.fromRGB(70, 70, 70)
		itemFrame.BorderSizePixel = 0
		itemFrame.Parent = scrollFrame

		local itemCorner = Instance.new("UICorner")
		itemCorner.CornerRadius = UDim.new(0, 8)
		itemCorner.Parent = itemFrame

		-- Name
		local nameLabel = Instance.new("TextLabel")
		nameLabel.Size = UDim2.new(0.55, 0, 0, mobile and 36 or 30)
		nameLabel.Position = UDim2.new(0.05, 0, 0, 8)
		nameLabel.BackgroundTransparency = 1
		nameLabel.Text = animalData.Icon .. " " .. animalName
		nameLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
		nameLabel.TextScaled = true
		nameLabel.Font = Enum.Font.GothamBold
		nameLabel.TextXAlignment = Enum.TextXAlignment.Left
		nameLabel.Parent = itemFrame

		-- Description
		local descLabel = Instance.new("TextLabel")
		descLabel.Size = UDim2.new(0.55, 0, 0, mobile and 42 or 34)
		descLabel.Position = UDim2.new(0.05, 0, 0, mobile and 48 or 40)
		descLabel.BackgroundTransparency = 1
		descLabel.Text = animalData.Description
		descLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
		descLabel.TextScaled = true
		descLabel.Font = Enum.Font.Gotham
		descLabel.TextXAlignment = Enum.TextXAlignment.Left
		descLabel.Parent = itemFrame

		-- Buy button
		local buttonWidth = mobile and 0.35 or 0.32
		local btnHeight = mobile and 40 or 34
		local buttonY = mobile and 18 or 16

		local buyBtn = Instance.new("TextButton")
		buyBtn.Size = UDim2.new(buttonWidth, 0, 0, btnHeight)
		buyBtn.Position = UDim2.new(0.62, 0, 0, buttonY)
		buyBtn.BackgroundColor3 = Color3.fromRGB(100, 200, 100)
		buyBtn.Text = ownedCount > 0 and ("Buy (" .. ownedCount .. " owned)") or ("Buy 💵" .. animalData.BuyPrice)
		buyBtn.TextColor3 = Color3.fromRGB(0, 0, 0)
		buyBtn.TextScaled = true
		buyBtn.Font = Enum.Font.GothamBold
		buyBtn.Parent = itemFrame

		local buyCorner = Instance.new("UICorner")
		buyCorner.CornerRadius = UDim.new(0, 6)
		buyCorner.Parent = buyBtn

		buyBtn.MouseButton1Click:Connect(function()
			local success = buyAnimal(player, animalName, animalData.BuyPrice)
			if success then
				refreshCallback()
			end
		end)

		yPos = yPos + rowHeight + 6
	end
	-- Beehive section - NOW USING PRODUCTCONFIG
	local currentCount = getBeehiveCount(player)
	local beehiveConfig = ProductConfig.BEEHIVE_CONFIG

	local beehiveFrame = Instance.new("Frame")
	beehiveFrame.Size = UDim2.new(0.95, 0, 0, rowHeight + 30)
	beehiveFrame.Position = UDim2.new(0.025, 0, 0, yPos)
	beehiveFrame.BackgroundColor3 = Color3.fromRGB(80, 70, 50)
	beehiveFrame.BorderSizePixel = 0
	beehiveFrame.Parent = scrollFrame

	local beehiveCorner = Instance.new("UICorner")
	beehiveCorner.CornerRadius = UDim.new(0, 8)
	beehiveCorner.Parent = beehiveFrame

	-- Name
	local nameLabel = Instance.new("TextLabel")
	nameLabel.Size = UDim2.new(0.55, 0, 0, mobile and 36 or 30)
	nameLabel.Position = UDim2.new(0.05, 0, 0, 8)
	nameLabel.BackgroundTransparency = 1
	nameLabel.Text = beehiveConfig.Icon .. " " .. beehiveConfig.Name
	nameLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
	nameLabel.TextScaled = true
	nameLabel.Font = Enum.Font.GothamBold
	nameLabel.TextXAlignment = Enum.TextXAlignment.Left
	nameLabel.Parent = beehiveFrame

	-- Quantity owned
	local qtyLabel = Instance.new("TextLabel")
	qtyLabel.Size = UDim2.new(0.55, 0, 0, mobile and 30 or 24)
	qtyLabel.Position = UDim2.new(0.05, 0, 0, mobile and 44 or 36)
	qtyLabel.BackgroundTransparency = 1
	qtyLabel.Text = "Owned: " .. currentCount .. " / " .. beehiveConfig.MaxQuantity
	qtyLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
	qtyLabel.TextScaled = true
	qtyLabel.Font = Enum.Font.Gotham
	qtyLabel.TextXAlignment = Enum.TextXAlignment.Left
	qtyLabel.Parent = beehiveFrame

	-- Next hive info
	local nextHiveNum = currentCount + 1
	if nextHiveNum <= beehiveConfig.MaxQuantity then
		local beehiveData = ProductConfig.GetBeehiveData(nextHiveNum)
		local nextPrice = beehiveData.Price
		local nextRate = beehiveData.HoneyRate

		local infoLabel = Instance.new("TextLabel")
		infoLabel.Size = UDim2.new(0.55, 0, 0, mobile and 30 or 24)
		infoLabel.Position = UDim2.new(0.05, 0, 0, mobile and 74 or 60)
		infoLabel.BackgroundTransparency = 1
		infoLabel.Text = "Next: 🍯" .. nextRate .. "/hr"
		infoLabel.TextColor3 = Color3.fromRGB(255, 220, 150)
		infoLabel.TextScaled = true
		infoLabel.Font = Enum.Font.Gotham
		infoLabel.TextXAlignment = Enum.TextXAlignment.Left
		infoLabel.Parent = beehiveFrame

		-- Buy button
		local buttonWidth = mobile and 0.35 or 0.32
		local btnHeight = mobile and 40 or 34
		local buttonY = mobile and 30 or 20

		local buyBtn = Instance.new("TextButton")
		buyBtn.Size = UDim2.new(buttonWidth, 0, 0, btnHeight)
		buyBtn.Position = UDim2.new(0.62, 0, 0, buttonY)
		buyBtn.BackgroundColor3 = Color3.fromRGB(255, 200, 50)
		buyBtn.Text = "Buy Hive #" .. nextHiveNum .. " 💵" .. nextPrice
		buyBtn.TextColor3 = Color3.fromRGB(0, 0, 0)
		buyBtn.TextScaled = true
		buyBtn.Font = Enum.Font.GothamBold
		buyBtn.Parent = beehiveFrame

		local buyCorner = Instance.new("UICorner")
		buyCorner.CornerRadius = UDim.new(0, 6)
		buyCorner.Parent = buyBtn

		buyBtn.MouseButton1Click:Connect(function()
			local success = buyBeehive(player, nextPrice)
			if success then
				refreshCallback()
			end
		end)
	else
		-- Max hives owned
		local maxLabel = Instance.new("TextLabel")
		maxLabel.Size = UDim2.new(0.35, 0, 0, mobile and 40 or 34)
		maxLabel.Position = UDim2.new(0.62, 0, 0, mobile and 30 or 20)
		maxLabel.BackgroundColor3 = Color3.fromRGB(100, 200, 100)
		maxLabel.Text = "✅ MAX"
		maxLabel.TextColor3 = Color3.fromRGB(0, 0, 0)
		maxLabel.TextScaled = true
		maxLabel.Font = Enum.Font.GothamBold
		maxLabel.Parent = beehiveFrame

		local maxCorner = Instance.new("UICorner")
		maxCorner.CornerRadius = UDim.new(0, 6)
		maxCorner.Parent = maxLabel
	end

	yPos = yPos + rowHeight + 36

	scrollFrame.CanvasSize = UDim2.new(0, 0, 0, yPos + 10)
	gui.Parent = player.PlayerGui
end

-- --
-- PUBLIC FUNCTION
-- --
_G.openPoultryShop = function(player)
	print(player.Name .. " opened Poultry Shop")

	-- ✅ Complete level 11 when opening (tutorial pauses - level becomes 999)
	if _G.CompleteTutorialLevel then
		local currentLevel = player:FindFirstChild("CurrentArrowLevel")
		if currentLevel and currentLevel.Value == 11 then
			print("🎯 Completing tutorial level 11 - Visited Poultry Shop")
			_G.CompleteTutorialLevel(player, 11)
		end
	end

	local function refresh()
		createShopGUI(player, refresh)
	end

	createShopGUI(player, refresh)
end



