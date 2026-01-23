-- StarterGui/FarmJournalGUI/LocalScript
-- Farm Statistics Dashboard with tabbed interface
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local player = Players.LocalPlayer

local FarmStatsConfig = require(ReplicatedStorage:WaitForChild("FarmStatsConfig"))
local getFarmStatsFunction = ReplicatedStorage:WaitForChild("GetFarmStatsFunction")
local achievementUnlockedEvent = ReplicatedStorage:WaitForChild("AchievementUnlockedEvent")

-- Create BindableEvent for opening (client-to-client communication)
local openJournalEvent = ReplicatedStorage:FindFirstChild("OpenJournalEvent")

-- If it exists and is a RemoteEvent, destroy it and create BindableEvent
if openJournalEvent and openJournalEvent:IsA("RemoteEvent") then
	openJournalEvent:Destroy()
	openJournalEvent = nil
end

-- Create BindableEvent if it doesn't exist
if not openJournalEvent then
	openJournalEvent = Instance.new("BindableEvent")
	openJournalEvent.Name = "OpenJournalEvent"
	openJournalEvent.Parent = ReplicatedStorage
end

print("📖 Farm Journal GUI loaded!")


-- ============================================
-- CREATE UI STRUCTURE
-- ============================================

-- Get the ScreenGui properly
local screenGui = script.Parent
screenGui.ResetOnSpawn = false
screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling

-- INDEPENDENT device detection - don't rely on anything external
local UserInputService = game:GetService("UserInputService")
local viewportSize = workspace.CurrentCamera.ViewportSize

-- Detect mobile AND small screens
local isTouchDevice = UserInputService.TouchEnabled and not UserInputService.KeyboardEnabled
local isSmallScreen = viewportSize.X < 400 or viewportSize.Y < 700
local isMobile = isTouchDevice or isSmallScreen

print("📱 Journal Device Info: ViewportSize=" .. tostring(viewportSize) .. " | isMobile=" .. tostring(isMobile))


-- Background overlay (dims everything behind)
local journalOverlay = Instance.new("Frame")
journalOverlay.Name = "JournalOverlay"
journalOverlay.Size = UDim2.new(1, 0, 1, 0)
journalOverlay.Position = UDim2.new(0, 0, 0, 0)
journalOverlay.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
journalOverlay.BackgroundTransparency = 0.5
journalOverlay.BorderSizePixel = 0
journalOverlay.Visible = false
journalOverlay.ZIndex = 4
journalOverlay.Parent = screenGui

-- Main container (centered popup EXACTLY like leaderboard)
local mainFrame = Instance.new("Frame")
mainFrame.Name = "MainFrame"
mainFrame.Size = UDim2.new(isMobile and 0.88 or 0.6, 0, isMobile and 0.85 or 0.8, 0)
mainFrame.Position = UDim2.new(0.5, 0, 0.5, 0)
mainFrame.AnchorPoint = Vector2.new(0.5, 0.5)
mainFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
mainFrame.BackgroundTransparency = 0.15
mainFrame.BorderSizePixel = 0
mainFrame.Visible = false
mainFrame.ZIndex = 5
mainFrame.Parent = screenGui

local mainCorner = Instance.new("UICorner")
mainCorner.CornerRadius = UDim.new(0, 12)
mainCorner.Parent = mainFrame

local mainStroke = Instance.new("UIStroke")
mainStroke.Color = Color3.fromRGB(100, 100, 100)
mainStroke.Thickness = 2
mainStroke.Transparency = 0.3
mainStroke.Parent = mainFrame

-- Title (EXACTLY like leaderboard)
local titleLabel = Instance.new("TextLabel")
titleLabel.Size = UDim2.new(1, -60, 0, 40)
titleLabel.Position = UDim2.new(0, 5, 0, 5)
titleLabel.BackgroundTransparency = 1
titleLabel.Text = "📖 Farm Journal"
titleLabel.TextColor3 = Color3.fromRGB(100, 200, 100)  -- Green like stats theme
titleLabel.TextScaled = true
titleLabel.Font = Enum.Font.GothamBold
titleLabel.ZIndex = 6
titleLabel.Parent = mainFrame

