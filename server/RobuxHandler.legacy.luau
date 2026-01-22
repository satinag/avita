local MarketplaceService = game:GetService("MarketplaceService")
local Players = game:GetService("Players")
local Products = require(script.Parent.RobuxProducts)

-- Helper: Grant rewards based on Grant string
local function grantReward(player, grantString)
	if grantString:match("Cash%+") then
		-- Cash reward
		local amount = tonumber(grantString:match("%d+"))
		local cash = player.leaderstats:FindFirstChild("Cash")
		if cash then
			cash.Value = cash.Value + amount
			print("💰 Granted $" .. amount .. " to " .. player.Name)
		end

	elseif grantString:match("HouseLevel%+") then
		-- ✅ NEW: House upgrade
		local level = tonumber(grantString:match("%d+"))
		if _G.UpgradeHouse then
			_G.UpgradeHouse(player, level, true)  -- true = skip cost check
			print("🏠 Granted House Level " .. level .. " to " .. player.Name)
		end

	elseif grantString:match("%.") then
		-- Format: "ToolsOwned.Improved Shovel" or "PoultryOwned.Chicken"
		local folder, item = grantString:match("(.-)%.(.+)")
		local parent = player:FindFirstChild(folder)
		if parent then
			local itemValue = parent:FindFirstChild(item)
			if itemValue and itemValue:IsA("BoolValue") then
				itemValue.Value = true
				print("✅ Granted " .. item .. " to " .. player.Name)
			end
		end
	end
end

-- Process Developer Product purchases
MarketplaceService.ProcessReceipt = function(receiptInfo)
	local player = Players:GetPlayerByUserId(receiptInfo.PlayerId)
	if not player then
		return Enum.ProductPurchaseDecision.NotProcessedYet
	end

	-- Find product by ProductId
	for itemName, product in pairs(Products) do
		if product.ProductId == receiptInfo.ProductId then
			grantReward(player, product.Grant)
			print("🎉 " .. player.Name .. " purchased " .. itemName)
			return Enum.ProductPurchaseDecision.PurchaseGranted
		end
	end

	warn("⚠️ Unknown product ID: " .. receiptInfo.ProductId)
	return Enum.ProductPurchaseDecision.NotProcessedYet
end

print("💎 RobuxHandler loaded and ready")
