-- TownShopProximityHandler.lua (UPDATED - Deep Search)
-- Handles ProximityPrompt triggers for Town buildings
-- Location: ServerScriptService (Town place)

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

-- Create RemoteEvent to open shop GUI
local OpenTownShopEvent = ReplicatedStorage:FindFirstChild("OpenTownShopEvent")
if not OpenTownShopEvent then
	OpenTownShopEvent = Instance.new("RemoteEvent")
	OpenTownShopEvent.Name = "OpenTownShopEvent"
	OpenTownShopEvent.Parent = ReplicatedStorage
end

print("🏪 TownShopProximityHandler loading...")

-- ============================================
-- BUILDING DEFINITIONS (matching TownBuildingConfig)
-- ============================================
local BUILDINGS = {
	"Bakery",
	"Fishery",
	"DairyShop",
	"CookieShop",
	"ProduceMarket",
	"FruitStand",
	"BeeShop",
	"ButcherShop"
}

-- ============================================
-- HELPER: Deep search for ProximityPrompt
-- ============================================
local function findProximityPrompt(parent)
	-- First, check direct children
	local prompt = parent:FindFirstChildOfClass("ProximityPrompt")
	if prompt then
		return prompt
	end

	-- If not found, search all descendants
	for _, descendant in ipairs(parent:GetDescendants()) do
		if descendant:IsA("ProximityPrompt") then
			return descendant
		end
	end

	return nil
end

-- ============================================
-- HELPER: Format building name for display
-- ============================================
local function formatBuildingName(buildingID)
	-- Convert "BeeShop" -> "Bee Shop"
	-- Convert "DairyShop" -> "Dairy Shop"
	local formatted = buildingID:gsub("(%l)(%u)", "%1 %2") -- Add space before capital letters
	return formatted
end

-- ============================================
-- CONNECT PROXIMITY PROMPTS
-- ============================================
task.wait(2) -- Wait for workspace to load

local townFolder = workspace:WaitForChild("Town", 10)
if not townFolder then
	warn("❌ Town folder not found in workspace!")
	return
end

local connectedCount = 0

for _, buildingID in ipairs(BUILDINGS) do
	local building = townFolder:FindFirstChild(buildingID)

	if not building then
		warn("❌ Building not found in Town folder:", buildingID)
		continue
	end

	-- Deep search for ProximityPrompt
	local prompt = findProximityPrompt(building)

	if not prompt then
		warn("❌ No ProximityPrompt found in:", buildingID, "- Searched all descendants")
		continue
	end

	-- Configure prompt
	prompt.ActionText = "Sell Items"
	prompt.ObjectText = formatBuildingName(buildingID)
	prompt.KeyboardKeyCode = Enum.KeyCode.E
	prompt.MaxActivationDistance = 10

	-- Connect trigger
	prompt.Triggered:Connect(function(player)
		print("🏪", player.Name, "opened", buildingID)

		-- Fire event to client to open GUI
		OpenTownShopEvent:FireClient(player, buildingID)
	end)

	connectedCount = connectedCount + 1
	print("✅ Connected ProximityPrompt:", buildingID, "->", prompt:GetFullName())
end

print("✅ TownShopProximityHandler ready! Connected", connectedCount, "/", #BUILDINGS, "buildings")
