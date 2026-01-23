-- TownBuildingConfig.lua (ModuleScript)
-- Defines all marketplace buildings and their product filters
-- Location: ReplicatedStorage (Town place)

local TownBuildingConfig = {}

-- ============================================
-- BUILDING DEFINITIONS
-- ============================================
TownBuildingConfig.BUILDINGS = {
	-- GENERAL MARKETPLACE (All Products)
	{
		ID = "GeneralMarketplace",
		Name = "General Marketplace",
		Icon = "🏪",
		Description = "Buy and sell all farm products",
		WorkspacePath = "workspace.Town.GeneralMarketplace", -- Where building model is located
		AllowedCategories = {"Crops", "Products", "Fish", "Animals"}, -- Show everything
		Color = Color3.fromRGB(100, 150, 200) -- UI theme color
	},

	-- BAKERY (Wheat, Corn flour products)
	{
		ID = "Bakery",
		Name = "Bakery",
		Icon = "🥖",
		Description = "Buy flour, wheat, and corn",
		WorkspacePath = "workspace.Town.Bakery",
		AllowedCategories = {"Crops"}, -- Only crops
		AllowedItems = {"Wheat", "Corn"}, -- Specific items only
		Color = Color3.fromRGB(220, 180, 120)
	},

	-- COOKIE SHOP (Eggs, Milk, Wheat)
	{
		ID = "CookieShop",
		Name = "Cookie Shop",
		Icon = "🍪",
		Description = "Buy ingredients for baking",
		WorkspacePath = "workspace.Town.CookieShop",
		AllowedCategories = {"Products", "Crops"},
		AllowedItems = {"Eggs", "Milk", "Wheat", "Corn"}, -- Baking ingredients
		Color = Color3.fromRGB(200, 150, 100)
	},

	-- COFFEE SHOP (Future: Coffee beans)
	{
		ID = "CoffeeShop",
		Name = "Coffee Shop",
		Icon = "☕",
		Description = "Buy coffee beans and milk",
		WorkspacePath = "workspace.Town.CoffeeShop",
		AllowedCategories = {"Products", "Crops"},
		AllowedItems = {"Milk", "CoffeeBeans"}, -- CoffeeBeans not yet implemented
		Color = Color3.fromRGB(139, 90, 60)
	},

	-- FISHERY (Fish only)
	{
		ID = "Fishery",
		Name = "Fishery",
		Icon = "🐟",
		Description = "Buy and sell fresh fish",
		WorkspacePath = "workspace.Town.Fishery",
		AllowedCategories = {"Fish"}, -- Only fish
		Color = Color3.fromRGB(70, 130, 180)
	},

	-- DAIRY SHOP (Milk, Eggs, Cheese)
	{
		ID = "DairyShop",
		Name = "Dairy Shop",
		Icon = "🥛",
		Description = "Buy dairy and poultry products",
		WorkspacePath = "workspace.Town.DairyShop",
		AllowedCategories = {"Products"},
		AllowedItems = {"Milk", "Eggs", "Cheese"}, -- Cheese not yet implemented
		Color = Color3.fromRGB(240, 248, 255)
	},

	-- BUTCHER SHOP (Meat products)
	{
		ID = "ButcherShop",
		Name = "Butcher Shop",
		Icon = "🥩",
		Description = "Buy meat and animal products",
		WorkspacePath = "workspace.Town.ButcherShop",
		AllowedCategories = {"Products"},
		AllowedItems = {"Meat", "Wool"}, 
		Color = Color3.fromRGB(180, 80, 80)
	},

	-- PRODUCE MARKET (Fresh vegetables)
	{
		ID = "ProduceMarket",
		Name = "Produce Market",
		Icon = "🥕",
		Description = "Buy fresh vegetables",
		WorkspacePath = "workspace.Town.ProduceMarket",
		AllowedCategories = {"Crops"},
		AllowedItems = {"Carrot", "Potato", "Tomato", "Pumpkin"}, -- Vegetables only
		Color = Color3.fromRGB(120, 180, 100)
	},

	-- FRUIT STAND (Fruits)
	{
		ID = "FruitStand",
		Name = "Fruit Stand",
		Icon = "🍓",
		Description = "Buy fresh fruits",
		WorkspacePath = "workspace.Town.FruitStand",
		AllowedCategories = {"Crops"},
		AllowedItems = {"Strawberry", "Watermelon"}, -- Fruits only
		Color = Color3.fromRGB(220, 100, 150)
	},

	-- BEE SHOP (Honey, Wax)
	{
		ID = "BeeShop",
		Name = "Honey & Wax Shop",
		Icon = "🐝",
		Description = "Buy honey and beeswax",
		WorkspacePath = "workspace.Town.BeeShop",
		AllowedCategories = {"Products"},
		AllowedItems = {"Honey", "Wax"},
		Color = Color3.fromRGB(255, 200, 50)
	}
}

-- ============================================
-- HELPER FUNCTIONS
-- ============================================

-- Get building by ID
function TownBuildingConfig.GetBuilding(buildingId)
	for _, building in ipairs(TownBuildingConfig.BUILDINGS) do
		if building.ID == buildingId then
			return building
		end
	end
	return nil
end

-- Check if item is allowed in building
function TownBuildingConfig.IsItemAllowed(buildingId, itemName, itemCategory)
	local building = TownBuildingConfig.GetBuilding(buildingId)
	if not building then return false end

	-- Check category filter
	local categoryAllowed = false
	for _, allowedCat in ipairs(building.AllowedCategories) do
		if allowedCat == itemCategory then
			categoryAllowed = true
			break
		end
	end

	if not categoryAllowed then return false end

	-- Check specific item filter (if exists)
	if building.AllowedItems then
		local itemAllowed = false
		for _, allowedItem in ipairs(building.AllowedItems) do
			if allowedItem == itemName then
				itemAllowed = true
				break
			end
		end
		return itemAllowed
	end

	-- No specific filter = all items in category allowed
	return true
end

-- Get all allowed items for a building
function TownBuildingConfig.GetAllowedItems(buildingId)
	local building = TownBuildingConfig.GetBuilding(buildingId)
	if not building then return {} end

	return {
		Categories = building.AllowedCategories,
		Items = building.AllowedItems -- May be nil (= all items in categories)
	}
end

-- Filter listings by building rules
function TownBuildingConfig.FilterListings(buildingId, allListings)
	local building = TownBuildingConfig.GetBuilding(buildingId)
	if not building then return allListings end

	local filtered = {}

	for _, listing in ipairs(allListings) do
		if TownBuildingConfig.IsItemAllowed(buildingId, listing.ItemName, listing.Category) then
			table.insert(filtered, listing)
		end
	end

	return filtered
end

print("✅ TownBuildingConfig loaded with " .. #TownBuildingConfig.BUILDINGS .. " buildings")
return TownBuildingConfig
