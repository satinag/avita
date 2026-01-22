-- ServerScriptService/PoultryBarn
-- Handles barn collection for multiple animal types

local UserInputService = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ProductConfig = require(ReplicatedStorage:WaitForChild("ProductConfig"))  
local SoundManager

pcall(function() 
	SoundManager = require(game:GetService("ReplicatedStorage"):WaitForChild("SoundManager", 2)) 
end)

-- Create RemoteEvents for client communication
local GetProductDataFunction = ReplicatedStorage:FindFirstChild("GetProductData")
if not GetProductDataFunction then
	GetProductDataFunction = Instance.new("RemoteFunction")
	GetProductDataFunction.Name = "GetProductData"
	GetProductDataFunction.Parent = ReplicatedStorage
	print("✅ Created GetProductData RemoteFunction")
end

local ProductActionEvent = ReplicatedStorage:FindFirstChild("ProductActionEvent")
if not ProductActionEvent then
	ProductActionEvent = Instance.new("RemoteEvent")
	ProductActionEvent.Name = "ProductActionEvent"
	ProductActionEvent.Parent = ReplicatedStorage
	print("✅ Created ProductActionEvent")
end

local OpenPoultryBarnEvent = ReplicatedStorage:FindFirstChild("OpenPoultryBarnEvent")
if not OpenPoultryBarnEvent then
	OpenPoultryBarnEvent = Instance.new("RemoteEvent")
	OpenPoultryBarnEvent.Name = "OpenPoultryBarnEvent"
	OpenPoultryBarnEvent.Parent = ReplicatedStorage
	print("✅ Created OpenPoultryBarnEvent")
end

print("🏠 Poultry Barn loaded!")

-- ============================================
-- CONSTANTS
-- ============================================

local ANIMAL_RATES = {
	Chicken = 20,
	Cow = 50,
	Pig = 35,
	Sheep = 40
}

-- ============================================
-- HELPERS
-- ============================================

local function isMobile()
	return UserInputService.TouchEnabled and not UserInputService.KeyboardEnabled
end

