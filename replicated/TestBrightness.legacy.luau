-- Test script - delete after testing
task.wait(5)

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local player = game:GetService("Players"):GetPlayers()[1]

if player then
	print("\n" .. string.rep("=", 50))
	print("🧪 STARTING DAY/NIGHT MANAGER TEST")
	print(string.rep("=", 50) .. "\n")

	-- ============================================
	-- TEST 1: CLEAR SPRING NIGHT
	-- ============================================
	print("TEST 1 → Spring | Night | Clear")
	_G.forceSeason("Spring")
	task.wait(2)
	_G.setGameTime(1360)
	_G.forceWeather("Clear", "Spring")
	task.wait(10)

	-- ============================================
	-- TEST 2: CLEAR WINTER DAY
	-- ============================================
	print("TEST 2 → Winter | Day | Clear")
	_G.forceSeason("Winter")
	task.wait(2)
	_G.setGameTime(1360)
	_G.forceWeather("Clear", "Winter")
	task.wait(10)

	-- ============================================
	-- TEST 3: SNOWY WINTER NIGHT
	-- ============================================
	print("TEST 3 → Winter | Day | Snow")
	_G.setGameTime(660)
	_G.forceWeather("Clear", "Winter")
	task.wait(10)

	-- ============================================
	-- TEST 4: RAINY SPRING DAY
	-- ============================================
	print("TEST 4 → Spring | Day | Rain")
	_G.forceSeason("Spring")
	task.wait(2)
	_G.setGameTime(660)
	_G.forceWeather("Clear", "Spring")
	task.wait(10)

	-- ============================================
	-- TEST 5: CLEAR SPRING EVENING
	-- ============================================
	print("TEST 5 → Spring | Evening | Clear")
	_G.setGameTime(1140)
	_G.forceWeather("Clear", "Spring")
	task.wait(10)

	-- ============================================
	-- TEST 6: RAINY WINTER EVENING
	-- ============================================
	print("TEST 6 → Winter | Evening | Rain")
	_G.forceSeason("Winter")
	task.wait(2)
	_G.setGameTime(1140)
	_G.forceWeather("Clear", "Winter")
	task.wait(10)

	-- ============================================
	-- TEST 7: CLEAR SUMMER DAY
	-- ============================================
	print("TEST 7 → Summer | Day | Clear")
	_G.forceSeason("Summer")
	task.wait(2)
	_G.setGameTime(660)
	_G.forceWeather("Clear", "Summer")
	task.wait(10)

	-- ============================================
	-- TEST 8: CLEAR FALL NIGHT
	-- ============================================
	print("TEST 8 → Fall | Night | Clear")
	_G.forceSeason("Fall")
	task.wait(2)
	_G.setGameTime(1360)
	_G.forceWeather("Clear", "Fall")
	task.wait(10)

	-- ============================================
	-- RETURN TO NORMAL
	-- ============================================
	print("COMPLETE → Spring | Day | Clear")
	_G.forceSeason("Spring")
	task.wait(2)
	_G.setGameTime(660)
	_G.forceWeather("Clear", "Spring")
	task.wait(10)

	print("\n" .. string.rep("=", 50))
	print("✅ ALL TESTS COMPLETE")
	print(string.rep("=", 50) .. "\n")

else
	warn("❌ No players connected yet!")
end