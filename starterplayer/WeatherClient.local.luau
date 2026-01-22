-- LocalScript in StarterPlayer > StarterPlayerScripts
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local Lighting = game:GetService("Lighting")

local weatherEvent = ReplicatedStorage:WaitForChild("WeatherEvent", 15)
if not weatherEvent then
	warn("❌ WeatherEvent not found!")
	return
end

print("✅ WeatherClient loaded!")

local currentWeatherType = "Clear"
local isWeatherActive = false
local player = Players. LocalPlayer
local camera = workspace.CurrentCamera

-- ============================================
-- SOUND SETUP
-- ============================================

local rainSound = Instance.new("Sound")
rainSound.Name = "RainSound"
rainSound.SoundId = "http://www.roblox.com/asset/?id=130852656"
rainSound.Volume = 0.5
rainSound. Looped = true
rainSound. Parent = workspace
rainSound. PlayOnRemove = false

local thunderSound = Instance.new("Sound")
thunderSound.Name = "ThunderSound"
thunderSound.SoundId = "rbxassetid://233091161"
thunderSound.Volume = 0.8
thunderSound.Parent = workspace
thunderSound.PlayOnRemove = false

-- ============================================
-- WEATHER FOLDER
-- ============================================

local weatherFolder = workspace:FindFirstChild("WeatherEffects")
if not weatherFolder then
	weatherFolder = Instance.new("Folder")
	weatherFolder.Name = "WeatherEffects"
	weatherFolder.Parent = workspace
end

-- ============================================
-- RAIN SETUP
-- ============================================

local rainDropTemplate = Instance.new("Part")
rainDropTemplate. Anchored = true
rainDropTemplate.CanCollide = false
rainDropTemplate.Transparency = 0.3
rainDropTemplate.BrickColor = BrickColor.new("Pastel light blue")
rainDropTemplate.TopSurface = "Smooth"
rainDropTemplate.BottomSurface = "Smooth"
rainDropTemplate.FormFactor = "Custom"
rainDropTemplate.Size = Vector3.new(0.2, 1.2, 0.2)

local rainMesh = Instance.new("BlockMesh")
rainMesh.Scale = Vector3.new(0.4, 2, 0.4)
rainMesh.Parent = rainDropTemplate

-- ============================================
-- SNOW SETUP (FROM CREATOR STORE)
-- ============================================

local snowModel = workspace:FindFirstChild("WeatherSnowModel")
if not snowModel then
	snowModel = Instance. new("Folder")
	snowModel.Name = "WeatherSnowModel"
	snowModel.Parent = workspace
end

local snowQueue = {}
local snowConfig = {
	SmallestFlakeSize = 8,
	LargestFlakeSize = 15,
	MaxMoveX = 5,
	MinMoveX = -5,
	MaxMoveY = 1,
	MinMoveY = -12,
	MaxMoveZ = 5,
	MinMoveZ = -5,
	CyclesPerLifeMax = 4,
	CyclesPerLifeMin = 2,
	CycleLife = 20,
	MaxTransparency = 0.3,
	RangeX = 8,
	RangeY = 4,
	RangeZ = 8,
	SnowAmountFactor = 3
}

local function getSnowflakeMovement()
	return Vector3.new(
		math. random(snowConfig.MinMoveX, snowConfig.MaxMoveX) / 100,
		math.random(snowConfig.MinMoveY, snowConfig.MaxMoveY) / 100,
		math. random(snowConfig.MinMoveZ, snowConfig.MaxMoveZ) / 100
	)
end

local function getRandomSnowflakePosition(lastValidPlace)
	return CFrame.new() + lastValidPlace: pointToWorldSpace(Vector3.new(
		math. random(-snowConfig.RangeX, snowConfig.RangeX),
		math.random(-3, snowConfig.RangeY),
		math.random(-snowConfig. RangeZ * 2, 0)
		))
end

local function makeSnowFlake(parent, initialCFrame)
	local flakeSize = math.random(snowConfig.SmallestFlakeSize, snowConfig.LargestFlakeSize) / 100

	local flake = Instance.new("Part", parent)
	flake.Anchored = true
	flake.CanCollide = false
	flake.FormFactor = "Custom"
	flake.Size = Vector3.new(1, 1, 1)
	flake.Name = "SnowFlake"
	flake. BottomSurface = "Smooth"
	flake.CFrame = initialCFrame
	flake. Transparency = 1

	local mesh = Instance.new("SpecialMesh", flake)
	mesh.MeshType = "FileMesh"
	mesh.MeshId = "http://www.roblox.com/asset/?id=1185246"
	mesh.TextureId = "http://www.roblox.com/asset/? id=1361097"
	mesh.VertexColor = Vector3.new(1, 1, 1)
	mesh.Scale = Vector3.new(flakeSize, flakeSize, flakeSize)

	local snowFlake = {
		Flake = flake,
		CycleTick = snowConfig.CycleLife,
		CyclesLeft = math.random(snowConfig.CyclesPerLifeMin, snowConfig.CyclesPerLifeMax),
		MoveRate = getSnowflakeMovement(),
		Mode = 0
	}
	table.insert(snowQueue, snowFlake)
end

