-- ServerScriptService/DayNightManager

local TweenService = game:GetService("TweenService")
local Players = game:GetService("Players")
local Lighting = game:GetService("Lighting")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

print("🌙 Day/Night Manager loaded!")

-- ============================================
-- CONFIGURATION (Stardew Valley inspired)
-- ============================================

local CONFIG = {
	CYCLE_DURATION = 900,   -- ✅ 15 minutes per full cycle
	START_TIME = 660,
	END_TIME = 1440,
	BEDTIME_WARN = 1380,
	SLEEP_TIME = 1200,
	PASSOUT_TIME = 1500,

	STARTING_ENERGY = 270,
	MAX_ENERGY = 500,
	ENERGY_RESTORE_NIGHT = 0.9,
	ENERGY_RESTORE_LATE = 0.75,
	ENERGY_RESTORE_VERY_LATE = 0.5,

	DAY_START = 360,    -- 6:00 AM
	DAY_END = 1080,     -- 6:00 PM

	-- Time speed multipliers
	DAY_TIME_SPEED = 1,
	NIGHT_TIME_SPEED = 2,

	DAY_GROWTH_MULTIPLIER = 1,
	NIGHT_GROWTH_MULTIPLIER = 0.5,

	SEASON_GROWTH = {
		Spring = 1.0,
		Summer = 1.2,
		Fall = 0.9,
		Winter = 0.3
	},

	SEASON_PRICE = {
		Spring = 1.0,
		Summer = 1.1,
		Fall = 1.2,
		Winter = 0.5
	},

	-- ✅ SINGLE SOURCE OF TRUTH - BRIGHTNESS ONLY
	SEASON_BRIGHTNESS = {
		Spring = {Day = 2.5, Evening = 2.0, Night = 1.3},
		Summer = {Day = 2.5, Evening = 1.8, Night = 1},
		Fall = {Day = 1.8, Evening = 1.2, Night = 1.2},
		Winter = {Day = 1.5, Evening = 1.0, Night = 1.0}
	},

	-- ✅ WEATHER MULTIPLIERS (applied on top of brightness)
	WEATHER_MULTIPLIERS = {
		Rain = 0.5,
		Snow = 0.7,
		Clear = 1.0
	},

	WEATHER_CHANCE = {
		Spring = 0.9,   -- 20% chance of rain
		Summer = 0.1,   -- 10% chance of rain
		Fall = 0.3,     -- 30% chance of rain
		Winter = 0.4    -- 40% chance of snow
	},
}

-- ✅ EXPOSE CONFIG GLOBALLY
_G.DAY_GROWTH_MULTIPLIER = CONFIG.DAY_GROWTH_MULTIPLIER
_G.NIGHT_GROWTH_MULTIPLIER = CONFIG.NIGHT_GROWTH_MULTIPLIER

-- ============================================
-- GLOBAL STATE
-- ============================================

local gameTime = CONFIG.START_TIME
local isPaused = false
local dayCount = 1
local currentSeason = "Spring"
local playerEnergy = {}
local currentWeather = nil
local forcedWeather = nil
local weatherStartTime = 0
local weatherDuration = 0


-- ✅ TRACK LAST UPDATE TO AVOID REPEATS
local lastLightingUpdate = {
	season = currentSeason,
	time = gameTime,
	weather = currentWeather
}

-- ✅ EXPOSE THESE FOR DATASTOREMODULE
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
-- TIME CHECKS
-- ============================================

local function isDaytime()
	return gameTime >= CONFIG.DAY_START and gameTime < CONFIG.DAY_END
end

local function isNighttime()
	return not isDaytime()
end

local function getGrowthMultiplier()
	return isDaytime() and CONFIG.DAY_GROWTH_MULTIPLIER or CONFIG.NIGHT_GROWTH_MULTIPLIER
end

-- ============================================
-- ✅ SEASON HELPERS
-- ============================================

_G.getSeasonGrowthMultiplier = function(player)
	local season = _G.getCurrentSeason(player)
	return CONFIG.SEASON_GROWTH[season] or 1.0
end

_G.getSeasonPriceMultiplier = function(player)
	local season = _G.getCurrentSeason(player)
	return CONFIG.SEASON_PRICE[season] or 1.0
end

