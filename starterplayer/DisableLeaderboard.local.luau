local StarterGui = game:GetService("StarterGui")

-- Wait for game to load
game:GetService("RunService").Heartbeat:Wait()

-- Disable leaderboard
StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.PlayerList, false)
print("🚫 Leaderboard disabled (client)")
