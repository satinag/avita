-- ServerScriptService/GameTipsManager
-- Contextual tips and messages based on farm milestones (independent of tutorial queue)

local Players = game:GetService("Players")
local ServerScriptService = game:GetService("ServerScriptService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local DataStoreModule = require(ServerScriptService:WaitForChild("DataStoreModule"))

print("💡 Game Tips Manager loaded!")

local showTutorialEvent = ReplicatedStorage:WaitForChild("ShowTutorialEvent")

-- Track which tips have been shown per player
local shownTips = {}

-- ============================================
-- TIP DEFINITIONS
-- ============================================

local MILESTONE_TIPS = {
	-- Harvest milestones
	{
		StatKey = "TotalCropsHarvested",
		Threshold = 40,
		TipName = "Harvest20",
		Title = "🌾 Farming Expert!",
		Message = "You've harvested 20 crops! Keep upgrading your tools for faster growth and bigger yields!",
		Duration = 5
	},
	{
		StatKey = "TotalCropsHarvested",
		Threshold = 100,
		TipName = "Harvest100",
		Title = "🌾 Master Harvester!",
		Message = "100 crops harvested! Try planting different crop types to maximize your earnings!",
		Duration = 5
	},
	{
		StatKey = "TotalCropsHarvested",
		Threshold = 500,
		TipName = "Harvest500",
		Title = "🏆 Legendary Farmer!",
		Message = "500 crops! You're a true farming master! Have you explored all zones?",
		Duration = 6
	},

	-- Money earned milestones
	{
		StatKey = "TotalCashEarned",
		Threshold = 1000,
		TipName = "Earned1000",
		Title = "💰 First Thousand!",
		Message = "You've earned $1,000! Invest in more plots and animals to grow your farm!",
		Duration = 5
	},
	{
		StatKey = "TotalCashEarned",
		Threshold = 5000,
		TipName = "Earned5000",
		Title = "💰 Business Tycoon!",
		Message = "$5,000 earned! Don't forget to upgrade your tools for maximum efficiency!",
		Duration = 5
	},

	-- Plot ownership
	{
		StatKey = "PlotsOwned",
		Threshold = 8,
		TipName = "Plots8",
		Title = "🏡 Expanding Empire!",
		Message = "You own 8 plots! More plots means more crops growing at once!",
		Duration = 5
	},

	-- Animal collection milestones
	{
		StatKey = "TotalEggsCollected",
		Threshold = 50,
		TipName = "Eggs50",
		Title = "🥚 Egg Collector!",
		Message = "50 eggs collected! Upgrade to Passive Income to collect automatically!",
		Duration = 5
	},
	{
		StatKey = "TotalMilkCollected",
		Threshold = 50,
		TipName = "Milk50",
		Title = "🥛 Dairy Farmer!",
		Message = "50 milk collected! Cows are great passive income sources!",
		Duration = 5
	},
}

-- ============================================
-- MONITORING SYSTEM
-- ============================================

local function checkMilestones(player)
	local data = DataStoreModule.PlayerData[player.UserId]
	if not data or not data.FarmStats then return end

	if not shownTips[player.UserId] then
		shownTips[player.UserId] = {}
	end

	for _, tip in ipairs(MILESTONE_TIPS) do
		-- Skip if already shown
		if shownTips[player.UserId][tip.TipName] then continue end

		-- Get stat value
		local statValue = data.FarmStats[tip.StatKey] or 0

		-- Check threshold
		if statValue >= tip.Threshold then
			-- Mark as shown
			shownTips[player.UserId][tip.TipName] = true

			-- Fire message
			showTutorialEvent:FireClient(player, tip.TipName, {
				Title = tip.Title,
				Message = tip.Message,
				Duration = tip.Duration
			})

			print("💡 Showed tip to " .. player.Name .. ": " .. tip.TipName)
		end
	end
end

-- ============================================
-- STAT CHANGE LISTENER
-- ============================================

local function monitorPlayer(player)
	-- Check immediately
	task.wait(1)
	checkMilestones(player)

	-- Monitor stats periodically (every 5 seconds)
	local connection
	connection = game:GetService("RunService").Heartbeat:Connect(function()
		if not player.Parent then
			connection:Disconnect()
			return
		end

		task.wait(5)
		checkMilestones(player)
	end)
end

-- ============================================
-- INITIALIZATION
-- ============================================

Players.PlayerAdded:Connect(function(player)
	-- Wait for data to load
	task.wait(3)

	monitorPlayer(player)
end)

Players.PlayerRemoving:Connect(function(player)
	shownTips[player.UserId] = nil
end)

print("✅ Game Tips Manager ready - monitoring farm milestones!")