-- ============================================
-- TIME OF DAY HELPERS
-- ============================================

local function getTimeOfDay(timeToCheck)
	timeToCheck = timeToCheck or gameTime
	if timeToCheck >= CONFIG.DAY_START and timeToCheck < CONFIG.DAY_END then
		return "Day"
	elseif timeToCheck >= 1380 then  -- 11:00 PM = Full Night
		return "Night"
	else
		return "Evening"  -- 10:00 PM - 11:00 PM
	end
end

_G.getTimeOfDay = function(player)
	local time = player and _G.playerGameTime[player.UserId] or gameTime
	return getTimeOfDay(time)
end

_G.isDayTime = function(player)
	return _G.getTimeOfDay(player) == "Day"
end

_G.isNightTime = function(player)
	return _G.getTimeOfDay(player) == "Night"
end

_G.isEveningTime = function(player)
	return _G.getTimeOfDay(player) == "Evening"
end

-- ============================================
-- LIGHTING & VISUALS
-- ============================================

local function updateLighting(season, timeToCheck, weatherType)
	timeToCheck = timeToCheck or gameTime
	weatherType = weatherType or currentWeather or "Clear"

	local seasonConfig = CONFIG.SEASON_BRIGHTNESS[season] or CONFIG.SEASON_BRIGHTNESS.Spring
	local weatherMultiplier = CONFIG.WEATHER_MULTIPLIERS[weatherType] or CONFIG.WEATHER_MULTIPLIERS["Clear"]
	local timeOfDay = getTimeOfDay(timeToCheck)

	local brightness

	if timeOfDay == "Day" then
		brightness = seasonConfig.Day
	elseif timeOfDay == "Night" then
		brightness = seasonConfig.Night
	else
		brightness = seasonConfig.Evening
	end

	brightness = brightness * weatherMultiplier

	-- ✅ MANIPULATE CLOCKTIME TO KEEP SUN UP LONGER
	local hours = timeToCheck / 60

	-- If it's between 6 PM and 10 PM, slow down the sun's descent
	if hours >= 18 and hours < 22 then
		-- Map 18:00-22:00 (4 hours) to 17:00-18:00 (1 hour sun position)
		local eveningProgress = (hours - 18) / 4  -- 0 to 1
		hours = 17 + eveningProgress  -- Sun stays between 5 PM and 6 PM position
	end

	Lighting.ClockTime = hours
	Lighting.Brightness = brightness
	Lighting.OutdoorAmbient = Color3.fromRGB(128, 128, 128)

end



-- ============================================
-- ✅ WEATHER SYSTEM
-- ============================================

local function startWeather(season, isForced)
	if forcedWeather and not isForced then
		return
	end

	local chance = CONFIG.WEATHER_CHANCE[season] or 0
	local weatherType = nil

	if math.random() < chance then
		weatherType = (season == "Winter") and "Snow" or "Rain"
	end

	if weatherType then
		currentWeather = weatherType
		forcedWeather = isForced or false
		weatherStartTime = gameTime  -- ✅ Record start time
		weatherDuration = math.random(10, 20)  -- ✅ Random 10-20 game minutes

		print("🌧️ " .. weatherType .. " started (will last " .. weatherDuration .. " minutes)")

		local weatherEvent = ReplicatedStorage:FindFirstChild("WeatherEvent")
		if weatherEvent then
			weatherEvent:FireAllClients(weatherType, season)
		end

		updateLighting(season, gameTime, weatherType)
	else
		currentWeather = "Clear"  -- ✅ Changed from nil
		forcedWeather = false
		print("☀️ Clear skies")

		local weatherEvent = ReplicatedStorage:FindFirstChild("WeatherEvent")
		if weatherEvent then
			weatherEvent:FireAllClients("Clear", season)
		end

		updateLighting(season, gameTime, "Clear")
	end
end



-- ============================================
-- ENERGY SYSTEM
-- ============================================

local function initPlayerEnergy(player)
	playerEnergy[player.UserId] = CONFIG.STARTING_ENERGY
	print("⚡ " .. player.Name .. " energy initialized:    " .. CONFIG.STARTING_ENERGY)
end

_G.getPlayerEnergy = function(player)
	return playerEnergy[player.UserId] or CONFIG.STARTING_ENERGY
end

