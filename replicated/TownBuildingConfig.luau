-- TownBuildingConfig.lua (ModuleScript)
-- Configuration for Town shops with sell cooldown system
-- Location: ReplicatedStorage (accessible from both Farm and Town)

local TownBuildingConfig = {}

-- ============================================
-- COOLDOWN CONFIGURATION
-- ============================================
TownBuildingConfig.SELL_COOLDOWN = 12 * 60 -- 12 game hours = 720 game minutes

-- ============================================
-- BUILDING DEFINITIONS
-- ============================================
TownBuildingConfig.BUILDINGS = {
	{
		ID = "Bakery",
		Name = "Bakery",
		Icon = "🍞",
		Description = "Sell wheat and corn for 20% more!",
		AcceptedCategories = {"Crops"},
		AcceptedItems = {"Wheat", "Corn"},
		PriceMultiplier = 1.20,
		Color = Color3.fromRGB(220, 180, 120)
	},
	{
		ID = "Fishery",
		Name = "Fishery",
		Icon = "🐟",
		Description = "Sell fish for 30% more!",
		AcceptedCategories = {"Fish"},
		AcceptedItems = nil, -- All fish accepted
		PriceMultiplier = 1.30,
		Color = Color3.fromRGB(70, 130, 180)
	},
	{
		ID = "DairyShop",
		Name = "Dairy Shop",
		Icon = "🥛",
		Description = "Sell milk and eggs for 25% more!",
		AcceptedCategories = {"Products"},
		AcceptedItems = {"Milk", "Eggs"},
		PriceMultiplier = 1.25,
		Color = Color3.fromRGB(240, 248, 255)
	},
	{
		ID = "CookieShop",
		Name = "Cookie Shop",
		Icon = "🍪",
		Description = "Sell baking ingredients for 25% more!",
		AcceptedCategories = {"Products", "Crops"},
		AcceptedItems = {"Eggs", "Milk", "Wheat"},
		PriceMultiplier = 1.25,
		Color = Color3.fromRGB(200, 150, 100)
	},
	{
		ID = "ProduceMarket",
		Name = "Produce Market",
		Icon = "🥕",
		Description = "Sell vegetables for 20% more!",
		AcceptedCategories = {"Crops"},
		AcceptedItems = {"Carrot", "Potato", "Tomato", "Pumpkin"},
		PriceMultiplier = 1.20,
		Color = Color3.fromRGB(120, 180, 100)
	},
	{
		ID = "FruitStand",
		Name = "Fruit Stand",
		Icon = "🍓",
		Description = "Sell fruits for 25% more!",
		AcceptedCategories = {"Crops"},
		AllowedItems = {"Strawberry", "Watermelon"},
		PriceMultiplier = 1.25,
		Color = Color3.fromRGB(220, 100, 150)
	},
	{
		ID = "BeeShop",
		Name = "Bee Shop",
		Icon = "🐝",
		Description = "Sell honey and wax for 35% more!",
		AcceptedCategories = {"Products"},
		AcceptedItems = {"Honey", "Wax"},
		PriceMultiplier = 1.35,
		Color = Color3.fromRGB(255, 200, 50)
	},
	{
		ID = "ButcherShop",
		Name = "Butcher Shop",
		Icon = "🥩",
		Description = "Sell meat and wool for 25% more!",
		AcceptedCategories = {"Products"},
		AcceptedItems = {"Meat", "Wool"},
		PriceMultiplier = 1.25,
		Color = Color3.fromRGB(180, 80, 80)
	}
}

-- Helper: Get building by ID
function TownBuildingConfig.GetBuilding(buildingId)
	for _, building in ipairs(TownBuildingConfig.BUILDINGS) do
		if building.ID == buildingId then
			return building
		end
	end
	return nil
end

-- Helper: Check if item is accepted
function TownBuildingConfig.IsItemAccepted(buildingId, itemName, itemCategory)
	local building = TownBuildingConfig.GetBuilding(buildingId)
	if not building then return false end

	-- Check category
	local categoryAccepted = false
	for _, cat in ipairs(building.AcceptedCategories) do
		if cat == itemCategory then
			categoryAccepted = true
			break
		end
	end

	if not categoryAccepted then return false end

	-- Check specific items (if filter exists)
	if building.AcceptedItems then
		for _, item in ipairs(building.AcceptedItems) do
			if item == itemName then
				return true
			end
		end
		return false
	end

	return true -- No filter, all items in category accepted
end

-- Helper: Calculate cooldown remaining (in game minutes)
function TownBuildingConfig.GetCooldownRemaining(lastSellTime, currentGameTime)
	if not lastSellTime or lastSellTime == 0 then
		return 0 -- No cooldown
	end

	local elapsed = currentGameTime - lastSellTime
	local remaining = TownBuildingConfig.SELL_COOLDOWN - elapsed

	return math.max(0, remaining)
end

-- Helper: Format cooldown as "Xh Ym"
function TownBuildingConfig.FormatCooldown(gameMinutes)
	if gameMinutes <= 0 then
		return "Ready!"
	end

	local hours = math.floor(gameMinutes / 60)
	local minutes = math.floor(gameMinutes % 60)

	if hours > 0 then
		return string.format("%dh %dm", hours, minutes)
	else
		return string.format("%dm", minutes)
	end
end

return TownBuildingConfig
