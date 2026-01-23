-- ServerScriptService/HouseManager
-- Handles house upgrades with cash and Robux options + switching between owned houses

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")

local SoundManager
pcall(function()
	SoundManager = require(ReplicatedStorage:WaitForChild("SoundManager"), 2)
end)

local ProductConfig = require(ReplicatedStorage:WaitForChild("ProductConfig"))

print("House Manager loaded!")

-- ============================================
-- CONFIGURATION
-- ============================================

-- ✅ NEW: Track highest owned level AND current active house separately
local playerHighestHouse = {}  -- Highest house they've purchased
local playerActiveHouse = {}   -- Currently displayed house

-- Helper: get house model from ProductConfig.ModelPath
local function getHouseModel(level)
	local houseData = ProductConfig.GetHouseData(level)
	if not houseData then
		warn("No house data for level", level)
		return nil
	end

	-- Expect ModelPath like "workspace.Houses.House1"
	-- For safety, use the Houses folder directly
	local housesFolder = workspace:WaitForChild("Houses")
	local modelName = "House" .. tostring(level)
	local model = housesFolder:FindFirstChild(modelName)

	if not model then
		warn("House model not found for level", level, "expected", modelName)
	end

	return model
end

-- ============================================
-- HOUSE VISIBILITY TOGGLE
-- ============================================

local function setHouseVisibility(level, isActive)
	local houseModel = getHouseModel(level)
	if not houseModel then return end

	-- Helper function to check if part is inside a walk-through model
	local function isInWalkThroughModel(part)
		local current = part.Parent
		while current and current ~= houseModel do
			local name = current.Name:lower()
			if name:match("door") or name:match("window") or name:match("glass")
				or name:match("frame") or name:match("curtain") then
				return true
			end
			current = current.Parent
		end
		return false
	end

	for _, descendant in ipairs(houseModel:GetDescendants()) do
		if descendant:IsA("BasePart") then
			if isActive then
				-- Restore original transparency
				descendant.Transparency = descendant:GetAttribute("OriginalTransparency") or 0

				-- Check part name AND parent models
				local partName = descendant.Name:lower()
				local isWalkThrough =
					partName:match("door") or
					partName:match("window") or
					partName:match("glass") or
					partName:match("curtain") or
					descendant.Transparency > 0.5 or
					isInWalkThroughModel(descendant)

				descendant.CanCollide = not isWalkThrough
			else
				-- Save original transparency first time
				if not descendant:GetAttribute("OriginalTransparency") then
					descendant:SetAttribute("OriginalTransparency", descendant.Transparency)
				end
				descendant.Transparency = 1
				descendant.CanCollide = false
			end
		elseif descendant:IsA("Decal") or descendant:IsA("Texture") then
			if not descendant:GetAttribute("OriginalTransparency") then
				descendant:SetAttribute("OriginalTransparency", descendant.Transparency)
			end
			descendant.Transparency = isActive and descendant:GetAttribute("OriginalTransparency") or 1
		elseif descendant:IsA("SurfaceGui") then
			descendant.Enabled = isActive
		elseif descendant:IsA("PointLight") or descendant:IsA("SpotLight") or descendant:IsA("SurfaceLight") then
			descendant.Enabled = isActive
		elseif descendant:IsA("ParticleEmitter") or descendant:IsA("Smoke") or descendant:IsA("Fire") then
			descendant.Enabled = isActive
		end
	end

	print(houseModel.Name .. " - Active: " .. tostring(isActive))
end


-- ============================================
-- ✅ NEW: SWITCH TO OWNED HOUSE (NO COST)
-- ============================================

local function switchToHouse(player, level)
	local highestOwned = playerHighestHouse[player.UserId] or 1

	-- Can't switch to a house you don't own
	if level > highestOwned then
		warn(player.Name .. " tried to switch to unowned house level " .. level)
		return false
	end

	-- Already on this house
	if playerActiveHouse[player.UserId] == level then
		print(player.Name .. " is already in House Level " .. level)
		return false
	end

	-- Hide all houses
	for houseLevel = 1, ProductConfig.GetMaxHouseLevel() do
		setHouseVisibility(houseLevel, false)
	end

	-- Show selected house
	setHouseVisibility(level, true)

	playerActiveHouse[player.UserId] = level
	player:SetAttribute("ActiveHouseLevel", level)

	if SoundManager then
		pcall(function()
			SoundManager:PlaySoundForPlayer(player, "PurchaseSound")
		end)
	end

	print(player.Name .. " switched to House Level " .. level)
	return true
