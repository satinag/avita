-- StarterPlayer/StarterPlayerScripts/TutorialIndicatorHandlers
-- Client-side handlers for all indicator types

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")

local player = Players.LocalPlayer
local TutorialLevelConfig = require(ReplicatedStorage:WaitForChild("TutorialLevelConfig"))

local IndicatorHandlers = {}
local activeIndicators = {}

-- ============================================
-- ARROW HANDLER
-- ============================================
IndicatorHandlers.ArrowHandler = {}

function IndicatorHandlers.ArrowHandler:Create(levelConfig)
	local character = player.Character
	if not character then return nil end

	local humanoidRootPart = character:FindFirstChild("HumanoidRootPart")
	if not humanoidRootPart then return nil end

	local targetObject = TutorialLevelConfig:ResolvePathToTarget(levelConfig.TargetPath)
	local targetPart = TutorialLevelConfig:GetRenderablePart(targetObject)
	if not targetPart then return nil end

	local targetAttachment = targetPart:FindFirstChildOfClass("Attachment")
	if not targetAttachment then
		targetAttachment = Instance.new("Attachment")
		targetAttachment.Name = "ArrowTargetAttachment"
		targetAttachment.Parent = targetPart
	end

	local playerAttachment = Instance.new("Attachment")
	playerAttachment.Name = "ArrowPlayerAttachment"
	playerAttachment.Parent = humanoidRootPart

	local beam = Instance.new("Beam")
	beam.Name = "TutorialArrowBeam"
	beam.Parent = workspace.CurrentCamera
	beam.Attachment0 = playerAttachment
	beam.Attachment1 = targetAttachment

	local settings = TutorialLevelConfig.ArrowSettings
	beam.Color = ColorSequence.new(settings.Color)
	beam.Width0 = settings.Width0
	beam.Width1 = settings.Width1
	beam.FaceCamera = true
	beam.Transparency = NumberSequence.new(settings.Transparency)
	beam.LightEmission = settings.LightEmission
	beam.Texture = settings.Texture
	beam.TextureSpeed = settings.TextureSpeed
	beam.TextureLength = settings.TextureLength

	local ancestryConnection = targetPart.AncestryChanged:Connect(function()
		if not targetPart:IsDescendantOf(workspace) then
			self:Destroy()
		end
	end)

	print("🎯 Created Arrow indicator")
	return {
		Beam = beam,
		PlayerAttachment = playerAttachment,
		AncestryConnection = ancestryConnection
	}
end

function IndicatorHandlers.ArrowHandler:Destroy()
	if activeIndicators.Arrow then
		if activeIndicators.Arrow.Beam then
			activeIndicators.Arrow.Beam:Destroy()
		end
		if activeIndicators.Arrow.PlayerAttachment then
			activeIndicators.Arrow.PlayerAttachment:Destroy()
		end
		if activeIndicators.Arrow.AncestryConnection then
			activeIndicators.Arrow.AncestryConnection:Disconnect()
		end
		activeIndicators.Arrow = nil
		print("🗑️ Destroyed Arrow indicator")
	end
end

-- ============================================
-- DISCOVERY MARKER HANDLER (Jumping Arrow)
-- ============================================
IndicatorHandlers.DiscoveryMarkerHandler = {}