_G.setPlayerEnergy = function(player, amount)
	playerEnergy[player.UserId] = math.min(amount, CONFIG.MAX_ENERGY)
end

_G.consumeEnergy = function(player, amount)
	local current = _G.getPlayerEnergy(player)
	_G.setPlayerEnergy(player, current - amount)
end

_G.restoreEnergyFromFood = function(player, energyAmount)
	_G.setPlayerEnergy(player, _G.getPlayerEnergy(player) + energyAmount)
	print("🍎 " .. player.Name .. " ate food - energy:    " .. _G.getPlayerEnergy(player))
end

-- ============================================
-- SLEEP & BEDTIME
-- ============================================

_G.sendPlayerToBed = function(player)
	local currentTime = _G.playerGameTime[player.UserId] or gameTime
	local energyRestoration = CONFIG.ENERGY_RESTORE_VERY_LATE

	if currentTime <= CONFIG.SLEEP_TIME then
		energyRestoration = CONFIG.ENERGY_RESTORE_NIGHT
		print("😴 " .. player.Name .. " slept early - full restore (90%)")
	elseif currentTime <= 1260 then
		energyRestoration = CONFIG.ENERGY_RESTORE_LATE
		print("😴 " .. player.Name .. " slept late - partial restore (75%)")
	else
		energyRestoration = CONFIG.ENERGY_RESTORE_VERY_LATE
		print("😴 " .. player.Name .. " slept very late - minimal restore (50%)")
	end

	local restoredEnergy = math.floor(CONFIG.MAX_ENERGY * energyRestoration)
	_G.setPlayerEnergy(player, restoredEnergy)

	-- Reset player's day
	_G.playerDayCount[player.UserId] = (_G.playerDayCount[player.UserId] or 1) + 1
	_G.playerGameTime[player.UserId] = CONFIG.START_TIME

	local dayNum = _G.playerDayCount[player.UserId]
	local seasons = {"Spring", "Summer", "Fall", "Winter"}
	local seasonIndex = math.ceil(dayNum / 28)
	_G.playerSeason[player.UserId] = seasons[(seasonIndex % 4) == 0 and 4 or (seasonIndex % 4)]

	print("📅 " .. player.Name .. " advanced to Day " .. dayNum .. " (" .. _G.playerSeason[player.UserId] .. ")")
end

_G.isPlayerInBed = function(player)
	return player:GetAttribute("InBed") or false
end

-- ============================================
-- DAY PROGRESSION
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

_G.getGrowthMultiplier = function(player)
	-- Get player's current time, or use global if no player
	local time = player and _G.playerGameTime[player.UserId] or gameTime
	local isDayNow = time >= CONFIG.DAY_START and time < CONFIG.DAY_END
	return isDayNow and CONFIG.DAY_GROWTH_MULTIPLIER or CONFIG.NIGHT_GROWTH_MULTIPLIER
end

_G.NextDay = function()
	dayCount = dayCount + 1
	gameTime = CONFIG.START_TIME

	local seasons = {"Spring", "Summer", "Fall", "Winter"}
	local seasonIndex = math.ceil(dayCount / 28)
	currentSeason = seasons[(seasonIndex % 4) == 0 and 4 or (seasonIndex % 4)]

	print("\n📅 ===== DAY " .. dayCount .. " (" .. currentSeason .. ") =====")
	print("⏰ New day started at: " .. formatTime(gameTime))

	-- ✅ ROLL FOR WEATHER
	startWeather(currentSeason)

	local DailyQuestManager = require(game:GetService("ServerScriptService"):FindFirstChild("DailyQuestManager") or {})
	if DailyQuestManager and DailyQuestManager.InitializeQuests then
		for _, player in pairs(Players:GetPlayers()) do
			task.spawn(function()
				DailyQuestManager:InitializeQuests(player)
			end)
		end
	end
end

-- ============================================
-- TIME LOOP
-- ============================================

-- ✅ CREATE REMOTES FIRST (before anything uses them)
local timeUpdateRemote = Instance.new("RemoteEvent")
timeUpdateRemote.Name = "TimeUpdate"
timeUpdateRemote.Parent = ReplicatedStorage

local weatherEvent = Instance.new("RemoteEvent")
weatherEvent.Name = "WeatherEvent"
weatherEvent.Parent = ReplicatedStorage

