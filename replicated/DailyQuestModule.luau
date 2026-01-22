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
	}
}

return DailyQuestModule