function IndicatorHandlers.DiscoveryMarkerHandler:Create(levelConfig)
	local targetObject = TutorialLevelConfig:ResolvePathToTarget(levelConfig.TargetPath)
	local targetPart = TutorialLevelConfig:GetRenderablePart(targetObject)
	if not targetPart then return nil end

	local settings = TutorialLevelConfig.DiscoveryMarkerSettings

	local targetSize = targetPart.Size
	local baseHeight = targetSize.Y / 2 + settings.HoverHeight
	local basePosition = targetPart.Position + Vector3.new(0, baseHeight, 0)

	local arrow = Instance.new("Model")
	arrow.Name = "DiscoveryArrow_" .. levelConfig.Name
	arrow.Parent = workspace

	local shaft = Instance.new("Part")
	shaft.Name = "Shaft"
	shaft.Size = Vector3.new(0.3, settings.ArrowSize.Y, 0.3)
	shaft.Color = settings.ArrowColor
	shaft.Material = settings.ArrowMaterial
	shaft.Transparency = settings.ArrowTransparency
	shaft.Anchored = true
	shaft.CanCollide = false
	shaft.CastShadow = false
	shaft.CFrame = CFrame.new(basePosition)
	shaft.Parent = arrow

	local leftWing = Instance.new("WedgePart")
	leftWing.Name = "LeftWing"
	leftWing.Size = Vector3.new(0.3, 1.2, 1.2)
	leftWing.Color = settings.ArrowColor
	leftWing.Material = settings.ArrowMaterial
	leftWing.Transparency = settings.ArrowTransparency
	leftWing.Anchored = true
	leftWing.CanCollide = false
	leftWing.CastShadow = false
	leftWing.CFrame = CFrame.new(basePosition - Vector3.new(0, settings.ArrowSize.Y/2 + 0.4, 0))
		* CFrame.Angles(0, 0, math.rad(90))
		* CFrame.Angles(math.rad(45), 0, 0)
	leftWing.Parent = arrow

	local rightWing = Instance.new("WedgePart")
	rightWing.Name = "RightWing"
	rightWing.Size = Vector3.new(0.3, 1.2, 1.2)
	rightWing.Color = settings.ArrowColor
	rightWing.Material = settings.ArrowMaterial
	rightWing.Transparency = settings.ArrowTransparency
	rightWing.Anchored = true
	rightWing.CanCollide = false
	rightWing.CastShadow = false
	rightWing.CFrame = CFrame.new(basePosition - Vector3.new(0, settings.ArrowSize.Y/2 + 0.4, 0))
		* CFrame.Angles(0, 0, math.rad(-90))
		* CFrame.Angles(math.rad(-45), 0, 0)
	rightWing.Parent = arrow

	arrow.PrimaryPart = shaft

	local light = Instance.new("PointLight")
	light.Color = settings.LightColor
	light.Brightness = settings.LightBrightness
	light.Range = settings.LightRange
	light.Parent = shaft

	local lightPulse = TweenService:Create(
		light,
		TweenInfo.new(0.6, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true),
		{Brightness = settings.LightBrightness * 0.6}
	)
	lightPulse:Play()

	local startCFrame = arrow:GetPrimaryPartCFrame()
	local jumpTween = TweenService:Create(
		shaft,
		TweenInfo.new(settings.JumpSpeed, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true),
		{CFrame = startCFrame * CFrame.new(0, settings.JumpHeight, 0)}
	)

	local updateConnection = RunService.RenderStepped:Connect(function()
		if shaft and shaft.Parent and arrow.Parent then
			local currentPos = shaft.Position
			leftWing.CFrame = CFrame.new(currentPos - Vector3.new(0, settings.ArrowSize.Y/2 + 0.4, 0))
				* CFrame.Angles(0, 0, math.rad(90))
				* CFrame.Angles(math.rad(45), 0, 0)
			rightWing.CFrame = CFrame.new(currentPos - Vector3.new(0, settings.ArrowSize.Y/2 + 0.4, 0))
				* CFrame.Angles(0, 0, math.rad(-90))
				* CFrame.Angles(math.rad(-45), 0, 0)
		end
	end)

	jumpTween:Play()

	local rotationSpeed = settings.RotationSpeed
	local rotateConnection = RunService.Heartbeat:Connect(function(dt)
		if arrow and arrow.Parent and shaft.Parent then
			arrow:SetPrimaryPartCFrame(shaft.CFrame * CFrame.Angles(0, math.rad(rotationSpeed) * dt, 0))
		end
	end)

	print("🎯 Created DiscoveryMarker indicator")
	return {
		Arrow = arrow,
		Shaft = shaft,
		Light = light,
		JumpTween = jumpTween,
		LightPulse = lightPulse,
		UpdateConnection = updateConnection,
		RotateConnection = rotateConnection
	}
