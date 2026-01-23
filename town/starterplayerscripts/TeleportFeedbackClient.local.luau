-- TeleportFeedbackClient.lua (Town Place)
-- Shows instant loading screen when teleporting

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local ShowTeleportScreen = ReplicatedStorage:WaitForChild("ShowTeleportScreen")

-- Create reusable loading screen
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "TeleportLoadingScreen"
screenGui.DisplayOrder = 999
screenGui.IgnoreGuiInset = true
screenGui.Enabled = false
screenGui.Parent = playerGui

local frame = Instance.new("Frame")
frame.Size = UDim2.new(1, 0, 1, 0)
frame.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
frame.BackgroundTransparency = 0.3
frame.BorderSizePixel = 0
frame.Parent = screenGui

local messageLabel = Instance.new("TextLabel")
messageLabel.Size = UDim2.new(0, 400, 0, 100)
messageLabel.Position = UDim2.new(0.5, -200, 0.5, -50)
messageLabel.BackgroundColor3 = Color3.fromRGB(30, 30, 35)
messageLabel.BorderSizePixel = 0
messageLabel.Text = "Loading..."
messageLabel.TextColor3 = Color3.new(1, 1, 1)
messageLabel.TextSize = 24
messageLabel.Font = Enum.Font.GothamBold
messageLabel.TextWrapped = true
messageLabel.Parent = frame

local corner = Instance.new("UICorner")
corner.CornerRadius = UDim.new(0, 12)
corner.Parent = messageLabel

-- Spinning animation
local spinner = Instance.new("ImageLabel")
spinner.Size = UDim2.new(0, 40, 0, 40)
spinner.Position = UDim2.new(0.5, -20, 0, -60)
spinner.BackgroundTransparency = 1
spinner.Image = "rbxasset://textures/ui/LoadingCircle.png"
spinner.Parent = messageLabel

-- Spin animation
local rotating = false
local function startSpinner()
	rotating = true
	task.spawn(function()
		while rotating do
			for i = 0, 360, 10 do
				if not rotating then break end
				spinner.Rotation = i
				task.wait(0.03)
			end
		end
	end)
end

local function stopSpinner()
	rotating = false
end

-- Listen for server trigger
ShowTeleportScreen.OnClientEvent:Connect(function(message)
	messageLabel.Text = message
	screenGui.Enabled = true
	startSpinner()

	-- Auto-hide after 5 seconds (in case teleport fails)
	task.delay(5, function()
		screenGui.Enabled = false
		stopSpinner()
	end)
end)

print("✅ Teleport feedback client ready")