-- Close button
local closeButton = Instance.new("TextButton")
closeButton.Size = UDim2.new(0, 35, 0, 35)  -- Same as leaderboard
closeButton.Position = UDim2.new(1, -40, 0, 5)  -- Same as leaderboard
closeButton.BackgroundColor3 = Color3.fromRGB(200, 100, 100)
closeButton.Text = "X"
closeButton.TextColor3 = Color3.fromRGB(255, 255, 255)
closeButton.TextScaled = true
closeButton.Font = Enum.Font.GothamBold
closeButton.ZIndex = 7
closeButton.Parent = mainFrame

local closeCorner = Instance.new("UICorner")
closeCorner.CornerRadius = UDim.new(1, 0)
closeCorner.Parent = closeButton

-- Tab container
local tabContainer = Instance.new("Frame")
tabContainer.Name = "TabContainer"
tabContainer.Size = UDim2.new(1, -10, 0, 50)
tabContainer.Position = UDim2.new(0, 5, 0, 45)
tabContainer.BackgroundTransparency = 1
tabContainer.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
tabContainer.BorderSizePixel = 0
tabContainer.Parent = mainFrame

local tabLayout = Instance.new("UIListLayout")
tabLayout.FillDirection = Enum.FillDirection.Horizontal
tabLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
tabLayout.Padding = UDim.new(0, 5)
tabLayout.Parent = tabContainer

-- Content container (EXACTLY like leaderboard scroll)
local contentFrame = Instance.new("ScrollingFrame")
contentFrame.Name = "ContentFrame"
contentFrame.Size = UDim2.new(1, -10, 1, -115)
contentFrame.Position = UDim2.new(0, 5, 0, 110)
contentFrame.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
contentFrame.BorderSizePixel = 0
contentFrame.ScrollBarThickness = 8
contentFrame.CanvasSize = UDim2.new(0, 0, 0, 0)
contentFrame.AutomaticCanvasSize = Enum.AutomaticSize.Y
contentFrame.ZIndex = 6
contentFrame.Parent = mainFrame

local contentCorner = Instance.new("UICorner")
contentCorner.CornerRadius = UDim.new(0, 8)
contentCorner.Parent = contentFrame

local contentLayout = Instance.new("UIListLayout")
contentLayout.Padding = UDim.new(0, 10)
contentLayout.SortOrder = Enum.SortOrder.LayoutOrder
contentLayout.Parent = contentFrame

local contentPadding = Instance.new("UIPadding")
contentPadding.PaddingTop = UDim.new(0, 10)
contentPadding.PaddingBottom = UDim.new(0, 10)
contentPadding.PaddingLeft = UDim.new(0, 10)
contentPadding.PaddingRight = UDim.new(0, 10)
contentPadding.Parent = contentFrame

-- ============================================
-- TAB CREATION
-- ============================================

local tabs = {}
local activeTab = nil

local function createTab(name, emoji)
	local tab = Instance.new("TextButton")
	tab.Name = name .. "Tab"

	-- Calculate tab size based on viewport (5 tabs total)
	local viewportSize = workspace.CurrentCamera.ViewportSize
	local isSmallScreen = viewportSize.X < 400

	-- On small screens, use percentage width; on large screens use fixed
	if isSmallScreen then
		tab.Size = UDim2.new(0.18, -2, 0, 35)  -- 18% width, 35px height
		tab.TextSize = 10  -- Smaller text
	else
		tab.Size = UDim2.new(0, 110, 0, 40)  -- 110px width, 40px height
		tab.TextSize = 14  -- Normal text
	end

	tab.BackgroundColor3 = Color3.fromRGB(70, 70, 70)
	tab.Text = emoji .. " " .. name
	tab.TextColor3 = Color3.fromRGB(200, 200, 200)
	tab.Font = Enum.Font.Gotham
	tab.Parent = tabContainer

	local tabCorner = Instance.new("UICorner")
	tabCorner.CornerRadius = UDim.new(0, 8)
	tabCorner.Parent = tab

	tabs[name] = tab
	return tab
end


-- Create all tabs
createTab("Overview", "📊")
createTab("Crops", "🌾")
createTab("Animals", "🐔")
createTab("Economy", "💰")
createTab("Achievements", "🏆")

