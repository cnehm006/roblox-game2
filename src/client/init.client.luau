--[[
	Main Client Entry Point
	Initializes UI and client-side game systems
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")

-- Wait for shared modules
local Shared = ReplicatedStorage:WaitForChild("Shared")
local Remotes = require(Shared:WaitForChild("Remotes"))
local GameConfig = require(Shared:WaitForChild("GameConfig"))

-- Client modules (script.Parent is the Client folder)
local Client = script.Parent
local UIManager = require(Client:WaitForChild("UIManager"))
local CoinEffects = require(Client:WaitForChild("CoinEffects"))
local BoardHandler = require(Client:WaitForChild("BoardHandler"))

print("═══════════════════════════════════════════════════════════════")
print("  COIN INCREMENTAL GAME - Starting Client")
print("═══════════════════════════════════════════════════════════════")

-- Wait for character
local function onCharacterAdded(character)
	print("[Client] Character loaded")
end

if LocalPlayer.Character then
	onCharacterAdded(LocalPlayer.Character)
end
LocalPlayer.CharacterAdded:Connect(onCharacterAdded)

-- Initialize UI
UIManager.init()

-- Initialize effects
CoinEffects.init()

-- Initialize board handler
BoardHandler.init()

-- Request initial data from server
task.spawn(function()
	local data = Remotes.invokeServer("GetPlayerData")
	if data then
		UIManager.updateAllData(data)
		print("[Client] Initial data loaded")
		
		-- Refresh boards with initial data
		task.wait(0.5)
		BoardHandler.refreshBoards()
	else
		warn("[Client] Failed to load initial data")
	end
end)

-- Listen for server updates
Remotes.getEvent("StatsUpdated").OnClientEvent:Connect(function(stats)
	UIManager.updateStats(stats)
end)

Remotes.getEvent("UpgradesUpdated").OnClientEvent:Connect(function(upgrades)
	UIManager.updateUpgrades(upgrades)
	BoardHandler.refreshBoards()
end)

Remotes.getEvent("CoinCollected").OnClientEvent:Connect(function(rarityName, value, xp)
	CoinEffects.showCollectionEffect(rarityName, value, xp)
end)

Remotes.getEvent("LevelUp").OnClientEvent:Connect(function(newLevel, levelsGained)
	CoinEffects.showLevelUpEffect(newLevel, levelsGained)
	UIManager.showNotification("Level Up! Now level " .. newLevel, Color3.fromRGB(255, 215, 0))
end)

Remotes.getEvent("RebirthCompleted").OnClientEvent:Connect(function(rebirthData)
	CoinEffects.showRebirthEffect()
	UIManager.updateRebirthData(rebirthData)
	UIManager.showNotification("Rebirth #" .. rebirthData.rebirths .. "! +" .. math.floor(rebirthData.coinBoost * 100) .. "% coin boost", Color3.fromRGB(147, 112, 219))
	BoardHandler.refreshBoards()
end)

Remotes.getEvent("RebirthBoardUnlocked").OnClientEvent:Connect(function()
	UIManager.unlockRebirthBoard()
	UIManager.showNotification("Rebirth Board Unlocked!", Color3.fromRGB(255, 100, 100))
	BoardHandler.refreshBoards()
end)

Remotes.getEvent("CoinSpawned").OnClientEvent:Connect(function(coin, rarityName, color)
	CoinEffects.setupCoinEffects(coin, rarityName, color)
end)

print("═══════════════════════════════════════════════════════════════")
print("  COIN INCREMENTAL GAME - Client Ready!")
print("═══════════════════════════════════════════════════════════════")
