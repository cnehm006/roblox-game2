--[[
	GameConfig - Central configuration for the coin incremental game
	Contains all rarities, upgrades, rebirth settings, and level scaling
]]

local GameConfig = {}

-- ═══════════════════════════════════════════════════════════════
-- COIN RARITIES
-- ═══════════════════════════════════════════════════════════════
GameConfig.CoinRarities = {
	{
		name = "Bronze",
		color = Color3.fromRGB(205, 127, 50),
		valueMultiplier = 1,
		xpYield = 1,
		weight = 1000, -- Most common
	},
	{
		name = "Silver",
		color = Color3.fromRGB(192, 192, 192),
		valueMultiplier = 2,
		xpYield = 1.2,
		weight = 500,
	},
	{
		name = "Gold",
		color = Color3.fromRGB(255, 215, 0),
		valueMultiplier = 5,
		xpYield = 1.5,
		weight = 200,
	},
	{
		name = "Diamond",
		color = Color3.fromRGB(185, 242, 255),
		valueMultiplier = 15,
		xpYield = 2,
		weight = 75,
	},
	{
		name = "Emerald",
		color = Color3.fromRGB(80, 200, 120),
		valueMultiplier = 40,
		xpYield = 2.5,
		weight = 30,
	},
	{
		name = "Ruby",
		color = Color3.fromRGB(224, 17, 95),
		valueMultiplier = 100,
		xpYield = 3,
		weight = 10,
	},
	{
		name = "Obsidian",
		color = Color3.fromRGB(30, 30, 35),
		valueMultiplier = 300,
		xpYield = 4,
		weight = 3,
	},
	{
		name = "Quartz",
		color = Color3.fromRGB(255, 255, 255),
		valueMultiplier = 1000,
		xpYield = 5,
		weight = 1, -- Rarest
	},
}

-- ═══════════════════════════════════════════════════════════════
-- BASE UPGRADES (Upgrade Board)
-- ═══════════════════════════════════════════════════════════════
GameConfig.BaseUpgrades = {
	FasterRespawning = {
		name = "FasterRespawning",
		displayName = "Faster Respawning",
		description = "Coins spawn more frequently",
		maxLevel = 200,
		baseCost = 10,
		costMultiplier = 1.15,
	},
	CoinValueMultiplier = {
		name = "CoinValueMultiplier",
		displayName = "Coin Value",
		description = "Increases the value of all coins",
		maxLevel = 400,
		baseCost = 25,
		costMultiplier = 1.12,
	},
	CoinRarityChance = {
		name = "CoinRarityChance",
		displayName = "Rarity Luck",
		description = "Increases chance of rare coins",
		maxLevel = 300,
		baseCost = 50,
		costMultiplier = 1.18,
	},
	MaxCoinsOnPlatform = {
		name = "MaxCoinsOnPlatform",
		displayName = "Max Coins",
		description = "More coins can exist at once",
		maxLevel = 250,
		baseCost = 100,
		costMultiplier = 1.20,
	},
	CoinPullingStrength = {
		name = "CoinPullingStrength",
		displayName = "Coin Magnet",
		description = "Coins are attracted to you from further away",
		maxLevel = 500,
		baseCost = 15,
		costMultiplier = 1.10,
	},
}

-- ═══════════════════════════════════════════════════════════════
-- REBIRTH UPGRADES (Rebirth Board)
-- ═══════════════════════════════════════════════════════════════
GameConfig.RebirthUpgrades = {
	QuickUpgrades = {
		name = "QuickUpgrades",
		displayName = "Quick Upgrades",
		description = "Grants free coin upgrades when rebirthing (10 per level)",
		maxLevel = 20,
		costPerLevel = 25000000, -- 25M
	},
	RebirthVault = {
		name = "RebirthVault",
		displayName = "Rebirth Vault",
		description = "Keeps a percentage of coins when rebirthing (1% per level)",
		maxLevel = 50,
		costPerLevel = 60000000, -- 60M
	},
	OfflineCoinCollection = {
		name = "OfflineCoinCollection",
		displayName = "Offline Collection",
		description = "Earns coins while offline (10M per level)",
		maxLevel = 500,
		costPerLevel = 30000000, -- 30M
	},
	AutomaticUpgrading = {
		name = "AutomaticUpgrading",
		displayName = "Auto Upgrading",
		description = "Automatically upgrades base upgrades",
		maxLevel = 100,
		costPerLevel = 35000000, -- 35M
	},
	AutomaticRebirths = {
		name = "AutomaticRebirths",
		displayName = "Auto Rebirth",
		description = "Rebirths automatically at intervals",
		maxLevel = 5,
		costPerLevel = 2500000000, -- 2.5B
	},
}

