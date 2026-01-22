local MarketplaceService = game:GetService("MarketplaceService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local RobuxClient = {}

-- Create a Robux button next to a cash button
function RobuxClient.createRobuxButton(itemName, cashButton, robuxPrice, productId)
	local robuxBtn = Instance.new("TextButton")

	-- Position next to cash button
	robuxBtn.Size = cashButton.Size
	robuxBtn.Position = UDim2.new(
		cashButton.Position.X.Scale + cashButton.Size.X.Scale + 0.02,  -- 2% gap
		0,
		cashButton.Position.Y.Scale,
		cashButton.Position.Y.Offset
	)

	-- Roblox blue color
	robuxBtn.BackgroundColor3 = Color3.fromRGB(0, 170, 255)
	robuxBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
	robuxBtn.Text = "💎 " .. robuxPrice
	robuxBtn.TextScaled = true
	robuxBtn.Font = Enum.Font.GothamBold
	robuxBtn.Parent = cashButton.Parent

	-- Corner radius (match cash button)
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 6)
	corner.Parent = robuxBtn

	-- Purchase on click
	robuxBtn.MouseButton1Click:Connect(function()
		MarketplaceService:PromptProductPurchase(Players.LocalPlayer, productId)
	end)

	return robuxBtn
end

return RobuxClient
