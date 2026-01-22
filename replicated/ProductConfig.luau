-- ReplicatedStorage/ProductConfig
-- 🎯 SINGLE SOURCE OF TRUTH for ALL game products and prices

local ProductConfig = {}

-- ============================================
-- 🌾 CROPS (Seeds + Harvest Prices)
-- ============================================
ProductConfig.CROPS = {
	Wheat = {
		SeedCost = 40,
		SeedQuantity = 5,
		SellPrice = 25,
		UnlockRequirement = 0,
		GrowTime = 10,
		Emoji = "🌾",
		ConversionRate = 5  -- Crops → Seeds ratio
	},
	Corn = {
		SeedCost = 100,
		SeedQuantity = 5,
		SellPrice = 70,
		UnlockRequirement = 200,
		GrowTime = 20,
		Emoji = "🌽",
		ConversionRate = 5
	},
	Carrot = {
		SeedCost = 60,
		SeedQuantity = 5,
		SellPrice = 40,
		UnlockRequirement = 350,
		GrowTime = 30,
		Emoji = "🥕",
		ConversionRate = 5
	},
	Potato = {
		SeedCost = 200,
		SeedQuantity = 5,
		SellPrice = 130,
		UnlockRequirement = 700,
		GrowTime = 40,
		Emoji = "🥔",
		ConversionRate = 5
	},
	Tomato = {
		SeedCost = 150,
		SeedQuantity = 5,
		SellPrice = 100,
		UnlockRequirement = 1500,
		GrowTime = 50,
		Emoji = "🍅",
		ConversionRate = 5
	},
	Pumpkin = {
		SeedCost = 300,
		SeedQuantity = 5,
		SellPrice = 200,
		UnlockRequirement = 3000,
		GrowTime = 60,
		Emoji = "🎃",
		ConversionRate = 5
	},
	Strawberry = {
		SeedCost = 500,
		SeedQuantity = 5,
		SellPrice = 350,
		UnlockRequirement = 5500,
		GrowTime = 70,
		Emoji = "🍓",
		ConversionRate = 5
	},
	Watermelon = {
		SeedCost = 800,
		SeedQuantity = 5,
		SellPrice = 550,
		UnlockRequirement = 9000,
		GrowTime = 80,
		Emoji = "🍉",
		ConversionRate = 5
	}
}

-- ============================================
-- 🔧 TOOLS
-- ============================================
ProductConfig.TOOLS = {
	ImprovedShovel = {
		Name = "ImprovedShovel",  -- DataStore/Inventory field name
		DisplayName = "Improved Shovel",  -- GUI display name
		Price = 200,
		Icon = "⛏️",
		Effect = "DoubleYield",
		Bonus = 2,
		Description = "Harvest 2 crops instead of 1",
		UpgradeTo = "UpgradedShovel"
	},
	WateringCan = {
		Name = "WateringCan",
		DisplayName = "Watering Can",
		Price = 300,
		Icon = "💧",
		Effect = "GrowthSpeed",
		Bonus = 0.20,
		Description = "Crops grow 20% faster",
		UpgradeTo = "UpgradedWateringCan"
	},
	UpgradedWateringCan = {
		Name = "UpgradedWateringCan",
		DisplayName = "Upgraded Watering Can",
		Price = 2000,
		UnlockTotalEarned = 2000,
		Icon = "💧⭐",
		Effect = "UpgradedGrowthSpeed",
		Bonus = 0.30,
		Description = "30% faster growth",
		Prereq = "WateringCan",
		IsUpgrade = true
	},
	UpgradedShovel = {
		Name = "UpgradedShovel",
		DisplayName = "Upgraded Shovel",
		Price = 5000,
		UnlockTotalEarned = 5000,
		Icon = "⛏️⭐",
		Effect = "UpgradedYield",
		Bonus = 3,
		Description = "Harvest 3 crops",
		Prereq = "ImprovedShovel",
		IsUpgrade = true
	},
	FishingRod = {
		Name = "FishingRod",
		DisplayName = "Fishing Rod",
		Price = 800,
		Icon = "🎣",
		Description = "Catch fish at the pond!"
	}
}

