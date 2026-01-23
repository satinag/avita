local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local player = Players.LocalPlayer
local gui = script.Parent

-- ✅ Device detection
local isMobile = UserInputService.TouchEnabled and not UserInputService.KeyboardEnabled and not UserInputService.MouseEnabled

-- State
local showStats = false
local showQuests = false
local autoHideThread = nil

-- ✅ RESPONSIVE: Positions (STACKED VERTICALLY on left)
local statsButtonPos = UDim2.new(0, 10, 0, 10)
local statsFramePos = UDim2.new(0, 70, 0, 10)
local questsButtonPos = UDim2.new(0, 10, 0, 70)  
local questsFramePos = UDim2.new(0, 70, 0, 70)  -- ✅ Changed from 130 to 70
local journalButtonPos = UDim2.new(0, 10, 0, 130)  -- ✅ ADD THIS NEW LINE
local leaderboardButtonPos = UDim2.new(0, 10, 0, 190)  

-- ✅ Scale sizes for mobile
local scaleX = isMobile and 0.77 or 1.1
local scaleY = isMobile and 0.77 or 1.1

-- Milestones
local MILESTONES = {
	{Name = "Expansion Zone 1", Cash = 1000},
	{Name = "Expansion Zone 2", Cash = 5000},
	{Name = "Expansion Zone 3", Cash = 15000}
}

-- ALL 8 SEEDS/CROPS DATA
local ITEMS_DATA = {
	{Name = "Wheat", Emoji = "🌾", Color = Color3.fromRGB(200, 180, 100)},
	{Name = "Corn", Emoji = "🌽", Color = Color3.fromRGB(255, 200, 50)},
	{Name = "Carrot", Emoji = "🥕", Color = Color3.fromRGB(255, 140, 50)},
	{Name = "Potato", Emoji = "🥔", Color = Color3.fromRGB(180, 130, 80)},
	{Name = "Tomato", Emoji = "🍅", Color = Color3.fromRGB(255, 150, 150)},
	{Name = "Pumpkin", Emoji = "🎃", Color = Color3.fromRGB(255, 120, 30)},
	{Name = "Strawberry", Emoji = "🍓", Color = Color3.fromRGB(255, 180, 200)},
	{Name = "Watermelon", Emoji = "🍉", Color = Color3.fromRGB(80, 180, 80)}
}

-- STATS FRAME
local statsFrame = Instance.new("Frame")
statsFrame.Name = "StatsFrame"
statsFrame.Size = UDim2.new(0.35 * scaleX, 0, 0.56 * scaleY, 0)
statsFrame.Position = statsFramePos
statsFrame.AnchorPoint = Vector2.new(0, 0)
statsFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
statsFrame.BackgroundTransparency = 0.15
statsFrame.BorderSizePixel = 0
statsFrame.Visible = false
statsFrame.ZIndex = 5
statsFrame.Parent = gui

local statsCorner = Instance.new("UICorner")
statsCorner.CornerRadius = UDim.new(0, 12)
statsCorner.Parent = statsFrame

local statsStroke = Instance.new("UIStroke")
statsStroke.Color = Color3.fromRGB(100, 100, 100)
statsStroke.Thickness = 2
statsStroke.Transparency = 0.3
statsStroke.Parent = statsFrame

local statsAspect = Instance.new("UIAspectRatioConstraint")
statsAspect.AspectRatio = 0.9
statsAspect.Parent = statsFrame

-- Cash label
local cashLabel = Instance.new("TextLabel")
cashLabel.Size = UDim2.new(1, -4, 0.11, 0)
cashLabel.Position = UDim2.new(0, 2, 0, 2)
cashLabel.BackgroundColor3 = Color3.fromRGB(50, 120, 50)
cashLabel.BackgroundTransparency = 0
cashLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
cashLabel.TextScaled = true
cashLabel.Font = Enum.Font.Gotham
cashLabel.Text = "💰 Cash: 0"
cashLabel.BorderSizePixel = 0
cashLabel.ZIndex = 6
cashLabel.Parent = statsFrame

local cashCorner = Instance.new("UICorner")
cashCorner.CornerRadius = UDim.new(0, 10)
cashCorner.Parent = cashLabel

-- SEEDS SECTION HEADER
local seedsHeader = Instance.new("TextLabel")
seedsHeader.Size = UDim2.new(1, -4, 0.09, 0)
seedsHeader.Position = UDim2.new(0, 2, 0.11, 2)
seedsHeader.BackgroundColor3 = Color3.fromRGB(100, 150, 50)
seedsHeader.TextColor3 = Color3.fromRGB(255, 255, 255)
seedsHeader.TextScaled = true
seedsHeader.Font = Enum.Font.Gotham
seedsHeader.Text = "🌱 Seeds"
seedsHeader.BorderSizePixel = 0
seedsHeader.ZIndex = 6
seedsHeader.Parent = statsFrame

local seedsHeaderCorner = Instance.new("UICorner")
seedsHeaderCorner.CornerRadius = UDim.new(0, 8)
seedsHeaderCorner.Parent = seedsHeader

-- Create seed labels dynamically (4 per row, 2 rows)
local seedLabels = {}
local rowHeight = 0.11
local startY = 0.20

for i, itemData in ipairs(ITEMS_DATA) do
	local row = math.floor((i - 1) / 4)
	local col = (i - 1) % 4

	local label = Instance.new("TextLabel")
	label.Size = UDim2.new(0.25, -4, rowHeight, -2)
	label.Position = UDim2.new(col * 0.25, 2, startY + row * rowHeight, 1)
	label.BackgroundColor3 = itemData.Color
	label.TextColor3 = Color3.fromRGB(0, 0, 0)
	label.TextScaled = true
	label.Font = Enum.Font.Gotham
	label.Text = itemData.Emoji .. " 0"
	label.BorderSizePixel = 0
	label.ZIndex = 6
	label.Parent = statsFrame

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 6)
	corner.Parent = label

	seedLabels[itemData.Name] = label
end

