--[[
	PlayerDataTemplate - Default player data structure
	Used for new players and data validation
]]

local PlayerDataTemplate = {}

PlayerDataTemplate.Default = {
	-- Currency & Stats
	coins = 0,
	totalCoinsEarned = 0,
	xp = 0,
	level = 1,
	
	-- Rebirths
	rebirths = 0,
	totalRebirths = 0,
	
	-- Upgrade Levels
	upgrades = {
		FasterRespawning = 0,
		CoinValueMultiplier = 0,
		CoinRarityChance = 0,
		MaxCoinsOnPlatform = 0,
		CoinPullingStrength = 0,
	},
	rebirthUpgrades = {
		QuickUpgrades = 0,
		RebirthVault = 0,
		OfflineCoinCollection = 0,
		AutomaticUpgrading = 0,
		AutomaticRebirths = 0,
	},
	
	-- Tracking
	coinsCollected = 0,
	playTime = 0,
	lastOnline = 0,
	
	-- Version
	dataVersion = 1,
}

-- Deep clone function for creating new player data
function PlayerDataTemplate.clone()
	local data = {}
	for key, value in pairs(PlayerDataTemplate.Default) do
		if type(value) == "table" then
			data[key] = {}
			for k, v in pairs(value) do
				data[key][k] = v
			end
		else
			data[key] = value
		end
	end
	return data
end

-- Validate and repair player data
function PlayerDataTemplate.validate(data)
	if type(data) ~= "table" then
		return PlayerDataTemplate.clone()
	end
	
	local template = PlayerDataTemplate.Default
	
	-- Ensure all fields exist with correct types
	for key, defaultValue in pairs(template) do
		if data[key] == nil then
			if type(defaultValue) == "table" then
				data[key] = {}
				for k, v in pairs(defaultValue) do
					data[key][k] = v
				end
			else
				data[key] = defaultValue
			end
		end
	end
	
	-- Validate nested upgrade tables
	if type(data.upgrades) ~= "table" then
		data.upgrades = {}
		for k, v in pairs(template.upgrades) do
			data.upgrades[k] = v
		end
	else
		for key, value in pairs(template.upgrades) do
			if data.upgrades[key] == nil then
				data.upgrades[key] = value
			end
		end
	end
	
	if type(data.rebirthUpgrades) ~= "table" then
		data.rebirthUpgrades = {}
		for k, v in pairs(template.rebirthUpgrades) do
			data.rebirthUpgrades[k] = v
		end
	else
		for key, value in pairs(template.rebirthUpgrades) do
			if data.rebirthUpgrades[key] == nil then
				data.rebirthUpgrades[key] = value
			end
		end
	end
	
	return data
end

return PlayerDataTemplate