local function updateSnowQueue()
	local halfLife = snowConfig.CycleLife
	local maxTransparency = snowConfig.MaxTransparency
	local index = 1

	while index <= #snowQueue do
		local snowFlake = snowQueue[index]
		local cycleTick = snowFlake.CycleTick
		local flake = snowFlake.Flake

		if snowFlake.Mode == 2 then
			snowFlake.CyclesLeft = snowFlake.CyclesLeft - 1
			if snowFlake.CyclesLeft <= 0 then
				flake: Destroy()
				table.remove(snowQueue, index)
			else
				snowFlake.CycleTick = snowConfig.CycleLife
				snowFlake.Mode = 0
				index = index + 1
			end
		elseif snowFlake.Mode == 0 then
			flake.Transparency = (cycleTick / halfLife) * maxTransparency + maxTransparency
			flake.CFrame = flake.CFrame + snowFlake.MoveRate
			snowFlake.CycleTick = cycleTick - 1
			if snowFlake.CycleTick <= 0 then
				snowFlake.Mode = 1
			end
			index = index + 1
		elseif snowFlake.Mode == 1 then
			flake.Transparency = (cycleTick / halfLife) * maxTransparency + maxTransparency
			flake.CFrame = flake.CFrame + snowFlake. MoveRate
			snowFlake.CycleTick = cycleTick + 1
			if snowFlake.CycleTick >= halfLife then
				snowFlake.Mode = 2
			end
			index = index + 1
		end
	end
end

-- ============================================
-- LIGHTNING FUNCTION
-- ============================================

local function triggerLightning()
	spawn(function()
		local originalAmbient = Lighting.Ambient
		local originalBrightness = Lighting. Brightness
		local flashTime = 0.15

		Lighting.Ambient = Color3.fromRGB(255, 255, 255)
		Lighting.Brightness = 3
		task.wait(flashTime)
		Lighting.Ambient = originalAmbient
		Lighting. Brightness = originalBrightness

		task.wait(flashTime)

		Lighting.Ambient = Color3.fromRGB(255, 255, 255)
		Lighting.Brightness = 3
		task.wait(flashTime)
		Lighting.Ambient = originalAmbient
		Lighting. Brightness = originalBrightness

		thunderSound:Stop()
		thunderSound:Play()
	end)
end

-- ============================================
-- RAIN FUNCTION
-- ============================================

local rainActive = false

local function startRain()
	rainActive = true
	weatherFolder:ClearAllChildren()

	task.delay(1, function()
		if rainActive and currentWeatherType == "Rain" then
			rainSound:Stop()
			rainSound:Play()
		end
	end)

	spawn(function()
		while rainActive and currentWeatherType == "Rain" do
			task.wait(math.random(5, 10))
			if rainActive and currentWeatherType == "Rain" then
				triggerLightning()
			end
		end
	end)

	spawn(function()
		while rainActive and currentWeatherType == "Rain" do
			for i = 1, 8 do
				if not rainActive or currentWeatherType ~= "Rain" then break end

				local drop = rainDropTemplate:Clone()
				local function onHit(hit)
					drop: Destroy()
				end
				drop. Touched:Connect(onHit)
				drop.Parent = weatherFolder
				drop.CFrame = camera.CoordinateFrame * CFrame.new(
					math.random(-25, 25),
					math.random(40, 55),
					math.random(-25, 25)
				)
				drop.Anchored = false

				task.delay(10, function()
					if drop. Parent then
						drop:Destroy()
					end
				end)

				task.wait(0.03)
			end
			task.wait(0.1)
		end
		weatherFolder:ClearAllChildren()
	end)
end

-- ============================================
-- SNOW FUNCTION
-- ============================================

local snowActive = false
local lastValidPlace = nil

local function startSnow()
	rainActive = false  -- Stop rain if active
	snowActive = true
	weatherFolder:ClearAllChildren()
	snowModel:ClearAllChildren()
	snowQueue = {}
	rainSound:Stop()

	spawn(function()
		while snowActive and currentWeatherType == "Snow" do
			local cameraPos = camera.CoordinateFrame. p
			if cameraPos then
				lastValidPlace = camera. CoordinateFrame
			end

			if lastValidPlace then
				for i = 1, snowConfig. SnowAmountFactor do
					makeSnowFlake(snowModel, getRandomSnowflakePosition(lastValidPlace))
				end
			end

			updateSnowQueue()
			task.wait(0.03)
		end

		snowModel:ClearAllChildren()
		snowQueue = {}
	end)
end

-- ============================================
-- CLEAR WEATHER FUNCTION
-- ============================================

local function clearWeather()
	rainActive = false
	snowActive = false
	rainSound:Stop()
	task.wait(0.1)
	weatherFolder:ClearAllChildren()
	snowModel:ClearAllChildren()
	snowQueue = {}
end

-- ============================================
-- LISTEN FOR WEATHER CHANGES
-- ============================================

weatherEvent. OnClientEvent:Connect(function(weatherType, season)
	print("📡 Weather:  " .. weatherType .. " (" .. season .. ")")

	if weatherType == currentWeatherType then
		return
	end

	currentWeatherType = weatherType

	if weatherType == "Snow" then
		startSnow()
	elseif weatherType == "Rain" then
		startRain()
	else
		clearWeather()
	end
end)

print("✅ WeatherClient ready!")