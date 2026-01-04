--[[
	CoinSpawner - Handles spawning coins on the platform
	Manages rarity distribution, spawn timing, and coin lifecycle
]]

local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local Debris = game:GetService("Debris")

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local GameConfig = require(ReplicatedStorage.Shared.GameConfig)
local Remotes = require(ReplicatedStorage.Shared.Remotes)

local DataManager -- Forward declaration, set in init

local CoinSpawner = {}

-- State
local spawnPlatform = nil
local activeCoins = {}

local spawnLoopRunning = false

-- Create the coin spawn platform
local function createSpawnPlatform()
	local platform = Instance.new("Part")
	platform.Name = "CoinPlatform"
	platform.Anchored = true
	platform.CanCollide = true
	platform.Size = Vector3.new(80, 2, 80)
	platform.Position = Vector3.new(0, 1, 0)
	platform.Color = Color3.fromRGB(100, 100, 120)
	platform.Material = Enum.Material.SmoothPlastic
	platform.TopSurface = Enum.SurfaceType.Smooth
	platform.BottomSurface = Enum.SurfaceType.Smooth
	platform.Parent = Workspace
	
	-- Add visual accent
	local accent = Instance.new("Part")
	accent.Name = "PlatformAccent"
	accent.Anchored = true
	accent.CanCollide = false
	accent.Size = Vector3.new(82, 0.5, 82)
	accent.Position = Vector3.new(0, 2.25, 0)
	accent.Color = Color3.fromRGB(70, 180, 220)
	accent.Material = Enum.Material.Neon
	accent.Transparency = 0.7
	accent.Parent = Workspace
	
	return platform
end

-- Select a rarity based on weighted probabilities
local function selectRarity(luckLevel)
	local weights = GameConfig.getAdjustedRarityWeights(luckLevel)
	local totalWeight = 0
	
	for _, weight in ipairs(weights) do
		totalWeight = totalWeight + weight
	end
	
	local random = math.random() * totalWeight
	local cumulative = 0
	
	for i, rarity in ipairs(GameConfig.CoinRarities) do
		cumulative = cumulative + weights[i]
		if random <= cumulative then
			return rarity
		end
	end
	
	-- Fallback to first (most common)
	return GameConfig.CoinRarities[1]
end

-- Create a coin mesh with proper appearance
local function createCoin(rarity, position)
	local coin = Instance.new("Part")
	coin.Name = "Coin_" .. rarity.name
	coin.Anchored = true
	coin.CanCollide = false
	coin.Size = Vector3.new(0.3, 2.5, 2.5) -- Thin cylinder (thickness, diameter, diameter)
	coin.Position = position
	coin.Color = rarity.color
	coin.Material = Enum.Material.Metal
	coin.Shape = Enum.PartType.Cylinder
	
	-- Rotate to stand upright on edge (coin standing up)
	coin.CFrame = CFrame.new(position) * CFrame.Angles(0, math.random() * math.pi * 2, math.rad(90))
	
	-- Add shine effect for rare coins
	if rarity.valueMultiplier >= 15 then
		local highlight = Instance.new("Highlight")
		highlight.FillColor = rarity.color
		highlight.FillTransparency = 0.8
		highlight.OutlineColor = rarity.color
		highlight.OutlineTransparency = 0.3
		highlight.Parent = coin
	end
	
	-- Add particles for very rare coins
	if rarity.valueMultiplier >= 100 then
		local attachment = Instance.new("Attachment")
		attachment.Parent = coin
		
		local sparkles = Instance.new("ParticleEmitter")
		sparkles.Color = ColorSequence.new(rarity.color)
		sparkles.LightEmission = 0.5
		sparkles.Size = NumberSequence.new(0.3, 0)
		sparkles.Lifetime = NumberRange.new(0.5, 1)
		sparkles.Rate = 10
		sparkles.Speed = NumberRange.new(2, 4)
		sparkles.SpreadAngle = Vector2.new(180, 180)
		sparkles.Parent = attachment
	end
	
	-- Add spinning animation
	local rotationValue = Instance.new("NumberValue")
	rotationValue.Name = "Rotation"
	rotationValue.Value = 0
	rotationValue.Parent = coin
	
	return coin
end

-- Count current coins
local function countActiveCoins()
	local count = 0
	for _, _ in pairs(activeCoins) do
		count = count + 1
	end
	return count
end

