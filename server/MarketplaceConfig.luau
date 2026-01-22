-- MarketplaceConfig.lua (ServerScriptService - ModuleScript)
-- Configuration for marketplace: categories, price limits, fees

local MarketplaceConfig = {}

-- ============================================
-- MARKETPLACE SETTINGS
-- ============================================

MarketplaceConfig.SETTINGS = {
	MAX_LISTINGS_PER_PLAYER = 5,
	LISTING_FEE_PERCENT = 5,
	LISTING_DURATION_DAYS = 7,
	MIN_PRICE = 1,
	MAX_PRICE = 999999,
}

-- ============================================
-- CATEGORIES & ITEMS
-- ============================================

MarketplaceConfig.CATEGORIES = {
	Crops = {
		Items = {"Wheat", "Corn", "Carrot", "Potato", "Tomato", "Pumpkin", "Strawberry", "Watermelon"},
		Icon = "🌾",
		InventoryFolder = "CropInventory",
		DefaultPriceMultiplier = 1.2
	},
	Products = {
		Items = {"Eggs", "Milk", "Meat", "Wool", "Honey"},
		Icon = "🥚",
		InventoryFolder = "ProductInventory",
		DefaultPriceMultiplier = 1.3
	},
	Fish = {
		Items = {"Salmon", "Tuna", "Bass", "Catfish"},
		Icon = "🐟",
		InventoryFolder = "FishInventory",
		DefaultPriceMultiplier = 1.4
	},
	Animals = {
		Items = {"Chicken", "Cow", "Pig", "Sheep"},
		Icon = "🐔",
		InventoryFolder = "AnimalInventory",
		MinPrice = 400,
		MaxPrice = 50000
	}
}

-- ============================================
-- PRICE LIMITS PER ITEM
-- ============================================

MarketplaceConfig.PRICE_LIMITS = {
	Wheat = {Min = 1, Max = 500},
	Corn = {Min = 1, Max = 500},
	Carrot = {Min = 1, Max = 500},
	Potato = {Min = 1, Max = 500},
	Tomato = {Min = 1, Max = 500},
	Pumpkin = {Min = 1, Max = 1000},
	Strawberry = {Min = 1, Max = 2000},
	Watermelon = {Min = 1, Max = 3000},
	Eggs = {Min = 1, Max = 100},
	Milk = {Min = 1, Max = 200},
	Meat = {Min = 1, Max = 200},
	Wool = {Min = 1, Max = 200},
	Honey = {Min = 1, Max = 100},
	Salmon = {Min = 1, Max = 200},
	Tuna = {Min = 1, Max = 300},
	Bass = {Min = 1, Max = 400},
	Catfish = {Min = 1, Max = 500},
}

-- ============================================
-- HELPER FUNCTIONS
-- ============================================

function MarketplaceConfig.GetCategoryForItem(itemName)
	for categoryName, categoryData in pairs(MarketplaceConfig.CATEGORIES) do
		for _, item in ipairs(categoryData.Items) do
			if item == itemName then
				return categoryName
			end
		end
	end
	return nil
end

function MarketplaceConfig.GetInventoryFolder(itemName)
	local categoryName = MarketplaceConfig.GetCategoryForItem(itemName)
	if categoryName then
		return MarketplaceConfig.CATEGORIES[categoryName].InventoryFolder
	end
	return nil
end

function MarketplaceConfig.GetPriceLimits(itemName)
	return MarketplaceConfig.PRICE_LIMITS[itemName] or {Min = MarketplaceConfig.SETTINGS.MIN_PRICE, Max = MarketplaceConfig.SETTINGS.MAX_PRICE}
end

function MarketplaceConfig.ValidatePrice(itemName, pricePerUnit)
	local limits = MarketplaceConfig.GetPriceLimits(itemName)

	if pricePerUnit < limits.Min then
		return false, "Price too low (min: $" .. limits.Min .. ")"
	end

	if pricePerUnit > limits.Max then
		return false, "Price too high (max: $" .. limits.Max .. ")"
	end

	return true
end

function MarketplaceConfig.CalculateListingFee(totalPrice)
	return math.floor(totalPrice * (MarketplaceConfig.SETTINGS.LISTING_FEE_PERCENT / 100))
end

function MarketplaceConfig.GetItemEmoji(itemName)
	local emojis = {
		Wheat = "🌾", Corn = "🌽", Carrot = "🥕", Potato = "🥔",
		Tomato = "🍅", Pumpkin = "🎃", Strawberry = "🍓", Watermelon = "🍉",
		Eggs = "🥚", Milk = "🥛", Meat = "🥩", Wool = "🧶", Honey = "🍯",
		Salmon = "🐟", Tuna = "🐟", Bass = "🐠", Catfish = "🐡",
		Chicken = "🐔", Cow = "🐄", Pig = "🐷", Sheep = "🐑"
	}
	return emojis[itemName] or "📦"
end

return MarketplaceConfig