end

function IndicatorHandlers.DiscoveryMarkerHandler:Destroy()
	if activeIndicators.DiscoveryMarker then
		local data = activeIndicators.DiscoveryMarker
		if data.Arrow then data.Arrow:Destroy() end
		if data.JumpTween then data.JumpTween:Cancel() end
		if data.LightPulse then data.LightPulse:Cancel() end
		if data.UpdateConnection then data.UpdateConnection:Disconnect() end
		if data.RotateConnection then data.RotateConnection:Disconnect() end
		activeIndicators.DiscoveryMarker = nil
		print("🗑️ Destroyed DiscoveryMarker indicator")
	end
end

-- ============================================
-- HIGHLIGHT HANDLER
-- ============================================
IndicatorHandlers.HighlightHandler = {}

function IndicatorHandlers.HighlightHandler:Create(levelConfig)
	local targetObject = TutorialLevelConfig:ResolvePathToTarget(levelConfig.TargetPath)
	local targetPart = TutorialLevelConfig:GetRenderablePart(targetObject)
	if not targetPart then return nil end

	local settings = TutorialLevelConfig.HighlightSettings

	local highlight = Instance.new("Highlight")
	highlight.FillColor = settings.FillColor
	highlight.OutlineColor = settings.OutlineColor
	highlight.FillTransparency = settings.FillTransparency
	highlight.OutlineTransparency = settings.OutlineTransparency
	highlight.DepthMode = settings.DepthMode

	if targetPart.Parent:IsA("Model") then
		highlight.Parent = targetPart.Parent
	else
		highlight.Parent = targetPart
	end

	local pulseTween = TweenService:Create(
		highlight,
		TweenInfo.new(1, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true),
		{OutlineTransparency = 0.5}
	)
	pulseTween:Play()

	print("🎯 Created Highlight indicator")
	return {
		Highlight = highlight,
		PulseTween = pulseTween
	}
end

function IndicatorHandlers.HighlightHandler:Destroy()
	if activeIndicators.Highlight then
		local data = activeIndicators.Highlight
		if data.Highlight then data.Highlight:Destroy() end
		if data.PulseTween then data.PulseTween:Cancel() end
		activeIndicators.Highlight = nil
		print("🗑️ Destroyed Highlight indicator")
	end
end

-- ============================================
-- UI BADGE HANDLER
-- ============================================
IndicatorHandlers.UIBadgeHandler = {}

function IndicatorHandlers.UIBadgeHandler:Create(levelConfig)
	local guiPath = levelConfig.TargetPath
	local parts = string.split(guiPath, ".")

	local current = player:WaitForChild(parts[1], 5)
	for i = 2, #parts do
		if current then
			current = current:FindFirstChild(parts[i])
		end
	end

	if not current or not current:IsA("GuiObject") then
		warn("Could not find GUI target: " .. guiPath)
		return nil
	end

	local settings = TutorialLevelConfig.UIBadgeSettings

	local badge = Instance.new("TextLabel")
	badge.Name = "TutorialBadge"
	badge.Text = settings.Text
	badge.BackgroundColor3 = settings.BackgroundColor
	badge.TextColor3 = settings.TextColor
	badge.Size = settings.Size
	badge.Position = UDim2.new(1, -75, 0, 5)
	badge.Font = settings.Font
	badge.TextSize = settings.TextSize
	badge.ZIndex = 1000
	badge.Parent = current

	local corner = Instance.new("UICorner")
	corner.CornerRadius = settings.CornerRadius
	corner.Parent = badge

	local pulseTween = nil
	if settings.PulseEffect then
		pulseTween = TweenService:Create(
			badge,
			TweenInfo.new(0.8, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true),
			{Size = UDim2.new(0, 75, 0, 32)}
		)
		pulseTween:Play()
	end

	local clickConnection = current.MouseButton1Click:Connect(function()
		self:Destroy()
	end)

	print("🎯 Created UIBadge indicator")
	return {
		Badge = badge,
		PulseTween = pulseTween,
		ClickConnection = clickConnection
	}
