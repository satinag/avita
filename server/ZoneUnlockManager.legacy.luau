local Players = game:GetService("Players")
local ServerScriptService = game:GetService("ServerScriptService")
local TutorialManager = nil

task.spawn(function()
	task.wait(2)
	TutorialManager = ServerScriptService:FindFirstChild("TutorialManager")
end)

-- Zone configuration
local ZONES = {
	{
		Name = "Expansion Zone 1",
		RequiredEarnings = 200,
		Plots = {5, 6, 7, 8},
		Folder = workspace:FindFirstChild("ExpansionZone1"),
		SignName = "ExpansionSign",
		TutorialStep = "GoToZone1",
		TutorialMessage = "Zone1Unlock"
	},
	{
		Name = "Expansion Zone 2",
		RequiredEarnings = 500,
		Plots = {9, 10, 11, 12},
		Folder = workspace:FindFirstChild("ExpansionZone2"),
		SignName = "ExpansionSign",
		TutorialStep = "GoToZone2",
		TutorialMessage = "Zone2Unlock"
	},
	{
		Name = "Expansion Zone 3",
		RequiredEarnings = 800,
		Plots = {13, 14, 15, 16},
		Folder = workspace:FindFirstChild("ExpansionZone3"),
		SignName = "ExpansionSign",
		TutorialStep = "GoToZone3",
		TutorialMessage = "Zone3Unlock"
	},
	{
		Name = "Poultry Shop",
		RequiredEarnings = 1100,
		Plots = {},
		Folder = workspace.AnimalZone,
		SignName = "ExpansionSign",
		ShopModel = "PoultryShop",  -- Name of shop model	
		TutorialStep = "GoToPoultryShop",
		TutorialMessage = "PoultryUnlock"
	},
	{
		Name = "First Beehive",
		RequiredEarnings = 0,  
		RequiredBeehives = 1, 
		Plots = {},
		Folder = workspace.AnimalZone,
		TutorialStep = "GoToFirstHive",
		TutorialMessage = "FirstHiveCollection"
	}
}

-- ✅ TRACK HIGHEST ZONE TO RESUME PER SESSION
local zonesToResume = {}

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


-- ✅ RESUME TO HIGHEST NON-COMPLETED ZONE ONLY
local function resumeHighestZone(player)
	if not zonesToResume[player. UserId] then return end

	local highestZone = zonesToResume[player.UserId]

	task.spawn(function()
		task.wait(0.5)

		-- Get player's tutorial state
		local currentStep = player: FindFirstChild("CurrentArrowStep")
		if not currentStep then 
			zonesToResume[player.UserId] = nil
			return 
		end

		local progressData = player:GetAttribute("TutorialProgress")
		if not progressData then 
			zonesToResume[player.UserId] = nil
			return 
		end

		local decoded = game:GetService("HttpService"):JSONDecode(progressData)

		-- ✅ Check if this zone's tutorial step was already completed
		local alreadyCompleted = false
		for _, completedStep in ipairs(decoded. CompletedSteps) do
			if completedStep == highestZone.Step then
				alreadyCompleted = true
				break
			end
		end

		-- ✅ IF ALREADY COMPLETED, STAY PAUSED (NO MESSAGE, NO RESUME)
		if alreadyCompleted then
			print("🎉 Zone step '" .. highestZone.Step .. "' already completed - staying paused")
			zonesToResume[player.UserId] = nil
			return
		end

		-- ✅ IF NOT COMPLETED, SHOW MESSAGE AND RESUME
		if highestZone.Message and _G.ShowTutorialMessage then
			_G.ShowTutorialMessage(player, highestZone.Message)
		end

		task.wait(1)

		-- Resume tutorial to this zone's step
		if currentStep. Value == "Paused" and _G.ResumeTutorialStep then
			print("🔄 Resuming tutorial to zone:  " .. highestZone.Step)
			_G.ResumeTutorialStep(player, highestZone.Step)
		end

		zonesToResume[player.UserId] = nil
	end)
end

-- ✅ GLOBAL tracking (zones unlock once for all players)
local unlockedZones = {}

Players.PlayerAdded:Connect(function(player)
	zonesToResume[player.UserId] = nil

	local totalEarned = player:WaitForChild("TotalEarned")
	local beehiveCount = player:WaitForChild("BeehiveCount", 10)

	-- Check for initial unlocks and track HIGHEST zone only
	for _, zoneConfig in ipairs(ZONES) do
		if zoneConfig.Folder and totalEarned.Value >= zoneConfig.RequiredEarnings and not unlockedZones[zoneConfig.Name] then
			unlockZone(zoneConfig)
			unlockedZones[zoneConfig.Name] = true

			zonesToResume[player.UserId] = {
				Step = zoneConfig.TutorialStep,
				Message = zoneConfig.TutorialMessage
			}
		end
	end

	task.wait(0.5)
	resumeHighestZone(player)

	-- Listen to totalEarned changes
	totalEarned.Changed:Connect(function(earned)
		for _, zoneConfig in ipairs(ZONES) do
			if zoneConfig.Folder and earned >= zoneConfig.RequiredEarnings and not unlockedZones[zoneConfig.Name] then
				unlockZone(zoneConfig)
				unlockedZones[zoneConfig.Name] = true

				zonesToResume[player.UserId] = {
					Step = zoneConfig.TutorialStep,
					Message = zoneConfig.TutorialMessage
				}
			end
		end

		task.wait(0.5)
		resumeHighestZone(player)
	end)

	-- ✅ ADD THIS: Listen to beehiveCount changes (same pattern as totalEarned)
	if beehiveCount then
		beehiveCount.Changed:Connect(function(count)
			for _, zoneConfig in ipairs(ZONES) do
				if zoneConfig.RequiredBeehives and count >= zoneConfig.RequiredBeehives and not unlockedZones[zoneConfig.Name] then
					unlockedZones[zoneConfig.Name] = true

					zonesToResume[player.UserId] = {
						Step = zoneConfig.TutorialStep,
						Message = zoneConfig.TutorialMessage
					}

					task.wait(0.5)
					resumeHighestZone(player)
				end
			end
		end)
	end
end)


Players.PlayerRemoving:Connect(function(player)
	zonesToResume[player.UserId] = nil
end)

-- ✅ LOCK POULTRY SHOP ON START (only if not already unlocked)
task.wait(2)
local poultryShop = workspace.AnimalZone and workspace.AnimalZone:FindFirstChild("PoultryShop")
if poultryShop and not unlockedZones["Poultry Shop"] then  -- ✅ Only lock if not unlocked
	for _, descendant in pairs(poultryShop:GetDescendants()) do
		if descendant:IsA("BasePart") then
			descendant.Transparency = 0.6
		end
	end
	local prompt = poultryShop:FindFirstChildOfClass("ProximityPrompt", true)
	if prompt then
		prompt:SetAttribute("ZoneLocked", true)
		prompt.ActionText = "🔒 Earn $1100"  -- ✅ Match your RequiredEarnings
		print("🔒 Poultry Shop locked")
	end
else
	print("🏪 Poultry Shop already unlocked - skipping lock")
end

print("🗺️ Zone Manager loaded")