-- ServerScriptService/LeaderboardManager
local DataStoreService = game:GetService("DataStoreService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local LeaderboardStore = DataStoreService:GetOrderedDataStore("GlobalLeaderboard_v1")

local LeaderboardManager = {}

-- Categories to track
local CATEGORIES = {
	"TotalEarned",
	"Cash",
	"PlotsOwned",    -- ✅ Keep plots
	"AnimalsOwned",  -- ✅ Add animals
	"HouseLevel",    -- ✅ Add house
	"DaysPlayed"
}


-- Save player to leaderboard
function LeaderboardManager:UpdatePlayer(player)
	local userId = player.UserId
	local displayName = player.Name

	-- Gather stats
	local cash = player.leaderstats and player.leaderstats.Cash and player.leaderstats.Cash.Value or 0
	local totalEarned = player:FindFirstChild("TotalEarned") and player.TotalEarned.Value or 0

	-- Count plots (KEEP THIS)
	local plotsOwned = 0
	local ownedPlots = player:FindFirstChild("OwnedPlots")
	if ownedPlots then
		for i = 1, 16 do
			local plotValue = ownedPlots:FindFirstChild("Plot" .. i)
			if plotValue and plotValue.Value == player.Name then
				plotsOwned = plotsOwned + 1
			end
		end
	end

	-- Count animals (ADD THIS)
	local animalsOwned = 0
	local poultryOwned = player:FindFirstChild("PoultryOwned")
	if poultryOwned then
		for _, animal in pairs(poultryOwned:GetChildren()) do
			if animal:IsA("BoolValue") and animal.Value then
				animalsOwned = animalsOwned + 1
			end
		end
	end

	-- Get beehive count
	local beehiveCount = player:FindFirstChild("BeehiveCount")
	if beehiveCount then
		animalsOwned = animalsOwned + beehiveCount.Value
	end

	-- Get house level
	local houseLevel = player:GetAttribute("HouseLevel") or 1

	-- Get day count
	local daysPlayed = 1
	if _G.playerDayCount and _G.playerDayCount[userId] then
		daysPlayed = _G.playerDayCount[userId]
	end

	-- Save each category
	for _, category in ipairs(CATEGORIES) do
		local value = 0
		if category == "TotalEarned" then value = totalEarned
		elseif category == "Cash" then value = cash
		elseif category == "PlotsOwned" then value = plotsOwned     
		elseif category == "AnimalsOwned" then value = animalsOwned 
		elseif category == "HouseLevel" then value = houseLevel     
		elseif category == "DaysPlayed" then value = daysPlayed
		end

		pcall(function()
			LeaderboardStore:SetAsync(category .. "_" .. userId, value)
		end)
	end

	-- Store display name
	local nameStore = DataStoreService:GetDataStore("PlayerNames_v1")
	pcall(function()
		nameStore:SetAsync(tostring(userId), displayName)
	end)

	print("📊 Updated leaderboard for " .. player.Name)
end

-- Get top 10
function LeaderboardManager:GetTop10(category)
	local success, pages = pcall(function()
		return LeaderboardStore:GetSortedAsync(false, 10)
	end)

	if not success or not pages then
		warn("Failed to fetch leaderboard: " .. tostring(pages))
		return {}
	end

	local leaderboard = {}
	local nameStore = DataStoreService:GetDataStore("PlayerNames_v1")

	-- Safe page retrieval
	local pageSuccess, currentPage = pcall(function()
		return pages:GetCurrentPage()
	end)

	if not pageSuccess or not currentPage then
		warn("Failed to get current page")
		return {}
	end

	-- Filter entries by category prefix
	for _, entry in ipairs(currentPage) do
		-- Check if key starts with our category
		if string.match(entry.key, "^" .. category .. "_") then
			local userId = tonumber(string.match(entry.key, "%d+"))
			local playerName = "Player"

			pcall(function()
				playerName = nameStore:GetAsync(tostring(userId)) or "Player"
			end)

			table.insert(leaderboard, {
				Rank = #leaderboard + 1,
				UserId = userId,
				Name = playerName,
				Value = entry.value
			})

			-- Stop at 10 entries
			if #leaderboard >= 10 then
				break
			end
		end
	end

	return leaderboard
end

-- Auto-update every 5 minutes
Players.PlayerAdded:Connect(function(player)
	task.spawn(function()
		task.wait(10) -- Wait for player data to load
		while player.Parent do
			LeaderboardManager:UpdatePlayer(player)
			task.wait(300) -- 5 minutes
		end
	end)
end)

-- Update on logout
Players.PlayerRemoving:Connect(function(player)
	LeaderboardManager:UpdatePlayer(player)
end)

-- RemoteFunction for client requests
local getLeaderboardRemote = Instance.new("RemoteFunction")
getLeaderboardRemote.Name = "GetLeaderboard"
getLeaderboardRemote.Parent = ReplicatedStorage

getLeaderboardRemote.OnServerInvoke = function(player, category)
	-- Validate category exists
	local validCategory = false
	for _, cat in ipairs(CATEGORIES) do
		if cat == category then
			validCategory = true
			break
		end
	end

	if not category or not validCategory then
		category = "TotalEarned"
	end

	return LeaderboardManager:GetTop10(category)
end

-- Make globally accessible
_G.LeaderboardManager = LeaderboardManager

print("📊 Leaderboard Manager loaded!")
return LeaderboardManager
