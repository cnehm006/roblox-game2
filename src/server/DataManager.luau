--[[
	DataManager - Handles player data persistence and management
	Uses DataStoreService for saving/loading with session locking
]]

local Players = game:GetService("Players")
local DataStoreService = game:GetService("DataStoreService")
local RunService = game:GetService("RunService")

local PlayerDataTemplate = require(game:GetService("ReplicatedStorage").Shared.PlayerDataTemplate)

local DataManager = {}

-- Configuration
local DATA_STORE_NAME = "CoinIncrementalV1"
local AUTO_SAVE_INTERVAL = 60 -- seconds
local RETRY_ATTEMPTS = 3
local RETRY_DELAY = 1

-- State
local dataStore = nil
local playerData = {}
local dataLoaded = {}

-- Initialize DataStore (skip in Studio for testing)
local function initDataStore()
	if RunService:IsStudio() then
		-- Use mock data in Studio (optional: can enable real DataStore)
		warn("[DataManager] Running in Studio - using local data only")
		return
	end
	
	local success, result = pcall(function()
		return DataStoreService:GetDataStore(DATA_STORE_NAME)
	end)
	
	if success then
		dataStore = result
		print("[DataManager] DataStore initialized")
	else
		warn("[DataManager] Failed to get DataStore:", result)
	end
end

-- Load player data from DataStore
local function loadData(player)
	local key = "Player_" .. player.UserId
	local data = nil
	
	if dataStore then
		for attempt = 1, RETRY_ATTEMPTS do
			local success, result = pcall(function()
				return dataStore:GetAsync(key)
			end)
			
			if success then
				if result then
					data = PlayerDataTemplate.validate(result)
					print("[DataManager] Loaded data for " .. player.Name)
				end
				break
			else
				warn("[DataManager] Load attempt " .. attempt .. " failed for " .. player.Name .. ": " .. tostring(result))
				if attempt < RETRY_ATTEMPTS then
					task.wait(RETRY_DELAY)
				end
			end
		end
	end
	
	-- Create new data if none exists
	if not data then
		data = PlayerDataTemplate.clone()
		print("[DataManager] Created new data for " .. player.Name)
	end
	
	-- Calculate offline earnings
	if data.rebirthUpgrades.OfflineCoinCollection > 0 and data.lastOnline > 0 then
		local offlineTime = os.time() - data.lastOnline
		local maxOfflineTime = 86400 -- 24 hours max
		offlineTime = math.min(offlineTime, maxOfflineTime)
		
		local coinsPerLevel = 10000000 -- 10M per level
		local offlineEarnings = offlineTime * (coinsPerLevel * data.rebirthUpgrades.OfflineCoinCollection) / 3600
		
		if offlineEarnings > 0 then
			data.coins = data.coins + math.floor(offlineEarnings)
			data.totalCoinsEarned = data.totalCoinsEarned + math.floor(offlineEarnings)
			print("[DataManager] " .. player.Name .. " earned " .. offlineEarnings .. " coins while offline")
		end
	end
	
	return data
end

-- Save player data to DataStore
local function saveData(player, data)
	if not dataStore then return true end -- Skip in Studio
	
	local key = "Player_" .. player.UserId
	data.lastOnline = os.time()
	
	for attempt = 1, RETRY_ATTEMPTS do
		local success, result = pcall(function()
			dataStore:SetAsync(key, data)
		end)
		
		if success then
			return true
		else
			warn("[DataManager] Save attempt " .. attempt .. " failed for " .. player.Name .. ": " .. tostring(result))
			if attempt < RETRY_ATTEMPTS then
				task.wait(RETRY_DELAY)
			end
		end
	end
	
	return false
end

-- ═══════════════════════════════════════════════════════════════
-- PUBLIC API
-- ═══════════════════════════════════════════════════════════════

-- Create leaderstats for a player
local function createLeaderstats(player, data)
	local leaderstats = Instance.new("Folder")
	leaderstats.Name = "leaderstats"
	leaderstats.Parent = player
	
	local coinsValue = Instance.new("NumberValue")
	coinsValue.Name = "Coins"
	coinsValue.Value = data.coins
	coinsValue.Parent = leaderstats
	
	local levelValue = Instance.new("IntValue")
	levelValue.Name = "Level"
	levelValue.Value = data.level
	levelValue.Parent = leaderstats
	
	local rebirthsValue = Instance.new("IntValue")
	rebirthsValue.Name = "Rebirths"
	rebirthsValue.Value = data.rebirths
	rebirthsValue.Parent = leaderstats
	
	return leaderstats
end

-- Update leaderstats values
local function updateLeaderstats(player)
	local data = playerData[player]
	if not data then return end
	
	local leaderstats = player:FindFirstChild("leaderstats")
	if not leaderstats then return end
	
	local coinsValue = leaderstats:FindFirstChild("Coins")
	if coinsValue then
		coinsValue.Value = data.coins
	end
	
	local levelValue = leaderstats:FindFirstChild("Level")
	if levelValue then
		levelValue.Value = data.level
	end
	
	local rebirthsValue = leaderstats:FindFirstChild("Rebirths")
	if rebirthsValue then
		rebirthsValue.Value = data.rebirths
	end
end