-- CROPS SECTION HEADER
local cropsHeader = Instance.new("TextLabel")
cropsHeader.Size = UDim2.new(1, -4, 0.09, 0)
cropsHeader.Position = UDim2.new(0, 2, 0.42, 2)
cropsHeader.BackgroundColor3 = Color3.fromRGB(150, 100, 50)
cropsHeader.TextColor3 = Color3.fromRGB(255, 255, 255)
cropsHeader.TextScaled = true
cropsHeader.Font = Enum.Font.Gotham
cropsHeader.Text = "🌾 Crops"
cropsHeader.BorderSizePixel = 0
cropsHeader.ZIndex = 6
cropsHeader.Parent = statsFrame

local cropsHeaderCorner = Instance.new("UICorner")
cropsHeaderCorner.CornerRadius = UDim.new(0, 8)
cropsHeaderCorner.Parent = cropsHeader

-- Create crop labels dynamically (4 per row, 2 rows)
local cropLabels = {}
local cropsStartY = 0.51

for i, itemData in ipairs(ITEMS_DATA) do
	local row = math.floor((i - 1) / 4)
	local col = (i - 1) % 4

	local label = Instance.new("TextLabel")
	label.Size = UDim2.new(0.25, -4, rowHeight, -2)
	label.Position = UDim2.new(col * 0.25, 2, cropsStartY + row * rowHeight, 1)
	label.BackgroundColor3 = itemData.Color
	label.TextColor3 = Color3.fromRGB(0, 0, 0)
	label.TextScaled = true
	label.Font = Enum.Font.Gotham
	label.Text = itemData.Emoji .. " 0"
	label.BorderSizePixel = 0
	label.ZIndex = 6
	label.Parent = statsFrame

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 6)
	corner.Parent = label

	cropLabels[itemData.Name] = label
end

-- Tools label
local toolsLabel = Instance.new("TextLabel")
toolsLabel.Size = UDim2.new(1, -4, 0.11, 0)
toolsLabel.Position = UDim2.new(0, 2, 0.73, 2)
toolsLabel.BackgroundColor3 = Color3.fromRGB(100, 100, 150)
toolsLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
toolsLabel.TextScaled = true
toolsLabel.Font = Enum.Font.Gotham
toolsLabel.Text = "🛠️ Tools: None"
toolsLabel.BorderSizePixel = 0
toolsLabel.ZIndex = 6
toolsLabel.Parent = statsFrame

local toolsCorner = Instance.new("UICorner")
toolsCorner.CornerRadius = UDim.new(0, 8)
toolsCorner.Parent = toolsLabel

-- Plots label
local plotLabel = Instance.new("TextLabel")
plotLabel.Size = UDim2.new(1, -4, 0.14, 0)
plotLabel.Position = UDim2.new(0, 2, 0.84, 2)
plotLabel.BackgroundColor3 = Color3.fromRGB(120, 80, 40)
plotLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
plotLabel.TextScaled = true
plotLabel.Font = Enum.Font.Gotham
plotLabel.Text = "🟫 Plots: 0/8"
plotLabel.BorderSizePixel = 0
plotLabel.ZIndex = 6
plotLabel.Parent = statsFrame

local plotCorner = Instance.new("UICorner")
plotCorner.CornerRadius = UDim.new(0, 8)
plotCorner.Parent = plotLabel


-- ✅ RESPONSIVE: QUESTS FRAME
local questsFrame = Instance.new("Frame")
questsFrame.Name = "QuestsFrame"
questsFrame.Size = UDim2.new(0.35 * scaleX, 0, 0.45 * scaleY, 0)
questsFrame.Position = questsFramePos
questsFrame.AnchorPoint = Vector2.new(0, 0)
questsFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
questsFrame.BackgroundTransparency = 0.15
questsFrame.BorderSizePixel = 0
questsFrame.Visible = false
questsFrame.ZIndex = 5
questsFrame.Parent = gui

local questsCorner = Instance.new("UICorner")
questsCorner.CornerRadius = UDim.new(0, 12)
questsCorner.Parent = questsFrame

local questsStroke = Instance.new("UIStroke")
questsStroke.Color = Color3.fromRGB(100, 100, 100)
questsStroke.Thickness = 2
questsStroke.Transparency = 0.3
questsStroke.Parent = questsFrame

local questsAspect = Instance.new("UIAspectRatioConstraint")
questsAspect.AspectRatio = 2.2
questsAspect.Parent = questsFrame

-- ✅ Background overlay (dims everything behind leaderboard)
local leaderboardOverlay = Instance.new("Frame")
leaderboardOverlay.Name = "LeaderboardOverlay"
leaderboardOverlay.Size = UDim2.new(1, 0, 1, 0)
leaderboardOverlay.Position = UDim2.new(0, 0, 0, 0)
leaderboardOverlay.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
leaderboardOverlay.BackgroundTransparency = 0.5
leaderboardOverlay.BorderSizePixel = 0
leaderboardOverlay.Visible = false
leaderboardOverlay.ZIndex = 100
leaderboardOverlay.Parent = gui

-- LEADERBOARD FRAME (centered popup with left padding for buttons)
local leaderboardFrame = Instance.new("Frame")
leaderboardFrame.Name = "LeaderboardFrame"
leaderboardFrame.Size = UDim2.new(isMobile and 0.88 or 0.48, 0, isMobile and 0.85 or 0.75, 0)
leaderboardFrame.Position = UDim2.new(0.5, 35, 0.5, 0)
leaderboardFrame.AnchorPoint = Vector2.new(0.5, 0.5)
leaderboardFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
leaderboardFrame.BackgroundTransparency = 0.15
leaderboardFrame.BorderSizePixel = 0
leaderboardFrame.Visible = false
leaderboardFrame.ZIndex = 101
leaderboardFrame.Parent = gui


local leaderboardCorner = Instance.new("UICorner")
leaderboardCorner.CornerRadius = UDim.new(0, 12)
leaderboardCorner.Parent = leaderboardFrame

local leaderboardStroke = Instance.new("UIStroke")
leaderboardStroke.Color = Color3.fromRGB(100, 100, 100)
leaderboardStroke.Thickness = 2
leaderboardStroke.Transparency = 0.3
leaderboardStroke.Parent = leaderboardFrame

-- Title
local leaderboardTitle = Instance.new("TextLabel")
leaderboardTitle.Size = UDim2.new(1, -60, 0, 40)  -- ✅ Leave space for close button
leaderboardTitle.Position = UDim2.new(0, 5, 0, 5)
leaderboardTitle.BackgroundTransparency = 1
leaderboardTitle.Text = "🏆 Top 10 Players"
leaderboardTitle.TextColor3 = Color3.fromRGB(255, 215, 0)
leaderboardTitle.TextScaled = true
leaderboardTitle.Font = Enum.Font.GothamBold
leaderboardTitle.ZIndex = 6
leaderboardTitle.Parent = leaderboardFrame

