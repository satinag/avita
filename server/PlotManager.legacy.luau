-- ServerScriptService/PlotManager
-- Handles all 16 plots across all zones with unified logic

local SoundManager
pcall(function() SoundManager = require(game:GetService("ReplicatedStorage"):WaitForChild("SoundManager", 2)) end)

local DailyQuestManager = require(game:GetService("ServerScriptService"):WaitForChild("DailyQuestManager"))
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

print("🌾 Plot Manager loaded!")

-- ============================================
-- CONSTANTS
-- ============================================

local PLOT_COSTS = {
	Plot1 = 0, Plot2 = 50, Plot3 = 50, Plot4 = 50,
	Plot5 = 0, Plot6 = 50, Plot7 = 50, Plot8 = 50,
	Plot9 = 0, Plot10 = 50, Plot11 = 50, Plot12 = 50,
	Plot13 = 0, Plot14 = 50, Plot15 = 50, Plot16 = 50
}

local SEEDS = {
	Wheat = {Cost = 0, GrowTime = 10, Model = "WheatModel", MatureModel = "WheatMature"},
	Corn = {Cost = 0, GrowTime = 20, Model = "CornModel", MatureModel = "CornMature"},
	Carrot = {Cost = 0, GrowTime = 15, Model = "CarrotModel", MatureModel = "CarrotMature"},
	Potato = {Cost = 0, GrowTime = 30, Model = "PotatoModel", MatureModel = "PotatoMature"},
	Tomato = {Cost = 0, GrowTime = 25, Model = "TomatoModel", MatureModel = "TomatoMature"},
	Pumpkin = {Cost = 0, GrowTime = 40, Model = "PumpkinModel", MatureModel = "PumpkinMature"},
	Strawberry = {Cost = 0, GrowTime = 50, Model = "StrawberryModel", MatureModel = "StrawberryMature"},
	Watermelon = {Cost = 0, GrowTime = 60, Model = "WatermelonModel", MatureModel = "WatermelonMature"}
}

-- ============================================
-- HELPERS
-- ============================================

local function isZoneLocked(prompt, plot)
	local zoneLocked = prompt:GetAttribute("ZoneLocked")
	if zoneLocked == nil then
		-- Initialize:  Plots 5+ start locked
		local plotNum = tonumber(plot.Name: match("%d+"))
		if plotNum and plotNum >= 5 then
			prompt:SetAttribute("ZoneLocked", true)
			return true
		end
	end
	return zoneLocked == true
end

_G.setupPlotPrompt = function(prompt)
	local plot = prompt.  Parent
	local plotCost = PLOT_COSTS[plot. Name] or 50

	-- Function to update prompt based on lock status
	local function updatePromptText()
		if isZoneLocked(prompt, plot) then
			prompt.ActionText = "🔒 Earn money to unlock this zone"
		else
			if plotCost == 0 then
				prompt.ActionText = "Claim Free Plot"
			else
				prompt.ActionText = "Purchase Plot (" .. plotCost .. " Cash)"
			end
		end
	end

	-- Set initial lock status
	updatePromptText()

	-- ✅ LISTEN FOR ATTRIBUTE CHANGES (zone unlock)
	prompt:GetAttributeChangedSignal("ZoneLocked"):Connect(function()
		updatePromptText()
	end)

	prompt.Triggered:Connect(function(player)
		handlePlotInteraction(player, prompt, plot)
	end)
end

local function hasTool(player, toolName)
	local toolsOwned = player:FindFirstChild("ToolsOwned")
	if not toolsOwned then return false end
	local tool = toolsOwned:FindFirstChild(toolName)
	return tool and tool.Value
end

local function getGrowthMultiplier(player)
	if hasTool(player, "UpgradedWateringCan") then  -- ✅ No space
		return 0.7
	elseif hasTool(player, "WateringCan") then  -- ✅ No space (was "Watering Can")
		return 0.8
	end
	return 1.0
end

local function getHarvestMultiplier(player)
	if hasTool(player, "UpgradedShovel") then  -- ✅ Already correct
		return 3
	elseif hasTool(player, "ImprovedShovel") then  -- ✅ No space (was "Improved Shovel")
		return 2
	end
	return 1