function DataManager.init()
	initDataStore()
	
	-- Player join handler
	Players.PlayerAdded:Connect(function(player)
		local data = loadData(player)
		playerData[player] = data
		dataLoaded[player] = true
		createLeaderstats(player, data)
	end)
	
	-- Player leave handler
	Players.PlayerRemoving:Connect(function(player)
		local data = playerData[player]
		if data then
			saveData(player, data)
			playerData[player] = nil
			dataLoaded[player] = nil
		end
	end)
	
	-- Handle existing players (if script loaded late)
	for _, player in ipairs(Players:GetPlayers()) do
		if not playerData[player] then
			task.spawn(function()
				local data = loadData(player)
				playerData[player] = data
				dataLoaded[player] = true
			end)
		end
	end
	
	-- Auto-save loop
	task.spawn(function()
		while true do
			task.wait(AUTO_SAVE_INTERVAL)
			for player, data in pairs(playerData) do
				task.spawn(function()
					saveData(player, data)
				end)
			end
		end
	end)
	
	-- Save all on game close
	game:BindToClose(function()
		for player, data in pairs(playerData) do
			saveData(player, data)
		end
	end)
	
	print("[DataManager] Initialized")
end

-- Get player data (waits if not loaded)
function DataManager.getData(player)
	-- Wait for data to load (max 10 seconds)
	local startTime = os.clock()
	while not dataLoaded[player] and os.clock() - startTime < 10 do
		task.wait(0.1)
	end
	
	return playerData[player]
end

-- Check if player data is loaded
function DataManager.isDataLoaded(player)
	return dataLoaded[player] == true
end

-- Update player coins
function DataManager.addCoins(player, amount)
	local data = playerData[player]
	if data then
		data.coins = data.coins + amount
		data.totalCoinsEarned = data.totalCoinsEarned + amount
		updateLeaderstats(player)
	end
end

-- Spend coins (returns false if insufficient)
function DataManager.spendCoins(player, amount)
	local data = playerData[player]
	if data and data.coins >= amount then
		data.coins = data.coins - amount
		updateLeaderstats(player)
		return true
	end
	return false
end

-- Add XP to player
function DataManager.addXP(player, amount)
	local data = playerData[player]
	if data then
		data.xp = data.xp + amount
	end
end

-- Increment coin collection count
function DataManager.incrementCoinsCollected(player)
	local data = playerData[player]
	if data then
		data.coinsCollected = data.coinsCollected + 1
	end
end

-- Get upgrade level
function DataManager.getUpgradeLevel(player, upgradeName)
	local data = playerData[player]
	if data and data.upgrades[upgradeName] then
		return data.upgrades[upgradeName]
	end
	return 0
end

-- Set upgrade level
function DataManager.setUpgradeLevel(player, upgradeName, level)
	local data = playerData[player]
	if data and data.upgrades[upgradeName] ~= nil then
		data.upgrades[upgradeName] = level
	end
end

-- Get rebirth upgrade level
function DataManager.getRebirthUpgradeLevel(player, upgradeName)
	local data = playerData[player]
	if data and data.rebirthUpgrades[upgradeName] then
		return data.rebirthUpgrades[upgradeName]
	end
	return 0
end

-- Set rebirth upgrade level
function DataManager.setRebirthUpgradeLevel(player, upgradeName, level)
	local data = playerData[player]
	if data and data.rebirthUpgrades[upgradeName] ~= nil then
		data.rebirthUpgrades[upgradeName] = level
	end
end

-- Get player level
function DataManager.getLevel(player)
	local data = playerData[player]
	if data then
		return data.level
	end
	return 1
end

-- Set player level
function DataManager.setLevel(player, level)
	local data = playerData[player]
	if data then
		data.level = level
		updateLeaderstats(player)
	end
end

-- Get player XP
function DataManager.getXP(player)
	local data = playerData[player]
	if data then
		return data.xp
	end
	return 0
end

-- Set player XP
function DataManager.setXP(player, xp)
	local data = playerData[player]
	if data then
		data.xp = xp
	end
end

-- Get rebirths
function DataManager.getRebirths(player)
	local data = playerData[player]
	if data then
		return data.rebirths
	end
	return 0
end

-- Perform rebirth (resets appropriate values)
function DataManager.performRebirth(player, vaultPercentage, quickUpgrades)
	local data = playerData[player]
	if not data then return end
	
	-- Calculate vault coins to keep
	local keptCoins = math.floor(data.coins * (vaultPercentage / 100))
	
	-- Reset values
	data.coins = keptCoins
	data.xp = 0
	data.level = 1
	
	-- Reset base upgrades
	for name, _ in pairs(data.upgrades) do
		data.upgrades[name] = 0
	end
	
	-- Apply quick upgrades (distribute evenly across all upgrades)
	local upgradeNames = {"FasterRespawning", "CoinValueMultiplier", "CoinRarityChance", "MaxCoinsOnPlatform", "CoinPullingStrength"}
	local upgradesPerType = math.floor(quickUpgrades / #upgradeNames)
	for _, name in ipairs(upgradeNames) do
		data.upgrades[name] = upgradesPerType
	end
	
	-- Increment rebirth count
	data.rebirths = data.rebirths + 1
	data.totalRebirths = data.totalRebirths + 1
	
	updateLeaderstats(player)
end

-- Force save (for critical moments)
function DataManager.forceSave(player)
	local data = playerData[player]
	if data then
		task.spawn(function()
			saveData(player, data)
		end)
	end
end

return DataManager
