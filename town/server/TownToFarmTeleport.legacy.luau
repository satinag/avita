-- TownToFarmTeleport.lua (Town Place)
local TeleportService = game:GetService("TeleportService")
local Players = game:GetService("Players")
local DataStoreService = game:GetService("DataStoreService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local FARM_PLACE_ID = 96456254275756
local FarmStore = DataStoreService:GetDataStore("PlayerFarms_v1")

local farmPortal = workspace:WaitForChild("FarmPortal", 10)
if not farmPortal then
	warn("❌ FarmPortal not found in Town!")
	return
end

local prompt = farmPortal:FindFirstChildOfClass("ProximityPrompt")
if not prompt then
	warn("❌ No ProximityPrompt in FarmPortal!")
	return
end

-- Create RemoteEvent for instant GUI feedback
local ShowTeleportScreen = Instance.new("RemoteEvent")
ShowTeleportScreen.Name = "ShowTeleportScreen"
ShowTeleportScreen.Parent = ReplicatedStorage

local teleporting = {}

prompt.Triggered:Connect(function(player)
	local userId = player.UserId

	if teleporting[userId] then
		return
	end
	teleporting[userId] = true

	-- ✅ INSTANT FEEDBACK - Show loading screen immediately
	ShowTeleportScreen:FireClient(player, "🚜 Preparing your farm...")

	print("🚜 " .. player.Name .. " going to farm...")

	-- Get farm code
	local loadSuccess, savedCode = pcall(function()
		return FarmStore:GetAsync("Farm_" .. userId)
	end)

	if loadSuccess and savedCode and type(savedCode) == "string" and #savedCode > 10 then
		print("   ✅ Found farm, teleporting...")

		-- Update loading message
		ShowTeleportScreen:FireClient(player, "🌾 Entering your farm...")

		local teleportSuccess, teleportError = pcall(function()
			TeleportService:TeleportToPrivateServer(FARM_PLACE_ID, savedCode, {player})
		end)

		if not teleportSuccess then
			warn("   ❌ Teleport failed: " .. tostring(teleportError))
			ShowTeleportScreen:FireClient(player, "❌ Teleport failed!")
			task.wait(2)
			teleporting[userId] = nil
		end
	else
		warn("   ❌ No farm found")
		ShowTeleportScreen:FireClient(player, "❌ No farm found!")
		task.wait(2)
		player:Kick("❌ No farm found!\n\nPlease rejoin the game.")
		teleporting[userId] = nil
	end
end)

print("✅ Town → Farm teleport ready")
