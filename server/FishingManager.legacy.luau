-- FishingManager.lua (ServerScriptService - Script)
-- Handles fishing mechanics, rarity, cooldowns, and fish product management

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

-- Load dependencies
local ProductConfig = require(ReplicatedStorage:WaitForChild("ProductConfig"))

-- Load SoundManager safely
local SoundManager
pcall(function()
	SoundManager = require(ReplicatedStorage:WaitForChild("SoundManager", 2))
end)

print("🎣 FishingManager loaded!")

-- ============================================
-- CREATE REMOTE EVENTS
-- ============================================

local GetFishDataFunction = ReplicatedStorage:FindFirstChild("GetFishData")
if not GetFishDataFunction then
	GetFishDataFunction = Instance.new("RemoteFunction")
	GetFishDataFunction.Name = "GetFishData"
	GetFishDataFunction.Parent = ReplicatedStorage
	print("✅ Created GetFishData RemoteFunction")
end

local FishActionEvent = ReplicatedStorage:FindFirstChild("FishActionEvent")
if not FishActionEvent then
	FishActionEvent = Instance.new("RemoteEvent")
	FishActionEvent.Name = "FishActionEvent"
	FishActionEvent.Parent = ReplicatedStorage
	print("✅ Created FishActionEvent")
end

local OpenFishHubEvent = ReplicatedStorage:FindFirstChild("OpenFishHubEvent")
if not OpenFishHubEvent then
	OpenFishHubEvent = Instance.new("RemoteEvent")
	OpenFishHubEvent.Name = "OpenFishHubEvent"
	OpenFishHubEvent.Parent = ReplicatedStorage
	print("✅ Created OpenFishHubEvent")
end

local OpenFishingZoneServer = ReplicatedStorage:FindFirstChild("OpenFishingZoneServer")
if not OpenFishingZoneServer then
	OpenFishingZoneServer = Instance.new("RemoteEvent")
	OpenFishingZoneServer.Name = "OpenFishingZoneServer"
	OpenFishingZoneServer.Parent = ReplicatedStorage
	print("✅ Created OpenFishingZoneServer RemoteEvent")
end

-- ============================================
-- FISHING CONFIGURATION
-- ============================================

local FISHING_CONFIG = {
	COOLDOWN_SECONDS = 60, -- 1 minute between fishing attempts
	CAST_TIME = 3, -- 3 seconds to "cast" (animation time)

	-- Fish rarity weights (total = 100)
	RARITY_WEIGHTS = {
		Salmon = 40,   -- 40% chance (Common)
		Tuna = 30,     -- 30% chance (Uncommon)
		Bass = 20,     -- 20% chance (Rare)
		Catfish = 10   -- 10% chance (Very Rare)
	}
}

-- ============================================
-- HELPER FUNCTIONS
-- ============================================

-- Check if player owns Fishing Rod
local function hasFishingRod(player)
	local toolsOwned = player:FindFirstChild("ToolsOwned")
	if not toolsOwned then return false end

	local fishingRod = toolsOwned:FindFirstChild("FishingRod")
	return fishingRod and fishingRod.Value == true
end