-- ============================================
-- STAT DISPLAY HELPERS
-- ============================================

local function createStatRow(labelText, valueText)
	local row = Instance.new("Frame")
	row.Size = UDim2.new(1, 0, 0, 35)
	row.BackgroundColor3 = Color3.fromRGB(45, 45, 45)
	row.BorderSizePixel = 0
	row.Parent = contentFrame

	local rowCorner = Instance.new("UICorner")
	rowCorner.CornerRadius = UDim.new(0, 6)
	rowCorner.Parent = row

	local label = Instance.new("TextLabel")
	label.Size = UDim2.new(0.6, -10, 1, 0)
	label.Position = UDim2.new(0, 10, 0, 0)
	label.BackgroundTransparency = 1
	label.Text = labelText
	label.TextColor3 = Color3.fromRGB(200, 200, 200)
	label.Font = Enum.Font.Gotham
	label.TextSize = 14
	label.TextXAlignment = Enum.TextXAlignment.Left
	label.Parent = row

	local value = Instance.new("TextLabel")
	value.Size = UDim2.new(0.4, -10, 1, 0)
	value.Position = UDim2.new(0.6, 0, 0, 0)
	value.BackgroundTransparency = 1
	value.Text = valueText
	value.TextColor3 = Color3.fromRGB(100, 200, 100)
	value.Font = Enum.Font.GothamBold
	value.TextSize = 16
	value.TextXAlignment = Enum.TextXAlignment.Right
	value.Parent = row

	return row
end

local function createSectionHeader(text)
	local header = Instance.new("TextLabel")
	header.Size = UDim2.new(1, 0, 0, 30)
	header.BackgroundTransparency = 1
	header.Text = text
	header.TextColor3 = Color3.fromRGB(255, 255, 255)
	header.Font = Enum.Font.GothamBold
	header.TextSize = 18
	header.TextXAlignment = Enum.TextXAlignment.Left
	header.Parent = contentFrame

	return header
end

-- ============================================
-- TAB CONTENT RENDERING
-- ============================================

local function clearContent()
	for _, child in ipairs(contentFrame:GetChildren()) do
		if child:IsA("Frame") or child:IsA("TextLabel") then
			child:Destroy()
		end
	end
end

local function showOverviewTab(stats)
	clearContent()

	createSectionHeader("📊 Farm Overview")
	createStatRow("Days Played", tostring(stats.DaysPlayed or 0))
	createStatRow("Prestige Level", tostring(stats.PrestigeLevel or 0))

	createSectionHeader("💰 Financial Summary")
	createStatRow("Current Cash", FarmStatsConfig.FormatCash(stats.CurrentCash or 0))
	createStatRow("Total Earned", FarmStatsConfig.FormatCash(stats.TotalCashEarned or 0))
	createStatRow("Total Spent", FarmStatsConfig.FormatCash(stats.TotalCashSpent or 0))
	createStatRow("Net Profit", FarmStatsConfig.FormatCash(stats.NetProfit or 0))
end

local function showCropsTab(stats)
	clearContent()

	createSectionHeader("🌾 Crop Statistics")
	createStatRow("Total Harvested", FarmStatsConfig.FormatNumber(stats.TotalCropsHarvested or 0))
	createStatRow("Total Sold", FarmStatsConfig.FormatNumber(stats.TotalCropsSold or 0))
	createStatRow("Largest Harvest", tostring(stats.LargestSingleHarvest or 0))
	createStatRow("Favorite Crop", stats.FavoriteCrop or "None")

	createSectionHeader("📦 Harvest Breakdown")
	for cropName, count in pairs(stats.CropHarvestCounts or {}) do
		if count > 0 then
			createStatRow(cropName, FarmStatsConfig.FormatNumber(count))
		end
	end
end

