local TutorialArrowConfig = {}

-- Define all tutorial steps in order
-- TriggerType: "Location" (auto-detect when player reaches), "Manual" (requires FireTutorialEvent)
TutorialArrowConfig.Steps = {
	{
		Name = "GoToSeedShop",
		DisplayName = "Go to the Seed Shop",
		Target = "StartingZone.SeedShop",
		TargetType = "Model",
		Distance = 15,
		TriggerType = "Location",
		TutorialMessage = "Welcome",
		Order = 1,
		ResumeCondition = nil -- Always available
	},
	{
		Name = "BuySeeds",
		DisplayName = "Buy seeds from the shop",
		Target = "StartingZone.SeedShop",
		TargetType = "Model",
		Distance = 15,
		TriggerType = "Manual",
		TutorialMessage = nil,
		Order = 2,
		ResumeCondition = nil
	},
	{
		Name = "GoToPlot",
		DisplayName = "Go to your farming plot",
		Target = "StartingZone.Plot1",
		TargetType = "Any",
		Distance = 10,
		TriggerType = "Manual",
		TutorialMessage = "PlantingTutorial",
		Order = 3,
		ResumeCondition = nil
	},
	{
		Name = "HarvestFirstCrop",
		DisplayName = "Harvest your first crop",
		Target = "StartingZone.Plot1",
		TargetType = "Any",
		Distance = 10,
		TriggerType = "Manual",
		TutorialMessage = nil,
		Order = 4,
		ResumeCondition = nil
	},
	{
		Name = "GoToBarn",
		DisplayName = "Take your harvest to the Barn",
		Target = "StartingZone.Barn",
		TargetType = "Model",
		Distance = 12,
		TriggerType = "Manual",
		TutorialMessage = "FirstHarvest",
		Order = 5,
		ResumeCondition = nil
	},
	{
		Name = "SellAtBarn",
		DisplayName = "Sell crops at the Barn",
		Target = "StartingZone.Barn",
		TargetType = "Model",
		Distance = 12,
		TriggerType = "Manual",
		TutorialMessage = "BarnVisit",
		Order = 6,
		ResumeCondition = nil
	},
	{
		Name = "GoToZone1",
		DisplayName = "Check out Expansion Zone 1",
		Target = "ExpansionZone1.Plot5",
		TargetType = "Any",
		Distance = 15,
		TriggerType = "Manual",
		TutorialMessage = nil,
		Order = 7,
		ResumeCondition = "Zone1Unlocked" -- Triggered when Zone1 unlocks
	},
	{
		Name = "GoToZone2",
		DisplayName = "Check out Expansion Zone 2",
		Target = "ExpansionZone2.Plot9",
		TargetType = "Any",
		Distance = 15,
		TriggerType = "Manual",
		TutorialMessage = nil,
		Order = 8,
		ResumeCondition = "Zone2Unlocked" -- ✅ Only activate when Zone2 unlocks
	},
	{
		Name = "GoToZone3",
		DisplayName = "Check out Expansion Zone 3",
		Target = "ExpansionZone3.Plot13",
		TargetType = "Any",
		Distance = 15,
		TriggerType = "Manual",
		TutorialMessage = nil,
		Order = 9,
		ResumeCondition = "Zone3Unlocked" -- ✅ Only activate when Zone3 unlocks
	},
	{
		Name = "GoToPoultryShop",
		DisplayName = "Visit the Poultry Farm",
		Target = "AnimalZone.PoultryShop",
		TargetType = "Model",
		Distance = 15,
		TriggerType = "Manual",
		TutorialMessage = nil,
		Order = 10,
		ResumeCondition = "PoultryUnlocked"
	},
	{
		Name = "BuyFirstBeehive",
		DisplayName = "Buy your first beehive",
		Target = "AnimalZone.PoultryShop",
		TargetType = "Model",
		Distance = 15,
		TriggerType = "Manual",
		TutorialMessage = nil,
		Order = 11,
		ResumeCondition = nil
	},
	{
		Name = "GoToFirstHive",
		DisplayName = "Collect honey from your hive",
		Target = "AnimalZone.Hives.Hive1.Union",  -- Replace "Union" with actual part name
		TargetType = "Part",
		Distance = 10,
		TriggerType = "Manual",
		TutorialMessage = "FirstHiveCollection",
		Order = 12,
		ResumeCondition = nil
	}
}


-- Arrow appearance settings
TutorialArrowConfig.ArrowSettings = {
	Color = Color3.fromRGB(255, 255, 0),
	Width0 = 1,
	Width1 = 1,
	Transparency = 0.3,
	LightEmission = 1,
	Texture = "rbxasset://textures/particles/sparkles_main.dds",
	TextureSpeed = 2,
	TextureLength = 3
}

-- Helper function to find object by path
function TutorialArrowConfig:FindObjectByPath(path)
	local parts = string.split(path, ".")
	local current = workspace
	for _, partName in ipairs(parts) do
		current = current:FindFirstChild(partName)
		if not current then return nil end
	end
	return current
end

-- Helper function to get target part
function TutorialArrowConfig:GetTargetPart(targetPath, targetType)
	if not targetPath then return nil end  -- ✅ Handle Paused state

	local targetObject = self:FindObjectByPath(targetPath)
	if not targetObject then
		warn("Could not find object at path: " .. targetPath)
		return nil
	end

	if targetType == "Model" or targetObject:IsA("Model") then
		local part = targetObject.PrimaryPart or targetObject:FindFirstChildWhichIsA("BasePart", true)
		if not part then
			warn("Model " .. targetPath .. " has no PrimaryPart or parts")
			return nil
		end
		return part
	elseif targetType == "Part" or targetObject:IsA("BasePart") then
		return targetObject
	else
		if targetObject:IsA("Model") then
			local part = targetObject.PrimaryPart or targetObject:FindFirstChildWhichIsA("BasePart", true)
			return part
		elseif targetObject:IsA("BasePart") then
			return targetObject
		else
			warn("Target " .. targetPath .. " is not a Part or Model")
			return nil
		end
	end
end

function TutorialArrowConfig:GetStep(stepName)
	for _, step in ipairs(self.Steps) do
		if step.Name == stepName then
			return step
		end
	end
	return nil
end

function TutorialArrowConfig:GetNextStep(currentStepName)
	for i, step in ipairs(self.Steps) do
		if step.Name == currentStepName then
			local nextStep = self.Steps[i + 1]

			-- If there's no next step, return Paused state
			if not nextStep then
				return {Name = "Paused", DisplayName = "Tutorial Complete"}
			end

			-- If next step requires a condition that's not met, pause
			if nextStep.ResumeCondition then
				return {Name = "Paused", DisplayName = "Tutorial Paused"}
			end

			return nextStep
		end
	end
	return nil
end

return TutorialArrowConfig