-- ============================================
-- 🐔 ANIMALS
-- ============================================
ProductConfig.ANIMALS = {
	Chicken = {
		Name = "Chicken",
		BuyPrice = 400,
		SellPrice = 300,  -- Player-to-player marketplace base price
		Icon = "🐔",
		ProductType = "Eggs",
		ProductionTime = 60,  -- seconds
		ProductionAmount = 1,
		Description = "Produces eggs every minute"
	},
	Cow = {
		Name = "Cow",
		BuyPrice = 1500,
		SellPrice = 1200,
		Icon = "🐄",
		ProductType = "Milk",
		ProductionTime = 120,
		ProductionAmount = 1,
		Description = "Produces milk every 2 minutes"
	},
	Pig = {
		Name = "Pig",
		BuyPrice = 800,
		SellPrice = 600,
		Icon = "🐷",
		ProductType = "Meat",
		ProductionTime = 180,
		ProductionAmount = 1,
		Description = "Produces meat every 3 minutes"
	},
	Sheep = {
		Name = "Sheep",
		BuyPrice = 1200,
		SellPrice = 900,
		Icon = "🐑",
		ProductType = "Wool",
		ProductionTime = 150,
		ProductionAmount = 1,
		Description = "Produces wool every 2.5 minutes"
	}
}

-- ============================================
-- 🥚 ANIMAL PRODUCTS
-- ============================================
ProductConfig.PRODUCTS = {
	Eggs = {
		Name = "Eggs",
		SellPrice = 20,  -- NPC sell price (at barn)
		QuickSellPrice = 15,  -- NEW - Instant sell at shop
		MarketPriceMin = 15,  -- NEW - Min marketplace price
		MarketPriceMax = 30,  -- NEW - Max marketplace price
		Icon = "🥚",
		Source = "Chicken",
		CollectionTime = 300  -- NEW - 5 minutes per egg
	},
	Milk = {
		Name = "Milk",
		SellPrice = 50,
		QuickSellPrice = 40,
		MarketPriceMin = 40,
		MarketPriceMax = 80,
		Icon = "🥛",
		Source = "Cow",
		CollectionTime = 600
	},
	Meat = {
		Name = "Meat",
		SellPrice = 35,
		QuickSellPrice = 30,
		MarketPriceMin = 30,
		MarketPriceMax = 60,
		Icon = "🥩",
		Source = "Pig",
		CollectionTime = 480
	},
	Wool = {
		Name = "Wool",
		SellPrice = 45,
		QuickSellPrice = 35,
		MarketPriceMin = 35,
		MarketPriceMax = 70,
		Icon = "🧶",
		Source = "Sheep",
		CollectionTime = 720
	},
	Honey = {
		Name = "Honey",
		SellPrice = 30,
		QuickSellPrice = 25,
		MarketPriceMin = 20,
		MarketPriceMax = 40,
		Icon = "🍯",
		Source = "Beehive",
		CollectionTime = 300
	},
	Wax = {
		Name = "Wax",
		SellPrice = 25,
		QuickSellPrice = 20,
		MarketPriceMin = 18,
		MarketPriceMax = 35,
		Icon = "🕯️",
		Source = "Beehive",
		CollectionTime = 600 -- 10 minutes (slower than honey)
	}
}

-- ============================================
-- 🐟 FISH
-- ============================================
ProductConfig.FISH = {
	Salmon = {
		Name = "Salmon",
		SellPrice = 50,
		QuickSellPrice = 40,  -- NEW
		MarketPriceMin = 35,  -- NEW
		MarketPriceMax = 60,  -- NEW
		Icon = "🐟",
		Rarity = "Common",
		Weight = 60
	},
	Tuna = {
		Name = "Tuna",
		SellPrice = 100,
		QuickSellPrice = 80,
		MarketPriceMin = 70,
		MarketPriceMax = 120,
		Icon = "🐠",
		Rarity = "Uncommon",
		Weight = 25
	},
	Bass = {
		Name = "Bass",
		SellPrice = 200,
		QuickSellPrice = 160,
		MarketPriceMin = 140,
		MarketPriceMax = 220,
		Icon = "🐡",
		Rarity = "Rare",
		Weight = 10
	},
	Catfish = {
		Name = "Catfish",
		SellPrice = 400,
		QuickSellPrice = 320,
		MarketPriceMin = 280,
		MarketPriceMax = 450,
		Icon = "🦈",
		Rarity = "Very Rare",
		Weight = 5
	}
}