_G.BroadcastGameTime = function(time, day, season)
	timeUpdateRemote:FireAllClients(time, day, season)
end

local function updateGameTime()
	local baseIncrement = CONFIG.CYCLE_DURATION / 1440

	-- ✅ Smooth transition: 1x at day → 2x at midnight → 1x at dawn
	local timeMultiplier = 1
	if not isDaytime() then
		local nightProgress = (gameTime - CONFIG.DAY_END) / (1440 - CONFIG.DAY_END + CONFIG.DAY_START)
		local speedBoost = math.sin(nightProgress * math.pi) * (CONFIG.NIGHT_TIME_SPEED - 1)
		timeMultiplier = 1 + speedBoost
	end

	gameTime = gameTime + (baseIncrement * timeMultiplier)

	-- ✅ CHECK IF WEATHER SHOULD STOP
	if currentWeather and currentWeather ~= "Clear" and not forcedWeather then
		local elapsed = gameTime - weatherStartTime
		if elapsed >= weatherDuration then
			print("☀️ Weather clearing after " .. math.floor(elapsed) .. " game minutes")
			currentWeather = "Clear"
			weatherStartTime = 0
			weatherDuration = 0

			local weatherEvent = ReplicatedStorage:FindFirstChild("WeatherEvent")
			if weatherEvent then
				weatherEvent:FireAllClients("Clear", currentSeason)
			end

			updateLighting(currentSeason, gameTime, "Clear")
		end
	end

	if gameTime >= 1440 then
		_G.NextDay()
	end

	if gameTime >= CONFIG.PASSOUT_TIME and gameTime < (CONFIG.PASSOUT_TIME + 1) then
		for _, player in pairs(Players:GetPlayers()) do
			if not _G.isPlayerInBed(player) then
				local cash = player:FindFirstChild("leaderstats") and player:FindFirstChild("leaderstats"):FindFirstChild("Cash")
				if cash then
					local penalty = math.floor(cash.Value * 0.1)
					cash.Value = math.max(0, cash.Value - penalty)
					print("⚠️ " .. player.Name .. " passed out! Lost $" .. penalty)
				end

				_G.setPlayerEnergy(player, 250)
				_G.sendPlayerToBed(player)
			end
		end
	end
end




spawn(function()
	while true do
		task.wait(1)

		if not isPaused then
			updateGameTime()

			-- ✅ UPDATE LIGHTING BASED ON AVERAGE PLAYER TIME (WITH SEASON & WEATHER)
			local totalTime = 0
			local playerCount = 0
			for _, player in pairs(Players:GetPlayers()) do
				totalTime = totalTime + (_G.playerGameTime[player.UserId] or gameTime)
				playerCount = playerCount + 1
			end

			-- Use average time for lighting (or global if no players)
			local avgTime = playerCount > 0 and (totalTime / playerCount) or gameTime

			-- ✅ ONLY UPDATE LIGHTING IF SOMETHING CHANGED
			local shouldUpdate = false
			if lastLightingUpdate.season ~= currentSeason then
				shouldUpdate = true
			elseif lastLightingUpdate.weather ~= currentWeather then
				shouldUpdate = true
			elseif math.abs(lastLightingUpdate.time - avgTime) >= 1 then  -- Update every 1 game minute
				shouldUpdate = true
			end

			if shouldUpdate then
				updateLighting(currentSeason, avgTime, currentWeather)
				lastLightingUpdate.season = currentSeason
				lastLightingUpdate.time = avgTime
				lastLightingUpdate.weather = currentWeather
			end

			-- ✅ BROADCAST PER-PLAYER TIME (INCREMENT FOR EACH PLAYER)
			for _, player in pairs(Players:GetPlayers()) do
				local playerTime = _G.playerGameTime[player.UserId] or gameTime
				local baseIncrement = CONFIG.CYCLE_DURATION / 1440

				-- ✅ SAME smooth transition logic
				local timeMultiplier = 1
				local isPlayerDay = playerTime >= CONFIG.DAY_START and playerTime < CONFIG.DAY_END

				if not isPlayerDay then
					local nightProgress = (playerTime - CONFIG.DAY_END) / (1440 - CONFIG.DAY_END + CONFIG.DAY_START)
					local speedBoost = math.sin(nightProgress * math.pi) * (CONFIG.NIGHT_TIME_SPEED - 1)
					timeMultiplier = 1 + speedBoost
				end

				_G.playerGameTime[player.UserId] = playerTime + (baseIncrement * timeMultiplier)

				-- Check if day should advance
				if _G.playerGameTime[player.UserId] >= 1440 then
					_G.playerDayCount[player.UserId] = (_G.playerDayCount[player.UserId] or 1) + 1
					_G.playerGameTime[player.UserId] = CONFIG.START_TIME

					local dayNum = _G.playerDayCount[player.UserId]
					local seasons = {"Spring", "Summer", "Fall", "Winter"}
					local seasonIndex = math.ceil(dayNum / 28)
					_G.playerSeason[player.UserId] = seasons[(seasonIndex % 4) == 0 and 4 or (seasonIndex % 4)]

					print("📅 " .. player.Name .. " advanced to Day " .. dayNum .. " (" .. _G.playerSeason[player.UserId] .. ")")
				end

				local time = _G.playerGameTime[player.UserId]
				local day = _G.playerDayCount[player.UserId]
				local season = _G.playerSeason[player.UserId]

				_G.BroadcastGameTime(time, day, season)
			end

		end
	end
end)

