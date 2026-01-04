--[[
	Main Server Entry Point
	Initializes all game systems for the coin incremental game
]]

local ServerScriptService = game:GetService("ServerScriptService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Wait for shared modules to be available
local Shared = ReplicatedStorage:WaitForChild("Shared")
local Remotes = require(Shared:WaitForChild("Remotes"))

-- Server modules
local Server = ServerScriptService:WaitForChild("Server")
local DataManager = require(Server:WaitForChild("DataManager"))
local CoinSpawner = require(Server:WaitForChild("CoinSpawner"))
local CoinCollector = require(Server:WaitForChild("CoinCollector"))
local LevelSystem = require(Server:WaitForChild("LevelSystem"))
local UpgradeSystem = require(Server:WaitForChild("UpgradeSystem"))
local RebirthSystem = require(Server:WaitForChild("RebirthSystem"))
local RebirthBoardSystem = require(Server:WaitForChild("RebirthBoardSystem"))
local BoardInteraction = require(Server:WaitForChild("BoardInteraction"))

print("═══════════════════════════════════════════════════════════════")
print("  COIN INCREMENTAL GAME - Starting Server")
print("═══════════════════════════════════════════════════════════════")

-- Initialize remotes first
Remotes.init()
print("[Server] Remotes initialized")

-- Initialize data manager
DataManager.init()

-- Initialize level system
LevelSystem.init(DataManager)

-- Initialize coin systems
CoinSpawner.init(DataManager)
CoinCollector.init(DataManager, CoinSpawner, LevelSystem)

-- Initialize upgrade systems
UpgradeSystem.init(DataManager)

-- Initialize rebirth systems
RebirthSystem.init(DataManager, CoinCollector, UpgradeSystem)
RebirthBoardSystem.init(DataManager, UpgradeSystem, RebirthSystem)

-- Initialize board interaction
BoardInteraction.init(DataManager)

-- Set up GetPlayerData remote
local getDataRemote = Remotes.getFunction("GetPlayerData")
getDataRemote.OnServerInvoke = function(player)
	local GameConfig = require(Shared:WaitForChild("GameConfig"))
	
	local data = DataManager.getData(player)
	if not data then
		return nil
	end
	
	-- Return comprehensive data for client
	return {
		-- Stats
		coins = data.coins,
		totalCoinsEarned = data.totalCoinsEarned,
		xp = data.xp,
		level = data.level,
		rebirths = data.rebirths,
		
		-- Upgrades
		upgrades = data.upgrades,
		rebirthUpgrades = data.rebirthUpgrades,
		
		-- Level info
		levelInfo = LevelSystem.getLevelInfo(player),
		
		-- Rebirth info
		rebirthInfo = RebirthSystem.getRebirthInfo(player),
		rebirthBoardUnlocked = RebirthBoardSystem.isUnlocked(player),
		
		-- Upgrade info
		baseUpgradeInfo = UpgradeSystem.getUpgradeInfo(player),
		rebirthUpgradeInfo = RebirthBoardSystem.getUpgradeInfo(player),
		
		-- Config for client reference
		rebirthRequirement = GameConfig.Rebirth.requirement,
	}
end

print("═══════════════════════════════════════════════════════════════")
print("  COIN INCREMENTAL GAME - Server Ready!")
print("═══════════════════════════════════════════════════════════════")
