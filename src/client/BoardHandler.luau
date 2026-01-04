--[[
	BoardHandler - Handles client-side interaction with physical upgrade boards
	Connects SurfaceGui buttons to server upgrade functions
]]

local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local GameConfig = require(Shared:WaitForChild("GameConfig"))
local Remotes = require(Shared:WaitForChild("Remotes"))

local LocalPlayer = Players.LocalPlayer

local BoardHandler = {}

-- State for hold-to-upgrade
local isHolding = false
local holdingButton = nil
local holdingUpgrade = nil
local holdingIsRebirth = false
local holdStartTime = 0
local lastUpgradeTime = 0

-- Format numbers
local function formatNumber(num)
	if num >= 1000000000 then
		return string.format("%.1fB", num / 1000000000)
	elseif num >= 1000000 then
		return string.format("%.1fM", num / 1000000)
	elseif num >= 1000 then
		return string.format("%.1fK", num / 1000)
	else
		return tostring(math.floor(num))
	end
end

-- Update upgrade board display
local function updateUpgradeBoard()
	local boardModel = Workspace:FindFirstChild("UpgradeBoardModel")
	if not boardModel then return end
	
	local board = boardModel:FindFirstChild("Board")
	if not board then return end
	
	local surfaceGui = board:FindFirstChild("UpgradeGui")
	if not surfaceGui then return end
	
	-- Get player data
	local data = Remotes.invokeServer("GetPlayerData")
	if not data then return end
	
	local mainFrame = surfaceGui:FindFirstChild("Frame")
	if not mainFrame then
		-- Find the first frame child
		for _, child in pairs(surfaceGui:GetChildren()) do
			if child:IsA("Frame") then
				mainFrame = child
				break
			end
		end
	end
	if not mainFrame then return end
	
	local upgradesFrame = mainFrame:FindFirstChildWhichIsA("Frame")
	if not upgradesFrame then return end
	
	for _, card in pairs(upgradesFrame:GetChildren()) do
		if not card:IsA("Frame") then continue end
		
		local upgradeName = card.Name
		local upgrade = GameConfig.BaseUpgrades[upgradeName]
		if not upgrade then continue end
		
		local level = data.upgrades[upgradeName] or 0
		local cost = GameConfig.getUpgradeCost(upgrade, level)
		local isMaxed = level >= upgrade.maxLevel
		local canAfford = data.coins >= cost
		
		local levelLabel = card:FindFirstChild("LevelLabel")
		if levelLabel then
			levelLabel.Text = "lvl: " .. level .. " / " .. upgrade.maxLevel
		end
		
		local costLabel = card:FindFirstChild("CostLabel")
		if costLabel then
			if isMaxed then
				costLabel.Text = "MAXED"
			else
				costLabel.Text = formatNumber(cost) .. " coins"
			end
		end
		
		local buyButton = card:FindFirstChild("BuyButton")
		if buyButton then
			if isMaxed then
				buyButton.Text = "MAX"
				buyButton.BackgroundColor3 = Color3.fromRGB(100, 200, 100)
			else
				buyButton.Text = "upgrade"
				if canAfford then
					buyButton.BackgroundColor3 = Color3.fromRGB(60, 170, 220)
				else
					buyButton.BackgroundColor3 = Color3.fromRGB(80, 80, 100)
				end
			end
		end
	end
end