-- Get random fish based on rarity weights
local function getRandomFish()
	local totalWeight = 0
	for _, weight in pairs(FISHING_CONFIG.RARITY_WEIGHTS) do
		totalWeight = totalWeight + weight
	end

	local roll = math.random(1, totalWeight)
	local cumulative = 0

	for fishName, weight in pairs(FISHING_CONFIG.RARITY_WEIGHTS) do
		cumulative = cumulative + weight
		if roll <= cumulative then
			local fishInfo = ProductConfig.GetFishData(fishName)
			return fishName, fishInfo
		end
	end

	-- Fallback (shouldn't happen)
	return "Salmon", ProductConfig.GetFishData("Salmon")
end

-- Get owned fish products
local function getOwnedFish(player)
	local fishInventory = player:FindFirstChild("FishInventory")
	if not fishInventory then return {} end

	local owned = {}
	for _, fishValue in ipairs(fishInventory:GetChildren()) do
		if fishValue:IsA("IntValue") and fishValue.Value > 0 then
			local fishData = ProductConfig.GetFishData(fishValue.Name)
			table.insert(owned, {
				Name = fishValue.Name,
				Count = fishValue.Value,
				Price = fishData and fishData.SellPrice or 0,
				Icon = fishData and fishData.Icon or "🐟"
			})
		end
	end

	return owned
end

-- Sell fish
local function sellFish(player, fishName)
	local fishInventory = player:FindFirstChild("FishInventory")
	local fishValue = fishInventory and fishInventory:FindFirstChild(fishName)

	if not fishValue or fishValue.Value == 0 then
		return false, 0, "No " .. fishName .. " to sell"
	end

	local cash = player.leaderstats:FindFirstChild("Cash")
	if not cash then
		return false, 0, "No cash value found"
	end

	local amountSold = fishValue.Value

	-- ✅ FIX: Use GetFishData instead of GetProductSellPrice
	local fishData = ProductConfig.GetFishData(fishName)
	local pricePerFish = fishData and fishData.SellPrice or 0
	local earnings = amountSold * pricePerFish

	cash.Value = cash.Value + earnings
	fishValue.Value = 0

	-- Track fish selling quest
	local DailyQuestManager = require(script.Parent:WaitForChild("DailyQuestManager"))
	if DailyQuestManager then
		DailyQuestManager:UpdateProgress(player, "Sell", {Amount = amountSold})
	end

	print(player.Name .. " sold " .. amountSold .. " x " .. fishName .. " for $" .. earnings)


	if _G.TrackStat then
		_G.TrackStat(player, "TotalCashEarned", earnings)
	end

	return true, earnings, "Sold " .. amountSold .. " " .. fishName
end




-- ============================================
-- MAIN FISHING FUNCTION
-- ============================================

function _G.FishAtPond(player)
	-- Check if player owns Fishing Rod
	if not hasFishingRod(player) then
		return false, "locked", "🎣 Buy a Fishing Rod from the Tool Shop first!"
	end

	-- Check cooldown
	local lastFish = player:GetAttribute("LastFishTime") or 0
	local currentTime = os.time()

	if (currentTime - lastFish) < FISHING_CONFIG.COOLDOWN_SECONDS then
		local remaining = FISHING_CONFIG.COOLDOWN_SECONDS - (currentTime - lastFish)
		return false, "cooldown", remaining
	end

	-- Random fish selection
	local fishName, fishInfo = getRandomFish()

	-- Add to fish inventory
	local fishInventory = player:FindFirstChild("FishInventory")
	if not fishInventory then
		return false, "error", "No fish inventory"
	end

	local fishValue = fishInventory:FindFirstChild(fishName)
	if not fishValue then
		return false, "error", "Fish type not found: " .. fishName
	end

	-- Add 1 fish
	fishValue.Value = fishValue.Value + 1
	
	-- Track daily quest progress
	local DailyQuestManager = require(script.Parent:WaitForChild("DailyQuestManager"))
	if DailyQuestManager then
		local fishInfo = ProductConfig.GetFishData(fishName)
		local rarity = fishInfo and fishInfo.Rarity or "Common"

		DailyQuestManager:UpdateFishCatch(player, fishName, rarity, 1)
		print("📝 Tracked fish catch for quests: " .. fishName .. " (" .. rarity .. ")")

		-- Also track for mixed quests
		DailyQuestManager:UpdateMixedQuest(player, "CatchFish", 1)
	end


	-- Set cooldown
	player:SetAttribute("LastFishTime", currentTime)

	-- Track stats
	if _G.TrackStat then
		_G.TrackStat(player, "TotalFishCaught", 1)
		_G.TrackStat(player, "Total" .. fishName .. "Caught", 1)
	end

	print("🐟 " .. player.Name .. " caught 1 " .. fishName .. " (" .. fishInfo.Rarity .. ")")

	return true, "success", fishName, fishInfo.Icon, fishInfo.Rarity
end

-- ============================================
-- CHECK FISHING ROD OWNERSHIP (For UI updates)
-- ============================================

function _G.CanPlayerFish(player)
	return hasFishingRod(player)
end

-- ============================================
-- GLOBAL FUNCTION TO OPEN FISHING ZONE
-- ============================================

_G.openFishingZone = function(player)
	print(player.Name .. " opened Fishing Zone")
	-- This function can be expanded to show a fishing GUI if needed
	-- For now, it's just a placeholder that the client can call to reopen
end

-- ============================================
-- REMOTE EVENTS
-- ============================================

-- RemoteFunction callback (Get fish data for GUI)
GetFishDataFunction.OnServerInvoke = function(player)
	return getOwnedFish(player)
end

-- RemoteEvent listener (Sell fish)
FishActionEvent.OnServerEvent:Connect(function(player, action, fishName)
	print("🎣 FishActionEvent:", action, fishName)

	if action == "Sell" then
		local success, earnings, message = sellFish(player, fishName)
		FishActionEvent:FireClient(player, "Sell", success, message)
	end
end)

-- Listen for client request to reopen Fishing Zone
OpenFishingZoneServer.OnServerEvent:Connect(function(player)
	print("🔄 Client requested to reopen FishingZone")
	_G.openFishingZone(player)
end)

-- ============================================
-- PLAYER INITIALIZATION
-- ============================================

Players.PlayerAdded:Connect(function(player)
	-- Wait for player data to load
	task.spawn(function()
		local toolsOwned = player:WaitForChild("ToolsOwned", 30)
		if not toolsOwned then
			warn("❌ ToolsOwned not found for " .. player.Name)
			return
		end

		local fishingRod = toolsOwned:WaitForChild("FishingRod", 10)
		if fishingRod then
			print("🎣 " .. player.Name .. " Fishing Rod status: " .. tostring(fishingRod.Value))
		end
	end)
end)

print("✅ FishingManager ready")
