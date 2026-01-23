-- LoadingScreen in FARM place StarterGui
local Players = game:GetService("Players")
local player = Players.LocalPlayer

local screenGui = script.Parent
screenGui.ResetOnSpawn = false
screenGui.IgnoreGuiInset = true
screenGui.DisplayOrder = 100

-- Background
local background = Instance.new("Frame")
background.Size = UDim2.new(1, 0, 1, 0)
background.BackgroundColor3 = Color3.fromRGB(34, 139, 34)
background.BorderSizePixel = 0
background.Parent = screenGui

-- Loading text
local loadingText = Instance.new("TextLabel")
loadingText.Size = UDim2.new(0.8, 0, 0, 50)
loadingText.Position = UDim2.new(0.1, 0, 0.45, 0)
loadingText.BackgroundTransparency = 1
loadingText.Text = "🌾 Loading Your Farm..."
loadingText.TextColor3 = Color3.new(1, 1, 1)
loadingText.TextSize = 42
loadingText.Font = Enum.Font.GothamBold
loadingText.TextScaled = true
loadingText.Parent = background

-- Tips
local tips = {
	"💡 Plant wheat first - it's the fastest crop!",
	"💰 Higher-tier crops earn more money!",
	"🏡 Unlock new zones to expand your farm!",
	"⏰ Crops grow even when you're offline!"
}

local tipText = Instance.new("TextLabel")
tipText.Size = UDim2.new(0.8, 0, 0, 40)
tipText.Position = UDim2.new(0.1, 0, 0.55, 0)
tipText.BackgroundTransparency = 1
tipText.Text = tips[math.random(#tips)]
tipText.TextColor3 = Color3.fromRGB(220, 220, 220)
tipText.TextSize = 20
tipText.Font = Enum.Font.Gotham
tipText.TextScaled = true
tipText.Parent = background

-- Wait for farm to load
task.wait(1)
local loaded = false
local timeout = tick() + 10

while not loaded and tick() < timeout do
	if workspace:FindFirstChild("StartingZone") or workspace:FindFirstChild("Plots") then
		loaded = true
	end
	task.wait(0.3)
end

-- Fade out
task.wait(0.5)
for i = 0, 1, 0.1 do
	background.BackgroundTransparency = i
	loadingText.TextTransparency = i
	tipText.TextTransparency = i
	task.wait(0.05)
end

screenGui:Destroy()