-- Update rebirth board display
local function updateRebirthBoard()
	local boardModel = Workspace:FindFirstChild("RebirthBoardModel")
	if not boardModel then return end
	
	local board = boardModel:FindFirstChild("Board")
	if not board then return end
	
	local surfaceGui = board:FindFirstChild("RebirthGui")
	if not surfaceGui then return end
	
	-- Get player data
	local data = Remotes.invokeServer("GetPlayerData")
	if not data then return end
	
	local mainFrame = nil
	for _, child in pairs(surfaceGui:GetChildren()) do
		if child:IsA("Frame") then
			mainFrame = child
			break
		end
	end
	if not mainFrame then return end
	
	-- Show/hide locked overlay
	local lockedOverlay = mainFrame:FindFirstChild("LockedOverlay")
	if lockedOverlay then
		lockedOverlay.Visible = data.totalRebirths < 1
	end
	
	-- Find upgrades frame
	local upgradesFrame = nil
	for _, child in pairs(mainFrame:GetChildren()) do
		if child:IsA("Frame") and child.Name ~= "LockedOverlay" then
			upgradesFrame = child
			break
		end
	end
	if not upgradesFrame then return end
	
	for _, card in pairs(upgradesFrame:GetChildren()) do
		if not card:IsA("Frame") then continue end
		
		local upgradeName = card.Name
		local upgrade = GameConfig.RebirthUpgrades[upgradeName]
		if not upgrade then continue end
		
		local level = data.rebirthUpgrades[upgradeName] or 0
		local cost = upgrade.costPerLevel
		local isMaxed = level >= upgrade.maxLevel
		local canAfford = data.coins >= cost
		
		local levelLabel = card:FindFirstChild("LevelLabel")
		if levelLabel then
			levelLabel.Text = "lvl: " .. level .. " / " .. upgrade.maxLevel
		end
		
		local costLabel = card:FindFirstChild("CostLabel")
		if costLabel then
			if isMaxed then
				costLabel.Text = "MAXED"
			else
				costLabel.Text = formatNumber(cost) .. " coins"
			end
		end
		
		local buyButton = card:FindFirstChild("BuyButton")
		if buyButton then
			if isMaxed then
				buyButton.Text = "MAX"
				buyButton.BackgroundColor3 = Color3.fromRGB(100, 200, 100)
			else
				buyButton.Text = "upgrade"
				if canAfford then
					buyButton.BackgroundColor3 = Color3.fromRGB(180, 100, 255)
				else
					buyButton.BackgroundColor3 = Color3.fromRGB(80, 80, 100)
				end
			end
		end
	end
end

-- Connect buttons on upgrade board
local function connectUpgradeBoard()
	local boardModel = Workspace:WaitForChild("UpgradeBoardModel", 10)
	if not boardModel then return end
	
	local board = boardModel:WaitForChild("Board", 5)
	if not board then return end
	
	local surfaceGui = board:WaitForChild("UpgradeGui", 5)
	if not surfaceGui then return end
	
	-- Wait for GUI to be ready
	task.wait(0.5)
	
	local mainFrame = nil
	for _, child in pairs(surfaceGui:GetChildren()) do
		if child:IsA("Frame") then
			mainFrame = child
			break
		end
	end
	if not mainFrame then return end
	
	local upgradesFrame = nil
	for _, child in pairs(mainFrame:GetChildren()) do
		if child:IsA("Frame") then
			upgradesFrame = child
			break
		end
	end
	if not upgradesFrame then return end
	
	for _, card in pairs(upgradesFrame:GetChildren()) do
		if not card:IsA("Frame") then continue end
		
		local upgradeName = card.Name
		local buyButton = card:FindFirstChild("BuyButton")
		if not buyButton then continue end
		
		-- Single click
		buyButton.MouseButton1Click:Connect(function()
			local result = Remotes.invokeServer("PurchaseUpgrade", upgradeName)
			if result then
				updateUpgradeBoard()
			end
		end)
		
		-- Hold to upgrade quickly
		buyButton.MouseButton1Down:Connect(function()
			isHolding = true
			holdingButton = buyButton
			holdingUpgrade = upgradeName
			holdingIsRebirth = false
			holdStartTime = tick()
		end)
		
		buyButton.MouseButton1Up:Connect(function()
			if holdingButton == buyButton then
				isHolding = false
				holdingButton = nil
				holdingUpgrade = nil
			end
		end)
		
		buyButton.MouseLeave:Connect(function()
			if holdingButton == buyButton then
				isHolding = false
				holdingButton = nil
				holdingUpgrade = nil
			end
		end)
	end
	
	print("[BoardHandler] Upgrade board connected")
end