end


-- ============================================
-- UPGRADE FUNCTION (PURCHASE NEW HOUSE)
-- ============================================

local function upgradeHouse(player, newLevel, skipCost)
	-- Expose this later as G.UpgradeHouse
	if newLevel < 1 or newLevel > ProductConfig.GetMaxHouseLevel() then
		warn("Invalid house level " .. tostring(newLevel))
		return false
	end

	local highestOwned = playerHighestHouse[player.UserId] or 1

	-- Can't buy a house you already own or skip levels
	if newLevel <= highestOwned then
		print(player.Name .. " already owns House Level " .. newLevel)
		return false
	end

	if newLevel > highestOwned + 1 then
		print(player.Name .. " can't skip to House Level " .. newLevel .. " from " .. highestOwned)
		return false
	end

	local houseData = ProductConfig.GetHouseData(newLevel)
	if not houseData then
		warn("No ProductConfig data for House Level " .. newLevel)
		return false
	end

	local cash = player.leaderstats and player.leaderstats:FindFirstChild("Cash")

	-- Check affordability unless Robux purchase
	if not skipCost then
		if not cash or cash.Value < houseData.Price then
			print(player.Name .. " can't afford House Level " .. newLevel)
			return false
		end
	end

	-- Deduct cost if not free/Robux
	if not skipCost and houseData.Price > 0 then
		cash.Value = cash.Value - houseData.Price
	end

	-- Update ownership
	playerHighestHouse[player.UserId] = newLevel
	player:SetAttribute("HouseLevel", newLevel)

	-- Automatically switch to the new house
	switchToHouse(player, newLevel)

	if SoundManager then
		pcall(function()
			SoundManager:PlaySoundForPlayer(player, "PurchaseSound")
		end)
	end

	print(player.Name .. " purchased House Level " .. newLevel)
	return true
end

-- Make globally accessible for Robux handler
_G.UpgradeHouse = upgradeHouse

-- ============================================
-- GUI CREATION
-- ============================================

local function isMobile()
	return UserInputService.TouchEnabled and not UserInputService.KeyboardEnabled
end