-- ✅ Close button (X)
local closeButton = Instance.new("TextButton")
closeButton.Size = UDim2.new(0, 35, 0, 35)
closeButton.Position = UDim2.new(1, -40, 0, 5)
closeButton.BackgroundColor3 = Color3.fromRGB(200, 100, 100)
closeButton.Text = "X"
closeButton.TextColor3 = Color3.fromRGB(255, 255, 255)
closeButton.TextScaled = true
closeButton.Font = Enum.Font.GothamBold
closeButton.ZIndex = 7
closeButton.Parent = leaderboardFrame

local closeCorner = Instance.new("UICorner")
closeCorner.CornerRadius = UDim.new(1, 0)
closeCorner.Parent = closeButton


-- Category selector (buttons)
local categoryFrame = Instance.new("Frame")
categoryFrame.Size = UDim2.new(1, -10, 0, 50)
categoryFrame.Position = UDim2.new(0, 5, 0, 50)
categoryFrame.BackgroundTransparency = 1
categoryFrame.ZIndex = 6
categoryFrame.Parent = leaderboardFrame

-- ✅ NEW: Category definitions with icons and labels
local categories = {
	{ID = "TotalEarned", Icon = "💰", Label = "Total earned $"},
	{ID = "Cash", Icon = "💵", Label = "Cash"},
	{ID = "PlotsOwned", Icon = "🟫", Label = "Plots"},      
	{ID = "AnimalsOwned", Icon = "🐔", Label = "Animals"},
	{ID = "HouseLevel", Icon = "🏠", Label = "House"},     
	{ID = "DaysPlayed", Icon = "📅", Label = "Days"}
}

local categoryButtons = {}

