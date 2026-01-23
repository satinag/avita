-- GamePassInfoUI.local.lua (LocalScript)
-- Shows GamePass shop/info panel
-- Location: StarterGui.GamePassInfoUI

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local MarketplaceService = game:GetService("MarketplaceService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local GamePassConfig = require(ReplicatedStorage:WaitForChild("GamePassConfig", 10))
if not GamePassConfig then
	warn("❌ GamePassConfig not found")
	return
end

-- Create GUI
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "GamePassShopUI"
screenGui.ResetOnSpawn = false
screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
screenGui.Parent = playerGui

-- Shop button (floating)
local shopButton = Instance.new("TextButton")
shopButton.Name = "ShopButton"
shopButton.Size = UDim2.new(0, 50, 0, 50)
shopButton.Position = UDim2.new(1, -60, 0, 200)
shopButton.BackgroundColor3 = Color3.fromRGB(255, 200, 50)
shopButton.Text = "🛒"
shopButton.TextScaled = true
shopButton.Font = Enum.Font.GothamBold
shopButton.ZIndex = 10
shopButton.Parent = screenGui

local shopCorner = Instance.new("UICorner")
shopCorner.CornerRadius = UDim.new(0, 10)
shopCorner.Parent = shopButton

-- Shop panel (hidden by default)
local shopPanel = Instance.new("Frame")
shopPanel.Name = "ShopPanel"
shopPanel.Size = UDim2.new(0.5, 0, 0.6, 0)
shopPanel.Position = UDim2.new(0.25, 0, 0.2, 0)
shopPanel.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
shopPanel.BorderSizePixel = 0
shopPanel.Visible = false
shopPanel.ZIndex = 15
shopPanel.Parent = screenGui

local panelCorner = Instance.new("UICorner")
panelCorner.CornerRadius = UDim.new(0, 12)
panelCorner.Parent = shopPanel

-- Title
local title = Instance.new("TextLabel")
title.Size = UDim2.new(1, 0, 0, 50)
title.BackgroundTransparency = 1
title.Text = "🛒 GamePass Shop"
title.TextColor3 = Color3.new(1, 1, 1)
title.TextSize = 24
title.Font = Enum.Font.GothamBold
title.ZIndex = 16
title.Parent = shopPanel

-- Close button
local closeBtn = Instance.new("TextButton")
closeBtn.Size = UDim2.new(0, 40, 0, 40)
closeBtn.Position = UDim2.new(1, -45, 0, 5)
closeBtn.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
closeBtn.Text = "✖"
closeBtn.TextScaled = true
closeBtn.Font = Enum.Font.GothamBold
closeBtn.ZIndex = 17
closeBtn.Parent = shopPanel

local closeCorner = Instance.new("UICorner")
closeCorner.CornerRadius = UDim.new(0, 8)
closeCorner.Parent = closeBtn

-- Scroll frame for GamePasses
local scrollFrame = Instance.new("ScrollingFrame")
scrollFrame.Size = UDim2.new(1, -20, 1, -70)
scrollFrame.Position = UDim2.new(0, 10, 0, 60)
scrollFrame.BackgroundTransparency = 1
scrollFrame.ScrollBarThickness = 6
scrollFrame.ZIndex = 16
scrollFrame.Parent = shopPanel

-- Create GamePass cards
local yOffset = 10
for passName, passData in pairs(GamePassConfig.PASSES) do
	local card = Instance.new("Frame")
	card.Size = UDim2.new(1, -10, 0, 120)
	card.Position = UDim2.new(0, 5, 0, yOffset)
	card.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
	card.BorderSizePixel = 0
	card.ZIndex = 17
	card.Parent = scrollFrame

	local cardCorner = Instance.new("UICorner")
	cardCorner.CornerRadius = UDim.new(0, 8)
	cardCorner.Parent = card

	-- Icon
	local icon = Instance.new("TextLabel")
	icon.Size = UDim2.new(0, 60, 0, 60)
	icon.Position = UDim2.new(0, 10, 0, 10)
	icon.BackgroundTransparency = 1
	icon.Text = passData.Icon
	icon.TextScaled = true
	icon.ZIndex = 18
	icon.Parent = card

	-- Name
	local name = Instance.new("TextLabel")
	name.Size = UDim2.new(0.6, 0, 0, 30)
	name.Position = UDim2.new(0, 80, 0, 10)
	name.BackgroundTransparency = 1
	name.Text = passData.Name
	name.TextColor3 = Color3.new(1, 1, 1)
	name.TextSize = 18
	name.Font = Enum.Font.GothamBold
	name.TextXAlignment = Enum.TextXAlignment.Left
	name.ZIndex = 18
	name.Parent = card

	-- Description
	local desc = Instance.new("TextLabel")
	desc.Size = UDim2.new(0.6, 0, 0, 40)
	desc.Position = UDim2.new(0, 80, 0, 45)
	desc.BackgroundTransparency = 1
	desc.Text = passData.Description
	desc.TextColor3 = Color3.fromRGB(200, 200, 200)
	desc.TextSize = 12
	desc.Font = Enum.Font.Gotham
	desc.TextWrapped = true
	desc.TextXAlignment = Enum.TextXAlignment.Left
	desc.ZIndex = 18
	desc.Parent = card

	-- Buy button
	local buyBtn = Instance.new("TextButton")
	buyBtn.Size = UDim2.new(0, 100, 0, 35)
	buyBtn.Position = UDim2.new(1, -110, 0, 80)
	buyBtn.BackgroundColor3 = Color3.fromRGB(70, 150, 70)
	buyBtn.Text = "Buy"
	buyBtn.TextColor3 = Color3.new(1, 1, 1)
	buyBtn.TextSize = 16
	buyBtn.Font = Enum.Font.GothamBold
	buyBtn.ZIndex = 18
	buyBtn.Parent = card

	local buyCorner = Instance.new("UICorner")
	buyCorner.CornerRadius = UDim.new(0, 6)
	buyCorner.Parent = buyBtn

	-- Check if owned
	local CheckGamePassFunction = ReplicatedStorage:WaitForChild("CheckGamePassFunction", 5)
	if CheckGamePassFunction then
		local owned = CheckGamePassFunction:InvokeServer(passName)
		if owned then
			buyBtn.Text = "Owned ✓"
			buyBtn.BackgroundColor3 = Color3.fromRGB(100, 100, 100)
			buyBtn.Active = false
		end
	end

	-- Purchase action
	buyBtn.MouseButton1Click:Connect(function()
		local PromptGamePassEvent = ReplicatedStorage:FindFirstChild("PromptGamePassEvent")
		if PromptGamePassEvent then
			PromptGamePassEvent:FireServer(passName)
		end
	end)

	yOffset = yOffset + 130
end

scrollFrame.CanvasSize = UDim2.new(0, 0, 0, yOffset + 10)

-- Toggle shop
shopButton.MouseButton1Click:Connect(function()
	shopPanel.Visible = not shopPanel.Visible
end)

closeBtn.MouseButton1Click:Connect(function()
	shopPanel.Visible = false
end)

print("✅ GamePass Shop UI loaded")
