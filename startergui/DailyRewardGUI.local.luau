-- Daily Reward GUI Client
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local player = Players.LocalPlayer

local claimEvent = ReplicatedStorage:WaitForChild("ClaimDailyRewardEvent")

-- Create UI
local gui = script.Parent

local frame = Instance.new("Frame")
frame.Name = "RewardFrame"
frame.Size = UDim2.new(0, 400, 0, 250)
frame.Position = UDim2.new(0.5, -200, 0.5, -125)
frame.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
frame.BorderSizePixel = 3
frame.BorderColor3 = Color3.fromRGB(255, 215, 0)
frame.Visible = false
frame.Parent = gui

local title = Instance.new("TextLabel")
title.Size = UDim2.new(1, 0, 0, 50)
title.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
title.Text = "🎁 DAILY REWARD"
title.TextColor3 = Color3.fromRGB(255, 215, 0)
title.TextScaled = true
title.Font = Enum.Font.GothamBold
title.Parent = frame

local streakLabel = Instance.new("TextLabel")
streakLabel.Size = UDim2.new(1, -20, 0, 40)
streakLabel.Position = UDim2.new(0, 10, 0, 60)
streakLabel.BackgroundTransparency = 1
streakLabel.Text = "Day 1 Reward"
streakLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
streakLabel.TextScaled = true
streakLabel.Font = Enum.Font.Gotham
streakLabel.Parent = frame

local rewardLabel = Instance.new("TextLabel")
rewardLabel.Size = UDim2.new(1, -20, 0, 60)
rewardLabel.Position = UDim2.new(0, 10, 0, 110)
rewardLabel.BackgroundTransparency = 1
rewardLabel.Text = "Loading..."
rewardLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
rewardLabel.TextSize = 18
rewardLabel.Font = Enum.Font.Gotham
rewardLabel.TextWrapped = true
rewardLabel.Parent = frame

local claimButton = Instance.new("TextButton")
claimButton.Size = UDim2.new(0.8, 0, 0, 50)
claimButton.Position = UDim2.new(0.1, 0, 0, 185)
claimButton.BackgroundColor3 = Color3.fromRGB(50, 200, 50)
claimButton.Text = "CLAIM REWARD"
claimButton.TextColor3 = Color3.fromRGB(255, 255, 255)
claimButton.TextScaled = true
claimButton.Font = Enum.Font.GothamBold
claimButton.Parent = frame

-- Listen for reward availability
claimEvent.OnClientEvent:Connect(function(status, streak, description)
	if status == "available" then
		frame.Visible = true
		streakLabel.Text = "Day " .. streak .. " Reward!"
		rewardLabel.Text = description or "Claim your daily reward!"

	elseif status == "success" then
		rewardLabel.Text = "✅ " .. description
		claimButton.Text = "CLAIMED!"
		claimButton.BackgroundColor3 = Color3.fromRGB(100, 100, 100)
		claimButton.Active = false
		wait(3)
		frame.Visible = false

	elseif status == "already_claimed" then
		frame.Visible = true
		streakLabel.Text = "Day " .. streak .. " Streak"
		rewardLabel.Text = "Already claimed today!\nCome back tomorrow for Day " .. (streak % 7 + 1)
		claimButton.Text = "Come Back Tomorrow"
		claimButton.BackgroundColor3 = Color3.fromRGB(100, 100, 100)
		claimButton.Active = false
	end
end)

-- Claim button click
claimButton.MouseButton1Click:Connect(function()
	if claimButton.Active ~= false then
		claimEvent:FireServer()
	end
end)

print("🎁 Daily Reward GUI loaded!")