local function createHouseUpgradeGUI(player)
	local existingGui = player.PlayerGui:FindFirstChild("HouseUpgradeGui")
	if existingGui then
		existingGui:Destroy()
	end

	local gui = Instance.new("ScreenGui")
	gui.Name = "HouseUpgradeGui"
	gui.ResetOnSpawn = false
	gui.IgnoreGuiInset = true

	local camera = workspace.CurrentCamera
	local viewportSize = camera.ViewportSize
	local narrow = viewportSize.X < 900
	local mobile = narrow

	local frameWidth = narrow and 0.98 or 0.70
	local frameHeight = narrow and 0.90 or 0.80

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
	title.Text = "House Selection"
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
	local highestOwned = playerHighestHouse[player.UserId] or 1
	local currentActive = playerActiveHouse[player.UserId] or highestOwned

	for level = 1, ProductConfig.GetMaxHouseLevel() do
		local house = ProductConfig.GetHouseData(level)
		if not house then continue end

		local isOwned = level <= highestOwned
		local isActive = level == currentActive
		local isNextUpgrade = level == highestOwned + 1
		local isLocked = level > highestOwned + 1

		-- Card height
		local cardHeight = mobile and 280 or 240

		local houseCard = Instance.new("Frame")
		houseCard.Size = UDim2.new(0.95, 0, 0, cardHeight)
		houseCard.Position = UDim2.new(0.025, 0, 0, yPos)
		houseCard.BackgroundColor3 =
			isActive and Color3.fromRGB(100, 150, 100) or -- Green for active
			isOwned and Color3.fromRGB(70, 100, 130) or   -- Blue for owned
			isNextUpgrade and Color3.fromRGB(100, 100, 70) or -- Yellow-ish
			Color3.fromRGB(60, 60, 60)                   -- Gray for locked
		houseCard.BorderSizePixel = 0
		houseCard.Parent = scrollFrame

		local cardCorner = Instance.new("UICorner")
		cardCorner.CornerRadius = UDim.new(0, 10)
		cardCorner.Parent = houseCard

		-- Thumbnail
		local thumbnail = Instance.new("ImageLabel")
		thumbnail.Size = UDim2.new(0.35, 0, 0.65, 0)
		thumbnail.Position = UDim2.new(0.03, 0, 0.05, 0)
		thumbnail.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
		thumbnail.Image = house.Thumbnail
		thumbnail.ScaleType = Enum.ScaleType.Fit
		thumbnail.Parent = houseCard

		local thumbCorner = Instance.new("UICorner")
		thumbCorner.CornerRadius = UDim.new(0, 8)
		thumbCorner.Parent = thumbnail

		-- Info section
		local infoFrame = Instance.new("Frame")
		infoFrame.Size = UDim2.new(0.57, 0, 1, 0)
		infoFrame.Position = UDim2.new(0.41, 0, 0, 0)
		infoFrame.BackgroundTransparency = 1
		infoFrame.Parent = houseCard

		-- House name
		local nameLabel = Instance.new("TextLabel")
		nameLabel.Size = UDim2.new(1, 0, 0, mobile and 35 or 30)
		nameLabel.Position = UDim2.new(0, 0, 0, 10)
		nameLabel.BackgroundTransparency = 1
		nameLabel.Text = (house.Icon or "") .. " " .. house.Name
		nameLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
		nameLabel.TextScaled = true
		nameLabel.Font = Enum.Font.GothamBold
		nameLabel.TextXAlignment = Enum.TextXAlignment.Left
		nameLabel.Parent = infoFrame

		-- Description
		local descLabel = Instance.new("TextLabel")
		descLabel.Size = UDim2.new(1, 0, 0, mobile and 25 or 22)
		descLabel.Position = UDim2.new(0, 0, 0, mobile and 50 or 45)
		descLabel.BackgroundTransparency = 1
		descLabel.Text = house.Description
		descLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
		descLabel.TextScaled = true
		descLabel.Font = Enum.Font.Gotham
		descLabel.TextXAlignment = Enum.TextXAlignment.Left
		descLabel.Parent = infoFrame

		-- Level indicator
		local levelLabel = Instance.new("TextLabel")
		levelLabel.Size = UDim2.new(1, 0, 0, mobile and 22 or 20)
		levelLabel.Position = UDim2.new(0, 0, 0, mobile and 80 or 72)
		levelLabel.BackgroundTransparency = 1
		levelLabel.Text = "Level " .. level
		levelLabel.TextColor3 = Color3.fromRGB(255, 215, 0)
		levelLabel.TextScaled = true
		levelLabel.Font = Enum.Font.GothamBold
		levelLabel.TextXAlignment = Enum.TextXAlignment.Left
		levelLabel.Parent = infoFrame

		-- Buttons
		local buttonWidth = 0.48
		local buttonHeight = mobile and 40 or 35
		local buttonY = mobile and 115 or 105

		if isActive then
			-- CURRENT HOUSE
			local activeLabel = Instance.new("TextLabel")
			activeLabel.Size = UDim2.new(1, 0, 0, buttonHeight)
			activeLabel.Position = UDim2.new(0, 0, 0, buttonY)
			activeLabel.BackgroundColor3 = Color3.fromRGB(100, 200, 100)
			activeLabel.Text = "ACTIVE"
			activeLabel.TextColor3 = Color3.fromRGB(0, 0, 0)
			activeLabel.TextScaled = true
			activeLabel.Font = Enum.Font.GothamBold
			activeLabel.Parent = infoFrame

			local activeCorner = Instance.new("UICorner")
			activeCorner.CornerRadius = UDim.new(0, 6)
			activeCorner.Parent = activeLabel

		elseif isOwned then
			-- OWNED BUT NOT ACTIVE - SWITCH BUTTON
			local switchBtn = Instance.new("TextButton")
			switchBtn.Size = UDim2.new(1, 0, 0, buttonHeight)
			switchBtn.Position = UDim2.new(0, 0, 0, buttonY)
			switchBtn.BackgroundColor3 = Color3.fromRGB(100, 150, 200)
			switchBtn.Text = "Switch To This House"
			switchBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
			switchBtn.TextScaled = true
			switchBtn.Font = Enum.Font.GothamBold
			switchBtn.Parent = infoFrame

			local switchCorner = Instance.new("UICorner")
			switchCorner.CornerRadius = UDim.new(0, 6)
			switchCorner.Parent = switchBtn

			switchBtn.MouseButton1Click:Connect(function()
				if switchToHouse(player, level) then
					gui:Destroy()
					createHouseUpgradeGUI(player)
				end
			end)

		elseif isNextUpgrade then
			-- NEXT UPGRADE - CASH / ROBUX BUTTONS
			local cashBtn = Instance.new("TextButton")
			cashBtn.Size = UDim2.new(buttonWidth, 0, 0, buttonHeight)
			cashBtn.Position = UDim2.new(0, 0, 0, buttonY)
			cashBtn.BackgroundColor3 = Color3.fromRGB(100, 200, 100)
			cashBtn.Text = "💵 " .. house.Price
			cashBtn.TextColor3 = Color3.fromRGB(0, 0, 0)
			cashBtn.TextScaled = true
			cashBtn.Font = Enum.Font.GothamBold
			cashBtn.Parent = infoFrame

			local cashCorner = Instance.new("UICorner")
			cashCorner.CornerRadius = UDim.new(0, 6)
			cashCorner.Parent = cashBtn

			cashBtn.MouseButton1Click:Connect(function()
				if upgradeHouse(player, level, false) then
					gui:Destroy()
					createHouseUpgradeGUI(player)
				end
			end)

			-- Optional: Robux button wired via Products if you still use that
			-- (keep your existing Robux integration here)
		else
			-- LOCKED
			local lockedLabel = Instance.new("TextLabel")
			lockedLabel.Size = UDim2.new(1, 0, 0, buttonHeight)
			lockedLabel.Position = UDim2.new(0, 0, 0, buttonY)
			lockedLabel.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
			lockedLabel.Text = "Locked"
			lockedLabel.TextColor3 = Color3.fromRGB(150, 150, 150)
			lockedLabel.TextScaled = true
			lockedLabel.Font = Enum.Font.Gotham
			lockedLabel.Parent = infoFrame

			local lockedCorner = Instance.new("UICorner")
			lockedCorner.CornerRadius = UDim.new(0, 6)
			lockedCorner.Parent = lockedLabel
		end

		yPos = yPos + cardHeight + 12
	end

	scrollFrame.CanvasSize = UDim2.new(0, 0, 0, yPos + 10)
	gui.Parent = player.PlayerGui
