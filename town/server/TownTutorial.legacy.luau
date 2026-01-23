-- TownTutorial.lua (Town Place)
-- Welcome new players and guide them to their farm

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

Players.PlayerAdded:Connect(function(player)
	-- Wait for player to load
	player.CharacterAdded:Wait()
	task.wait(2)

	-- Check if new player (first join)
	local isNewPlayer = not player:GetAttribute("HasVisitedTown")

	if isNewPlayer then
		player:SetAttribute("HasVisitedTown", true)

		-- Show welcome message
		local ShowTutorialEvent = ReplicatedStorage:FindFirstChild("ShowTutorialEvent")
		if ShowTutorialEvent then
			ShowTutorialEvent:FireClient(player, "Welcome", {
				Title = "Welcome to Farm Town! 🌾",
				Message = "Visit the Farm Portal to start your farming journey! Browse shops, trade with others, and complete quests here in Town.",
				Duration = 8
			})
		end

		-- Highlight Farm Portal
		task.delay(8, function()
			local farmPortal = workspace:FindFirstChild("FarmPortal")
			if farmPortal then
				local highlight = Instance.new("Highlight")
				highlight.FillColor = Color3.fromRGB(100, 255, 100)
				highlight.OutlineColor = Color3.fromRGB(50, 200, 50)
				highlight.Parent = farmPortal

				task.delay(15, function()
					highlight:Destroy()
				end)
			end
		end)
	end

	print("✅ " .. player.Name .. " joined Town")
end)
