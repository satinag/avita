-- LobbyTeleporter - Teleports players to their personal farm
local TeleportService = game:GetService("TeleportService")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local DataStoreService = game:GetService("DataStoreService")

-- ========================================
-- CONFIGURATION
-- ========================================
local FARM_PLACE_ID = 96456254275756  -- ⚠️ REPLACE WITH YOUR FARM PLACE ID!
local FarmStore = DataStoreService:GetDataStore("PlayerFarms_v1")

-- ========================================
-- DISABLE IN STUDIO
-- ========================================
if RunService:IsStudio() then
	warn("🔧 STUDIO MODE - Teleports disabled")
	warn("   Publish and test from Roblox website!")
	return
end

-- ========================================
-- LOBBY SYSTEM
-- ========================================
print("═══════════════════════════════════════")
print("🌐 LOBBY SERVER ACTIVE")
print("   Farm Place ID: " .. FARM_PLACE_ID)
print("═══════════════════════════════════════")

local teleporting = {}

Players.PlayerAdded:Connect(function(player)
	local userId = player.UserId

	-- Prevent duplicate teleports
	if teleporting[userId] then
		warn("⚠️ " .. player.Name .. " already being teleported")
		return
	end
	teleporting[userId] = true

	print("👤 " .. player.Name .. " joined lobby (ID: " .. userId .. ")")

	-- Wait for character to load
	local character = player.Character or player.CharacterAdded:Wait()
	print("   → Character loaded")
	task.wait(1.5)

	-- Check if player still connected
	if not player.Parent or not Players:FindFirstChild(player.Name) then
		warn("   → Player disconnected during loading")
		teleporting[userId] = nil
		return
	end

	local serverCode = nil

	-- ========================================
	-- CHECK FOR EXISTING FARM
	-- ========================================
	print("   → Checking for existing farm...")
	local loadSuccess, savedCode = pcall(function()
		return FarmStore:GetAsync("Farm_" .. userId)
	end)

	if loadSuccess and savedCode and type(savedCode) == "string" and #savedCode > 10 then
		serverCode = savedCode
		print("   ✅ Found existing farm")
		print("      Code: " .. string.sub(serverCode, 1, 15) .. "...")
	else
		-- ========================================
		-- CREATE NEW FARM
		-- ========================================
		print("   → No existing farm found")
		print("   → Creating new reserved server...")

		local reserveSuccess, newCode = pcall(function()
			return TeleportService:ReserveServer(FARM_PLACE_ID)
		end)

		if reserveSuccess and newCode then
			serverCode = newCode
			print("   ✅ New farm created!")
			print("      Code: " .. string.sub(serverCode, 1, 15) .. "...")

			-- Save the farm code for future joins
			local saveSuccess, saveError = pcall(function()
				FarmStore:SetAsync("Farm_" .. userId, serverCode)
			end)

			if saveSuccess then
				print("   ✅ Farm code saved to DataStore")
			else
				warn("   ⚠️ Failed to save farm code: " .. tostring(saveError))
				warn("      Player can still join, but won't persist")
			end
		else
			-- Critical failure
			warn("   ❌ FAILED to create reserved server!")
			warn("      Error: " .. tostring(newCode))
			player:Kick("❌ Could not create your farm.\n\nPlease rejoin the game!")
			teleporting[userId] = nil
			return
		end
	end

	-- ========================================
	-- FINAL CHECKS BEFORE TELEPORT
	-- ========================================
	task.wait(0.5)

	if not player.Parent or not Players:FindFirstChild(player.Name) then
		warn("   → Player left before teleport")
		teleporting[userId] = nil
		return
	end

	-- ========================================
	-- TELEPORT TO FARM
	-- ========================================
	print("   → Teleporting " .. player.Name .. " to their farm...")

	local teleportSuccess, teleportError = pcall(function()
		TeleportService:TeleportToPrivateServer(FARM_PLACE_ID, serverCode, {player})
	end)

	if teleportSuccess then
		print("   ✅ TELEPORT SUCCESSFUL")
		print("      " .. player.Name .. " sent to their personal farm")
	else
		warn("   ❌ TELEPORT FAILED!")
		warn("      Error: " .. tostring(teleportError))
		player:Kick("❌ Could not enter your farm.\n\nError: " .. tostring(teleportError) .. "\n\nPlease rejoin!")
	end

	-- Cleanup
	task.delay(10, function()
		teleporting[userId] = nil
	end)
end)

-- ========================================
-- CLEANUP ON PLAYER LEAVE
-- ========================================
Players.PlayerRemoving:Connect(function(player)
	teleporting[player.UserId] = nil
	print("👋 " .. player.Name .. " left lobby")
end)

print("✅ Lobby system initialized")
print("   Waiting for players...")
print("═══════════════════════════════════════")
