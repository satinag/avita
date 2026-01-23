-- GamePassConfig.lua (ModuleScript)
-- Central configuration for all GamePasses
-- Location: ReplicatedStorage

local GamePassConfig = {}

-- ============================================
-- GAMEPASS IDS (REPLACE WITH YOUR ACTUAL IDS!)
-- ============================================
GamePassConfig.PASSES = {
	MarketplaceVIP = {
		ID = 1683230870, -- REPLACE: Quick-list from Farm
		Name = "Marketplace VIP",
		Icon = "🛍️",
		Description = "List items from anywhere + VIP Town button",
		Benefits = {
			"List items without going to Town",
			"Instant VIP teleport button",
			"Priority marketplace placement"
		}
	},

	AutoSellGuarantee = {
		ID = 1684986789, -- REPLACE: Auto-sell after 1 day
		Name = "Auto-Sell Guarantee",
		Icon = "💰",
		Description = "Listings auto-sell after 1 game day",
		Benefits = {
			"Guaranteed sales in 24h",
			"Full asking price (no fees)",
			"Never lose inventory to expired listings"
		}
	}
}

-- ============================================
-- HELPER FUNCTIONS
-- ============================================

-- Get GamePass data by name
function GamePassConfig.GetPass(passName)
	return GamePassConfig.PASSES[passName]
end

-- Get all GamePass IDs as array
function GamePassConfig.GetAllPassIDs()
	local ids = {}
	for _, pass in pairs(GamePassConfig.PASSES) do
		table.insert(ids, pass.ID)
	end
	return ids
end

-- Get GamePass name by ID
function GamePassConfig.GetPassNameByID(passId)
	for name, pass in pairs(GamePassConfig.PASSES) do
		if pass.ID == passId then
			return name
		end
	end
	return nil
end

print("✅ GamePassConfig loaded")
return GamePassConfig
