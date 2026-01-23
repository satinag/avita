-- ReplicatedStorage/TutorialLevelConfig
-- Unified tutorial system with path-based targets and multiple indicator types

local TutorialLevelConfig = {}

-- ============================================
-- PATH RESOLVER
-- ============================================
function TutorialLevelConfig:ResolvePathToTarget(pathString)
	if not pathString or pathString == "" then
		warn("❌ Empty path provided")
		return nil
	end

	local parts = {}
	for part in string.gmatch(pathString, "[^%.]+") do
		table.insert(parts, part)
	end

	if #parts == 0 then
		warn("❌ Invalid path format: " .. pathString)
		return nil
	end

	local rootName = parts[1]:lower()
	local current = nil
	local startIndex = 2

	if rootName == "workspace" then
		current = workspace
	elseif rootName == "replicatedstorage" then
		current = game:GetService("ReplicatedStorage")
	elseif rootName == "serverstorage" then
		current = game:GetService("ServerStorage")
	elseif rootName == "lighting" then
		current = game:GetService("Lighting")
	else
		current = workspace
		startIndex = 1
	end

	for i = startIndex, #parts do
		local partName = parts[i]
		local nextObj = current:FindFirstChild(partName)

		if not nextObj then
			warn(string.format("❌ Could not find '%s' in path '%s' (step %d/%d)", 
				partName, pathString, i, #parts))
			return nil
		end

		current = nextObj
	end

	print("✅ Resolved path: " .. pathString .. " → " .. current:GetFullName())
	return current
end

function TutorialLevelConfig:GetRenderablePart(object)
	if not object then return nil end

	if object:IsA("BasePart") then
		return object
	end

	if object:IsA("Model") then
		local part = object.PrimaryPart or object:FindFirstChildWhichIsA("BasePart", true)
		if part then
			return part
		end
	end

	if object.Parent and object.Parent:IsA("BasePart") then
		return object.Parent
	end

	warn("❌ Could not find renderable part for: " .. object:GetFullName())
	return nil
end

-- ============================================
-- INDICATOR TYPE DEFINITIONS
-- ============================================
TutorialLevelConfig.IndicatorTypes = {
	Arrow = {
		Name = "Arrow",
		Description = "Directional beam arrow from player to target",
		RequiresTarget = true,
		ClientHandler = "ArrowHandler"
	},

	DiscoveryMarker = {
		Name = "DiscoveryMarker",
		Description = "Jumping arrow above target location",
		RequiresTarget = true,
		ClientHandler = "DiscoveryMarkerHandler"
	},

	UIBadge = {
		Name = "UIBadge",
		Description = "NEW badge on UI element",
		RequiresTarget = false,
		ClientHandler = "UIBadgeHandler"
	},

	MessageOnly = {
		Name = "MessageOnly",
		Description = "Tutorial popup with no world/UI indicator",
		RequiresTarget = false,
		ClientHandler = nil
	},

	Highlight = {
		Name = "Highlight",
		Description = "Glowing highlight effect on target object",
		RequiresTarget = true,
		ClientHandler = "HighlightHandler"
	},

	BreadcrumbTrail = {
		Name = "BreadcrumbTrail",
		Description = "Particle trail leading player to destination",
		RequiresTarget = true,
		ClientHandler = "BreadcrumbHandler"
	}
}

-- ============================================
-- TUTORIAL LEVEL DEFINITIONS
-- ============================================
TutorialLevelConfig.Levels = {
	[1] = {
		Name = "GoToSeedShop",
		DisplayName = "Go to the Seed Shop",
		TargetPath = "workspace.StartingZone.SeedShop",
		Distance = 15,
		TriggerType = "Location",
		IndicatorType = "Arrow",
		MessageToShow = "Welcome",
		Category = "CoreProgression"
	},

	[2] = {
		Name = "BuySeeds",
		DisplayName = "Buy seeds from the shop",
		TargetPath = "workspace.StartingZone.SeedShop",
		Distance = 15,
		TriggerType = "Manual",
		IndicatorType = "Arrow",
		MessageToShow = nil,
		Category = "CoreProgression"
	},

	[3] = {
		Name = "GoToPlot",
		DisplayName = "Go to your farming plot",
		TargetPath = "workspace.StartingZone.Plot1",
		Distance = 10,
		TriggerType = "Manual",
		IndicatorType = "Arrow",
		MessageToShow = "PlantingTutorial",
		Category = "CoreProgression"
	},

	[4] = {
		Name = "HarvestFirstCrop",
		DisplayName = "Harvest your first crop",
		TargetPath = "workspace.StartingZone.Plot1",
		Distance = 10,
		TriggerType = "Manual",
		IndicatorType = "Arrow",
		MessageToShow = nil,
		Category = "CoreProgression"
	},

	[5] = {
		Name = "GoToBarn",
		DisplayName = "Take your harvest to the Barn",
		TargetPath = "workspace.StartingZone.Barn",
		Distance = 12,
		TriggerType = "Manual",
		IndicatorType = "Arrow",
		MessageToShow = "FirstHarvest",
		Category = "CoreProgression"
	},

	[6] = {
		Name = "SellAtBarn",
		DisplayName = "Sell crops at the Barn",
		TargetPath = "workspace.StartingZone.Barn",
		Distance = 12,
		TriggerType = "Manual",
		IndicatorType = "Arrow",
		MessageToShow = "BarnVisit",
		Category = "CoreProgression"
	},
	[7] = {
		Name = "GoToHouses",
		DisplayName = "Upgrade your house",
		TargetPath = "workspace.Houses.PostalBox.Model",
		Distance = 10,
		TriggerType = "Manual",
		IndicatorType = "DiscoveryMarker",
		MessageToShow = "HouseUpgrade",
		Category = "CoreProgression"
	},
	[8] = {
		Name = "GoToZone1",
		DisplayName = "Check out Expansion Zone 1",
		TargetPath = "workspace.ExpansionZone1.Plot5",
		Distance = 15,
		TriggerType = "UnlockTrigger",
		IndicatorType = "Arrow",
		MessageToShow = "Zone1Unlock",
		Category = "Expansion"
	},

	[9] = {
		Name = "GoToZone2",
		DisplayName = "Check out Expansion Zone 2",
		TargetPath = "workspace.ExpansionZone2.Plot9",
		Distance = 15,
		TriggerType = "UnlockTrigger",
		IndicatorType = "Arrow",
		MessageToShow = "Zone2Unlock",
		Category = "Expansion"
	},

	[10] = {
		Name = "GoToZone3",
		DisplayName = "Check out Expansion Zone 3",
		TargetPath = "workspace.ExpansionZone3.Plot13",
		Distance = 15,
		TriggerType = "UnlockTrigger",
		IndicatorType = "Arrow",
		MessageToShow = "Zone3Unlock",
		Category = "Expansion"
	},

	[11] = {
		Name = "GoToPoultryShop",
		DisplayName = "Visit the Poultry Farm",
		TargetPath = "workspace.AnimalZone.PoultryShop",
		Distance = 15,
		TriggerType = "UnlockTrigger",
		IndicatorType = "Arrow",
		MessageToShow = "PoultryUnlock",
		Category = "Animals"
	},

	[11] = {
		Name = "GoToPoultryShop",
		DisplayName = "Visit the Poultry Farm",
		TargetPath = "workspace.AnimalZone.PoultryShop",
		Distance = 15,
		TriggerType = "UnlockTrigger",
		IndicatorType = "Arrow",
		MessageToShow = "PoultryUnlock",
		Category = "Animals"
	},

	[12] = {  
		Name = "GoToFirstHive",
		DisplayName = "Collect honey from your hive",
		TargetPath = "workspace.AnimalZone.Hives.Hive1.Union",
		Distance = 10,
		TriggerType = "Manual",
		IndicatorType = "Highlight",
		MessageToShow = "FirstHiveCollection",
		Category = "Animals"
	},
	[13] = {
		Name = "GoToFishingPond",
		DisplayName = "Try fishing at the pond",
		TargetPath = "workspace.AnimalZone.FishPond.Water", -- Adjust path to your pond location
		Distance = 12,
		TriggerType = "Manual",
		IndicatorType = "Arrow",
		MessageToShow = "FishingRodUnlock",
		Category = "Fishing"
	}



}

-- ============================================
-- VISUAL SETTINGS
-- ============================================
TutorialLevelConfig.ArrowSettings = {
	Color = Color3.fromRGB(255, 255, 0),
	Width0 = 1,
	Width1 = 1,
	Transparency = 0.3,
	LightEmission = 1,
	Texture = "rbxasset://textures/particles/sparkles_main.dds",
	TextureSpeed = 2,
	TextureLength = 3
}

TutorialLevelConfig.DiscoveryMarkerSettings = {
	ArrowColor = Color3.fromRGB(255, 200, 0),
	ArrowSize = Vector3.new(2, 3, 0.3),
	ArrowMaterial = Enum.Material.Neon,
	ArrowTransparency = 0.2,
	LightColor = Color3.fromRGB(255, 200, 0),
	LightBrightness = 3,  -- Changed from 8 to 3 (much dimmer)
	LightRange = 12,      -- Changed from 30 to 12 (smaller radius)
	HoverHeight = 6,
	JumpHeight = 2,
	JumpSpeed = 1,
	RotationSpeed = 45
}


TutorialLevelConfig.HighlightSettings = {
	FillColor = Color3.fromRGB(255, 255, 100),
	OutlineColor = Color3.fromRGB(255, 200, 0),
	FillTransparency = 0.5,
	OutlineTransparency = 0,
	DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
}

TutorialLevelConfig.UIBadgeSettings = {
	Text = "🆕 NEW",
	BackgroundColor = Color3.fromRGB(255, 0, 0),
	TextColor = Color3.new(1, 1, 1),
	Size = UDim2.new(0, 70, 0, 30),
	Font = Enum.Font.GothamBold,
	TextSize = 16,
	CornerRadius = UDim.new(0, 8),
	PulseEffect = true
}

TutorialLevelConfig.BreadcrumbSettings = {
	ParticleColor = ColorSequence.new(Color3.fromRGB(255, 255, 100)),
	ParticleSize = NumberSequence.new(0.5),
	EmissionRate = 20,
	Lifetime = NumberRange.new(2, 3),
	Speed = NumberRange.new(2, 3),
	SpreadAngle = Vector2.new(10, 10)
}

-- ============================================
-- HELPER FUNCTIONS
-- ============================================
function TutorialLevelConfig:GetLevel(levelNumber)
	return self.Levels[levelNumber]
end

function TutorialLevelConfig:GetNextLevel(currentLevel)
	local nextLevel = currentLevel + 1
	while self.Levels[nextLevel] do
		if not self.Levels[nextLevel].Optional then
			return self.Levels[nextLevel]
		end
		nextLevel = nextLevel + 1
	end
	return nil
end

function TutorialLevelConfig:GetStep(stepName)
	for level, config in pairs(self.Levels) do
		if config.Name == stepName then
			return config, level
		end
	end
	return nil, nil
end

function TutorialLevelConfig:GetDiscoveryLevels()
	local discoveries = {}
	for level, config in pairs(self.Levels) do
		if config.Category == "Discovery" and config.Optional then
			table.insert(discoveries, {Level = level, Config = config})
		end
	end
	return discoveries
end

function TutorialLevelConfig:GetIndicatorTypeInfo(typeName)
	return self.IndicatorTypes[typeName]
end

function TutorialLevelConfig:GetTargetPart(targetPathOrLegacy, targetType)
	local object = self:ResolvePathToTarget(targetPathOrLegacy)
	return self:GetRenderablePart(object)
end

print("📚 TutorialLevelConfig loaded successfully")
return TutorialLevelConfig



--[[
===============================================================
TUTORIAL REFERENCE – TYPES & WHEN TO USE THEM
===============================================================

INDICATOR TYPES (IndicatorType)
--------------------------------
"Arrow"
- What it does:
  - Draws a beam from the player to the target object.
- Best for:
  - Core progression steps where you want to clearly point the player somewhere.
- Example use:
  - "Go to the Seed Shop"
  - "Go to the Barn"
- Notes:
  - Very strong directional guidance, always visible while active.

"DiscoveryMarker"
- What it does:
  - Spawns a jumping, glowing arrow ABOVE the target, pointing down.
- Best for:
  - Discovering features/areas that are important but not strictly required.
  - Points of interest (shops, systems, POIs).
- Example use:
  - "Discover Marketplace"
  - "Discover Fishing Spot"
- Notes:
  - Good for optional/side content and “hey, look here!” moments.

"Highlight"
- What it does:
  - Adds a glowing outline around a specific object or model.
- Best for:
  - Interact-with-this-object steps.
- Example use:
  - "Harvest this crop"
  - "Collect honey from this hive"
  - "Press this button / use this machine"
- Notes:
  - Very clear when you want the player to click or interact.

"UIBadge"
- What it does:
  - Shows a “NEW” style badge on top of a UI button.
- Best for:
  - Unlocking new UI features or menus.
- Example use:
  - "Marketplace UI unlocked"
  - "Daily Rewards button available"
- Notes:
  - TargetPath must be a GUI object (e.g. PlayerGui.MainUI.MarketplaceButton).

"MessageOnly"
- What it does:
  - Shows only a popup/tutorial message with NO world/UI indicator.
- Best for:
  - Informational tips that don’t need pointing.
- Example use:
  - “You unlocked X feature, here’s how it works”
  - Congratulation messages after major milestones.
- Notes:
  - Purely informational; player is not visually guided anywhere.

"BreadcrumbTrail"
- What it does:
  - Emits particles from the player in the direction of the target.
- Best for:
  - More “magical” or subtle guidance instead of a hard arrow.
- Example use:
  - Guiding to a mystical area, portal, or special NPC.
- Notes:
  - The player sees a directional “flow” rather than a line/arrow.

---------------------------------------------------------------
TRIGGER TYPES (TriggerType)
---------------------------------------------------------------
"Location"
- Completes automatically when the player gets within Distance of TargetPath.
- Use for:
  - “Go to X” / exploration objectives.
- Example:
  - Go stand near Seed Shop, Barn, new zones, etc.

"Manual"
- Must be completed explicitly by code.
- Use for:
  - Actions that require a specific interaction or server-side confirmation.
- Example:
  - Buying seeds, selling crops, catching first fish.
- Implementation:
  - Some server script calls: _G.CompleteTutorialLevel(player, levelNumber)

"UnlockTrigger"
- Level is activated/advanced by another system when a condition is met.
- Use for:
  - Zone unlocks, feature unlocks, achievements.
- Example:
  - “Zone 2 unlocked when reaching X money”
- Implementation:
  - External code calls: _G.ActivateTutorialLevel(player, levelNumber)

---------------------------------------------------------------
FIELD SUMMARY PER LEVEL ENTRY
---------------------------------------------------------------
Each entry in TutorialLevelConfig.Levels uses:

Name          : Internal ID (string, used in code)
DisplayName   : Player-facing short text (optional, mostly for logs)
TargetPath    : "workspace...." or "PlayerGui...." or implicit workspace
Distance      : For "Location" triggers (nil for pure UI or manual-only)
TriggerType   : "Location" | "Manual" | "UnlockTrigger"
IndicatorType : "Arrow" | "DiscoveryMarker" | "Highlight" | "UIBadge" | "MessageOnly" | "BreadcrumbTrail"
MessageToShow : Key used by TutorialManager / TutorialClient for popup text
Category      : "CoreProgression" | "Expansion" | "Animals" | "Discovery" | "UI" | etc.
Optional      : boolean; true = does not block main progression

---------------------------------------------------------------
USAGE GUIDELINES
---------------------------------------------------------------
- Use "Arrow" for mandatory core steps that move the player around the map.
- Use "Highlight" when the step is “interact with this exact object”.
- Use "DiscoveryMarker" for optional POIs and systems you want to showcase.
- Use "UIBadge" when a new UI button becomes relevant/unlocked.
- Use "MessageOnly" for tips and info that don’t need a visual locator.
- Use "BreadcrumbTrail" when you want softer / thematic guidance.
===============================================================
]]--
