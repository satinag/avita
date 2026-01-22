-- ServerScriptService/ToolStore
-- Handles Tool Store GUI and interactions

local ProductConfig = require(game:GetService("ReplicatedStorage"):WaitForChild("ProductConfig"))

local SoundManager
pcall(function() SoundManager = require(game:GetService("ReplicatedStorage"):WaitForChild("SoundManager", 2)) end)

local UserInputService = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

print("🔧 Tool Store loaded!")

-- ✅ Load Robux products config
local Products
pcall(function()
	Products = require(game:GetService("ServerScriptService"):WaitForChild("RobuxProducts"))
end)

-- Tool prices and effects
local TOOLS = ProductConfig.GetAllTools()

-- ============================================
-- HELPERS
-- ============================================

local function isMobile()
	return UserInputService.TouchEnabled and not UserInputService.KeyboardEnabled
end

local function hasTool(player, toolName)
	local toolsOwned = player:FindFirstChild("ToolsOwned")
	if not toolsOwned then return false end
	local tool = toolsOwned:FindFirstChild(toolName)
	return tool and tool.Value
end

local function meetsUnlockRequirement(player, tool)
	if not tool.UnlockTotalEarned then return true end
	local totalEarned = player:FindFirstChild("TotalEarned")
	if not totalEarned then return false end
	return totalEarned.Value >= tool.UnlockTotalEarned
end

local function findUpgradeFor(baseTool)
	for _, tool in ipairs(TOOLS) do
		if tool.Prereq == baseTool.Name then
			return tool
		end
	end
	return nil
end

local function getToolHeight(owned, upgrade, upgradeOwned, mobile)
	local textHeight = mobile and 50 or 45
	local buttonHeight = mobile and 32 or 28
	local totalButtonHeight = (buttonHeight * 2) + 4 + 16
	return math.max(textHeight, totalButtonHeight)
end

-- ============================================
-- GUI CREATION
-- ============================================

