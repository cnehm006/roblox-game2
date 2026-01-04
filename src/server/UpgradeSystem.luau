--[[
	UpgradeSystem - Handles base upgrade purchases and effects
	Manages the upgrade board functionality
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local GameConfig = require(ReplicatedStorage.Shared.GameConfig)
local Remotes = require(ReplicatedStorage.Shared.Remotes)

local DataManager -- Forward declaration

local UpgradeSystem = {}

-- ═══════════════════════════════════════════════════════════════
-- UPGRADE LOGIC
-- ═══════════════════════════════════════════════════════════════

-- Calculate cost for an upgrade at a specific level
local function getUpgradeCost(upgradeName, level)
	local upgrade = GameConfig.BaseUpgrades[upgradeName]
	if not upgrade then return math.huge end
	
	return GameConfig.getUpgradeCost(upgrade, level)
end

-- Check if player can afford upgrade
local function canAfford(player, upgradeName)
	local data = DataManager.getData(player)
	if not data then return false end
	
	local currentLevel = data.upgrades[upgradeName] or 0
	local cost = getUpgradeCost(upgradeName, currentLevel)
	
	return data.coins >= cost
end

-- Check if upgrade is at max level
local function isMaxLevel(player, upgradeName)
	local upgrade = GameConfig.BaseUpgrades[upgradeName]
	if not upgrade then return true end
	
	local data = DataManager.getData(player)
	if not data then return true end
	
	local currentLevel = data.upgrades[upgradeName] or 0
	return currentLevel >= upgrade.maxLevel
end

-- Purchase an upgrade
local function purchaseUpgrade(player, upgradeName)
	-- Validate upgrade exists
	local upgrade = GameConfig.BaseUpgrades[upgradeName]
	if not upgrade then
		return false, "Invalid upgrade"
	end
	
	-- Check data loaded
	local data = DataManager.getData(player)
	if not data then
		return false, "Data not loaded"
	end
	
	-- Check max level
	local currentLevel = data.upgrades[upgradeName] or 0
	if currentLevel >= upgrade.maxLevel then
		return false, "Already at max level"
	end
	
	-- Check cost
	local cost = getUpgradeCost(upgradeName, currentLevel)
	if not DataManager.spendCoins(player, cost) then
		return false, "Not enough coins"
	end
	
	-- Apply upgrade
	DataManager.setUpgradeLevel(player, upgradeName, currentLevel + 1)
	
	-- Notify client
	local updatedData = DataManager.getData(player)
	if updatedData then
		Remotes.fireClient("UpgradesUpdated", player, updatedData.upgrades)
		Remotes.fireClient("StatsUpdated", player, {
			coins = updatedData.coins,
		})
	end
	
	return true, nil
end

-- Get all upgrade info for a player
local function getUpgradeInfo(player)
	local data = DataManager.getData(player)
	local info = {}
	
	for name, upgrade in pairs(GameConfig.BaseUpgrades) do
		local level = 0
		if data then
			level = data.upgrades[name] or 0
		end
		local cost = getUpgradeCost(name, level)
		local maxed = level >= upgrade.maxLevel
		
		info[name] = {
			level = level,
			maxLevel = upgrade.maxLevel,
			cost = maxed and 0 or cost,
			canAfford = data and (data.coins >= cost) or false,
			isMaxed = maxed,
		}
	end
	
	return info
end

-- ═══════════════════════════════════════════════════════════════
-- AUTO UPGRADING (Rebirth Upgrade)
-- ═══════════════════════════════════════════════════════════════

local autoUpgradeConnections = {}

local function startAutoUpgrading(player)
	if autoUpgradeConnections[player] then return end
	
	autoUpgradeConnections[player] = task.spawn(function()
		while true do
			local data = DataManager.getData(player)
			if not data then
				task.wait(1)
				continue
			end
			
			local autoLevel = data.rebirthUpgrades.AutomaticUpgrading
			if autoLevel <= 0 then
				task.wait(1)
				continue
			end
			
			-- Calculate upgrade interval (faster with more levels)
			local interval = math.max(0.5, 5 - (autoLevel * 0.04)) -- 5 seconds at level 1, 0.5 seconds at level 100
			
			-- Try to upgrade each upgrade type
			local upgradeOrder = {
				"CoinValueMultiplier",
				"CoinRarityChance", 
				"FasterRespawning",
				"MaxCoinsOnPlatform",
				"CoinPullingStrength",
			}
			
			for _, upgradeName in ipairs(upgradeOrder) do
				if canAfford(player, upgradeName) and not isMaxLevel(player, upgradeName) then
					purchaseUpgrade(player, upgradeName)
					break -- Only one upgrade per tick
				end
			end
			
			task.wait(interval)
		end
	end)
end

local function stopAutoUpgrading(player)
	if autoUpgradeConnections[player] then
		task.cancel(autoUpgradeConnections[player])
		autoUpgradeConnections[player] = nil
	end
end

-- ═══════════════════════════════════════════════════════════════
-- PUBLIC API
-- ═══════════════════════════════════════════════════════════════

function UpgradeSystem.init(dataManagerModule)
	DataManager = dataManagerModule
	
	-- Set up remote function for purchases
	local purchaseRemote = Remotes.getFunction("PurchaseUpgrade")
	purchaseRemote.OnServerInvoke = function(player, upgradeName)
		local success, errorMsg = purchaseUpgrade(player, upgradeName)
		return {
			success = success,
			error = errorMsg,
			upgradeInfo = getUpgradeInfo(player),
		}
	end
	
	-- Start auto-upgrading for players with the upgrade
	local Players = game:GetService("Players")
	
	Players.PlayerAdded:Connect(function(player)
		task.spawn(function()
			while not DataManager.isDataLoaded(player) do
				task.wait(0.1)
			end
			
			local data = DataManager.getData(player)
			if data and data.rebirthUpgrades.AutomaticUpgrading > 0 then
				startAutoUpgrading(player)
			end
		end)
	end)
	
	Players.PlayerRemoving:Connect(function(player)
		stopAutoUpgrading(player)
	end)
	
	print("[UpgradeSystem] Initialized")
end

-- Check if player can purchase upgrade
function UpgradeSystem.canPurchase(player, upgradeName)
	return canAfford(player, upgradeName) and not isMaxLevel(player, upgradeName)
end

-- Get upgrade info
function UpgradeSystem.getUpgradeInfo(player)
	return getUpgradeInfo(player)
end

-- Refresh auto-upgrading after rebirth upgrade purchase
function UpgradeSystem.refreshAutoUpgrade(player)
	local data = DataManager.getData(player)
	if data and data.rebirthUpgrades.AutomaticUpgrading > 0 then
		stopAutoUpgrading(player)
		startAutoUpgrading(player)
	else
		stopAutoUpgrading(player)
	end
end

return UpgradeSystem
