--[[
	CoinCollector - Handles coin attraction and collection
	Manages pull mechanics and collection rewards
]]

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local GameConfig = require(ReplicatedStorage.Shared.GameConfig)
local Remotes = require(ReplicatedStorage.Shared.Remotes)

local DataManager -- Forward declaration
local CoinSpawner -- Forward declaration
local LevelSystem -- Forward declaration

local CoinCollector = {}

-- State
local playerCharacters = {}
local isRunning = false

-- Update character references
local function setupPlayerCharacter(player)
	local function onCharacterAdded(character)
		playerCharacters[player] = character
		character:WaitForChild("HumanoidRootPart", 10)
	end
	
	if player.Character then
		onCharacterAdded(player.Character)
	end
	
	player.CharacterAdded:Connect(onCharacterAdded)
	
	player.CharacterRemoving:Connect(function()
		playerCharacters[player] = nil
	end)
end

-- Get player's HumanoidRootPart
local function getPlayerRoot(player)
	local character = playerCharacters[player]
	if not character then return nil end
	return character:FindFirstChild("HumanoidRootPart")
end

-- Apply speed boost from rebirths
local function updatePlayerSpeed(player)
	local character = playerCharacters[player]
	if not character then return end
	
	local humanoid = character:FindFirstChildOfClass("Humanoid")
	if not humanoid then return end
	
	local rebirths = DataManager.getRebirths(player)
	local speedBoost = math.min(rebirths * GameConfig.Rebirth.speedBoostPerRebirth, GameConfig.Rebirth.maxSpeedBoost)
	local baseSpeed = 16
	
	humanoid.WalkSpeed = baseSpeed * (1 + speedBoost)
end

-- Collect a coin and give rewards
local function collectCoin(player, coin)
	local coinData = CoinSpawner.getCoinData(coin)
	if not coinData then return end -- Already collected
	
	local data = DataManager.getData(player)
	if not data then return end
	
	-- Calculate final coin value with multipliers
	local valueMultiplier = GameConfig.getCoinValueMultiplier(
		data.upgrades.CoinValueMultiplier,
		data.rebirths
	)
	local finalValue = math.floor(coinData.value * valueMultiplier)
	local xpAmount = coinData.xp
	
	-- Add rewards
	DataManager.addCoins(player, finalValue)
	DataManager.addXP(player, xpAmount)
	DataManager.incrementCoinsCollected(player)
	
	-- Process level up
	LevelSystem.processXP(player)
	
	-- Remove coin
	CoinSpawner.removeCoin(coin)
	
	-- Notify client
	Remotes.fireClient("CoinCollected", player, coinData.rarity.name, finalValue, xpAmount)
	
	-- Send updated stats
	local updatedData = DataManager.getData(player)
	if updatedData then
		Remotes.fireClient("StatsUpdated", player, {
			coins = updatedData.coins,
			xp = updatedData.xp,
			level = updatedData.level,
			totalCoinsEarned = updatedData.totalCoinsEarned,
		})
	end
end

-- Main update loop - handles attraction and collection
local function updateLoop(deltaTime)
	local activeCoins = CoinSpawner.getActiveCoins()
	
	for _, player in ipairs(Players:GetPlayers()) do
		if not DataManager.isDataLoaded(player) then continue end
		
		local root = getPlayerRoot(player)
		if not root then continue end
		
		local playerPos = root.Position
		local data = DataManager.getData(player)
		if not data then continue end
		
		-- Get player's attraction stats
		local attractionRadius = GameConfig.getAttractionRadius(data.upgrades.CoinPullingStrength)
		local pullSpeed = GameConfig.getPullSpeed(data.upgrades.CoinPullingStrength)
		local collectionRadius = GameConfig.Attraction.collectionRadius
		
		for _, coin in ipairs(activeCoins) do
			if not coin.Parent then continue end -- Skip destroyed coins
			
			local coinPos = coin.Position
			local distance = (playerPos - coinPos).Magnitude
			
			-- Check for collection
			if distance <= collectionRadius then
				collectCoin(player, coin)
				continue
			end
			
			-- Check for attraction
			if distance <= attractionRadius then
				-- Calculate pull direction and speed
				local direction = (playerPos - coinPos).Unit
				local pullDistance = pullSpeed * deltaTime
				
				-- Don't overshoot
				if pullDistance > distance - collectionRadius then
					pullDistance = distance - collectionRadius
				end
				
				-- Move coin toward player (preserve rotation)
				local newPos = coinPos + direction * pullDistance
				local currentRotation = coin.CFrame - coin.CFrame.Position
				coin.CFrame = CFrame.new(newPos) * currentRotation
			end
		end
	end
end

-- ═══════════════════════════════════════════════════════════════
-- PUBLIC API
-- ═══════════════════════════════════════════════════════════════

function CoinCollector.init(dataManagerModule, coinSpawnerModule, levelSystemModule)
	DataManager = dataManagerModule
	CoinSpawner = coinSpawnerModule
	LevelSystem = levelSystemModule
	
	-- Setup existing players
	for _, player in ipairs(Players:GetPlayers()) do
		setupPlayerCharacter(player)
	end
	
	-- Setup new players
	Players.PlayerAdded:Connect(function(player)
		setupPlayerCharacter(player)
		
		-- Update speed when data loads
		task.spawn(function()
			while not DataManager.isDataLoaded(player) do
				task.wait(0.1)
			end
			updatePlayerSpeed(player)
		end)
		
		-- Update speed on respawn
		player.CharacterAdded:Connect(function()
			task.wait(0.5) -- Wait for humanoid
			updatePlayerSpeed(player)
		end)
	end)
	
	-- Cleanup on leave
	Players.PlayerRemoving:Connect(function(player)
		playerCharacters[player] = nil
	end)
	
	-- Start update loop
	if not isRunning then
		isRunning = true
		RunService.Heartbeat:Connect(updateLoop)
	end
	
	print("[CoinCollector] Initialized")
end

-- Update player speed (called after rebirth)
function CoinCollector.updateSpeed(player)
	updatePlayerSpeed(player)
end

return CoinCollector