local function createToolShopGUI(player)
	local existingGui = player.PlayerGui:FindFirstChild("ToolShopGui")
	if existingGui then existingGui:Destroy() end

	local gui = Instance.new("ScreenGui")
	gui.Name = "ToolShopGui"
	gui.ResetOnSpawn = false
	gui.IgnoreGuiInset = true

	local camera = workspace.CurrentCamera
	local viewportSize = camera.ViewportSize
	local isNarrowScreen = viewportSize.X < 900
	local mobile = isNarrowScreen
	local frameWidth = isNarrowScreen and 0.98 or 0.50
	local frameHeight = isNarrowScreen and 0.90 or 0.75

	local frame = Instance.new("Frame")
	frame.Size = UDim2.new(frameWidth, 0, frameHeight, 0)
	frame.Position = UDim2.new(0.5, 0, 0.5, 0)
	frame.AnchorPoint = Vector2.new(0.5, 0.5)
	frame.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
	frame.BorderSizePixel = 0
	frame.Parent = gui

	local frameCorner = Instance.new("UICorner")
	frameCorner.CornerRadius = UDim.new(0, 12)
	frameCorner.Parent = frame

	local title = Instance.new("TextLabel")
	title.Size = UDim2.new(1, 0, 0, mobile and 60 or 50)
	title.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
	title.Text = "🔧 Tool Store"
	title.TextColor3 = Color3.fromRGB(255, 255, 255)
	title.TextScaled = true
	title.Font = Enum.Font.GothamBold
	title.Parent = frame

	local titleCorner = Instance.new("UICorner")
	titleCorner.CornerRadius = UDim.new(0, 12)
	titleCorner.Parent = title

	local titlePadding = Instance.new("UIPadding")
	titlePadding.PaddingLeft = UDim.new(0, 10)
	titlePadding.PaddingRight = UDim.new(0, 10)
	titlePadding.Parent = title

	local closeButton = Instance.new("TextButton")
	closeButton.Size = UDim2.new(0, 40, 0, 40)
	closeButton.Position = UDim2.new(1, -45, 0, 5)
	closeButton.BackgroundColor3 = Color3.fromRGB(200, 100, 100)
	closeButton.Text = "X"
	closeButton.TextColor3 = Color3.fromRGB(255, 255, 255)
	closeButton.TextScaled = true
	closeButton.Font = Enum.Font.GothamBold
	closeButton.Parent = frame

	local closeCorner = Instance.new("UICorner")
	closeCorner.CornerRadius = UDim.new(1, 0)
	closeCorner.Parent = closeButton

	closeButton.MouseButton1Click:Connect(function()
		gui:Destroy()
	end)

	local titleHeight = mobile and 60 or 50

	local scrollFrame = Instance.new("ScrollingFrame")
	scrollFrame.Size = UDim2.new(1, -20, 1, -(titleHeight + 20))
	scrollFrame.Position = UDim2.new(0, 10, 0, titleHeight + 10)
	scrollFrame.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
	scrollFrame.BorderSizePixel = 0
	scrollFrame.ScrollBarThickness = mobile and 12 or 8
	scrollFrame.Parent = frame

	local scrollCorner = Instance.new("UICorner")
	scrollCorner.CornerRadius = UDim.new(0, 8)
	scrollCorner.Parent = scrollFrame

	local yPos = 10

	for _, tool in ipairs(TOOLS) do
		if tool.IsUpgrade then continue end

		local owned = hasTool(player, tool.Name)
		local upgrade = findUpgradeFor(tool)
		local upgradeOwned = upgrade and hasTool(player, upgrade.Name)
		local frameHeight = getToolHeight(owned, upgrade ~= nil, upgrade and upgradeOwned or false, mobile)

		local toolFrame = Instance.new("Frame")
		toolFrame.Size = UDim2.new(0.95, 0, 0, frameHeight)
		toolFrame.Position = UDim2.new(0.025, 0, 0, yPos)
		toolFrame.BackgroundColor3 = owned and Color3.fromRGB(50, 100, 50) or Color3.fromRGB(70, 70, 70)
		toolFrame.BorderSizePixel = 0
		toolFrame.Parent = scrollFrame

		local toolCorner = Instance.new("UICorner")
		toolCorner.CornerRadius = UDim.new(0, 8)
		toolCorner.Parent = toolFrame

		local nameLabel = Instance.new("TextLabel")
		nameLabel.Size = UDim2.new(0.9, 0, 0, mobile and 30 or 25)
		nameLabel.Position = UDim2.new(0.05, 0, 0, 8)
		nameLabel.BackgroundTransparency = 1
		nameLabel.Text = tool.Icon .. " " .. tool.DisplayName
		nameLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
		nameLabel.TextScaled = true
		nameLabel.Font = Enum.Font.GothamBold
		nameLabel.TextXAlignment = Enum.TextXAlignment.Left
		nameLabel.Parent = toolFrame

		local namePadding = Instance.new("UIPadding")
		namePadding.PaddingLeft = UDim.new(0, 5)
		namePadding.PaddingRight = UDim.new(0, 5)
		namePadding.Parent = nameLabel

		local descLabel = Instance.new("TextLabel")
		descLabel.Size = UDim2.new(0.9, 0, 0, mobile and 20 or 18)
		descLabel.Position = UDim2.new(0.05, 0, 0, mobile and 42 or 37)
		descLabel.BackgroundTransparency = 1
		descLabel.Text = tool.Description
		descLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
		descLabel.TextScaled = true
		descLabel.Font = Enum.Font.Gotham
		descLabel.TextXAlignment = Enum.TextXAlignment.Left
		descLabel.Parent = toolFrame

		local descPadding = Instance.new("UIPadding")
		descPadding.PaddingLeft = UDim.new(0, 5)
		descPadding.PaddingRight = UDim.new(0, 5)
		descPadding.Parent = descLabel

		if upgrade and owned and not upgradeOwned then
			local upgradeInfoLabel = Instance.new("TextLabel")
			upgradeInfoLabel.Size = UDim2.new(0.9, 0, 0, mobile and 18 or 16)
			upgradeInfoLabel.Position = UDim2.new(0.05, 0, 0, mobile and 66 or 58)
			upgradeInfoLabel.BackgroundTransparency = 1
			upgradeInfoLabel.Text = "⭐ Upgrade: " .. upgrade.Description .. " ($" .. upgrade.Price .. ")"
			upgradeInfoLabel.TextColor3 = Color3.fromRGB(255, 215, 0)
			upgradeInfoLabel.TextScaled = true
			upgradeInfoLabel.Font = Enum.Font.GothamBold
			upgradeInfoLabel.TextXAlignment = Enum.TextXAlignment.Left
			upgradeInfoLabel.Parent = toolFrame

			local upgradeInfoPadding = Instance.new("UIPadding")
			upgradeInfoPadding.PaddingLeft = UDim.new(0, 5)
			upgradeInfoPadding.PaddingRight = UDim.new(0, 5)
			upgradeInfoPadding.Parent = upgradeInfoLabel
		end

		-- ✅ BUTTONS: Cash on left, Robux on right
		local buttonWidth = mobile and 0.17 or 0.16
		local buttonHeight = mobile and 32 or 28
		local buttonSpacing = 4
		local buttonStartY = mobile and 10 or 8

		if owned then
			-- OWNED label (top row)
			local ownedLabel = Instance.new("TextLabel")
			ownedLabel.Size = UDim2.new(buttonWidth * 2 + 0.02, 0, 0, buttonHeight)
			ownedLabel.Position = UDim2.new(0.63, 0, 0, buttonStartY)
			ownedLabel.BackgroundColor3 = Color3.fromRGB(100, 200, 100)
			ownedLabel.Text = "✅ OWNED"
			ownedLabel.TextColor3 = Color3.fromRGB(0, 0, 0)
			ownedLabel.TextScaled = true
			ownedLabel.Font = Enum.Font.GothamBold
			ownedLabel.Parent = toolFrame

			local ownedCorner = Instance.new("UICorner")
			ownedCorner.CornerRadius = UDim.new(0, 6)
			ownedCorner.Parent = ownedLabel

			-- ✅ UPGRADE BUTTONS (bottom row)
			if upgrade and not upgradeOwned then
				-- Cash upgrade button
				local upgradeCashBtn = Instance.new("TextButton")
				upgradeCashBtn.Size = UDim2.new(buttonWidth, 0, 0, buttonHeight)
				upgradeCashBtn.Position = UDim2.new(0.63, 0, 0, buttonStartY + buttonHeight + buttonSpacing)
				upgradeCashBtn.BackgroundColor3 = Color3.fromRGB(255, 215, 0)
				upgradeCashBtn.Text = "💰 $" .. upgrade.Price
				upgradeCashBtn.TextColor3 = Color3.fromRGB(0, 0, 0)
				upgradeCashBtn.TextScaled = true
				upgradeCashBtn.Font = Enum.Font.GothamBold
				upgradeCashBtn.Parent = toolFrame

				local upgradeCashCorner = Instance.new("UICorner")
				upgradeCashCorner.CornerRadius = UDim.new(0, 6)
				upgradeCashCorner.Parent = upgradeCashBtn

				upgradeCashBtn.MouseButton1Click:Connect(function()
					local cash = player.leaderstats:FindFirstChild("Cash")
					if cash and cash.Value >= upgrade.Price then
						cash.Value = cash.Value - upgrade.Price

						_G.TrackStat(player, "TotalCashSpent", upgrade.Price)
						_G.TrackStat(player, "MoneySpentOnTools", upgrade.Price)

						local toolsOwned = player:FindFirstChild("ToolsOwned")
						if toolsOwned then
							-- ✅ Use upgrade.Name directly (no space removal)
							local upgradeValue = toolsOwned:FindFirstChild(upgrade.Name)
							if upgradeValue then
								upgradeValue.Value = true
								if SoundManager then 
									pcall(function() SoundManager:PlaySoundForPlayer(player, "PurchaseSound") end) 
								end
								gui:Destroy()
								createToolShopGUI(player)
							else
								warn("❌ Upgrade field not found: " .. upgrade.Name)
							end
						end
					end
				end)

				-- ✅ Robux upgrade button
				if Products and Products[upgrade.DisplayName] then
					task.spawn(function()
						local productData = Products[upgrade.DisplayName]

						local upgradeRobuxBtn = Instance.new("TextButton")
						upgradeRobuxBtn.Size = UDim2.new(buttonWidth, 0, 0, buttonHeight)
						upgradeRobuxBtn.Position = UDim2.new(0.63 + buttonWidth + 0.02, 0, 0, buttonStartY + buttonHeight + buttonSpacing)
						upgradeRobuxBtn.BackgroundColor3 = Color3.fromRGB(0, 170, 255)
						upgradeRobuxBtn.Text = "\u{E002} " .. productData.RobuxPrice
						upgradeRobuxBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
						upgradeRobuxBtn.TextScaled = true
						upgradeRobuxBtn.Font = Enum.Font.GothamBold
						upgradeRobuxBtn.Parent = toolFrame

						local upgradeRobuxCorner = Instance.new("UICorner")
						upgradeRobuxCorner.CornerRadius = UDim.new(0, 6)
						upgradeRobuxCorner.Parent = upgradeRobuxBtn

						upgradeRobuxBtn.MouseButton1Click:Connect(function()
							game:GetService("MarketplaceService"):PromptProductPurchase(player, productData.ProductId)
						end)
					end)
				end

			elseif upgrade and upgradeOwned then
				local upgradeOwnedLabel = Instance.new("TextLabel")
				upgradeOwnedLabel.Size = UDim2.new(buttonWidth * 2 + 0.02, 0, 0, buttonHeight)
				upgradeOwnedLabel.Position = UDim2.new(0.63, 0, 0, buttonStartY + buttonHeight + buttonSpacing)
				upgradeOwnedLabel.BackgroundColor3 = Color3.fromRGB(255, 215, 0)
				upgradeOwnedLabel.Text = "⭐ MAX"
				upgradeOwnedLabel.TextColor3 = Color3.fromRGB(0, 0, 0)
				upgradeOwnedLabel.TextScaled = true
				upgradeOwnedLabel.Font = Enum.Font.GothamBold
				upgradeOwnedLabel.Parent = toolFrame

				local upgradeOwnedCorner = Instance.new("UICorner")
				upgradeOwnedCorner.CornerRadius = UDim.new(0, 6)
				upgradeOwnedCorner.Parent = upgradeOwnedLabel
			end
		else
			-- ✅ BASE TOOL BUY BUTTONS
			local buyCashBtn = Instance.new("TextButton")
			buyCashBtn.Size = UDim2.new(buttonWidth, 0, 0, buttonHeight)
			buyCashBtn.Position = UDim2.new(0.63, 0, 0, buttonStartY)
			buyCashBtn.BackgroundColor3 = Color3.fromRGB(100, 200, 100)
			buyCashBtn.Text = "💰 $" .. tool.Price
			buyCashBtn.TextColor3 = Color3.fromRGB(0, 0, 0)
			buyCashBtn.TextScaled = true
			buyCashBtn.Font = Enum.Font.GothamBold
			buyCashBtn.Parent = toolFrame

			local buyCashCorner = Instance.new("UICorner")
			buyCashCorner.CornerRadius = UDim.new(0, 6)
			buyCashCorner.Parent = buyCashBtn

			buyCashBtn.MouseButton1Click:Connect(function()
				local cash = player.leaderstats:FindFirstChild("Cash")
				if cash and cash.Value >= tool.Price then
					cash.Value = cash.Value - tool.Price

					_G.TrackStat(player, "TotalCashSpent", tool.Price)
					_G.TrackStat(player, "MoneySpentOnTools", tool.Price)

					local toolsOwned = player:FindFirstChild("ToolsOwned")
					if toolsOwned then
						-- ✅ Use tool.Name directly (no space removal)
						local toolValue = toolsOwned:FindFirstChild(tool.Name)
						if toolValue then
							toolValue.Value = true
							if SoundManager then 
								pcall(function() SoundManager:PlaySoundForPlayer(player, "PurchaseSound") end) 
							end
							gui:Destroy()
							createToolShopGUI(player)
						else
							warn("❌ Tool field not found: " .. tool.Name)
						end
					end
				end
			end)

			-- ✅ Robux button (use DisplayName for lookup)
			if Products and Products[tool.DisplayName] then
				task.spawn(function()
					local productData = Products[tool.DisplayName]

					local buyRobuxBtn = Instance.new("TextButton")
					buyRobuxBtn.Size = UDim2.new(buttonWidth, 0, 0, buttonHeight)
					buyRobuxBtn.Position = UDim2.new(0.63 + buttonWidth + 0.02, 0, 0, buttonStartY)
					buyRobuxBtn.BackgroundColor3 = Color3.fromRGB(0, 170, 255)
					buyRobuxBtn.Text = "\u{E002} " .. productData.RobuxPrice
					buyRobuxBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
					buyRobuxBtn.TextScaled = true
					buyRobuxBtn.Font = Enum.Font.GothamBold
					buyRobuxBtn.Parent = toolFrame

					local buyRobuxCorner = Instance.new("UICorner")
					buyRobuxCorner.CornerRadius = UDim.new(0, 6)
					buyRobuxCorner.Parent = buyRobuxBtn

					buyRobuxBtn.MouseButton1Click:Connect(function()
						game:GetService("MarketplaceService"):PromptProductPurchase(player, productData.ProductId)
					end)
				end)
			end
		end

		yPos = yPos + frameHeight + 10
	end

	scrollFrame.CanvasSize = UDim2.new(0, 0, 0, yPos + 10)
	gui.Parent = player.PlayerGui
end

-- ============================================
-- PUBLIC FUNCTION
-- ============================================

_G.openToolStore = function(player)
	print(player.Name .. " opened tool store")
	createToolShopGUI(player)
end
