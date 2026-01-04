--[[
	RebirthBoardSystem - Handles rebirth upgrades (advanced upgrades)
	Unlocked after first rebirth, uses fixed coin costs
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local GameConfig = require(ReplicatedStorage.Shared.GameConfig)
local Remotes = require(ReplicatedStorage.Shared.Remotes)

local DataManager -- Forward declaration
local UpgradeSystem -- Forward declaration
local RebirthSystem -- Forward declaration

local RebirthBoardSystem = {}

-- ═══════════════════════════════════════════════════════════════
-- REBIRTH UPGRADE LOGIC
-- ═══════════════════════════════════════════════════════════════

-- Check if rebirth board is unlocked for player
local function isBoardUnlocked(player)
	local data = DataManager.getData(player)
	if not data then return false end
	return data.totalRebirths > 0
end

-- Get cost for rebirth upgrade (fixed per level)
local function getUpgradeCost(upgradeName)
	local upgrade = GameConfig.RebirthUpgrades[upgradeName]
	if not upgrade then return math.huge end
	return upgrade.costPerLevel
end

-- Check if player can afford upgrade
local function canAfford(player, upgradeName)
	local data = DataManager.getData(player)
	if not data then return false end
	
	local cost = getUpgradeCost(upgradeName)
	return data.coins >= cost
end

-- Check if upgrade is at max level
local function isMaxLevel(player, upgradeName)
	local upgrade = GameConfig.RebirthUpgrades[upgradeName]
	if not upgrade then return true end
	
	local data = DataManager.getData(player)
	if not data then return true end
	
	local currentLevel = data.rebirthUpgrades[upgradeName] or 0
	return currentLevel >= upgrade.maxLevel
end

-- Purchase a rebirth upgrade
local function purchaseUpgrade(player, upgradeName)
	-- Validate upgrade exists
	local upgrade = GameConfig.RebirthUpgrades[upgradeName]
	if not upgrade then
		return false, "Invalid upgrade"
	end
	
	-- Check board unlocked
	if not isBoardUnlocked(player) then
		return false, "Rebirth board not unlocked"
	end
	
	-- Check data loaded
	local data = DataManager.getData(player)
	if not data then
		return false, "Data not loaded"
	end
	
	-- Check max level
	local currentLevel = data.rebirthUpgrades[upgradeName] or 0
	if currentLevel >= upgrade.maxLevel then
		return false, "Already at max level"
	end
	
	-- Check cost (fixed per level)
	local cost = upgrade.costPerLevel
	if not DataManager.spendCoins(player, cost) then
		return false, "Not enough coins"
	end
	
	-- Apply upgrade
	DataManager.setRebirthUpgradeLevel(player, upgradeName, currentLevel + 1)
	
	-- Special handling for certain upgrades
	if upgradeName == "AutomaticUpgrading" and UpgradeSystem then
		UpgradeSystem.refreshAutoUpgrade(player)
	elseif upgradeName == "AutomaticRebirths" and RebirthSystem then
		RebirthSystem.refreshAutoRebirth(player)
	end
	
	-- Notify client
	local updatedData = DataManager.getData(player)
	if updatedData then
		Remotes.fireClient("StatsUpdated", player, {
			coins = updatedData.coins,
		})
	end
	
	return true, nil
end

-- Get all rebirth upgrade info for a player
local function getUpgradeInfo(player)
	local data = DataManager.getData(player)
	local info = {}
	
	for name, upgrade in pairs(GameConfig.RebirthUpgrades) do
		local level = 0
		if data then
			level = data.rebirthUpgrades[name] or 0
		end
		local maxed = level >= upgrade.maxLevel
		
		info[name] = {
			level = level,
			maxLevel = upgrade.maxLevel,
			cost = upgrade.costPerLevel, -- Fixed cost
			canAfford = data and (data.coins >= upgrade.costPerLevel) or false,
			isMaxed = maxed,
			description = upgrade.description,
		}
	end
	
	return info
end

-- Get detailed effect description for upgrade
local function getEffectDescription(upgradeName, level)
	local upgrade = GameConfig.RebirthUpgrades[upgradeName]
	if not upgrade then return "" end
	
	if upgradeName == "QuickUpgrades" then
		return level * 10 .. " free upgrades on rebirth"
	elseif upgradeName == "RebirthVault" then
		return "Keep " .. level .. "% of coins on rebirth"
	elseif upgradeName == "OfflineCoinCollection" then
		return "Earn " .. (level * 10) .. "M coins per hour offline"
	elseif upgradeName == "AutomaticUpgrading" then
		local interval = math.max(0.5, 5 - (level * 0.04))
		return string.format("Auto-upgrade every %.1fs", interval)
	elseif upgradeName == "AutomaticRebirths" then
		local interval = GameConfig.AutoRebirthIntervals[level] or 10
		return "Auto-rebirth every " .. interval .. "s"
	end
	
	return upgrade.description
end

-- ═══════════════════════════════════════════════════════════════
-- PUBLIC API
-- ═══════════════════════════════════════════════════════════════

function RebirthBoardSystem.init(dataManagerModule, upgradeSystemModule, rebirthSystemModule)
	DataManager = dataManagerModule
	UpgradeSystem = upgradeSystemModule
	RebirthSystem = rebirthSystemModule
	
	-- Set up remote function for purchases
	local purchaseRemote = Remotes.getFunction("PurchaseRebirthUpgrade")
	purchaseRemote.OnServerInvoke = function(player, upgradeName)
		local success, errorMsg = purchaseUpgrade(player, upgradeName)
		return {
			success = success,
			error = errorMsg,
			upgradeInfo = getUpgradeInfo(player),
			isUnlocked = isBoardUnlocked(player),
		}
	end
	
	print("[RebirthBoardSystem] Initialized")
end

-- Check if board is unlocked
function RebirthBoardSystem.isUnlocked(player)
	return isBoardUnlocked(player)
end

-- Get upgrade info
function RebirthBoardSystem.getUpgradeInfo(player)
	return getUpgradeInfo(player)
end

-- Get effect description
function RebirthBoardSystem.getEffectDescription(upgradeName, level)
	return getEffectDescription(upgradeName, level)
end

return RebirthBoardSystem
