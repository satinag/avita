-- DailyQuestManager: Handles quest logic and daily resets
local Players = game:GetService("Players")
local ServerScriptService = game:GetService("ServerScriptService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local DataStoreModule = require(ServerScriptService:WaitForChild("DataStoreModule"))
local QuestModule = require(ReplicatedStorage:WaitForChild("DailyQuestModule"))

local DailyQuestManager = {}

-- Get UTC day key (e.g., "2026-01-10")
local function getCurrentDayKey()
	local time = os.time()
	local date = os.date("!*t", time) -- UTC time
	return string.format("%04d-%02d-%02d", date.year, date.month, date.day)
end

-- Pick random quests BASED ON PLAYER PROGRESSION
local function generateDailyQuests(player)
	local quests = {}
	local pool = {}

	-- 🎯 DYNAMIC TIER = SeedsUnlocked.Value
	local seedsUnlocked = player:FindFirstChild("SeedsUnlocked")
	local playerTier = seedsUnlocked and seedsUnlocked.Value or 0
	print("🎯 " .. player.Name .. " Tier " .. playerTier .. " (SeedsUnlocked=" .. playerTier .. ")")

	-- Filter quests by tier (TierReq <= playerTier OR TierReq=1)
	for _, quest in ipairs(QuestModule.QuestPool) do
		if not quest.TierReq or quest.TierReq <= playerTier or quest.TierReq == 1 then
			table.insert(pool, quest)
		end
	end


	print("📊 " .. #pool .. "/" .. #QuestModule.QuestPool .. " quests available for Tier " .. playerTier)

	-- Pick 3 random from available pool
	for i = 1, 3 do
		if #pool == 0 then break end
		local index = math.random(1, #pool)
		table.insert(quests, pool[index])
		table.remove(pool, index)
	end

	return quests
end


-- Initialize player quests
function DailyQuestManager:InitializeQuests(player)
	local data = DataStoreModule.PlayerData[player.UserId]
	if not data then return end

	-- Create DailyQuests data if missing
	if not data.DailyQuests then
		data.DailyQuests = {
			LastResetDay = getCurrentDayKey(),
			ActiveQuests = {},
			Progress = {}
		}
	end

	-- Check if new day → reset quests
	local currentDay = getCurrentDayKey()
	if data.DailyQuests.LastResetDay ~= currentDay then
		print("🔄 New day detected! Resetting daily quests for " .. player.Name)
		data.DailyQuests.LastResetDay = currentDay
		data.DailyQuests.ActiveQuests = generateDailyQuests(player)
		data.DailyQuests.Progress = {}

		-- Initialize progress for each quest
		for _, quest in ipairs(data.DailyQuests.ActiveQuests) do
			data.DailyQuests.Progress[quest.ID] = {
				Current = 0,
				Completed = false,
				Claimed = false
			}
		end
	end

	-- Create quest values for client to read
	local questsFolder = Instance.new("Folder")
	questsFolder.Name = "DailyQuests"
	questsFolder.Parent = player

	for i, quest in ipairs(data.DailyQuests.ActiveQuests) do
		local questFolder = Instance.new("Folder")
		questFolder.Name = "Quest" .. i
		questFolder.Parent = questsFolder

		local questID = Instance.new("StringValue")
		questID.Name = "ID"
		questID.Value = quest.ID
		questID.Parent = questFolder

		local progress = data.DailyQuests.Progress[quest.ID]
		local currentVal = Instance.new("IntValue")
		currentVal.Name = "Current"
		currentVal.Value = progress.Current
		currentVal.Parent = questFolder

		local targetVal = Instance.new("IntValue")
		targetVal.Name = "Target"
		targetVal.Value = quest.Target
		targetVal.Parent = questFolder

		local completedVal = Instance.new("BoolValue")
		completedVal.Name = "Completed"
		completedVal.Value = progress.Completed
		completedVal.Parent = questFolder

		local claimedVal = Instance.new("BoolValue")
		claimedVal.Name = "Claimed"
		claimedVal.Value = progress.Claimed
		claimedVal.Parent = questFolder
	end

	print("✅ Daily quests initialized for " .. player.Name)
end

-- Update quest progress
function DailyQuestManager:UpdateProgress(player, questType, value)
	local data = DataStoreModule.PlayerData[player.UserId]
	if not data or not data.DailyQuests then return end

	local questsFolder = player:FindFirstChild("DailyQuests")
	if not questsFolder then return end

	-- Check each active quest
	for _, quest in ipairs(data.DailyQuests.ActiveQuests) do
		-- Match Type AND specific crop/seed
		local typeMatch = quest.Type == questType
		local cropMatch = not quest.CropType or (value.CropType == quest.CropType)
		local seedMatch = not quest.SeedType or (value.SeedType == quest.SeedType)

		if typeMatch and cropMatch and seedMatch then
			local progress = data.DailyQuests.Progress[quest.ID]
			if not progress.Completed then
				-- Increment progress
				progress.Current = math.min(progress.Current + (value.Amount or 1), quest.Target)

				-- Update client values
				for _, questFolder in ipairs(questsFolder:GetChildren()) do
					local idVal = questFolder:FindFirstChild("ID")
					if idVal and idVal.Value == quest.ID then
						local currentVal = questFolder:FindFirstChild("Current")
						if currentVal then
							currentVal.Value = progress.Current
						end

						-- Check if completed
						if progress.Current >= quest.Target and not progress.Completed then
							progress.Completed = true
							local completedVal = questFolder:FindFirstChild("Completed")
							if completedVal then
								completedVal.Value = true
							end
							print("🎉 " .. player.Name .. " completed quest: " .. quest.Name)
						end
					end
				end
			end
		end
	end
end


-- Claim quest reward
function DailyQuestManager:ClaimReward(player, questID)
	local data = DataStoreModule.PlayerData[player.UserId]
	if not data or not data.DailyQuests then return false end

	local progress = data.DailyQuests.Progress[questID]
	if not progress or not progress.Completed or progress.Claimed then
		return false
	end

	-- Find quest definition
	local quest = nil
	for _, q in ipairs(data.DailyQuests.ActiveQuests) do
		if q.ID == questID then
			quest = q
			break
		end
	end

	if not quest then return false end

	-- Give rewards
	local leaderstats = player:FindFirstChild("leaderstats")
	if quest.Reward.Cash and leaderstats then
		local cash = leaderstats:FindFirstChild("Cash")
		if cash then
			cash.Value = cash.Value + quest.Reward.Cash
		end
	end

	if quest.Reward.Seeds then
		local seedInventory = player:FindFirstChild("SeedInventory")
		if seedInventory then
			for seedType, amount in pairs(quest.Reward.Seeds) do
				local seedVal = seedInventory:FindFirstChild(seedType)
				if seedVal then
					seedVal.Value = seedVal.Value + amount
				end
			end
		end
	end

	-- Mark as claimed
	progress.Claimed = true

	-- Update client
	local questsFolder = player:FindFirstChild("DailyQuests")
	if questsFolder then
		for _, questFolder in ipairs(questsFolder:GetChildren()) do
			local idVal = questFolder:FindFirstChild("ID")
			if idVal and idVal.Value == questID then
				local claimedVal = questFolder:FindFirstChild("Claimed")
				if claimedVal then
					claimedVal.Value = true
				end
			end
		end
	end

	print("💰 " .. player.Name .. " claimed reward for: " .. quest.Name)
	return true
end

-- Player joined
Players.PlayerAdded:Connect(function(player)
	-- Wait for data to load
	repeat task.wait(0.1) until DataStoreModule.PlayerData[player.UserId]

	DailyQuestManager:InitializeQuests(player)
end)

-- RemoteFunction for client to claim rewards
local claimRemote = Instance.new("RemoteFunction")
claimRemote.Name = "ClaimQuestReward"
claimRemote.Parent = ReplicatedStorage

claimRemote.OnServerInvoke = function(player, questID)
	return DailyQuestManager:ClaimReward(player, questID)
end

-- ============================================
-- NEW QUEST TRACKING FUNCTIONS
-- ============================================

-- Track animal product collection (Eggs, Milk, Meat, Wool)
function DailyQuestManager:UpdateProductCollection(player, productType, amount)
	local data = DataStoreModule.PlayerData[player.UserId]
	if not data or not data.DailyQuests then return end

	local questsFolder = player:FindFirstChild("DailyQuests")
	if not questsFolder then return end

	-- Check each active quest
	for _, quest in ipairs(data.DailyQuests.ActiveQuests) do
		local progress = data.DailyQuests.Progress[quest.ID]

		-- Match quest type and product
		if quest.Type == "Collect" and quest.ProductType == productType and not progress.Completed then
			-- Increment progress
			progress.Current = math.min(progress.Current + amount, quest.Target)

			-- Update client values
			for _, questFolder in ipairs(questsFolder:GetChildren()) do
				local idVal = questFolder:FindFirstChild("ID")
				if idVal and idVal.Value == quest.ID then
					local currentVal = questFolder:FindFirstChild("Current")
					if currentVal then
						currentVal.Value = progress.Current
					end

					-- Check if completed
					if progress.Current >= quest.Target and not progress.Completed then
						progress.Completed = true
						local completedVal = questFolder:FindFirstChild("Completed")
						if completedVal then
							completedVal.Value = true
						end
						print("✅ " .. player.Name .. " completed quest: " .. quest.Name)
					end
					break
				end
			end
		end
	end
end

-- Track product selling at barn
function DailyQuestManager:UpdateProductSell(player, amount)
	self:UpdateProgress(player, "SellProduct", {Amount = amount})
end

-- Track fish catching
function DailyQuestManager:UpdateFishCatch(player, fishName, rarity, amount)
	amount = amount or 1
	local data = DataStoreModule.PlayerData[player.UserId]
	if not data or not data.DailyQuests then return end

	local questsFolder = player:FindFirstChild("DailyQuests")
	if not questsFolder then return end

	-- Check each active quest
	for _, quest in ipairs(data.DailyQuests.ActiveQuests) do
		local progress = data.DailyQuests.Progress[quest.ID]

		if not progress.Completed then
			local matches = false

			-- Generic fish catch
			if quest.Type == "CatchFish" and not quest.FishType and not quest.FishRarity then
				matches = true
			end

			-- Specific fish type
			if quest.Type == "CatchFish" and quest.FishType == fishName then
				matches = true
			end

			-- Rare fish quest
			if quest.Type == "CatchRareFish" and quest.FishRarity then
				for _, rarityLevel in ipairs(quest.FishRarity) do
					if rarityLevel == rarity then
						matches = true
						break
					end
				end
			end

			if matches then
				-- Increment progress
				progress.Current = math.min(progress.Current + amount, quest.Target)

				-- Update client values
				for _, questFolder in ipairs(questsFolder:GetChildren()) do
					local idVal = questFolder:FindFirstChild("ID")
					if idVal and idVal.Value == quest.ID then
						local currentVal = questFolder:FindFirstChild("Current")
						if currentVal then
							currentVal.Value = progress.Current
						end

						-- Check if completed
						if progress.Current >= quest.Target then
							progress.Completed = true
							local completedVal = questFolder:FindFirstChild("Completed")
							if completedVal then
								completedVal.Value = true
							end
							print("✅ " .. player.Name .. " completed quest: " .. quest.Name)
						end
						break
					end
				end
			end
		end
	end
end

-- Track fish selling
function DailyQuestManager:UpdateFishSell(player, amount)
	self:UpdateProgress(player, "SellFish", {Amount = amount})
end

-- Track beehive ownership
function DailyQuestManager:CheckBeehiveOwnership(player)
	local beehiveCount = player:FindFirstChild("BeehiveCount")
	if not beehiveCount then return end

	local count = beehiveCount.Value

	local data = DataStoreModule.PlayerData[player.UserId]
	if not data or not data.DailyQuests then return end

	local questsFolder = player:FindFirstChild("DailyQuests")
	if not questsFolder then return end

	-- Check beehive ownership quests
	for _, quest in ipairs(data.DailyQuests.ActiveQuests) do
		if quest.Type == "OwnBeehives" then
			local progress = data.DailyQuests.Progress[quest.ID]

			if count >= quest.Target and not progress.Completed then
				progress.Current = count
				progress.Completed = true

				-- Update client
				for _, questFolder in ipairs(questsFolder:GetChildren()) do
					local idVal = questFolder:FindFirstChild("ID")
					if idVal and idVal.Value == quest.ID then
						local currentVal = questFolder:FindFirstChild("Current")
						local completedVal = questFolder:FindFirstChild("Completed")

						if currentVal then currentVal.Value = count end
						if completedVal then completedVal.Value = true end

						print("✅ " .. player.Name .. " completed quest: " .. quest.Name)
						break
					end
				end
			end
		end
	end
end

-- Track animal ownership (different types)
function DailyQuestManager:CheckAnimalOwnership(player)
	local animalInventory = player:FindFirstChild("AnimalInventory")
	if not animalInventory then return end

	-- Count unique animal types
	local uniqueCount = 0
	for _, animalValue in ipairs(animalInventory:GetChildren()) do
		if animalValue:IsA("IntValue") and animalValue.Value > 0 then
			uniqueCount = uniqueCount + 1
		end
	end

	local data = DataStoreModule.PlayerData[player.UserId]
	if not data or not data.DailyQuests then return end

	local questsFolder = player:FindFirstChild("DailyQuests")
	if not questsFolder then return end

	-- Check animal ownership quests
	for _, quest in ipairs(data.DailyQuests.ActiveQuests) do
		if quest.Type == "OwnAnimals" then
			local progress = data.DailyQuests.Progress[quest.ID]

			if uniqueCount >= quest.Target and not progress.Completed then
				progress.Current = uniqueCount
				progress.Completed = true

				-- Update client
				for _, questFolder in ipairs(questsFolder:GetChildren()) do
					local idVal = questFolder:FindFirstChild("ID")
					if idVal and idVal.Value == quest.ID then
						local currentVal = questFolder:FindFirstChild("Current")
						local completedVal = questFolder:FindFirstChild("Completed")

						if currentVal then currentVal.Value = uniqueCount end
						if completedVal then completedVal.Value = true end

						print("✅ " .. player.Name .. " completed quest: " .. quest.Name)
						break
					end
				end
			end
		end
	end
end

-- Track marketplace listing
function DailyQuestManager:UpdateMarketplaceListing(player, amount)
	amount = amount or 1
	self:UpdateProgress(player, "ListMarketplace", {Amount = amount})
end

-- Track marketplace purchases
function DailyQuestManager:UpdateMarketplacePurchase(player, amount)
	amount = amount or 1
	self:UpdateProgress(player, "BuyMarketplace", {Amount = amount})
end

-- Track when player's listing is sold
function DailyQuestManager:UpdateMarketplaceSold(player, amount)
	amount = amount or 1
	self:UpdateProgress(player, "MarketplaceSold", {Amount = amount})
end

-- Track cash spending
function DailyQuestManager:UpdateCashSpending(player, amount)
	self:UpdateProgress(player, "SpendCash", {Amount = amount})
end

-- Track mixed quest progress
function DailyQuestManager:UpdateMixedQuest(player, questType, amount)
	local data = DataStoreModule.PlayerData[player.UserId]
	if not data or not data.DailyQuests then return end

	local questsFolder = player:FindFirstChild("DailyQuests")
	if not questsFolder then return end

	-- Check each active mixed quest
	for _, quest in ipairs(data.DailyQuests.ActiveQuests) do
		if quest.Type == "Mixed" and quest.Requirements then
			local progress = data.DailyQuests.Progress[quest.ID]

			if not progress.MixedProgress then
				progress.MixedProgress = {}
				for i, req in ipairs(quest.Requirements) do
					progress.MixedProgress[i] = 0
				end
			end

			-- Update matching requirement
			for i, req in ipairs(quest.Requirements) do
				if req.Type == questType then
					progress.MixedProgress[i] = math.min(
						progress.MixedProgress[i] + amount, 
						req.Target
					)
				end
			end

			-- Check if ALL requirements met
			local allMet = true
			for i, req in ipairs(quest.Requirements) do
				if progress.MixedProgress[i] < req.Target then
					allMet = false
					break
				end
			end

			if allMet and not progress.Completed then
				progress.Current = quest.Target
				progress.Completed = true

				-- Update client
				for _, questFolder in ipairs(questsFolder:GetChildren()) do
					local idVal = questFolder:FindFirstChild("ID")
					if idVal and idVal.Value == quest.ID then
						local currentVal = questFolder:FindFirstChild("Current")
						local completedVal = questFolder:FindFirstChild("Completed")

						if currentVal then currentVal.Value = quest.Target end
						if completedVal then completedVal.Value = true end

						print("✅ " .. player.Name .. " completed mixed quest: " .. quest.Name)
						break
					end
				end
			end
		end
	end
end

print("✅ DailyQuestManager expanded with new quest types")


return DailyQuestManager