-- Auto rebirth intervals (seconds) per level
GameConfig.AutoRebirthIntervals = {
	[1] = 10,
	[2] = 5,
	[3] = 2,
	[4] = 1,
	[5] = 0.5,
}

-- ═══════════════════════════════════════════════════════════════
-- REBIRTH SETTINGS
-- ═══════════════════════════════════════════════════════════════
GameConfig.Rebirth = {
	requirement = 1000000, -- 1M coins to rebirth
	coinBoostPerRebirth = 0.10, -- 10% permanent coin boost per rebirth
	speedBoostPerRebirth = 0.02, -- 2% speed boost per rebirth
	maxSpeedBoost = 1.0, -- Max 100% speed boost (2x walkspeed)
}

-- ═══════════════════════════════════════════════════════════════
-- LEVEL SYSTEM
-- ═══════════════════════════════════════════════════════════════
GameConfig.Level = {
	baseXP = 100, -- Base XP for level 1
	scalingFactor = 1.2, -- XP scaling for levels 1-99
	xpCapLevel = 100, -- Level at which XP requirement caps
	xpCapAmount = 12000, -- Fixed XP requirement at level 100+
}

-- ═══════════════════════════════════════════════════════════════
-- SPAWNING SETTINGS
-- ═══════════════════════════════════════════════════════════════
GameConfig.Spawning = {
	baseSpawnInterval = 2.0, -- Seconds between spawns (base)
	minSpawnInterval = 0.1, -- Minimum spawn interval
	baseMaxCoins = 10, -- Base max coins on platform
	coinLifetime = 30, -- Seconds before coin despawns
	coinSize = Vector3.new(2, 0.2, 2), -- Coin dimensions
}

-- ═══════════════════════════════════════════════════════════════
-- COIN ATTRACTION SETTINGS
-- ═══════════════════════════════════════════════════════════════
GameConfig.Attraction = {
	baseRadius = 5, -- Base attraction radius
	radiusPerLevel = 0.5, -- Additional radius per upgrade level
	basePullSpeed = 20, -- Base pull speed
	pullSpeedPerLevel = 2, -- Additional speed per level
	collectionRadius = 3, -- Distance to collect coin
}

-- ═══════════════════════════════════════════════════════════════
-- HELPER FUNCTIONS
-- ═══════════════════════════════════════════════════════════════

-- Calculate upgrade cost at a specific level
function GameConfig.getUpgradeCost(upgrade, level)
	return math.floor(upgrade.baseCost * (upgrade.costMultiplier ^ level))
end

-- Calculate XP requirement for a level
function GameConfig.getXPRequirement(level)
	if level < GameConfig.Level.xpCapLevel then
		return math.floor(GameConfig.Level.baseXP * level * GameConfig.Level.scalingFactor)
	else
		return GameConfig.Level.xpCapAmount
	end
end

-- Calculate spawn interval based on upgrade level
function GameConfig.getSpawnInterval(upgradeLevel)
	local reduction = upgradeLevel * 0.008 -- 0.8% faster per level
	local interval = GameConfig.Spawning.baseSpawnInterval * (1 - reduction)
	return math.max(interval, GameConfig.Spawning.minSpawnInterval)
end

-- Calculate max coins based on upgrade level
function GameConfig.getMaxCoins(upgradeLevel)
	return GameConfig.Spawning.baseMaxCoins + (upgradeLevel * 2)
end

-- Calculate rarity weights with luck bonus
function GameConfig.getAdjustedRarityWeights(luckLevel)
	local weights = {}
	local luckMultiplier = 1 + (luckLevel * 0.02) -- 2% better rare chances per level
	
	for i, rarity in ipairs(GameConfig.CoinRarities) do
		if i == 1 then
			-- Reduce common coin weight as luck increases
			weights[i] = rarity.weight / luckMultiplier
		else
			-- Increase rare coin weights
			weights[i] = rarity.weight * (1 + (luckMultiplier - 1) * 0.5)
		end
	end
	
	return weights
end

-- Calculate coin value multiplier from upgrades and rebirths
function GameConfig.getCoinValueMultiplier(upgradeLevel, rebirths)
	local upgradeBonus = 1 + (upgradeLevel * 0.05) -- 5% per upgrade level
	local rebirthBonus = 1 + (rebirths * GameConfig.Rebirth.coinBoostPerRebirth)
	return upgradeBonus * rebirthBonus
end

-- Calculate attraction radius
function GameConfig.getAttractionRadius(upgradeLevel)
	return GameConfig.Attraction.baseRadius + (upgradeLevel * GameConfig.Attraction.radiusPerLevel)
end

-- Calculate pull speed
function GameConfig.getPullSpeed(upgradeLevel)
	return GameConfig.Attraction.basePullSpeed + (upgradeLevel * GameConfig.Attraction.pullSpeedPerLevel)
end

return GameConfig
