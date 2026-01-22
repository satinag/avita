-- ReplicatedStorage/FarmStatsConfig
-- Shared configuration for Farm Journal stats and achievements

local FarmStatsConfig = {}

-- Achievement definitions
FarmStatsConfig.ACHIEVEMENTS = {
	{ID = "FarmOwner", Name = "🏡 Farm Owner", Description = "Own 10 plots", Requirement = 10, StatKey = "PlotsOwned"},
	{ID = "MasterFarmer", Name = "🌾 Master Farmer", Description = "Harvest 500 crops", Requirement = 500, StatKey = "TotalCropsHarvested"},
	{ID = "Wealthy", Name = "💰 Wealthy", Description = "Earn $10,000", Requirement = 10000, StatKey = "TotalCashEarned"},
	{ID = "AnimalLover", Name = "🐔 Animal Lover", Description = "Own all 4 animals", Requirement = 4, StatKey = "AnimalsOwned"},
	{ID = "BeeKeeper", Name = "🐝 Bee Keeper", Description = "Own 5 beehives", Requirement = 5, StatKey = "BeehivesOwned"},
}

-- Format large numbers (1000 -> 1,000)
function FarmStatsConfig.FormatNumber(num)
	local formatted = tostring(math.floor(num))
	return formatted:reverse():gsub("(%d%d%d)", "%1,"):reverse():gsub("^,", "")
end

-- Format currency ($1500 -> $1,500)
function FarmStatsConfig.FormatCash(amount)
	return "$" .. FarmStatsConfig.FormatNumber(amount)
end

return FarmStatsConfig
