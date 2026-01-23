-- FarmToTownTeleport.lua (Farm Place)
local TeleportService = game:GetService("TeleportService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local TOWN_PLACE_ID = 95651613209851

local townPortal = workspace:WaitForChild("TownPortal", 10)
if not townPortal then
	warn("❌ TownPortal not found!")
	return
end

local prompt = townPortal:FindFirstChildOfClass("ProximityPrompt")
if not prompt then
	warn("❌ No ProximityPrompt!")
	return
end

-- Create RemoteEvent for instant feedback
local ShowTeleportScreen = ReplicatedStorage:FindFirstChild("ShowTeleportScreen")
if not ShowTeleportScreen then
	ShowTeleportScreen = Instance.new("RemoteEvent")
	ShowTeleportScreen.Name = "ShowTeleportScreen"
	ShowTeleportScreen.Parent = ReplicatedStorage
	print("✅ Created ShowTeleportScreen RemoteEvent in Farm")
end

local teleporting = {}

prompt.Triggered:Connect(function(player)
	if teleporting[player.UserId] then
		return
	end
	teleporting[player.UserId] = true

	print("🏙️ " .. player.Name .. " going to Town...")

	-- ✅ INSTANT FEEDBACK - Fire to client immediately
	ShowTeleportScreen:FireClient(player, "🏙️ Traveling to Town...")

	task.wait(0.1) -- Small delay to ensure GUI shows

	local success, err = pcall(function()
		TeleportService:Teleport(TOWN_PLACE_ID, player)
	end)

	if not success then
		warn("❌ Teleport failed: " .. tostring(err))
		ShowTeleportScreen:FireClient(player, "❌ Teleport failed!")
		task.wait(2)
		teleporting[player.UserId] = nil
	end
end)

print("✅ Farm → Town teleport ready")
