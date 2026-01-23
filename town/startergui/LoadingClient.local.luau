-- TownLoadingScreen.largeImage.lua (TOWN place, LocalScript under TownLoadingScreen)

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local ContentProvider = game:GetService("ContentProvider")

local player = Players.LocalPlayer
local screenGui = script.Parent

screenGui.ResetOnSpawn = false
screenGui.IgnoreGuiInset = true
screenGui.DisplayOrder = 100
screenGui.Enabled = true

UserInputService.ModalEnabled = true

local GAME_IMAGE_ID = "rbxassetid://122204151163514"

-- FULLSCREEN BACKGROUND
local background = Instance.new("Frame")
background.Size = UDim2.new(1, 0, 1, 0)
background.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
background.BorderSizePixel = 0
background.Parent = screenGui

-- BIG IMAGE CONTAINER (TOP HALF OF SCREEN)
local imageContainer = Instance.new("Frame")
imageContainer.Name = "ImageContainer"
imageContainer.AnchorPoint = Vector2.new(0.5, 0)
imageContainer.Position = UDim2.new(0.5, 0, 0.05, 0)
imageContainer.Size = UDim2.new(0.9, 0, 0.5, 0) -- 50% of screen height
imageContainer.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
imageContainer.BorderSizePixel = 0
imageContainer.Parent = background

local imageCorner = Instance.new("UICorner")
imageCorner.CornerRadius = UDim.new(0, 16)
imageCorner.Parent = imageContainer

local imagePadding = Instance.new("UIPadding")
imagePadding.PaddingTop = UDim.new(0, 8)
imagePadding.PaddingBottom = UDim.new(0, 8)
imagePadding.PaddingLeft = UDim.new(0, 8)
imagePadding.PaddingRight = UDim.new(0, 8)
imagePadding.Parent = imageContainer

local imageAspect = Instance.new("UIAspectRatioConstraint")
imageAspect.DominantAxis = Enum.DominantAxis.Height
imageAspect.AspectRatio = 16/9  -- assume widescreen
imageAspect.Parent = imageContainer

local gameImage = Instance.new("ImageLabel")
gameImage.BackgroundTransparency = 1
gameImage.Size = UDim2.new(1, 0, 1, 0)
gameImage.Image = GAME_IMAGE_ID
gameImage.ScaleType = Enum.ScaleType.Fit
gameImage.Parent = imageContainer

-- Round the photo itself
local imageInnerCorner = Instance.new("UICorner")
imageInnerCorner.CornerRadius = UDim.new(0, 16) -- match or slightly less than container
imageInnerCorner.Parent = gameImage

ContentProvider:PreloadAsync({gameImage})

-- TEXT + BAR CONTAINER (BOTTOM)
local bottomContainer = Instance.new("Frame")
bottomContainer.AnchorPoint = Vector2.new(0.5, 0)
bottomContainer.Position = UDim2.new(0.5, 0, 0.6, 0)
bottomContainer.Size = UDim2.new(0.9, 0, 0.3, 0)
bottomContainer.BackgroundTransparency = 1
bottomContainer.Parent = background

local layout = Instance.new("UIListLayout")
layout.FillDirection = Enum.FillDirection.Vertical
layout.HorizontalAlignment = Enum.HorizontalAlignment.Center
layout.VerticalAlignment = Enum.VerticalAlignment.Top
layout.Padding = UDim.new(0, 8)
layout.Parent = bottomContainer

local title = Instance.new("TextLabel")
title.Size = UDim2.new(1, 0, 0, 50)
title.BackgroundTransparency = 1
title.Text = "🏙️ Loading Town..."
title.TextColor3 = Color3.new(1, 1, 1)
title.Font = Enum.Font.GothamBold
title.TextScaled = true
title.TextWrapped = true
title.Parent = bottomContainer

local tip = Instance.new("TextLabel")
tip.Size = UDim2.new(1, 0, 0, 40)
tip.BackgroundTransparency = 1
tip.Text = "💡 Visit shops and buildings to trade and explore."
tip.TextColor3 = Color3.fromRGB(220, 220, 220)
tip.Font = Enum.Font.Gotham
tip.TextScaled = true
tip.TextWrapped = true
tip.Parent = bottomContainer

local progressBg = Instance.new("Frame")
progressBg.Size = UDim2.new(1, 0, 0, 14)
progressBg.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
progressBg.BorderSizePixel = 0
progressBg.Parent = bottomContainer

local bgCorner = Instance.new("UICorner")
bgCorner.CornerRadius = UDim.new(0, 999)
bgCorner.Parent = progressBg

local progressBar = Instance.new("Frame")
progressBar.Size = UDim2.new(0, 0, 1, 0)
progressBar.BackgroundColor3 = Color3.fromRGB(100, 200, 100)
progressBar.BorderSizePixel = 0
progressBar.Parent = progressBg

local barCorner = Instance.new("UICorner")
barCorner.CornerRadius = UDim.new(0, 999)
barCorner.Parent = progressBar

local function setProgress(p, text)
	if text then
		title.Text = text
	end
	progressBar:TweenSize(
		UDim2.new(math.clamp(p, 0, 1), 0, 1, 0),
		Enum.EasingDirection.Out,
		Enum.EasingStyle.Quad,
		0.25,
		true
	)
end

local function waitForTownReady()
	setProgress(0.2, "Preparing Town...")
	task.wait(0.4)

	setProgress(0.4, "Loading Town buildings...")
	workspace:WaitForChild("Town", 15)

	setProgress(0.6, "Loading UI & marketplace...")
	local playerGui = player:WaitForChild("PlayerGui")
	playerGui:WaitForChild("MarketplaceGUI", 15)

	setProgress(0.8, "Almost ready...")
	task.wait(0.4)

	setProgress(1, "Welcome to Town!")
	task.wait(0.4)

	for i = 0, 1, 0.1 do
		background.BackgroundTransparency = i
		title.TextTransparency = i
		tip.TextTransparency = i
		progressBg.BackgroundTransparency = i
		progressBar.BackgroundTransparency = i
		gameImage.ImageTransparency = i
		imageContainer.BackgroundTransparency = i
		task.wait(0.05)
	end

	UserInputService.ModalEnabled = false
	screenGui:Destroy()
end

task.spawn(waitForTownReady)