-- --
-- BEEHIVES
-- --
ProductConfig.BEEHIVES = {
	{
		Level = 1,
		Price = 2000,
		HoneyRate = 30,
		WaxRate = 15
	},
	{
		Level = 2,
		Price = 3500,
		HoneyRate = 45,
		WaxRate = 20
	},
	{
		Level = 3,
		Price = 5500,
		HoneyRate = 65,
		WaxRate = 30
	},
	{
		Level = 4,
		Price = 8000,
		HoneyRate = 90,
		WaxRate = 40
	},
	{
		Level = 5,
		Price = 12000,
		HoneyRate = 120,
		WaxRate = 55
	},
	{
		Level = 6,
		Price = 18000,
		HoneyRate = 160,
		WaxRate = 75
	},
	{
		Level = 7,
		Price = 27000,
		HoneyRate = 210,
		WaxRate = 100
	},
	{
		Level = 8,
		Price = 40000,
		HoneyRate = 280,
		WaxRate = 135
	}
}

ProductConfig.BEEHIVE_CONFIG = {
	MaxQuantity = 8,
	Icon = "🐝",
	Name = "Beehive",
	Description = "Produces honey and wax every hour"
}

-- --
-- HOUSES
-- --
ProductConfig.HOUSES = {
	{
		Name = "Starter Cottage",
		Level = 1,
		Price = 0, -- Free
		Icon = "🏠",
		Description = "Your humble beginning",
		ModelPath = "workspace.Houses.House1",
		Thumbnail = "rbxassetid://86286339012632"
	},
	{
		Name = "Cozy Farmhouse",
		Level = 2,
		Price = 10000,
		Icon = "🏡",
		Description = "Bigger and better living space",
		ModelPath = "workspace.Houses.House2",
		Thumbnail = "rbxassetid://137663208314736"
	},
	{
		Name = "Grand Estate",
		Level = 3,
		Price = 25000,
		Icon = "🏘️",
		Description = "Spacious luxury home",
		ModelPath = "workspace.Houses.House3",
		Thumbnail = "rbxassetid://127545931924354"
	},
	{
		Name = "Mansion",
		Level = 4,
		Price = 50000,
		Icon = "🏰",
		Description = "The ultimate farming empire",
		ModelPath = "workspace.Houses.House4",
		Thumbnail = "rbxassetid://105472243889184"
	}
}

-- ============================================
-- 📋 HELPER FUNCTIONS
-- ============================================

-- --
-- HELPER FUNCTIONS - BEEHIVES
-- --
function ProductConfig.GetBeehiveData(level)
	return ProductConfig.BEEHIVES[level]
end

function ProductConfig.GetBeehivePrice(level)
	local data = ProductConfig.BEEHIVES[level]
	return data and data.Price or 0
end

function ProductConfig.GetBeehiveRate(level)
	local data = ProductConfig.BEEHIVES[level]
	return data and data.HoneyRate or 0
end

function ProductConfig.GetMaxBeehives()
	return ProductConfig.BEEHIVE_CONFIG.MaxQuantity
end

-- --
-- HELPER FUNCTIONS - HOUSES
-- --
function ProductConfig.GetHouseData(level)
	return ProductConfig.HOUSES[level]
end

function ProductConfig.GetHousePrice(level)
	local data = ProductConfig.HOUSES[level]
	return data and data.Price or 0
end

function ProductConfig.GetMaxHouseLevel()
	return #ProductConfig.HOUSES
end


-- Crops
function ProductConfig.GetCropData(cropName)
	return ProductConfig.CROPS[cropName]
end

function ProductConfig.GetSellPrice(cropName)
	local data = ProductConfig.CROPS[cropName]
	return data and data.SellPrice or 0
end

function ProductConfig.GetSeedCost(cropName)
	local data = ProductConfig.CROPS[cropName]
	return data and data.SeedCost or 0
end

-- Tools
function ProductConfig.GetToolData(toolName)
	return ProductConfig.TOOLS[toolName]