-- Connect buttons on rebirth board
local function connectRebirthBoard()
	local boardModel = Workspace:WaitForChild("RebirthBoardModel", 10)
	if not boardModel then return end
	
	local board = boardModel:WaitForChild("Board", 5)
	if not board then return end
	
	local surfaceGui = board:WaitForChild("RebirthGui", 5)
	if not surfaceGui then return end
	
	task.wait(0.5)
	
	local mainFrame = nil
	for _, child in pairs(surfaceGui:GetChildren()) do
		if child:IsA("Frame") then
			mainFrame = child
			break
		end
	end
	if not mainFrame then return end
	
	local upgradesFrame = nil
	for _, child in pairs(mainFrame:GetChildren()) do
		if child:IsA("Frame") and child.Name ~= "LockedOverlay" then
			upgradesFrame = child
			break
		end
	end
	if not upgradesFrame then return end
	
	for _, card in pairs(upgradesFrame:GetChildren()) do
		if not card:IsA("Frame") then continue end
		
		local upgradeName = card.Name
		local buyButton = card:FindFirstChild("BuyButton")
		if not buyButton then continue end
		
		buyButton.MouseButton1Click:Connect(function()
			local result = Remotes.invokeServer("PurchaseRebirthUpgrade", upgradeName)
			if result then
				updateRebirthBoard()
			end
		end)
		
		buyButton.MouseButton1Down:Connect(function()
			isHolding = true
			holdingButton = buyButton
			holdingUpgrade = upgradeName
			holdingIsRebirth = true
			holdStartTime = tick()
		end)
		
		buyButton.MouseButton1Up:Connect(function()
			if holdingButton == buyButton then
				isHolding = false
				holdingButton = nil
				holdingUpgrade = nil
			end
		end)
		
		buyButton.MouseLeave:Connect(function()
			if holdingButton == buyButton then
				isHolding = false
				holdingButton = nil
				holdingUpgrade = nil
			end
		end)
	end
	
	print("[BoardHandler] Rebirth board connected")
end

-- Hold-to-upgrade loop
local function startHoldLoop()
	RunService.Heartbeat:Connect(function()
		if not isHolding or not holdingUpgrade then return end
		
		-- Wait a bit before starting rapid upgrades
		if tick() - holdStartTime < 0.3 then return end
		
		-- Upgrade every 0.1 seconds while holding
		if tick() - lastUpgradeTime < 0.1 then return end
		lastUpgradeTime = tick()
		
		if holdingIsRebirth then
			local result = Remotes.invokeServer("PurchaseRebirthUpgrade", holdingUpgrade)
			if result then
				updateRebirthBoard()
			end
		else
			local result = Remotes.invokeServer("PurchaseUpgrade", holdingUpgrade)
			if result then
				updateUpgradeBoard()
			end
		end
	end)
end

-- ═══════════════════════════════════════════════════════════════
-- PUBLIC API
-- ═══════════════════════════════════════════════════════════════

function BoardHandler.init()
	-- Connect boards after they're created
	task.spawn(function()
		connectUpgradeBoard()
		connectRebirthBoard()
		
		-- Initial update
		task.wait(1)
		updateUpgradeBoard()
		updateRebirthBoard()
	end)
	
	-- Start hold loop
	startHoldLoop()
	
	-- Listen for stats updates to refresh boards
	local remotesFolder = ReplicatedStorage:WaitForChild("Remotes")
	local statsEvent = remotesFolder:WaitForChild("StatsUpdated", 5)
	if statsEvent then
		statsEvent.OnClientEvent:Connect(function()
			updateUpgradeBoard()
			updateRebirthBoard()
		end)
	end
	
	local upgradesEvent = remotesFolder:WaitForChild("UpgradesUpdated", 5)
	if upgradesEvent then
		upgradesEvent.OnClientEvent:Connect(function()
			updateUpgradeBoard()
		end)
	end
	
	print("[BoardHandler] Initialized")
end

function BoardHandler.refreshBoards()
	updateUpgradeBoard()
	updateRebirthBoard()
end

return BoardHandler