local function showAnimalsTab(stats)
	clearContent()

	createSectionHeader("🐔 Animal Statistics")
	createStatRow("Total Animals Owned", tostring(stats.TotalAnimalsOwned or 0))

	createSectionHeader("📦 Collections")
	createStatRow("🥚 Eggs Collected", FarmStatsConfig.FormatNumber(stats.TotalEggsCollected or 0))
	createStatRow("🥛 Milk Collected", FarmStatsConfig.FormatNumber(stats.TotalMilkCollected or 0))
	createStatRow("🥩 Meat Collected", FarmStatsConfig.FormatNumber(stats.TotalMeatCollected or 0))
	createStatRow("🧶 Wool Collected", FarmStatsConfig.FormatNumber(stats.TotalWoolCollected or 0))
	createStatRow("🍯 Honey Collected", FarmStatsConfig.FormatNumber(stats.TotalHoneyCollected or 0))
end

local function showEconomyTab(stats)
	clearContent()

	createSectionHeader("💰 Spending Breakdown")
	createStatRow("Spent on Plots", FarmStatsConfig.FormatCash(stats.MoneySpentOnPlots or 0))
	createStatRow("Spent on Tools", FarmStatsConfig.FormatCash(stats.MoneySpentOnTools or 0))
	createStatRow("Spent on Seeds", FarmStatsConfig.FormatCash(stats.MoneySpentOnSeeds or 0))
	createStatRow("Spent on Animals", FarmStatsConfig.FormatCash(stats.MoneySpentOnAnimals or 0))

	createSectionHeader("📈 Summary")
	createStatRow("Total Income", FarmStatsConfig.FormatCash(stats.TotalCashEarned or 0))
	createStatRow("Total Expenses", FarmStatsConfig.FormatCash(stats.TotalCashSpent or 0))
	createStatRow("Net Profit", FarmStatsConfig.FormatCash(stats.NetProfit or 0))
end

local function showAchievementsTab(stats)
	clearContent()

	createSectionHeader("🏆 Achievements")

	for _, achievement in ipairs(FarmStatsConfig.ACHIEVEMENTS) do
		local unlocked = stats.Achievements[achievement.ID] or false

		local row = Instance.new("Frame")
		row.Size = UDim2.new(1, 0, 0, 60)
		row.BackgroundColor3 = unlocked and Color3.fromRGB(60, 120, 60) or Color3.fromRGB(45, 45, 45)
		row.BorderSizePixel = 0
		row.Parent = contentFrame

		local rowCorner = Instance.new("UICorner")
		rowCorner.CornerRadius = UDim.new(0, 8)
		rowCorner.Parent = row

		local icon = Instance.new("TextLabel")
		icon.Size = UDim2.new(0, 50, 1, 0)
		icon.BackgroundTransparency = 1
		icon.Text = unlocked and "✅" or "🔒"
		icon.TextSize = 30
		icon.Parent = row

		local nameLabel = Instance.new("TextLabel")
		nameLabel.Size = UDim2.new(1, -60, 0, 25)
		nameLabel.Position = UDim2.new(0, 60, 0, 5)
		nameLabel.BackgroundTransparency = 1
		nameLabel.Text = achievement.Name
		nameLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
		nameLabel.Font = Enum.Font.GothamBold
		nameLabel.TextSize = 16
		nameLabel.TextXAlignment = Enum.TextXAlignment.Left
		nameLabel.Parent = row

		local descLabel = Instance.new("TextLabel")
		descLabel.Size = UDim2.new(1, -60, 0, 20)
		descLabel.Position = UDim2.new(0, 60, 0, 30)
		descLabel.BackgroundTransparency = 1
		descLabel.Text = achievement.Description
		descLabel.TextColor3 = Color3.fromRGB(180, 180, 180)
		descLabel.Font = Enum.Font.Gotham
		descLabel.TextSize = 12
		descLabel.TextXAlignment = Enum.TextXAlignment.Left
		descLabel.Parent = row
	end
end

-- ============================================
-- TAB SWITCHING
-- ============================================