for i, cat in ipairs(categories) do
	local btn = Instance.new("TextButton")
	btn.Size = UDim2.new(1/#categories, -2, 1, 0)
	btn.Position = UDim2.new((i-1)/#categories, 1, 0, 0)
	btn.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
	btn.Text = ""  -- ✅ Clear text, we'll use custom layout
	btn.TextColor3 = Color3.fromRGB(255, 255, 255)
	btn.Font = Enum.Font.Gotham
	btn.ZIndex = 7
	btn.Parent = categoryFrame

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 6)
	corner.Parent = btn

	-- ✅ Icon (top 60% of button)
	local icon = Instance.new("TextLabel")
	icon.Size = UDim2.new(1, 0, 0.6, 0)  -- 60% height
	icon.Position = UDim2.new(0, 0, 0, 0)  -- Start at top
	icon.BackgroundTransparency = 1
	icon.Text = cat.Icon
	icon.TextColor3 = Color3.fromRGB(255, 255, 255)
	icon.TextScaled = true
	icon.Font = Enum.Font.Gotham
	icon.ZIndex = 8
	icon.Parent = btn


	-- ✅ Label (below icon, centered, bold)
	local label = Instance.new("TextLabel")
	label.Size = UDim2.new(1, 0, 0.4, 0)
	label.Position = UDim2.new(0, 0, 0.6, 0)
	label.BackgroundTransparency = 1
	label.Text = cat.Label
	label.TextColor3 = Color3.fromRGB(200, 200, 200)
	label.TextScaled = true
	label.Font = Enum.Font.GothamBold  -- ✅ Bold
	label.TextXAlignment = Enum.TextXAlignment.Center
	label.ZIndex = 8
	label.Parent = btn


	categoryButtons[cat.ID] = btn
end


-- Scrolling list
-- Scrolling list
local leaderboardScroll = Instance.new("ScrollingFrame")
leaderboardScroll.Size = UDim2.new(1, -10, 1, -115)  -- Was -95, now -115
leaderboardScroll.Position = UDim2.new(0, 5, 0, 110)  -- Was 90, now 110
leaderboardScroll.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
leaderboardScroll.BorderSizePixel = 0
leaderboardScroll.ScrollBarThickness = 8
leaderboardScroll.ZIndex = 6
leaderboardScroll.Parent = leaderboardFrame

local scrollCorner = Instance.new("UICorner")
scrollCorner.CornerRadius = UDim.new(0, 8)
scrollCorner.Parent = leaderboardScroll



-- Create RemoteFunction for claiming
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- ✅ RESPONSIVE: Dynamic quest display function
local function updateQuestsDisplay()
	-- Clear existing quest slots
	for _, child in ipairs(questsFrame:GetChildren()) do
		if child:IsA("Frame") and child.Name:match("QuestSlot") then
			child:Destroy()
		end
	end

	local questsFolder = player:FindFirstChild("DailyQuests")
	if not questsFolder then 
		return 
	end

	local QuestModule = require(ReplicatedStorage:WaitForChild("DailyQuestModule"))
	local yPos = 0.05
	local slotHeight = isMobile and 0.33 or 0.30  -- ✅ Slightly taller on mobile

	for i, questFolder in ipairs(questsFolder:GetChildren()) do
		local questID = questFolder:FindFirstChild("ID")
		local current = questFolder:FindFirstChild("Current")
		local target = questFolder:FindFirstChild("Target")
		local completed = questFolder:FindFirstChild("Completed")
		local claimed = questFolder:FindFirstChild("Claimed")

		if questID and current and target and completed and claimed then
			local questDef = nil
			for _, q in ipairs(QuestModule.QuestPool) do
				if q.ID == questID.Value then
					questDef = q
					break
				end
			end

			if questDef then
				-- ✅ RESPONSIVE: Quest slot
				local slot = Instance.new("Frame")
				slot.Name = "QuestSlot" .. i
				slot.Size = UDim2.new(0.95, 0, slotHeight, 0)
				slot.Position = UDim2.new(0.025, 0, yPos, 0)
				slot.BackgroundColor3 = claimed.Value and Color3.fromRGB(50, 100, 50) or (completed.Value and Color3.fromRGB(60, 120, 60) or Color3.fromRGB(60, 60, 60))
				slot.BorderSizePixel = 0
				slot.Parent = questsFrame

				local corner = Instance.new("UICorner")
				corner.CornerRadius = UDim.new(0, 8)
				corner.Parent = slot

				-- Quest name
				local nameLabel = Instance.new("TextLabel")
				nameLabel.Size = UDim2.new(1, -10, 0.25, 0)
				nameLabel.Position = UDim2.new(0, 5, 0.05, 0)
				nameLabel.BackgroundTransparency = 1
				nameLabel.Text = questDef.Name
				nameLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
				nameLabel.TextScaled = true
				nameLabel.Font = Enum.Font.GothamBold
				nameLabel.TextXAlignment = Enum.TextXAlignment.Left
				nameLabel.TextTruncate = Enum.TextTruncate.AtEnd
				nameLabel.Parent = slot

				local namePadding = Instance.new("UIPadding")
				namePadding.PaddingLeft = UDim.new(0, 5)
				namePadding.Parent = nameLabel

				-- ✅ Progress bar background
				local progBg = Instance.new("Frame")
				progBg.Size = UDim2.new(0.9, 0, 0.2, 0)
				progBg.Position = UDim2.new(0.05, 0, 0.35, 0)
				progBg.BackgroundColor3 = Color3.fromRGB(80, 80, 80)
				progBg.BorderSizePixel = 0
				progBg.ZIndex = 6
				progBg.Parent = slot

				local progBgCorner = Instance.new("UICorner")
				progBgCorner.CornerRadius = UDim.new(0, 6)
				progBgCorner.Parent = progBg

				-- ✅ Progress bar fill
				local progFill = Instance.new("Frame")
				progFill.Size = UDim2.new(math.min(current.Value / target.Value, 1), 0, 1, 0)
				progFill.BackgroundColor3 = Color3.fromRGB(100, 255, 100)
				progFill.BorderSizePixel = 0
				progFill.ZIndex = 7
				progFill.Parent = progBg

				local progFillCorner = Instance.new("UICorner")
				progFillCorner.CornerRadius = UDim.new(0, 6)
				progFillCorner.Parent = progFill

				-- ✅ NEW: Progress text OVERLAY (contrasting color)
				local progressOverlay = Instance.new("TextLabel")
				progressOverlay.Size = UDim2.new(1, 0, 1, 0)
				progressOverlay.Position = UDim2.new(0, 0, 0, 0)
				progressOverlay.BackgroundTransparency = 1
				progressOverlay.Text = current.Value .. " / " .. target.Value
				progressOverlay.TextColor3 = Color3.fromRGB(255, 255, 255)  -- White for contrast
				progressOverlay.TextScaled = true
				progressOverlay.Font = Enum.Font.GothamBold
				progressOverlay.ZIndex = 8  -- Above bar fill
				progressOverlay.Parent = progBg

				local progressStroke = Instance.new("UIStroke")
				progressStroke.Color = Color3.fromRGB(0, 0, 0)
				progressStroke.Thickness = 2
				progressStroke.Transparency = 0.3
				progressStroke.Parent = progressOverlay

				-- ✅ RESPONSIVE: Claim button or status
				if completed.Value and not claimed.Value then
					local claimBtn = Instance.new("TextButton")
					claimBtn.Size = UDim2.new(isMobile and 0.4 or 0.35, 0, 0.25, 0)
					claimBtn.Position = UDim2.new(isMobile and 0.55 or 0.6, 0, 0.7, 0)
					claimBtn.BackgroundColor3 = Color3.fromRGB(100, 200, 100)
					claimBtn.Text = "CLAIM"
					claimBtn.TextColor3 = Color3.fromRGB(0, 0, 0)
					claimBtn.TextScaled = true
					claimBtn.Font = Enum.Font.GothamBold
					claimBtn.Parent = slot

					local claimCorner = Instance.new("UICorner")
					claimCorner.CornerRadius = UDim.new(0, 6)
					claimCorner.Parent = claimBtn

					claimBtn.MouseButton1Click:Connect(function()
						local success = ReplicatedStorage:WaitForChild("ClaimQuestReward"):InvokeServer(questID.Value)
						if success then
							print("✅ Quest claimed!")
							updateQuestsDisplay()
						end
					end)
				elseif claimed.Value then
					local statusLabel = Instance.new("TextLabel")
					statusLabel.Size = UDim2.new(0.4, 0, 0.25, 0)
					statusLabel.Position = UDim2.new(0.55, 0, 0.7, 0)
					statusLabel.BackgroundTransparency = 1
					statusLabel.Text = "✅ CLAIMED"
					statusLabel.TextColor3 = Color3.fromRGB(100, 255, 100)
					statusLabel.TextScaled = true
					statusLabel.Font = Enum.Font.GothamBold
					statusLabel.Parent = slot
				else
					local statusLabel = Instance.new("TextLabel")
					statusLabel.Size = UDim2.new(0.4, 0, 0.25, 0)
					statusLabel.Position = UDim2.new(0.55, 0, 0.7, 0)
					statusLabel.BackgroundTransparency = 1
					statusLabel.Text = "In Progress"
					statusLabel.TextColor3 = Color3.fromRGB(200, 200, 100)
					statusLabel.TextScaled = true
					statusLabel.Font = Enum.Font.Gotham
					statusLabel.Parent = slot
				end

				yPos = yPos + slotHeight + 0.02
			end
		end
	end
end

-- Quest listener
task.spawn(function()
	repeat task.wait(0.1) until player:FindFirstChild("DailyQuests")

	for _, questFolder in ipairs(player.DailyQuests:GetChildren()) do
		for _, val in ipairs(questFolder:GetChildren()) do
			if val:IsA("IntValue") or val:IsA("BoolValue") then
				val.Changed:Connect(updateQuestsDisplay)
			end
		end
	end

	updateQuestsDisplay()
end)

-- ============================================
-- TIME DISPLAY (Top Right) - MINI & ABSOLUTE TOP CORNER
-- ============================================

-- Main clock container - MINI SIZE, ABSOLUTE TOP CORNER
local clockContainer = Instance.new("Frame")
clockContainer.Name = "ClockContainer"
clockContainer.Size = UDim2.new(0, 135, 0, 45)  -- ✅ Slightly wider: 135x45 (was 120)
clockContainer.Position = UDim2.new(1, -140, 0, 0)  -- ✅ Adjusted position for new width
clockContainer.AnchorPoint = Vector2.new(0, 0)
clockContainer.BackgroundColor3 = Color3.fromRGB(25, 25, 30)
clockContainer.BackgroundTransparency = 0.15
clockContainer.BorderSizePixel = 0
clockContainer.ZIndex = 5
clockContainer.ClipsDescendants = true
clockContainer.Parent = gui

local clockCorner = Instance.new("UICorner")
clockCorner.CornerRadius = UDim.new(0, 8)
clockCorner.Parent = clockContainer

-- Fancy gradient background
local clockGradient = Instance.new("UIGradient")
clockGradient.Color = ColorSequence.new{
	ColorSequenceKeypoint.new(0, Color3.fromRGB(40, 40, 50)),
	ColorSequenceKeypoint.new(1, Color3.fromRGB(20, 20, 30))
}
clockGradient.Rotation = 45
clockGradient.Parent = clockContainer

-- Stroke border for depth
local clockStroke = Instance.new("UIStroke")
clockStroke.Color = Color3.fromRGB(80, 80, 100)
clockStroke.Thickness = 1.5
clockStroke.Transparency = 0.4
clockStroke.Parent = clockContainer

-- Time text (larger, bold)
local timeText = Instance.new("TextLabel")
timeText.Name = "TimeText"
timeText.Size = UDim2.new(1, -8, 0.5, 0)
timeText.Position = UDim2.new(0, 4, 0, 1)
timeText.BackgroundTransparency = 1
timeText.Text = "12:00 PM"
timeText.TextColor3 = Color3.fromRGB(255, 255, 255)
timeText.TextScaled = true
timeText.Font = Enum.Font.GothamBold
timeText.TextTruncate = Enum.TextTruncate.AtEnd
timeText.ZIndex = 6
timeText.Parent = clockContainer

-- Text glow effect
local timeGlow = Instance.new("UIStroke")
timeGlow.Color = Color3.fromRGB(255, 220, 150)
timeGlow.Thickness = 0
timeGlow.Transparency = 0.7
timeGlow.Parent = timeText

-- Day/Season text (smaller, below time)
local dateText = Instance.new("TextLabel")
dateText.Name = "DateText"
dateText.Size = UDim2.new(1, -8, 0.42, 0)
dateText.Position = UDim2.new(0, 4, 0.54, 0)
dateText.BackgroundTransparency = 1
dateText.Text = "📅 Day 1 • Spring"
dateText.TextColor3 = Color3.fromRGB(200, 220, 255)
dateText.TextScaled = true
dateText.Font = Enum.Font.Gotham
dateText.TextTruncate = Enum.TextTruncate.AtEnd
dateText.ZIndex = 6
dateText.Parent = clockContainer

-- Listen for time updates from server
task.spawn(function()
	local ReplicatedStorage = game:GetService("ReplicatedStorage")
	local timeUpdateRemote = ReplicatedStorage:WaitForChild("TimeUpdate", 10)

	if not timeUpdateRemote then
		print("❌ TimeUpdate remote not found")
		return
	end

	timeUpdateRemote.OnClientEvent:Connect(function(time, day, season)
		-- ✅ Safety check for nil values
		day = tonumber(day) or 1
		time = tonumber(time) or 660
		season = season or "Spring"

		local hours = math.floor(time / 60)
		local mins = time % 60
		local period = hours >= 12 and "PM" or "AM"
		if hours > 12 then hours = hours - 12 end
		if hours == 0 then hours = 12 end

		-- Format day number nicely (abbreviate only if huge)
		local dayStr
		if day > 9999 then
			dayStr = string.format("%.1fk", day / 1000)  -- "10.5k"
		elseif day > 999 then
			dayStr = string.format("%.0fk", day / 1000)  -- "1k"
		else
			dayStr = tostring(day)
		end

		-- Update time display
		timeText.Text = string.format("%d:%02d %s", hours, mins, period)
		dateText.Text = string.format("📅 Day %s • %s", dayStr, season)

		-- Dynamic color based on time of day
		if period == "AM" and hours >= 6 then
			-- Morning - bright yellow glow
			timeGlow.Color = Color3.fromRGB(255, 220, 100)
			clockGradient.Color = ColorSequence.new{
				ColorSequenceKeypoint.new(0, Color3.fromRGB(60, 60, 80)),
				ColorSequenceKeypoint.new(1, Color3.fromRGB(30, 30, 50))
			}
		elseif period == "PM" and hours >= 6 then
			-- Evening/Night - blue/purple glow
			timeGlow.Color = Color3.fromRGB(150, 180, 255)
			clockGradient.Color = ColorSequence.new{
				ColorSequenceKeypoint.new(0, Color3.fromRGB(30, 30, 50)),
				ColorSequenceKeypoint.new(1, Color3.fromRGB(15, 15, 30))
			}
		else
			-- Day - neutral
			timeGlow.Color = Color3.fromRGB(255, 255, 200)
			clockGradient.Color = ColorSequence.new{
				ColorSequenceKeypoint.new(0, Color3.fromRGB(50, 50, 70)),
				ColorSequenceKeypoint.new(1, Color3.fromRGB(25, 25, 40))
			}
		end
	end)
end)

print("⏰ Mini top-corner time display loaded!")



-- STATS BUTTON
local statsButton = Instance.new("ImageButton")
statsButton.Name = "ToggleStats"
statsButton.Size = UDim2.new(0, 50 * scaleX, 0, 50 * scaleY)
statsButton.Position = statsButtonPos
statsButton.AnchorPoint = Vector2.new(0, 0)
statsButton.BackgroundTransparency = 1
statsButton.BorderSizePixel = 0
statsButton.Image = ""
statsButton.ZIndex = 10
statsButton.Parent = gui

local statsIcon = Instance.new("TextLabel")
statsIcon.Size = UDim2.new(1, 0, 1, 0)
statsIcon.Position = UDim2.new(0, 0, 0, 0)
statsIcon.BackgroundTransparency = 1
statsIcon.Text = "💰"
statsIcon.TextColor3 = Color3.fromRGB(255, 255, 255)
statsIcon.TextScaled = true
statsIcon.Font = Enum.Font.Gotham
statsIcon.ZIndex = 11
statsIcon.Parent = statsButton

local statsIconStroke = Instance.new("UIStroke")
statsIconStroke.Color = Color3.fromRGB(0, 0, 0)
statsIconStroke.Thickness = 3
statsIconStroke.Transparency = 0.5
statsIconStroke.Parent = statsIcon

-- QUESTS BUTTON
local questsButton = Instance.new("ImageButton")
questsButton.Name = "ToggleQuests"
questsButton.Size = UDim2.new(0, 50 * scaleX, 0, 50 * scaleY)
questsButton.Position = questsButtonPos
questsButton.AnchorPoint = Vector2.new(0, 0)
questsButton.BackgroundTransparency = 1
questsButton.BorderSizePixel = 0
questsButton.Image = ""
questsButton.ZIndex = 10
questsButton.Parent = gui

local questsIcon = Instance.new("TextLabel")
questsIcon.Size = UDim2.new(1, 0, 1, 0)
questsIcon.Position = UDim2.new(0, 0, 0, 0)
questsIcon.BackgroundTransparency = 1
questsIcon.Text = "📜"
questsIcon.TextColor3 = Color3.fromRGB(255, 255, 255)
questsIcon.TextScaled = true
questsIcon.Font = Enum.Font.Gotham
questsIcon.ZIndex = 11
questsIcon.Parent = questsButton

local questsIconStroke = Instance.new("UIStroke")
questsIconStroke.Color = Color3.fromRGB(0, 0, 0)
questsIconStroke.Thickness = 3
questsIconStroke.Transparency = 0.5
questsIconStroke.Parent = questsIcon


-- JOURNAL BUTTON
local journalButton = Instance.new("ImageButton")
journalButton.Name = "ToggleJournal"
journalButton.Size = UDim2.new(0, 50 * scaleX, 0, 50 * scaleY)
journalButton.Position = journalButtonPos    -- ✅ BETWEEN quests (130) and leaderboard (250)
journalButton.AnchorPoint = Vector2.new(0, 0)
journalButton.BackgroundTransparency = 1
journalButton.BorderSizePixel = 0
journalButton.Image = ""
journalButton.ZIndex = 10
journalButton.Parent = gui

-- Create journal icon
local journalIcon = Instance.new("TextLabel")
journalIcon.Size = UDim2.new(1, 0, 1, 0)
journalIcon.Position = UDim2.new(0, 0, 0, 0)
journalIcon.BackgroundTransparency = 1
journalIcon.Text = "📖"
journalIcon.TextColor3 = Color3.fromRGB(100, 150, 200)  -- Blue color like the original design
journalIcon.TextScaled = true
journalIcon.Font = Enum.Font.Gotham
journalIcon.ZIndex = 11
journalIcon.Parent = journalButton

local journalIconStroke = Instance.new("UIStroke")
journalIconStroke.Color = Color3.fromRGB(0, 0, 0)
journalIconStroke.Thickness = 3
journalIconStroke.Transparency = 0.5
journalIconStroke.Parent = journalIcon

-- LEADERBOARD BUTTON
local leaderboardButton = Instance.new("ImageButton")
leaderboardButton.Name = "ToggleLeaderboard"
leaderboardButton.Size = UDim2.new(0, 50 * scaleX, 0, 50 * scaleY)
leaderboardButton.Position = leaderboardButtonPos   -- ✅ 130 + 70 = 200 (was 190)
leaderboardButton.AnchorPoint = Vector2.new(0, 0)
leaderboardButton.BackgroundTransparency = 1
leaderboardButton.BorderSizePixel = 0
leaderboardButton.Image = ""
leaderboardButton.ZIndex = 10
leaderboardButton.Parent = gui

-- Create leaderboard icon first
local leaderboardIcon = Instance.new("TextLabel")
leaderboardIcon.Size = UDim2.new(1, 0, 1, 0)
leaderboardIcon.Position = UDim2.new(0, 0, 0, 0)
leaderboardIcon.BackgroundTransparency = 1
leaderboardIcon.Text = "🏆"
leaderboardIcon.TextColor3 = Color3.fromRGB(255, 215, 0)
leaderboardIcon.TextScaled = true
leaderboardIcon.Font = Enum.Font.Gotham
leaderboardIcon.ZIndex = 11
leaderboardIcon.Parent = leaderboardButton

local leaderboardIconStroke = Instance.new("UIStroke")
leaderboardIconStroke.Color = Color3.fromRGB(0, 0, 0)
leaderboardIconStroke.Thickness = 3
leaderboardIconStroke.Transparency = 0.5
leaderboardIconStroke.Parent = leaderboardIcon



-- Update Functions
local function getNextMilestone(currentCash)
	for _, milestone in ipairs(MILESTONES) do
		if currentCash < milestone.Cash then return milestone end
	end
	return nil
end

local function updateStats()
	local leaderstats = player:FindFirstChild("leaderstats")
	if not leaderstats then return end

	local cash = leaderstats:FindFirstChild("Cash")
	local seedInventory = player:FindFirstChild("SeedInventory")
	local cropInventory = player:FindFirstChild("CropInventory")
	local toolsOwned = player:FindFirstChild("ToolsOwned")

	if cash then cashLabel.Text = "💰 Cash: " .. cash.Value end

	if seedInventory then
		for _, itemData in ipairs(ITEMS_DATA) do
			local seedValue = seedInventory:FindFirstChild(itemData.Name)
			local label = seedLabels[itemData.Name]
			if label and seedValue then
				label.Text = itemData.Emoji .. " " .. seedValue.Value
			end
		end
	end

	if cropInventory then
		for _, itemData in ipairs(ITEMS_DATA) do
			local cropValue = cropInventory:FindFirstChild(itemData.Name)
			local label = cropLabels[itemData.Name]
			if label and cropValue then
				label.Text = itemData.Emoji .. " " .. cropValue.Value
			end
		end
	end

	if toolsOwned then
		local toolIcons = {}
		local improvedShovel = toolsOwned:FindFirstChild("Improved Shovel")
		local wateringCan = toolsOwned:FindFirstChild("Watering Can")
		local upgradedWateringCan = toolsOwned:FindFirstChild("UpgradedWateringCan")
		local upgradedShovel = toolsOwned:FindFirstChild("UpgradedShovel")

		if improvedShovel and improvedShovel.Value then
			table.insert(toolIcons, "⛏️" .. (upgradedShovel and upgradedShovel.Value and "⭐" or ""))
		end
		if wateringCan and wateringCan.Value then
			table.insert(toolIcons, "💧" .. (upgradedWateringCan and upgradedWateringCan.Value and "⭐" or ""))
		end

		if #toolIcons > 0 then
			toolsLabel.Text = "🛠️ Tools: " .. table.concat(toolIcons, " ")
		else
			toolsLabel.Text = "🛠️ Tools: None"
		end
	end

	-- ✅ Count all owned plots (1-16)
	local ownedPlots = 0
	local totalPlots = 16

	-- Starting Zone (Plot1-4)
	local startingZone = workspace:FindFirstChild("StartingZone")
	if startingZone then
		for i = 1, 4 do
			local plot = startingZone:FindFirstChild("Plot" .. i)
			if plot and plot:GetAttribute("Owner") == player.Name then 
				ownedPlots = ownedPlots + 1 
			end
		end
	end

	-- Expansion Zone 1 (Plot5-8)
	local expansionZone1 = workspace:FindFirstChild("ExpansionZone1")
	if expansionZone1 then
		for i = 5, 8 do
			local plot = expansionZone1:FindFirstChild("Plot" .. i)
			if plot and plot:GetAttribute("Owner") == player.Name then 
				ownedPlots = ownedPlots + 1 
			end
		end
	end

	-- Expansion Zone 2 (Plot9-12)
	local expansionZone2 = workspace:FindFirstChild("ExpansionZone2")
	if expansionZone2 then
		for i = 9, 12 do
			local plot = expansionZone2:FindFirstChild("Plot" .. i)
			if plot and plot:GetAttribute("Owner") == player.Name then 
				ownedPlots = ownedPlots + 1 
			end
		end
	end

	-- Expansion Zone 3 (Plot13-16)
	local expansionZone3 = workspace:FindFirstChild("ExpansionZone3")
	if expansionZone3 then
		for i = 13, 16 do
			local plot = expansionZone3:FindFirstChild("Plot" .. i)
			if plot and plot:GetAttribute("Owner") == player.Name then 
				ownedPlots = ownedPlots + 1 
			end
		end
	end

	plotLabel.Text = "🟫 Plots: " .. ownedPlots .. "/" .. totalPlots
end

local currentCategory = "TotalEarned"

-- ✅ Get owned animals as compact list (icon + count)
local function getAnimalsList(userId)
	-- Try to find player in game
	local targetPlayer = nil
	for _, p in ipairs(Players:GetPlayers()) do
		if p.UserId == userId then
			targetPlayer = p
			break
		end
	end

	if not targetPlayer then
		return nil  -- Player not in this server, will show total number instead
	end

	local animalCounts = {}
	local poultryOwned = targetPlayer:FindFirstChild("PoultryOwned")

	if poultryOwned then
		if poultryOwned:FindFirstChild("Chicken") and poultryOwned.Chicken.Value then
			table.insert(animalCounts, "🐔1")
		end
		if poultryOwned:FindFirstChild("Cow") and poultryOwned.Cow.Value then
			table.insert(animalCounts, "🐮1")
		end
		if poultryOwned:FindFirstChild("Pig") and poultryOwned.Pig.Value then
			table.insert(animalCounts, "🐷1")
		end
		if poultryOwned:FindFirstChild("Sheep") and poultryOwned.Sheep.Value then
			table.insert(animalCounts, "🐑1")
		end
	end

	-- Add beehives with count
	local beehiveCount = targetPlayer:FindFirstChild("BeehiveCount")
	if beehiveCount and beehiveCount.Value > 0 then
		table.insert(animalCounts, "🐝" .. beehiveCount.Value)
	end

	return #animalCounts > 0 and table.concat(animalCounts, " ") or "None"
end


local function updateLeaderboard()
	-- Clear existing entries
	for _, child in ipairs(leaderboardScroll:GetChildren()) do
		if child:IsA("Frame") then
			child:Destroy()
		end
	end

	-- Fetch data from server
	local success, leaderboardData = pcall(function()
		return game:GetService("ReplicatedStorage"):WaitForChild("GetLeaderboard"):InvokeServer(currentCategory)
	end)

	if not success or not leaderboardData then
		warn("Failed to fetch leaderboard")
		return
	end

	-- Display entries
	local yPos = 5
	for _, entry in ipairs(leaderboardData) do
		local row = Instance.new("Frame")
		row.Size = UDim2.new(1, -10, 0, 40)
		row.Position = UDim2.new(0, 5, 0, yPos)
		row.BackgroundColor3 = entry.Rank <= 3 and Color3.fromRGB(80, 70, 50) or Color3.fromRGB(50, 50, 50)
		row.BorderSizePixel = 0
		row.ZIndex = 7
		row.Parent = leaderboardScroll

		local rowCorner = Instance.new("UICorner")
		rowCorner.CornerRadius = UDim.new(0, 6)
		rowCorner.Parent = row

		-- Rank
		local rankLabel = Instance.new("TextLabel")
		rankLabel.Size = UDim2.new(0.15, 0, 1, 0)
		rankLabel.Position = UDim2.new(0, 5, 0, 0)
		rankLabel.BackgroundTransparency = 1
		rankLabel.Text = entry.Rank == 1 and "🥇" or entry.Rank == 2 and "🥈" or entry.Rank == 3 and "🥉" or "#" .. entry.Rank
		rankLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
		rankLabel.TextScaled = true
		rankLabel.Font = Enum.Font.GothamBold
		rankLabel.ZIndex = 8
		rankLabel.Parent = row

		-- Name (smaller text)
		local nameLabel = Instance.new("TextLabel")
		nameLabel.Size = UDim2.new(0.5, 0, 1, 0)
		nameLabel.Position = UDim2.new(0.15, 0, 0, 0)
		nameLabel.BackgroundTransparency = 1
		nameLabel.Text = entry.Name
		nameLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
		nameLabel.TextSize = isMobile and 14 or 16  -- ✅ Fixed size instead of scaled
		nameLabel.Font = Enum.Font.Gotham
		nameLabel.TextXAlignment = Enum.TextXAlignment.Left
		nameLabel.TextTruncate = Enum.TextTruncate.AtEnd
		nameLabel.ZIndex = 8
		nameLabel.Parent = row
		
		-- Value
		local valueLabel = Instance.new("TextLabel")
		valueLabel.Size = UDim2.new(0.35, -10, 1, 0)
		valueLabel.Position = UDim2.new(0.65, 0, 0, 0)
		valueLabel.BackgroundTransparency = 1

		-- ✅ Show animals list if AnimalsOwned category, otherwise show number
		if currentCategory == "AnimalsOwned" then
			local animalsList = getAnimalsList(entry.UserId)
			valueLabel.Text = animalsList or tostring(entry.Value)
			valueLabel.TextSize = isMobile and 16 or 18  -- ✅ Larger size for bigger emojis
			valueLabel.Font = Enum.Font.Gotham  -- ✅ Regular font (not bold) for better emoji rendering
		else
			valueLabel.Text = tostring(entry.Value)
			valueLabel.TextSize = isMobile and 14 or 16
			valueLabel.Font = Enum.Font.GothamBold  -- Keep bold for numbers
		end

		valueLabel.TextColor3 = Color3.fromRGB(100, 255, 100)
		valueLabel.TextXAlignment = Enum.TextXAlignment.Right
		valueLabel.ZIndex = 8
		valueLabel.Parent = row



		-- ✅ Add padding to push text away from edge
		local valuePadding = Instance.new("UIPadding")
		valuePadding.PaddingRight = UDim.new(0, 8)  -- 8px from right edge
		valuePadding.Parent = valueLabel



		yPos = yPos + 45
	end

	leaderboardScroll.CanvasSize = UDim2.new(0, 0, 0, yPos)
end

-- Category button handlers
for cat, btn in pairs(categoryButtons) do
	btn.MouseButton1Click:Connect(function()
		currentCategory = cat

		-- Update button colors
		for c, b in pairs(categoryButtons) do
			b.BackgroundColor3 = c == cat and Color3.fromRGB(100, 150, 100) or Color3.fromRGB(60, 60, 60)
		end

		updateLeaderboard()
	end)
end


local function toggleStats()
	showStats = not showStats

	if showStats and showQuests then
		showQuests = false
		questsFrame.Visible = false
		questsIcon.Text = "📜"
	end

	statsFrame.Visible = showStats
	statsIcon.Text = showStats and "❌" or "💰"

	if autoHideThread then
		task.cancel(autoHideThread)
		autoHideThread = nil
	end

	if showStats and isMobile then
		autoHideThread = task.delay(5, function()
			showStats = false
			statsFrame.Visible = false
			statsIcon.Text = "💰"
			autoHideThread = nil
		end)
	end
end

local function toggleQuests()
	showQuests = not showQuests

	if showQuests then
		showStats = false
		statsFrame.Visible = false
		statsIcon.Text = "💰"
	end

	questsFrame.Visible = showQuests
	questsIcon.Text = showQuests and "❌" or "📜"

	if autoHideThread then
		task.cancel(autoHideThread)
		autoHideThread = nil
	end

	if showQuests and isMobile then
		autoHideThread = task.delay(5, function()
			showQuests = false
			questsFrame.Visible = false
			questsIcon.Text = "📜"
			autoHideThread = nil
		end)
	end
end

local showLeaderboard = false

local function toggleLeaderboard()
	showLeaderboard = not showLeaderboard

	-- Hide other panels
	if showLeaderboard then
		showStats = false
		showQuests = false
		statsFrame.Visible = false
		questsFrame.Visible = false
		statsIcon.Text = "💰"
		questsIcon.Text = "📜"

		updateLeaderboard()
	end

	leaderboardFrame.Visible = showLeaderboard
	leaderboardOverlay.Visible = showLeaderboard  -- ✅ Show/hide overlay
	leaderboardIcon.Text = showLeaderboard and "❌" or "🏆"

	-- Mobile auto-hide
	if autoHideThread then
		task.cancel(autoHideThread)
		autoHideThread = nil
	end

	if showLeaderboard and isMobile then
		autoHideThread = task.delay(8, function()  -- Longer timeout for centered popup
			showLeaderboard = false
			leaderboardFrame.Visible = false
			leaderboardOverlay.Visible = false
			leaderboardIcon.Text = "🏆"
			autoHideThread = nil
		end)
	end
end


leaderboardButton.MouseButton1Click:Connect(toggleLeaderboard)
questsButton.MouseButton1Click:Connect(toggleQuests)
statsButton.MouseButton1Click:Connect(toggleStats)
journalButton.MouseButton1Click:Connect(function()
	-- Fire BindableEvent instead of accessing FarmJournalGUI directly
	local ReplicatedStorage = game:GetService("ReplicatedStorage")
	local openJournalEvent = ReplicatedStorage:FindFirstChild("OpenJournalEvent")

	if openJournalEvent and openJournalEvent:IsA("BindableEvent") then
		openJournalEvent:Fire()
	end
end)



-- ✅ Close button uses toggle function (syncs state properly)
closeButton.MouseButton1Click:Connect(function()
	toggleLeaderboard()  -- Uses the same toggle logic
end)

task.spawn(function()
	repeat task.wait(0.1) until player:FindFirstChild("leaderstats")
	local leaderstats = player.leaderstats
	leaderstats.Cash.Changed:Connect(updateStats)

	repeat task.wait(0.1) until player:FindFirstChild("SeedInventory")
	for _, seed in pairs(player.SeedInventory:GetChildren()) do
		if seed:IsA("IntValue") then seed.Changed:Connect(updateStats) end
	end

	repeat task.wait(0.1) until player:FindFirstChild("CropInventory")
	for _, crop in pairs(player.CropInventory:GetChildren()) do
		if crop:IsA("IntValue") then crop.Changed:Connect(updateStats) end
	end

	repeat task.wait(0.1) until player:FindFirstChild("ToolsOwned")
	for _, tool in pairs(player.ToolsOwned:GetChildren()) do
		if tool:IsA("BoolValue") then 
			tool.Changed:Connect(updateStats)
		end
	end

	repeat task.wait(0.1) until player:FindFirstChild("TotalEarned")

	task.wait(0.5)
	updateStats()
end)

task.spawn(function()
	while true do
		updateStats()
		task.wait(1)
	end
end)

print("✅ CombinedHUD loaded (responsive + progress overlay)! Mobile:", isMobile)