end



-- ============================================
-- PLAYER MANAGEMENT
-- ============================================

local function setupPlayerHouse(player)
	-- Load highest owned level
	local savedLevel = player:GetAttribute("HouseLevel") or 1
	playerHighestHouse[player.UserId] = savedLevel

	-- Load active house, defaults to highest
	local activeLevel = player:GetAttribute("ActiveHouseLevel") or savedLevel
	playerActiveHouse[player.UserId] = activeLevel

	-- Show active house
	for level = 1, ProductConfig.GetMaxHouseLevel() do
		setHouseVisibility(level, level == activeLevel)
	end

	print(player.Name .. " owns up to Level " .. savedLevel .. ", active Level " .. activeLevel)
end

Players.PlayerAdded:Connect(function(player)
	-- WAIT FOR DATASTORE TO SET THE ATTRIBUTE
	local attempts = 0
	local maxAttempts = 100 -- 10 seconds max
	while not player:GetAttribute("HouseLevel") and attempts < maxAttempts do
		task.wait(0.1)
		attempts += 1
	end

	local savedLevel = player:GetAttribute("HouseLevel") or 1
	local activeLevel = player:GetAttribute("ActiveHouseLevel") or savedLevel

	print("HouseManager read - HouseLevel:", tostring(player:GetAttribute("HouseLevel")))
	print("HouseManager read - ActiveHouseLevel:", tostring(player:GetAttribute("ActiveHouseLevel")))
	print("HouseManager set - savedLevel:", savedLevel)
	print("HouseManager set - activeLevel:", activeLevel)

	playerHighestHouse[player.UserId] = savedLevel
	playerActiveHouse[player.UserId] = activeLevel

	for level = 1, ProductConfig.GetMaxHouseLevel() do
		setHouseVisibility(level, level == activeLevel)
	end

	print(player.Name .. " owns up to Level " .. savedLevel .. ", active Level " .. activeLevel)
end)

-- ============================================
-- PROXIMITY PROMPT
-- ============================================

local prompt = workspace.Houses:WaitForChild("PostalBox"):WaitForChild("Model"):WaitForChild("ProximityPrompt")

prompt.Triggered:Connect(function(player)
	print(player.Name .. " opened house selection")

	-- Tutorial: Complete level 7 (Visit Houses)
	if _G.CompleteTutorialLevel then
		local currentLevel = player:FindFirstChild("CurrentArrowLevel")
		if currentLevel and currentLevel.Value == 7 then
			print("🎯 Completing tutorial level 7 - Visited houses")
			_G.CompleteTutorialLevel(player, 7)
		end
	end

	createHouseUpgradeGUI(player)
end)


print("✅ House Manager ready!")