-- PLAYER INITIALIZATION
Players.PlayerAdded:Connect(function(player)
	initPlayerEnergy(player)
	task.wait(0.5)

	local DataStoreModule
	local dsModule = game.ServerScriptService:FindFirstChild("DataStoreModule")
	if dsModule then
		DataStoreModule = require(dsModule)
	end
	local data = nil
	if DataStoreModule then
		data = DataStoreModule.PlayerData[player.UserId]
	end
	
	if data and data.GameTime then
		-- EXISTING PLAYER - Load saved time + offline progress
		_G.playerGameTime[player.UserId] = data.GameTime or CONFIG.START_TIME
		_G.playerDayCount[player.UserId] = data.DayCount or 1
		_G.playerSeason[player.UserId] = data.Season or "Spring"

		local lastSaveTime = data.LastSaveTime or 0
		local currentTime = os.time()
		local offlineSeconds = currentTime - lastSaveTime

		-- 🆕 CALCULATE OFFLINE DAYS WITH 7-DAY CAP
		local realSecondsPerGameDay = CONFIG.CYCLE_DURATION  -- 900 seconds = 15 minutes
		local offlineGameDays = math.floor(offlineSeconds / realSecondsPerGameDay)

		-- 🔒 CAP AT 7 DAYS MAXIMUM
		local MAX_OFFLINE_DAYS = 7
		if offlineGameDays > MAX_OFFLINE_DAYS then
			print(player.Name .. " was offline for " .. offlineGameDays .. " days, capping at " .. MAX_OFFLINE_DAYS)
			offlineGameDays = MAX_OFFLINE_DAYS
		end

		if offlineGameDays > 0 then
			-- Advance day count
			_G.playerDayCount[player.UserId] = _G.playerDayCount[player.UserId] + offlineGameDays

			-- Update season based on new day count
			local dayNum = _G.playerDayCount[player.UserId]
			local seasons = {"Spring", "Summer", "Fall", "Winter"}
			local seasonIndex = math.ceil(dayNum / 28)
			_G.playerSeason[player.UserId] = seasons[(seasonIndex % 4 == 0) and 4 or (seasonIndex % 4)]

			print(player.Name .. " was offline for " .. offlineGameDays .. " game days!")
			print("Advanced from Day " .. (_G.playerDayCount[player.UserId] - offlineGameDays) .. " to Day " .. _G.playerDayCount[player.UserId])
		end

		-- Calculate remaining partial day progress (only if under 7 days)
		local remainingOfflineSeconds = offlineSeconds
		if offlineGameDays == MAX_OFFLINE_DAYS then
			-- If capped, only count the time for exactly 7 days
			remainingOfflineSeconds = MAX_OFFLINE_DAYS * realSecondsPerGameDay
		end

		local offlineGameMinutes = (remainingOfflineSeconds % realSecondsPerGameDay) / (CONFIG.CYCLE_DURATION / 1440)
		_G.playerGameTime[player.UserId] = _G.playerGameTime[player.UserId] + offlineGameMinutes

		-- Wrap time if it exceeded a day
		while _G.playerGameTime[player.UserId] >= 1440 do
			_G.playerGameTime[player.UserId] = _G.playerGameTime[player.UserId] - 1440
			_G.playerDayCount[player.UserId] = _G.playerDayCount[player.UserId] + 1
		end

		-- Update season again after time wrapping
		local dayNum = _G.playerDayCount[player.UserId]
		local seasons = {"Spring", "Summer", "Fall", "Winter"}
		local seasonIndex = math.ceil(dayNum / 28)
		_G.playerSeason[player.UserId] = seasons[(seasonIndex % 4 == 0) and 4 or (seasonIndex % 4)]

		print(player.Name .. " loaded Day " .. _G.playerDayCount[player.UserId] .. " at " .. formatTime(_G.playerGameTime[player.UserId]))

		if offlineSeconds > 60 then
			print("Offline for " .. math.floor(offlineSeconds / 60) .. " real minutes")
		end
	else
		-- NEW PLAYER - Start at 11:00 AM, no offline calc
		_G.playerGameTime[player.UserId] = CONFIG.START_TIME  -- 660 = 11:00 AM
		_G.playerDayCount[player.UserId] = 1
		_G.playerSeason[player.UserId] = "Spring"
		print("New player " .. player.Name .. " starting at " .. formatTime(CONFIG.START_TIME) .. ", Day 1, Spring")
	end

	print("Initialized energy for " .. player.Name)
end)



