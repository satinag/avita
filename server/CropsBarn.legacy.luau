-- ServerScriptService/CropsBarn
-- Handles all barn-related logic: selling, converting crops, GUI creation

local ProductConfig = require(game:GetService("ReplicatedStorage"):WaitForChild("ProductConfig"))

local SoundManager
pcall(function() SoundManager = require(game:GetService("ReplicatedStorage"):WaitForChild("SoundManager", 2)) end)

local DailyQuestManager
pcall(function() 
	DailyQuestManager = require(game:GetService("ServerScriptService"):WaitForChild("DailyQuestManager", 2)) 
end)

local ReplicatedStorage = game:GetService("ReplicatedStorage")

print("🌾 CropsBarn Manager loaded!")

-- ============================================
-- CREATE REMOTE EVENTS/FUNCTIONS (FIRST!)
-- ============================================

-- Create RemoteFunction for getting crop data
local GetCropDataFunction = ReplicatedStorage:FindFirstChild("GetCropData")
if not GetCropDataFunction then
	GetCropDataFunction = Instance.new("RemoteFunction")
	GetCropDataFunction.Name = "GetCropData"
	GetCropDataFunction.Parent = ReplicatedStorage
	print("✅ Created GetCropData RemoteFunction")
end

-- Create RemoteEvent for barn actions
local BarnActionEvent = ReplicatedStorage:FindFirstChild("BarnActionEvent")
if not BarnActionEvent then
	BarnActionEvent = Instance.new("RemoteEvent")
	BarnActionEvent.Name = "BarnActionEvent"
	BarnActionEvent.Parent = ReplicatedStorage
	print("✅ Created BarnActionEvent")
end

-- Create RemoteEvent to open barn GUI
local OpenBarnEvent = ReplicatedStorage:FindFirstChild("OpenBarnEvent")
if not OpenBarnEvent then
	OpenBarnEvent = Instance.new("RemoteEvent")
	OpenBarnEvent.Name = "OpenBarnEvent"
	OpenBarnEvent.Parent = ReplicatedStorage
	print("✅ Created OpenBarnEvent")
end

-- ============================================
-- CONSTANTS
-- ============================================

local CONVERSION_RATES = {
	Wheat = 5,
	Corn = 5,
	Carrot = 5,
	Potato = 5,
	Tomato = 5,
	Pumpkin = 5,
	Strawberry = 5,
	Watermelon = 5
}

local CROP_EMOJIS = {
	Wheat = "🌾",
	Corn = "🌽",
	Carrot = "🥕",
	Potato = "🥔",
	Tomato = "🍅",
	Pumpkin = "🎃",
	Strawberry = "🍓",
	Watermelon = "🍉"
}

local CROP_ORDER = {"Wheat", "Corn", "Carrot", "Potato", "Tomato", "Pumpkin", "Strawberry", "Watermelon"}

-- ============================================
-- HELPER FUNCTIONS
-- ============================================

local function getOwnedCrops(player)
	local cropInventory = player:FindFirstChild("CropInventory")
	if not cropInventory then return {} end

	local owned = {}
	for _, cropName in ipairs(CROP_ORDER) do
		local cropValue = cropInventory:FindFirstChild(cropName)
		if cropValue and cropValue.Value > 0 then
			table.insert(owned, {
				Name = cropName, 
				Count = cropValue.Value, 
				Price = ProductConfig.GetSellPrice(cropName),  -- ✅ Use ProductConfig
				Emoji = CROP_EMOJIS[cropName]
			})
		end
	end
	return owned
end

-- ============================================
-- BUSINESS LOGIC FUNCTIONS
-- ============================================

_G.SellCrop = function(player, cropName)
	local leaderstats = player:FindFirstChild("leaderstats")
	local cash = leaderstats and leaderstats:FindFirstChild("Cash")
	local totalEarned = player:FindFirstChild("TotalEarned")
	local cropInventory = player:FindFirstChild("CropInventory")
	local cropValue = cropInventory and cropInventory:FindFirstChild(cropName)

	if not cropValue or cropValue.Value <= 0 then
		return false, 0, "No " .. cropName .. " to sell"
	end

	if not cash then
		return false, 0, "No cash value found"
	end

	local amountSold = cropValue.Value
	local pricePerCrop = ProductConfig.GetSellPrice(cropName)  -- ✅ Use ProductConfig
	local earnings = amountSold * pricePerCrop

	cash.Value = cash.Value + earnings

	if totalEarned then 
		totalEarned.Value = totalEarned.Value + earnings
	end

	cropValue.Value = 0

	print(player.Name .. " sold " .. amountSold .. " " .. cropName .. " for $" .. earnings .. " cash!")

	_G.TrackStat(player, "TotalCashEarned", earnings)
	_G.TrackStat(player, "TotalCropsSold", amountSold)

	if DailyQuestManager then
		DailyQuestManager:UpdateProgress(player, "Sell", {Amount = amountSold})
	end

	-- Tutorial: Complete level 6 (Sell at Barn)
	if _G.CompleteTutorialLevel then
		local currentLevel = player:FindFirstChild("CurrentArrowLevel")
		if currentLevel and currentLevel.Value == 6 then
			print("🎯 Completing tutorial level 6 - Sold crops")
			_G.CompleteTutorialLevel(player, 6)
		end
	end


	if SoundManager then
		pcall(function() 
			SoundManager:PlaySoundForPlayer(player, "CoinSound") 
		end)
	end

	return true, earnings, "Sold " .. amountSold .. " " .. cropName