local function getOwnedAnimals(player)
	local owned = {}

	print("🔍 Checking AnimalInventory for " .. player.Name)

	-- Check AnimalInventory (IntValue)
	local animalInventory = player:FindFirstChild("AnimalInventory")

	if not animalInventory then
		warn("❌ AnimalInventory folder not found for " .. player.Name)
		return owned
	end

	print("✅ AnimalInventory found, checking children...")

	for _, animalValue in ipairs(animalInventory:GetChildren()) do
		print("  - Found: " .. animalValue.Name .. " (Type: " .. animalValue.ClassName .. ", Value: " .. tostring(animalValue.Value) .. ")")

		if animalValue:IsA("IntValue") and animalValue.Value > 0 then
			table.insert(owned, animalValue.Name)
			print("  ✅ Added " .. animalValue.Name .. " to owned list")
		end
	end

	print("📊 Total owned animals: " .. #owned)
	return owned
end

-- ============================================
-- COLLECTION LOGIC
-- ============================================

local function collectAnimal(player, animalName)
	-- Use ProductManager to collect products instead of cash
	if not _G.CollectAnimalProduct then
		warn("❌ ProductManager not loaded!")
		return false, "System not ready"
	end

	local success, result, icon = _G.CollectAnimalProduct(player, animalName)

	if success then
		-- result = amount collected
		-- icon = product emoji

		-- Show notification
		local showTutorialEvent = ReplicatedStorage:WaitForChild("ShowTutorialEvent")
		showTutorialEvent:FireClient(player, "ProductCollected", {
			Title = "📦 Collection Complete!",
			Message = icon .. " You collected " .. result .. " from your " .. animalName .. "!",
			Duration = 3
		})

		-- Play sound
		if SoundManager then
			pcall(function()
				SoundManager:PlaySoundForPlayer(player, "CoinSound")
			end)
		end

		return true, result
	else
		-- result = cooldown remaining (if number) or error message
		if type(result) == "number" then
			-- Still on cooldown
			return false, "Wait " .. math.floor(result / 60) .. "m " .. (result % 60) .. "s"
		else
			return false, result
		end
	end
end

local function upgradeAnimalPassive(player, animalName)
	if player:GetAttribute("Passive_" .. animalName) then
		return false, "Already active"
	end

	local upgradePrices = {Chicken=3000, Cow=6000, Pig=4500, Sheep=5000}
	local price = upgradePrices[animalName]

	local cash = player.leaderstats:FindFirstChild("Cash")
	if not cash or cash.Value < price then
		return false, "Not enough money"
	end

	cash.Value = cash.Value - price
	player:SetAttribute("Passive_" .. animalName, true)
	print("💰 " .. player.Name .. " enabled passive for " .. animalName .. " ($" .. price .. ")")
	return true
end

-- ============================================
-- GUI CREATION
-- ============================================

local function createBarnGUI(player, refreshCallback)
	local existingGui = player.PlayerGui:FindFirstChild("PoultryBarnGui")
	if existingGui then existingGui:Destroy() end

	local gui = Instance.new("ScreenGui")
	gui.Name = "PoultryBarnGui"
	gui.ResetOnSpawn = false
	gui.IgnoreGuiInset = true

	local camera = workspace.CurrentCamera
	local viewportSize = camera.ViewportSize
	local isNarrowScreen = viewportSize.X < 900
	local mobile = isNarrowScreen

	local frameWidth = isNarrowScreen and 0.98 or 0.55
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
	title.Text = "🏠 Animal Barn"
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

	local titleHeight = mobile and 60 or 50

	-- Scrolling frame
	local scrollFrame = Instance.new("ScrollingFrame")
	scrollFrame.Size = UDim2.new(1, -20, 1, -(titleHeight + 20))
	scrollFrame.Position = UDim2.new(0, 10, 0, titleHeight + 10)
	scrollFrame.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
	scrollFrame.BorderSizePixel = 0
	scrollFrame.ScrollBarThickness = mobile and 12 or 8
	scrollFrame.Parent = frame

	local scrollCorner = Instance.new("UICorner")
	scrollCorner.CornerRadius = UDim.new(0, 8)
	scrollCorner.Parent = scrollFrame

	local ownedAnimals = getOwnedAnimals(player)
	local yPos = 10
	local rowHeight = mobile and 100 or 85

	-- Animals section
	if #ownedAnimals > 0 then
		-- Section header
		local animalHeader = Instance.new("TextLabel")
		animalHeader.Size = UDim2.new(0.9, 0, 0, 30)
		animalHeader.Position = UDim2.new(0.05, 0, 0, yPos)
		animalHeader.BackgroundTransparency = 1
		animalHeader.Text = "🐔 Animals"
		animalHeader.TextColor3 = Color3.fromRGB(255, 255, 100)
		animalHeader.TextScaled = true
		animalHeader.Font = Enum.Font.GothamBold
		animalHeader.TextXAlignment = Enum.TextXAlignment.Left
		animalHeader.Parent = scrollFrame
		yPos = yPos + 40

		for _, animalName in ipairs(ownedAnimals) do
			local icons = {Chicken="🐔", Cow="🐮", Pig="🐷", Sheep="🐑"}

			local animalFrame = Instance.new("Frame")
			animalFrame.Size = UDim2.new(0.95, 0, 0, rowHeight)
			animalFrame.Position = UDim2.new(0.025, 0, 0, yPos)
			animalFrame.BackgroundColor3 = Color3.fromRGB(60, 80, 60)
			animalFrame.BorderSizePixel = 0
			animalFrame.Parent = scrollFrame

			local animalCorner = Instance.new("UICorner")
			animalCorner.CornerRadius = UDim.new(0, 8)
			animalCorner.Parent = animalFrame

			-- Info frame (left)
			local infoFrame = Instance.new("Frame")
			infoFrame.Size = UDim2.new(0.35, 0, 1, 0)
			infoFrame.Position = UDim2.new(0.02, 0, 0, 0)
			infoFrame.BackgroundTransparency = 1
			infoFrame.Parent = animalFrame

			local nameLabel = Instance.new("TextLabel")
			nameLabel.Size = UDim2.new(1, 0, 0.4, 0)
			nameLabel.BackgroundTransparency = 1
			nameLabel.Text = (icons[animalName] or "") .. " " .. animalName
			nameLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
			nameLabel.TextScaled = true
			nameLabel.Font = Enum.Font.GothamBold
			nameLabel.TextXAlignment = Enum.TextXAlignment.Left
			nameLabel.Parent = infoFrame

			-- Get animal product info from ProductConfig
			local animalData = ProductConfig.GetAnimalData(animalName)

			-- Get animal count
			local animalInventory = player:FindFirstChild("AnimalInventory")
			local animalValue = animalInventory and animalInventory:FindFirstChild(animalName)
			local animalCount = animalValue and animalValue.Value or 0

			local rateLabel = Instance.new("TextLabel")
			rateLabel.Size = UDim2.new(1, 0, 0.6, 0)
			rateLabel.Position = UDim2.new(0, 0, 0.4, 0)
			rateLabel.BackgroundTransparency = 1
			rateLabel.TextXAlignment = Enum.TextXAlignment.Left

			-- Show cooldown status
			if animalData then
				local lastCollect = player:GetAttribute("AnimalLastCollect_" .. animalName) or 0
				local currentTime = os.time()
				local timeElapsed = currentTime - lastCollect
				local productionTime = animalData.ProductionTime or 60
				local cyclesReady = math.floor(timeElapsed / productionTime)
				local nextCycleIn = productionTime - (timeElapsed % productionTime)

				if cyclesReady > 0 then
					rateLabel.Text = "✅ Ready! (" .. cyclesReady .. " cycles × " .. animalCount .. " = " .. (cyclesReady * animalCount) .. " " .. animalData.ProductType .. ")"
					rateLabel.TextColor3 = Color3.fromRGB(100, 255, 100)  -- Green
				else
					rateLabel.Text = "⏳ Next in " .. nextCycleIn .. "s (" .. animalCount .. " animals)"
					rateLabel.TextColor3 = Color3.fromRGB(255, 220, 150)  -- Yellow
				end
			else
				rateLabel.Text = "Produces resources"
				rateLabel.TextColor3 = Color3.fromRGB(255, 220, 150)
			end

			rateLabel.TextScaled = true
			rateLabel.Font = Enum.Font.Gotham
			rateLabel.Parent = infoFrame

			-- ==========================================
			-- 3 HORIZONTAL BUTTONS (Collect, Auto-Collect, Sell/List)
			-- ==========================================

			local buttonWidth = mobile and 0.19 or 0.18
			local buttonHeight = mobile and 36 or 34
			local buttonY = mobile and (rowHeight - buttonHeight - 8) or (rowHeight - buttonHeight - 5)
			local buttonSpacing = 0.015

			-- 1. COLLECT BUTTON (Left)
			local collectBtn = Instance.new("TextButton")
			collectBtn.Size = UDim2.new(buttonWidth, 0, 0, buttonHeight)
			collectBtn.Position = UDim2.new(0.38, 0, 0, buttonY)
			collectBtn.BackgroundColor3 = Color3.fromRGB(100, 200, 100)
			collectBtn.Text = "Collect " .. (animalData and animalData.ProductType or "Product")
			collectBtn.TextColor3 = Color3.fromRGB(0, 0, 0)
			collectBtn.TextScaled = true
			collectBtn.Font = Enum.Font.GothamBold
			collectBtn.Parent = animalFrame

			local collectCorner = Instance.new("UICorner")
			collectCorner.CornerRadius = UDim.new(0, 6)
			collectCorner.Parent = collectBtn

			collectBtn.MouseButton1Click:Connect(function()
				local success = collectAnimal(player, animalName)
				if success then
					refreshCallback()
				end
			end)

			-- 2. AUTO-COLLECT BUTTON (Middle)
			local autoCollectBtn = Instance.new("TextButton")
			autoCollectBtn.Size = UDim2.new(buttonWidth, 0, 0, buttonHeight)
			autoCollectBtn.Position = UDim2.new(0.38 + buttonWidth + buttonSpacing, 0, 0, buttonY)

			-- Check if auto-collect is enabled
			local autoEnabled = player:GetAttribute("AutoCollect_" .. animalName)
			if autoEnabled then
				autoCollectBtn.BackgroundColor3 = Color3.fromRGB(100, 200, 100)
				autoCollectBtn.Text = "✓ Auto-Collect"
			else
				autoCollectBtn.BackgroundColor3 = Color3.fromRGB(100, 150, 255)
				autoCollectBtn.Text = "Auto $3000"
			end

			autoCollectBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
			autoCollectBtn.TextScaled = true
			autoCollectBtn.Font = Enum.Font.Gotham
			autoCollectBtn.Parent = animalFrame

			local autoCorner = Instance.new("UICorner")
			autoCorner.CornerRadius = UDim.new(0, 6)
			autoCorner.Parent = autoCollectBtn

			autoCollectBtn.MouseButton1Click:Connect(function()
				if player:GetAttribute("AutoCollect_" .. animalName) then
					return  -- Already enabled
				end

				local cash = player.leaderstats:FindFirstChild("Cash")
				if cash and cash.Value >= 3000 then
					cash.Value = cash.Value - 3000
					player:SetAttribute("AutoCollect_" .. animalName, true)
					print("✅ " .. player.Name .. " enabled auto-collect for " .. animalName)
					refreshCallback()
				end
			end)

			-- 3. SELL/LIST BUTTON (Right) - ONLY if has products
			local productInventory = player:FindFirstChild("ProductInventory")
			local productType = animalData and animalData.ProductType or nil
			local productValue = productInventory and productType and productInventory:FindFirstChild(productType)
			local hasProducts = productValue and productValue.Value > 0

			if hasProducts then
				local sellListBtn = Instance.new("TextButton")
				sellListBtn.Size = UDim2.new(buttonWidth, 0, 0, buttonHeight)
				sellListBtn.Position = UDim2.new(0.38 + (buttonWidth + buttonSpacing) * 2, 0, 0, buttonY)
				sellListBtn.BackgroundColor3 = Color3.fromRGB(255, 150, 50)
				sellListBtn.Text = "Sell/List\n" .. productType .. " (" .. productValue.Value .. ")"
				sellListBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
				sellListBtn.TextScaled = true
				sellListBtn.Font = Enum.Font.GothamBold
				sellListBtn.Parent = animalFrame

				local sellListCorner = Instance.new("UICorner")
				sellListCorner.CornerRadius = UDim.new(0, 6)
				sellListCorner.Parent = sellListBtn

				sellListBtn.MouseButton1Click:Connect(function()
					gui:Destroy()  -- Close barn
					OpenPoultryBarnEvent:FireClient(player, "PoultryBarn")  -- Pass source
				end)
			end

			yPos = yPos + rowHeight + 10
		end
	end

	-- Empty state
	if #ownedAnimals == 0 then
		local noAnimalsLabel = Instance.new("TextLabel")
		noAnimalsLabel.Size = UDim2.new(0.9, 0, 0, 80)
		noAnimalsLabel.Position = UDim2.new(0.05, 0, 0, 20)
		noAnimalsLabel.BackgroundTransparency = 1
		noAnimalsLabel.Text = "No animals owned! 🐔 Visit the Poultry Shop to buy."
		noAnimalsLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
		noAnimalsLabel.TextScaled = true
		noAnimalsLabel.Font = Enum.Font.Gotham
		noAnimalsLabel.Parent = scrollFrame
	end

	scrollFrame.CanvasSize = UDim2.new(0, 0, 0, yPos + 20)

	gui.Parent = player.PlayerGui
end

-- CORRECT - Only opens animal barn server-side GUI
_G.openPoultryBarn = function(player)
	print(player.Name .. " opened Poultry Barn")

	local function refresh()
		createBarnGUI(player, refresh)
	end

	createBarnGUI(player, refresh)
end

-- Listen for client request to reopen barn
local OpenPoultryBarnServer = ReplicatedStorage:FindFirstChild("OpenPoultryBarnServer")
if not OpenPoultryBarnServer then
	OpenPoultryBarnServer = Instance.new("RemoteEvent")
	OpenPoultryBarnServer.Name = "OpenPoultryBarnServer"
	OpenPoultryBarnServer.Parent = ReplicatedStorage
	print("✅ Created OpenPoultryBarnServer RemoteEvent")
end

OpenPoultryBarnServer.OnServerEvent:Connect(function(player)
	print("🔵 Client requested to reopen PoultryBarn")
	_G.openPoultryBarn(player)
end)
