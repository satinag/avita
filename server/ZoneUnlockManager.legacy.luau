local Players = game:GetService("Players")
local ServerScriptService = game:GetService("ServerScriptService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Load TutorialLevelConfig
local TutorialLevelConfig = require(ReplicatedStorage:WaitForChild("TutorialLevelConfig"))

-- Zone configuration (now with TutorialLevel instead of TutorialStep)
local ZONES = {
	{
		Name = "Expansion Zone 1",
		RequiredEarnings = 500,
		Plots = {5, 6, 7, 8},
		Folder = workspace:FindFirstChild("ExpansionZone1"),
		SignName = "ExpansionSign",
		TutorialLevel = 8,  -- Level 8 = GoToZone1
		TutorialMessage = "Zone1Unlock"
	},
	{
		Name = "Expansion Zone 2",
		RequiredEarnings = 1500,
		Plots = {9, 10, 11, 12},
		Folder = workspace:FindFirstChild("ExpansionZone2"),
		SignName = "ExpansionSign",
		TutorialLevel = 9,  -- Level 9 = GoToZone2
		TutorialMessage = "Zone2Unlock"
	},
	{
		Name = "Expansion Zone 3",
		RequiredEarnings = 5000,
		Plots = {13, 14, 15, 16},
		Folder = workspace:FindFirstChild("ExpansionZone3"),
		SignName = "ExpansionSign",
		TutorialLevel = 10,  -- Level 10 = GoToZone3
		TutorialMessage = "Zone3Unlock"
	},
	{
		Name = "Poultry Shop",
		RequiredEarnings = 15000,
		Plots = {},
		Folder = workspace.AnimalZone,
		SignName = "ExpansionSign",
		ShopModel = "PoultryShop",
		TutorialLevel = 11,  -- Level 11 = GoToPoultryShop
		TutorialMessage = "PoultryUnlock"
	},
	{
		Name = "First Beehive",
		RequiredEarnings = 0,
		RequiredBeehives = 1,
		Plots = {},
		Folder = workspace.AnimalZone,
		TutorialLevel = 12,  -- Level 12 = GoToFirstHive
		TutorialMessage = "FirstHiveCollection"
	}
}

-- ✅ GLOBAL tracking (zones unlock once for all players)
local unlockedZones = {}

local function unlockZone(zoneConfig)
	local zone = zoneConfig.Folder
	if not zone then
		warn("Zone folder not found: " .. zoneConfig.Name)
		return
	end

	-- Remove wall
	local wall = zone:FindFirstChild("InvisibleWall")
	if wall then
		wall:Destroy()
		print("🚪 Removed " .. zoneConfig.Name .. " wall")
	end

	-- Destroy sign (only if SignName is specified)
	if zoneConfig.SignName then
		local sign = zone:FindFirstChild(zoneConfig.SignName)
		if sign then
			sign:Destroy()
			print("🪧 Removed " .. zoneConfig.Name .. " sign")
		end
	end

	-- Un-blur plots
	for _, plotNum in ipairs(zoneConfig.Plots) do
		local plot = zone:FindFirstChild("Plot" .. plotNum)
		if plot then
			for _, descendant in pairs(plot:GetDescendants()) do
				if descendant:IsA("BasePart") then
					descendant.Transparency = 0
				end
			end
			local prompt = plot:FindFirstChildOfClass("ProximityPrompt", true)
			if prompt then
				prompt:SetAttribute("ZoneLocked", false)
			end
		end
	end

	-- Unlock poultry shop
	if zoneConfig.ShopModel then
		local shopModel = zone:FindFirstChild(zoneConfig.ShopModel)
		if shopModel then
			for _, descendant in pairs(shopModel:GetDescendants()) do
				if descendant:IsA("BasePart") then
					descendant.Transparency = 0
				end
			end

			local shopPrompt = shopModel:FindFirstChildOfClass("ProximityPrompt", true)
			if shopPrompt then
				shopPrompt:SetAttribute("ZoneLocked", false)
				shopPrompt.Enabled = true
				shopPrompt.ActionText = "Open Poultry Shop"
				print("✅ Unlocked Poultry Shop")
			end
		end
	end

	print("✨ " .. zoneConfig.Name .. " unlocked!")
end

Players.PlayerAdded:Connect(function(player)
	local totalEarned = player:WaitForChild("TotalEarned")
	local beehiveCount = player:WaitForChild("BeehiveCount", 10)
	local currentLevel = player:WaitForChild("CurrentArrowLevel", 10)

	print("💰 " .. player.Name .. " joined with TotalEarned: $" .. totalEarned.Value)

	-- Check for initial unlocks on join
	for _, zoneConfig in ipairs(ZONES) do
		print("🔍 Checking zone: " .. zoneConfig.Name .. " | Required: $" .. zoneConfig.RequiredEarnings .. " | Has: $" .. totalEarned.Value .. " | Already unlocked: " .. tostring(unlockedZones[zoneConfig.Name]))

		if zoneConfig.Folder and totalEarned.Value >= zoneConfig.RequiredEarnings and not unlockedZones[zoneConfig.Name] then
			unlockZone(zoneConfig)
			unlockedZones[zoneConfig.Name] = true

			-- ✅ ONLY activate tutorial if player hasn't passed this level yet
			if zoneConfig.TutorialLevel and currentLevel and currentLevel.Value < zoneConfig.TutorialLevel then
				if _G.ShowTutorialMessage and zoneConfig.TutorialMessage then
					task.wait(0.5)
					_G.ShowTutorialMessage(player, zoneConfig.TutorialMessage)
				end

				if _G.ActivateTutorialLevel then
					task.wait(0.5)
					_G.ActivateTutorialLevel(player, zoneConfig.TutorialLevel)
					print("🎯 Activated tutorial level " .. zoneConfig.TutorialLevel .. " for " .. zoneConfig.Name)
				end
			else
				print("⏭️ Skipping tutorial level " .. zoneConfig.TutorialLevel .. " - player already at level " .. (currentLevel and currentLevel.Value or "?"))
			end
		end
	end


	-- Listen to totalEarned changes (DURING GAMEPLAY ONLY)
	totalEarned.Changed:Connect(function(earned)
		print("💰💰 TotalEarned changed to: $" .. earned)

		local highestZoneToUnlock = nil
		local zonesToUnlock = {}

		-- Find ALL zones that should unlock
		for _, zoneConfig in ipairs(ZONES) do
			if zoneConfig.Folder and earned >= zoneConfig.RequiredEarnings and not unlockedZones[zoneConfig.Name] then
				table.insert(zonesToUnlock, zoneConfig)
				highestZoneToUnlock = zoneConfig  -- Keep track of highest
			end
		end

		-- Unlock ALL qualifying zones
		for _, zoneConfig in ipairs(zonesToUnlock) do
			unlockZone(zoneConfig)
			unlockedZones[zoneConfig.Name] = true
		end

		-- Only show message/arrow for the HIGHEST zone
		if highestZoneToUnlock then
			-- Show tutorial message
			if highestZoneToUnlock.TutorialMessage and _G.ShowTutorialMessage then
				task.wait(0.5)
				_G.ShowTutorialMessage(player, highestZoneToUnlock.TutorialMessage)
			end

			-- Activate tutorial level
			if highestZoneToUnlock.TutorialLevel and _G.ActivateTutorialLevel then
				task.wait(0.5)
				_G.ActivateTutorialLevel(player, highestZoneToUnlock.TutorialLevel)
				print("🎯 Activated tutorial level " .. highestZoneToUnlock.TutorialLevel .. " for " .. highestZoneToUnlock.Name)
			end
		end
	end)




	-- Listen to beehiveCount changes
	if beehiveCount then
		beehiveCount.Changed:Connect(function(count)
			print("🐝 BeehiveCount changed: " .. count)

			for _, zoneConfig in ipairs(ZONES) do
				if zoneConfig.RequiredBeehives and count >= zoneConfig.RequiredBeehives and not unlockedZones[zoneConfig.Name] then
					unlockedZones[zoneConfig.Name] = true

					-- Show tutorial message
					if zoneConfig.TutorialMessage and _G.ShowTutorialMessage then
						task.wait(0.5)
						_G.ShowTutorialMessage(player, zoneConfig.TutorialMessage)
					end

					-- Activate tutorial level
					if zoneConfig.TutorialLevel and _G.ActivateTutorialLevel then
						task.wait(0.5)
						_G.ActivateTutorialLevel(player, zoneConfig.TutorialLevel)
						print("🎯 Activated tutorial level " .. zoneConfig.TutorialLevel)
					end
				end
			end
		end)
	end
end)

-- Lock poultry shop on start
task.wait(2)
local poultryShop = workspace.AnimalZone and workspace.AnimalZone:FindFirstChild("PoultryShop")
if poultryShop and not unlockedZones["Poultry Shop"] then
	for _, descendant in pairs(poultryShop:GetDescendants()) do
		if descendant:IsA("BasePart") then
			descendant.Transparency = 0.6
		end
	end
	local prompt = poultryShop:FindFirstChildOfClass("ProximityPrompt", true)
	if prompt then
		prompt:SetAttribute("ZoneLocked", true)
		prompt.ActionText = "🔒 Earn $1100"
		print("🔒 Poultry Shop locked")
	end
else
	print("🏪 Poultry Shop already unlocked - skipping lock")
end

print("🗺️ Zone Manager loaded")
