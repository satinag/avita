-- Central configuration for ALL Robux products
return {
	-- ToolStore
	["Improved Shovel"] = {
		Type = "Product",
		ProductId = 1671667150,  -- Replace with your ID
		RobuxPrice = 20,
		Grant = "ToolsOwned.Improved Shovel"
	},
	["UpgradedShovel"] = {
		Type = "Product",
		ProductId = 1671749206,  -- Replace with your ID
		RobuxPrice = 50,
		Grant = "ToolsOwned.UpgradedShovel"
	},
	["Watering Can"] = {
		Type = "Product",
		ProductId = 1112223334,
		RobuxPrice = 75,
		Grant = "ToolsOwned.Watering Can"
	},

	-- PoultryShop
	["Chicken"] = {
		Type = "Product",
		ProductId = 5556667778,
		RobuxPrice = 100,
		Grant = "PoultryOwned.Chicken"
	},
	["Cow"] = {
		Type = "Product",
		ProductId = 9998887776,
		RobuxPrice = 300,
		Grant = "PoultryOwned.Cow"
	},
	["Pig"] = {
		Type = "Product",
		ProductId = 4443332221,
		RobuxPrice = 200,
		Grant = "PoultryOwned.Pig"
	},

	-- Universal (can use anywhere)
	["Cash500"] = {
		Type = "Product",
		ProductId = 7778889990,
		RobuxPrice = 25,
		Grant = "Cash+500"
	},
	["House2"] = {
		Type = "Product",
		ProductId = 1234567890,  -- ⚠️ REPLACE WITH YOUR PRODUCT ID
		RobuxPrice = 150,
		Grant = "HouseLevel+2"
	},
	["House3"] = {
		Type = "Product",
		ProductId = 1234567891,  -- ⚠️ REPLACE WITH YOUR PRODUCT ID
		RobuxPrice = 300,
		Grant = "HouseLevel+3"
	},
	["House4"] = {
		Type = "Product",
		ProductId = 1234567892,  -- ⚠️ REPLACE WITH YOUR PRODUCT ID
		RobuxPrice = 500,
		Grant = "HouseLevel+4"
	}
}
