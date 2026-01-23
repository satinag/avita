-- TownTutorialConfig.lua (ModuleScript)
-- Scalable tutorial system for Town buildings/features
-- Location: ReplicatedStorage (Town place)

local TownTutorialConfig = {}

-- ============================================
-- TUTORIAL DEFINITIONS
-- ============================================
TownTutorialConfig.TUTORIALS = {
	-- INITIAL WELCOME (Shows on first join)
	{
		ID = "Welcome",
		Trigger = "OnJoin",
		Priority = 1,
		ShowOnce = true,
		Title = "Welcome to Farm Town! 🌾",
		Message = "This is the Town hub where you can:\n• Trade with other players\n• Visit shops\n• Complete quests\n\nHead to the Farm Portal to start farming!",
		Duration = 8,
		HighlightTarget = "FarmPortal", -- Workspace path
		HighlightDuration = 15
	},

	-- FARM PORTAL
	{
		ID = "FarmPortal",
		Trigger = "Proximity",
		Priority = 2,
		ShowOnce = true,
		TargetObject = "Workspace.FarmPortal",
		Title = "🚜 Your Private Farm",
		Message = "Enter here to go to your personal farm!\nYour farm is private - only you can access it.",
		Duration = 5
	},

	-- MARKETPLACE (General)
	{
		ID = "Marketplace",
		Trigger = "Proximity",
		Priority = 3,
		ShowOnce = true,
		TargetObject = "Workspace.Town.GeneralMarketplace",
		Title = "🏪 General Marketplace",
		Message = "Buy and sell all types of farm products here!\nBrowse listings from other players.",
		Duration = 5
	},

	-- BAKERY (Door has prompt)
	{
		ID = "Bakery",
		Trigger = "Proximity",
		Priority = 4,
		ShowOnce = true,
		TargetObject = "Town.Bakery",  -- Finds Workspace.Town.Bakery.Door ✓
		Title = "🥖 Bakery",
		Message = "Trade wheat and corn here!\nSpecialized shop for grain products.",
		Duration = 4
	},

	-- FISHERY
	{
		ID = "Fishery",
		Trigger = "Proximity",
		Priority = 5,
		ShowOnce = true,
		TargetObject = "Workspace.Town.Fishery",
		Title = "🐟 Fishery",
		Message = "Sell your catches here!\nAll fish types accepted.",
		Duration = 4
	},

	-- COOKIE SHOP
	{
		ID = "CookieShop",
		Trigger = "Proximity",
		Priority = 6,
		ShowOnce = true,
		TargetObject = "Town.CookieShop",
		Title = "🍪 Cookie Shop",
		Message = "Trade baking ingredients!\nEggs, milk, wheat, and more.",
		Duration = 4
	},

	-- DAIRY SHOP
	{
		ID = "DairyShop",
		Trigger = "Proximity",
		Priority = 7,
		ShowOnce = true,
		TargetObject = "Workspace.Town.DairyShop",
		Title = "🥛 Dairy Shop",
		Message = "Dairy and poultry products!\nMilk, eggs, cheese trading hub.",
		Duration = 4
	},

	-- BEE SHOP
	{
		ID = "BeeShop",
		Trigger = "Proximity",
		Priority = 8,
		ShowOnce = true,
		TargetObject = "Workspace.Town.BeeShop",
		Title = "🐝 Honey & Wax Shop",
		Message = "Trade honey and beeswax here!\nSpecialized beekeeping market.",
		Duration = 4
	},

	-- GAMEPASS SHOP
	{
		ID = "GamePassShop",
		Trigger = "Proximity",
		Priority = 9,
		ShowOnce = true,
		TargetObject = "Wsorkspace.GamePassKiosk",
		Title = "🛒 GamePass Shop",
		Message = "Unlock special abilities!\n• Quick-list from Farm\n• Auto-sell guarantee\n• And more!",
		Duration = 5
	},

	-- RETURN TO FARM REMINDER
	{
		ID = "ReturnReminder",
		Trigger = "Timer",
		TriggerAfter = 120, -- 2 minutes in Town
		ShowOnce = false,
		Title = "🚜 Ready to Farm?",
		Message = "Don't forget to visit your farm!\nGrow crops, raise animals, and more.",
		Duration = 5
	}
}

-- ============================================
-- HELPER FUNCTIONS
-- ============================================

-- Get tutorial by ID
function TownTutorialConfig.GetTutorial(tutorialId)
	for _, tutorial in ipairs(TownTutorialConfig.TUTORIALS) do
		if tutorial.ID == tutorialId then
			return tutorial
		end
	end
	return nil
end

-- Get all proximity-triggered tutorials
function TownTutorialConfig.GetProximityTutorials()
	local tutorials = {}
	for _, tutorial in ipairs(TownTutorialConfig.TUTORIALS) do
		if tutorial.Trigger == "Proximity" then
			table.insert(tutorials, tutorial)
		end
	end
	return tutorials
end

-- Get tutorials by trigger type
function TownTutorialConfig.GetTutorialsByTrigger(triggerType)
	local tutorials = {}
	for _, tutorial in ipairs(TownTutorialConfig.TUTORIALS) do
		if tutorial.Trigger == triggerType then
			table.insert(tutorials, tutorial)
		end
	end
	return tutorials
end

print("✅ TownTutorialConfig loaded with " .. #TownTutorialConfig.TUTORIALS .. " tutorials")
return TownTutorialConfig