end

_G.ConvertCrop = function(player, cropName)
	local cropInventory = player:FindFirstChild("CropInventory")
	local seedInventory = player:FindFirstChild("SeedInventory")
	local cropValue = cropInventory and cropInventory:FindFirstChild(cropName)
	local seedValue = seedInventory and seedInventory:FindFirstChild(cropName)

	if not cropValue or cropValue.Value <= 0 then
		return false, 0, "No " .. cropName .. " to convert"
	end

	if not seedValue then
		return false, 0, "Seed inventory error"
	end

	local cropsConverted = cropValue.Value
	local conversionRate = CONVERSION_RATES[cropName] or 5
	local seedsGained = cropsConverted * conversionRate

	seedValue.Value = seedValue.Value + seedsGained
	cropValue.Value = 0

	print("🌱 " .. player.Name .. " converted " .. cropsConverted .. " " .. cropName .. " into " .. seedsGained .. " seeds!")

	if DailyQuestManager then
		DailyQuestManager:UpdateProgress(player, "Sell", {Amount = cropsConverted})
	end

	if SoundManager then
		pcall(function() 
			SoundManager:PlaySoundForPlayer(player, "PurchaseSound") 
		end)
	end

	return true, seedsGained, "Converted " .. cropsConverted .. " crops to " .. seedsGained .. " seeds"
end

-- ============================================
-- GUI CREATION (CLIENT-SIDE)
-- ============================================

GetCropDataFunction.OnServerInvoke = function(player)
	return getOwnedCrops(player)
end

-- Simple function to trigger client-side GUI
_G.OpenBarnUI = function(player)
	print("🔵 SERVER: Firing OpenBarnEvent to " .. player.Name)
	OpenBarnEvent:FireClient(player)
	print("🔵 SERVER: Event fired successfully")
end

-- ============================================
-- REMOTE EVENT LISTENER (SERVER)
-- ============================================

BarnActionEvent.OnServerEvent:Connect(function(player, action, cropName)
	print("🟢 SERVER: BarnActionEvent received - Action:", action, "Crop:", cropName)

	if action == "Sell" then
		-- Sell crops
		local cropInventory = player:FindFirstChild("CropInventory")
		if not cropInventory then return end

		local cropValue = cropInventory:FindFirstChild(cropName)
		if not cropValue or cropValue.Value == 0 then
			warn("❌ Player has no " .. cropName .. " to sell")
			return
		end

		-- ✅ Use ProductConfig instead of hardcoded table
		local price = ProductConfig.GetSellPrice(cropName)
		local quantity = cropValue.Value
		local totalEarned = price * quantity

		-- Add cash
		local cash = player.leaderstats:FindFirstChild("Cash")
		if cash then
			cash.Value = cash.Value + totalEarned
			print("💰 " .. player.Name .. " sold " .. quantity .. "x " .. cropName .. " for $" .. totalEarned)
		end
		
		-- ✅ ADD THIS: Update TotalEarned (zone unlock trigger)
		local totalEarnedValue = player:FindFirstChild("TotalEarned")
		if totalEarnedValue then
			totalEarnedValue.Value = totalEarnedValue.Value + totalEarned
			print("💰 TotalEarned updated to: $" .. totalEarnedValue.Value)
		end

		-- Remove crops
		cropValue.Value = 0

		-- Track stats
		if _G.TrackStat then
			_G.TrackStat(player, "TotalCashEarned", totalEarned)
			_G.TrackStat(player, "TotalCropsSold", quantity)
		end

		-- Tutorial: Complete level 6 (Sell at Barn)
		local currentLevel = player:FindFirstChild("CurrentArrowLevel")
		print("🔍 DEBUG: CurrentArrowLevel exists:", currentLevel ~= nil)
		if currentLevel then
			print("🔍 DEBUG: CurrentArrowLevel value:", currentLevel.Value)
			if currentLevel.Value == 6 then
				print("🎯 Completing tutorial level 6 - Sold crops at barn")
				if _G.CompleteTutorialLevel then
					_G.CompleteTutorialLevel(player, 6)
				end
			end
		end



		-- Notify client
		BarnActionEvent:FireClient(player, "Sell", true, "Sold " .. quantity .. "x " .. cropName .. " for $" .. totalEarned)

	elseif action == "Convert" then
		-- Convert crops to seeds (5:1 ratio)
		local cropInventory = player:FindFirstChild("CropInventory")
		local seedInventory = player:FindFirstChild("SeedInventory")

		if not cropInventory or not seedInventory then return end

		local cropValue = cropInventory:FindFirstChild(cropName)
		local seedValue = seedInventory:FindFirstChild(cropName)

		if not cropValue or cropValue.Value < 5 then
			warn("❌ Need at least 5 " .. cropName .. " to convert")
			return
		end

		local cropsToConvert = math.floor(cropValue.Value / 5) * 5
		local seedsGained = cropsToConvert / 5

		cropValue.Value = cropValue.Value - cropsToConvert
		seedValue.Value = seedValue.Value + seedsGained

		print("🌱 " .. player.Name .. " converted " .. cropsToConvert .. "x " .. cropName .. " into " .. seedsGained .. " seeds")

		-- Notify client
		BarnActionEvent:FireClient(player, "Convert", true, "Converted " .. cropsToConvert .. " crops into " .. seedsGained .. " seeds")
	end
end)

print("✅ CropsBarn server listener ready!")
print("✅ CropsBarn ready - Server-side logic loaded")