end

function ProductConfig.GetAllTools()
	local tools = {}
	for _, tool in pairs(ProductConfig.TOOLS) do
		table.insert(tools, tool)
	end
	return tools
end

-- Animals
function ProductConfig.GetAnimalData(animalName)
	return ProductConfig.ANIMALS[animalName]
end

-- Products
function ProductConfig.GetProductData(productName)
	return ProductConfig.PRODUCTS[productName]
end

function ProductConfig.GetProductSellPrice(productName)
	local data = ProductConfig.PRODUCTS[productName]
	return data and data.SellPrice or 0
end

-- Fish
function ProductConfig.GetFishData(fishName)
	return ProductConfig.FISH[fishName]
end

function ProductConfig.GetFishSellPrice(fishName)
	local data = ProductConfig.FISH[fishName]
	return data and data.SellPrice or 0
end

-- Generic lookup (searches all categories)
function ProductConfig.GetItemData(itemName)
	return ProductConfig.CROPS[itemName]
		or ProductConfig.TOOLS[itemName]
		or ProductConfig.ANIMALS[itemName]
		or ProductConfig.PRODUCTS[itemName]
		or ProductConfig.FISH[itemName]
		or ProductConfig.BUILDINGS[itemName]
end

-- ============================================
-- 🔄 CONVERSION RECIPES (Product → Seeds)
-- ============================================
ProductConfig.CONVERSIONS = {
	Eggs = {
		Input = 10,
		Output = {
			Wheat = 5,
			Corn = 3
		},
		Description = "10 Eggs → 5 Wheat + 3 Corn Seeds"
	},
	Milk = {
		Input = 5,
		Output = {
			Carrot = 3,
			Potato = 2
		},
		Description = "5 Milk → 3 Carrot + 2 Potato Seeds"
	},
	Meat = {
		Input = 3,
		Output = {
			Tomato = 2,
			Pumpkin = 1
		},
		Description = "3 Meat → 2 Tomato + 1 Pumpkin Seed"
	},
	Wool = {
		Input = 5,
		Output = {
			Strawberry = 3,
			Watermelon = 1
		},
		Description = "5 Wool → 3 Strawberry + 1 Watermelon Seed"
	},
	Honey = {
		Input = 10,
		Output = {
			Wheat = 3,
			Corn = 3,
			Carrot = 3
		},
		Description = "10 Honey → 3 Wheat + 3 Corn + 3 Carrot Seeds"
	},
	Wax = {
		Input = 8,
		Output = {Corn = 4, Potato = 2},
		Description = "8 Wax → 4 Corn + 2 Potato Seeds"
	},
	Salmon = {
		Input = 5,
		Output = {
			Wheat = 8
		},
		Description = "5 Salmon → 8 Wheat Seeds"
	},
	Tuna = {
		Input = 3,
		Output = {
			Corn = 5,
			Carrot = 3
		},
		Description = "3 Tuna → 5 Corn + 3 Carrot Seeds"
	},
	Bass = {
		Input = 2,
		Output = {
			Potato = 3,
			Tomato = 2
		},
		Description = "2 Bass → 3 Potato + 2 Tomato Seeds"
	},
	Catfish = {
		Input = 1,
		Output = {
			Pumpkin = 2,
			Strawberry = 2,
			Watermelon = 1
		},
		Description = "1 Catfish → 2 Pumpkin + 2 Strawberry + 1 Watermelon Seed"
	}
}

-- Helper for conversions
function ProductConfig.GetConversionRecipe(productName)
	return ProductConfig.CONVERSIONS[productName]
end

function ProductConfig.CanConvert(player, productName)
	local recipe = ProductConfig.CONVERSIONS[productName]
	if not recipe then return false, "No conversion recipe" end

	local productInventory = player:FindFirstChild("ProductInventory")
	local fishInventory = player:FindFirstChild("FishInventory")

	local inventory = productInventory or fishInventory
	if not inventory then return false, "No inventory" end

	local productValue = inventory:FindFirstChild(productName)
	if not productValue then return false, "Product not found" end

	if productValue.Value < recipe.Input then
		return false, "Need " .. recipe.Input .. " " .. productName
	end

	return true
end


return ProductConfig