-- Get random position on platform
local function getRandomSpawnPosition()
	if not spawnPlatform then
		return Vector3.new(0, 5, 0)
	end
	
	local platformSize = spawnPlatform.Size
	local platformPos = spawnPlatform.Position
	
	local x = platformPos.X + (math.random() - 0.5) * (platformSize.X - 4)
	local z = platformPos.Z + (math.random() - 0.5) * (platformSize.Z - 4)
	local y = platformPos.Y + platformSize.Y / 2 + 1.5 -- Slightly above platform
	
	return Vector3.new(x, y, z)
end

-- Get best player stats for spawning (highest upgrades affect spawn)
local function getBestPlayerStats()
	local bestMaxCoins = 0
	local bestRarityChance = 0
	local bestSpawnSpeed = 0
	
	for _, player in ipairs(Players:GetPlayers()) do
		if DataManager.isDataLoaded(player) then
			local maxCoinsLevel = DataManager.getUpgradeLevel(player, "MaxCoinsOnPlatform")
			local rarityLevel = DataManager.getUpgradeLevel(player, "CoinRarityChance")
			local spawnLevel = DataManager.getUpgradeLevel(player, "FasterRespawning")
			
			bestMaxCoins = math.max(bestMaxCoins, maxCoinsLevel)
			bestRarityChance = math.max(bestRarityChance, rarityLevel)
			bestSpawnSpeed = math.max(bestSpawnSpeed, spawnLevel)
		end
	end
	
	return bestMaxCoins, bestRarityChance, bestSpawnSpeed
end

-- Spawn a single coin
local function spawnCoin()
	local maxCoinsLevel, rarityLevel, _ = getBestPlayerStats()
	local maxCoins = GameConfig.getMaxCoins(maxCoinsLevel)
	
	-- Check if at capacity
	if countActiveCoins() >= maxCoins then
		return
	end
	
	-- Select rarity and create coin
	local rarity = selectRarity(rarityLevel)
	local position = getRandomSpawnPosition()
	local coin = createCoin(rarity, position)
	
	-- Calculate base value
	local baseValue = 1
	local value = baseValue * rarity.valueMultiplier
	local xp = rarity.xpYield
	
	-- Store coin data
	activeCoins[coin] = {
		rarity = rarity,
		value = value,
		xp = xp,
		spawnTime = os.clock(),
	}
	
	coin.Parent = Workspace
	
	-- Set up auto-despawn
	Debris:AddItem(coin, GameConfig.Spawning.coinLifetime)
	
	-- Clean up tracking when destroyed
	coin.Destroying:Connect(function()
		activeCoins[coin] = nil
	end)
	
	-- Notify clients
	Remotes.fireAllClients("CoinSpawned", coin, rarity.name, rarity.color)
end

-- Main spawn loop
local function startSpawnLoop()
	if spawnLoopRunning then return end
	spawnLoopRunning = true
	
	task.spawn(function()
		while spawnLoopRunning do
			-- Only spawn if players exist
			if #Players:GetPlayers() > 0 then
				spawnCoin()
			end
			
			-- Calculate spawn interval based on best player stats
			local _, _, spawnSpeedLevel = getBestPlayerStats()
			local interval = GameConfig.getSpawnInterval(spawnSpeedLevel)
			
			task.wait(interval)
		end
	end)
end

-- ═══════════════════════════════════════════════════════════════
-- PUBLIC API
-- ═══════════════════════════════════════════════════════════════

function CoinSpawner.init(dataManagerModule)
	DataManager = dataManagerModule
	
	-- Create spawn platform
	spawnPlatform = createSpawnPlatform()
	
	-- Start spawning when first player joins
	Players.PlayerAdded:Connect(function()
		if not spawnLoopRunning then
			startSpawnLoop()
		end
	end)
	
	-- Start immediately if players already exist
	if #Players:GetPlayers() > 0 then
		startSpawnLoop()
	end
	
	print("[CoinSpawner] Initialized")
end

-- Get coin data for collection
function CoinSpawner.getCoinData(coin)
	return activeCoins[coin]
end

-- Remove a coin (when collected)
function CoinSpawner.removeCoin(coin)
	if activeCoins[coin] then
		activeCoins[coin] = nil
		coin:Destroy()
	end
end

-- Get all active coins
function CoinSpawner.getActiveCoins()
	local coins = {}
	for coin, _ in pairs(activeCoins) do
		table.insert(coins, coin)
	end
	return coins
end

-- Get spawn platform reference
function CoinSpawner.getPlatform()
	return spawnPlatform
end

return CoinSpawner
