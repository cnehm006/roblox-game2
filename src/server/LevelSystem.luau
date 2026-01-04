--[[
	LevelSystem - Handles XP tracking and level progression
	Implements the XP cap system for endless scaling
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local GameConfig = require(ReplicatedStorage.Shared.GameConfig)
local Remotes = require(ReplicatedStorage.Shared.Remotes)

local DataManager -- Forward declaration

local LevelSystem = {}

-- Cache for XP requirements (optimization for frequent lookups)
local xpRequirementCache = {}

-- Get XP requirement for a specific level (with caching)
local function getXPRequirement(level)
	if xpRequirementCache[level] then
		return xpRequirementCache[level]
	end
	
	local requirement = GameConfig.getXPRequirement(level)
	xpRequirementCache[level] = requirement
	return requirement
end

-- Calculate total XP needed from level 1 to target level
local function getTotalXPForLevel(targetLevel)
	local total = 0
	for level = 1, targetLevel - 1 do
		total = total + getXPRequirement(level)
	end
	return total
end

-- ═══════════════════════════════════════════════════════════════
-- PUBLIC API
-- ═══════════════════════════════════════════════════════════════

function LevelSystem.init(dataManagerModule)
	DataManager = dataManagerModule
	
	-- Pre-cache first 200 levels for performance
	for level = 1, 200 do
		getXPRequirement(level)
	end
	
	print("[LevelSystem] Initialized")
end

-- Process XP and handle level ups
function LevelSystem.processXP(player)
	local data = DataManager.getData(player)
	if not data then return end
	
	local currentLevel = data.level
	local currentXP = data.xp
	local levelsGained = 0
	
	-- Keep leveling up while we have enough XP
	while true do
		local requirement = getXPRequirement(currentLevel)
		
		if currentXP >= requirement then
			currentXP = currentXP - requirement
			currentLevel = currentLevel + 1
			levelsGained = levelsGained + 1
			
			-- Safety cap to prevent infinite loops (shouldn't happen normally)
			if levelsGained > 1000 then
				break
			end
		else
			break
		end
	end
	
	-- Update data if levels changed
	if levelsGained > 0 then
		DataManager.setLevel(player, currentLevel)
		DataManager.setXP(player, currentXP)
		
		-- Notify client of level up
		Remotes.fireClient("LevelUp", player, currentLevel, levelsGained)
		
		print("[LevelSystem] " .. player.Name .. " leveled up! Now level " .. currentLevel .. " (+" .. levelsGained .. " levels)")
	else
		-- Just update XP
		DataManager.setXP(player, currentXP)
	end
end

-- Get progress to next level (0 to 1)
function LevelSystem.getProgress(player)
	local data = DataManager.getData(player)
	if not data then return 0 end
	
	local requirement = getXPRequirement(data.level)
	if requirement <= 0 then return 0 end
	
	return math.clamp(data.xp / requirement, 0, 1)
end

-- Get XP requirement for current level
function LevelSystem.getCurrentRequirement(player)
	local data = DataManager.getData(player)
	if not data then return 100 end
	
	return getXPRequirement(data.level)
end

-- Get level info for display
function LevelSystem.getLevelInfo(player)
	local data = DataManager.getData(player)
	if not data then
		return {
			level = 1,
			xp = 0,
			requirement = 100,
			progress = 0,
		}
	end
	
	local requirement = getXPRequirement(data.level)
	return {
		level = data.level,
		xp = data.xp,
		requirement = requirement,
		progress = math.clamp(data.xp / requirement, 0, 1),
	}
end

-- Estimate level from total XP (for leaderboards/display)
function LevelSystem.estimateLevelFromTotalXP(totalXP)
	local level = 1
	local remainingXP = totalXP
	
	-- Quick estimation using cap logic
	if totalXP > getTotalXPForLevel(GameConfig.Level.xpCapLevel) then
		-- Calculate pre-cap levels
		local preCap = getTotalXPForLevel(GameConfig.Level.xpCapLevel)
		remainingXP = totalXP - preCap
		level = GameConfig.Level.xpCapLevel
		
		-- Each level after cap costs fixed XP
		level = level + math.floor(remainingXP / GameConfig.Level.xpCapAmount)
	else
		-- Normal scaling
		while true do
			local req = getXPRequirement(level)
			if remainingXP >= req then
				remainingXP = remainingXP - req
				level = level + 1
			else
				break
			end
		end
	end
	
	return level
end

return LevelSystem
