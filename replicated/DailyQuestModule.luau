-- DailyQuestModule.lua (COMPLETE - Copy-paste)
local DailyQuestModule = {}

DailyQuestModule.QuestPool = {
	-- 🌾 WHEAT (Tier 1 - Starter)
	{
		ID = "PlantWheat1", Name = "Plant 5 Wheat Seeds", Description = "Plant 5 Wheat seeds", 
		Type = "Plant", SeedType = "Wheat", Target = 5, 
		Reward = {Cash = 150}, TierReq = 1
	},
	{
		ID = "HarvestWheat1", Name = "Harvest 10 Wheat", Description = "Harvest 10 Wheat crops", 
		Type = "Harvest", CropType = "Wheat", Target = 10, 
		Reward = {Cash = 500}, TierReq = 1
	},

	-- 🌽 CORN (Tier 2 - Barn unlock)
	{
		ID = "PlantCorn1", Name = "Plant 5 Corn Seeds", Description = "Plant 5 Corn seeds", 
		Type = "Plant", SeedType = "Corn", Target = 5, 
		Reward = {Seeds = {Corn = 2}, Cash = 200}, TierReq = 2
	},
	{
		ID = "HarvestCorn1", Name = "Harvest 8 Corn", Description = "Harvest 8 Corn crops", 
		Type = "Harvest", CropType = "Corn", Target = 8, 
		Reward = {Cash = 400}, TierReq = 2
	},

	-- 🥕 CARROT (Tier 3 - Shop starter)
	{
		ID = "PlantCarrot1", Name = "Plant 6 Carrots", Description = "Plant 6 Carrot seeds", 
		Type = "Plant", SeedType = "Carrot", Target = 6, 
		Reward = {Cash = 250}, TierReq = 3
	},
	{
		ID = "HarvestCarrot1", Name = "Harvest 12 Carrots", Description = "Harvest 12 Carrot crops", 
		Type = "Harvest", CropType = "Carrot", Target = 12, 
		Reward = {Cash = 600}, TierReq = 3
	},

	-- 🥔 POTATO (Tier 4 - Easy shop)
	{
		ID = "PlantPotato1", Name = "Plant 4 Potatoes", Description = "Plant 4 Potato seeds", 
		Type = "Plant", SeedType = "Potato", Target = 4, 
		Reward = {Seeds = {Tomato = 2}, Cash = 350}, TierReq = 4
	},
	{
		ID = "HarvestPotato1", Name = "Harvest 8 Potatoes", Description = "Harvest 8 Potato crops", 
		Type = "Harvest", CropType = "Potato", Target = 8, 
		Reward = {Cash = 700}, TierReq = 4
	},

	-- 🍅 TOMATO (Tier 5 - Shop mid)
	{
		ID = "PlantTomato1", Name = "Plant 4 Tomatoes", Description = "Plant 4 Tomato seeds", 
		Type = "Plant", SeedType = "Tomato", Target = 4, 
		Reward = {Cash = 400}, TierReq = 5
	},
	{
		ID = "HarvestTomato1", Name = "Harvest 7 Tomatoes", Description = "Harvest 7 Tomato crops", 
		Type = "Harvest", CropType = "Tomato", Target = 7, 
		Reward = {Cash = 800}, TierReq = 5
	},

	-- 🎃 PUMPKIN (Tier 6 - Mid-game)
	{
		ID = "PlantPumpkin1", Name = "Plant 3 Pumpkins", Description = "Plant 3 Pumpkin seeds", 
		Type = "Plant", SeedType = "Pumpkin", Target = 3, 
		Reward = {Seeds = {Strawberry = 2}, Cash = 600}, TierReq = 6
	},
	{
		ID = "HarvestPumpkin1", Name = "Harvest 6 Pumpkins", Description = "Harvest 6 Pumpkin crops", 
		Type = "Harvest", CropType = "Pumpkin", Target = 6, 
		Reward = {Cash = 1200}, TierReq = 6
	},

	-- 🍓 STRAWBERRY (Tier 7 - Late mid-game)
	{
		ID = "PlantStrawberry1", Name = "Plant 4 Strawberries", Description = "Plant 4 Strawberry seeds", 
		Type = "Plant", SeedType = "Strawberry", Target = 4, 
		Reward = {Cash = 700}, TierReq = 7
	},
	{
		ID = "HarvestStrawberry1", Name = "Harvest 8 Strawberries", Description = "Harvest 8 Strawberry crops", 
		Type = "Harvest", CropType = "Strawberry", Target = 8, 
		Reward = {Cash = 1400}, TierReq = 7
	},

	-- 🍉 WATERMELON (Tier 8 - Endgame)
	{
		ID = "PlantWatermelon1", Name = "Plant 2 Watermelons", Description = "Plant 2 Watermelon seeds", 
		Type = "Plant", SeedType = "Watermelon", Target = 2, 
		Reward = {Seeds = {Watermelon = 1}, Cash = 1500}, TierReq = 8
	},
	{
		ID = "HarvestWatermelon1", Name = "Harvest 4 Watermelons", Description = "Harvest 4 Watermelon crops", 
		Type = "Harvest", CropType = "Watermelon", Target = 4, 
		Reward = {Cash = 3000}, TierReq = 8
	},

	-- 🌟 UNIVERSAL QUESTS (All tiers)
	{
		ID = "SellCrops1", Name = "Sell 20 Crops", Description = "Sell any 20 crops at the Barn", 
		Type = "Sell", Target = 20, Reward = {Cash = 800}, TierReq = 1
	},
	{
		ID = "EarnCash1", Name = "Earn 1500 Cash", Description = "Earn 1500 cash total", 
		Type = "Earn", Target = 1500, Reward = {Cash = 1000}, TierReq = 1
	},
	
	-- ============================================
	-- 🐔 ANIMAL QUESTS
	-- ============================================
	{
		ID = "CollectEggs1", 
		Name = "Collect Eggs", 
		Description = "Collect 10 eggs from chickens", 
		Type = "Collect", 
		ProductType = "Eggs", 
		Target = 10, 
		Reward = {Cash = 300}, 
		TierReq = 2  -- Unlocks after barn
	},
	{
		ID = "CollectEggs2", 
		Name = "Egg Collection Streak", 
		Description = "Collect 25 eggs from chickens", 
		Type = "Collect", 
		ProductType = "Eggs", 
		Target = 25, 
		Reward = {Cash = 600, Seeds = {Corn = 3}}, 
		TierReq = 4
	},
	{
		ID = "CollectMilk1", 
		Name = "Fresh Milk", 
		Description = "Collect 5 milk from cows", 
		Type = "Collect", 
		ProductType = "Milk", 
		Target = 5, 
		Reward = {Cash = 400}, 
		TierReq = 3
	},
	{
		ID = "CollectMilk2", 
		Name = "Dairy Farm", 
		Description = "Collect 15 milk from cows", 
		Type = "Collect", 
		ProductType = "Milk", 
		Target = 15, 
		Reward = {Cash = 1000, Seeds = {Potato = 5}}, 
		TierReq = 5
	},
	{
		ID = "CollectMeat1", 
		Name = "Meat Supplier", 
		Description = "Collect 8 meat from pigs", 
		Type = "Collect", 
		ProductType = "Meat", 
		Target = 8, 
		Reward = {Cash = 500}, 
		TierReq = 4
	},
	{
		ID = "CollectWool1", 
		Name = "Wool Collector", 
		Description = "Collect 10 wool from sheep", 
		Type = "Collect", 
		ProductType = "Wool", 
		Target = 10, 
		Reward = {Cash = 550}, 
		TierReq = 4
	},
	{
		ID = "SellProducts1", 
		Name = "Product Vendor", 
		Description = "Sell any 15 animal products at the barn", 
		Type = "SellProduct", 
		Target = 15, 
		Reward = {Cash = 700}, 
		TierReq = 3
	},
	{
		ID = "SellProducts2", 
		Name = "Market Expert", 
		Description = "Sell any 40 animal products", 
		Type = "SellProduct", 
		Target = 40, 
		Reward = {Cash = 1500}, 
		TierReq = 6
	},
	{
		ID = "OwnAnimals1", 
		Name = "Animal Farm", 
		Description = "Own at least 3 different animal types", 
		Type = "OwnAnimals", 
		Target = 3, 
		Reward = {Cash = 800}, 
		TierReq = 4
	},

	-- ============================================
	-- 🐝 BEEHIVE QUESTS
	-- ============================================
	{
		ID = "CollectHoney1", 
		Name = "Honey Harvest", 
		Description = "Collect 20 honey from beehives", 
		Type = "Collect", 
		ProductType = "Honey", 
		Target = 20, 
		Reward = {Cash = 500}, 
		TierReq = 4
	},
	{
		ID = "CollectHoney2", 
		Name = "Sweet Success", 
		Description = "Collect 50 honey from beehives", 
		Type = "Collect", 
		ProductType = "Honey", 
		Target = 50, 
		Reward = {Cash = 1200, Seeds = {Pumpkin = 3}}, 
		TierReq = 6
	},
	{
		ID = "CollectWax1", 
		Name = "Wax Worker", 
		Description = "Collect 15 wax from beehives", 
		Type = "Collect", 
		ProductType = "Wax", 
		Target = 15, 
		Reward = {Cash = 600}, 
		TierReq = 5
	},
	{
		ID = "CollectWax2", 
		Name = "Wax Master", 
		Description = "Collect 35 wax from beehives", 
		Type = "Collect", 
		ProductType = "Wax", 
		Target = 35, 
		Reward = {Cash = 1400}, 
		TierReq = 7
	},
	{
		ID = "OwnBeehives1", 
		Name = "Bee Keeper", 
		Description = "Own at least 3 beehives", 
		Type = "OwnBeehives", 
		Target = 3, 
		Reward = {Cash = 900}, 
		TierReq = 5
	},
	{
		ID = "OwnBeehives2", 
		Name = "Apiary Owner", 
		Description = "Own at least 6 beehives", 
		Type = "OwnBeehives", 
		Target = 6, 
		Reward = {Cash = 2000}, 
		TierReq = 7
	},

	-- ============================================
	-- 🎣 FISHING QUESTS
	-- ============================================
	{
		ID = "CatchFish1", 
		Name = "First Catch", 
		Description = "Catch any 5 fish", 
		Type = "CatchFish", 
		Target = 5, 
		Reward = {Cash = 400}, 
		TierReq = 3
	},
	{
		ID = "CatchFish2", 
		Name = "Fishing Spree", 
		Description = "Catch any 15 fish", 
		Type = "CatchFish", 
		Target = 15, 
		Reward = {Cash = 1000}, 
		TierReq = 5
	},
	{
		ID = "CatchFish3", 
		Name = "Master Angler", 
		Description = "Catch any 30 fish", 
		Type = "CatchFish", 
		Target = 30, 
		Reward = {Cash = 2500, Seeds = {Watermelon = 5}}, 
		TierReq = 7
	},
	{
		ID = "CatchRareFish1", 
		Name = "Rare Catch", 
		Description = "Catch 1 Bass or Catfish", 
		Type = "CatchRareFish", 
		FishRarity = {"Rare", "Very Rare"}, 
		Target = 1, 
		Reward = {Cash = 1000}, 
		TierReq = 5
	},
	{
		ID = "CatchRareFish2", 
		Name = "Trophy Hunter", 
		Description = "Catch 5 rare fish (Bass/Catfish)", 
		Type = "CatchRareFish", 
		FishRarity = {"Rare", "Very Rare"}, 
		Target = 5, 
		Reward = {Cash = 3500}, 
		TierReq = 7
	},
	{
		ID = "SellFish1", 
		Name = "Fish Vendor", 
		Description = "Sell any 10 fish at the barn", 
		Type = "SellFish", 
		Target = 10, 
		Reward = {Cash = 700}, 
		TierReq = 4
	},
	{
		ID = "SellFish2", 
		Name = "Fish Market Pro", 
		Description = "Sell any 25 fish", 
		Type = "SellFish", 
		Target = 25, 
		Reward = {Cash = 1800}, 
		TierReq = 6
	},
	{
		ID = "CatchSalmon1", 
		Name = "Salmon Run", 
		Description = "Catch 10 Salmon", 
		Type = "CatchFish", 
		FishType = "Salmon", 
		Target = 10, 
		Reward = {Cash = 600}, 
		TierReq = 4
	},
	{
		ID = "CatchTuna1", 
		Name = "Tuna Hunter", 
		Description = "Catch 5 Tuna", 
		Type = "CatchFish", 
		FishType = "Tuna", 
		Target = 5, 
		Reward = {Cash = 800}, 
		TierReq = 5
	},

	-- ============================================
	-- 🏪 MARKETPLACE QUESTS (NEW!)
	-- ============================================
	{
		ID = "ListItems1", 
		Name = "First Listing", 
		Description = "List 3 items on the marketplace", 
		Type = "ListMarketplace", 
		Target = 3, 
		Reward = {Cash = 500}, 
		TierReq = 3
	},
	{
		ID = "ListItems2", 
		Name = "Market Tycoon", 
		Description = "List 10 items on the marketplace", 
		Type = "ListMarketplace", 
		Target = 10, 
		Reward = {Cash = 1500}, 
		TierReq = 5
	},
	{
		ID = "BuyItems1", 
		Name = "Smart Shopper", 
		Description = "Purchase 5 items from the marketplace", 
		Type = "BuyMarketplace", 
		Target = 5, 
		Reward = {Cash = 600}, 
		TierReq = 4
	},
	{
		ID = "SellMarket1", 
		Name = "Successful Seller", 
		Description = "Have 5 listings sold by other players", 
		Type = "MarketplaceSold", 
		Target = 5, 
		Reward = {Cash = 1200}, 
		TierReq = 5
	},

	-- ============================================
	-- 🎯 MIXED/COMBO QUESTS
	-- ============================================
	{
		ID = "DiverseFarmer1", 
		Name = "Diverse Farmer", 
		Description = "Harvest crops AND collect animal products (10 of each)", 
		Type = "Mixed", 
		Requirements = {
			{Type = "Harvest", Target = 10},
			{Type = "Collect", Target = 10}
		},
		Reward = {Cash = 1200, Seeds = {Strawberry = 5}}, 
		TierReq = 6
	},
	{
		ID = "AllRounder1", 
		Name = "All-Rounder", 
		Description = "Plant 5 crops, collect 5 products, catch 5 fish", 
		Type = "Mixed", 
		Requirements = {
			{Type = "Plant", Target = 5},
			{Type = "Collect", Target = 5},
			{Type = "CatchFish", Target = 5}
		},
		Reward = {Cash = 2000}, 
		TierReq = 7
	},

	-- ============================================
	-- 💰 ECONOMY QUESTS
	-- ============================================
	{
		ID = "SpendCash1", 
		Name = "Big Spender", 
		Description = "Spend 2000 cash on upgrades", 
		Type = "SpendCash", 
		Target = 2000, 
		Reward = {Cash = 1000}, 
		TierReq = 4
	},
	{
		ID = "SpendCash2", 
		Name = "Investment King", 
		Description = "Spend 5000 cash on upgrades", 
		Type = "SpendCash", 
		Target = 5000, 
		Reward = {Cash = 2500}, 
		TierReq = 6
	}
}

return DailyQuestModule