end

function IndicatorHandlers.UIBadgeHandler:Destroy()
	if activeIndicators.UIBadge then
		local data = activeIndicators.UIBadge
		if data.Badge then data.Badge:Destroy() end
		if data.PulseTween then data.PulseTween:Cancel() end
		if data.ClickConnection then data.ClickConnection:Disconnect() end
		activeIndicators.UIBadge = nil
		print("🗑️ Destroyed UIBadge indicator")
	end
end

-- ============================================
-- BREADCRUMB TRAIL HANDLER
-- ============================================
IndicatorHandlers.BreadcrumbHandler = {}

function IndicatorHandlers.BreadcrumbHandler:Create(levelConfig)
	local character = player.Character
	if not character then return nil end

	local humanoidRootPart = character:FindFirstChild("HumanoidRootPart")
	if not humanoidRootPart then return nil end

	local targetObject = TutorialLevelConfig:ResolvePathToTarget(levelConfig.TargetPath)
	local targetPart = TutorialLevelConfig:GetRenderablePart(targetObject)
	if not targetPart then return nil end

	local settings = TutorialLevelConfig.BreadcrumbSettings

	local attachment = Instance.new("Attachment")
	attachment.Name = "BreadcrumbAttachment"
	attachment.Parent = humanoidRootPart

	local particles = Instance.new("ParticleEmitter")
	particles.Name = "BreadcrumbParticles"
	particles.Color = settings.ParticleColor
	particles.Size = settings.ParticleSize
	particles.Rate = settings.EmissionRate
	particles.Lifetime = settings.Lifetime
	particles.Speed = settings.Speed
	particles.SpreadAngle = settings.SpreadAngle
	particles.LightEmission = 1
	particles.Parent = attachment

	local updateConnection = RunService.Heartbeat:Connect(function()
		if humanoidRootPart and targetPart and humanoidRootPart.Parent and targetPart.Parent then
			local direction = (targetPart.Position - humanoidRootPart.Position).Unit
			particles.EmissionDirection = Enum.NormalId.Front
			attachment.CFrame = CFrame.lookAt(Vector3.new(0, 0, 0), direction)
		end
	end)

	print("🎯 Created BreadcrumbTrail indicator")
	return {
		Attachment = attachment,
		Particles = particles,
		UpdateConnection = updateConnection
	}
end

function IndicatorHandlers.BreadcrumbHandler:Destroy()
	if activeIndicators.BreadcrumbTrail then
		local data = activeIndicators.BreadcrumbTrail
		if data.Attachment then data.Attachment:Destroy() end
		if data.UpdateConnection then data.UpdateConnection:Disconnect() end
		activeIndicators.BreadcrumbTrail = nil
		print("🗑️ Destroyed BreadcrumbTrail indicator")
	end
end

-- ============================================
-- MAIN INDICATOR MANAGER
-- ============================================
function IndicatorHandlers:ShowIndicator(levelConfig)
	local indicatorType = levelConfig.IndicatorType

	self:HideIndicator()

	local handler = self[indicatorType .. "Handler"]
	if not handler then
		warn("No handler found for indicator type: " .. indicatorType)
		return
	end

	local indicatorData = handler:Create(levelConfig)
	if indicatorData then
		activeIndicators[indicatorType] = indicatorData
		print("✨ Created " .. indicatorType .. " for level: " .. levelConfig.DisplayName)
	end
end

function IndicatorHandlers:HideIndicator()
	for indicatorType, _ in pairs(activeIndicators) do
		local handler = self[indicatorType .. "Handler"]
		if handler and handler.Destroy then
			handler:Destroy()
		end
	end
end

print("🎨 TutorialIndicatorHandlers loaded successfully")
return IndicatorHandlers
