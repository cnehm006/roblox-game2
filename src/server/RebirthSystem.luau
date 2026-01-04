--[[
	RebirthSystem - Handles rebirth mechanics and permanent boosts
	Manages the rebirth trigger, reset, and progression
]]

local Players = game:GetService("Players")

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local GameConfig = require(ReplicatedStorage.Shared.GameConfig)
local Remotes = require(ReplicatedStorage.Shared.Remotes)

local DataManager -- Forward declaration
local CoinCollector -- Forward declaration
local UpgradeSystem -- Forward declaration

local RebirthSystem = {}

-- Auto rebirth connections
local autoRebirthConnections = {}

-- ═══════════════════════════════════════════════════════════════
-- REBIRTH LOGIC
-- ═══════════════════════════════════════════════════════════════

-- Check if player can rebirth
local function canRebirth(player)
	local data = DataManager.getData(player)
	if not data then
		return false, "Data not loaded"
	end
	
	if data.coins < GameConfig.Rebirth.requirement then
		return false, "Need " .. GameConfig.Rebirth.requirement .. " coins (have " .. data.coins .. ")"
	end
	
	return true, nil
end

-- Perform rebirth
local function performRebirth(player)
	local canDo, reason = canRebirth(player)
	if not canDo then
		return false, reason
	end
	
	local data = DataManager.getData(player)
	if not data then
		return false, "Data not loaded"
	end
	
	-- Calculate vault percentage from rebirth upgrades
	local vaultPercentage = data.rebirthUpgrades.RebirthVault -- 1% per level
	
	-- Calculate quick upgrades
	local quickUpgradeLevel = data.rebirthUpgrades.QuickUpgrades
	local freeUpgrades = quickUpgradeLevel * 10 -- 10 upgrades per level
	
	-- Track if this is first rebirth
	local isFirstRebirth = data.rebirths == 0
	
	-- Perform the rebirth
	DataManager.performRebirth(player, vaultPercentage, freeUpgrades)
	
	-- Update player speed
	if CoinCollector then
		CoinCollector.updateSpeed(player)
	end
	
	-- Get updated data
	local updatedData = DataManager.getData(player)
	if not updatedData then
		return false, "Failed to update data"
	end
	
	-- Notify client
	Remotes.fireClient("RebirthCompleted", player, {
		rebirths = updatedData.rebirths,
		coinBoost = updatedData.rebirths * GameConfig.Rebirth.coinBoostPerRebirth,
		speedBoost = math.min(updatedData.rebirths * GameConfig.Rebirth.speedBoostPerRebirth, GameConfig.Rebirth.maxSpeedBoost),
		keptCoins = updatedData.coins,
	})
	
	-- Send updated stats
	Remotes.fireClient("StatsUpdated", player, {
		coins = updatedData.coins,
		xp = updatedData.xp,
		level = updatedData.level,
		rebirths = updatedData.rebirths,
	})
	
	-- Send updated upgrades
	Remotes.fireClient("UpgradesUpdated", player, updatedData.upgrades)
	
	-- Notify about rebirth board unlock
	if isFirstRebirth then
		Remotes.fireClient("RebirthBoardUnlocked", player)
	end
	
	print("[RebirthSystem] " .. player.Name .. " rebirthed! Total rebirths: " .. updatedData.rebirths)
	
	return true, nil
end

-- Get rebirth info for display
local function getRebirthInfo(player)
	local data = DataManager.getData(player)
	
	if not data then
		return {
			canRebirth = false,
			requirement = GameConfig.Rebirth.requirement,
			currentCoins = 0,
			rebirths = 0,
			coinBoost = 0,
			speedBoost = 0,
			nextCoinBoost = GameConfig.Rebirth.coinBoostPerRebirth,
			nextSpeedBoost = GameConfig.Rebirth.speedBoostPerRebirth,
		}
	end
	
	local currentSpeedBoost = math.min(data.rebirths * GameConfig.Rebirth.speedBoostPerRebirth, GameConfig.Rebirth.maxSpeedBoost)
	local nextSpeedBoost = math.min((data.rebirths + 1) * GameConfig.Rebirth.speedBoostPerRebirth, GameConfig.Rebirth.maxSpeedBoost)
	
	return {
		canRebirth = data.coins >= GameConfig.Rebirth.requirement,
		requirement = GameConfig.Rebirth.requirement,
		currentCoins = data.coins,
		rebirths = data.rebirths,
		coinBoost = data.rebirths * GameConfig.Rebirth.coinBoostPerRebirth,
		speedBoost = currentSpeedBoost,
		nextCoinBoost = (data.rebirths + 1) * GameConfig.Rebirth.coinBoostPerRebirth,
		nextSpeedBoost = nextSpeedBoost,
	}
end

-- ═══════════════════════════════════════════════════════════════
-- AUTO REBIRTH
-- ═══════════════════════════════════════════════════════════════

local function startAutoRebirth(player)
	if autoRebirthConnections[player] then return end
	
	autoRebirthConnections[player] = task.spawn(function()
		while true do
			local data = DataManager.getData(player)
			if not data then
				task.wait(1)
				continue
			end
			
			local autoLevel = data.rebirthUpgrades.AutomaticRebirths
			if autoLevel <= 0 then
				task.wait(1)
				continue
			end
			
			-- Get interval from config
			local interval = GameConfig.AutoRebirthIntervals[autoLevel] or 10
			
			-- Try to rebirth
			if data.coins >= GameConfig.Rebirth.requirement then
				performRebirth(player)
			end
			
			task.wait(interval)
		end
	end)
end

local function stopAutoRebirth(player)
	if autoRebirthConnections[player] then
		task.cancel(autoRebirthConnections[player])
		autoRebirthConnections[player] = nil
	end
end

-- ═══════════════════════════════════════════════════════════════
-- PUBLIC API
-- ═══════════════════════════════════════════════════════════════

function RebirthSystem.init(dataManagerModule, coinCollectorModule, upgradeSystemModule)
	DataManager = dataManagerModule
	CoinCollector = coinCollectorModule
	UpgradeSystem = upgradeSystemModule
	
	-- Set up remote function for rebirth
	local rebirthRemote = Remotes.getFunction("PerformRebirth")
	rebirthRemote.OnServerInvoke = function(player)
		local success, errorMsg = performRebirth(player)
		return {
			success = success,
			error = errorMsg,
			rebirthInfo = getRebirthInfo(player),
		}
	end
	
	-- Start auto-rebirth for players with the upgrade
	Players.PlayerAdded:Connect(function(player)
		task.spawn(function()
			while not DataManager.isDataLoaded(player) do
				task.wait(0.1)
			end
			
			local data = DataManager.getData(player)
			if data and data.rebirthUpgrades.AutomaticRebirths > 0 then
				startAutoRebirth(player)
			end
		end)
	end)
	
	Players.PlayerRemoving:Connect(function(player)
		stopAutoRebirth(player)
	end)
	
	print("[RebirthSystem] Initialized")
end

-- Check if player can rebirth
function RebirthSystem.canRebirth(player)
	local can, _ = canRebirth(player)
	return can
end

-- Get rebirth info
function RebirthSystem.getRebirthInfo(player)
	return getRebirthInfo(player)
end

-- Refresh auto-rebirth after upgrade purchase
function RebirthSystem.refreshAutoRebirth(player)
	local data = DataManager.getData(player)
	if data and data.rebirthUpgrades.AutomaticRebirths > 0 then
		stopAutoRebirth(player)
		startAutoRebirth(player)
	else
		stopAutoRebirth(player)
	end
end

return RebirthSystem
