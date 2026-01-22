-- DailyRewardManager: Handles daily login rewards
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local DataStoreModule = require(ServerScriptService:WaitForChild("DataStoreModule"))

-- Load SoundManager safely
local SoundManager
pcall(function()
	SoundManager = require(ReplicatedStorage:WaitForChild("SoundManager", 2))
end)

-- Create RemoteEvent for daily rewards
local claimDailyRewardEvent = Instance.new("RemoteEvent")
claimDailyRewardEvent.Name = "ClaimDailyRewardEvent"
claimDailyRewardEvent.Parent = ReplicatedStorage

-- Daily reward structure
local DAILY_REWARDS = {
	[1] = {Cash = 50, Seeds = {}, Description = "Welcome back! 50 Cash"},
	[2] = {Cash = 100, Seeds = {Wheat = 3}, Description = "Day 2: 100 Cash + 3 Wheat Seeds"},
	[3] = {Cash = 150, Seeds = {Corn = 5}, Description = "Day 3: 150 Cash + 5 Corn Seeds"},
	[4] = {Cash = 200, Seeds = {Potato = 3}, Description = "Day 4: 200 Cash + 3 Potato Seeds"},
	[5] = {Cash = 300, Seeds = {Wheat = 5, Corn = 5}, Description = "Day 5: 300 Cash + Seeds"},
	[6] = {Cash = 400, Seeds = {Wheat = 10}, Description = "Day 6: 400 Cash + 10 Wheat Seeds"},
	[7] = {Cash = 500, Seeds = {Wheat = 10, Corn = 10, Potato = 10}, Description = "🎉 Day 7 BONUS: 500 Cash + ALL Seeds!"}
}

-- Check if player can claim daily reward
local function canClaimReward(player)
	local data = DataStoreModule.PlayerData[player.UserId]
	if not data then return false, 0 end

	local lastClaimDate = data.DailyReward.LastClaimDate or ""
	local currentDate = os.date("%Y-%m-%d", os.time())

	-- First time claiming
	if lastClaimDate == "" then
		return true, 1
	end

	-- Already claimed today
	if lastClaimDate == currentDate then
		return false, data.DailyReward.Streak
	end

	-- Check if claimed yesterday (to maintain streak)
	local lastTime = os.time({year = tonumber(lastClaimDate:sub(1,4)), month = tonumber(lastClaimDate:sub(6,7)), day = tonumber(lastClaimDate:sub(9,10)), hour = 0, min = 0, sec = 0})
	local currentTime = os.time({year = tonumber(currentDate:sub(1,4)), month = tonumber(currentDate:sub(6,7)), day = tonumber(currentDate:sub(9,10)), hour = 0, min = 0, sec = 0})
	local daysDifference = math.floor((currentTime - lastTime) / 86400)

	if daysDifference == 1 then
		-- Continue streak
		local newStreak = math.min(data.DailyReward.Streak + 1, 7)
		return true, newStreak
	else
		-- Reset streak
		return true, 1
	end
end

-- Give daily reward
local function giveReward(player, day)
	local reward = DAILY_REWARDS[day]
	if not reward then return false end

	-- Give cash
	local leaderstats = player:FindFirstChild("leaderstats")
	local cash = leaderstats and leaderstats:FindFirstChild("Cash")
	if cash then
		cash.Value = cash.Value + reward.Cash
	end

	-- Give seeds
	local seedInventory = player:FindFirstChild("SeedInventory")
	if seedInventory then
		for seedName, amount in pairs(reward.Seeds) do
			local seedValue = seedInventory:FindFirstChild(seedName)
			if seedValue then
				seedValue.Value = seedValue.Value + amount
			end
		end
	end

	-- Update data
	local data = DataStoreModule.PlayerData[player.UserId]
	if data then
		data.DailyReward.LastClaimDate = os.date("%Y-%m-%d", os.time())
		data.DailyReward.Streak = day
	end

	-- Play coin sound for daily reward (safely)
	if SoundManager then
		pcall(function()
			SoundManager:PlaySoundForPlayer(player, "CoinSound")
		end)
	end

	print("🎁 " .. player.Name .. " claimed Day " .. day .. " reward: " .. reward.Description)
	return true
end

-- Handle claim request from client
claimDailyRewardEvent.OnServerEvent:Connect(function(player)
	local canClaim, streak = canClaimReward(player)

	if canClaim then
		local success = giveReward(player, streak)
		if success then
			claimDailyRewardEvent:FireClient(player, "success", streak, DAILY_REWARDS[streak].Description)
		end
	else
		claimDailyRewardEvent:FireClient(player, "already_claimed", streak)
	end
end)

-- Check for available reward when player joins
Players.PlayerAdded:Connect(function(player)
	wait(5) -- Wait for data to load

	local canClaim, streak = canClaimReward(player)
	if canClaim then
		-- Notify player they have a reward available
		claimDailyRewardEvent:FireClient(player, "available", streak)
	end
end)

print("🎁 Daily Reward Manager loaded!")
