-- TutorialClient.local.lua (LocalScript)
-- Displays tutorial messages with animations
-- Location: StarterGui.TutorialClient (Town place)

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

-- Wait for remote event
local ShowTutorialEvent = ReplicatedStorage:WaitForChild("ShowTutorialEvent", 10)
if not ShowTutorialEvent then
	warn("❌ ShowTutorialEvent not found")
	return
end

-- ============================================
-- CREATE GUI CONTAINER
-- ============================================
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "TutorialGUI"
screenGui.ResetOnSpawn = false
screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
screenGui.Parent = playerGui

-- ============================================
-- SHOW TUTORIAL FUNCTION
-- ============================================
local currentTutorial = nil

local function showTutorial(tutorialId, data)
	-- Don't overlap tutorials
	if currentTutorial then
		currentTutorial:Destroy()
	end

	-- Create tutorial frame
	local tutorialFrame = Instance.new("Frame")
	tutorialFrame.Name = "TutorialFrame"
	tutorialFrame.Size = UDim2.new(0.4, 0, 0, 120)
	tutorialFrame.Position = UDim2.new(0.3, 0, -0.2, 0) -- Start off-screen (top)
	tutorialFrame.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
	tutorialFrame.BorderSizePixel = 0
	tutorialFrame.ZIndex = 100
	tutorialFrame.Parent = screenGui

	currentTutorial = tutorialFrame

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 12)
	corner.Parent = tutorialFrame

	-- Shadow effect
	local shadow = Instance.new("ImageLabel")
	shadow.Size = UDim2.new(1, 20, 1, 20)
	shadow.Position = UDim2.new(0, -10, 0, -10)
	shadow.BackgroundTransparency = 1
	shadow.Image = "rbxasset://textures/ui/GuiImagePlaceholder.png"
	shadow.ImageColor3 = Color3.fromRGB(0, 0, 0)
	shadow.ImageTransparency = 0.7
	shadow.ZIndex = 99
	shadow.Parent = tutorialFrame

	-- Icon
	local icon = Instance.new("TextLabel")
	icon.Size = UDim2.new(0, 50, 0, 50)
	icon.Position = UDim2.new(0, 10, 0, 10)
	icon.BackgroundTransparency = 1
	icon.Text = "💡"
	icon.TextScaled = true
	icon.ZIndex = 101
	icon.Parent = tutorialFrame

	-- Title
	local title = Instance.new("TextLabel")
	title.Size = UDim2.new(1, -70, 0, 30)
	title.Position = UDim2.new(0, 65, 0, 10)
	title.BackgroundTransparency = 1
	title.Text = data.Title or "Tutorial"
	title.TextColor3 = Color3.fromRGB(255, 255, 100)
	title.TextSize = 18
	title.Font = Enum.Font.GothamBold
	title.TextXAlignment = Enum.TextXAlignment.Left
	title.ZIndex = 101
	title.Parent = tutorialFrame

	-- Message
	local message = Instance.new("TextLabel")
	message.Size = UDim2.new(1, -70, 0, 70)
	message.Position = UDim2.new(0, 65, 0, 45)
	message.BackgroundTransparency = 1
	message.Text = data.Message or ""
	message.TextColor3 = Color3.fromRGB(220, 220, 220)
	message.TextSize = 14
	message.Font = Enum.Font.Gotham
	message.TextWrapped = true
	message.TextXAlignment = Enum.TextXAlignment.Left
	message.TextYAlignment = Enum.TextYAlignment.Top
	message.ZIndex = 101
	message.Parent = tutorialFrame

	-- Progress bar
	local progressBar = Instance.new("Frame")
	progressBar.Size = UDim2.new(1, 0, 0, 3)
	progressBar.Position = UDim2.new(0, 0, 1, -3)
	progressBar.BackgroundColor3 = Color3.fromRGB(100, 255, 100)
	progressBar.BorderSizePixel = 0
	progressBar.ZIndex = 101
	progressBar.Parent = tutorialFrame

	-- ============================================
	-- ANIMATIONS
	-- ============================================

	-- Slide in from top
	local slideIn = TweenService:Create(
		tutorialFrame,
		TweenInfo.new(0.5, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
		{Position = UDim2.new(0.3, 0, 0.05, 0)}
	)
	slideIn:Play()

	-- Progress bar countdown
	local duration = data.Duration or 5
	local progressTween = TweenService:Create(
		progressBar,
		TweenInfo.new(duration, Enum.EasingStyle.Linear),
		{Size = UDim2.new(0, 0, 0, 3)}
	)
	progressTween:Play()

	-- Slide out after duration
	task.delay(duration, function()
		local slideOut = TweenService:Create(
			tutorialFrame,
			TweenInfo.new(0.4, Enum.EasingStyle.Quad, Enum.EasingDirection.In),
			{Position = UDim2.new(0.3, 0, -0.2, 0)}
		)
		slideOut:Play()

		slideOut.Completed:Connect(function()
			tutorialFrame:Destroy()
			if currentTutorial == tutorialFrame then
				currentTutorial = nil
			end
		end)
	end)
end

-- ============================================
-- LISTEN FOR TUTORIALS
-- ============================================
ShowTutorialEvent.OnClientEvent:Connect(function(tutorialId, data)
	showTutorial(tutorialId, data)
end)

print("✅ Tutorial Client loaded")
