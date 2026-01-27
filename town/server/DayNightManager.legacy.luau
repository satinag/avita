-- ServerScriptService/DayNightManager (TOWN - Lightweight)
-- Simplified version: Only time tracking + lighting, NO weather, NO quests

local TweenService = game:GetService("TweenService")
local Players = game:GetService("Players")
local Lighting = game:GetService("Lighting")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

print("🌙 Day/Night Manager (Town - Lightweight) loaded!")

-- ============================================
-- CONFIGURATION
-- ============================================

local CONFIG = {
	CYCLE_DURATION = 900,   -- 15 minutes per full cycle
	START_TIME = 660,       -- 11:00 AM
	END_TIME = 1440,
	STARTING_ENERGY = 270,
	MAX_ENERGY = 500,
	DAY_START = 360,        -- 6:00 AM
	DAY_END = 1080,         -- 6:00 PM
}

-- ============================================
-- GLOBAL STATE
-- ============================================

local gameTime = CONFIG.START_TIME
local dayCount = 1
local currentSeason = "Spring"
local playerEnergy = {}

_G.playerGameTime = {}
_G.playerDayCount = {}
_G.playerSeason = {}

-- ============================================
-- TIME FORMATTING
-- ============================================

local function formatTime(minutes)
	local hours = math.floor(minutes / 60)
	local mins = minutes % 60
	local period = hours >= 12 and "PM" or "AM"
	if hours > 12 then hours = hours - 12 end
	if hours == 0 then hours = 12 end
	return string.format("%d:%02d %s", hours, mins, period)
end

-- ============================================
-- LIGHTING
-- ============================================

local function updateLighting(timeToCheck)
	timeToCheck = timeToCheck or gameTime
	local hours = timeToCheck / 60

	-- Slow down sunset visually
	if hours >= 18 and hours < 22 then
		local eveningProgress = (hours - 18) / 4
		hours = 17 + eveningProgress
	end

	Lighting.ClockTime = hours
	Lighting.Brightness = 2
	Lighting.OutdoorAmbient = Color3.fromRGB(128, 128, 128)
end

-- ============================================
-- ENERGY SYSTEM
-- ============================================

local function initPlayerEnergy(player)
	playerEnergy[player.UserId] = CONFIG.STARTING_ENERGY
	print("⚡ " .. player.Name .. " energy initialized: " .. CONFIG.STARTING_ENERGY)
end

_G.getPlayerEnergy = function(player)
	return playerEnergy[player.UserId] or CONFIG.STARTING_ENERGY
end

_G.setPlayerEnergy = function(player, amount)
	playerEnergy[player.UserId] = math.min(amount, CONFIG.MAX_ENERGY)
end

-- ============================================
-- TIME GETTERS
-- ============================================

_G.getCurrentTime = function(player)
	return _G.playerGameTime[player.UserId] or gameTime
end

_G.getCurrentTimeFormatted = function(player)
	local time = _G.playerGameTime[player.UserId] or gameTime
	return formatTime(time)
end

_G.getDayCount = function(player)
	return _G.playerDayCount[player.UserId] or dayCount
end

_G.getCurrentSeason = function(player)
	return _G.playerSeason[player.UserId] or currentSeason
end

-- ============================================
-- TIME LOOP
-- ============================================

local function updateGameTime()
	local baseIncrement = CONFIG.CYCLE_DURATION / 1440
	gameTime = gameTime + baseIncrement

	if gameTime >= 1440 then
		dayCount = dayCount + 1
		gameTime = CONFIG.START_TIME

		local seasons = {"Spring", "Summer", "Fall", "Winter"}
		local seasonIndex = math.ceil(dayCount / 28)
		currentSeason = seasons[(seasonIndex % 4 == 0) and 4 or (seasonIndex % 4)]

		print("\n📅 ===== DAY " .. dayCount .. " (" .. currentSeason .. ") =====")
		print("⏰ New day started at: " .. formatTime(gameTime))
	end
end

spawn(function()
	while true do
		task.wait(1)
		updateGameTime()

		-- Update lighting
		local totalTime = 0
		local playerCount = 0
		for _, player in pairs(Players:GetPlayers()) do
			totalTime = totalTime + (_G.playerGameTime[player.UserId] or gameTime)
			playerCount = playerCount + 1
		end

		local avgTime = playerCount > 0 and (totalTime / playerCount) or gameTime
		updateLighting(avgTime)

		-- Update per-player time
		for _, player in pairs(Players:GetPlayers()) do
			local playerTime = _G.playerGameTime[player.UserId] or gameTime
			local baseIncrement = CONFIG.CYCLE_DURATION / 1440  -- ✅ Define baseIncrement here
			_G.playerGameTime[player.UserId] = playerTime + baseIncrement

			if _G.playerGameTime[player.UserId] >= 1440 then
				_G.playerDayCount[player.UserId] = (_G.playerDayCount[player.UserId] or 1) + 1
				_G.playerGameTime[player.UserId] = CONFIG.START_TIME

				local dayNum = _G.playerDayCount[player.UserId]
				local seasons = {"Spring", "Summer", "Fall", "Winter"}
				local seasonIndex = math.ceil(dayNum / 28)
				_G.playerSeason[player.UserId] = seasons[(seasonIndex % 4 == 0) and 4 or (seasonIndex % 4)]
			end
		end
	end
end)

-- ============================================
-- PLAYER INITIALIZATION
-- ============================================

Players.PlayerAdded:Connect(function(player)
	initPlayerEnergy(player)
	task.wait(0.5)

	local DataStoreModule = game.ServerScriptService:FindFirstChild("DataStoreModule") and require(game.ServerScriptService.DataStoreModule)
	local data = nil
	if DataStoreModule then
		data = DataStoreModule.PlayerData[player.UserId]
	end

	-- ✅ FIXED: Properly check if data exists
	if data then
		-- Load saved time from Farm
		_G.playerGameTime[player.UserId] = data.GameTime or CONFIG.START_TIME
		_G.playerDayCount[player.UserId] = data.DayCount or 1
		_G.playerSeason[player.UserId] = data.Season or "Spring"

		print("⏰ " .. player.Name .. " loaded from DataStore:")
		print("   Day:", _G.playerDayCount[player.UserId])
		print("   Season:", _G.playerSeason[player.UserId])
		print("   Time:", formatTime(_G.playerGameTime[player.UserId]))
	else
		-- New player (shouldn't happen if Farm already saved)
		_G.playerGameTime[player.UserId] = CONFIG.START_TIME
		_G.playerDayCount[player.UserId] = 1
		_G.playerSeason[player.UserId] = "Spring"
		print("🆕 " .. player.Name .. " starting: Day 1, Spring, 11:00 AM")
	end

end)

Players.PlayerRemoving:Connect(function(player)
	playerEnergy[player.UserId] = nil
	_G.playerGameTime[player.UserId] = nil
	_G.playerDayCount[player.UserId] = nil
	_G.playerSeason[player.UserId] = nil
end)

print("✅ Day/Night Manager ready!")