end


local function getAvailableSeeds(player)
	local seedInventory = player:FindFirstChild("SeedInventory")
	if not seedInventory then return {} end

	local available = {}
	for seedName, seedData in pairs(SEEDS) do
		local seedValue = seedInventory:FindFirstChild(seedName)
		if seedValue and seedValue.Value > 0 then
			table. insert(available, seedName)
		end
	end
	return available
end

-- ============================================
-- ANIMATION
-- ============================================

local function animateCrop(crop, startScale, duration, easingStyle)
	if crop:IsA("Model") then
		for _, part in pairs(crop:GetDescendants()) do
			if part:IsA("BasePart") then
				local originalSize = part.Size
				part.Size = originalSize * startScale
				local tween = TweenService:Create(part, TweenInfo.new(duration, easingStyle, Enum.EasingDirection.Out), {Size = originalSize})
				tween:Play()
			end
		end
	else
		local originalSize = crop.Size
		crop.Size = originalSize * startScale
		local tween = TweenService:Create(crop, TweenInfo.new(duration, easingStyle, Enum.EasingDirection.Out), {Size = originalSize})
		tween:Play()
	end
end

-- ============================================
-- SEED SELECTION GUI
-- ============================================

local function askSeedChoice(player)
	local available = getAvailableSeeds(player)

	if #available == 0 then
		return nil, "No seeds available!  Buy seeds at the shop or convert crops at the Barn"
	elseif #available == 1 then
		return available[1], nil
	else
		local gui = Instance.new("ScreenGui")
		gui.Name = "SeedChoiceGui"
		gui.ResetOnSpawn = false

		local frame = Instance.new("Frame")
		frame.Size = UDim2.new(0, 300, 0, 60 * #available + 100)
		frame.Position = UDim2.new(0.5, -150, 0.5, -((60 * #available + 100) / 2))
		frame.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
		frame.BorderSizePixel = 3
		frame.Parent = gui

		local title = Instance.new("TextLabel")
		title.Size = UDim2.new(1, 0, 0, 40)
		title.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
		title.Text = "Choose Seed to Plant"
		title.TextColor3 = Color3.fromRGB(255, 255, 255)
		title.TextScaled = true
		title.Font = Enum.Font.GothamBold
		title. Parent = frame

		local choice = nil

		for i, seedName in ipairs(available) do
			local button = Instance.new("TextButton")
			button.Size = UDim2.new(0.9, 0, 0, 50)
			button.Position = UDim2.new(0.05, 0, 0, 45 + (i-1) * 55)
			button.BackgroundColor3 = Color3.fromRGB(100, 200, 100)
			local seedCount = player.  SeedInventory[seedName].  Value
			button.Text = seedName .. " (Owned: " .. seedCount .. ")"
			button.TextColor3 = Color3.fromRGB(0, 0, 0)
			button.TextScaled = true
			button.Font = Enum.Font. Gotham
			button.Parent = frame

			button.MouseButton1Click:Connect(function()
				choice = seedName
				gui:Destroy()
			end)
		end

		local yPos = 45 + (#available * 55) + 5
		local cancelBtn = Instance.new("TextButton")
		cancelBtn.Size = UDim2.new(0.9, 0, 0, 40)
		cancelBtn.Position = UDim2.new(0.05, 0, 0, yPos)
		cancelBtn.BackgroundColor3 = Color3.fromRGB(200, 100, 100)
		cancelBtn.Text = "Cancel"
		cancelBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
		cancelBtn.TextScaled = true
		cancelBtn.Font = Enum.Font.Gotham
		cancelBtn.Parent = frame

		cancelBtn.MouseButton1Click:Connect(function()
			gui:Destroy()
		end)

		gui.Parent = player.PlayerGui

		local timeout = 30
		local elapsed = 0
		while not choice and elapsed < timeout and gui.Parent do
			task.wait(0.1)
			elapsed = elapsed + 0.1
		end

		if gui.Parent then gui:Destroy() end
		return choice, choice and nil or "No seed selected"
	end
end

-- ============================================
-- BUSINESS LOGIC
-- ============================================

local function handlePlotInteraction(player, prompt, plot)
	-- Check if zone is locked
	if isZoneLocked(prompt, plot) then
		print(player.Name .. " tried to use locked plot:  " .. plot.Name)
		return
	end

	local owner = plot:GetAttribute("Owner")
	local isGrowing = plot:GetAttribute("IsGrowing")
	local canHarvest = plot:GetAttribute("CanHarvest")
	local plotCost = PLOT_COSTS[plot.Name] or 50
	local plotPart = plot:IsA("Model") and (plot.PrimaryPart or plot:FindFirstChildWhichIsA("BasePart")) or plot

	if not owner then
		-- ============================================
		-- PURCHASE/CLAIM PLOT
		-- ============================================

		local leaderstats = player:FindFirstChild("leaderstats")
		local cash = leaderstats and leaderstats:FindFirstChild("Cash")

		if plotCost == 0 then
			plot:SetAttribute("Owner", player.Name)

			local ownedPlots = player:FindFirstChild("OwnedPlots")
			if ownedPlots then
				local plotValue = ownedPlots:FindFirstChild(plot.Name)
				if plotValue then
					plotValue.Value = player.Name
				end
			end

			prompt.ActionText = "Select Seed to Plant"
			print(player.Name .. " claimed " .. plot.Name .. " (free)")

			-- Tutorial: Complete zone unlock levels (free plots)
			if _G.CompleteTutorialLevel then
				local currentLevel = player:FindFirstChild("CurrentArrowLevel")
				print("🔍 DEBUG: Plot claimed - " .. plot.Name .. " | CurrentLevel: " .. (currentLevel and currentLevel.Value or "nil"))
				if currentLevel then
					if plot.Name == "Plot5" and currentLevel.Value == 8 then
						print("🎯 Completing tutorial level 8 - Claimed Zone1 plot")
						_G.CompleteTutorialLevel(player, 8)
					elseif plot.Name == "Plot9" and currentLevel.Value == 9 then
						print("🎯 Completing tutorial level 9 - Claimed Zone2 plot")
						_G.CompleteTutorialLevel(player, 9)
					elseif plot.Name == "Plot13" and currentLevel.Value == 10 then
						print("🎯 Completing tutorial level 10 - Claimed Zone3 plot")
						_G.CompleteTutorialLevel(player, 10)
					end
				end
			else
				print("⚠️ _G.CompleteTutorialLevel not found!")
			end


			if SoundManager and plotPart then 
				pcall(function() SoundManager:PlaySoundAtLocation("PurchaseSound", plotPart.Position) end) 
			end

		elseif cash and cash.Value >= plotCost then
			cash.Value = cash.Value - plotCost

			-- Track spending stats
			_G.TrackStat(player, "TotalCashSpent", plotCost)
			_G.TrackStat(player, "MoneySpentOnPlots", plotCost)

			plot:SetAttribute("Owner", player.Name)

			-- Track stat
			_G.TrackStat(player, "PlotsOwned", 1)

			local ownedPlots = player:FindFirstChild("OwnedPlots")
			if ownedPlots then
				local plotValue = ownedPlots:FindFirstChild(plot.Name)
				if plotValue then
					plotValue.Value = player.Name
				end
			end

			prompt.ActionText = "Select Seed to Plant"
			print(player.Name .. " purchased " .. plot.Name .. " for " .. plotCost .. " cash")

			-- Tutorial: Complete zone unlock levels (paid plots)
			if _G.CompleteTutorialLevel then
				local currentLevel = player:FindFirstChild("CurrentArrowLevel")
				if currentLevel then
					if plot.Name == "Plot5" and currentLevel.Value == 8 then
						print("🎯 Completing tutorial level 8 - Claimed Zone1 plot")
						_G.CompleteTutorialLevel(player, 8)
					elseif plot.Name == "Plot9" and currentLevel.Value == 9 then
						print("🎯 Completing tutorial level 9 - Claimed Zone2 plot")
						_G.CompleteTutorialLevel(player, 9)
					elseif plot.Name == "Plot13" and currentLevel.Value == 10 then
						print("🎯 Completing tutorial level 10 - Claimed Zone3 plot")
						_G.CompleteTutorialLevel(player, 10)
					end
				end
			end

			if SoundManager and plotPart then 
				pcall(function() SoundManager:PlaySoundAtLocation("PurchaseSound", plotPart.Position) end) 
			end
		else
			print(player.Name .. " needs " .. plotCost .. " cash to purchase " .. plot.Name)
		end


	elseif owner == player.Name and canHarvest then
		-- ============================================
		-- HARVEST
		-- ============================================

		plot:SetAttribute("CanHarvest", false)
		plot:SetAttribute("IsGrowing", false)

		local seedType = plot:GetAttribute("CurrentSeed") or "Wheat"
		prompt.ActionText = "Harvesting..."
		task.wait(0.5)

		local cropInventory = player:FindFirstChild("CropInventory")
		local cropCount = cropInventory and cropInventory:FindFirstChild(seedType)
		local harvestAmount = getHarvestMultiplier(player)

		print("⛏️ Harvest multiplier: " .. harvestAmount ..  "x")

		if cropCount then
			cropCount.Value = cropCount.Value + harvestAmount
			
			-- Track harvest stats
			_G.TrackCropHarvest(player, seedType, harvestAmount)

			print(player.Name .. " harvested " .. harvestAmount .. " " .. seedType .. " crop(s)!  (Total: " .. cropCount.Value ..  ")")

			if DailyQuestManager then
				DailyQuestManager:UpdateProgress(player, "Harvest", {
					CropType = seedType,
					Amount = harvestAmount
				})
				
				-- Also track for mixed quests
				DailyQuestManager:UpdateMixedQuest(player, "Harvest", harvestAmount)
				
			end

			-- Tutorial: Complete level 4 (First Harvest)
			if _G.CompleteTutorialLevel and plot.Name == "Plot1" then
				local currentLevel = player:FindFirstChild("CurrentArrowLevel")
				if currentLevel and currentLevel.Value == 4 then
					print("🎯 Completing tutorial level 4 - First harvest")
					_G.CompleteTutorialLevel(player, 4)
				end
			end

			if SoundManager and plotPart then 
				pcall(function() SoundManager:PlaySoundAtLocation("HarvestSound", plotPart.Position) end) 
			end
		end

		local crop = plot:FindFirstChild("Crop")
		if crop then crop: Destroy() end

		plot:SetAttribute("CurrentSeed", nil)
		plot:SetAttribute("PlantTime", nil)

		local ownedPlots = player:FindFirstChild("OwnedPlots")
		if ownedPlots then
			local seedValue = ownedPlots: FindFirstChild(plot.Name ..  "_Seed")
			if seedValue then
				seedValue.Value = ""
			end

			local plantTimeValue = ownedPlots: FindFirstChild(plot.Name ..  "_PlantTime")
			if plantTimeValue then
				plantTimeValue.Value = 0
			end
		end

		prompt.ActionText = "Select Seed to Plant"

	elseif owner == player.Name and not isGrowing then
		-- ============================================
		-- PLANT
		-- ============================================

		plot:SetAttribute("IsGrowing", true)

		local selectedSeed, error = askSeedChoice(player)

		if not selectedSeed then
			print(player.Name .. " - " .. (error or "No seed selected"))
			plot:SetAttribute("IsGrowing", false)
			return
		end

		local seedData = SEEDS[selectedSeed]
		local inventory = player:FindFirstChild("SeedInventory")
		local seedCount = inventory and inventory:FindFirstChild(selectedSeed)

		if not seedCount or seedCount.Value <= 0 then
			print(player.Name .. " has no " .. selectedSeed .. " seeds!")
			plot:SetAttribute("IsGrowing", false)
			return
		end

		seedCount.Value = seedCount.Value - 1
		plot:SetAttribute("CurrentSeed", selectedSeed)

		local plantTime = os.time()
		plot:SetAttribute("PlantTime", plantTime)

		local ownedPlots = player: FindFirstChild("OwnedPlots")
		if ownedPlots then
			local seedValue = ownedPlots:FindFirstChild(plot.Name .. "_Seed")
			if seedValue then
				seedValue.Value = selectedSeed
			end

			local plantTimeValue = ownedPlots:FindFirstChild(plot. Name .. "_PlantTime")
			if plantTimeValue then
				plantTimeValue.Value = plantTime
			end
		end

		prompt.ActionText = "Planting..."
		print(player.Name .. " planted " ..  selectedSeed .. " (" .. seedCount.Value .. " seeds remaining)")

		if SoundManager and plotPart then 
			pcall(function() SoundManager:PlaySoundAtLocation("PlantSound", plotPart.Position) end) 
		end

		if DailyQuestManager then
			DailyQuestManager: UpdateProgress(player, "Plant", {
				SeedType = selectedSeed,
				Amount = 1
			})
			
			-- Also track for mixed quests
			DailyQuestManager:UpdateMixedQuest(player, "Plant", 1)
		end

		-- Tutorial: Complete level 3 (Plant First Seed)
		if _G.CompleteTutorialLevel then
			local currentLevel = player:FindFirstChild("CurrentArrowLevel")
			if currentLevel and currentLevel.Value == 3 then
				print("🎯 Completing tutorial level 3 - Planted first seed")
				_G.CompleteTutorialLevel(player, 3)
			end
		end

		-- Spawn young crop
		local cropModel = ReplicatedStorage:FindFirstChild(seedData.Model)
		if cropModel then
			local crop = cropModel:Clone()
			crop.Name = "Crop"
			crop.Parent = plot

			local landPart = plot:FindFirstChild("Land") or plotPart
			local exactGroundY = landPart.Position.Y + (landPart.Size.Y / 2)

			if crop: IsA("Model") then
				local targetPos = Vector3.new(landPart.Position.X, exactGroundY + 2, landPart.Position.Z)
				if not crop. PrimaryPart then
					crop. PrimaryPart = crop:FindFirstChildWhichIsA("BasePart")
				end
				if crop.PrimaryPart then
					crop: SetPrimaryPartCFrame(CFrame.new(targetPos) * CFrame.Angles(0, 0, 0))
				else
					crop: MoveTo(targetPos)
				end
				for _, part in pairs(crop:GetDescendants()) do
					if part:IsA("BasePart") then
						part.Anchored = true
						part.CanCollide = false
					end
				end
			else
				local targetY = exactGroundY + (crop.Size.Y / 2)
				crop.CFrame = CFrame.new(landPart.Position.X, targetY, landPart.Position. Z)
				crop. Anchored = true
				crop. CanCollide = false
			end

			animateCrop(crop, 0.2, 1.5, Enum.EasingStyle.Bounce)
		end

		-- Growth with tool multipliers AND day/night bonus
		local growTime = seedData.GrowTime * getGrowthMultiplier(player)

		-- ✅ APPLY DAY/NIGHT MULTIPLIER
		if _G.getGrowthMultiplier then
			local multiplier = _G.getGrowthMultiplier(player)
			growTime = growTime / multiplier  -- ✅ DIVIDE not multiply
			print("🌙 Growth multiplier:  " ..  multiplier .. "x - adjusted grow time:  " .. math.floor(growTime) .. "s")
		end

		local toolIcon = ""
		if hasTool(player, "UpgradedWateringCan") then
			toolIcon = " 💧⭐"
			print("💧⭐ Upgraded Watering Can active!  Growth time:  " .. math.floor(growTime) .. "s")
		elseif hasTool(player, "WateringCan") then
			toolIcon = " 💧"
			print("💧 Watering Can active! Growth time:  " .. math.floor(growTime) .. "s")
		end

		prompt. ActionText = "Growing..." .. toolIcon .. " (" .. math.floor(growTime) .. "s)"
		task.wait(growTime)

		local growingCrop = plot:FindFirstChild("Crop")
		if growingCrop then growingCrop: Destroy() end

		-- Spawn mature crop
		local matureModel = ReplicatedStorage: FindFirstChild(seedData.MatureModel)
		if matureModel then
			local matureCrop = matureModel:Clone()
			matureCrop.Name = "Crop"
			matureCrop.Parent = plot

			local landPart = plot:FindFirstChild("Land") or plotPart
			local exactGroundY = landPart.Position.Y + (landPart. Size.Y / 2)

			if matureCrop:IsA("Model") then
				for _, part in pairs(matureCrop:GetDescendants()) do
					if part:IsA("BasePart") then
						part.Anchored = true
						part.CanCollide = false
						part.CanTouch = false
						part.CanQuery = false
					end
				end

				if not matureCrop.PrimaryPart then
					matureCrop.PrimaryPart = matureCrop:FindFirstChildWhichIsA("BasePart")
				end

				local targetPos = Vector3.new(landPart.Position.X, exactGroundY + 0.5, landPart.Position.Z)

				if matureCrop.PrimaryPart then
					matureCrop:SetPrimaryPartCFrame(CFrame.new(targetPos) * CFrame.Angles(0, 0, 0))
				else
					matureCrop:MoveTo(targetPos)
				end
			else
				matureCrop. Anchored = true
				matureCrop.CanCollide = false
				matureCrop. CanTouch = false
				matureCrop.CanQuery = false

				local targetY = exactGroundY + 0.5
				matureCrop.CFrame = CFrame.new(landPart.Position.X, targetY, landPart.Position.Z)
			end

			animateCrop(matureCrop, 0.3, 1.2, Enum.EasingStyle.Elastic)
		end

		plot:SetAttribute("IsGrowing", false)
		plot:SetAttribute("CanHarvest", true)
		prompt.ActionText = "Harvest " .. selectedSeed
		print("🌾 " .. selectedSeed .. " is ready to harvest on " .. plot.Name)
	end
end

-- ============================================
-- SETUP:  Hook all plot prompts
-- ============================================

_G.setupPlotPrompt = function(prompt)
	local plot = prompt.Parent
	local plotCost = PLOT_COSTS[plot.Name] or 50

	-- Function to set initial/default text based on plot state
	local function setDefaultText()
		local owner = plot:GetAttribute("Owner")

		-- If plot has an owner, show interaction text based on state
		if owner then
			local canHarvest = plot:GetAttribute("CanHarvest")
			local isGrowing = plot:GetAttribute("IsGrowing")
			local seedType = plot:GetAttribute("CurrentSeed") or "Wheat"

			if canHarvest then
				prompt.ActionText = "Harvest " .. seedType
			elseif isGrowing then
				prompt.ActionText = "Growing..."
			else
				prompt.ActionText = "Select Seed to Plant"
			end
		else
			-- Plot is unclaimed - show purchase/claim text
			if isZoneLocked(prompt, plot) then
				prompt.ActionText = "🔒 Earn money to unlock this zone"
			elseif plotCost == 0 then
				prompt. ActionText = "Claim Free Plot"
			else
				prompt.ActionText = "Purchase Plot (" .. plotCost .. " Cash)"
			end
		end
	end

	-- Set initial text
	setDefaultText()

	-- Listen for attribute changes
	prompt: GetAttributeChangedSignal("ZoneLocked"):Connect(function()
		setDefaultText()
	end)

	prompt:GetAttributeChangedSignal("Owner"):Connect(function()
		setDefaultText()
		print("📍 Plot " .. plot.Name ..  " ownership changed")
	end)

	prompt:GetAttributeChangedSignal("CanHarvest"):Connect(function()
		setDefaultText()
	end)

	prompt:GetAttributeChangedSignal("IsGrowing"):Connect(function()
		setDefaultText()
	end)

	prompt:GetAttributeChangedSignal("CurrentSeed"):Connect(function()
		setDefaultText()
	end)

	prompt. Triggered:Connect(function(player)
		handlePlotInteraction(player, prompt, plot)
	end)
end

print("✅ PlotManager ready - call _G.setupPlotPrompt(prompt) for each plot")