Players.PlayerRemoving:Connect(function(player)
	playerEnergy[player.UserId] = nil
	_G.playerGameTime[player.UserId] = nil
	_G.playerDayCount[player.UserId] = nil
	_G.playerSeason[player.UserId] = nil
end)

-- ============================================
-- ADMIN COMMANDS
-- ============================================

_G.setGameTime = function(minutes)
	gameTime = math.clamp(minutes, 0, 1440)

	-- ✅ ALSO UPDATE ALL PLAYERS' TIME
	for _, player in pairs(Players:GetPlayers()) do
		_G.playerGameTime[player.UserId] = gameTime
	end

	print("⏰ Game time set to: " .. formatTime(gameTime))

	-- ✅ FORCE LIGHTING UPDATE WITH WEATHER
	updateLighting(currentSeason, gameTime, currentWeather)
end

_G.forceSeason = function(season)
	if not CONFIG.SEASON_GROWTH[season] then
		warn("❌ Invalid season: " .. season .. " (must be Spring, Summer, Fall, or Winter)")
		return
	end

	currentSeason = season

	-- ✅ UPDATE ALL PLAYERS' SEASONS
	for _, player in pairs(Players:GetPlayers()) do
		_G.playerSeason[player.UserId] = season
	end

	print("🌍 Forced season to: " .. season)

	-- ✅ UPDATE LIGHTING
	updateLighting(season, gameTime, currentWeather)
end

_G.forceWeather = function(weatherType, season)
	print("🌦️ forceWeather called: " .. weatherType .. " (" .. season .. ")")  -- ✅ ADD THIS

	season = season or currentSeason
	currentSeason = season
	currentWeather = weatherType
	forcedWeather = true

	-- ✅ UPDATE ALL PLAYERS' SEASONS
	for _, player in pairs(Players:GetPlayers()) do
		_G.playerSeason[player.UserId] = season
	end

	local weatherEvent = ReplicatedStorage:FindFirstChild("WeatherEvent")
	if weatherEvent then
		weatherEvent:FireAllClients(weatherType, season)
	end

	-- ✅ UPDATE LIGHTING
	updateLighting(season, gameTime, weatherType)
end

_G.pauseDay = function()
	isPaused = true
	print("⏸️ Day paused")
end

_G.resumeDay = function()
	isPaused = false
	print("▶️ Day resumed")
end

_G.skipToTime = function(hours, minutes)
	gameTime = (hours * 60) + minutes
	print("⏭️ Skipped to: " .. formatTime(gameTime))
end

print("✅ Day/Night Manager ready!")
print("   Current time: " .. formatTime(gameTime))
print("   Cycle duration: " .. (CONFIG.CYCLE_DURATION / 60) .. " minutes")
print("   Season system: ✅ Active")
print("   Weather system: ✅ Active")