local function switchTab(tabName, stats)
	-- Update tab colors
	for name, tab in pairs(tabs) do
		if name == tabName then
			tab.BackgroundColor3 = Color3.fromRGB(60, 120, 60)
			tab.TextColor3 = Color3.fromRGB(255, 255, 255)
		else
			tab.BackgroundColor3 = Color3.fromRGB(70, 70, 70)
			tab.TextColor3 = Color3.fromRGB(200, 200, 200)
		end
	end

	-- Show content
	if tabName == "Overview" then
		showOverviewTab(stats)
	elseif tabName == "Crops" then
		showCropsTab(stats)
	elseif tabName == "Animals" then
		showAnimalsTab(stats)
	elseif tabName == "Economy" then
		showEconomyTab(stats)
	elseif tabName == "Achievements" then
		showAchievementsTab(stats)
	end

	activeTab = tabName
	contentFrame.CanvasPosition = Vector2.new(0, 0)
end

-- ============================================
-- OPEN/CLOSE
-- ============================================

local function openJournal()
	mainFrame.Visible = true
	journalOverlay.Visible = true

	-- Fetch latest stats
	local success, stats = pcall(function()
		return getFarmStatsFunction:InvokeServer()
	end)

	if success and stats then
		switchTab(activeTab or "Overview", stats)
	else
		warn("Failed to load farm stats")
	end
end

local function closeJournal()
	mainFrame.Visible = false
	journalOverlay.Visible = false
end


-- ============================================
-- CONNECTIONS
-- ============================================

closeButton.MouseButton1Click:Connect(closeJournal)

for name, tab in pairs(tabs) do
	tab.MouseButton1Click:Connect(function()
		local success, stats = pcall(function()
			return getFarmStatsFunction:InvokeServer()
		end)

		if success and stats then
			switchTab(name, stats)
		end
	end)
end

-- Listen for BindableEvent from CombinedHUD button
local openJournalEvent = ReplicatedStorage:FindFirstChild("OpenJournalEvent")
if openJournalEvent and openJournalEvent:IsA("BindableEvent") then
	openJournalEvent.Event:Connect(openJournal)
end



-- ============================================
-- ACHIEVEMENT NOTIFICATIONS
-- ============================================

achievementUnlockedEvent.OnClientEvent:Connect(function(achievement)
	-- Create notification popup
	local notification = Instance.new("Frame")
	notification.Size = UDim2.new(0, 350, 0, 100)
	notification.Position = UDim2.new(0.5, -175, 0, -120)
	notification.BackgroundColor3 = Color3.fromRGB(60, 120, 60)
	notification.BorderSizePixel = 0
	notification.Parent = screenGui

	local notifCorner = Instance.new("UICorner")
	notifCorner.CornerRadius = UDim.new(0, 12)
	notifCorner.Parent = notification

	local title = Instance.new("TextLabel")
	title.Size = UDim2.new(1, -20, 0, 30)
	title.Position = UDim2.new(0, 10, 0, 10)
	title.BackgroundTransparency = 1
	title.Text = "🏆 Achievement Unlocked!"
	title.TextColor3 = Color3.fromRGB(255, 255, 255)
	title.Font = Enum.Font.GothamBold
	title.TextSize = 18
	title.Parent = notification

	local name = Instance.new("TextLabel")
	name.Size = UDim2.new(1, -20, 0, 25)
	name.Position = UDim2.new(0, 10, 0, 40)
	name.BackgroundTransparency = 1
	name.Text = achievement.Name
	name.TextColor3 = Color3.fromRGB(255, 255, 150)
	name.Font = Enum.Font.GothamBold
	name.TextSize = 16
	name.Parent = notification

	local desc = Instance.new("TextLabel")
	desc.Size = UDim2.new(1, -20, 0, 20)
	desc.Position = UDim2.new(0, 10, 0, 65)
	desc.BackgroundTransparency = 1
	desc.Text = achievement.Description
	desc.TextColor3 = Color3.fromRGB(200, 200, 200)
	desc.Font = Enum.Font.Gotham
	desc.TextSize = 12
	desc.Parent = notification

	-- Animate in
	local tweenIn = TweenService:Create(notification, TweenInfo.new(0.5, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
		Position = UDim2.new(0.5, -175, 0, 20)
	})
	tweenIn:Play()

	-- Wait and animate out
	task.wait(4)
	local tweenOut = TweenService:Create(notification, TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
		Position = UDim2.new(0.5, -175, 0, -120)
	})
	tweenOut:Play()
	tweenOut.Completed:Connect(function()
		notification:Destroy()
	end)
end)

print("📖 Farm Journal ready!")
